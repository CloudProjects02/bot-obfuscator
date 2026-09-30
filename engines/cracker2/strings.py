from __future__ import annotations

import re
import math
from dataclasses import dataclass, field
from typing import List, Dict, Set, Optional, Tuple
from ast_nodes import (
    ASTNode,
    Program,
    Block,
    Statement,
    Expression,
    StringLiteral,
    TableConstructor,
    TableField,
    CallExpr,
    BinaryExpr,
    UnaryExpr,
    LocalAssign,
    Assign,
    FunctionDef,
    LocalFunctionDef,
    IfStatement,
    WhileStatement,
    RepeatStatement,
    ForNumeric,
    ForGeneric,
    DoBlock,
    ReturnStatement,
    CallStatement,
    IndexExpr,
    MemberExpr,
    MethodCallExpr,
    ParenthesizedExpr,
    IfExpr,
)
from constants import fold_expression, ConstantEvaluator


COMMON_SHORT_WORDS: Set[str] = {
    "on", "in", "to", "at", "id", "ip", "no", "ok", "go", "up", "by", "if", "or", "as", "is", "it", "my", "we", "he", "me"
}

NOISE_STRINGS: Set[str] = {
    "__index",
    "__newindex",
    "__call",
    "__metatable",
    "__tostring",
    "__add",
    "__sub",
    "__mul",
    "__div",
    "__mod",
    "__pow",
    "__unm",
    "__concat",
    "__len",
    "__eq",
    "__lt",
    "__le",
    "__mode",
}

ROBLOX_SERVICES: Set[str] = {
    "Workspace",
    "Players",
    "Lighting",
    "ReplicatedStorage",
    "ReplicatedFirst",
    "ServerStorage",
    "ServerScriptService",
    "StarterGui",
    "StarterPack",
    "StarterPlayer",
    "SoundService",
    "Chat",
    "TextChatService",
    "TweenService",
    "UserInputService",
    "RunService",
    "HttpService",
    "MarketplaceService",
    "TeleportService",
}


@dataclass
class StringOccurrence:
    value: str
    line: int
    column: int
    source_kind: str  # 'STATIC', 'CONSTANT_FOLDED', 'TABLE_KEY', 'TABLE_VAL', 'CONTAINER'
    is_meaningful: bool
    context: Optional[str] = None


@dataclass
class StringRecoveryResult:
    all_strings: List[str]
    meaningful_strings: List[str]
    technical_strings: List[str]
    occurrences: List[StringOccurrence]
    string_counts: Dict[str, int]


class StringClassifier:
    @staticmethod
    def calculate_entropy(text: str) -> float:
        if not text:
            return 0.0
        prob = [float(text.count(c)) / len(text) for c in set(text)]
        return -sum(p * math.log2(p) for p in prob)

    @classmethod
    def is_meaningful(cls, val: str) -> bool:
        if not val:
            return False

        stripped = val.strip()
        if not stripped:
            return False

        # Filter out Luraph / obfuscator encrypted container blobs
        if stripped.startswith("LPH$") or stripped.startswith("LPH:") or len(stripped) > 500:
            return False

        # Filter out regex patterns and format strings
        if stripped.startswith(":[") or stripped.startswith(":(%") or stripped.startswith("[ -"):
            return False

        # Filter out 1-character strings
        if len(stripped) == 1:
            return False

        # Filter out 2-character obfuscator keys (e.g. C4, h4, Xq, rq, qq, v4, z4, Wq, Zq, mq, F4, bq, e4, S4, Nq, Rq, Gq, tq, eq, Qq, q4, x4, K4, X4, s4, L4, Tq, Bq, Dq, Mq, uq, CP, pq, Y4, y4, n4, Sq, gq, lq, t4, cP, w4, g4, d4, yq, Cq, I4, Jq, Vq, aq, Lq, _q, Hq, kq, l4, i4, Yq, f4, H4, Pq, wq, a4, nq, Oq, oq, Iq, Z4, Kq, hq, Uq, jq, m4, cq, vq, E4, xq, dq, Fq, b4, Eq, o4, J4, Q4, lP, c4, G4, V4, O4, j4, Aq, M4, B4, W4, _4, T4, fq, A4, U4, sq, P4, iq)
        if len(stripped) == 2:
            if stripped.lower() in COMMON_SHORT_WORDS:
                return True
            # Obfuscation pattern check: letter+number, letter+'q', letter+'4', uppercase pairs
            if re.match(r"^[A-Za-z][0-9qP4_]$", stripped) or re.match(r"^[A-Z]{2}$", stripped):
                return False
            if not stripped.isalpha():
                return False

        # Filter out punctuation-only strings (e.g. "$", "#", "{", "|", '"', "}", "!", "~", "%", "?", ":", "_")
        if all(not c.isalnum() and not c.isspace() for c in stripped):
            return False

        # URLs and web addresses are high value
        if stripped.startswith("http://") or stripped.startswith("https://") or "discord.com" in stripped or "lura.ph" in stripped:
            return True

        # Roblox services
        if stripped in ROBLOX_SERVICES:
            return True

        # Natural language phrases with spaces and letters (e.g. "hello jack", "Loading script", "Access denied")
        if " " in stripped and any(c.isalpha() for c in stripped):
            # Check for reasonable alphanumeric content
            alphanumeric_count = sum(1 for c in stripped if c.isalnum() or c.isspace())
            if alphanumeric_count / len(stripped) >= 0.7:
                return True

        # Filter out random high-entropy hash strings (e.g. 9TM`6, G^MbL, vWw2j, hMM5-, lN7Je, XqbTM, PpcwB, hR8Fx, Jpc0k, 5kwJC, 6itTIlrqvj, etc.)
        # These are short strings with special chars or mixed cases having high entropy and non-word structure
        if len(stripped) <= 12 and any(c in "`^~|/\\&%$#@!*+;:<=>?" for c in stripped):
            return False

        # Words with letters
        letters = sum(1 for c in stripped if c.isalpha())
        digits = sum(1 for c in stripped if c.isdigit())
        total = len(stripped)

        # Filter out random mixed-case / interleaved-digit hash tokens (e.g. vWw2j, lN7Je, hR8Fx, Jpc0k, 5kwJC)
        if any(c.isdigit() for c in stripped) and any(c.isalpha() for c in stripped):
            if not stripped.endswith("32") and not stripped.endswith("64") and not stripped.endswith("128"):
                return False

        # Standard words (e.g. 'string', 'table', 'username', 'print', 'message', 'player')
        if total >= 3:
            if letters == total:
                # Check for clean casing: all lower, all upper, TitleCase, or camelCase
                if stripped.islower() or stripped.isupper():
                    has_vowels = any(c.lower() in "aeiouy" for c in stripped)
                    return has_vowels or total <= 4
                if stripped.istitle():
                    return True
                # CamelCase check
                if re.match(r"^[a-z]+[A-Z][a-z]+", stripped):
                    return True
                return False

            # Alphanumeric identifiers like player_1, item_123, button_click
            if letters >= 3 and (letters + digits) / total >= 0.8:
                if "_" in stripped:
                    return True

        return False


class StringCatalog:
    def __init__(self):
        self.occurrences: List[StringOccurrence] = []
        self.seen_values: Set[str] = set()

    def add(self, value: str, line: int = 1, column: int = 1, source_kind: str = "STATIC", context: Optional[str] = None):
        if not isinstance(value, str):
            return
        is_meaningful = StringClassifier.is_meaningful(value)
        self.occurrences.append(
            StringOccurrence(
                value=value,
                line=line,
                column=column,
                source_kind=source_kind,
                is_meaningful=is_meaningful,
                context=context,
            )
        )
        self.seen_values.add(value)

    def extract_from_ast(self, node: ASTNode):
        """Walk the AST to extract all static and folded string literals."""
        if node is None:
            return

        if isinstance(node, StringLiteral):
            self.add(node.value, line=node.line, column=node.column, source_kind="STATIC")
            return

        # Constant fold expressions to see if they yield strings (e.g. "hel" .. "lo")
        if isinstance(node, Expression):
            ok, val = ConstantEvaluator.eval_expr(node)
            if ok and isinstance(val, str):
                self.add(val, line=node.line, column=node.column, source_kind="CONSTANT_FOLDED")

        # Walk children recursively
        if hasattr(node, "__dict__"):
            for k, v in node.__dict__.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, ASTNode):
                            self.extract_from_ast(item)
                elif isinstance(v, ASTNode):
                    self.extract_from_ast(v)

    def build_result(self) -> StringRecoveryResult:
        dedup_all: List[str] = []
        dedup_meaningful: List[str] = []
        dedup_technical: List[str] = []
        counts: Dict[str, int] = {}
        seen: Set[str] = set()

        for occ in self.occurrences:
            val = occ.value
            counts[val] = counts.get(val, 0) + 1
            if val not in seen:
                seen.add(val)
                dedup_all.append(val)
                if occ.is_meaningful:
                    dedup_meaningful.append(val)
                else:
                    dedup_technical.append(val)

        return StringRecoveryResult(
            all_strings=dedup_all,
            meaningful_strings=dedup_meaningful,
            technical_strings=dedup_technical,
            occurrences=self.occurrences,
            string_counts=counts,
        )

    def format_strings_txt(self, meaningful_only: bool = True) -> str:
        """Format human-readable strings, one per line (meaningful/clean strings only)."""
        res = self.build_result()
        target_list = res.meaningful_strings if meaningful_only and res.meaningful_strings else res.all_strings
        lines = []
        for s in target_list:
            clean_s = s.replace("\r\n", " ").replace("\n", " ").strip()
            if clean_s:
                lines.append(clean_s)
        return "\n".join(lines) + ("\n" if lines else "")


def extract_strings(program: Program) -> StringRecoveryResult:
    catalog = StringCatalog()
    catalog.extract_from_ast(program)
    return catalog.build_result()
