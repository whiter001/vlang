// Test that assert with generic optional pointer comparison to none compiles correctly.
// Regression test for https://github.com/vlang/v/issues/26425

struct Foo[T] {
}

pub fn (self Foo[T]) bar() ?&Foo[T] {
	return none
}

pub fn (self Foo[T]) baz() ?&Foo[T] {
	return &self
}

fn test_generic_optional_ptr_assert_none() {
	assert Foo[int]{}.bar() == none
}

fn test_generic_optional_ptr_assert_not_none() {
	f := Foo[int]{}
	assert f.baz() != none
}
