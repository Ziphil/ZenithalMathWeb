# coding: utf-8


require 'pp'
require 'rexml/document'
include REXML


module ZoticaParserMethod

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
    elsif ZoticaBuilder::DATA["leaf"].include?(name)
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
      style_string = ZoticaBuilder.create_style_string(attributes["font_url"])
      script_string = ZoticaBuilder.create_script_string
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
    if options[:math] || @only_math
      return ZoticaBuilder.create_math_element(name, attributes, children_list, {:fonts => @fonts})
    else
      return super
    end
  end

  def create_special_element(kind, children, options)
    if options[:math] || @only_math
      return ZoticaBuilder.create_math_element("g", {}, [children], {:fonts => @fonts})
    else
      return super
    end
  end

  def create_text(raw_text, options)
    if (options[:math] || @only_math) && !options[:math_leaf]
      return ZoticaBuilder.create_math_text(raw_text, {:fonts => @fonts})
    else
      return super
    end
  end

  def create_escape(place, char, options)
    if (options[:math] || @only_math) && place == :text
      return ZoticaBuilder.create_math_escape(char, {:fonts => @fonts})
    else
      return super
    end
  end

end


module ZoticaParserMixin

  include ZoticaParserMethod

  attr_accessor :raw_macro_name
  attr_accessor :resource_macro_name
  attr_accessor :only_math

  def setup_variables
    @simple_math_macro_name = nil
    @raw_macro_name = "raw"
    @resource_macro_name = "math-resource"
    @math_macro_names = []
    @only_math = false
    @fonts = {}
    @math_level = 0
  end

  def load_font(path)
    if path
      @fonts[:main] = JSON.parse(File.read(path))
    end
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

  private

  def self.extended(object)
    object.instance_eval do
      setup_variables
    end
  end

end


class ZoticaParser < ZenithalParser

  def initialize(source)
    super(source)
    extend(ZoticaParserMixin)
  end

end