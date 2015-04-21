require "../../spec_helper"

CodeGenCEnumString = "lib LibFoo; enum Bar; X, Y, Z = 10, W; end end"

macro assert_codegens(input, output, file = __FILE__, line = __LINE__)
  it "codegens enum with #{ {{input}} } ", {{file}}, {{line}} do
    run("
      lib LibFoo
        enum Bar
          X = #{ {{input}} }
        end
      end

      LibFoo::Bar::X
    ").to_i.should eq({{output}})
  end
end

describe "Code gen: c enum" do
  it "codegens enum value" do
    run("#{CodeGenCEnumString}; LibFoo::Bar::X").to_i.should eq(0)
  end

  it "codegens enum value 2" do
    run("#{CodeGenCEnumString}; LibFoo::Bar::Y").to_i.should eq(1)
  end

  it "codegens enum value 3" do
    run("#{CodeGenCEnumString}; LibFoo::Bar::Z").to_i.should eq(10)
  end

  it "codegens enum value 4" do
    run("#{CodeGenCEnumString}; LibFoo::Bar::W").to_i.should eq(11)
  end

  assert_codegens("1 + 2", 3)
  assert_codegens("3 - 2", 1)
  assert_codegens("3 * 2", 6)
  assert_codegens("10 / 2", 5)
  assert_codegens("1 << 3", 8)
  assert_codegens("100 >> 3", 12)
  assert_codegens("10 & 3", 2)
  assert_codegens("10 | 3", 11)
  assert_codegens("(1 + 2) * 3", 9)
  assert_codegens("10 % 3", 1)

  it "codegens enum that refers to another enum constant" do
    run("
      lib LibFoo
        enum Bar
          A = 1
          B = A + 1
          C = B + 1
        end
      end

      LibFoo::Bar::C
      ").to_i.should eq(3)
  end

  it "codegens enum that refers to another constant" do
    run("
      lib LibFoo
        X = 10
        enum Bar
          A = X
          B = A + 1
          C = B + 1
        end
      end

      LibFoo::Bar::C
      ").to_i.should eq(12)
  end
end
