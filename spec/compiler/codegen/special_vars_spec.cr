require "../../spec_helper"

describe "Codegen: special vars" do
  {% for name in ["$~", "$?"] %}
    it "codegens {{name.id}}" do
      run(%(
        class Object; def not_nil!; self; end; end

        def foo(z)
          {{name.id}} = "hey"
        end

        foo(2)
        {{name.id}}
        )).to_string.should eq("hey")
    end

    it "codegens {{name.id}} with nilable (1)" do
      run(%(
        require "prelude"

        def foo
          if 1 == 2
            {{name.id}} = "foo"
          end
        end

        foo

        begin
          {{name.id}}
        rescue ex
          "ouch"
        end
        )).to_string.should eq("ouch")
    end

    it "codegens {{name.id}} with nilable (2)" do
      run(%(
        require "prelude"

        def foo
          if 1 == 1
            {{name.id}} = "foo"
          end
        end

        foo

        begin
          {{name.id}}
        rescue ex
          "ouch"
        end
        )).to_string.should eq("foo")
    end
  {% end %}

  it "codegens $~ two levels" do
    run(%(
      class Object; def not_nil!; self; end; end

      def foo
        $? = "hey"
      end

      def bar
        $? = foo
        $?
      end

      bar
      $?
      )).to_string.should eq("hey")
  end
end
