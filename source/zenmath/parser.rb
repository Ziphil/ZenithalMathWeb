# coding: utf-8


require 'pp'
require 'rexml/document'
require 'sassc'
include REXML


module ZenithalMathParserMethod

  STYLE_MACRO_NAME = "math-style"
  RAW_MACRO_NAME = "raw"
  STYLE_PATH = "resource/math.scss"
  SCRIPT_PATH = "resource/math.js"

  include ZenithalMathCreater
  include ZenithalParserMethod

  private

  def determine_options(name, marks, attributes, macro, options)
    if macro && @math_macro_names.include?(name)
      options = options.clone
      options[:math] = true
      return options
    elsif macro && name == RAW_MACRO_NAME
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
    elsif name == RAW_MACRO_NAME
      children = children_list.first
      return children
    elsif name == STYLE_MACRO_NAME
      style_path = File.expand_path("../" + STYLE_PATH, __FILE__)
      script_path = File.expand_path("../" + SCRIPT_PATH, __FILE__)
      data_path = File.expand_path("../" + DATA_PATH, __FILE__)
      style_string = SassC::Engine.new(File.read(style_path), {:style => :compressed}).render
      style_string.gsub!("__mathfonturl__", attributes["url"].to_s)
      script_string = "DATA=" + File.read(data_path) + "\n" + File.read(script_path)
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

end


class ZenithalMathParser < ZenithalParser

  include ZenithalMathParserMethod

  def initialize(source)
    super(source)
    @math_macro_names = []
    @math_level = 0
  end

  def register_math_macro(name, &block)
    @math_macro_names << name
    @macros.store(name, block)
  end

end