# frozen_string_literal: true

desc 'Annotate model files'

task annotate: :environment do
  Rake::Task['annotate:model'].execute
end

namespace :annotate do
  desc 'Annotate models'
  task model: :environment do
    puts 'Annotating models'
    system('annotate --models -a')
  end
end
