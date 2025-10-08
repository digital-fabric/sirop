# 1.0 2025-10-08

- Add support for getting AST of procs/methods defined in IRB session

# 0.9 2025-08-17

- Add advance_to_end option to `Sourcifier#adjust_whitespace`

# 0.8.3 2025-08-08

- Add support for `it`

# 0.8.2 2025-08-07

- Fix source map calculation

# 0.8.1 2025-08-06

- Fix usage of @source_map_line_ofs

# 0.8 2025-08-06

- Add source map generation
- Require Ruby 3.4 or higher

# 0.7 2025-07-24

- Add minimize_whitespace option to `Sourcifier#initialize`
- Fix `Sirop.to_ast` for wrapped procs

# 0.6 2025-07-23

- Update to current version of Prism

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
