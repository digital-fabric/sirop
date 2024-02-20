require_relative './lib/sirop/version'

Gem::Specification.new do |s|
  s.name        = 'sirop'
  s.version     = Sirop::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Sirop: Ruby code rewriter'
  s.author      = 'Sharon Rosner'
  s.email       = 'sharon@noteflakes.com'
  s.files       = `git ls-files README.md CHANGELOG.md lib`.split
  s.homepage    = 'http://github.com/digital-fabric/sirop'
  s.metadata    = {
    "source_code_uri" => "https://github.com/digital-fabric/sirop",
    "documentation_uri" => "https://www.rubydoc.info/gems/sirop",
    "homepage_uri" => "https://github.com/digital-fabric/sirop",
    "changelog_uri" => "https://github.com/digital-fabric/sirop/blob/main/CHANGELOG.md"
  }

  s.rdoc_options = ["--title", "Sirop", "--main", "README.md"]
  s.extra_rdoc_files = ["README.md", "sirop.png"]
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 3.0'

  s.add_runtime_dependency      'prism',                '~>0.19.0'

  s.add_development_dependency  'minitest',             '~>5.22.0'
end
