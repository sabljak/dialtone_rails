require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.pattern = "test/*_test.rb"
end

task default: :test

desc "Build demo assets and check the widget in headless Chrome"
task :browser do
  sh "npm run build:demo"
  ruby "test/browser.rb"
end
