from __future__ import annotations

import unittest
from pathlib import Path
import tempfile
import shutil

from lexer import tokenize
from structure import parse
from constants import fold_expression, ConstantEvaluator
from strings import extract_strings, StringCatalog
from optimizer import optimize_ast
from codegen import generate_lua
from ir import build_ir
from cfg import build_cfg_for_functions
from anti_analysis import detect_anti_analysis
from vm_detector import detect_vm
from lph import LPHDetector


class TestCracker2Pipeline(unittest.TestCase):

    def test_simple_print(self):
        code = 'print("hello")'
        tokens = tokenize(code)
        prog = parse(tokens)
        strings_res = extract_strings(prog)
        self.assertIn("hello", strings_res.all_strings)
        opt_prog = optimize_ast(prog)
        out_lua = generate_lua(opt_prog).strip()
        self.assertEqual(out_lua, 'print("hello")')

    def test_multiple_arguments(self):
        code = 'print("hello", "jack")'
        tokens = tokenize(code)
        prog = parse(tokens)
        strings_res = extract_strings(prog)
        self.assertIn("hello", strings_res.all_strings)
        self.assertIn("jack", strings_res.all_strings)
        out_lua = generate_lua(prog).strip()
        self.assertEqual(out_lua, 'print("hello", "jack")')

    def test_string_concatenation_folding(self):
        code = 'local x = "hel" .. "lo"\nprint(x)'
        tokens = tokenize(code)
        prog = parse(tokens)
        opt_prog = optimize_ast(prog)
        strings_res = extract_strings(opt_prog)
        self.assertIn("hello", strings_res.all_strings)
        out_lua = generate_lua(opt_prog).strip()
        self.assertIn('local x = "hello"', out_lua)
        # Constant propagation may fold print(x) to print("hello")
        self.assertTrue('print("hello")' in out_lua or 'print(x)' in out_lua)

    def test_constant_arithmetic_and_bitwise_folding(self):
        code = 'local a = 10 + 20\nlocal b = bit32.band(255, 15)'
        tokens = tokenize(code)
        prog = parse(tokens)
        opt_prog = optimize_ast(prog)
        out_lua = generate_lua(opt_prog).strip()
        self.assertIn('local a = 30', out_lua)
        self.assertIn('local b = 15', out_lua)

    def test_named_function(self):
        code = 'local function test()\n    return "hello"\nend'
        tokens = tokenize(code)
        prog = parse(tokens)
        strings_res = extract_strings(prog)
        self.assertIn("hello", strings_res.all_strings)
        out_lua = generate_lua(prog).strip()
        self.assertIn("local function test()", out_lua)
        self.assertIn('return "hello"', out_lua)

    def test_nested_closures_and_upvalues(self):
        code = '''local function outer()
    local x = "hello"
    return function()
        return x
    end
end'''
        tokens = tokenize(code)
        prog = parse(tokens)
        strings_res = extract_strings(prog)
        self.assertIn("hello", strings_res.all_strings)
        out_lua = generate_lua(prog).strip()
        self.assertIn("local function outer()", out_lua)
        self.assertIn('local x = "hello"', out_lua)
        self.assertIn("function()", out_lua)
        self.assertIn("return x", out_lua)

    def test_boolean_simplification_and_dead_branches(self):
        code = '''if true then
    print("hello")
else
    print("wrong")
end'''
        tokens = tokenize(code)
        prog = parse(tokens)
        opt_prog = optimize_ast(prog)
        out_lua = generate_lua(opt_prog).strip()
        self.assertIn('print("hello")', out_lua)
        self.assertNotIn('print("wrong")', out_lua)

    def test_table_constructors(self):
        code = '''local t = {
    "hello",
    "jack",
    "world"
}'''
        tokens = tokenize(code)
        prog = parse(tokens)
        strings_res = extract_strings(prog)
        self.assertIn("hello", strings_res.all_strings)
        self.assertIn("jack", strings_res.all_strings)
        self.assertIn("world", strings_res.all_strings)

    def test_anti_analysis_detection(self):
        code = '''local env = getfenv()
debug.getinfo(1)
setmetatable({}, { __index = env })'''
        tokens = tokenize(code)
        prog = parse(tokens)
        report = detect_anti_analysis(prog, code)
        self.assertTrue(report.debug_inspection)
        self.assertTrue(report.environment_checks)
        self.assertTrue(report.metatable_tampering)

    def test_ir_and_cfg_generation(self):
        code = '''local x = 10
while x > 0 do
    x = x - 1
end'''
        tokens = tokenize(code)
        prog = parse(tokens)
        ir_fns = build_ir(prog)
        self.assertTrue(len(ir_fns) >= 1)
        cfg_list = build_cfg_for_functions(ir_fns)
        self.assertTrue(len(cfg_list) >= 1)
        self.assertTrue(len(cfg_list[0].blocks) >= 2)

    def test_hello_lua_file(self):
        hello_path = Path(__file__).resolve().parent / "hello.lua"
        if hello_path.exists():
            code = hello_path.read_text(encoding="utf-8")
            tokens = tokenize(code)
            prog = parse(tokens)
            strings_res = extract_strings(prog)
            self.assertIn("hello jack", strings_res.all_strings)
            out_lua = generate_lua(prog).strip()
            self.assertEqual(out_lua, 'print("hello jack")')

    def test_obfuscated_lua_file(self):
        obf_path = Path(__file__).resolve().parent / "obfuscated.lua"
        if obf_path.exists():
            code = obf_path.read_text(encoding="utf-8")
            tokens = tokenize(code)
            self.assertTrue(len(tokens) > 1000)
            containers = LPHDetector.find_containers(code)
            self.assertTrue(len(containers) >= 1)
            vm_report = detect_vm(parse(tokens), code)
            self.assertTrue(vm_report.vm_detected)

    def test_bytecode_compilation(self):
        from compiler import LuaCompiler
        code = 'local message = "hello world"\nprint(message)'
        tokens = tokenize(code)
        prog = parse(tokens)
        compiler = LuaCompiler()
        bc = compiler.compile(prog)
        self.assertTrue(bc.startswith(b"\x1bLua\x51"))
        self.assertTrue(len(bc) > 30)


if __name__ == "__main__":
    unittest.main()
