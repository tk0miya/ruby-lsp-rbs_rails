# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[rubocop rbs:all]

namespace :rbs do
  task all: %i[install check validate]

  task :install do
    sh "bundle exec rbs collection install --frozen"
  end

  task :check do
    sh "bundle exec steep check"
  end

  task :validate do
    sh "bundle exec rbs -Isig validate"
  end
end
