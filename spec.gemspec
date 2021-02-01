# coding: utf-8


lib = File.expand_path("../lib", __FILE__)
unless $LOAD_PATH.include?(lib)
  $LOAD_PATH.unshift(lib) 
end

Gem::Specification.new do |spec|
  spec.name = "zotica"
  spec.version = "1.6.0"
  spec.authors = ["Ziphil"]
  spec.email = ["ziphil.shaleiras@gmail.com"]
  spec.licenses = ["MIT"]
  spec.homepage = "https://github.com/Ziphil/ZenithalMathWeb"
  spec.summary = "Web rendering engine for mathematical formulae"
  spec.description = <<~end_string
    To be written.
  end_string
  spec.required_ruby_version = ">= 2.5"
  
  spec.add_runtime_dependency("zenml", ">= 1.6.0", "~> 1")
  spec.add_runtime_dependency("sassc", "~> 2")
  spec.add_runtime_dependency("ttfunk", "~> 1")

  spec.files = Dir.glob("source/**/*")
  spec.require_paths = ["source"]
  spec.bindir = "exec"
  spec.executables = ["zotica", "zoticaf"]
end