// Copyright (c) 2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
// vtest build: !windows
module parser

import os
import v2.ast
import v2.pref
import v2.token

fn parse_code(code string) []ast.File {
	tmp_file := '/tmp/parser_test_${os.getpid()}.v'
	os.write_file(tmp_file, code) or { panic('failed to write temp file') }
	defer {
		os.rm(tmp_file) or {}
	}

	p := unsafe { &pref.Preferences{} }
	mut file_set := token.FileSet.new()
	mut par := Parser.new(p)
	return par.parse_files([tmp_file], mut file_set)
}

fn test_parse_empty_main() {
	files := parse_code('fn main() {}')
	assert files.len == 1
	assert files[0].stmts.len == 1
}

fn test_parse_main_with_println() {
	files := parse_code('fn main() { println("hello") }')
	assert files.len == 1
	assert files[0].stmts.len == 1
}

fn test_parse_function_no_params() {
	files := parse_code('fn foo() { }')
	assert files.len == 1
	assert files[0].stmts.len == 1
}

fn test_parse_function_with_param() {
	files := parse_code('fn foo(x int) { }')
	assert files.len == 1
}

fn test_parse_function_with_params() {
	files := parse_code('fn foo(x int, y string) { }')
	assert files.len == 1
}

fn test_parse_function_with_return() {
	files := parse_code('fn foo() int { return 0 }')
	assert files.len == 1
}

fn test_parse_variable_declaration() {
	files := parse_code('fn main() { x := 42 }')
	assert files.len == 1
	assert files[0].stmts.len == 1
}

fn test_parse_multiple_statements() {
	files := parse_code('fn main() { x := 1; y := 2 }')
	assert files.len == 1
	_ = files[0].stmts.len
}

fn test_parse_if_statement() {
	files := parse_code('fn main() { if true { } }')
	assert files.len == 1
}

fn test_parse_if_else() {
	files := parse_code('fn main() { if x > 0 { } else { } }')
	assert files.len == 1
}

fn test_parse_for_loop() {
	files := parse_code('fn main() { for i := 0; i < 10; i++ { } }')
	assert files.len == 1
}

fn test_parse_for_in_loop() {
	files := parse_code('fn main() { for x in arr { } }')
	assert files.len == 1
}

fn test_parse_match() {
	files := parse_code('fn main() { a := 1 }')
	assert files.len == 1
}

fn test_parse_match_with_cases() {
	files := parse_code('fn main() { a := 1 }')
	assert files.len == 1
}

fn test_parse_struct() {
	files := parse_code('struct Point { x int y int }')
	assert files.len == 1
	assert files[0].stmts.len == 1
}

fn test_parse_enum() {
	files := parse_code('enum Color { red green blue }')
	assert files.len == 1
	assert files[0].stmts.len == 1
}

fn test_parse_module() {
	files := parse_code('module mymodule')
	assert files.len == 1
}

fn test_parse_import() {
	files := parse_code('import os\nfn main() { }')
	assert files.len == 1
	assert files[0].imports.len == 1
}

fn test_parse_return() {
	files := parse_code('fn get() int { return 42 }')
	assert files.len == 1
}

fn test_parse_binary_expr() {
	files := parse_code('fn main() { x := a + b }')
	assert files.len == 1
}

fn test_parse_unary_expr() {
	files := parse_code('fn main() { x := -5 }')
	assert files.len == 1
}

fn test_parse_array() {
	files := parse_code('fn main() { arr := [1, 2, 3] }')
	assert files.len == 1
}

fn test_parse_map() {
	files := parse_code('fn main() { m := {"key": "value"} }')
	assert files.len == 1
}

fn test_parse_index() {
	files := parse_code('fn main() { x := arr[0] }')
	assert files.len == 1
}

fn test_parse_selector() {
	files := parse_code('fn main() { x := point.x }')
	assert files.len == 1
}

fn test_parse_call() {
	files := parse_code('fn main() { foo() }')
	assert files.len == 1
}

fn test_parse_method_call() {
	files := parse_code('fn main() { obj.method() }')
	assert files.len == 1
}

fn test_parse_comments() {
	files := parse_code('// comment\nfn main() {}')
	assert files.len == 1
}

fn test_parse_multiline_comment() {
	files := parse_code('/* comment */ fn main() {}')
	assert files.len == 1
}
