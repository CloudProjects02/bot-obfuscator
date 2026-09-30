from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional, List, Set, Tuple


@dataclass(frozen=True)
class Token:
    kind: str
    value: str
    position: int
    line: int
    column: int
    raw: Optional[str] = None


KEYWORDS: Set[str] = {
    "and",
    "break",
    "continue",
    "do",
    "else",
    "elseif",
    "end",
    "export",
    "false",
    "for",
    "function",
    "if",
    "in",
    "local",
    "nil",
    "not",
    "or",
    "repeat",
    "return",
    "then",
    "true",
    "type",
    "until",
    "while",
}

MULTI_OPERATORS: Tuple[str, ...] = (
    "...",
    "::",
    "==",
    "~=",
    "<=",
    ">=",
    "..=",
    "+=",
    "-=",
    "*=",
    "/=",
    "//=",
    "%=",
    "^=",
    "&=",
    "|=",
    "<<=",
    ">>=",
    "..",
    "//",
    "<<",
    ">>",
    "->",
)

SINGLE_OPERATORS: Set[str] = set(
    "+-*/%^#=<>~&|(){}[];:,.@"
)


class LexerError(Exception):
    def __init__(self, message: str, line: int = 1, column: int = 1):
        super().__init__(f"{message} at line {line}, column {column}")
        self.raw_message = message
        self.line = line
        self.column = column


class Lexer:
    def __init__(self, source: str):
        self.source = source
        self.length = len(source)
        self.index = 0
        self.line = 1
        self.column = 1

    def _advance(self, count: int = 1) -> str:
        text = self.source[self.index : self.index + count]
        for char in text:
            if char == "\n":
                self.line += 1
                self.column = 1
            else:
                self.column += 1
        self.index += count
        return text

    def _peek(self, count: int = 1, offset: int = 0) -> str:
        start = self.index + offset
        return self.source[start : start + count]

    def _emit(
        self,
        kind: str,
        value: str,
        position: int,
        line: int,
        column: int,
        raw: Optional[str] = None,
    ) -> Token:
        return Token(
            kind=kind,
            value=value,
            position=position,
            line=line,
            column=column,
            raw=raw if raw is not None else value,
        )

    def _read_long_bracket(self) -> Optional[Token]:
        start = self.index
        start_line = self.line
        start_column = self.column

        if self.index >= self.length or self.source[self.index] != "[":
            return None

        cursor = self.index + 1
        equals = 0
        while cursor < self.length and self.source[cursor] == "=":
            equals += 1
            cursor += 1

        if cursor >= self.length or self.source[cursor] != "[":
            return None

        opener_length = cursor - self.index + 1
        self._advance(opener_length)

        # In Lua, the first newline following a long bracket open is ignored
        if self.index < self.length and self.source[self.index] == "\r":
            self._advance()
            if self.index < self.length and self.source[self.index] == "\n":
                self._advance()
        elif self.index < self.length and self.source[self.index] == "\n":
            self._advance()

        content_start = self.index
        close = "]" + ("=" * equals) + "]"
        end = self.source.find(close, self.index)

        if end == -1:
            raise LexerError("Unterminated long string", start_line, start_column)

        value = self.source[content_start:end]
        raw_text = self.source[start : end + len(close)]
        self._advance(end - self.index)
        self._advance(len(close))

        return self._emit(
            "STRING",
            value,
            start,
            start_line,
            start_column,
            raw=raw_text,
        )

    def _read_short_string(self) -> Token:
        start = self.index
        line = self.line
        column = self.column
        quote = self.source[self.index]
        self._advance()

        chars: List[str] = []
        escapes = {
            "n": "\n",
            "r": "\r",
            "t": "\t",
            "b": "\b",
            "f": "\f",
            "v": "\v",
            "a": "\a",
            "\\": "\\",
            '"': '"',
            "'": "'",
            "0": "\0",
        }

        while self.index < self.length:
            char = self.source[self.index]

            if char == quote:
                self._advance()
                raw_text = self.source[start : self.index]
                return self._emit(
                    "STRING",
                    "".join(chars),
                    start,
                    line,
                    column,
                    raw=raw_text,
                )

            if char in "\r\n":
                raise LexerError("Unterminated string literal", line, column)

            if char == "\\":
                self._advance()
                if self.index >= self.length:
                    raise LexerError("Unterminated escape sequence", line, column)

                escaped = self.source[self.index]

                if escaped in escapes:
                    chars.append(escapes[escaped])
                    self._advance()
                    continue

                if escaped == "z":
                    # Lua 5.2+ / Luau \z skips whitespace until next non-whitespace
                    self._advance()
                    while self.index < self.length and self.source[self.index].isspace():
                        self._advance()
                    continue

                if escaped == "x":
                    self._advance()
                    hex_digits = self._peek(2)
                    if len(hex_digits) == 2 and all(c in "0123456789abcdefABCDEF" for c in hex_digits):
                        chars.append(chr(int(hex_digits, 16)))
                        self._advance(2)
                        continue
                    else:
                        chars.append("x")
                        continue

                if escaped == "u":
                    # Lua 5.3+ / Luau \u{XXXX}
                    if self._peek(1, 1) == "{":
                        self._advance(2)
                        hex_buf = []
                        while self.index < self.length and self.source[self.index] != "}":
                            c = self.source[self.index]
                            if c in "0123456789abcdefABCDEF":
                                hex_buf.append(c)
                                self._advance()
                            else:
                                break
                        if self.index < self.length and self.source[self.index] == "}":
                            self._advance()
                            try:
                                codepoint = int("".join(hex_buf), 16)
                                chars.append(chr(codepoint))
                                continue
                            except (ValueError, OverflowError):
                                chars.append("\ufffd")
                                continue

                if escaped.isdigit():
                    digits = []
                    for _ in range(3):
                        if self.index < self.length and self.source[self.index].isdigit():
                            digits.append(self.source[self.index])
                            self._advance()
                        else:
                            break
                    if digits:
                        val = int("".join(digits), 10)
                        if val > 255:
                            val = 255
                        chars.append(chr(val))
                        continue

                chars.append(escaped)
                self._advance()
                continue

            chars.append(char)
            self._advance()

        raise LexerError("Unterminated string literal", line, column)

    def _read_interpolated_string(self) -> Token:
        # Luau string interpolation: `...`
        start = self.index
        line = self.line
        column = self.column
        self._advance()  # Skip opening backtick

        chars: List[str] = []
        while self.index < self.length:
            char = self.source[self.index]
            if char == "`":
                self._advance()
                raw_text = self.source[start : self.index]
                return self._emit(
                    "INTERPOLATED_STRING",
                    "".join(chars),
                    start,
                    line,
                    column,
                    raw=raw_text,
                )
            if char == "\\" and self.index + 1 < self.length:
                chars.append(self.source[self.index : self.index + 2])
                self._advance(2)
                continue
            chars.append(char)
            self._advance()

        raise LexerError("Unterminated interpolated string", line, column)

    def _read_number(self) -> Token:
        start = self.index
        line = self.line
        column = self.column

        # Hexadecimal (0x / 0X) or Binary (0b / 0B)
        peek_prefix = self._peek(2).lower()
        if peek_prefix in ("0x", "0b"):
            self._advance(2)
            while self.index < self.length:
                char = self.source[self.index]
                if char.isalnum() or char in "._":
                    self._advance()
                else:
                    break
            raw_text = self.source[start : self.index]
            return self._emit("NUMBER", raw_text, start, line, column, raw=raw_text)

        # Standard decimal / float / scientific notation
        has_dot = False
        has_exp = False
        while self.index < self.length:
            char = self.source[self.index]
            if char.isdigit() or char == "_":
                self._advance()
                continue
            if char == "." and not has_dot and not has_exp:
                # Distinguish from .. operator
                if self._peek(2) == "..":
                    break
                has_dot = True
                self._advance()
                continue
            if char in "eE" and not has_exp:
                has_exp = True
                self._advance()
                if self.index < self.length and self.source[self.index] in "+-":
                    self._advance()
                continue
            break

        raw_text = self.source[start : self.index]
        return self._emit("NUMBER", raw_text, start, line, column, raw=raw_text)

    def _read_identifier(self) -> Token:
        start = self.index
        line = self.line
        column = self.column
        self._advance()

        while self.index < self.length:
            char = self.source[self.index]
            if char.isalnum() or char == "_":
                self._advance()
            else:
                break

        value = self.source[start : self.index]
        kind = "KEYWORD" if value in KEYWORDS else "IDENT"
        return self._emit(kind, value, start, line, column, raw=value)

    def tokenize(self) -> List[Token]:
        tokens: List[Token] = []

        while self.index < self.length:
            char = self.source[self.index]

            if char.isspace():
                self._advance()
                continue

            start = self.index
            line = self.line
            column = self.column

            # Comments
            if self.source.startswith("--", self.index):
                self._advance(2)
                # Check for long comment --[[ ... ]]
                if self.index < self.length and self.source[self.index] == "[":
                    saved_index = self.index
                    saved_line = self.line
                    saved_column = self.column
                    try:
                        token = self._read_long_bracket()
                        if token is not None:
                            continue
                    except LexerError:
                        self.index = saved_index
                        self.line = saved_line
                        self.column = saved_column

                # Single line comment: advance to newline
                while self.index < self.length and self.source[self.index] not in "\r\n":
                    self._advance()
                continue

            # Short string literals
            if char in "\"'":
                tokens.append(self._read_short_string())
                continue

            # Luau string interpolations
            if char == "`":
                tokens.append(self._read_interpolated_string())
                continue

            # Long string literals
            if char == "[":
                token = self._read_long_bracket()
                if token is not None:
                    tokens.append(token)
                    continue

            # Number literals
            if char.isdigit():
                tokens.append(self._read_number())
                continue

            if char == "." and self.index + 1 < self.length and self.source[self.index + 1].isdigit():
                tokens.append(self._read_number())
                continue

            # Identifiers and keywords
            if char.isalpha() or char == "_":
                tokens.append(self._read_identifier())
                continue

            # Multi-character operators
            matched = False
            for operator in MULTI_OPERATORS:
                if self.source.startswith(operator, self.index):
                    self._advance(len(operator))
                    tokens.append(
                        self._emit("OP", operator, start, line, column, raw=operator)
                    )
                    matched = True
                    break
            if matched:
                continue

            # Single-character operators
            if char in SINGLE_OPERATORS:
                self._advance()
                tokens.append(
                    self._emit("OP", char, start, line, column, raw=char)
                )
                continue

            # Unknown character fallback
            self._advance()
            tokens.append(
                self._emit("UNKNOWN", char, start, line, column, raw=char)
            )

        tokens.append(
            Token(
                kind="EOF",
                value="",
                position=self.index,
                line=self.line,
                column=self.column,
                raw="",
            )
        )

        return tokens


def tokenize(source: str) -> List[Token]:
    return Lexer(source).tokenize()