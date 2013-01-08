module ActiveRecord
  module ConnectionAdapters
    class JdbcDriver
      attr_reader :name, :properties
      
      def initialize(name, properties = {})
        @name = name
        @driver = driver_class.new
        if properties.is_a?(Java::JavaUtil::Properties)
          @properties = properties # allow programmatically set properties
        else
          @properties = Java::JavaUtil::Properties.new
          properties.each { |key, val| @properties[key] = val.to_s } if properties
        end
      end

      def driver_class
        @driver_class ||= begin
          driver_class_const = (@name[0...1].capitalize + @name[1..@name.length]).gsub(/\./, '_')
          Jdbc::Mutex.synchronized do
            unless Jdbc.const_defined?(driver_class_const)
              driver_class_name = @name
              Jdbc.module_eval do
                java_import(driver_class_name) { driver_class_const }
              end
            end
          end unless Jdbc.const_defined?(driver_class_const)
          driver_class = Jdbc.const_get(driver_class_const)
          raise "You must specify a driver for your JDBC connection" unless driver_class
          driver_class
        end
      end

      def connection(url, user, pass)
        # bypass DriverManager to get around problem with dynamically loaded jdbc drivers
        properties = self.properties.clone
        properties.setProperty("user", user) if user
        properties.setProperty("password", pass) if pass
        @driver.connect(url, properties)
      end
    end
  end
end
