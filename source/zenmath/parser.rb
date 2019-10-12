# coding: utf-8


require 'pp'
require 'rexml/document'
require 'sassc'
include REXML


module ZenmathParserMethod

  STYLE_PATH = "resource/math.scss"
  SCRIPT_DIR = "resource/script"

  include ZenmathBuilder
  include ZenithalParserMethod

  private

  def determine_options(name, marks, attributes, macro, options)
    if macro && @math_macro_names.include?(name)
      options = options.clone
      options[:math] = true
      return options
    elsif macro && name == @raw_macro_name
      options = options.clone
      options[:math] = nil
      return options
    elsif DATA["leaf"].include?(name)
      options = options.clone
      options[:math_leaf] = true
      return options
    else
      return super
    end
  end

  def process_macro(name, marks, attributes, children_list, options)
    if @math_macro_names.include?(name)
      next_children_list = children_list.map do |children|
        element = Element.build("math-root") do |element|
          element << children
        end
        next element
      end
      raw_nodes = @macros[name].call(attributes, next_children_list)
      nodes = raw_nodes.inject(Nodes[], :<<)
      return nodes
    elsif name == @raw_macro_name
      children = children_list.first
      return children
    elsif name == @resource_macro_name
      style_string = STYLE_STRING.gsub("__mathfonturl__", attributes["font-url"] || "font.otf")
      script_string = SCRIPT_STRING
      nodes = Nodes[]
      nodes << Element.build("style") do |element|
        element << Text.new(style_string, true, nil, true)
      end
      nodes << Element.build("script") do |element|
        element << CData.new(script_string)
      end
      return nodes
    else
      return super
    end
  end

  def create_element(name, marks, attributes, children_list, options)
    if options[:math]
      return create_math_element(name, attributes, children_list)
    else
      return super
    end
  end

  def create_special_element(kind, children, options)
    if options[:math]
      return create_math_elements("row", {}, [children])
    else
      return super
    end
  end

  def create_text(raw_text, options)
    if options[:math] && !options[:math_leaf]
      return create_math_text(raw_text)
    else
      return super
    end
  end

  def create_escape(place, char, options)
    if options[:math] && place == :text
      return create_math_escape(char)
    else
      return super
    end
  end

  def self.create_style_string
    path = File.expand_path("../" + STYLE_PATH, __FILE__)
    string = SassC::Engine.new(File.read(path), {:style => :compressed}).render
    return string
  end

  def self.create_script_string
    dir = File.expand_path("../" + SCRIPT_DIR, __FILE__)
    string = "const DATA = "
    string << JSON.generate(DATA.slice("radical", "paren", "wide", "shift"))
    string << ";\n"
    Dir.each_child(dir) do |entry|
      string << File.read(dir + "/" + entry)
      string << "\n"
    end
    string << "window.onload = execute;"
    return string
  end

  STYLE_STRING = self.create_style_string
  SCRIPT_STRING = self.create_script_string

end


class ZenmathParser < ZenithalParser

  include ZenmathParserMethod

  attr_reader :raw_macro_name
  attr_reader :resource_macro_name

  def initialize(source)
    super(source)
    @simple_math_macro_name = nil
    @raw_macro_name = "raw"
    @resource_macro_name = "math-resource"
    @math_macro_names = []
    @math_level = 0
  end

  def register_math_macro(name, &block)
    @math_macro_names << name
    @macros.store(name, block)
  end

  def simple_math_macro_name=(name)
    @simple_math_macro_name = name
    register_math_macro(name) do |attributes, children_list|
      next [children_list.first]
    end
  end

end