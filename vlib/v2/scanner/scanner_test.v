// Copyright (c) 2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
// vtest build: !windows
module scanner

import v2.pref
import v2.token

fn new_test_scanner() &Scanner {
	p := unsafe { &pref.Preferences{} }
	return new_scanner(p, .normal)
}

fn test_scan_number() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, '12345')

	tok := s.scan()
	assert tok == .number
	assert s.lit == '12345'
}

fn test_scan_identifier() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, 'hello')

	tok := s.scan()
	assert tok == .name
	assert s.lit == 'hello'
}

fn test_scan_keyword_fn() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, 'fn')

	tok := s.scan()
	assert tok == .key_fn
}

fn test_scan_keyword_if() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, 'if')

	tok := s.scan()
	assert tok == .key_if
}

fn test_scan_string() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 20)
	s.init(f, '"hello world"')

	tok := s.scan()
	assert tok == .string
}

fn test_scan_operators() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 50)
	s.init(f, '+ - * / %')

	t1 := s.scan()
	assert t1 == .plus
	t2 := s.scan()
	assert t2 == .minus
	t3 := s.scan()
	assert t3 == .mul
	t4 := s.scan()
	assert t4 == .div
	t5 := s.scan()
	assert t5 == .mod
}

fn test_scan_comparison_operators() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 20)
	s.init(f, '== != < > <= >=')

	assert s.scan() == .eq
	assert s.scan() == .ne
	assert s.scan() == .lt
	assert s.scan() == .gt
	assert s.scan() == .le
	assert s.scan() == .ge
}

fn test_scan_assignment() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 20)
	s.init(f, '= := += -=')

	assert s.scan() == .assign
	assert s.scan() == .decl_assign
	assert s.scan() == .plus_assign
	assert s.scan() == .minus_assign
}

fn test_scan_punctuation() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 20)
	s.init(f, '( ) [ ] { } , ; :')

	assert s.scan() == .lpar
	assert s.scan() == .rpar
	assert s.scan() == .lsbr
	assert s.scan() == .rsbr
	assert s.scan() == .lcbr
	assert s.scan() == .rcbr
	assert s.scan() == .comma
	assert s.scan() == .semicolon
	assert s.scan() == .colon
}

fn test_scan_hex_number() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, '0xFF')

	tok := s.scan()
	assert tok == .number
	assert s.lit == '0xFF'
}

fn test_scan_float_number() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, '3.14')

	tok := s.scan()
	assert tok == .number
	assert s.lit == '3.14'
}

fn test_scan_arrow() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 5)
	s.init(f, '<-')

	tok := s.scan()
	assert tok == .arrow
}

fn test_scan_dotdot() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 5)
	s.init(f, '..')

	tok := s.scan()
	assert tok == .dotdot
}

fn test_scan_ellipsis() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 5)
	s.init(f, '...')

	tok := s.scan()
	assert tok == .ellipsis
}

fn test_scan_logical_operators() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, '|| && !')

	assert s.scan() == .logical_or
	assert s.scan() == .and
	assert s.scan() == .not
}

fn test_scan_multiple_identifiers() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 30)
	s.init(f, 'foo bar baz')

	assert s.scan() == .name
	assert s.lit == 'foo'
	assert s.scan() == .name
	assert s.lit == 'bar'
	assert s.scan() == .name
	assert s.lit == 'baz'
}

fn test_scan_increment_decrement() {
	mut s := new_test_scanner()
	mut fs := token.FileSet.new()
	f := fs.add_file('test.v', -1, 10)
	s.init(f, '++ --')

	assert s.scan() == .inc
	assert s.scan() == .dec
}
