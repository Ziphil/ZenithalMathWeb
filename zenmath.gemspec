# coding: utf-8


lib = File.expand_path("../lib", __FILE__)
unless $LOAD_PATH.include?(lib)
  $LOAD_PATH.unshift(lib) 
end

Gem::Specification.new do |spec|
  spec.name = "zenmath"
  spec.version = "0.0.0"
  spec.authors = ["Ziphil"]
  spec.email = ["ziphil.shaleiras@gmail.com"]
  spec.licenses = ["MIT"]
  spec.homepage = "https://github.com/Ziphil/ZenithalMath"
  spec.summary = "To be written"
  spec.description = <<~end_string
    To be written
  end_string
  spec.required_ruby_version = ">= 2.5"
  
  spec.add_runtime_dependency("zenml", ">= 1.2.0")
  spec.add_runtime_dependency("sassc")

  spec.files = Dir.glob("source/**/*")
  spec.require_paths = ["source"]
end