require 'pathname'

module FileSystemResource
  def self.included(klass)
    klass.class_eval do
      def self.dir
        Rails.root+'radiant'+name.downcase.pluralize
      end
      
      def self.ext
        '.radius'
      end
      
      def self.existing_files
        Pathname.glob(dir + "*#{ext}")
      end
      
      def self.already_registered? filename
        find_by_file_system_resource_and_content(true, filename)
      end
      
      # Returns a collection of records that were successfully registered
      def self.register
        filenames = existing_files.collect { |path| path.basename(ext).to_s }
        unregistered_files = filenames.reject {|name| already_registered? name}
        unregistered_files.collect do |filename|
          new(
            :name => filename,
            :filename => filename,
            :file_system_resource => true
          ).save(false)
        end
      end
      
      # Returns a collection of records that were removed
      # because their corresponding file was deleted
      def self.unregister_deleted
        records = find_all_by_file_system_resource(true)
        deleted = records.reject { |record| existing_files.include? record.path }
        deleted.collect { |record| record.destroy }
      end
      
      def path
        self.class.dir + "#{filename}#{self.class.ext}"
      end
      
      def filename
        file_system_resource? ? self[:content] : self[:name]
      end
      
      def filename=(value)
        self[:content] = value
      end
      
      def content
        file_system_resource? ? path.read : self[:content]
      end
      
      def content=(value)
        raise "File System Resources are read-only from the admin." if file_system_resource?
        self[:content] = value
      end
    end
  end
end