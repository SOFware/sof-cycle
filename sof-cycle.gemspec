# frozen_string_literal: true

require_relative "lib/sof/cycle/version"

Gem::Specification.new do |spec|
  spec.name = "sof-cycle"
  spec.version = SOF::Cycle::VERSION
  spec.authors = ["Jim Gay"]
  spec.email = ["jim@saturnflyer.com"]

  spec.summary = "Parse and interact with SOF cycle notation."
  spec.homepage = "https://github.com/SOFware/sof-cycle"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "forwardable"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0"
end
