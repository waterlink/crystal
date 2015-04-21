require "spec"

module Spec2
  ROOT_CONTEXTS = [] of Spec2::ContextContainer

  @@run_lamdbda = -> {}

  class ContextContainer(T)
    def examples
      T::SPEC_EXAMPLES
    end

    def run
      T.run
    end
  end

  class ExampleContainer(T)
    def build
      T.new
    end

    def description
      T.spec_description.join(" ")
    end
  end

  module Context
    # Maybe extract these into their own module
    def self.spec_nested_contexts; ROOT_CONTEXTS; end;
    def run_before; end
    def run_after; end
    def self.run_before_all; end
    def self.run_after_all; end
    def self.spec_description
      [] of String
    end

    macro it(description, file = __FILE__, line = __LINE__)
      class SpecExample%example
        # FIXME
        #include Spec2::Example

        include LastSpecContext

        def self.description
          ({{description}}).to_s
        end

        def self.spec_description
          LastSpecContext.spec_description + [description]
        end

        def run
          return if Spec.aborted?
          return unless Spec.matches?(self.class.description, {{file}}, {{line}})

          Spec.formatter.before_example(self.class.description)

          begin
            _run
            Spec::RootContext.report(:success, self.class.description, {{file}}, {{line}})
          rescue ex : Spec::AssertionFailed
            Spec::RootContext.report(:fail, self.class.description, {{file}}, {{line}}, ex)
            Spec.abort! if Spec.fail_fast?
          rescue ex
            Spec::RootContext.report(:error, self.class.description, {{file}}, {{line}}, ex)
            Spec.abort! if Spec.fail_fast?
          end
        end

        def _run
          {{yield}}
        end

      end

      SPEC_EXAMPLES << Spec2::ExampleContainer(SpecExample%example).new
    end

    macro let(name)
      def {{name.id}}
        @%value ||= begin
          {{yield}}
        end
      end
    end

    macro before
      def run_before
        previous_def
        {{yield}}
      end
    end

    macro after
      def run_after
        previous_def
        {{yield}}
      end
    end

    macro before_all
      def self.run_before_all
        previous_def
        {{yield}}
      end
    end

    macro after_all
      def self.run_after_all
        previous_def
        {{yield}}
      end
    end

    #macro define_run
    #  def self.run
    #    run_before_all

    #    SPEC_EXAMPLES.shuffle.each do |container|
    #      container.build.tap do |example|
    #        example.run_before
    #        example.run
    #        example.run_after
    #      end
    #    end

    #    SPEC_NESTED_CONTEXTS.shuffle.each &.run

    #    run_after_all
    #  end
    #end

    #define_run

    ## FIXME, the more context depth we have, the more stuff here needs
    ## to be added. Currently: 4
    #macro included
    #  define_run

    #  macro included
    #    define_run

    #    macro included
    #      define_run

    #      macro included
    #        define_run
    #      end
    #    end
    #  end
    #end
  end

  def self.run
    puts "run lambda is nil" unless @@run_lambda
    (@@run_lambda || -> {}).call
  end
end

alias LastSpecContext = Spec2::Context

macro describe(description)
  module SpecContext%context
    alias ParentSpecContext = LastSpecContext
    alias LastSpecContext = SpecContext%context

    include ParentSpecContext

    SPEC_NESTED_CONTEXTS = [] of Spec2::ContextContainer
    SPEC_EXAMPLES = [] of Spec2::ExampleContainer

    def self.spec_nested_contexts; SPEC_NESTED_CONTEXTS; end
    def self.run_before_all; end
    def self.run_after_all; end
    def run_before; super; end
    def run_after; super; end

    def self.spec_description
      ParentSpecContext.spec_description + [{{description.stringify}}]
    end

    def self.run
      run_before_all

      SPEC_EXAMPLES.shuffle.each do |container|
        container.build.tap do |example|
          example.run_before
          example.run
          example.run_after
        end
      end

      SPEC_NESTED_CONTEXTS.shuffle.each &.run

      run_after_all
    end

    {{yield}}
  end

  SpecContext%context::ParentSpecContext.spec_nested_contexts << Spec2::ContextContainer(SpecContext%context).new

  module ::Spec2
    @@run_lambda = -> { Spec2::ROOT_CONTEXTS.shuffle.each &.run }
  end
end

macro context(description)
  describe(description) do
    {{yield}}
  end
end

macro fail(msg, file = __FILE__, line = __LINE__)
  raise Spec::AssertionFailed.new({{msg}}, {{file}}, {{line}})
end

at_exit do
  time = Time.now
  Spec2.run
  elapsed_time = Time.now - time
  Spec::RootContext.print_results(elapsed_time)
  exit 1 unless Spec::RootContext.succeeded
end

# Example spec
#describe String do
#  describe "#to_i" do
#    let(:subject) { string.to_i }
#
#    context "when it is not an integer" do
#      let(:string) { "blablabla" }
#
#      it "returns 0" do
#        subject.should eq(0)
#      end
#    end
#
#    context "when it is an integer" do
#      let(:string) { "75" }
#
#      it "returns this integer" do
#        subject.should eq(77)
#      end
#    end
#
#    context "when it starts as integer" do
#      let(:string) { "9328asbdfjlj" }
#
#      it "returns this integer" do
#        subject.should eq(9328)
#      end
#    end
#  end
#end
#
#describe Int do
#  describe "#to_s" do
#    it "converts integer to string" do
#      45.to_s.should eq "45"
#    end
#  end
#end
