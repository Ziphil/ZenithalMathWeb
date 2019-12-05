# coding: utf-8


require 'json'
require 'pp'
require 'rexml/document'
require 'sassc'
require 'ttfunk'
include REXML


module ZoticaBuilder

  DATA_PATH = "resource/math.json"
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

  SPACE_ALTERNATIVES = {"sfun" => "afun", "sbin" => "abin", "srel" => "arel", "ssbin" => "asbin", "ssrel" => "asrel", "scas" => "acas", "quad" => "sgl", "qquad" => "dbl"}
  PHANTOM_TYPES = {"ph" => "bth", "vph" => "ver", "hph" => "hor"}
  ROLES = ["bin", "rel", "sbin", "srel", "del", "fun", "not", "ord", "lpar", "rpar", "cpar"]
  ALIGNS = {"c" => "center", "l" => "left", "r" => "right"}

  module_function

  def create_math_element(name, attributes, children_list, options = {})
    this = Nodes[]
    options[:role] = determine_role(attributes)
    options[:class] = attributes["class"]
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
        content_this << children_list.fetch(0, Nodes[])
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
        left_this << children_list.fetch(0, Nodes[])
        right_this << children_list.fetch(1, Nodes[])
      end
    when DATA["fence"].method(:key?)
      stretch_level = attributes["s"]
      left_symbol = ZoticaBuilder.fetch_fence_symbol(name, 0, stretch_level)
      right_symbol = ZoticaBuilder.fetch_fence_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_fence(name, name, left_symbol, right_symbol, modify, options) do |content_this|
        content_this << children_list.fetch(0, Nodes[])
      end
    when "intlike"
      kind = attributes["k"] || "int"
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_integral_symbol(kind, size)
      this << ZoticaBuilder.build_integral(symbol, size, options) do |sub_this, super_this|
        sub_this << children_list.fetch(0, Nodes[])
        super_this << children_list.fetch(1, Nodes[])
      end
    when DATA["integral"].method(:key?)
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_integral_symbol(name, size)
      this << ZoticaBuilder.build_integral(symbol, size, options) do |sub_this, super_this|
        sub_this << children_list.fetch(0, Nodes[])
        super_this << children_list.fetch(1, Nodes[])
      end
    when "sumlike"
      kind = attributes["k"] || "sum"
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_sum_symbol(kind, size)
      this << ZoticaBuilder.build_sum(symbol, size, options) do |under_this, over_this|
        under_this << children_list.fetch(0, Nodes[])
        over_this << children_list.fetch(1, Nodes[])
      end
    when DATA["sum"].method(:key?)
      size = (attributes["in"]) ? "inl" : "lrg"
      symbol = ZoticaBuilder.fetch_sum_symbol(name, size)
      this << ZoticaBuilder.build_sum(symbol, size, options) do |under_this, over_this|
        under_this << children_list.fetch(0, Nodes[])
        over_this << children_list.fetch(1, Nodes[])
      end
    when "accent"
      kind = attributes["k"]
      under_symbol = ZoticaBuilder.fetch_accent_symbol(kind, 0)
      over_symbol = ZoticaBuilder.fetch_accent_symbol(kind, 1)
      this << ZoticaBuilder.build_accent(under_symbol, over_symbol, options) do |base_this|
        base_this << children_list.fetch(0, Nodes[])
      end
    when DATA["accent"].method(:key?)
      under_symbol = ZoticaBuilder.fetch_accent_symbol(name, 0)
      over_symbol = ZoticaBuilder.fetch_accent_symbol(name, 1)
      this << ZoticaBuilder.build_accent(under_symbol, over_symbol, options) do |base_this|
        base_this << children_list.fetch(0, Nodes[])
      end
    when "wide"
      kind = attributes["k"]
      stretch_level = attributes["s"]
      under_symbol = ZoticaBuilder.fetch_wide_symbol(kind, 0, stretch_level)
      over_symbol  = ZoticaBuilder.fetch_wide_symbol(kind, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_wide(kind, under_symbol, over_symbol, modify, options) do |base_this|
        base_this << children_list.fetch(0, Nodes[])
      end
    when DATA["wide"].method(:key?)
      stretch_level = attributes["s"]
      under_symbol = ZoticaBuilder.fetch_wide_symbol(name, 0, stretch_level)
      over_symbol  = ZoticaBuilder.fetch_wide_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_wide(name, under_symbol, over_symbol, modify, options) do |base_this|
        base_this << children_list.fetch(0, Nodes[])
      end
    when "multi"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_this, left_super_this|
        base_this << children_list.fetch(0, Nodes[])
        sub_this << children_list.fetch(1, Nodes[])
        super_this << children_list.fetch(2, Nodes[])
        left_sub_this << children_list.fetch(3, Nodes[])
        left_super_this << children_list.fetch(4, Nodes[])
      end
    when "sb"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list.fetch(0, Nodes[])
        sub_this << children_list.fetch(1, Nodes[])
      end
    when "sp"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list.fetch(0, Nodes[])
        super_this << children_list.fetch(1, Nodes[])
      end
    when "sbsp"
      this << ZoticaBuilder.build_subsuper(options) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list.fetch(0, Nodes[])
        sub_this << children_list.fetch(1, Nodes[])
        super_this << children_list.fetch(2, Nodes[])
      end
    when "unov"
      this << ZoticaBuilder.build_underover(options) do |base_this, under_this, over_this|
        base_this << children_list.fetch(0, Nodes[])
        under_this << children_list.fetch(1, Nodes[])
        over_this << children_list.fetch(2, Nodes[])
      end
    when "un"
      this << ZoticaBuilder.build_underover(options) do |base_this, under_this, over_this|
        base_this << children_list.fetch(0, Nodes[])
        under_this << children_list.fetch(1, Nodes[])
      end
    when "ov"
      this << ZoticaBuilder.build_underover(options) do |base_this, under_this, over_this|
        base_this << children_list.fetch(0, Nodes[])
        over_this << children_list.fetch(1, Nodes[])
      end
    when "frac"
      this << ZoticaBuilder.build_fraction(options) do |numerator_this, denominator_this|
        numerator_this << children_list.fetch(0, Nodes[])
        denominator_this << children_list.fetch(1, Nodes[])
      end
    when "sqrt"
      stretch_level = attributes["s"]
      symbol = ZoticaBuilder.fetch_radical_symbol(stretch_level)
      modify = !stretch_level
      this << ZoticaBuilder.build_radical(symbol, modify, options) do |content_this, index_this|
        content_this << children_list.fetch(0, Nodes[])
        index_this << children_list.fetch(1, Nodes[])
      end
    when "table"
      type = attributes["t"]
      align_config = attributes["align"]
      raw = !!attributes["raw"]
      this << ZoticaBuilder.build_table(type, align_config, raw, options) do |table_this|
        table_this << children_list.fetch(0, Nodes[])
      end
    when "array"
      align_config = attributes["align"]
      this << ZoticaBuilder.build_table("std", align_config, true, options) do |table_this|
        table_this << children_list.fetch(0, Nodes[])
      end
    when "stack"
      this << ZoticaBuilder.build_table("stk", nil, true, options) do |table_this|
        table_this << children_list.fetch(0, Nodes[])
      end
    when "matrix"
      this << ZoticaBuilder.build_table("mat", nil, false, options) do |table_this|
        table_this << children_list.fetch(0, Nodes[])
      end
    when "case"
      left_symbol = ZoticaBuilder.fetch_fence_symbol("brace", 0, nil)
      right_symbol = ZoticaBuilder.fetch_fence_symbol("none", 1, nil)
      this << ZoticaBuilder.build_fence("brace", "none", left_symbol, right_symbol, true, options) do |this|
        this << ZoticaBuilder.build_table("cas", "ll", false) do |table_this|
          table_this << children_list.fetch(0, Nodes[])
        end
      end
    when "diag"
      vertical_gaps_string = attributes["ver"]
      horizontal_gaps_string = attributes["hor"]
      this << ZoticaBuilder.build_diagram(vertical_gaps_string, horizontal_gaps_string, options) do |table_this|
        table_this << children_list.fetch(0, Nodes[])
      end
    when "c"
      this << ZoticaBuilder.build_table_cell(options) do |cell_this|
        cell_this << children_list.fetch(0, Nodes[])
      end
    when "cc"
      children_list.each do |children|
        this << ZoticaBuilder.build_table_cell(options) do |cell_this|
          cell_this << children
        end
      end
      this << Element.new("math-sys-br")
    when "v"
      vertex_name = attributes["name"]
      this << ZoticaBuilder.build_diagram_vertex(vertex_name, options) do |vertex_this|
        vertex_this << children_list.fetch(0, Nodes[])
      end
    when "vv"
      children_list.each do |children|
        this << ZoticaBuilder.build_diagram_vertex(options) do |vertex_this|
          vertex_this << children
        end
      end
      this << Element.new("math-sys-br")
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
        label_this << children_list.fetch(0, Nodes[])
      end
    when "tree"
      this << ZoticaBuilder.build_tree(options) do |content_this|
        content_this << children_list.fetch(0, Nodes[])
      end
    when "axm"
      this << ZoticaBuilder.build_tree_axiom(options) do |content_this|
        content_this << children_list.fetch(0, Nodes[])
      end
    when "infr"
      number = attributes["n"].to_i
      this << ZoticaBuilder.build_tree_inference(number, options) do |content_this, right_label_this, left_label_this|
        content_this << children_list.fetch(0, Nodes[])
        right_label_this << children_list.fetch(1, Nodes[])
        left_label_this << children_list.fetch(2, Nodes[])
      end
    when "br"
      this << Element.new("math-sys-br")
    when "g"
      transform_configs = {}
      transform_configs[:rotate] = attributes["rotate"]
      this << ZoticaBuilder.build_group(transform_configs, options) do |content_this|
        content_this << children_list.fetch(0, Nodes[])
      end
    when "ph", "vph", "hph"
      type = PHANTOM_TYPES[name] || attributes["t"] || "bth"
      this << ZoticaBuilder.build_phantom(type, options) do |content_this|
        content_this << children_list.fetch(0, Nodes[])
      end
    when "s"
      type = attributes["t"] || "medium"
      this << ZoticaBuilder.build_space(type, options)
    when SPACE_ALTERNATIVES.method(:key?)
      type = SPACE_ALTERNATIVES[name]
      this << ZoticaBuilder.build_space(type, options)
    else
      this << Element.build(name) do |this|
        attributes.each do |key, value|
          this[key] = value
        end
        this << children_list.fetch(0, Nodes[])
      end
    end
    return this
  end

  def create_math_text(text, options = {})
    this = Nodes[]
    options = {}
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

  def determine_role(attributes)
    role = nil
    ROLES.each do |each_role|
      if attributes[each_role]
        role = each_role
      end
    end
    return role
  end

  def apply_options(nodes, options)
    nodes.each do |node|
      if node.is_a?(Element) && options[:role]
        classes = node["class"].split(" ") - ROLES
        classes << options[:role]
        node["class"] = classes.join(" ")
      end
      if options[:class]
        node["class"] = (node["class"].split(" ") + options[:class].split(" ")).join(" ")
      end
    end
  end

  def inherit_role(target_element, source_element)
    inner_elements = source_element.elements.to_a
    if inner_elements.size == 1
      inner_element = inner_elements.first
      inner_role = (inner_element["class"].split(" ") & ROLES).first
      if inner_role
        target_classes = target_element["class"].split(" ")
        if (target_classes & ROLES).empty?
          target_element["class"] = [*target_classes, inner_role].join(" ")
        end
      end
    end
  end

  def build_number(text, options = {})
    this = Nodes[]
    element = nil
    this << Element.build("math-n") do |this|
      this << ~text
      element = this
    end
    apply_options(this, options)
    modify_vertical_margins(element, "main", options)
    return this
  end

  def fetch_identifier_char(kind)
    char = DATA["identifier"].dig(kind) || ""
    return char
  end
  
  def fetch_alternative_identifier_text(kind, raw_text)
    text = raw_text.chars.map{|s| DATA.dig("alternative", kind, s) || ""}.join
    return text
  end

  def build_identifier(text, types, options = {})
    this = Nodes[]
    element = nil
    font_type = (types.include?("alt")) ? "math" : "main"
    this << Element.build("math-i") do |this|
      this["class"] = types.join(" ")
      this["data-cont"] = text
      this << ~text
      element = this
    end
    apply_options(this, options)
    modify_vertical_margins(element, font_type, options)
    return this
  end

  def fetch_operator_symbol(kind)
    symbol, types = DATA.dig("operator", kind) || ["", ["bin"]]
    return symbol, types
  end

  def build_operator(symbol, types, options = {}, &block)
    this = Nodes[]
    element = nil
    font_type = (types.include?("txt")) ? "main" : "math"
    this << Element.build("math-o") do |this|
      this["class"] = types.join(" ")
      this << ~symbol
      element = this
    end
    apply_options(this, options)
    modify_vertical_margins(element, font_type, options)
    return this
  end

  def modify_vertical_margins(element, font_type, options)
    text = element.inner_text
    max_top_margin, max_bottom_margin = -2, -2
    text.each_char do |char|
      codepoint = char.unpack1("U*")
      bottom_margin, top_margin = options[:fonts]&.dig(font_type.intern, codepoint.to_s) || DEFAULT_FONTS.dig(font_type.intern, codepoint.to_s) || [0, 0]
      if top_margin > max_top_margin
        max_top_margin = top_margin
      end
      if bottom_margin > max_bottom_margin
        max_bottom_margin = bottom_margin
      end
    end
    element["style"] += "line-height: 1; "
    element["style"] += "margin-top: #{max_top_margin}em; "
    element["style"] += "margin-bottom: #{max_bottom_margin}em; "
  end

  def build_strut(type, options = {})
    this = Nodes[]
    this << Element.build("math-strut") do |this|
      if type == "upper" || type == "dupper"
        this["style"] += "margin-bottom: -0.5em;"
      elsif type == "dlower" || type == "dfull"
        this["style"] += "margin-bottom: -0em;"
      else
        bottom_margin = options[:fonts]&.dig(:main, "72", 0) || DEFAULT_FONTS.dig(:main, "72", 0)
        this["style"] += "margin-bottom: #{bottom_margin}em;"
      end
      if type == "lower" || type == "dlower"
        this["style"] += "margin-top: -0.5em;"
      elsif type == "dupper" || type == "dfull"
        this["style"] += "margin-top: -0em;"
      else
        top_margin = options[:fonts]&.dig(:main, "72", 1) || DEFAULT_FONTS.dig(:main, "72", 1)
        this["style"] += "margin-top: #{top_margin}em;"
      end
      this << Element.build("math-text") do |this|
        this["style"] += "line-height: 1;"
        this << ~" "
      end
    end
    apply_options(this, options)
    return this
  end

  def build_subsuper(options = {}, &block)
    this = Nodes[]
    base_element, sub_element, super_element, left_sub_element, left_super_element = nil
    main_element = nil
    this << Element.build("math-subsup") do |this|
      main_element = this
      this << Element.build("math-lsub") do |this|
        left_sub_element = this
      end
      this << Element.build("math-lsup") do |this|
        left_super_element = this
      end
      this << Element.build("math-base") do |this|
        base_element = this
      end
      this << Element.build("math-sub") do |this|
        sub_element = this
      end
      this << Element.build("math-sup") do |this|
        super_element = this
      end
    end
    apply_options(this, options)
    block&.call(base_element, sub_element, super_element, left_sub_element, left_super_element)
    inherit_role(main_element, base_element)
    modify_subsuper(base_element, sub_element, super_element, left_sub_element, left_super_element)
    return this
  end

  def modify_subsuper(base_element, sub_element, super_element, left_sub_element, left_super_element)
    if sub_element.children.size <= 0
      sub_element.remove
    end
    if super_element.children.size <= 0
      super_element.remove
    end
    if left_sub_element && left_sub_element.children.size <= 0
      left_sub_element.remove
    end
    if left_super_element && left_super_element.children.size <= 0
      left_super_element.remove
    end
  end

  def build_underover(options = {}, &block)
    this = Nodes[]
    base_element, under_element, over_element = nil
    main_element = nil
    this << Element.build("math-underover") do |this|
      main_element = this
      this << Element.build("math-over") do |this|
        over_element = this
      end
      this << Element.build("math-basewrap") do |this|
        this << Element.build("math-base") do |this|
          base_element = this
        end
        this << Element.build("math-under") do |this|
          under_element = this
        end
      end
    end
    apply_options(this, options)
    block&.call(base_element, under_element, over_element)
    inherit_role(main_element, base_element)
    modify_underover(under_element, over_element)
    return this
  end

  def modify_underover(under_element, over_element)
    if under_element.children.size <= 0
      under_element.remove
    end
    if over_element.children.size <= 0
      over_element.remove
    end
  end

  def build_fraction(options = {}, &block)
    this = Nodes[]
    numerator_element, denominator_element = nil
    this << Element.build("math-frac") do |this|
      this << Element.build("math-num") do |this|
        numerator_element = this
      end
      this << Element.build("math-denwrap") do |this|
        this << Element.new("math-line")
        this << Element.build("math-den") do |this|
          denominator_element = this
        end
      end
    end
    apply_options(this, options)
    block&.call(numerator_element, denominator_element)
    modify_fraction(numerator_element, denominator_element)
    return this
  end

  def modify_fraction(numerator_element, denominator_element)
    numerator_element[0, 0] = build_strut("dlower").first
    denominator_element[0, 0] = build_strut("upper").first
  end

  def fetch_radical_symbol(stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("radical", stretch_level) || ""
    return symbol
  end

  def build_radical(symbol, modify, options = {}, &block)
    this = Nodes[]
    content_element, index_element = nil
    this << Element.build("math-rad") do |this|
      if modify
        this["class"] = "mod" 
      end
      this << Element.build("math-index") do |this|
        index_element = this
      end
      this << Element.build("math-sqrt") do |this|
        this << Element.build("math-surd") do |this|
          this << Element.build("math-o") do |this|
            this << Text.new(symbol, true, nil, false)
          end
        end
        this << Element.build("math-cont") do |this|
          content_element = this
        end
      end
    end
    apply_options(this, options)
    block&.call(content_element, index_element)
    modify_radical(content_element, index_element)
    return this
  end

  def modify_radical(content_element, index_element)
    content_element[0, 0] = build_strut("upper").first
    if index_element.children.size <= 0
      index_element.remove
    end
  end

  def fetch_fence_symbol(kind, position, stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("fence", kind, position, stretch_level) || ""
    return symbol
  end

  def build_fence(left_kind, right_kind, left_symbol, right_symbol, modify, options = {}, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-fence") do |this|
      this["class"] = "par"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-left"] = left_kind
        this["data-right"] = right_kind
      end
      this << Element.build("math-left") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(left_symbol, true, nil, false)
        end
      end
      this << Element.build("math-cont") do |this|
        content_element = this
      end
      this << Element.build("math-right") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(right_symbol, true, nil, false)
        end
      end
    end
    apply_options(this, options)
    block&.call(content_element)
    return this
  end

  def build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, options = {}, &block)
    this = Nodes[]
    left_element, right_element = nil
    this << Element.build("math-fence") do |this|
      this["class"] = "par"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-left"] = left_kind
        this["data-right"] = right_kind
        this["data-center"] = center_kind
      end
      this << Element.build("math-left") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(left_symbol, true, nil, false)
        end
      end
      this << Element.build("math-cont") do |this|
        left_element = this
      end
      this << Element.build("math-center") do |this|
        this["class"] = "cpar"
        this << Element.build("math-o") do |this|
          this << Text.new(right_symbol, true, nil, false)
        end
      end
      this << Element.build("math-cont") do |this|
        right_element = this
      end
      this << Element.build("math-right") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(right_symbol, true, nil, false)
        end
      end
    end
    apply_options(this, options)
    block&.call(left_element, right_element)
    return this
  end

  def fetch_integral_symbol(kind, size)
    size_index = (size == "lrg") ? 1 : 0
    symbol = DATA.dig("integral", kind, size_index) || ""
    return symbol
  end

  def build_integral(symbol, size, options = {}, &block)
    this = Nodes[]
    base_element, sub_element, super_element = nil
    this << Element.build("math-subsup") do |this|
      this["class"] = "int"
      unless size == "lrg"
        this["class"] = [*this["class"].split(" "), size].join(" ")
      end
      this << Element.build("math-base") do |this|
        base_element = this
        this << Element.build("math-o") do |this|
          this["class"] = "int"
          unless size == "lrg"
            this["class"] = [*this["class"].split(" "), size].join(" ")
          end
          this << Text.new(symbol, true, nil, false)
        end
      end
      this << Element.build("math-sub") do |this|
        sub_element = this
      end
      this << Element.build("math-sup") do |this|
        super_element = this
      end
    end
    apply_options(this, options)
    block&.call(sub_element, super_element)
    modify_subsuper(base_element, sub_element, super_element, nil, nil)
    return this
  end

  def fetch_sum_symbol(kind, size)
    size_index = (size == "lrg") ? 1 : 0
    symbol = DATA.dig("sum", kind, size_index) || ""
    return symbol
  end

  def build_sum(symbol, size, options = {}, &block)
    this = Nodes[]
    if size == "lrg"
      under_element, over_element = nil
      this << Element.build("math-underover") do |this|
        this["class"] = "sum"
        this << Element.build("math-over") do |this|
          over_element = this
        end
        this << Element.build("math-basewrap") do |this|
          this << Element.build("math-base") do |this|
            this << Element.build("math-o") do |this|
              this["class"] = "sum"
              this << Text.new(symbol, true, nil, false)
            end
          end
          this << Element.build("math-under") do |this|
            under_element = this
          end
        end
      end
      apply_options(this, options)
      block&.call(under_element, over_element)
      modify_underover(under_element, over_element)
    else
      base_element, sub_element, super_element = nil
      this << Element.build("math-subsup") do |this|
        this["class"] = "sum inl"
        this << Element.build("math-base") do |this|
          base_element = this
          this << Element.build("math-o") do |this|
            this["class"] = "sum inl"
            this << Text.new(symbol, true, nil, false)
          end
        end
        this << Element.build("math-sub") do |this|
          sub_element = this
        end
        this << Element.build("math-sup") do |this|
          super_element = this
        end
      end
      apply_options(this, options)
      block&.call(sub_element, super_element)
      modify_subsuper(base_element, sub_element, super_element, nil, nil)
    end
    return this
  end

  def build_accent(under_symbol, over_symbol, options = {}, &block)
    this = Nodes[]
    base_element, under_element, over_element = nil
    main_element = nil
    this << Element.build("math-underover") do |this|
      main_element = this
      this["class"] = "acc"
      this << Element.build("math-over") do |this|
        over_element = this
        if over_symbol
          this << Element.build("math-o") do |this|
            this["class"] = "acc"
            this << Text.new(over_symbol, true, nil, false)
          end
        end
      end
      this << Element.build("math-basewrap") do |this|
        this << Element.build("math-base") do |this|
          base_element = this
        end
        this << Element.build("math-under") do |this|
          under_element = this
          if under_symbol
            this << Element.build("math-o") do |this|
              this["class"] = "acc"
              this << Text.new(under_symbol, true, nil, false)
            end
          end
        end
      end
    end
    apply_options(this, options)
    block&.call(base_element)
    inherit_role(main_element, base_element)
    modify_underover(under_element, over_element)
    modify_accent(base_element, under_element, over_element)
    return this
  end

  def modify_accent(base_element, under_element, over_element)
    children = base_element.children
    if children.size == 1
      child = children.first
      if child.name == "math-i" && (child["class"].split(" ") & ["rm", "alt"]).empty?
        under_symbol_element = under_element.children.first
        over_symbol_element = over_element.children.first
        if under_symbol_element
          under_symbol_element["class"] = [*under_symbol_element["class"].split(" "), "it"].join(" ")
        end
        if over_symbol_element
          over_symbol_element["class"] = [*over_symbol_element["class"].split(" "), "it"].join(" ")
        end
      end
    end
  end

  def fetch_accent_symbol(kind, position)
    symbol = DATA.dig("accent", kind, position) || nil
    return symbol
  end

  def fetch_wide_symbol(kind, position, stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("wide", kind, position, stretch_level) || nil
    return symbol
  end

  def build_wide(kind, under_symbol, over_symbol, modify, options = {}, &block)
    this = Nodes[]
    base_element, under_element, over_element = nil
    main_element = nil
    this << Element.build("math-underover") do |this|
      this["class"] = "wid"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-kind"] = kind
      end
      main_element = this
      this << Element.build("math-over") do |this|
        if over_symbol
          this << Element.build("math-o") do |this|
            this["class"] = "wid"
            this << Text.new(over_symbol, true, nil, false)
          end
        end
        over_element = this
      end
      this << Element.build("math-basewrap") do |this|
        this << Element.build("math-base") do |this|
          base_element = this
        end
        this << Element.build("math-under") do |this|
          if under_symbol
            this << Element.build("math-o") do |this|
              this["class"] = "wid"
              this << Text.new(under_symbol, true, nil, false)
            end
          end
          under_element = this
        end
      end
    end
    apply_options(this, options)
    block&.call(base_element)
    inherit_role(main_element, base_element)
    modify_underover(under_element, over_element)
    return this
  end

  def build_table(type, align_config, raw, options = {}, &block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-table") do |this|
      this["class"] = type
      table_element = this
    end
    apply_options(this, options)
    block&.call(table_element)
    modify_table(table_element, type, align_config, raw)
    return this
  end

  def build_diagram(vertical_gaps_string, horizontal_gaps_string, options = {}, &block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-diagram") do |this|
      if vertical_gaps_string
        this["class"] = [*this["class"].split(" "), "vnon"].join(" ")
      end
      if horizontal_gaps_string
        this["class"] = [*this["class"].split(" "), "hnon"].join(" ")
      end
      table_element = this
    end
    apply_options(this, options)
    block&.call(table_element)
    modify_diagram(table_element, vertical_gaps_string, horizontal_gaps_string)
    modify_table(table_element, "diag", nil, false)
    return this
  end

  def modify_diagram(element, vertical_gaps_string, horizontal_gaps_string)
    cell_elements = element.elements.to_a
    vertical_gaps = vertical_gaps_string&.split(/\s*,\s*/)
    horizontal_gaps = horizontal_gaps_string&.split(/\s*,\s*/)
    column, row = 0, 0
    cell_elements.each_with_index do |child, i|
      if child.name == "math-cellwrap"
        vertical_gap = vertical_gaps&.fetch(row - 1, vertical_gaps.last)
        horizontal_gap = horizontal_gaps&.fetch(column - 1, horizontal_gaps.last)
        if vertical_gap && row > 0
          if vertical_gap =~ /^\d+$/
            child["style"] += "margin-top: #{vertical_gap.to_f / 18}em; "
          else
            child["class"] = [*child["class"].split(" "), "v#{vertical_gap}"].join(" ")
          end
        end
        if horizontal_gap && column > 0
          if horizontal_gap =~ /^\d+$/
            child["style"] += "margin-left: #{horizontal_gap.to_f / 18}em; "
          else
            child["class"] = [*child["class"].split(" "), "h#{horizontal_gap}"].join(" ")
          end
        end
        column += 1
      elsif child.name == "math-sys-br"
        row += 1
        column = 0
      end
    end
  end

  def modify_table(element, type, align_config, raw)
    align_array = align_config&.chars
    cell_elements = element.elements.to_a
    column, row = 0, 0
    cell_elements.each_with_index do |child, i|
      if child.name == "math-cell" || child.name == "math-cellwrap"
        if raw
          extra_class = []
          extra_class << "lpres" unless column == 0
          extra_class << "rpres" unless cell_elements[i + 1]&.name == "math-sys-br"
          child["class"] = (child["class"].split(" ") + extra_class).join(" ")
        end
        child["style"] += "grid-row: #{row + 1}; grid-column: #{column + 1};"
        if align_array
          align = ALIGNS[align_array[column]]
          child["style"] += "text-align: #{align};" 
        end
        unless type == "stk" || type == "diag"
          child[0, 0] = build_strut("dfull").first
        end
        column += 1
      elsif child.name == "math-sys-br"
        element.delete_element(child)
        row += 1
        column = 0
      end
    end
  end

  def build_table_cell(options = {}, &block)
    this = Nodes[]
    cell_element = nil
    this << Element.build("math-cell") do |this|
      cell_element = this
    end
    apply_options(this, options)
    block&.call(cell_element)
    return this
  end

  def build_diagram_vertex(name, options = {}, &block)
    this = Nodes[]
    vertex_element = nil
    this << Element.build("math-cellwrap") do |this|
      if name
        this["data-name"] = name
      end
      this << Element.build("math-cell") do |this|
        vertex_element = this
      end
    end
    apply_options(this, options)
    block&.call(vertex_element)
    return this
  end

  def build_arrow(name, configs, options = {}, &block)
    this = Nodes[]
    label_element = nil
    this << Element.build("math-arrow") do |this|
      this["data-start"] = configs[:start_config]
      this["data-end"] = configs[:end_config]
      if configs[:tip_kinds]
        this["data-tip"] = configs[:tip_kinds]
      end
      if configs[:bend_angle]
        this["data-bend"] = configs[:bend_angle]
      end
      if configs[:shift]
        this["data-shift"] = configs[:shift]
      end
      if configs[:line_count]
        this["data-line"] = configs[:line_count]
      end
      if configs[:dashed]
        this["data-dash"] = "data-dash"
      end
      if configs[:label_position]
        this["data-pos"] = configs[:label_position]
      end
      if configs[:inverted]
        this["data-inv"] = "data-inv"
      end
      if configs[:mark]
        this["data-mark"] = "data-mark"
      end
      if name
        this["data-name"] = name
      end
      label_element = this
    end
    apply_options(this, options)
    block&.call(label_element)
    return this
  end

  def build_tree(options = {}, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-tree") do |this|
      content_element = this
    end
    apply_options(this, options)
    block&.call(content_element)
    modify_tree(content_element)
    return this
  end

  def modify_tree(element)
    stack = []
    element.elements.each do |child|
      case child.name
      when "math-axiom"
        child[0, 0] = build_strut("dlower").first
        stack.push(child)
      when "math-sys-infer"
        number = child.attribute("data-num").to_s.to_i
        left_label_element = child.get_elements("math-sys-llabel").first
        right_label_element = child.get_elements("math-sys-rlabel").first
        antecedent_elements = stack.pop(number)
        inference_element = Element.build("math-infer") do |this|
          this << Element.build("math-label") do |this|
            if left_label_element.to_a.empty?
              this["class"] = "non"
            end
            left_label_element.each_element do |each_element|
              this << each_element
            end
          end
          this << Element.build("math-step") do |this|
            this << Element.build("math-ant") do |this|
              antecedent_elements.each do |antecedent_element|
                this << antecedent_element
              end
            end
            this << Element.build("math-conwrap") do |this|
              this << Element.new("math-line")
              this << Element.build("math-con") do |this|
                this << ZoticaBuilder.build_strut("upper").first
                this << ZoticaBuilder.build_strut("dlower").first
                this << child.get_elements("math-cont").first
              end
            end
          end
          this << Element.build("math-label") do |this|
            if right_label_element.to_a.empty?
              this["class"] = "non"
            end
            right_label_element.each_element do |each_element|
              this << each_element
            end
          end
        end
        stack.push(inference_element)
      end
    end
    element.each_element do |child|
      child.remove
    end
    element << stack.first
  end

  def build_tree_axiom(options = {}, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-axiom") do |this|
      content_element = this
    end
    apply_options(this, options)
    block&.call(content_element)
    return this
  end

  def build_tree_inference(number, options = {}, &block)
    this = Nodes[]
    content_element, right_label_element, left_label_element = nil
    this << Element.build("math-sys-infer") do |this|
      this["data-num"] = number.to_s
      this << Element.build("math-cont") do |this|
        content_element = this
      end
      this << Element.build("math-sys-rlabel") do |this|
        right_label_element = this
      end
      this << Element.build("math-sys-llabel") do |this|
        left_label_element = this
      end
    end
    apply_options(this, options)
    block&.call(content_element, right_label_element, left_label_element)
    return this
  end

  def build_group(transform_configs, options = {}, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-group") do |this|
      transforms = []
      if transform_configs[:rotate]
        transforms << "rotate(#{transform_configs[:rotate]}deg)"
      end
      unless transforms.empty?
        this["style"] += "transform: " + transforms.join(" ") + ";"
      end
      content_element = this
    end
    apply_options(this, options)
    block&.call(content_element)
    return this
  end

  def build_space(type, options = {})
    this = Nodes[]
    this << Element.build("math-space") do |this|
      this["class"] = type
    end
    apply_options(this, options)
    return this
  end

  def build_phantom(type, options = {}, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-phantom") do |this|
      this["class"] = ["lpres", "rpres"].join(" ")
      unless type == "bth"
        this["class"] = [*this["class"].split(" "), type].join(" ")
      end
      content_element = this
    end
    apply_options(this, options)
    block&.call(content_element)
    return this
  end

  def build_text(text, options = {}, &block)
    this = Nodes[]
    this << Element.build("math-text") do |this|
      this << Text.new(text, true, nil, false)
    end
    apply_options(this, options)
    return this
  end

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
    string << JSON.generate(ZoticaBuilder::DATA.slice("radical", "fence", "wide", "shift", "arrow"))
    string << ";\n"
    string << File.read(dir + "/main.js")
    string << "\n"
    Dir.each_child(dir) do |entry|
      unless entry == "main.js"
        string << File.read(dir + "/" + entry)
        string << "\n"
      end
    end
    string << "window.onload = () => Modifier.execute();"
    return string
  end

  def create_font_string(type, path = nil, metrics = nil)
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

  def save_font_strings
    main_font_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:main], __FILE__)
    math_font_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:math], __FILE__)
    File.open(main_font_path, "w") do |file|
      file.write(ZoticaBuilder.create_font_string(:main))
    end
    File.open(math_font_path, "w") do |file|
      file.write(ZoticaBuilder.create_font_string(:math))
    end
  end

  private

  def self.create_data
    path = File.expand_path("../" + DATA_PATH, __FILE__)
    data = JSON.parse(File.read(path))
    return data
  end

  def self.create_default_fonts
    fonts = {}
    main_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:main], __FILE__)
    math_path = File.expand_path("../" + DEFAULT_FONT_PATHS[:math], __FILE__)
    fonts[:main] = JSON.parse(File.read(main_path))
    fonts[:math] = JSON.parse(File.read(math_path))
    return fonts
  end

  DATA = self.create_data
  DEFAULT_FONTS = self.create_default_fonts

end