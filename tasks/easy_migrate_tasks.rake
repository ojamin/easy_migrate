# desc "Explaining what the task does"
# task :easy_migrate do
#   # Task goes here
# end

namespace :db do
  `rm -rf db/easy-migrations-tmp`
  `mkdir db/easy-migrations-tmp`
  files = []
  files << `find db/migrate | egrep -v "migrate$"`.split("\n")
  files << `find vendor/plugins/*/db/migrate | egrep -v "migrate$"`.split("\n")
  files.flatten!
  valid_files = files.collect{|s| s.scan(/^.*\/[0-9]{14}_.*/) }.flatten
  failed_plugins = (files - valid_files).collect{|s| s.scan(/^vendor\/plugins\/([A-Z_\-a-z]*)\/db/) }.flatten.uniq
  failed_scripts = (files - valid_files).collect{|s| s.scan(/^db\/migrate\/([A-Z_a-z0-9]*)/) }.flatten
  `for f in #{valid_files.join(" ")} ; do ln -s ../../$f db/easy-migrations-tmp/ ; done`
  puts "================================================================="
  puts "Migrations for the application and all plugins using easy_migrate"
  puts "================================================================="
  if failed_plugins.size > 0
    puts "The following plugins can not be migrated as they have the wrong style naming format..."
    puts failed_plugins.join(", ")
  end
  if failed_scripts.size > 0
    puts "The following scripts in db/migrate can not be migrated as they have the wrong style naming format..."
    puts failed_scripts.join(", ")
  end
  
  desc "Run db:migrate to run migrations for both db/migrate in the app and in the plugins"
  task :migrate => :environment do
    puts "All outstanding migrations have been run"
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate("db/easy-migrations-tmp/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

#  desc "Step forwards over all application and plugin migrations - set VERSION to jump"
#  task :up => :environment do
#    puts "Stepped upwards if possible"
#    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
#    ActiveRecord::Migrator.up("db/easy-migrations-tmp/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
#    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
#  end
  desc "Step backwards over all application and plugin migrations - set VERSION to jump"
  task :down => :environment do
    puts "Stepped backwards if possible"
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.down("db/easy-migrations-tmp/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

end
