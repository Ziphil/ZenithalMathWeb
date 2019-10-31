# coding: utf-8


require 'json'
require 'pp'
require 'rexml/document'
include REXML


module ZenmathBuilder

  DATA_PATH = "resource/math.json"
  SPACE_ALTERNATIVES = {"sfun" => "afun", "sbin" => "abin", "srel" => "arel", "ssbin" => "asbin", "ssrel" => "asrel", "scas" => "acas", "quad" => "sgl", "qquad" => "dbl"}
  PHANTOM_TYPES = {"ph" => nil, "vph" => "ver", "hph" => "hor"}
  SPACINGS = ["bin", "rel", "sbin", "srel", "del", "fun", "not", "ord", "lpar", "rpar", "cpar"]
  ALIGNS = {"c" => "center", "l" => "left", "r" => "right"}

  private

  def create_math_element(name, attributes, children_list)
    this = Nodes[]
    spacing = determine_spacing(attributes)
    case name
    when DATA["paren"].method(:key?)
      stretch_level = attributes["s"]
      left_symbol = fetch_paren_symbol(name, 0, stretch_level)
      right_symbol = fetch_paren_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << build_paren(name, name, left_symbol, right_symbol, modify, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "fence"
      stretch_level = attributes["s"]
      left_kind = attributes["l"] || "paren"
      right_kind = attributes["r"] || "paren"
      left_symbol = fetch_paren_symbol(left_kind, 0, stretch_level)
      right_symbol = fetch_paren_symbol(right_kind, 1, stretch_level)
      modify = !stretch_level
      this << build_paren(left_kind, right_kind, left_symbol, right_symbol, modify, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "set"
      stretch_level = attributes["s"]
      left_kind = attributes["l"] || "brace"
      right_kind = attributes["r"] || "brace"
      center_kind = attributes["c"] || "vert"
      left_symbol = fetch_paren_symbol(left_kind, 0, stretch_level)
      right_symbol = fetch_paren_symbol(right_kind, 1, stretch_level)
      center_symbol = fetch_paren_symbol(center_kind, 0, stretch_level)
      modify = !stretch_level
      this << build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, spacing) do |left_this, right_this|
        left_this << children_list[0]
        right_this << children_list[1]
      end
    when DATA["integral"].method(:key?)
      symbol = fetch_integral_symbol(name, "large")
      this << build_integral(symbol, spacing) do |sub_this, super_this|
        sub_this << children_list[0]
        super_this << children_list[1]
      end
    when DATA["sum"].method(:key?)
      symbol = fetch_sum_symbol(name, "large")
      this << build_sum(symbol, spacing) do |under_this, over_this|
        under_this << children_list[0]
        over_this << children_list[1]
      end
    when DATA["accent"].method(:key?)
      under_symbol = fetch_accent_symbol(name, 0)
      over_symbol = fetch_accent_symbol(name, 1)
      this << build_accent(under_symbol, over_symbol, spacing) do |base_this|
        base_this << children_list[0]
      end
    when DATA["wide"].method(:key?)
      stretch_level = attributes["s"]
      under_symbol = fetch_wide_symbol(name, 0, stretch_level)
      over_symbol  = fetch_wide_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << build_wide(name, under_symbol, over_symbol, modify, spacing) do |base_this|
        base_this << children_list[0]
      end
    when DATA["function"].method(:include?)
      this << build_identifier(name, ["fun"], spacing)
    when DATA["identifier"].method(:key?)
      char = fetch_identifier_char(name)
      this << build_identifier(char, [], spacing)
    when DATA["operator"].method(:key?)
      symbol, types = fetch_operator_symbol(name)
      this << build_operator(symbol, types, spacing)
    when "sb"
      this << build_subsuper(spacing) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list[0]
        sub_this << children_list[1]
      end
    when "sp"
      this << build_subsuper(spacing) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list[0]
        super_this << children_list[1]
      end
    when "sbsp"
      this << build_subsuper(spacing) do |base_this, sub_this, super_this, left_sub_element, left_super_element|
        base_this << children_list[0]
        sub_this << children_list[1]
        super_this << children_list[2]
      end
    when "multi"
      this << build_subsuper(spacing) do |base_this, sub_this, super_this, left_sub_this, left_super_this|
        base_this << children_list[0]
        sub_this << children_list[1]
        super_this << children_list[2]
        left_sub_this << children_list[3]
        left_super_this << children_list[4]
      end
    when "un"
      this << build_underover(spacing) do |base_this, under_this, over_this|
        base_this << children_list[0]
        under_this << children_list[1]
      end
    when "ov"
      this << build_underover(spacing) do |base_this, under_this, over_this|
        base_this << children_list[0]
        over_this << children_list[1]
      end
    when "unov"
      this << build_underover(spacing) do |base_this, under_this, over_this|
        base_this << children_list[0]
        under_this << children_list[1]
        over_this << children_list[2]
      end
    when "frac"
      this << build_fraction(spacing) do |numerator_this, denominator_this|
        numerator_this << children_list[0]
        denominator_this << children_list[1]
      end
    when "sqrt"
      stretch_level = attributes["s"]
      symbol = fetch_radical_symbol(stretch_level)
      modify = !stretch_level
      this << build_radical(symbol, modify, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "array"
      align_config = attributes["align"]
      this << build_array("std", align_config, true, spacing) do |table_this|
        table_this << children_list[0]
      end
    when "stack"
      this << build_array("stk", nil, true, spacing) do |table_this|
        table_this << children_list[0]
      end
    when "matrix"
      this << build_array("mat", nil, false, spacing) do |table_this|
        table_this << children_list[0]
      end
    when "case"
      left_symbol = fetch_paren_symbol("brace", 0, nil)
      right_symbol = fetch_paren_symbol("none", 1, nil)
      this << build_paren("brace", "none", left_symbol, right_symbol, true, spacing) do |this|
        this << build_array("cas", "ll", false) do |table_this|
          table_this << children_list[0]
        end
      end
    when "diag"
      vertical_gaps_string = attributes["ver"]
      horizontal_gaps_string = attributes["hor"]
      this << build_diagram(vertical_gaps_string, horizontal_gaps_string, spacing) do |table_this|
        table_this << children_list[0]
      end
    when "c"
      this << build_array_cell(spacing) do |cell_this|
        cell_this << children_list[0]
      end
    when "cc"
      children_list.each do |children|
        this << build_array_cell(spacing) do |cell_this|
          cell_this << children
        end
      end
      this << Element.new("math-sys-br")
    when "v"
      vertex_name = attributes["name"]
      this << build_diagram_vertex(vertex_name, spacing) do |vertex_this|
        vertex_this << children_list[0]
      end
    when "vv"
      children_list.each do |children|
        this << build_diagram_vertex(spacing) do |vertex_this|
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
      this << build_arrow(arrow_name, configs, spacing) do |label_this|
        label_this << children_list[0]
      end
    when "br"
      this << Element.new("math-sys-br")
    when "g"
      transform_configs = {}
      transform_configs[:rotate] = attributes["rotate"]
      this << build_group(transform_configs, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "s"
      type = attributes["t"] || "medium"
      this << build_space(type, spacing)
    when "ph", "vph", "hph"
      type = PHANTOM_TYPES[name]
      this << build_phantom(type, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "strut"
      this << build_phantom("ver", spacing) do |content_this|
        content_this << build_number("1")
      end
    when SPACE_ALTERNATIVES.method(:key?)
      type = SPACE_ALTERNATIVES[name]
      this << build_space(type, spacing)
    when "bb", "cal", "scr", "frak"
      raw_text = children_list[0].first.value
      text = fetch_alternative_identifier_text(name, raw_text)
      this << build_identifier(text, ["alt"], spacing)
    when "n"
      text = children_list[0].first.to_s
      this << build_number(text, spacing)
    when "i"
      types = attributes["t"]&.split(/\s*,\s*/) || []
      text = children_list[0].first.to_s
      this << build_identifier(text, types, spacing)
    when "op"
      text = children_list[0].first.to_s
      this << build_identifier(text, ["fun"], spacing)
    when "o"
      types = attributes["t"]&.split(/\s*,\s*/) || ["ord"]
      symbol = children_list[0].first.to_s
      this << build_operator(symbol, types, spacing)
    when "bf"
      text = children_list[0].first.to_s
      this << build_identifier(text, ["bf"], spacing)
    when "rm"
      text = children_list[0].first.to_s
      this << build_identifier(text, ["rm"], spacing)
    when "bfrm"
      text = children_list[0].first.to_s
      this << build_identifier(text, ["bf", "rm"], spacing)
    when "text"
      text = children_list[0].first.value
      this << build_text(text, spacing)
    else
      this << Element.build(name) do |this|
        attributes.each do |key, value|
          this[key] = value
        end
        this << children_list[0]
      end
    end
    return this
  end

  def create_math_text(text)
    this = Nodes[]
    text.each_char do |char|
      if char =~ /\p{Number}/
        this << build_number(char)
      elsif char =~ /\p{Letter}|\p{Mark}/
        this << build_identifier(char, [])
      elsif char == "'"
        symbol, types = fetch_operator_symbol("pr")
        this << build_subsuper do |base_this, sub_this, super_this|
          super_this << build_operator(symbol, types)
        end
      elsif char !~ /\s/
        char = DATA["replacement"][char] || char
        name = DATA["operator"].find{|s, (t, u)| char == t}&.first || char
        symbol, kinds = DATA["operator"][name] || [name, ["bin"]]
        this << build_operator(symbol, kinds)
      end
    end
    return this
  end

  def create_math_escape(char)
    next_char = char
    if DATA["greek"].key?(char)
      next_char = DATA["greek"][char]
    end
    return next_char
  end

  public

  def determine_spacing(attributes)
    spacing = nil
    SPACINGS.each do |each_spacing|
      if attributes[each_spacing]
        spacing = each_spacing
      end
    end
    return spacing
  end

  def add_spacing(nodes, spacing)
    nodes.each do |node|
      if node.is_a?(Element) && spacing
        classes = node["class"].split(" ") - SPACINGS
        classes << spacing
        node["class"] = classes.join(" ")
      end
    end
  end

  def build_number(text, spacing = nil)
    this = Nodes[]
    element = nil
    this << Element.build("math-n") do |this|
      this << ~text
      element = this
    end
    add_spacing(this, spacing)
    modify_vertical_margins(element, "main")
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

  def build_identifier(text, types, spacing = nil)
    this = Nodes[]
    element = nil
    font_type = (types.include?("alt")) ? "math" : "main"
    this << Element.build("math-i") do |this|
      this["class"] = types.join(" ")
      this["data-cont"] = text
      this << ~text
      element = this
    end
    add_spacing(this, spacing)
    modify_vertical_margins(element, font_type)
    return this
  end

  def fetch_operator_symbol(kind)
    symbol, types = DATA.dig("operator", kind) || ["", ["bin"]]
    return symbol, types
  end

  def build_operator(symbol, types, spacing = nil, &block)
    this = Nodes[]
    element = nil
    font_type = (types.include?("txt")) ? "main" : "math"
    this << Element.build("math-o") do |this|
      this["class"] = types.join(" ")
      this << ~symbol
      element = this
    end
    add_spacing(this, spacing)
    modify_vertical_margins(element, font_type)
    return this
  end

  def modify_vertical_margins(element, font_type)
    text = element.inner_text
    max_top_margin, max_bottom_margin = -2, -2
    text.each_char do |char|
      codepoint = char.unpack1("U*")
      bottom_margin, top_margin = @fonts.dig(font_type.intern, codepoint.to_s) || [0, 0]
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

  def build_strut(type, spacing = nil)
    this = Nodes[]
    this << Element.build("math-strut") do |this|
      if type == "upper" || type == "dupper"
        this["style"] += "margin-bottom: -0.5em;"
      elsif type == "dlower" || type == "dfull"
        this["style"] += "margin-bottom: -0em;"
      else
        bottom_margin = @fonts.dig(:main, "72", 0)
        this["style"] += "margin-bottom: #{bottom_margin}em;"
      end
      if type == "lower" || type == "dlower"
        this["style"] += "margin-top: -0.5em;"
      elsif type == "dupper" || type == "dfull"
        this["style"] += "margin-top: -0em;"
      else
        top_margin = @fonts.dig(:main, "72", 1)
        this["style"] += "margin-top: #{top_margin}em;"
      end
      this << Element.build("math-text") do |this|
        this["style"] += "line-height: 1;"
        this << ~" "
      end
    end
    add_spacing(this, spacing)
    return this
  end

  def build_subsuper(spacing = nil, &block)
    this = Nodes[]
    base_element, sub_element, super_element, left_sub_element, left_super_element = nil
    this << Element.build("math-subsup") do |this|
      subsuper_element = this
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
    add_spacing(this, spacing)
    block&.call(base_element, sub_element, super_element, left_sub_element, left_super_element)
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

  def build_underover(spacing = nil, &block)
    this = Nodes[]
    base_element, under_element, over_element = nil
    this << Element.build("math-underover") do |this|
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
    add_spacing(this, spacing)
    block&.call(base_element, under_element, over_element)
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

  def build_fraction(spacing = nil, &block)
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
    add_spacing(this, spacing)
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

  def build_radical(symbol, modify, spacing = nil, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-sqrt") do |this|
      if modify
        this["class"] = "mod" 
      end
      this << Element.build("math-surd") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(symbol, true, nil, false)
        end
      end
      this << Element.build("math-sqrtcont") do |this|
        content_element = this
      end
    end
    add_spacing(this, spacing)
    block&.call(content_element)
    modify_radical(content_element)
    return this
  end

  def modify_radical(content_element)
    content_element[0, 0] = build_strut("upper").first
  end

  def fetch_paren_symbol(kind, position, stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("paren", kind, position, stretch_level) || ""
    return symbol
  end

  def build_paren(left_kind, right_kind, left_symbol, right_symbol, modify, spacing = nil, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-paren") do |this|
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
      this << Element.build("math-parencont") do |this|
        content_element = this
      end
      this << Element.build("math-right") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(right_symbol, true, nil, false)
        end
      end
    end
    add_spacing(this, spacing)
    block&.call(content_element)
    return this
  end

  def build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, spacing = nil, &block)
    this = Nodes[]
    left_element, right_element = nil
    this << Element.build("math-paren") do |this|
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
      this << Element.build("math-parencont") do |this|
        left_element = this
      end
      this << Element.build("math-center") do |this|
        this["class"] = "cpar"
        this << Element.build("math-o") do |this|
          this << Text.new(right_symbol, true, nil, false)
        end
      end
      this << Element.build("math-parencont") do |this|
        right_element = this
      end
      this << Element.build("math-right") do |this|
        this << Element.build("math-o") do |this|
          this << Text.new(right_symbol, true, nil, false)
        end
      end
    end
    add_spacing(this, spacing)
    block&.call(left_element, right_element)
    return this
  end

  def fetch_integral_symbol(name, size)
    size_index = (size == "large") ? 1 : 0
    symbol = DATA.dig("integral", name, size_index) || ""
    return symbol
  end

  def build_integral(symbol, spacing = nil, &block)
    this = Nodes[]
    base_element, sub_element, super_element = nil
    this << Element.build("math-subsup") do |this|
      this["class"] = "int"
      this << Element.build("math-base") do |this|
        base_element = this
        this << Element.build("math-o") do |this|
          this["class"] = "int"
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
    add_spacing(this, spacing)
    block&.call(sub_element, super_element)
    modify_subsuper(base_element, sub_element, super_element, nil, nil)
    return this
  end

  def fetch_sum_symbol(name, size)
    size_index = (size == "large") ? 1 : 0
    symbol = DATA.dig("sum", name, size_index) || ""
    return symbol
  end

  def build_sum(symbol, spacing = nil, &block)
    this = Nodes[]
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
    add_spacing(this, spacing)
    block&.call(under_element, over_element)
    modify_underover(under_element, over_element)
    return this
  end

  def build_accent(under_symbol, over_symbol, spacing = nil, &block)
    this = Nodes[]
    base_element, under_element, over_element = nil
    underover_element = nil
    this << Element.build("math-underover") do |this|
      underover_element = this
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
    add_spacing(this, spacing)
    block&.call(base_element)
    modify_underover(under_element, over_element)
    modify_accent(base_element, under_element, over_element)
    return this
  end

  def modify_accent(base_element, under_element, over_element)
    children = base_element.children
    if children.size == 1
      child = children.first
      if child.name == "math-i" && (child["class"].split(" ") & ["fun", "rm", "alt"]).empty?
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

  def build_wide(kind, under_symbol, over_symbol, modify, spacing = nil, &block)
    this = Nodes[]
    base_element, under_element, over_element = nil
    this << Element.build("math-underover") do |this|
      this["class"] = "wid"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-kind"] = kind
      end
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
    add_spacing(this, spacing)
    block&.call(base_element)
    modify_underover(under_element, over_element)
    return this
  end

  def build_array(type, align_config, raw, spacing = nil, &block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-table") do |this|
      this["class"] = type
      table_element = this
    end
    add_spacing(this, spacing)
    block&.call(table_element)
    modify_array(table_element, type, align_config, raw)
    return this
  end

  def build_diagram(vertical_gaps_string, horizontal_gaps_string, spacing = nil, &block)
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
    add_spacing(this, spacing)
    block&.call(table_element)
    modify_diagram(table_element, vertical_gaps_string, horizontal_gaps_string)
    modify_array(table_element, "diag", nil, false)
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

  def modify_array(element, type, align_config, raw)
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

  def build_array_cell(spacing = nil, &block)
    this = Nodes[]
    cell_element = nil
    this << Element.build("math-cell") do |this|
      cell_element = this
    end
    add_spacing(this, spacing)
    block&.call(cell_element)
    return this
  end

  def build_diagram_vertex(name, spacing = nil, &block)
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
    add_spacing(this, spacing)
    block&.call(vertex_element)
    return this
  end

  def build_arrow(name, configs, spacing = nil, &block)
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
    add_spacing(this, spacing)
    block&.call(label_element)
    return this
  end

  def build_group(transform_configs, spacing = nil, &block)
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
    add_spacing(this, spacing)
    block&.call(content_element)
    return this
  end

  def build_space(type, spacing = nil)
    this = Nodes[]
    this << Element.build("math-space") do |this|
      this["class"] = type
    end
    add_spacing(this, spacing)
    return this
  end

  def build_phantom(type, spacing = nil, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-phantom") do |this|
      this["class"] = ["lpres", "rpres"].join(" ")
      if type
        this["class"] = [*this["class"].split(" "), type].join(" ")
      end
      content_element = this
    end
    add_spacing(this, spacing)
    block&.call(content_element)
    return this
  end

  def build_text(text, spacing = nil, &block)
    this = Nodes[]
    this << Element.build("math-text") do |this|
      this << Text.new(text, true, nil, false)
    end
    add_spacing(this, spacing)
    return this
  end

  private

  def self.create_data
    path = File.expand_path("../" + DATA_PATH, __FILE__)
    data = JSON.parse(File.read(path))
    return data
  end

  DATA = self.create_data

end