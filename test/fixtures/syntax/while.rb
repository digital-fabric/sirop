->(x) {
  foo while true

  while true
    p 'hi'
  end

  while false; 1; end

  while 1
    break if 1
    break(2) if 2
    break 3 if 3
    next if 4
  end
}
