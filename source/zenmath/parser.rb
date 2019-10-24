# coding: utf-8


require 'pp'
require 'rexml/document'
require 'sassc'
include REXML


module ZenmathParserMethod

  COMMON_STYLE_PATH = "resource/style/math.scss"
  SPECIALIZED_STYLE_PATH = "resource/style/times.scss"
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
      style_string = create_style_string(attributes["font_url"])
      script_string = create_script_string
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
      return create_math_element("g", {}, [children])
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

  module_function

  def create_style_string(font_url = nil, style = :compressed)
    common_path = File.expand_path("../" + COMMON_STYLE_PATH, __FILE__)
    common_string = SassC::Engine.new(File.read(common_path), {:style => style}).render
    common_string.gsub!("__mathfonturl__", font_url || "font.otf")
    specialized_path = File.expand_path("../" + SPECIALIZED_STYLE_PATH, __FILE__)
    specialized_string = SassC::Engine.new(File.read(specialized_path), {:style => style}).render
    string = common_string + specialized_string
    return string
  end

  def create_script_string
    dir = File.expand_path("../" + SCRIPT_DIR, __FILE__)
    string = "const DATA = "
    string << JSON.generate(DATA.slice("radical", "paren", "wide", "shift", "arrow"))
    string << ";\n"
    string << File.read(dir + "/main.js")
    string << "\n"
    Dir.each_child(dir) do |entry|
      unless entry == "main.js"
        string << File.read(dir + "/" + entry)
        string << "\n"
      end
    end
    string << "window.onload = execute;"
    return string
  end

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