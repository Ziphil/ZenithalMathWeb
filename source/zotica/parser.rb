# coding: utf-8


require 'pp'
require 'rexml/document'
include REXML


module ZoticaSingleParserMethod

  def parse
    if @block
      inner_element = parse_math_root
      raw_nodes = @block.call(@attributes, [inner_element])
      nodes = raw_nodes.inject(Nodes[], :<<)
    else
      nodes = parse_math_root
    end
    return nodes
  end

  private

  def parse_math_root
    element = Element.new("math-root")
    children = parse_nodes({})
    if @exact
      parse_eof
    end
    children.each do |child|
      element.add(child)
    end
    return element
  end

  def determine_options(name, marks, attributes, macro, options)
    if ZoticaBuilder::DATA["leaf"].include?(name)
      options = options.clone
      options[:math_leaf] = true
      return options
    else
      return super
    end
  end

  def create_element(name, marks, attributes, children_list, options)
    element = ZoticaBuilder.create_math_element(name, attributes, children_list, {:fonts => @fonts})
    return element
  end

  def create_special_element(kind, children, options)
    element = ZoticaBuilder.create_math_element("g", {}, [children], {:fonts => @fonts})
    return element
  end

  def create_text(raw_text, options)
    if !options[:math_leaf]
      text = ZoticaBuilder.create_math_text(raw_text, {:fonts => @fonts})
    else
      text = super
    end
    return text
  end

  def create_escape(place, char, options)
    if place == :text
      escape = ZoticaBuilder.create_math_escape(char, {:fonts => @fonts})
    else
      escape = super
    end
    return escape
  end

end


class ZoticaSingleParser < ZenithalParser

  include ZoticaSingleParserMethod

  attr_accessor :exact
  attr_accessor :fonts

  def initialize(source)
    super(source)
    @exact = false
    @fonts = {}
    @attributes = nil
    @block = nil
  end

  def setup(attributes, block)
    @attributes = attributes
    @block = block
  end

  def load_font(path)
    if path
      @fonts[:main] = JSON.parse(File.read(path))
    end
  end

end


class ZoticaParser < ZenithalParser

  def initialize(source)
    super(source)
    @raw_macro_names = []
    @fonts = {}
  end

  def load_font(path)
    if path
      @fonts[:main] = JSON.parse(File.read(path))
    end
  end

  def register_math_macro(name, &block)
    outer_self = self
    register_plugin(name) do |attributes|
      parser = ZoticaSingleParser.new(@source)
      @raw_macro_names.each do |raw_macro_name|
        parser.register_plugin(raw_macro_name) do |_|
          raw_parser = outer_self.clone
          raw_parser.exact = false
          raw_parser.whole = false
          next raw_parser
        end
      end
      parser.setup(attributes, block)
      parser.fonts = @fonts
      next parser
    end
  end

  def register_simple_math_macro(name)
    register_math_macro(name) do |attributes, children_list|
      next [children_list.first]
    end
  end

  def simple_math_macro_name=(name)
    warn("This method is now obsolete. Use 'register_simple_math_macro' instead.", uplevel: 1)
    register_simple_math_macro(name)
  end

  def register_raw_macro(name)
    @raw_macro_names << name
  end

  def raw_macro_name=(name)
    warn("This method is now obsolete. Use 'register_raw_macro' instead.", uplevel: 1)
    register_raw_macro(name)
  end

  def register_resource_macro(name)
    register_macro(name) do |attributes, children_list|
      style_string = ZoticaBuilder.create_style_string(attributes["font-url"])
      script_string = ZoticaBuilder.create_script_string
      nodes = Nodes[]
      nodes << Element.build("style") do |element|
        element << Text.new(style_string, true, nil, true)
      end
      nodes << Element.build("script") do |element|
        element << CData.new(script_string)
      end
      next nodes
    end
  end
  
  def resource_macro_name=(name)
    warn("This method is now obsolete. Use 'register_resource_macro' instead.", uplevel: 1)
    register_resource_macro(name)
  end

end