package examples

import "core:math/rand"

import fastrand ".."

main :: proc() {
  // Get a generator
  gen := fastrand.random_generator()
  context.random_generator = gen

  // Use with core:math/rand functions
  _ = rand.int_range(0, 100)
  _ = rand.float32()
}
