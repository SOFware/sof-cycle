# frozen_string_literal: true

require "bundler/gem_tasks"

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

task default: :spec

require "reissue/gem"

Reissue::Task.create do |task|
  task.version_file = "lib/sof/cycle/version.rb"
end
