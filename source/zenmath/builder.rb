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
      left_symbol, right_symbol = ZenmathBuilder.fetch_paren_symbols(name, stretch_level)
      this << ZenmathBuilder.build_paren(name, left_symbol, right_symbol, stretch_level) do |content_this|
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
      symbol, position = DATA["accent"].fetch(name, ["", "over"])
      position = position.intern
      this << ZenmathBuilder.build_accent(symbol, position) do |base_this|
        base_this << children_list[0]
      end
    when DATA["function"].method(:include?)
      this << ZenmathBuilder.build_identifier(name, true)
    when DATA["identifier"].method(:key?)
      symbol = DATA["identifier"].fetch(name, "")
      this << ZenmathBuilder.build_identifier(symbol, false)
    when DATA["operator"].method(:key?)
      symbol, kinds = DATA["operator"].fetch(name, [name, ["bin"]])
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
      this << ZenmathBuilder.build_matrix do |table_this|
        table_this << children_list[0]
      end
    when "r"
      this << ZenmathBuilder.build_table_row do |row_this|
        row_this <<  children_list[0]
      end
    when "c"
      this << ZenmathBuilder.build_table_cell do |cell_this|
        cell_this << children_list[0]
      end
    when "bb", "scr", "frak"
      alphabets = children_list[0].first.value
      symbol = alphabets.chars.map{|s| DATA["alternative"][name].fetch(s, "")}.join
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
        name = DATA["replacement"].fetch(name, name)
        symbol, kinds = DATA["operator"].fetch(name, [name, ["bin"]])
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
      if function
        this["class"] += " fun"
      end
      if alternative
        this["class"] += " alt"
      end
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
    symbol = DATA["radical"]&.fetch(stretch_level) || ""
    return symbol
  end

  def self.build_radical(symbol, stretch_level, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-sqrt") do |this|
      unless stretch_level
        this["class"] = "md-sqrt"
      end
      this << Element.build("math-surd") do |this|
        if stretch_level
          this["class"] = "s#{stretch_level}" 
        end
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

  def self.fetch_paren_symbols(kind, stretch_level)
    stretch_level ||= "0"
    left_symbol, right_symbol = DATA["paren"]&.fetch(kind)&.fetch("0") || ["", ""]
    return left_symbol, right_symbol
  end

  def self.build_paren(kind, left_symbol, right_symbol, stretch_level, &block)
    this = Nodes[]
    content_element = nil
    this << Element.build("math-paren") do |this|
      unless stretch_level
        this["class"] = "md-paren md-paren-#{kind}"
      end
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
    symbol = DATA["integral"]&.fetch(name)&.fetch(size_index) || ""
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
    symbol = DATA["sum"]&.fetch(name)&.fetch(size_index) || ""
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

  def self.build_accent(symbol, position = :over, &block)
    this = Nodes[]
    base_element = nil
    this << Element.build("math-underover") do |this|
      this["class"] = "acc"
      this << Element.build("math-over") do |this|
        if position == :over
          this << Element.build("math-o") do |this|
            this["class"] = "acc"
            this << Text.new(symbol, true, nil, false)
          end
        end
      end
      this << Element.build("math-basewrap") do |this|
        this << Element.build("math-base") do |this|
          base_element = this
        end
        this << Element.build("math-under") do |this|
          if position == :under
            this << Element.build("math-o") do |this|
              this["class"] = "acc"
              this << Text.new(symbol, true, nil, false)
            end
          end
        end
      end
    end
    block&.call(base_element)
    return this
  end

  def self.build_matrix(&block)
    this = Nodes[]
    table_element = nil
    this << Element.build("math-table") do |this|
      this["class"] = "mat"
      table_element = this
    end
    block&.call(table_element)
    return this
  end

  def self.build_table_row(&block)
    this = Nodes[]
    row_element = nil
    this << Element.build("math-row") do |this|
      row_element = this
    end
    block&.call(row_element)
    return this
  end

  def self.build_table_cell(&block)
    this = Nodes[]
    cell_element = nil
    this << Element.build("math-cell") do |this|
      cell_element = this
    end
    block&.call(cell_element)
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