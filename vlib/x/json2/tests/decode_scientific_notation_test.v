import x.json2 as json

// Test that JSON numbers in scientific notation can be decoded into integer types.
// Regression test for https://github.com/vlang/v/issues/26420

struct FooI64 {
pub mut:
	size i64
}

struct FooI32 {
pub mut:
	size i32
}

struct FooInt {
pub mut:
	size int
}

struct FooU64 {
pub mut:
	size u64
}

fn test_decode_scientific_notation_i64() {
	r := json.decode[FooI64]('{"size": 1.7596215426069998e+12}')!
	assert r.size == 1759621542606
}

fn test_decode_scientific_notation_i32() {
	r := json.decode[FooI32]('{"size": 1e+5}')!
	assert r.size == 100000
}

fn test_decode_scientific_notation_int() {
	r := json.decode[FooInt]('{"size": 2.5e+3}')!
	assert r.size == 2500
}

fn test_decode_scientific_notation_u64() {
	r := json.decode[FooU64]('{"size": 1e+10}')!
	assert r.size == 10000000000
}

fn test_decode_normal_integers_still_work() {
	r := json.decode[FooI64]('{"size": 42}')!
	assert r.size == 42
}

fn test_decode_negative_scientific_notation() {
	r := json.decode[FooI64]('{"size": -1.5e+3}')!
	assert r.size == -1500
}
