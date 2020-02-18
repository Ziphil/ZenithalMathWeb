# coding: utf-8


require 'fileutils'
require 'open3'
require 'pp'
require 'rexml/document'
require 'zenml'
require_relative '../../source/zotica'

include REXML
include Zenithal

BASE_PATH = File.expand_path("..", File.dirname($0)).encode("utf-8")

Kernel.load(File.join(BASE_PATH, "converter/utility.rb"))
Encoding.default_external = "UTF-8"
$stdout.sync = true


class SampleConverter < ZenithalConverter

  def initialize(document)
    super(document, :text)
  end

  def pass_element(element, scope, close = true)
    tag = Tag.new(element.name, nil, close)
    element.attributes.each_attribute do |attribute|
      tag[attribute.name] = attribute.to_s
    end
    tag << apply(element, scope)
    return tag
  end

  def pass_text(text, scope)
    string = text.to_s
    return string
  end

end


class WholeSampleConverter

  DOCUMENT_DIR = "sample/document"
  MACRO_DIR = "sample/macro"
  TEMPLATE_DIR = "sample/template"
  OUTPUT_DIR = "sample/out"

  def initialize(args)
  end

  def execute
    convert_normal
  end

  def convert_normal
    parser = create_parser
    converter = create_converter.tap{|s| s.update(parser.run)}
    ZoticaBuilder.save_font_strings
    File.write(OUTPUT_DIR + "/main.html", converter.convert)
    FileUtils.copy(DOCUMENT_DIR + "/style.css", OUTPUT_DIR + "/style.css")
  end

  def create_parser
    source = File.read(DOCUMENT_DIR + "/main.zml")
    parser = ZoticaParser.new(source)
    parser.register_resource_macro("math-resource")
    parser.register_raw_macro("raw")
    parser.brace_name = "x"
    parser.bracket_name = "xn"
    parser.slash_name = "i"
    Dir.each_child(MACRO_DIR) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:parser, parser)
        Kernel.eval(File.read(MACRO_DIR + "/" + entry), binding, entry)
      end
    end
    return parser
  end

  def create_converter
    converter = SampleConverter.new(nil)
    Dir.each_child(TEMPLATE_DIR) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:converter, converter)
        Kernel.eval(File.read(TEMPLATE_DIR + "/" + entry), binding, entry)
      end
    end
    return converter
  end

end


whole_converter = WholeSampleConverter.new(ARGV)
whole_converter.execute