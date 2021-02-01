# coding: utf-8


module Zenithal::ZoticaBuilder

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
  ROLES = ["bin", "rel", "sbin", "srel", "del", "fun", "not", "ord", "lpar", "rpar", "cpar"]
  ALIGNS = {"c" => "center", "l" => "left", "r" => "right"}

  module_function

  def apply_options(nodes, options)
    nodes.each do |node|
      if node.is_a?(REXML::Element) && options[:role]
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
    this = REXML::Nodes[]
    element = nil
    this << REXML::Element.build("math-n") do |this|
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
    this = REXML::Nodes[]
    element = nil
    font_type = (types.include?("alt")) ? "math" : "main"
    this << REXML::Element.build("math-i") do |this|
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
    this = REXML::Nodes[]
    element = nil
    font_type = (types.include?("txt")) ? "main" : "math"
    this << REXML::Element.build("math-o") do |this|
      this["class"] = types.join(" ")
      this["data-cont"] = symbol
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
    this = REXML::Nodes[]
    this << REXML::Element.build("math-strut") do |this|
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
      this << REXML::Element.build("math-text") do |this|
        this["style"] += "line-height: 1;"
        this << ~" "
      end
    end
    apply_options(this, options)
    return this
  end

  def build_subsuper(options = {}, &block)
    this = REXML::Nodes[]
    base_element, sub_element, super_element, left_sub_element, left_super_element = nil
    main_element = nil
    this << REXML::Element.build("math-subsup") do |this|
      main_element = this
      this << REXML::Element.build("math-lsub") do |this|
        left_sub_element = this
      end
      this << REXML::Element.build("math-lsup") do |this|
        left_super_element = this
      end
      this << REXML::Element.build("math-base") do |this|
        base_element = this
      end
      this << REXML::Element.build("math-sub") do |this|
        sub_element = this
      end
      this << REXML::Element.build("math-sup") do |this|
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
    this = REXML::Nodes[]
    base_element, under_element, over_element = nil
    main_element = nil
    this << REXML::Element.build("math-underover") do |this|
      main_element = this
      this << REXML::Element.build("math-over") do |this|
        over_element = this
      end
      this << REXML::Element.build("math-basewrap") do |this|
        this << REXML::Element.build("math-base") do |this|
          base_element = this
        end
        this << REXML::Element.build("math-under") do |this|
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
    this = REXML::Nodes[]
    numerator_element, denominator_element = nil
    this << REXML::Element.build("math-frac") do |this|
      this << REXML::Element.build("math-num") do |this|
        numerator_element = this
      end
      this << REXML::Element.build("math-denwrap") do |this|
        this << REXML::Element.new("math-line")
        this << REXML::Element.build("math-den") do |this|
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
    this = REXML::Nodes[]
    content_element, index_element = nil
    this << REXML::Element.build("math-rad") do |this|
      if modify
        this["class"] = "mod" 
      end
      this << REXML::Element.build("math-index") do |this|
        index_element = this
      end
      this << REXML::Element.build("math-sqrt") do |this|
        this << REXML::Element.build("math-surd") do |this|
          this << REXML::Element.build("math-o") do |this|
            this << REXML::Text.new(symbol, true, nil, false)
          end
        end
        this << REXML::Element.build("math-cont") do |this|
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
    this = REXML::Nodes[]
    content_element = nil
    this << REXML::Element.build("math-fence") do |this|
      this["class"] = "par"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-left"] = left_kind
        this["data-right"] = right_kind
      end
      this << REXML::Element.build("math-left") do |this|
        this << REXML::Element.build("math-o") do |this|
          this << REXML::Text.new(left_symbol, true, nil, false)
        end
      end
      this << REXML::Element.build("math-cont") do |this|
        content_element = this
      end
      this << REXML::Element.build("math-right") do |this|
        this << REXML::Element.build("math-o") do |this|
          this << REXML::Text.new(right_symbol, true, nil, false)
        end
      end
    end
    apply_options(this, options)
    block&.call(content_element)
    return this
  end

  def build_set(left_kind, right_kind, center_kind, left_symbol, right_symbol, center_symbol, modify, options = {}, &block)
    this = REXML::Nodes[]
    left_element, right_element = nil
    this << REXML::Element.build("math-fence") do |this|
      this["class"] = "par"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-left"] = left_kind
        this["data-right"] = right_kind
        this["data-center"] = center_kind
      end
      this << REXML::Element.build("math-left") do |this|
        this << REXML::Element.build("math-o") do |this|
          this << REXML::Text.new(left_symbol, true, nil, false)
        end
      end
      this << REXML::Element.build("math-cont") do |this|
        left_element = this
      end
      this << REXML::Element.build("math-center") do |this|
        this["class"] = "cpar"
        this << REXML::Element.build("math-o") do |this|
          this << REXML::Text.new(right_symbol, true, nil, false)
        end
      end
      this << REXML::Element.build("math-cont") do |this|
        right_element = this
      end
      this << REXML::Element.build("math-right") do |this|
        this << REXML::Element.build("math-o") do |this|
          this << REXML::Text.new(right_symbol, true, nil, false)
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
    this = REXML::Nodes[]
    base_element, sub_element, super_element = nil
    this << REXML::Element.build("math-subsup") do |this|
      this["class"] = "int"
      unless size == "lrg"
        this["class"] = [*this["class"].split(" "), size].join(" ")
      end
      this << REXML::Element.build("math-base") do |this|
        base_element = this
        this << REXML::Element.build("math-o") do |this|
          this["class"] = "int"
          unless size == "lrg"
            this["class"] = [*this["class"].split(" "), size].join(" ")
          end
          this << REXML::Text.new(symbol, true, nil, false)
        end
      end
      this << REXML::Element.build("math-sub") do |this|
        sub_element = this
      end
      this << REXML::Element.build("math-sup") do |this|
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
    this = REXML::Nodes[]
    if size == "lrg"
      under_element, over_element = nil
      this << REXML::Element.build("math-underover") do |this|
        this["class"] = "sum"
        this << REXML::Element.build("math-over") do |this|
          over_element = this
        end
        this << REXML::Element.build("math-basewrap") do |this|
          this << REXML::Element.build("math-base") do |this|
            this << REXML::Element.build("math-o") do |this|
              this["class"] = "sum"
              this << REXML::Text.new(symbol, true, nil, false)
            end
          end
          this << REXML::Element.build("math-under") do |this|
            under_element = this
          end
        end
      end
      apply_options(this, options)
      block&.call(under_element, over_element)
      modify_underover(under_element, over_element)
    else
      base_element, sub_element, super_element = nil
      this << REXML::Element.build("math-subsup") do |this|
        this["class"] = "sum inl"
        this << REXML::Element.build("math-base") do |this|
          base_element = this
          this << REXML::Element.build("math-o") do |this|
            this["class"] = "sum inl"
            this << REXML::Text.new(symbol, true, nil, false)
          end
        end
        this << REXML::Element.build("math-sub") do |this|
          sub_element = this
        end
        this << REXML::Element.build("math-sup") do |this|
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
    this = REXML::Nodes[]
    base_element, under_element, over_element = nil
    main_element = nil
    this << REXML::Element.build("math-underover") do |this|
      main_element = this
      this["class"] = "acc"
      this << REXML::Element.build("math-over") do |this|
        over_element = this
        if over_symbol
          this << REXML::Element.build("math-o") do |this|
            this["class"] = "acc"
            this << REXML::Text.new(over_symbol, true, nil, false)
          end
        end
      end
      this << REXML::Element.build("math-basewrap") do |this|
        this << REXML::Element.build("math-base") do |this|
          base_element = this
        end
        this << REXML::Element.build("math-under") do |this|
          under_element = this
          if under_symbol
            this << REXML::Element.build("math-o") do |this|
              this["class"] = "acc"
              this << REXML::Text.new(under_symbol, true, nil, false)
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
    this = REXML::Nodes[]
    base_element, under_element, over_element = nil
    main_element = nil
    this << REXML::Element.build("math-underover") do |this|
      this["class"] = "wid"
      if modify
        this["class"] = [*this["class"].split(" "), "mod"].join(" ")
        this["data-kind"] = kind
      end
      main_element = this
      this << REXML::Element.build("math-over") do |this|
        if over_symbol
          this << REXML::Element.build("math-o") do |this|
            this["class"] = "wid"
            this << REXML::Text.new(over_symbol, true, nil, false)
          end
        end
        over_element = this
      end
      this << REXML::Element.build("math-basewrap") do |this|
        this << REXML::Element.build("math-base") do |this|
          base_element = this
        end
        this << REXML::Element.build("math-under") do |this|
          if under_symbol
            this << REXML::Element.build("math-o") do |this|
              this["class"] = "wid"
              this << REXML::Text.new(under_symbol, true, nil, false)
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
    this = REXML::Nodes[]
    table_element = nil
    this << REXML::Element.build("math-table") do |this|
      this["class"] = type
      table_element = this
    end
    apply_options(this, options)
    block&.call(table_element)
    modify_table(table_element, type, align_config, raw)
    return this
  end

  def build_diagram(vertical_gaps_string, horizontal_gaps_string, align_baseline, options = {}, &block)
    this = REXML::Nodes[]
    table_element = nil
    this << REXML::Element.build("math-diagram") do |this|
      if vertical_gaps_string
        this["class"] = [*this["class"].split(" "), "vnon"].join(" ")
      end
      if horizontal_gaps_string
        this["class"] = [*this["class"].split(" "), "hnon"].join(" ")
      end
      if align_baseline
        this["class"] = [*this["class"].split(" "), "baseline"].join(" ")
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
          if vertical_gap =~ /^\-?\d+$/
            child["style"] += "margin-top: #{vertical_gap.to_f / 18}em; "
          else
            child["class"] = [*child["class"].split(" "), "v#{vertical_gap}"].join(" ")
          end
        end
        if horizontal_gap && column > 0
          if horizontal_gap =~ /^\-?\d+$/
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
    this = REXML::Nodes[]
    cell_element = nil
    this << REXML::Element.build("math-cell") do |this|
      cell_element = this
    end
    apply_options(this, options)
    block&.call(cell_element)
    return this
  end

  def build_diagram_vertex(name, options = {}, &block)
    this = REXML::Nodes[]
    vertex_element = nil
    this << REXML::Element.build("math-cellwrap") do |this|
      if name
        this["data-name"] = name
      end
      this << REXML::Element.build("math-cell") do |this|
        vertex_element = this
      end
    end
    apply_options(this, options)
    block&.call(vertex_element)
    return this
  end

  def build_arrow(name, configs, options = {}, &block)
    this = REXML::Nodes[]
    label_element = nil
    this << REXML::Element.build("math-arrow") do |this|
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
    this = REXML::Nodes[]
    content_element = nil
    this << REXML::Element.build("math-tree") do |this|
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
        inference_element = REXML::Element.build("math-infer") do |this|
          this << REXML::Element.build("math-label") do |this|
            if left_label_element.to_a.empty?
              this["class"] = "non"
            end
            left_label_element.each_element do |each_element|
              this << each_element
            end
          end
          this << REXML::Element.build("math-step") do |this|
            this << REXML::Element.build("math-ant") do |this|
              antecedent_elements.each do |antecedent_element|
                this << antecedent_element
              end
            end
            this << REXML::Element.build("math-conwrap") do |this|
              this << REXML::Element.new("math-line")
              this << REXML::Element.build("math-con") do |this|
                this << ZoticaBuilder.build_strut("upper").first
                this << ZoticaBuilder.build_strut("dlower").first
                this << child.get_elements("math-cont").first
              end
            end
          end
          this << REXML::Element.build("math-label") do |this|
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
    this = REXML::Nodes[]
    content_element = nil
    this << REXML::Element.build("math-axiom") do |this|
      content_element = this
    end
    apply_options(this, options)
    block&.call(content_element)
    return this
  end

  def build_tree_inference(number, options = {}, &block)
    this = REXML::Nodes[]
    content_element, right_label_element, left_label_element = nil
    this << REXML::Element.build("math-sys-infer") do |this|
      this["data-num"] = number.to_s
      this << REXML::Element.build("math-cont") do |this|
        content_element = this
      end
      this << REXML::Element.build("math-sys-rlabel") do |this|
        right_label_element = this
      end
      this << REXML::Element.build("math-sys-llabel") do |this|
        left_label_element = this
      end
    end
    apply_options(this, options)
    block&.call(content_element, right_label_element, left_label_element)
    return this
  end

  def build_group(transform_configs, options = {}, &block)
    this = REXML::Nodes[]
    content_element = nil
    this << REXML::Element.build("math-group") do |this|
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
    this = REXML::Nodes[]
    this << REXML::Element.build("math-space") do |this|
      if type =~ /^\-?\d+$/
        this["style"] += "margin-left: #{type.to_f / 18}em !important; "
      else
        if type =~ /^\-/
          this["class"] = type.gsub(/^\-/, "m")
        else
          this["class"] = type
        end
      end
    end
    apply_options(this, options)
    return this
  end

  def build_phantom(type, options = {}, &block)
    this = REXML::Nodes[]
    content_element = nil
    this << REXML::Element.build("math-phantom") do |this|
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
    this = REXML::Nodes[]
    this << REXML::Element.build("math-text") do |this|
      this << REXML::Text.new(text, true, nil, false)
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
    string << JSON.generate(Zenithal::ZoticaBuilder::DATA.slice("radical", "fence", "wide", "shift", "arrow"))
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
      file.write(Zenithal::ZoticaBuilder.create_font_string(:main))
    end
    File.open(math_font_path, "w") do |file|
      file.write(Zenithal::ZoticaBuilder.create_font_string(:math))
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