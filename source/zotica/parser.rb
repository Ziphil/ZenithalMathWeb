# coding: utf-8


module Zenithal::ZoticaSingleParserMethod

  SPACE_ALTERNATIVES = {"sfun" => "afun", "sbin" => "abin", "srel" => "arel", "ssbin" => "asbin", "ssrel" => "asrel", "scas" => "acas", "quad" => "sgl", "qquad" => "dbl"}
  PHANTOM_TYPES = {"ph" => "bth", "vph" => "ver", "hph" => "hor"}

  def parse
    if @block
      inner_element = parse_math_root
      raw_nodes = @block.call(@attributes, [inner_element])
      nodes = raw_nodes.inject(REXML::Nodes[], :<<)
    else
      nodes = parse_math_root
    end
    return nodes
  end

  private

  def create_math_element(name, attributes, children_list, options = {})
    this = REXML::Nodes[]
    options[:role] = determine_role(attributes)
    options[:class] = attributes["class"]
    options[:fonts] = @fonts
    case name
    when "n"
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_number(text, options)
    when "i"
      types = attributes["t"]&.split(/\s*,\s*/) || []
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_identifier(text, types, options)
    when "bf"
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_identifier(text, ["bf"], options)
    when "rm"
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_identifier(text, ["rm"], options)
    when "bfrm"
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_identifier(text, ["bf", "rm"], options)
    when "tt"
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_identifier(text, ["tt"], options)
    when "bb", "varbb", "cal", "scr", "frak", "varfrak"
      raw_text = children_list[0].first.value
      text = ZoticaBuilder.fetch_alternative_identifier_text(name, raw_text)
      this << ZoticaBuilder.build_identifier(text, ["alt"], options)
    when "op"
      text = children_list[0].first.to_s
      this << ZoticaBuilder.build_identifier(text, ["fun", "rm"], options)
    when DATA["identifier"].method(:key?)
      char = ZoticaBuilder.fetch_identifier_char(name)
      this << ZoticaBuilder.build_identifier(char, [], options)
    when DATA["function"].method(:include?)
      this << ZoticaBuilder.build_identifier(name, ["fun", "rm"], options)
    when "o"
      types = attributes["t"]&.split(/\s*,\s*/) || ["ord"]
      symbol = children_list[0].first.to_s
      this << ZoticaBuilder.build_operator(symbol, types, options)
    when DATA["operator"].method(:key?)
      symbol, types = ZoticaBuilder.fetch_operator_symbol(name)
      this << ZoticaBuilder.build_operator(symbol, types, options)
    when "text"
      text = children_list[0].first.value
      this << ZoticaBuilder.build_text(text, options)
    when "fence"
      stretch_level = attributes["s"]
      left_kind = attributes["l"] || "paren"
      right_kind = attributes["r"] || "paren"
      left_symbol = ZoticaBuilder.fetch_fence_symbol(left_kind, 0, stretch_level)
      right_symbol = ZoticaBuilder.fetch_fence_symbol(right_kind, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_fence(left_kind, right_kind, left_symbol, right_symbol, modify, options) do |content_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "set"
      stretch_level = attributes["s"]
      left_kind = attributes["l"] || "brace"
      right_kind = attributes["r"] || "brace"
      center_kind = attributes["c"] || "vert"
      left_symbol = ZoticaBuilder.fetch_fence_symbol(left_kind, 0, stretch_level)
      right_symbol = ZoticaBuilder.fetch_fence_symbol(right_kind, 1, stretch_level)
      center_symbol = ZoticaBuilder.fetch_fence_symbol(center_kind, 0, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, options) do |left_this, right_this|
        left_this << children_list.fetch(0, REXML::Nodes[])
        right_this << children_list.fetch(1, REXML::Nodes[])
      end
    when DATA["fence"].method(:key?)
      stretch_level = attributes["s"]
      left_symbol = ZoticaBuilder.fetch_fence_symbol(name, 0, stretch_level)
      right_symbol = ZoticaBuilder.fetch_fence_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_fence(name, name, left_symbol, right_symbol, modify, options) do |content_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "intlike"
      kind = attributes["k"] || "int"
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_integral_symbol(kind, size)
      this << ZoticaBuilder.build_integral(symbol, size, options) do |sub_this, super_this|
        sub_this << children_list.fetch(0, REXML::Nodes[])
        super_this << children_list.fetch(1, REXML::Nodes[])
      end
    when DATA["integral"].method(:key?)
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_integral_symbol(name, size)
      this << ZoticaBuilder.build_integral(symbol, size, options) do |sub_this, super_this|
        sub_this << children_list.fetch(0, REXML::Nodes[])
        super_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "sumlike"
      kind = attributes["k"] || "sum"
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_sum_symbol(kind, size)
      this << ZoticaBuilder.build_sum(symbol, size, options) do |under_this, over_this|
        under_this << children_list.fetch(0, REXML::Nodes[])
        over_this << children_list.fetch(1, REXML::Nodes[])
      end
    when DATA["sum"].method(:key?)
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_sum_symbol(name, size)
      this << ZoticaBuilder.build_sum(symbol, size, options) do |under_this, over_this|
        under_this << children_list.fetch(0, REXML::Nodes[])
        over_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "accent"
      kind = attributes["k"]
      under_symbol = ZoticaBuilder.fetch_accent_symbol(kind, 0)
      over_symbol = ZoticaBuilder.fetch_accent_symbol(kind, 1)
      this << ZoticaBuilder.build_accent(under_symbol, over_symbol, options) do |base_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
      end
    when DATA["accent"].method(:key?)
      under_symbol = ZoticaBuilder.fetch_accent_symbol(name, 0)
      over_symbol = ZoticaBuilder.fetch_accent_symbol(name, 1)
      this << ZoticaBuilder.build_accent(under_symbol, over_symbol, options) do |base_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "wide"
      kind = attributes["k"]
      stretch_level = attributes["s"]
      under_symbol = ZoticaBuilder.fetch_wide_symbol(kind, 0, stretch_level)
      over_symbol  = ZoticaBuilder.fetch_wide_symbol(kind, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_wide(kind, under_symbol, over_symbol, modify, options) do |base_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
      end
    when DATA["wide"].method(:key?)
      stretch_level = attributes["s"]
      under_symbol = ZoticaBuilder.fetch_wide_symbol(name, 0, stretch_level)
      over_symbol  = ZoticaBuilder.fetch_wide_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_wide(name, under_symbol, over_symbol, modify, options) do |base_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "multi"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_this, left_super_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
        sub_this << children_list.fetch(1, REXML::Nodes[])
        super_this << children_list.fetch(2, REXML::Nodes[])
        left_sub_this << children_list.fetch(3, REXML::Nodes[])
        left_super_this << children_list.fetch(4, REXML::Nodes[])
      end
    when "sb"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list.fetch(0, REXML::Nodes[])
        sub_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "sp"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list.fetch(0, REXML::Nodes[])
        super_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "sbsp"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list.fetch(0, REXML::Nodes[])
        sub_this << children_list.fetch(1, REXML::Nodes[])
        super_this << children_list.fetch(2, REXML::Nodes[])
      end
    when "unov"
      this << ZoticaBuilder.build_underover(options) do |base_this, under_this, over_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
        under_this << children_list.fetch(1, REXML::Nodes[])
        over_this << children_list.fetch(2, REXML::Nodes[])
      end
    when "un"
      this << ZoticaBuilder.build_underover(options) do |base_this, under_this, over_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
        under_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "ov"
      this << ZoticaBuilder.build_underover(options) do |base_this, under_this, over_this|
        base_this << children_list.fetch(0, REXML::Nodes[])
        over_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "frac"
      this << ZoticaBuilder.build_fraction(options) do |numerator_this, denominator_this|
        numerator_this << children_list.fetch(0, REXML::Nodes[])
        denominator_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "sqrt"
      stretch_level = attributes["s"]
      symbol = ZoticaBuilder.fetch_radical_symbol(stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_radical(symbol, modify, options) do |content_this, index_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
        index_this << children_list.fetch(1, REXML::Nodes[])
      end
    when "table"
      type = attributes["t"]
      align_config = attributes["align"]
      raw = !!attributes["raw"]
      this << ZoticaBuilder.build_table(type, align_config, raw, options) do |table_this|
        table_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "array"
      align_config = attributes["align"]
      this << ZoticaBuilder.build_table("std", align_config, true, options) do |table_this|
        table_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "stack"
      this << ZoticaBuilder.build_table("stk", nil, true, options) do |table_this|
        table_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "matrix"
      this << ZoticaBuilder.build_table("mat", nil, false, options) do |table_this|
        table_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "case"
      left_symbol = ZoticaBuilder.fetch_fence_symbol("brace", 0, nil)
      right_symbol = ZoticaBuilder.fetch_fence_symbol("none", 1, nil)
      this << ZoticaBuilder.build_fence("brace", "none", left_symbol, right_symbol, true, options) do |this|
        this << ZoticaBuilder.build_table("cas", "ll", false) do |table_this|
          table_this << children_list.fetch(0, REXML::Nodes[])
        end
      end
    when "diag"
      vertical_gaps_string = attributes["ver"]
      horizontal_gaps_string = attributes["hor"]
      this << ZoticaBuilder.build_diagram(vertical_gaps_string, horizontal_gaps_string, options) do |table_this|
        table_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "c"
      this << ZoticaBuilder.build_table_cell(options) do |cell_this|
        cell_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "cc"
      children_list.each do |children|
        this << ZoticaBuilder.build_table_cell(options) do |cell_this|
          cell_this << children
        end
      end
      this << REXML::Element.new("math-sys-br")
    when "v"
      vertex_name = attributes["name"]
      this << ZoticaBuilder.build_diagram_vertex(vertex_name, options) do |vertex_this|
        vertex_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "vv"
      children_list.each do |children|
        this << ZoticaBuilder.build_diagram_vertex(options) do |vertex_this|
          vertex_this << children
        end
      end
      this << REXML::Element.new("math-sys-br")
    when "ar"
      configs = {}
      configs[:start_config] = attributes["s"]
      configs[:end_config] = attributes["e"]
      configs[:tip_kinds] = attributes["tip"]
      configs[:bend_angle] = attributes["bend"]
      configs[:shift] = attributes["shift"]
      configs[:line_count] = attributes["line"]
      configs[:dashed] = attributes["dash"]
      configs[:label_position] = attributes["pos"]
      configs[:inverted] = attributes["inv"]
      configs[:mark] = attributes["mark"]
      arrow_name = attributes["name"]
      this << ZoticaBuilder.build_arrow(arrow_name, configs, options) do |label_this|
        label_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "tree"
      this << ZoticaBuilder.build_tree(options) do |content_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "axm"
      this << ZoticaBuilder.build_tree_axiom(options) do |content_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "infr"
      number = attributes["n"].to_i
      this << ZoticaBuilder.build_tree_inference(number, options) do |content_this, right_label_this, left_label_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
        right_label_this << children_list.fetch(1, REXML::Nodes[])
        left_label_this << children_list.fetch(2, REXML::Nodes[])
      end
    when "br"
      this << REXML::Element.new("math-sys-br")
    when "g"
      transform_configs = {}
      transform_configs[:rotate] = attributes["rotate"]
      this << ZoticaBuilder.build_group(transform_configs, options) do |content_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "ph", "vph", "hph"
      type = PHANTOM_TYPES[name] || attributes["t"] || "bth"
      this << ZoticaBuilder.build_phantom(type, options) do |content_this|
        content_this << children_list.fetch(0, REXML::Nodes[])
      end
    when "s"
      type = attributes["t"] || "med"
      this << ZoticaBuilder.build_space(type, options)
    when SPACE_ALTERNATIVES.method(:key?)
      type = SPACE_ALTERNATIVES[name]
      this << ZoticaBuilder.build_space(type, options)
    else
      this << REXML::Element.build(name) do |this|
        attributes.each do |key, value|
          this[key] = value
        end
        this << children_list.fetch(0, REXML::Nodes[])
      end
    end
    return this
  end

  def create_math_text(text, options = {})
    this = REXML::Nodes[]
    options[:fonts] = @fonts
    text.each_char do |char|
      if char =~ /\p{Number}/
        this << ZoticaBuilder.build_number(char, options)
      elsif char =~ /\p{Letter}|\p{Mark}/
        this << ZoticaBuilder.build_identifier(char, [], options)
      elsif char == "'"
        symbol, types = ZoticaBuilder.fetch_operator_symbol("pr")
        this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this|
          super_this << ZoticaBuilder.build_operator(symbol, types, options)
        end
      elsif char !~ /\s/
        char = DATA["replacement"][char] || char
        name = DATA["operator"].find{|s, (t, u)| char == t}&.first || char
        symbol, kinds = DATA["operator"][name] || [name, ["bin"]]
        this << ZoticaBuilder.build_operator(symbol, kinds, options)
      end
    end
    return this
  end

  def create_math_escape(char, options = {})
    next_char = char
    if DATA["greek"].key?(char)
      next_char = DATA["greek"][char]
    end
    return next_char
  end

  def parse_math_root
    element = REXML::Element.new("math-root")
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
    if DATA["leaf"].include?(name)
      options = options.clone
      options[:math_leaf] = true
      return options
    else
      return super
    end
  end

  def determine_role(attributes)
    role = nil
    roles = ZoticaBuilder::ROLES
    roles.each do |each_role|
      if attributes[each_role]
        role = each_role
      end
    end
    return role
  end

  def create_element(name, marks, attributes, children_list, options)
    element = create_math_element(name, attributes, children_list)
    return element
  end

  def create_special_element(kind, children, options)
    element = create_math_element("g", {}, [children])
    return element
  end

  def create_text(raw_text, options)
    if !options[:math_leaf]
      text = create_math_text(raw_text)
    else
      text = super
    end
    return text
  end

  def create_escape(place, char, options)
    if place == :text
      escape = create_math_escape(char)
    else
      escape = super
    end
    return escape
  end

  ZoticaBuilder = Zenithal::ZoticaBuilder

  DATA = ZoticaBuilder::DATA
  DEFAULT_FONTS = ZoticaBuilder::DEFAULT_FONTS

end


class Zenithal::ZoticaSingleParser < Zenithal::ZenithalParser

  include Zenithal::ZoticaSingleParserMethod

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


class Zenithal::ZoticaParser < Zenithal::ZenithalParser

  def initialize(source)
    super(source)
    @inner_parser = Zenithal::ZoticaSingleParser.new(source)
  end

  def load_font(path)
    @inner_parser.load_font(path)
  end

  def register_math_macro(name, &block)
    register_plugin(name) do |attributes|
      parser = @inner_parser.clone
      parser.update(@source)
      parser.setup(attributes, block)
      next parser
    end
    @inner_parser.register_plugin(name) do |_|
      inner_parser = @inner_parser.clone
      inner_parser.update(@source)
      inner_parser.setup(attributes, block)
      next inner_parser
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
    outer_self = self
    @inner_parser.register_plugin(name) do |_|
      raw_parser = outer_self.clone
      raw_parser.exact = false
      raw_parser.whole = false
      next raw_parser
    end
  end

  def raw_macro_name=(name)
    warn("This method is now obsolete. Use 'register_raw_macro' instead.", uplevel: 1)
    register_raw_macro(name)
  end

  def register_resource_macro(name)
    register_macro(name) do |attributes, children_list|
      style_string = Zenithal::ZoticaBuilder.create_style_string(attributes["font-url"])
      script_string = Zenithal::ZoticaBuilder.create_script_string
      nodes = REXML::Nodes[]
      nodes << REXML::Element.build("style") do |element|
        element << REXML::Text.new(style_string, true, nil, true)
      end
      nodes << REXML::Element.build("script") do |element|
        element << REXML::CData.new(script_string)
      end
      next nodes
    end
  end
  
  def resource_macro_name=(name)
    warn("This method is now obsolete. Use 'register_resource_macro' instead.", uplevel: 1)
    register_resource_macro(name)
  end

end