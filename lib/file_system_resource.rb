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
        Pathname.glob(dir + '*'+ext)
      end
      
      # Returns a collection of records that were successfully registered
      def self.register
        existing_files.collect do |path|
          filename = path.basename ext
          next if find_by_file_system_resource_and_content(true, filename)
          create!(
            :name => filename,
            :filename => filename,
            :file_system_resource => true
          )
        end
      end
      
      def name
        file_system_resource? ? self[:name] + '_fs' : self[:name]
      end

      # Returns a collection of records that were removed
      # because their corresponding file was deleted
      def self.unregister_deleted
        find_all_by_file_system_resource(true).collect do |record|
          next if existing_files.include? record.path
          record.destroy
        end
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