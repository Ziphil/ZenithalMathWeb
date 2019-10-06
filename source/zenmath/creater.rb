# coding: utf-8


require 'json'
require 'pp'
require 'rexml/document'
include REXML


module ZenithalMathCreater

  CREATION_METHODS = {
    :paren => :paren,
    :integral => :integral,
    :function => :function, :operator => :operator,
    "n" => :custom_number, "i" => :custom_identifier, "op" => :custom_identifier, "o" => :custom_operator,
    "text" => :raw_text,
    "sp" => :superscript, "sb" => :superscript, "sbsp" => :subsuperscript,
    "frac" => :fraction,
    "sqrt" => :radical
  }
  DATA_PATH = "resource/math.json"
  DATA = JSON.parse(File.read(File.expand_path("../" + DATA_PATH, __FILE__)))

  private

  def create_math_element(name, attributes, children_list)
    nodes = Nodes[]
    method_name = nil
    if DATA["paren"].key?(name)
      method_name = CREATION_METHODS[:paren]
    elsif DATA["integral"].key?(name)
      method_name = CREATION_METHODS[:integral]
    elsif DATA["function"].include?(name)
      method_name = CREATION_METHODS[:function]
    elsif DATA["operator"].key?(name)
      method_name = CREATION_METHODS[:operator]
    elsif CREATION_METHODS.key?(name)
      method_name = CREATION_METHODS[name]
    end
    if method_name
      nodes = send("create_#{method_name}", name, attributes, children_list)
    end
    return nodes
  end

  def create_math_text(text)
    this = Nodes[]
    text.each_char do |char|
      if char =~ /\d/
        this << Element.build("math-n") do |this|
          this << Text.new(char, true, nil, false)
        end
      elsif char =~ /[[:alpha:]]/
        this << Element.build("math-i") do |this|
          this << Text.new(char, true, nil, false)
        end
      elsif char !~ /\s/
        name = DATA["operator"].find{|s, (t, u)| char == t}&.first || char
        name = DATA["replacement"].fetch(name, name)
        this << create_operator(name, {}, [])
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

  def create_custom_number(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-n") do |this|
      this << children_list[0]
    end
    return this
  end

  def create_custom_identifier(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-i") do |this|
      this["class"] = name unless name == "i"
      this << children_list[0]
    end
    return this
  end

  def create_custom_operator(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-o") do |this|
      this << children_list[0]
    end
    return this
  end

  def create_operator(name, attributes, children_list)
    this = Nodes[]
    symbol, kind = DATA["operator"].fetch(name, [name, "bin"])
    this << Element.build("math-o") do |this|
      this["class"] = kind
      this << Text.new(symbol, true, nil, false)
    end
    return this
  end

  def create_superscript(name, attributes, children_list)
    this = Nodes[]
    element_name = (name == "sp") ? "math-sup" : "math-sub"
    this << Element.build(element_name) do |this|
      this << Element.build("math-base") do |this|
        this << children_list[0]
      end
      this << Element.build("math-scr") do |this|
        this << children_list[1]
      end
    end
    return this
  end

  def create_subsuperscript(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-subsup") do |this|
      this << Element.build("math-base") do |this|
        this << children_list[0]
      end
      this << Element.build("math-scr") do |this|
        this << children_list[1]
      end
      this << Element.build("math-scr") do |this|
        this << children_list[2]
      end
    end
    return this
  end

  def create_fraction(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-frac") do |this|
      this << Element.build("math-num") do |this|
        this << children_list[0]
      end
      this << Element.build("math-denwrap") do |this|
        this << Element.build("math-den") do |this|
          this << children_list[1]
        end
      end
    end
    return this
  end

  def create_radical(name, attributes, children_list)
    this = Nodes[]
    stretch = !attributes["s"]
    stretch_level = attributes["s"] || "0"
    symbol = DATA["radical"].fetch(stretch_level, "")
    this << Element.build("math-sqrt") do |this|
      this << Element.build("math-surd") do |this|
        this["class"] = "s#{stretch_level}" unless stretch
        this << Element.build("math-o") do |this|
          this << Text.new(symbol, true, nil, false)
        end
      end
      this << Element.build("math-sqrtcont") do |this|
        this["class"] = "md-sqrt" if stretch
        this << children_list[0]
      end
    end
    return this
  end

  def create_paren(name, attributes, children_list)
    this = Nodes[]
    stretch = !attributes["s"]
    stretch_level = attributes["s"] || "0"
    left_symbol, right_symbol = DATA["paren"][name].fetch(stretch_level, ["", ""])
    this << Element.build("math-o") do |this|
      this["class"] = "lp"
      this << Text.new(left_symbol, true, nil, false)
    end
    this << Element.build("math-row") do |this|
      this["class"] = "md-paren md-paren-#{name}" if stretch
      this << children_list[0]
    end
    this << Element.build("math-o") do |this|
      this["class"] = "rp"
      this << Text.new(right_symbol, true, nil, false)
    end
    return this
  end

  def create_function(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-i") do |this|
      this["class"] = "op"
      this << Text.new(name, true, nil, false)
    end
    return this
  end

  def create_raw_text(name, attributes, children_list)
    this = Nodes[]
    this << Element.build("math-text") do |this|
      this << children_list[0]
    end
    return this
  end

  def create_raw(name, attributes, children_list)
    this = Nodes[]
    this << children_list[0]
    return this
  end

end