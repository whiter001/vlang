// Test that @[minify] structs with optional enum fields compile correctly.
// Regression test for https://github.com/vlang/v/issues/26622

pub enum MyMode as u8 {
	inherit
	a
	b
}

@[minify]
struct Cfg {
	mode ?MyMode
	ok   bool
}

fn test_minify_struct_with_optional_enum() {
	cfg := Cfg{}
	assert cfg.ok == false
	assert cfg.mode == none
	cfg2 := Cfg{
		mode: .a
		ok: true
	}
	assert cfg2.ok == true
	assert cfg2.mode? == .a
}
