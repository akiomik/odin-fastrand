package benchmark

import "base:runtime"

import "core:fmt"
import "core:math/rand"
import "core:time"

import fastrand ".."

benchmark_fill_bytes :: proc() {
  r := fastrand.Random_State{s = 12345}

  buf := make([]byte, 1024)
  defer delete(buf)

  start := time.now()

  for i in 0..<1_000_000 {
    fastrand.fill_bytes(&r, buf)
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / 1_000_000
  fmt.printf("fastrand.fill_bytes (1KB): %d ns/op\n", ns_per_op)
}

benchmark_fastrand_uint64 :: proc() {
  gen := fastrand.random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<10_000_000 {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / 10_000_000
  fmt.printf("rand.uint64 (fastrand): %d ns/op\n", ns_per_op)
}

benchmark_default_uint64 :: proc() {
  gen := runtime.default_random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<10_000_000 {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / 10_000_000
  fmt.printf("rand.uint64 (default: chacha8): %d ns/op\n", ns_per_op)
}

benchmark_pcg_uint64 :: proc() {
  gen := rand.pcg_random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<10_000_000 {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / 10_000_000
  fmt.printf("rand.uint64 (pcg): %d ns/op\n", ns_per_op)
}

benchmark_xoshiro256_uint64 :: proc() {
  gen := rand.xoshiro256_random_generator()
  context.random_generator = gen

  start := time.now()

  for i in 0..<10_000_000 {
    _ = rand.uint64()
  }

  duration := time.since(start)
  ns_per_op := time.duration_nanoseconds(duration) / 10_000_000
  fmt.printf("rand.uint64 (xoshiro256): %d ns/op\n", ns_per_op)
}

// Run all benchmarks
main :: proc() {
  fmt.println("\n=== Benchmarks ===")
  benchmark_fill_bytes()
  benchmark_fastrand_uint64()
  benchmark_default_uint64()
  benchmark_pcg_uint64()
  benchmark_xoshiro256_uint64()
}
