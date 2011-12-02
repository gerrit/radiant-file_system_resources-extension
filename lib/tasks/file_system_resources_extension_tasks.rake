namespace :radiant do
  namespace :extensions do
    namespace :file_system_resources do
      
      desc "Runs the migration of the Fs Resources extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          FileSystemResourcesExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          p FileSystemResourcesExtension.migrations_path
          FileSystemResourcesExtension.migrator.migrate
        end
      end

      namespace :migrate do
        task :rollback => :environment do
          step = ENV['STEP'] ? ENV['STEP'].to_i : 1
          FileSystemResourcesExtension.migrator.rollback(FileSystemResourcesExtension.migrations_path, step)
        end
      end

      desc "Copies public assets of the Fs Resources to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from FileSystemResourcesExtension"
        Dir[FileSystemResourcesExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(FileSystemResourcesExtension.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
        unless FileSystemResourcesExtension.root.starts_with? RAILS_ROOT # don't need to copy vendored tasks
          puts "Copying rake tasks from FileSystemResourcesExtension"
          local_tasks_path = File.join(RAILS_ROOT, %w(lib tasks))
          mkdir_p local_tasks_path, :verbose => false
          Dir[File.join FileSystemResourcesExtension.root, %w(lib tasks *.rake)].each do |file|
            cp file, local_tasks_path, :verbose => false
          end
        end
        FileSystemResourcesExtension.resource_classes.each do |klass|
          mkdir_p klass.dir
        end
      end
      
      desc "Move all Layouts and Snippets from the DB into the Filesystem"
      task :dump => :environment do
        FileSystemResourcesExtension.resource_classes.each do |klass|
          db_resources = klass.all.reject(&:file_system_resource?)
          db_resources.each do |layout_or_snippet|
            layout_or_snippet.path.open 'w' do |file|
              file << layout_or_snippet.content
            end
            layout_or_snippet.content = layout_or_snippet.name
            layout_or_snippet.file_system_resource = true
            # HACK: have to save without validations
            # as the (standard) appendix to the name fails validation
            unless layout_or_snippet.save(false)
              path.unlink
              raise "Error Saving: #{layout_or_snippet.inspect}"
            end
            puts "Dumped #{layout_or_snippet.filename}"
          end
        end
      end
      
      desc "Registers file system resources in the database (needed only when added/removed, not on edit)."
      task :register => :environment do
        FileSystemResourcesExtension.resource_classes.each do |klass|
          added, deleted = klass.register, klass.unregister_deleted
          added.each { |a| puts "Registered #{a.class.name} #{a.filename}." }
          deleted.each { |d| puts "Removed #{d.class.name }#{d.filename} (no longer exists on file system)." }
        end
      end
      
    end
  end
end
