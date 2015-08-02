module Sublime
  module SyntaxFormatter
    def format_comment(str)
      str = str.strip.gsub("\t", "    ")
      str = str.rstrip + "\n" if str.include?("\n")
      str
    end

    def format_regex(str)
      if str.include? "\n"
        lines = str.split("\n")
        # trim common indentation off of each line
        if lines.size > 1
          common_indent = leading_whitespace(lines[1])
          lines[2..-1].each do |line|
            cur_indent = leading_whitespace(line)
            if cur_indent.start_with?(common_indent)
              next
            elsif common_indent.start_with?(cur_indent)
              common_indent = cur_indent
            else
              common_indent = ''
            end
          end
          # Generally the first line doesn't have any indentation, add some
          lines[0] = common_indent + lines[0].lstrip unless lines[0].start_with?(common_indent)
        else
          common_indent = leading_whitespace(lines[0])
        end
        str = lines.map { |line| line[common_indent.size..-1] }.join("\n").rstrip
      end
      str
    end

    def format_captures(cap)
      captures = {}
      cap.each do |key, value|
        unless value.key?('name')
          puts "patterns and includes are not supported within captures: #{cap}"
          next
        end

        begin
          captures[key.to_i] = value['name']
        rescue
          puts 'named capture used, this is unsupported'
          captures[key] = value['name']
        end
      end
      captures
    end

    def format_external_syntax(key)
      fail 'invalid external syntax name' if '#$'.include?(key[0])
      if key.include?('#')
        syntax, rule = key.split('#')
        return "scope:#{syntax}##{rule}"
      else
        return "scope:#{key}"
      end
    end

    def needs_quoting?(str)
      (
        str == "" ||
        str.start_with?('<<') ||
        "\"'%-:?@`&*!,#|>0123456789=".include?(str[0]) ||
        %w(true false null).include?(str) ||
        str.include?("# ") ||
        str.include?(': ') ||
        str.include?('[') ||
        str.include?(']') ||
        str.include?('{') ||
        str.include?('}') ||
        str.include?("\n") ||
        ":#".include?(str[-1]) ||
        str.strip != str
      )
    end

    def quote(str)
      if str.include?("\\") || str.include?('"')
        return "'" + str.gsub("'", "''") + "'"
      else
        return '"' + str.gsub("\\", "\\\\").gsub('"', '\\"') + '"'
      end
    end

    def leading_whitespace(str)
      str[0...(str.size - str.lstrip.size)]
    end
  end
end
