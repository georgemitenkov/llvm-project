//===- SimplifyCFGPass.cpp - CFG Simplification Pass ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements dead code elimination and basic block merging, along
// with a collection of other peephole control flow optimizations.  For example:
//
//   * Removes basic blocks with no predecessors.
//   * Merges a basic block into its predecessor if there is only one and the
//     predecessor only has one successor.
//   * Eliminates PHI nodes for basic blocks with a single predecessor.
//   * Eliminates a basic block that only contains an unconditional branch.
//   * Changes invoke instructions to nounwind functions to be calls.
//   * Change things like "if (x) if (y)" into "if (x&y)".
//   * etc..
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/DomTreeUpdater.h"
#include "llvm/Analysis/GlobalsModRef.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/SimplifyCFGOptions.h"
#include <utility>
using namespace llvm;

#define DEBUG_TYPE "simplifycfg"

static cl::opt<unsigned> UserBonusInstThreshold(
    "bonus-inst-threshold", cl::Hidden, cl::init(1),
    cl::desc("Control the number of bonus instructions (default = 1)"));

static cl::opt<bool> UserKeepLoops(
    "keep-loops", cl::Hidden, cl::init(true),
    cl::desc("Preserve canonical loop structure (default = true)"));

static cl::opt<bool> UserSwitchToLookup(
    "switch-to-lookup", cl::Hidden, cl::init(false),
    cl::desc("Convert switches to lookup tables (default = false)"));

static cl::opt<bool> UserForwardSwitchCond(
    "forward-switch-cond", cl::Hidden, cl::init(false),
    cl::desc("Forward switch condition to phi ops (default = false)"));

static cl::opt<bool> UserHoistCommonInsts(
    "hoist-common-insts", cl::Hidden, cl::init(false),
    cl::desc("hoist common instructions (default = false)"));

static cl::opt<bool> UserSinkCommonInsts(
    "sink-common-insts", cl::Hidden, cl::init(false),
    cl::desc("Sink common instructions (default = false)"));


STATISTIC(NumSimpl, "Number of blocks simplified");

static bool tailMergeBlocksWithSimilarFunctionTerminators(Function &F,
                                                          DomTreeUpdater *DTU) {
  SmallMapVector<unsigned /*TerminatorOpcode*/, SmallVector<BasicBlock *, 2>, 4>
      Structure;

  // Scan all the blocks in the function, record the interesting-ones.
  for (BasicBlock &BB : F) {
    if (DTU && DTU->isBBPendingDeletion(&BB))
      continue;

    // We are only interested in function-terminating blocks.
    if (!succ_empty(&BB))
      continue;

    auto *Term = BB.getTerminator();

    // Fow now only support `ret` function terminators.
    // FIXME: lift this restriction.
    if (Term->getOpcode() != Instruction::Ret)
      continue;

    // We can't tail-merge block that contains a musttail call.
    if (BB.getTerminatingMustTailCall())
      continue;

    // Calls to experimental_deoptimize must be followed by a return
    // of the value computed by experimental_deoptimize.
    // I.e., we can not change `ret` to `br` for this block.
    if (auto *CI =
            dyn_cast_or_null<CallInst>(Term->getPrevNonDebugInstruction())) {
      if (Function *F = CI->getCalledFunction())
        if (Intrinsic::ID ID = F->getIntrinsicID())
          if (ID == Intrinsic::experimental_deoptimize)
            continue;
    }

    // PHI nodes cannot have token type, so if the terminator has an operand
    // with token type, we can not tail-merge this kind of function terminators.
    if (any_of(Term->operands(),
               [](Value *Op) { return Op->getType()->isTokenTy(); }))
      continue;

    // Only look at the block if it is empty or the only other thing in it is a
    // single PHI node that is the operand to the return.
    // FIXME: lift this restriction.
    if (Term != &BB.front()) {
      // Check for something else in the block.
      BasicBlock::iterator I(Term);
      --I;
      // Skip over debug info.
      while (isa<DbgInfoIntrinsic>(I) && I != BB.begin())
        --I;
      if (!isa<DbgInfoIntrinsic>(I) &&
          (!isa<PHINode>(I) || I != BB.begin() || Term->getNumOperands() == 0 ||
           Term->getOperand(0) != &*I))
        continue;
    }

    // Canonical blocks are uniqued based on the terminator type (opcode).
    Structure[Term->getOpcode()].emplace_back(&BB);
  }

  bool Changed = false;

  std::vector<DominatorTree::UpdateType> Updates;

  for (ArrayRef<BasicBlock *> BBs : make_second_range(Structure)) {
    SmallVector<PHINode *, 1> NewOps;

    // We don't want to change IR just because we can.
    // Only do that if there are at least two blocks we'll tail-merge.
    if (BBs.size() < 2)
      continue;

    Changed = true;

    if (DTU)
      Updates.reserve(Updates.size() + BBs.size());

    BasicBlock *CanonicalBB;
    Instruction *CanonicalTerm;
    {
      auto *Term = BBs[0]->getTerminator();

      // Create a canonical block for this function terminator type now,
      // placing it *before* the first block that will branch to it.
      CanonicalBB = BasicBlock::Create(
          F.getContext(), Twine("common.") + Term->getOpcodeName(), &F, BBs[0]);
      // We'll also need a PHI node per each operand of the terminator.
      NewOps.resize(Term->getNumOperands());
      for (auto I : zip(Term->operands(), NewOps)) {
        std::get<1>(I) = PHINode::Create(std::get<0>(I)->getType(),
                                         /*NumReservedValues=*/BBs.size(),
                                         CanonicalBB->getName() + ".op");
        CanonicalBB->getInstList().push_back(std::get<1>(I));
      }
      // Make it so that this canonical block actually has the right
      // terminator.
      CanonicalTerm = Term->clone();
      CanonicalBB->getInstList().push_back(CanonicalTerm);
      // If the canonical terminator has operands, rewrite it to take PHI's.
      for (auto I : zip(NewOps, CanonicalTerm->operands()))
        std::get<1>(I) = std::get<0>(I);
    }

    // Now, go through each block (with the current terminator type)
    // we've recorded, and rewrite it to branch to the new common block.
    const DILocation *CommonDebugLoc = nullptr;
    for (BasicBlock *BB : BBs) {
      auto *Term = BB->getTerminator();

      // Aha, found a new non-canonical function terminator. If it has operands,
      // forward them to the PHI nodes in the canonical block.
      for (auto I : zip(Term->operands(), NewOps))
        std::get<1>(I)->addIncoming(std::get<0>(I), BB);

      // Compute the debug location common to all the original terminators.
      if (!CommonDebugLoc)
        CommonDebugLoc = Term->getDebugLoc();
      else
        CommonDebugLoc =
            DILocation::getMergedLocation(CommonDebugLoc, Term->getDebugLoc());

      // And turn BB into a block that just unconditionally branches
      // to the canonical block.
      Term->eraseFromParent();
      BranchInst::Create(CanonicalBB, BB);
      if (DTU)
        Updates.push_back({DominatorTree::Insert, BB, CanonicalBB});
    }

    CanonicalTerm->setDebugLoc(CommonDebugLoc);
  }

  if (DTU)
    DTU->applyUpdates(Updates);

  return Changed;
}

/// Call SimplifyCFG on all the blocks in the function,
/// iterating until no more changes are made.
static bool iterativelySimplifyCFG(Function &F, const TargetTransformInfo &TTI,
                                   DomTreeUpdater *DTU,
                                   const SimplifyCFGOptions &Options) {
  bool Changed = false;
  bool LocalChange = true;

  SmallVector<std::pair<const BasicBlock *, const BasicBlock *>, 32> Edges;
  FindFunctionBackedges(F, Edges);
  SmallPtrSet<BasicBlock *, 16> UniqueLoopHeaders;
  for (unsigned i = 0, e = Edges.size(); i != e; ++i)
    UniqueLoopHeaders.insert(const_cast<BasicBlock *>(Edges[i].second));

  SmallVector<WeakVH, 16> LoopHeaders(UniqueLoopHeaders.begin(),
                                      UniqueLoopHeaders.end());

  while (LocalChange) {
    LocalChange = false;

    // Loop over all of the basic blocks and remove them if they are unneeded.
    for (Function::iterator BBIt = F.begin(); BBIt != F.end(); ) {
      BasicBlock &BB = *BBIt++;
      if (DTU) {
        assert(
            !DTU->isBBPendingDeletion(&BB) &&
            "Should not end up trying to simplify blocks marked for removal.");
        // Make sure that the advanced iterator does not point at the blocks
        // that are marked for removal, skip over all such blocks.
        while (BBIt != F.end() && DTU->isBBPendingDeletion(&*BBIt))
          ++BBIt;
      }
      if (simplifyCFG(&BB, TTI, DTU, Options, LoopHeaders)) {
        LocalChange = true;
        ++NumSimpl;
      }
    }
    Changed |= LocalChange;
  }
  return Changed;
}

static bool simplifyFunctionCFGImpl(Function &F, const TargetTransformInfo &TTI,
                                    DominatorTree *DT,
                                    const SimplifyCFGOptions &Options) {
  DomTreeUpdater DTU(DT, DomTreeUpdater::UpdateStrategy::Eager);

  bool EverChanged = removeUnreachableBlocks(F, DT ? &DTU : nullptr);
  EverChanged |=
      tailMergeBlocksWithSimilarFunctionTerminators(F, DT ? &DTU : nullptr);
  EverChanged |= iterativelySimplifyCFG(F, TTI, DT ? &DTU : nullptr, Options);

  // If neither pass changed anything, we're done.
  if (!EverChanged) return false;

  // iterativelySimplifyCFG can (rarely) make some loops dead.  If this happens,
  // removeUnreachableBlocks is needed to nuke them, which means we should
  // iterate between the two optimizations.  We structure the code like this to
  // avoid rerunning iterativelySimplifyCFG if the second pass of
  // removeUnreachableBlocks doesn't do anything.
  if (!removeUnreachableBlocks(F, DT ? &DTU : nullptr))
    return true;

  do {
    EverChanged = iterativelySimplifyCFG(F, TTI, DT ? &DTU : nullptr, Options);
    EverChanged |= removeUnreachableBlocks(F, DT ? &DTU : nullptr);
  } while (EverChanged);

  return true;
}

static bool simplifyFunctionCFG(Function &F, const TargetTransformInfo &TTI,
                                DominatorTree *DT,
                                const SimplifyCFGOptions &Options) {
  assert((!RequireAndPreserveDomTree ||
          (DT && DT->verify(DominatorTree::VerificationLevel::Full))) &&
         "Original domtree is invalid?");

  bool Changed = simplifyFunctionCFGImpl(F, TTI, DT, Options);

  assert((!RequireAndPreserveDomTree ||
          (DT && DT->verify(DominatorTree::VerificationLevel::Full))) &&
         "Failed to maintain validity of domtree!");

  return Changed;
}

// Command-line settings override compile-time settings.
static void applyCommandLineOverridesToOptions(SimplifyCFGOptions &Options) {
  if (UserBonusInstThreshold.getNumOccurrences())
    Options.BonusInstThreshold = UserBonusInstThreshold;
  if (UserForwardSwitchCond.getNumOccurrences())
    Options.ForwardSwitchCondToPhi = UserForwardSwitchCond;
  if (UserSwitchToLookup.getNumOccurrences())
    Options.ConvertSwitchToLookupTable = UserSwitchToLookup;
  if (UserKeepLoops.getNumOccurrences())
    Options.NeedCanonicalLoop = UserKeepLoops;
  if (UserHoistCommonInsts.getNumOccurrences())
    Options.HoistCommonInsts = UserHoistCommonInsts;
  if (UserSinkCommonInsts.getNumOccurrences())
    Options.SinkCommonInsts = UserSinkCommonInsts;
}

SimplifyCFGPass::SimplifyCFGPass() : Options() {
  applyCommandLineOverridesToOptions(Options);
}

SimplifyCFGPass::SimplifyCFGPass(const SimplifyCFGOptions &Opts)
    : Options(Opts) {
  applyCommandLineOverridesToOptions(Options);
}

PreservedAnalyses SimplifyCFGPass::run(Function &F,
                                       FunctionAnalysisManager &AM) {
  auto &TTI = AM.getResult<TargetIRAnalysis>(F);
  Options.AC = &AM.getResult<AssumptionAnalysis>(F);
  DominatorTree *DT = nullptr;
  if (RequireAndPreserveDomTree)
    DT = &AM.getResult<DominatorTreeAnalysis>(F);
  if (F.hasFnAttribute(Attribute::OptForFuzzing)) {
    Options.setSimplifyCondBranch(false).setFoldTwoEntryPHINode(false);
  } else {
    Options.setSimplifyCondBranch(true).setFoldTwoEntryPHINode(true);
  }
  if (!simplifyFunctionCFG(F, TTI, DT, Options))
    return PreservedAnalyses::all();
  PreservedAnalyses PA;
  if (RequireAndPreserveDomTree)
    PA.preserve<DominatorTreeAnalysis>();
  return PA;
}

namespace {
struct CFGSimplifyPass : public FunctionPass {
  static char ID;
  SimplifyCFGOptions Options;
  std::function<bool(const Function &)> PredicateFtor;

  CFGSimplifyPass(SimplifyCFGOptions Options_ = SimplifyCFGOptions(),
                  std::function<bool(const Function &)> Ftor = nullptr)
      : FunctionPass(ID), Options(Options_), PredicateFtor(std::move(Ftor)) {

    initializeCFGSimplifyPassPass(*PassRegistry::getPassRegistry());

    // Check for command-line overrides of options for debug/customization.
    applyCommandLineOverridesToOptions(Options);
  }

  bool runOnFunction(Function &F) override {
    if (skipFunction(F) || (PredicateFtor && !PredicateFtor(F)))
      return false;

    Options.AC = &getAnalysis<AssumptionCacheTracker>().getAssumptionCache(F);
    DominatorTree *DT = nullptr;
    if (RequireAndPreserveDomTree)
      DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
    if (F.hasFnAttribute(Attribute::OptForFuzzing)) {
      Options.setSimplifyCondBranch(false)
             .setFoldTwoEntryPHINode(false);
    } else {
      Options.setSimplifyCondBranch(true)
             .setFoldTwoEntryPHINode(true);
    }

    auto &TTI = getAnalysis<TargetTransformInfoWrapperPass>().getTTI(F);
    return simplifyFunctionCFG(F, TTI, DT, Options);
  }
  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<AssumptionCacheTracker>();
    if (RequireAndPreserveDomTree)
      AU.addRequired<DominatorTreeWrapperPass>();
    AU.addRequired<TargetTransformInfoWrapperPass>();
    if (RequireAndPreserveDomTree)
      AU.addPreserved<DominatorTreeWrapperPass>();
    AU.addPreserved<GlobalsAAWrapperPass>();
  }
};
}

char CFGSimplifyPass::ID = 0;
INITIALIZE_PASS_BEGIN(CFGSimplifyPass, "simplifycfg", "Simplify the CFG", false,
                      false)
INITIALIZE_PASS_DEPENDENCY(TargetTransformInfoWrapperPass)
INITIALIZE_PASS_DEPENDENCY(AssumptionCacheTracker)
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass)
INITIALIZE_PASS_END(CFGSimplifyPass, "simplifycfg", "Simplify the CFG", false,
                    false)

// Public interface to the CFGSimplification pass
FunctionPass *
llvm::createCFGSimplificationPass(SimplifyCFGOptions Options,
                                  std::function<bool(const Function &)> Ftor) {
  return new CFGSimplifyPass(Options, std::move(Ftor));
}
