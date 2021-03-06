require 'basic_assumption/default_assumption/base'
require 'basic_assumption/default_assumption/class_resolver'

module BasicAssumption
  # Handles coordinating the default behaviors available in the application
  # that is using the BasicAssumption library. Classes that extend
  # +BasicAssumption+ can use the +default_assumption+ method to set their
  # own default, like so:
  #
  #   class WidgetController
  #     default_assumption { Widget.find_by_id(123) }
  #   end
  #
  # Any calls to +assume+ inside the WidgetController class that do not also
  # pass a block will use this default block as their behavior.
  #
  # === Providing custom default classes
  #
  # It is possible to pass a symbol instead of a block to the
  # +default_assumption+ call. BasicAssumption out of the box will understand
  # the symbol :rails as an option passed to +default_assumption+,
  # and will use the block provided by an instance of
  # BasicAssumption::DefaultAssumption::Rails as the default behavior.
  #
  # BasicAssumption will use the same process for any symbol passed to
  # +default_assumption+. If you pass it :my_custom_default it will attempt
  # to find a class BasicAssumption::DefaultAssumption::MyCustomDefault that
  # provides a +block+ instance method, and use the result as the default
  # behavior. See the +Rails+ class for an example.
  module DefaultAssumption
    def self.register(klass, default) #:nodoc:
      registry[klass.name] = strategy(default)
    end

    def self.resolve(klass) #:nodoc:
      return strategy(klass) if klass.kind_of?(Symbol)
      while !registry.has_key?(klass.name)
        klass = superclass(klass)
        break if klass.nil?
      end
      lookup = klass && klass.name
      registry[lookup]
    end

    class << self
      attr_accessor :default #:nodoc:

      protected
      def registry #:nodoc:
        @registry ||= Hash.new { |h, k| strategy(default) }
      end

      def strategy(given=nil) #:nodoc:
        case given
        when Proc
          given
        when Symbol
          ClassResolver.new(given, 'BasicAssumption::DefaultAssumption').instance.block
        else
          Base.new.block
        end
      end

      private

      def superclass(klass)
        klass.ancestors[1]
      end
    end
  end
end
