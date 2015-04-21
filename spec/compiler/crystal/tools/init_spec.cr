require "spec"
require "yaml"
require "compiler/crystal/tools/init"

macro describe_file(name)
  describe {{name}} do
    let(:contents) { File.read("tmp/#{ {{name}} }") }

    it "has proper contents" do
      {{ yield }}
    end
  end
end

def run_init_project(skeleton_type, name, dir, author)
  Crystal::Init::InitProject.new(
    Crystal::Init::Config.new(skeleton_type, name, dir, author, true)
  ).run
end

module Crystal
  describe Init::InitProject do
    `[ -d tmp/example ] && rm -r tmp/example`
    `[ -d tmp/example_app ] && rm -r tmp/example_app`

    run_init_project("lib", "example", "tmp/example", "John Smith")
    run_init_project("app", "example_app", "tmp/example_app", "John Smith")

    describe_file "example/.gitignore" do
      contents.should contain("/.deps/")
      contents.should contain("/.deps.lock")
      contents.should contain("/libs/")
      contents.should contain("/.crystal/")
    end

    describe_file "example_app/.gitignore" do
      contents.should contain("/.deps/")
      contents.should_not contain("/.deps.lock")
      contents.should contain("/libs/")
      contents.should contain("/.crystal/")
    end

    describe_file "example/LICENSE" do
      contents.should match %r{Copyright \(c\) \d+ John Smith}
    end

    describe_file "example/README.md" do
      contents.should contain("# example")

      contents.should contain(%{```crystal
deps do
  github "[your-github-name]/example"
end
```})

      contents.should contain(%{require "example"})
      contents.should contain(%{1. Fork it ( https://github.com/[your-github-name]/example/fork )})
      contents.should contain(%{[your-github-name](https://github.com/[your-github-name]) John Smith - creator, maintainer})
    end

    describe_file "example/Projectfile" do
      contents.should eq(%{deps do\nend\n})
    end

    describe_file "example/.travis.yml" do
      parsed = YAML.load(contents) as Hash

      parsed["language"].should eq("c")

      (parsed["before_install"] as String)
        .should contain("curl http://dist.crystal-lang.org/apt/setup.sh | sudo bash")

      (parsed["before_install"] as String)
        .should contain("sudo apt-get -q update")

      (parsed["install"] as String)
        .should contain("sudo apt-get install crystal")

      parsed["script"].should eq(["crystal spec"])
    end

    describe_file "example/src/example.cr" do
      contents.should eq(%{require "./example/*"

module Example
  # TODO Put your code here
end
})
    end

    describe_file "example/src/example/version.cr" do
      contents.should eq(%{module Example
  VERSION = "0.0.1"
end
})
    end

    describe_file "example/spec/spec_helper.cr" do
      contents.should eq(%{require "spec"
require "../src/example"
})
    end

    describe_file "example/spec/example_spec.cr" do
      contents.should eq(%{require "./spec_helper"

describe Example do
  # TODO: Write tests

  it "works" do
    false.should eq(true)
  end
end
})
    end

    describe_file "example/.git/config" {}

  end
end
