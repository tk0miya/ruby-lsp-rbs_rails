# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[rubocop rbs:all]

namespace :rbs do
  task all: %i[install check validate]

  desc "Install RBS signatures"
  task :install do
    sh "bundle exec rbs collection install --frozen"
  end

  desc "Type check with Steep"
  task :check do
    sh "bundle exec steep check"
  end

  desc "Validate RBS files"
  task :validate do
    sh "bundle exec rbs -Isig validate"
  end
end
