from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Dict, Set, Optional, Tuple
from ir import IRInstruction, IRFunction


@dataclass
class BasicBlock:
    id: int
    label: str
    instructions: List[IRInstruction] = field(default_factory=list)
    predecessors: Set[int] = field(default_factory=set)
    successors: Set[int] = field(default_factory=set)
    is_entry: bool = False
    is_exit: bool = False


@dataclass
class ControlFlowGraph:
    function_id: int
    function_name: str
    blocks: Dict[int, BasicBlock] = field(default_factory=dict)
    entry_block_id: int = 0
    natural_loops: List[Tuple[int, Set[int]]] = field(default_factory=list)  # (header_id, loop_block_ids)

    def format(self) -> str:
        lines = [f"CFG for {self.function_name}:"]
        for block_id in sorted(self.blocks.keys()):
            bb = self.blocks[block_id]
            pred_str = ", ".join(f"B{p}" for p in sorted(bb.predecessors))
            succ_str = ", ".join(f"B{s}" for s in sorted(bb.successors))
            lines.append(f"  Block B{bb.id} [{bb.label}] (Preds: [{pred_str}], Succs: [{succ_str}]):")
            for inst in bb.instructions:
                lines.append(f"    {inst}")
        if self.natural_loops:
            lines.append("  Natural Loops:")
            for hdr, body in self.natural_loops:
                body_str = ", ".join(f"B{b}" for b in sorted(body))
                lines.append(f"    Header B{hdr} -> Body: [{body_str}]")
        return "\n".join(lines)


class CFGBuilder:
    def __init__(self):
        pass

    def build_for_function(self, ir_fn: IRFunction) -> ControlFlowGraph:
        cfg = ControlFlowGraph(function_id=ir_fn.id, function_name=ir_fn.name)

        if not ir_fn.instructions:
            empty_bb = BasicBlock(id=0, label="entry", is_entry=True, is_exit=True)
            cfg.blocks[0] = empty_bb
            return cfg

        # Step 1: Identify leader instruction indices
        leaders: Set[int] = {0}
        label_to_leader: Dict[str, int] = {}

        for i, inst in enumerate(ir_fn.instructions):
            if inst.op == "LABEL" and inst.label:
                leaders.add(i)
                label_to_leader[inst.label] = i
            elif inst.op in ("JUMP", "JUMP_IF_FALSE", "RETURN", "BREAK", "CONTINUE"):
                if i + 1 < len(ir_fn.instructions):
                    leaders.add(i + 1)

        sorted_leaders = sorted(leaders)

        # Step 2: Form BasicBlocks
        block_id_counter = 0
        leader_to_block_id: Dict[int, int] = {}
        label_to_block_id: Dict[str, int] = {}

        for idx, leader_idx in enumerate(sorted_leaders):
            next_leader_idx = sorted_leaders[idx + 1] if idx + 1 < len(sorted_leaders) else len(ir_fn.instructions)
            block_insts = ir_fn.instructions[leader_idx:next_leader_idx]

            block_label = f"block_{block_id_counter}"
            if block_insts and block_insts[0].op == "LABEL" and block_insts[0].label:
                block_label = block_insts[0].label
                label_to_block_id[block_insts[0].label] = block_id_counter

            bb = BasicBlock(
                id=block_id_counter,
                label=block_label,
                instructions=block_insts,
                is_entry=(block_id_counter == 0),
            )
            cfg.blocks[block_id_counter] = bb
            leader_to_block_id[leader_idx] = block_id_counter
            block_id_counter += 1

        # Step 3: Link edges between blocks
        for bb in cfg.blocks.values():
            if not bb.instructions:
                continue

            last_inst = bb.instructions[-1]
            next_bb_id = bb.id + 1 if (bb.id + 1) in cfg.blocks else None

            if last_inst.op == "JUMP":
                target_label = last_inst.args[0] if last_inst.args else None
                if target_label and target_label in label_to_block_id:
                    target_id = label_to_block_id[target_label]
                    bb.successors.add(target_id)
                    cfg.blocks[target_id].predecessors.add(bb.id)

            elif last_inst.op == "JUMP_IF_FALSE":
                target_label = last_inst.args[1] if len(last_inst.args) > 1 else None
                # Fallthrough branch
                if next_bb_id is not None:
                    bb.successors.add(next_bb_id)
                    cfg.blocks[next_bb_id].predecessors.add(bb.id)
                # False target branch
                if target_label and target_label in label_to_block_id:
                    target_id = label_to_block_id[target_label]
                    bb.successors.add(target_id)
                    cfg.blocks[target_id].predecessors.add(bb.id)

            elif last_inst.op == "RETURN":
                bb.is_exit = True

            else:
                # Normal fallthrough
                if next_bb_id is not None:
                    bb.successors.add(next_bb_id)
                    cfg.blocks[next_bb_id].predecessors.add(bb.id)

        # Step 4: Detect natural loops (back-edges)
        cfg.natural_loops = self.detect_loops(cfg)

        return cfg

    def detect_loops(self, cfg: ControlFlowGraph) -> List[Tuple[int, Set[int]]]:
        loops: List[Tuple[int, Set[int]]] = []
        dominators = self.compute_dominators(cfg)

        # A back-edge is an edge A -> B where B dominates A
        for u_id, bb in cfg.blocks.items():
            for v_id in bb.successors:
                if v_id in dominators.get(u_id, set()):
                    # Back-edge from u to v (v is header)
                    loop_body = self.get_loop_body(v_id, u_id, cfg)
                    loops.append((v_id, loop_body))

        return loops

    def compute_dominators(self, cfg: ControlFlowGraph) -> Dict[int, Set[int]]:
        all_blocks = set(cfg.blocks.keys())
        dom: Dict[int, Set[int]] = {b: set(all_blocks) for b in all_blocks}
        if cfg.entry_block_id in dom:
            dom[cfg.entry_block_id] = {cfg.entry_block_id}

        changed = True
        while changed:
            changed = False
            for b_id in all_blocks:
                if b_id == cfg.entry_block_id:
                    continue
                bb = cfg.blocks[b_id]
                if not bb.predecessors:
                    new_dom = {b_id}
                else:
                    pred_doms = [dom[p] for p in bb.predecessors if p in dom]
                    new_dom = set.intersection(*pred_doms).union({b_id}) if pred_doms else {b_id}

                if new_dom != dom[b_id]:
                    dom[b_id] = new_dom
                    changed = True

        return dom

    def get_loop_body(self, header_id: int, back_node_id: int, cfg: ControlFlowGraph) -> Set[int]:
        loop_body = {header_id, back_node_id}
        stack = [back_node_id] if back_node_id != header_id else []

        while stack:
            curr = stack.pop()
            for pred in cfg.blocks[curr].predecessors:
                if pred not in loop_body:
                    loop_body.add(pred)
                    stack.append(pred)

        return loop_body


def build_cfg_for_functions(functions: List[IRFunction]) -> List[ControlFlowGraph]:
    builder = CFGBuilder()
    return [builder.build_for_function(fn) for fn in functions]
