# frozen_string_literal: true

task :default => :test
task :test do
  exec 'ruby test/run.rb'
end

task :release do
  require_relative './lib/sirop/version'
  version = Papercraft::VERSION
  
  puts 'Building sirop...'
  `gem build sirop.gemspec`

  puts "Pushing sirop #{version}..."
  `gem push sirop-#{version}.gem`

  puts "Cleaning up..."
  `rm *.gem`
end
