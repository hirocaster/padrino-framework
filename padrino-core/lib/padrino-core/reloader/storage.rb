module Padrino
  module Reloader
    module Storage
      extend self

      def clear!
        files.each_key do |file|
          remove(file)
          Reloader.remove_feature(file)
        end
        @files = {}
      end

      def remove(name)
        file = files[name] || return
        file[:constants].each{ |constant| Reloader.remove_constant(constant) }
        file[:features].each{ |feature| Reloader.remove_feature(feature) }
        files.delete(name)
      end

      def prepare(name, mtimes)
        file = remove(name)
        @old_entries ||= {}
        @old_entries[name] = {
          :constants => ObjectSpace.classes,
          :features  => old_features = Set.new($LOADED_FEATURES.dup),
          :mtimes => mtimes.dup
        }
        features = file && file[:features] || []
        features.each{ |feature| Reloader.safe_load(feature, :force => true) }
        Reloader.remove_feature(name) if old_features.include?(name)
      end

      def commit(name)
        entry = {
          :constants => ObjectSpace.new_classes(@old_entries[name][:constants]),
          :features  => Set.new($LOADED_FEATURES) - @old_entries[name][:features] - [name]
        }
        files[name] = entry
        @old_entries.delete(name)
      end

      def rollback(name, mtimes)
        new_constants = ObjectSpace.new_classes(@old_entries[name][:constants]).reject do |constant|
          newly_commited_constant?(constant, mtimes, @old_entries[name][:mtimes])
        end
        new_constants.each{ |klass| Reloader.remove_constant(klass) }
        @old_entries.delete(name)
      end

      private

      def files
        @files ||= {}
      end

      ##
      # Returns true if and only if constant is commited after prepare
      #
      def newly_commited_constant?(constant, mtimes, old_mtimes)
        newly_commited_files(files, mtimes, old_mtimes).each do |_, entry|
          return true if entry[:constants].include?(constant)
        end
        false
      end

      ##
      # Returns a list of entries in "files" that is commited after prepare
      #
      def newly_commited_files(files, mtimes, old_mtimes)
        files.select do |file, _|
          next true unless old_mtimes[file]
          old_mtimes[file] < mtimes[file]
        end
      end
    end
  end
end
