// Copyright (c) 2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
// vtest build: !windows
module token

fn test_token_enum_values() {
	_ = Token.amp
	_ = Token.and
	_ = Token.assign
	_ = Token.number
	_ = Token.name
	_ = Token.string
	_ = Token.lcbr
	_ = Token.rcbr
	_ = Token.lpar
	_ = Token.rpar
	_ = Token.eof
}

fn test_token_is_assignment() {
	assert !Token.amp.is_assignment()
	assert Token.assign.is_assignment()
	assert Token.decl_assign.is_assignment()
	assert Token.plus_assign.is_assignment()
	assert Token.minus_assign.is_assignment()
	assert Token.mul_assign.is_assignment()
	assert Token.div_assign.is_assignment()
}

fn test_token_is_comparison() {
	assert !Token.amp.is_comparison()
	assert Token.eq.is_comparison()
	assert Token.ne.is_comparison()
	assert Token.lt.is_comparison()
	assert Token.le.is_comparison()
	assert Token.gt.is_comparison()
	assert Token.ge.is_comparison()
}

fn test_token_is_unary() {
	assert Token.not.is_unary()
	assert Token.bit_not.is_unary()
	assert Token.plus.is_unary()
	assert Token.minus.is_unary()
}

fn test_token_is_binary() {
	assert Token.plus.is_binary()
	assert Token.minus.is_binary()
	assert Token.mul.is_binary()
	assert Token.div.is_binary()
}

fn test_binding_power() {
	assert Token.logical_or.left_binding_power() == BindingPower.lowest
	assert Token.and.left_binding_power() == BindingPower.one
	assert Token.plus.left_binding_power() == BindingPower.three
	assert Token.mul.left_binding_power() == BindingPower.four
}

fn test_binding_power_comparison() {
	assert Token.eq.left_binding_power() == BindingPower.two
	assert Token.ne.left_binding_power() == BindingPower.two
	assert Token.lt.left_binding_power() == BindingPower.two
}

fn test_binding_power_shift() {
	assert Token.left_shift.left_binding_power() == BindingPower.two
	assert Token.right_shift.left_binding_power() == BindingPower.two
}

fn test_token_keyword_detection() {
	assert Token.key_fn.is_keyword()
	assert Token.key_if.is_keyword()
	assert Token.key_else.is_keyword()
	assert Token.key_for.is_keyword()
	assert Token.key_match.is_keyword()
	assert Token.key_return.is_keyword()
}

fn test_token_string_representation() {
	assert Token.plus.str() == '+'
	assert Token.minus.str() == '-'
	assert Token.mul.str() == '*'
	assert Token.div.str() == '/'
}

fn test_fileset_new() {
	fs := FileSet.new()
	assert fs.len() == 0
}

fn test_fileset_add_file() {
	fs := FileSet.new()
	f := fs.add_file('test.v', -1, 100)
	assert f.name == 'test.v'
}

fn test_position() {
	pos := Pos{
		line: 10
		col: 5
		pos: 100
	}
	assert pos.line == 10
	assert pos.col == 5
	assert pos.pos == 100
}
