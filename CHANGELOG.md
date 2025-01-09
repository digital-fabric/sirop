# 2025-01-09 0.5

- Add after_body hook for lambdas

# 2024-04-29 0.4

- Improve sourcifier to support all Ruby syntax, based on Prism test fixtures
- Update Prism

# 2024-04-19 0.3

- Add support for injecting (prefixed) parameters to a lambda node
- Fix whitespace adjustment in DSL compiler
- Improve DSL compiler to support embedded string expressions
- Correctly handle eval'd proc

# 2024-02-27 0.2

- Update README
- Remove support for Ruby < 3.2
- Implement general purpose Finder for finding nodes
- Implement DSL compiler (for tests)
- Implement Sirop.to_source

# 2024-02-20 0.1

- Find node for a given `Proc` object
