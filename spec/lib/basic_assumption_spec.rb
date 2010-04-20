require 'spec_helper'
require 'action_controller'

class Extender
  def quack
    {:foo => :bar}
  end
end

describe BasicAssumption do

  context "when a class extends BasicAssumption" do

    let(:extender_class) { Class.new(Extender) }
    let(:extender_instance) { extender_class.new }
    before(:each) do
      extender_class.extend(BasicAssumption)
    end

    it "declares named resources via #assume" do
      expect {
        extender_class.class_eval do
          assume :resource_name
        end
      }.to_not raise_error(NoMethodError)
    end

    it "declares an instance method of the given name" do
      extender_class.class_eval do
        assume :my_method_name
      end
      extender_instance.should respond_to(:my_method_name)
    end

    context "the instance method" do
      context "when no block was passed to assume" do
        it "returns nil by default" do
          extender_class.class_eval do
            assume :by_default
          end
          extender_instance.by_default.should be_nil
        end

        context "when the default is overridden" do
          it "returns the result of the overriding block" do
            extender_class.class_eval do
              default_assumption { 'overridden' }
              assume :overriden
            end
            extender_instance.overriden.should eql('overridden')
          end

          it "executes the default in the context of the extending instance" do
            extender_class.class_eval do
              default_assumption { quack }
              assume(:access_instance)
            end
            extender_instance.access_instance.should eql({:foo => :bar})
          end

          it "passes the name into the default block" do
            extender_class.class_eval do
              default_assumption { |name| name }
              assume(:given_name)
            end
            extender_instance.given_name.should eql(:given_name)
          end
        end
      end

      context "when a block was passed" do
        it "invokes the block as the method implementation" do
          extender_class.class_eval do
            assume(:resource) { 'this is my resource' }
          end
          extender_instance.resource.should eql('this is my resource')
        end

        it "executes in the context of the extending instance" do
          extender_class.class_eval do
            assume(:access_instance) { quack }
          end
          extender_instance.access_instance.should eql({:foo => :bar})
        end
      end

      it "memoizes the result for further calls" do
        extender_class.class_eval do
          assume(:random_once) { "#{rand(1_000_000)} #{rand(1_000_000)}" }
        end
        extender_instance.random_once.should eql(extender_instance.random_once)
      end
    end
  end

  context "within Rails" do
    before(:all) do
      require 'rails/init.rb'
    end
    let(:controller_class) { Class.new(::ActionController::Base) }
    let(:controller_instance) { controller_class.new }

    it "is extended by ActionController::Base" do
      ::ActionController::Base.should respond_to(:assume)
    end

    context "the instance method created by #assume" do
      it "is hidden from being an action" do
        controller_class.should_receive(:hide_action).with(:resource_name)
        controller_class.class_eval do
          assume(:resource_name)
        end
      end

      it "is visible in views" do
        controller_class.should_receive(:helper_method).with(:resource_name)
        controller_class.class_eval do
          assume(:resource_name)
        end
      end
    end

    context "classes derived from ActionController::Base" do
      let(:application_controller) { Class.new(controller_class) }
      let(:derived_class) { Class.new(application_controller) }
      let(:derived_instance) { derived_class.new }

      before(:all) do
        application_controller.class_eval do
          default_assumption { |name| "#{name}#{name}" }
        end
      end

      it "inherit the default assumption" do
        derived_class.class_eval do
          assume(:twice)
        end
        derived_instance.twice.should eql('twicetwice')
      end
    end

    context "the default assumption" do
      class ::Model; end
      it "attempts to find an instance of a model class inferred from the name" do
        controller_class.class_eval do
          assume(:model)
        end
        controller_instance.stub(:params => {'id' => 123})
        ::Model.should_receive(:find).with(123)
        controller_instance.model.should be_a_kind_of(Object)
      end
    end
  end
end
