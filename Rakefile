require 'spec/rake/spectask'
require 'cucumber/rake/task'

task :default => [:spec, :cucumber]

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
end

Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = %w{--format progress}
end

desc "Run specs with rcov"
Spec::Rake::SpecTask.new(:spec_with_rcov) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

namespace :generate do
  desc 'Generate Rails app for integration testing'
  task :app do
    unless File.directory? './tmp/example_app'
      if `rails -v` =~ /\ARails 3/
        system 'rails new ./tmp/example_app'
      else
        system 'rails ./tmp/example_app'
        Dir.chdir("./tmp/example_app/") do
          system "script/generate cucumber"
          system 'cp ../../templates/environment.rb  ./config/'
          system 'cp ../../templates/custom_steps.rb ./features/step_definitions/'
        end
      end
    end
  end

  desc 'Generate scaffolds, etc'
  task :custom => ['generate:app'] do
    Dir.chdir("./tmp/example_app/") do
      system "rake rails:template LOCATION='../../templates/generate_custom.rb'"
    end
  end
end

namespace :clobber do
  desc 'Remove generated Rails app'
  task :app do
    rm_rf './tmp/example_app'
  end
end

desc 'Remove generated code'
task :clobber do
  rm_rf './tmp'
end
