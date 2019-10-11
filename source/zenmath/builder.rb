# coding: utf-8


require 'json'
require 'pp'
require 'rexml/document'
include REXML


module ZenmathBuilder

  DATA_PATH = "resource/math.json"

  private

  def create_math_element(name, attributes, children_list)
    this = Nodes[]
    case name
    when DATA["paren"].method(:key?)
      stretch_level = attributes["s"]
      left_symbol, right_symbol = ZenmathBuilder.fetch_paren_symbols(name, name, stretch_level)
      this << ZenmathBuilder.build_paren(name, name, left_symbol, right_symbol, stretch_level) do |content_this|
        content_this << children_list[0]
      end
    when DATA["integral"].method(:key?)
      symbol = ZenmathBuilder.fetch_integral_symbol(name)
      this << ZenmathBuilder.build_integral(symbol) do |sub_this, super_this|
        sub_this << children_list[0]
        super_this << children_list[1]
      end
    when DATA["sum"].method(:key?)
      symbol = ZenmathBuilder.fetch_sum_symbol(name)
      this << ZenmathBuilder.build_sum(symbol) do |under_this, over_this|
        under_this << children_list[0]
        over_this << children_list[1]
      end
    when DATA["accent"].method(:key?)
      under_symbol, over_symbol = DATA.dig("accent", name) || [nil, nil]
      this << ZenmathBuilder.build_accent(under_symbol, over_symbol) do |base_this|
        base_this << children_list[0]
      end
    when DATA["wide"].method(:key?)
      stretch_level = attributes["s"]
      under_symbol, over_symbol = ZenmathBuilder.fetch_wide_symbols(name, stretch_level)
      this << ZenmathBuilder.build_wide(name, under_symbol, over_symbol, stretch_level) do |base_this|
        base_this << children_list[0]
      end
    when DATA["function"].method(:include?)
      this << ZenmathBuilder.build_identifier(name, true)
    when DATA["identifier"].method(:key?)
      symbol = DATA["identifier"].fetch(name, "")
      this << ZenmathBuilder.build_identifier(symbol, false)
    when DATA["operator"].method(:key?)
      symbol, kinds = DATA.dig("operator", name) || [name, ["bin"]]
      this << ZenmathBuilder.build_operator(symbol, kinds)
    when "n"
      number = children_list[0].first.to_s
      this << ZenmathBuilder.build_number(number)
    when "i"
      name = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(name, false)
    when "op"
      name = children_list[0].first.to_s
      this << ZenmathBuilder.build_identifier(name, true)
    when "o"
      name = children_list[0].first.to_s
      this << ZenmathBuilder.build_operator(name, ["bin"])
    when "sb"
      this << ZenmathBuilder.build_subsuper do |base_this, sub_this, super_this|
        base_this << children_list[0]
        sub_this << children_list[1]
      end
    when "sp"
      this << ZenmathBuilder.build_subsuper do |base_this, sub_this, super_this|
        base_this << children_list[0]
        super_this << children_list[1]
      end
    when "sbsp"
      this << ZenmathBuilder.build_subsuper do |base_this, sub_this, super_this|
        base_this << children_list[0]
        sub_this << children_list[1]
        super_this << children_list[2]
      end
    when "un"
      this << ZenmathBuilder.build_underover do |base_this, under_this, over_this|
        base_this << children_list[0]
        under_this << children_list[1]
      end
    when "ov"
      this << ZenmathBuilder.build_underover do |base_this, under_this, over_this|
        base_this << children_list[0]
        over_this << children_list[1]
      end
    when "unov"
      this << ZenmathBuilder.build_underover do |base_this, under_this, over_this|
        base_this << children_list[0]
        under_this << children_list[1]
        over_this << children_list[2]
      end
    when "frac"
      this << ZenmathBuilder.build_fraction do |numerator_this, denominator_this|
        numerator_this << children_list[0]
        denominator_this << children_list[1]
      end
    when "sqrt"
      stretch_level = attributes["s"]
      symbol = ZenmathBuilder.fetch_radical_symbol(stretch_level)
      this << ZenmathBuilder.build_radical(symbol, stretch_level) do |content_this|
        content_this << children_list[0]
      end
    when "matrix"
      this << ZenmathBuilder.build_array(nil, false) do |table_this|
        table_this["class"] = "matrix"
        table_this << children_list[0]
      end
    when "array"
      align_config = attributes["align"]
      this << ZenmathBuilder.build_array(align_config, true) do |table_this|
        table_this["class"] = "array"
        table_this << children_list[0]
      end
    when "case"
      left_symbol, right_symbol = ZenmathBuilder.fetch_paren_symbols("brace", "none", nil)
      this << ZenmathBuilder.build_paren("brace", "none", left_symbol, right_symbol, nil) do |this|
        this << ZenmathBuilder.build_array("ll", false) do |table_this|
          table_this["class"] = "case"
          table_this << children_list[0]
        end
      end
    when "c"
      this << ZenmathBuilder.build_array_cell do |cell_this|
        cell_this << children_list[0]
      end
    when "cc"
      children_list.each do |children|
        this << ZenmathBuilder.build_array_cell do |cell_this|
          cell_this << children
        end
      end
      this << Element.new("math-sys-br")
    when "br"
      this << Element.new("math-sys-br")
    when "bf"
      this << ZenmathBuilder.build_style(["bold"]) do |content_this|
        content_this << children_list[0]
      end
    when "bb", "cal", "scr", "frak"
      alphabets = children_list[0].first.value
      symbol = alphabets.chars.map{|s| DATA.dig("alternative", name, s) || ""}.join
      this << ZenmathBuilder.build_identifier(symbol, false, true)
    when "text"
      text = children_list[0].first.value
      this << ZenmathBuilder.build_text(text)
    end
    return this
  end

  def create_math_text(text)
    this = Nodes[]
    text.each_char do |char|
      if char =~ /\d/
        this << ZenmathBuilder.build_number(char)
      elsif char =~ /[[:alpha:]]/
        this << ZenmathBuilder.build_identifier(char, false)
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

  def self.build_number(number)
    this = Nodes[]
    this << Element.build("math-n") do |this|
      this << Text.new(number, true, nil, false)
    end
    return this
  end

  def self.build_identifier(name, function = false, alternative = false)
    this = Nodes[]
    this << Element.build("math-i") do |this|
      classes = []
      classes << "fun" if function
      classes << "alt" if alternative
      this["class"] = classes.join(" ")
      this << Text.new(name, true, nil, false)
    end
    return this
  end

  def self.build_operator(symbol, kinds, &block)
    this = Nodes[]
    this << Element.build("math-o") do |this|
      this["class"] = kinds.join(" ")
      this << Text.new(symbol, true, nil, false)
    end
    return this
  end

  def self.build_subsuper(&block)
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
    block&.call(base_element, sub_element, super_element)
    return this
  end

  def self.build_underover(&block)
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
    block&.call(base_element, under_element, over_element)
    return this
  end

  def self.build_fraction(&block)
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
    block&.call(numerator_element, denominator_element)
    return this
  end

  def self.fetch_radical_symbol(stretch_level)
    stretch_level ||= "0"
    symbol = DATA.dig("radical", stretch_level) || ""
    return symbol
  end

  def self.build_radical(symbol, stretch_level, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-sqrt") do |this|
      this["class"] = "mod" unless stretch_level
      this << Element.build("math-surd") do |this|
        this["class"] = "s#{stretch_level}" if stretch_level
        this << Element.build("math-o") do |this|
          this << Text.new(symbol, true, nil, false)
        end
      end
      this << Element.build("math-sqrtcont") do |this|
        content_element = this
      end
    end
    block&.call(content_element)
    return this
  end

  def self.fetch_paren_symbols(left_kind, right_kind, stretch_level)
    stretch_level ||= "0"
    left_symbol = DATA.dig("paren", left_kind, 0, stretch_level) || ""
    right_symbol = DATA.dig("paren", right_kind, 1, stretch_level) || ""
    return left_symbol, right_symbol
  end

  def self.build_paren(left_kind, right_kind, left_symbol, right_symbol, stretch_level, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-paren") do |this|
      this["class"] = "mod left-#{left_kind} right-#{right_kind}" unless stretch_level
      this << Element.build("math-left") do |this|
        this << Element.build("math-o") do |this|
          this["class"] = "lp"
          this << Text.new(left_symbol, true, nil, false)
        end
      end
      this << Element.build("math-parencont") do |this|
        content_element = this
      end
      this << Element.build("math-right") do |this|
        this << Element.build("math-o") do |this|
          this["class"] = "rp"
          this << Text.new(right_symbol, true, nil, false)
        end
      end
    end
    block&.call(content_element)
    return this
  end

  def self.fetch_integral_symbol(name, size = :large)
    size_index = (size == :large) ? 1 : 0
    symbol = DATA.dig("integral", name, size_index) || ""
    return symbol
  end

  def self.build_integral(symbol, &block)
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
    block&.call(sub_element, super_element)
    return this
  end

  def self.fetch_sum_symbol(name, size = :large)
    size_index = (size == :large) ? 1 : 0
    symbol = DATA.dig("sum", name, size_index) || ""
    return symbol
  end

  def self.build_sum(symbol, &block)
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
    block&.call(under_element, over_element)
    return this
  end

  def self.build_accent(under_symbol, over_symbol, &block)
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
    block&.call(base_element)
    return this
  end

  def self.fetch_wide_symbols(kind, stretch_level)
    stretch_level ||= "0"
    under_symbol = DATA.dig("wide", kind, 0, stretch_level) || nil
    over_symbol = DATA.dig("wide", kind, 1, stretch_level) || nil
    return under_symbol, over_symbol
  end

  def self.build_wide(kind, under_symbol, over_symbol, stretch_level, &block)
    this = Nodes[]
    base_element = nil
    this << Element.build("math-underover") do |this|
      this["class"] = "wide"
      this["class"] = [*this["class"].split(" "), "mod", "wide-#{kind}"].join(" ") unless stretch_level
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
    block&.call(base_element)
    return this
  end

  ALIGNS = {"c" => "center", "l" => "left", "r" => "right"}

  def self.build_array(align_config = nil, raw = false, &block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-table") do |this|
      this["class"] = "mat"
      table_element = this
    end
    block&.call(table_element)
    align_array = align_config&.chars
    column, row = 1, 1
    table_element.elements.each_with_index do |child, i|
      if child.name == "math-cell"
        if raw
          extra_class = []
          extra_class << "lpres" unless column == 1
          extra_class << "rpres" unless table_element.elements[i + 1]&.name == "math-sys-br"
          child["class"] = (child["class"].split(" ") + extra_class).join(" ")
        end
        child["style"] += "grid-row: #{row}; grid-column: #{column};"
        if align_array
          align = ALIGNS[align_array[column - 1]]
          child["style"] += "text-align: #{align};" 
        end
        column += 1
      elsif child.name == "math-sys-br"
        table_element.delete_element(child)
        row += 1
        column = 1
      end
    end
    return this
  end

  def self.build_array_cell(&block)
    this = Nodes[]
    cell_element = nil
    this << Element.build("math-cell") do |this|
      cell_element = this
    end
    block&.call(cell_element)
    return this
  end

  def self.build_style(kinds, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-style") do |this|
      this["class"] = kinds.join(" ")
      content_element = this
    end
    block&.call(content_element)
    return this
  end

  def self.build_text(text, &block)
    this = Nodes[]
    this << Element.build("math-text") do |this|
      this << Text.new(text, true, nil, false)
    end
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