require_relative "./syntax_formatter"

module Sublime
  class SyntaxYaml
    include SyntaxFormatter
    attr_reader :yaml
    TAB_SIZE = 2

    def initialize(val)
      @yaml = to_yaml(val, false, 0)
    end

    private

    def to_yaml(val, start_block_on_newline, indent)
      out = ''

      if indent == 0
        out += "%YAML 1.2\n---\n"
        out += "# http://www.sublimetext.com/docs/3/syntax.html\n"
      end

      if val.is_a?(Array)
        out += array_to_yaml(val, start_block_on_newline, indent)
      elsif val.is_a?(Hash)
        out += hash_to_yaml(val, start_block_on_newline, indent)
      elsif val.is_a?(String)
        out += string_to_yaml(val, start_block_on_newline, indent)
      elsif val.is_a?(TrueClass) || val.is_a?(FalseClass)
        out += boolean_to_yaml(val)
      else
        out += "#{val}\n"
      end
      # to_yaml will leave some trailing whitespace, remove it
      out.split("\n").map(&:rstrip).join("\n") + "\n"
    end

    def array_to_yaml(val, start_block_on_newline, indent)
      out = ''
      if val.size == 0
        out += "[]\n"
      else
        out += "\n" if start_block_on_newline
        val.each { |item| out += ' ' * indent + '- ' + to_yaml(item, false, indent + 2) }
      end
      out
    end

    def hash_to_yaml(val, start_block_on_newline, indent)
      out = ''
      out += "\n" if start_block_on_newline
      first = true
      order_keys(val.keys).each do |key|
        value = val[key]
        if !first || start_block_on_newline
          out += ' ' * indent
        else
          first = false
        end

        if key.is_a?(Numeric)
          out += key.to_s
        elsif needs_quoting?(key)
          out += quote(key)
        else
          out += key
        end

        out += ": "
        out += to_yaml(value, true, indent + TAB_SIZE)
      end
      out
    end

    def string_to_yaml(val, start_block_on_newline, indent)
      out = ''
      if needs_quoting?(val)
        if val.include?("\n")
          fail unless start_block_on_newline
          out += (val[-1] == "\n") ? "|\n" : "|-\n"
          val.split("\n").each { |line| out += "#{' ' * indent}#{line}\n" }
        else
          out += "#{quote(val)}\n"
        end
        return out
      else
        return "#{val}\n"
      end
    end

    def boolean_to_yaml(val)
      val ? "true\n" : "false\n"
    end

    def order_keys(list)
      key_order = %w(name main match comment file_extensions first_line_match hidden match scope main).reverse
      list = list.sort
      key_order.each do |key|
        if list.include?(key)
          list.delete_at(list.index(key))
          list.insert(0, key)
        end
      end
      list
    end

  end
end
