# coding: utf-8


require 'pp'
require 'rexml/document'
require 'sassc'
require 'ttfunk'
include REXML


module ZoticaParserMethod

  COMMON_STYLE_PATH = "resource/style/math.scss"
  SPECIALIZED_STYLE_PATH = "resource/style/times.scss"
  DEFAULT_TTF_PATHS = {:main => "resource/font/main.ttf", :math => "resource/font/math.ttf"}
  DEFAULT_FONT_PATHS = {:main => "resource/font/main.json", :math => "resource/font/math.json"}
  SCRIPT_DIR = "resource/script"

  CODEPOINTS = {
    :main => [
      0x0..0x2AF, 0x370..0x52F,
      0x2100..0x214F, 0x2200..0x22FF
    ],
    :math => [
      0x0..0x2AF,
      0x2100..0x214F, 0x2190..0x21FF, 0x2200..0x22FF, 0x2300..0x23FF, 0x27C0..0x27EF, 0x27F0..0x27FF, 0x2900..0x297F, 0x2980..0x29FF, 0x2A00..0x2AFF, 0x2B00..0x2BFF,
      0x1D400..0x1D7FF, 0xF0000..0xF05FF, 0xF1000..0xF10FF
    ]
  }

  include ZoticaBuilder
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
      style_string = ZoticaParserMethod.create_style_string(attributes["font_url"])
      script_string = ZoticaParserMethod.create_script_string
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

  def self.create_style_string(font_url = nil, style = :compressed)
    common_path = File.expand_path("../" + COMMON_STYLE_PATH, __FILE__)
    common_string = SassC::Engine.new(File.read(common_path), {:style => style}).render
    common_string.gsub!("__mathfonturl__", font_url || "font.otf")
    specialized_path = File.expand_path("../" + SPECIALIZED_STYLE_PATH, __FILE__)
    specialized_string = SassC::Engine.new(File.read(specialized_path), {:style => style}).render
    string = common_string + specialized_string
    return string
  end

  def self.create_script_string
    dir = File.expand_path("../" + SCRIPT_DIR, __FILE__)
    string = "const DATA = "
    string << JSON.generate(DATA.slice("radical", "fence", "wide", "shift", "arrow"))
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

  def self.create_font_string(type, path = nil, metrics = nil)
    unless path
      if type == :main
        path = File.expand_path("../" + DEFAULT_TTF_PATHS[:main], __FILE__)
        metrics = {:em => 2048, :ascent => 1638 + 78, :descent => 410 - 78}
      else
        path = File.expand_path("../" + DEFAULT_TTF_PATHS[:math], __FILE__)
        metrics = {:em => 1000, :ascent => 762, :descent => 238}
      end
    end
    file = TTFunk::File.open(path)
    first = true
    string = "{\n"
    CODEPOINTS[type].each do |part_codepoints|
      part_codepoints.each do |codepoint|
        glyph_id = file.cmap.unicode.first[codepoint]
        glyph = file.glyph_outlines.for(glyph_id)
        if glyph
          top_margin = (glyph.y_max - metrics[:ascent]) / metrics[:em].to_f
          bottom_margin = (-glyph.y_min - metrics[:descent]) / metrics[:em].to_f
          string << ",\n" unless first
          string << "  \"#{codepoint}\": [#{bottom_margin}, #{top_margin}]"
          first = false
        end
      end
    end
    string << "\n}"
    return string
  end

  def self.save_font_strings
    main_font_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:main], __FILE__)
    math_font_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:math], __FILE__)
    File.open(main_font_path, "w") do |file|
      file.write(ZoticaParserMethod.create_font_string(:main))
    end
    File.open(math_font_path, "w") do |file|
      file.write(ZoticaParserMethod.create_font_string(:math))
    end
  end

end


class ZoticaParser < ZenithalParser

  include ZoticaParserMethod

  attr_accessor :raw_macro_name
  attr_accessor :resource_macro_name

  def initialize(source)
    super(source)
    @simple_math_macro_name = nil
    @raw_macro_name = "raw"
    @resource_macro_name = "math-resource"
    @math_macro_names = []
    @fonts = {}
    @math_level = 0
    load_default_fonts
  end

  def load_default_fonts
    main_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:main], __FILE__)
    math_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:math], __FILE__)
    @fonts[:main] = JSON.parse(File.read(main_path))
    @fonts[:math] = JSON.parse(File.read(math_path))
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

end