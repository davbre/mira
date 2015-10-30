
# require 'rake/testtask'
namespace :test do

  Rails::TestTask.new("api") do |t|
    t.pattern = "test/api/v1/*_test.rb"
  end

  Rails::TestTask.new("controllers") do |t|
    t.pattern = "test/controllers/*_test.rb"
  end

  Rails::TestTask.new("models") do |t|
    t.pattern = "test/models/*_test.rb"
  end

  Rails::TestTask.new("all") do
    Rake::Task["test:api"].invoke
    Rake::Task["test:controllers"].invoke
    Rake::Task["test:models"].invoke
  end
end
