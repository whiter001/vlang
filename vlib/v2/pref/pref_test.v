// Copyright (c) 2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
// vtest build: !windows
module pref

fn test_backend_enum() {
	_ = Backend.v
	_ = Backend.cleanc
	_ = Backend.x64
	_ = Backend.arm64
}

fn test_arch_enum() {
	_ = Arch.auto
	_ = Arch.x64
	_ = Arch.arm64
}

fn test_preferences_default_values() {
	p := Preferences{}
	assert p.debug == false
	assert p.verbose == false
	assert p.skip_genv == false
	assert p.skip_builtin == false
	assert p.skip_imports == false
	assert p.skip_type_check == false
	assert p.no_parallel == true
	assert p.keep_c == false
	assert p.use_context_allocator == false
	assert p.backend == Backend.v
	assert p.arch == Arch.auto
}

fn test_preferences_backend() {
	mut p := Preferences{}
	p.backend = Backend.cleanc
	assert p.backend == Backend.cleanc

	p.backend = Backend.x64
	assert p.backend == Backend.x64

	p.backend = Backend.arm64
	assert p.backend == Backend.arm64
}

fn test_preferences_arch() {
	mut p := Preferences{}
	p.arch = Arch.x64
	assert p.arch == Arch.x64

	p.arch = Arch.arm64
	assert p.arch == Arch.arm64
}

fn test_preferences_debug_mode() {
	mut p := Preferences{}
	p.debug = true
	assert p.debug == true

	p.debug = false
	assert p.debug == false
}

fn test_preferences_output_file() {
	mut p := Preferences{}
	p.output_file = 'my_output'
	assert p.output_file == 'my_output'
}

fn test_preferences_verbose() {
	mut p := Preferences{}
	p.verbose = true
	assert p.verbose == true
}
