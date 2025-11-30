package tests

import "core:fmt"
import "core:testing"
import "core:math/rand"

import fastrand ".."

// Test fastrand.wrapping_add
@(test)
test_wrapping_add :: proc(t: ^testing.T) {
  max_u64 := max(u64)
  result := fastrand.wrapping_add(max_u64, 1)
  testing.expect(t, result == 0, "max + 1 should wrap to 0")

  result = fastrand.wrapping_add(max_u64, 2)
  testing.expect(t, result == 1, "max + 2 should wrap to 1")

  // Test normal addition (no overflow)
  result = fastrand.wrapping_add(100, 200)
  testing.expect(t, result == 300, "Normal addition should work")
}

// Test fastrand.fill_bytes
@(test)
test_fill_bytes :: proc(t: ^testing.T) {
  r := fastrand.Random_State{s = 12345}

  // Test various buffer sizes
  sizes := []int{0, 1, 7, 8, 15, 16, 100, 1000}
  for size in sizes {
    buf := make([]byte, size)
    defer delete(buf)

    fastrand.fill_bytes(&r, buf)

    // For non-empty buffers, check that not all bytes are the same
    if size > 10 {
      all_same := true
      first := buf[0]
      for b in buf[1:] {
        if b != first {
          all_same = false
          break
        }
      }
      testing.expect(t, !all_same, "Fill bytes should produce varied output")
    }
  }
}

// Test u64 generation
@(test)
test_gen_u64 :: proc(t: ^testing.T) {
  r := fastrand.Random_State{s = 12345}

  seen := make(map[u64]bool)
  defer delete(seen)

  // Generate 1000 values and check for uniqueness
  for _ in 0..<1000 {
    val := fastrand.gen_u64(&r)
    testing.expect(t, val not_in seen, "Should generate unique values")
    seen[val] = true
  }
}

// Test deterministic output
@(test)
test_deterministic :: proc(t: ^testing.T) {
  state1 := fastrand.Random_State{s = 12345}
  gen1 := fastrand.random_generator(&state1)

  state2 := fastrand.Random_State{s = 12345}
  gen2 := fastrand.random_generator(&state2)

  for _ in 0..<100 {
    val1 := rand.uint64(gen1)
    val2 := rand.uint64(gen2)
    testing.expect(t, val1 == val2, "Same seed should produce same sequence")
  }
}

// Test uniform distribution
@(test)
test_uniform_distribution :: proc(t: ^testing.T) {
  gen := fastrand.random_generator()

  buckets := 10
  counts := make([]int, buckets)
  defer delete(counts)

  iterations := 100000
  for _ in 0..<iterations {
    val := rand.int_max(buckets, gen)
    counts[val] += 1
  }

  expected := f64(iterations) / f64(buckets)

  // Chi-square test for uniform distribution
  chi_square: f64 = 0.0
  for count in counts {
    diff := f64(count) - expected
    chi_square += (diff * diff) / expected
  }

  // Critical value for chi-square with 9 degrees of freedom at 0.05 significance: ~16.92
  testing.expect(t, chi_square < 20.0,
    fmt.tprintf("Chi-square %.2f suggests non-uniform distribution", chi_square))
}

// Test fastrand.shuffle
@(test)
test_shuffle :: proc(t: ^testing.T) {
  gen := fastrand.random_generator()

  arr := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
  original := make([]int, len(arr))
  copy(original, arr)
  defer delete(original)

  rand.shuffle(arr, gen)

  // Check all elements still present
  for val in original {
    found := false
    for v in arr {
      if v == val {
        found = true
        break
      }
    }
    testing.expect(t, found, fmt.tprintf("Value %d should still be in array", val))
  }

  // Check that order changed (very unlikely to be the same)
  same := true
  for i in 0..<len(arr) {
    if arr[i] != original[i] {
      same = false
      break
    }
  }
  testing.expect(t, !same, "Shuffle should change order")
}


@(test)
test_choice :: proc(t: ^testing.T) {
  gen := fastrand.random_generator()

  arr := []int{10, 20, 30, 40, 50}

  counts := make(map[int]int)
  defer delete(counts)

  iterations := 10000
  for _ in 0..<iterations {
    val := rand.choice(arr, gen)
    counts[val] += 1
  }

  // Check all elements were chosen at least once
  for val in arr {
    testing.expect(t, val in counts && counts[val] > 0,
      fmt.tprintf("Value %d should be chosen at least once", val))
  }

  // Check rough distribution (each should be around 20%)
  for val in arr {
    ratio := f64(counts[val]) / f64(iterations)
    testing.expect(t, ratio > 0.15 && ratio < 0.25,
      fmt.tprintf("Choose distribution for %d: %.3f should be around 0.2", val, ratio))
  }
}

// Test rand.reset functionality
@(test)
test_reset :: proc(t: ^testing.T) {
  state1 := fastrand.Random_State{s = 12345}
  gen1 := fastrand.random_generator(&state1)

  state2 := fastrand.Random_State{s = 67890}
  gen2 := fastrand.random_generator(&state2)

  // Generate some values to change internal state
  for _ in 0..<10 {
    _ = rand.uint64(gen1)
    _ = rand.uint64(gen2)
  }

  // Test rand.reset with u64 seed
  seed: u64 = 42
  rand.reset(seed, gen1)
  rand.reset(seed, gen2)

  // After reset, both should generate identical sequences
  for i in 0..<50 {
    val1 := rand.uint64(gen1)
    val2 := rand.uint64(gen2)
    testing.expect(t, val1 == val2,
      fmt.tprintf("After reset, generators should produce same values at iteration %d", i))
  }

  // Test reset with different seeds
  seed1: u64 = 123456
  seed2: u64 = 654321

  rand.reset(seed1, gen1)
  rand.reset(seed2, gen2)

  different_found := false
  for _ in 0..<10 {
    val1 := rand.uint64(gen1)
    val2 := rand.uint64(gen2)
    if val1 != val2 {
      different_found = true
      break
    }
  }
  testing.expect(t, different_found, "Different seeds should produce different sequences")

  // Test that reset actually changes the state
  state3 := fastrand.Random_State{s = 999}
  gen3 := fastrand.random_generator(&state3)

  // Generate some values
  vals_before := make([dynamic]u64)
  defer delete(vals_before)
  for _ in 0..<5 {
    append(&vals_before, rand.uint64(gen3))
  }

  // Reset to original seed and generate again
  rand.reset(999, gen3)
  vals_after := make([dynamic]u64)
  defer delete(vals_after)
  for _ in 0..<5 {
    append(&vals_after, rand.uint64(gen3))
  }

  // Should produce same sequence as original
  testing.expect(t, len(vals_before) == len(vals_after), "Should have same number of values")
  for i in 0..<len(vals_before) {
    testing.expect(t, vals_before[i] == vals_after[i],
      fmt.tprintf("Reset should reproduce same sequence at index %d", i))
  }

  // Test direct state reset (testing our implementation directly)
  state5 := fastrand.Random_State{s = 999}
  state6 := fastrand.Random_State{s = 888}

  // Change their states
  for _ in 0..<5 {
    _ = fastrand.gen_u64(&state5)
    _ = fastrand.gen_u64(&state6)
  }

  // Reset both to same seed manually
  state5.s = 777
  state6.s = 777

  // They should produce identical sequences
  for i in 0..<10 {
    val5 := fastrand.gen_u64(&state5)
    val6 := fastrand.gen_u64(&state6)
    testing.expect(t, val5 == val6,
      fmt.tprintf("After manual reset, states should produce same values at iteration %d", i))
  }
}

// Test fill_bytes with specific sizes
@(test)
test_fill_bytes_detailed :: proc(t: ^testing.T) {
  r := fastrand.Random_State{s = 12345}

  // Test 64-bit (8 bytes) - fast path
  {
    buf := make([]byte, 8)
    defer delete(buf)

    r_copy1 := r
    r_copy2 := r

    fastrand.fill_bytes(&r_copy1, buf)

    // Generate the same value manually to verify fast path
    expected_val := fastrand.gen_u64(&r_copy2)
    expected_bytes := (^[8]byte)(&expected_val)^

    testing.expect(t, len(buf) == 8, "Buffer should be 8 bytes")
    for i in 0..<8 {
      testing.expect(t, buf[i] == expected_bytes[i],
        fmt.tprintf("64-bit fill_bytes mismatch at byte %d: got %d, expected %d", i, buf[i], expected_bytes[i]))
    }
  }

  // Test multiples of 8 bytes
  test_sizes_8_multiples := []int{16, 24, 32, 40, 64, 80}
  for size in test_sizes_8_multiples {
    buf := make([]byte, size)
    defer delete(buf)

    r_copy := r
    fastrand.fill_bytes(&r_copy, buf)

    // Verify each 8-byte chunk is properly filled
    chunks := size / 8
    r_verify := r
    for chunk in 0..<chunks {
      expected_val := fastrand.gen_u64(&r_verify)
      expected_bytes := (^[8]byte)(&expected_val)^

      start_idx := chunk * 8
      for byte_idx in 0..<8 {
        testing.expect(t, buf[start_idx + byte_idx] == expected_bytes[byte_idx],
          fmt.tprintf("8-byte multiple fill_bytes mismatch at size %d, chunk %d, byte %d", size, chunk, byte_idx))
      }
    }

    testing.expect(t, size % 8 == 0, fmt.tprintf("Test size %d should be multiple of 8", size))
  }

  // Test non-multiples of 8 bytes
  test_sizes_non_8 := []int{1, 3, 7, 9, 15, 17, 23, 25, 31, 33}
  for size in test_sizes_non_8 {
    buf := make([]byte, size)
    defer delete(buf)

    r_copy := r
    fastrand.fill_bytes(&r_copy, buf)

    // Verify full 8-byte chunks
    full_chunks := size / 8
    r_verify := r
    for chunk in 0..<full_chunks {
      expected_val := fastrand.gen_u64(&r_verify)
      expected_bytes := (^[8]byte)(&expected_val)^

      start_idx := chunk * 8
      for byte_idx in 0..<8 {
        testing.expect(t, buf[start_idx + byte_idx] == expected_bytes[byte_idx],
          fmt.tprintf("Non-8-multiple fill_bytes chunk mismatch at size %d, chunk %d, byte %d", size, chunk, byte_idx))
      }
    }

    // Verify remaining bytes
    remaining := size % 8
    if remaining > 0 {
      expected_val := fastrand.gen_u64(&r_verify)
      expected_bytes := (^[8]byte)(&expected_val)^

      start_idx := full_chunks * 8
      for byte_idx in 0..<remaining {
        testing.expect(t, buf[start_idx + byte_idx] == expected_bytes[byte_idx],
          fmt.tprintf("Non-8-multiple fill_bytes remainder mismatch at size %d, byte %d", size, byte_idx))
      }
    }
  }

  // Test that different calls produce different data
  {
    r1 := fastrand.Random_State{s = 111}
    r2 := fastrand.Random_State{s = 222}

    buf1 := make([]byte, 20)
    buf2 := make([]byte, 20)
    defer delete(buf1)
    defer delete(buf2)

    fastrand.fill_bytes(&r1, buf1)
    fastrand.fill_bytes(&r2, buf2)

    different := false
    for i in 0..<len(buf1) {
      if buf1[i] != buf2[i] {
        different = true
        break
      }
    }
    testing.expect(t, different, "Different seeds should produce different byte arrays")
  }
}
