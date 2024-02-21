->(x) {
  ->(x, y, z = 3) { foo }
  ->(x = 1, y, z) { foo }
  ->(x, *a)       { foo }
  ->(x, **b)      { foo }
  ->(x, *a, **b)  { foo }
  ->(x, &blk)     { blk.() }

  r1 = 0
  r2 = 0

  lambda { |x|                foo }
  lambda { |x, y = 2|         foo }
  lambda { |x, y = (r1 + r2)| foo }
  lambda { |x, y, *a|         foo }
  lambda { |x, **b|           foo }
  lambda { |x, *a, **b|       foo }
  lambda { |x, *a, &blk|      blk.() }
}
