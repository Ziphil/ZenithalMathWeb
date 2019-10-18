# coding: utf-8


require 'json'
require 'pp'
require 'rexml/document'
include REXML


module ZenmathBuilder

  DATA_PATH = "resource/math.json"
  SPACE_ALTERNATIVES = {"sfun" => "afun", "sbin" => "abin", "srel" => "arel", "ssbin" => "asbin", "ssrel" => "asrel", "scase" => "acase", "quad" => "sgl", "qquad" => "dbl"}
  PHANTOM_TYPES = {"ph" => nil, "vph" => "ver", "hph" => "hor"}
  SPACINGS = ["bin", "rel", "sbin", "srel", "del", "fun", "not", "ord", "lpar", "rpar", "cpar"]
  ALIGNS = {"c" => "center", "l" => "left", "r" => "right"}

  private

  def create_math_element(name, attributes, children_list)
    this = Nodes[]
    spacing = ZenmathBuilder.determine_spacing(attributes)
    case name
    when DATA["paren"].method(:key?)
      stretch_level = attributes["s"]
      left_symbol = ZenmathBuilder.fetch_paren_symbol(name, 0, stretch_level)
      right_symbol = ZenmathBuilder.fetch_paren_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << ZenmathBuilder.build_paren(name, name, left_symbol, right_symbol, modify, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "fence"
      stretch_level = attributes["s"]
      left_kind = attributes["l"] || "paren"
      right_kind = attributes["r"] || "paren"
      left_symbol = ZenmathBuilder.fetch_paren_symbol(left_kind, 0, stretch_level)
      right_symbol = ZenmathBuilder.fetch_paren_symbol(right_kind, 1, stretch_level)
      modify = !stretch_level
      this << ZenmathBuilder.build_paren(left_kind, right_kind, left_symbol, right_symbol, modify, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "set"
      stretch_level = attributes["s"]
      left_kind = attributes["l"] || "brace"
      right_kind = attributes["r"] || "brace"
      center_kind = attributes["c"] || "vert"
      left_symbol = ZenmathBuilder.fetch_paren_symbol(left_kind, 0, stretch_level)
      right_symbol = ZenmathBuilder.fetch_paren_symbol(right_kind, 1, stretch_level)
      center_symbol = ZenmathBuilder.fetch_paren_symbol(center_kind, 0, stretch_level)
      modify = !stretch_level
      this << ZenmathBuilder.build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, spacing) do |left_this, right_this|
        left_this << children_list[0]
        right_this << children_list[1]
      end
    when DATA["integral"].method(:key?)
      symbol = ZenmathBuilder.fetch_integral_symbol(name, "large")
      this << ZenmathBuilder.build_integral(symbol, spacing) do |sub_this, super_this|
        sub_this << children_list[0]
        super_this << children_list[1]
      end
    when DATA["sum"].method(:key?)
      symbol = ZenmathBuilder.fetch_sum_symbol(name, "large")
      this << ZenmathBuilder.build_sum(symbol, spacing) do |under_this, over_this|
        under_this << children_list[0]
        over_this << children_list[1]
      end
    when DATA["accent"].method(:key?)
      under_symbol = ZenmathBuilder.fetch_accent_symbol(name, 0)
      over_symbol = ZenmathBuilder.fetch_accent_symbol(name, 1)
      this << ZenmathBuilder.build_accent(under_symbol, over_symbol, spacing) do |base_this|
        base_this << children_list[0]
      end
    when DATA["wide"].method(:key?)
      stretch_level = attributes["s"]
      under_symbol = ZenmathBuilder.fetch_wide_symbol(name, 0, stretch_level)
      over_symbol  = ZenmathBuilder.fetch_wide_symbol(name, 1, stretch_level)
      modify = !stretch_level
      this << ZenmathBuilder.build_wide(name, under_symbol, over_symbol, modify, spacing) do |base_this|
        base_this << children_list[0]
      end
    when DATA["function"].method(:include?)
      this << ZenmathBuilder.build_identifier(name, ["fun"], spacing)
    when DATA["identifier"].method(:key?)
      char = ZenmathBuilder.fetch_identifier_char(name)
      this << ZenmathBuilder.build_identifier(char, [], spacing)
    when DATA["operator"].method(:key?)
      symbol, types = ZenmathBuilder.fetch_operator_symbol(name)
      this << ZenmathBuilder.build_operator(symbol, types, spacing)
    when "sb"
      this << ZenmathBuilder.build_subsuper(spacing) do |base_this, sub_this, super_this|
        base_this << children_list[0]
        sub_this << children_list[1]
      end
    when "sp"
      this << ZenmathBuilder.build_subsuper(spacing) do |base_this, sub_this, super_this|
        base_this << children_list[0]
        super_this << children_list[1]
      end
    when "sbsp"
      this << ZenmathBuilder.build_subsuper(spacing) do |base_this, sub_this, super_this|
        base_this << children_list[0]
        sub_this << children_list[1]
        super_this << children_list[2]
      end
    when "un"
      this << ZenmathBuilder.build_underover(spacing) do |base_this, under_this, over_this|
        base_this << children_list[0]
        under_this << children_list[1]
      end
    when "ov"
      this << ZenmathBuilder.build_underover(spacing) do |base_this, under_this, over_this|
        base_this << children_list[0]
        over_this << children_list[1]
      end
    when "unov"
      this << ZenmathBuilder.build_underover(spacing) do |base_this, under_this, over_this|
        base_this << children_list[0]
        under_this << children_list[1]
        over_this << children_list[2]
      end
    when "frac"
      this << ZenmathBuilder.build_fraction(spacing) do |numerator_this, denominator_this|
        numerator_this << children_list[0]
        denominator_this << children_list[1]
      end
    when "sqrt"
      stretch_level = attributes["s"]
      symbol = ZenmathBuilder.fetch_radical_symbol(stretch_level)
      modify = !stretch_level
      this << ZenmathBuilder.build_radical(symbol, modify, spacing) do |content_this|
        content_this << children_list[0]
      end
    when "matrix"
      this << ZenmathBuilder.build_array("matrix", nil, false, spacing) do |table_this|
        table_this << children_list[0]
      end
    when "array"
      align_config = attributes["align"]
      this << ZenmathBuilder.build_array("array", align_config, true, spacing) do |table_this|
        table_this << children_list[0]
      end
    when "case"
      left_symbol = ZenmathBuilder.fetch_paren_symbol("brace", 0, nil)
      right_symbol = ZenmathBuilder.fetch_paren_symbol("none", 1, nil)
      this << ZenmathBuilder.build_paren("brace", "none", left_symbol, right_symbol, true, spacing) do |this|
        this << ZenmathBuilder.build_array("case", "ll", false) do |table_this|
          table_this << children_list[0]
        end
      end
    when "diag"
      this << ZenmathBuilder.build_diagram(spacing) do |table_this|
        table_this << children_list[0]
      end
    when "c"
      this << ZenmathBuilder.build_array_cell(spacing) do |cell_this|
        cell_this << children_list[0]
      end
    when "cc"
      children_list.each do |children|
        this << ZenmathBuilder.build_array_cell(spacing) do |cell_this|
          cell_this << children
        end
      end
      this << Element.new("math-sys-br")
    when "v"
      this << ZenmathBuilder.build_diagram_vertex(spacing) do |vertex_this|
        vertex_this << children_list[0]
      end
    when "vv"
      children_list.each do |children|
        this << ZenmathBuilder.build_diagram_vertex(spacing) do |vertex_this|
          vertex_this << children
        end
      end
      this << Element.new("math-sys-br")
    when "ar"
      place_config = attributes["p"]
      bend_angle = attributes["b"]
      invert = attributes["inv"]
      this << ZenmathBuilder.build_arrow(place_config, bend_angle, invert, spacing) do |label_this|
        label_this << children_list[0]
      end
    when "br"
      this << Element.new("math-sys-br")
    when "g"
      this << ZenmathBuilder.build_group(spacing) do |content_this|
        content_this << children_list[0]
      end
    when "s"
      type = attributes["t"] || "medium"
      this << ZenmathBuilder.build_space(type, spacing)
    when "ph", "vph", "hph"
      type = PHANTOM_TYPES[name]
      this << ZenmathBuilder.build_phantom(type, spacing) do |content_this|
        content_this << children_list[0]
      end
    when SPACE_ALTERNATIVES.method(:key?)
      type = SPACE_ALTERNATIVES[name]
      this << ZenmathBuilder.build_space(type, spacing)
    when "bb", "cal", "scr", "frak"
      raw_text = children_list[0].first.value
      text = ZenmathBuilder.fetch_alternative_identifier_text(name, raw_text)
      this << ZenmathBuilder.build_identifier(text, ["alt"], spacing)
    when "n"
      text = children_list[0].first.to_s
      this << ZenmathBuilder.build_number(text, spacing)
    when "i"
      types = attributes["t"]&.split(/\s*,\s*/) || []
      text = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(text, types, spacing)
    when "op"
      text = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(text, ["fun"], spacing)
    when "o"
      types = attributes["t"]&.split(/\s*,\s*/) || ["ord"]
      symbol = children_list[0].first.to_s
      this << ZenmathBuilder.build_operator(symbol, types, spacing)
    when "bf"
      text = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(text, ["bf"], spacing)
    when "rm"
      text = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(text, ["rm"], spacing)
    when "bfrm"
      text = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(text, ["bf", "rm"], spacing)
    when "text"
      text = children_list[0].first.value
      this << ZenmathBuilder.build_text(text, spacing)
    end
    return this
  end

  def create_math_text(text)
    this = Nodes[]
    text.each_char do |char|
      if char =~ /\p{Number}/
        this << ZenmathBuilder.build_number(char)
      elsif char =~ /\p{Letter}|\p{Mark}/
        this << ZenmathBuilder.build_identifier(char, [])
      elsif char !~ /\s/
        name = DATA["operator"].find{|s, (t, u)| char == t}&.first || char
        name = DATA["replacement"][name] || name
        symbol, kinds = DATA["operator"][name] || [name, ["bin"]]
        this << ZenmathBuilder.build_operator(symbol, kinds)
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

  def self.determine_spacing(attributes)
    spacing = nil
    SPACINGS.each do |each_spacing|
      if attributes[each_spacing]
        spacing = each_spacing
      end
    end
    return spacing
  end

  def self.add_spacing(nodes, spacing)
    nodes.each do |node|
      if node.is_a?(Element) && spacing
        classes = node["class"].split(" ") - SPACINGS
        classes << spacing
        node["class"] = classes.join(" ")
      end
    end
  end

  def self.build_number(text, spacing = nil)
    this = Nodes[]
    this << Element.build("math-n") do |this|
      this << Text.new(text, true, nil, false)
    end
    add_spacing(this, spacing)
    return this
  end

  def self.fetch_identifier_char(kind)
    char = DATA["identifier"].dig(kind) || ""
    return char
  end
  
  def self.fetch_alternative_identifier_text(kind, raw_text)
    text = raw_text.chars.map{|s| DATA.dig("alternative", kind, s) || ""}.join
    return text
  end

  def self.build_identifier(text, types, spacing = nil)
    this = Nodes[]
    this << Element.build("math-i") do |this|
      this["class"] = types.join(" ")
      this["class"] = [*this["class"].split(" "), spacing].join(" ")
      this << Text.new(text, true, nil, false)
    end
    add_spacing(this, spacing)
    return this
  end

  def self.fetch_operator_symbol(kind)
    symbol, types = DATA.dig("operator", kind) || ["", ["bin"]]
    return symbol, types
  end

  def self.build_operator(symbol, types, spacing = nil, &block)
    this = Nodes[]
    this << Element.build("math-o") do |this|
      this["class"] = types.join(" ")
      this << Text.new(symbol, true, nil, false)
    end
    add_spacing(this, spacing)
    return this
  end

  def self.build_subsuper(spacing = nil, &block)
    this = Nodes[]
    base_element, sub_element, super_element = nil
    this << Element.build("math-subsup") do |this|
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
    block&.call(base_element, sub_element, super_element)
    return this
  end

  def self.build_underover(spacing = nil, &block)
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
    return this
  end

  def self.build_fraction(spacing = nil, &block)
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
    return this
  end

  def self.fetch_radical_symbol(stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("radical", stretch_level) || ""
    return symbol
  end

  def self.build_radical(symbol, modify, spacing = nil, &block)
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
    return this
  end

  def self.fetch_paren_symbol(kind, position, stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("paren", kind, position, stretch_level) || ""
    return symbol
  end

  def self.build_paren(left_kind, right_kind, left_symbol, right_symbol, modify, spacing = nil, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-paren") do |this|
      this["class"] = "par"
      if modify
        this["class"] = [*this["class"].split(" "), "mod", "left-#{left_kind}", "right-#{right_kind}"].join(" ")
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

  def self.build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, spacing = nil, &block)
    this = Nodes[]
    left_element, right_element = nil
    this << Element.build("math-paren") do |this|
      this["class"] = "par"
      if modify
        this["class"] = [*this["class"].split(" "), "mod", "lpar", "rpar", "left-#{left_kind}", "right-#{right_kind}", "center-#{center_kind}"].join(" ")
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

  def self.fetch_integral_symbol(name, size)
    size_index = (size == "large") ? 1 : 0
    symbol = DATA.dig("integral", name, size_index) || ""
    return symbol
  end

  def self.build_integral(symbol, spacing = nil, &block)
    this = Nodes[]
    sub_element, super_element = nil
    this << Element.build("math-subsup") do |this|
      this["class"] = "int"
      this << Element.build("math-base") do |this|
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
    return this
  end

  def self.fetch_sum_symbol(name, size)
    size_index = (size == "large") ? 1 : 0
    symbol = DATA.dig("sum", name, size_index) || ""
    return symbol
  end

  def self.build_sum(symbol, spacing = nil, &block)
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
    return this
  end

  def self.build_accent(under_symbol, over_symbol, spacing = nil, &block)
    this = Nodes[]
    base_element = nil
    this << Element.build("math-underover") do |this|
      this["class"] = "acc"
      this << Element.build("math-over") do |this|
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
    return this
  end

  def self.fetch_accent_symbol(kind, position)
    symbol = DATA.dig("accent", kind, position) || nil
    return symbol
  end

  def self.fetch_wide_symbol(kind, position, stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("wide", kind, position, stretch_level) || nil
    return symbol
  end

  def self.build_wide(kind, under_symbol, over_symbol, modify, spacing = nil, &block)
    this = Nodes[]
    base_element = nil
    this << Element.build("math-underover") do |this|
      this["class"] = "wide"
      if modify
        this["class"] = [*this["class"].split(" "), "mod", "wide-#{kind}"].join(" ")
      end
      this << Element.build("math-over") do |this|
        if over_symbol
          this << Element.build("math-o") do |this|
            this["class"] = "wide"
            this << Text.new(over_symbol, true, nil, false)
          end
        end
      end
      this << Element.build("math-basewrap") do |this|
        this << Element.build("math-base") do |this|
          base_element = this
        end
        this << Element.build("math-under") do |this|
          if under_symbol
            this << Element.build("math-o") do |this|
              this["class"] = "wide"
              this << Text.new(under_symbol, true, nil, false)
            end
          end
        end
      end
    end
    add_spacing(this, spacing)
    block&.call(base_element)
    return this
  end

  def self.build_array(type, align_config, raw, spacing = nil, &block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-table") do |this|
      this["class"] = type
      table_element = this
    end
    add_spacing(this, spacing)
    block&.call(table_element)
    modify_array(table_element, align_config, raw)
    return this
  end

  def self.build_diagram(spacing = nil, &block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-diagram") do |this|
      table_element = this
    end
    add_spacing(this, spacing)
    block&.call(table_element)
    modify_array(table_element, nil, false)
    return this
  end

  def self.modify_array(element, align_config, raw)
    align_array = align_config&.chars
    cell_elements = element.elements.to_a
    column, row = 1, 1
    cell_elements.each_with_index do |child, i|
      if child.name == "math-cell" || child.name == "math-cellwrap"
        if raw
          extra_class = []
          extra_class << "lpres" unless column == 1
          extra_class << "rpres" unless cell_elements[i + 1]&.name == "math-sys-br"
          child["class"] = (child["class"].split(" ") + extra_class).join(" ")
        end
        child["style"] += "grid-row: #{row}; grid-column: #{column};"
        if align_array
          align = ALIGNS[align_array[column - 1]]
          child["style"] += "text-align: #{align};" 
        end
        column += 1
      elsif child.name == "math-sys-br"
        element.delete_element(child)
        row += 1
        column = 1
      end
    end
  end

  def self.build_array_cell(spacing = nil, &block)
    this = Nodes[]
    cell_element = nil
    this << Element.build("math-cell") do |this|
      cell_element = this
    end
    add_spacing(this, spacing)
    block&.call(cell_element)
    return this
  end

  def self.build_diagram_vertex(spacing = nil, &block)
    this = Nodes[]
    vertex_element = nil
    this << Element.build("math-cellwrap") do |this|
      this << Element.build("math-cell") do |this|
        vertex_element = this
      end
    end
    add_spacing(this, spacing)
    block&.call(vertex_element)
    return this
  end

  def self.build_arrow(place_config, bend_angle, invert, spacing = nil, &block)
    this = Nodes[]
    label_element = nil
    this << Element.build("math-arrow") do |this|
      this["data-place"] = place_config
      if bend_angle
        this["data-bend"] = bend_angle
      end
      if invert
        this["data-inv"] = "data-inv"
      end
      label_element = this
    end
    add_spacing(this, spacing)
    block&.call(label_element)
    return this
  end

  def self.build_group(spacing = nil, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-group") do |this|
      content_element = this
    end
    add_spacing(this, spacing)
    block&.call(content_element)
    return this
  end

  def self.build_style(types, spacing = nil, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-style") do |this|
      this["class"] = types.join(" ")
      content_element = this
    end
    add_spacing(this, spacing)
    block&.call(content_element)
    return this
  end

  def self.build_space(type, spacing = nil)
    this = Nodes[]
    this << Element.build("math-space") do |this|
      this["class"] = type
    end
    add_spacing(this, spacing)
    return this
  end

  def self.build_phantom(type, spacing = nil, &block)
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

  def self.build_text(text, spacing = nil, &block)
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