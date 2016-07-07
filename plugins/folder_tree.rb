module FolderTree
  # Mustache block helper to quickly build folder tree heirarchies in HTML.
  # The output uses nested unordered HTML lists.
  #
  # Usage:
  # {{# folder_tree }}
  #   pages
  #     about.md
  #   posts
  #   essays
  #     derp
  #       merp
  #         hi.txt
  # {{/ folder_tree }}
  #
  # See #nested_array_to_html for rendered HTML
  # @returns[String] HTML
  def folder_tree(sub_context)
    data = text_list_to_flat_array(sub_context)
    data = flat_array_to_nested_array(data)
    nested_array_to_html(data)
  end

  private

  # Tranforms a nested text list into a nested HTML unordered list.
  # Automatically recognizes files if the name has an extension.
  #
  # Input:
  #   pages
  #     about.md
  #   posts
  #   essays
  #     derp
  #       merp
  #         hi.txt
  #
  # Output:
  # <ul class="depth-0 folder-tree">
  #   <li>
  #     <i class="icon-folder-close"></i><span class="name">pages</span>
  #     <ul class="depth-1">
  #       <li><i class="icon-file-alt"></i><span class="name">about.md</span></li>
  #     </ul>
  #   </li>
  #   <li><i class="icon-folder-close"></i><span class="name">posts</span></li>
  #   <li>
  #     <i class="icon-folder-close"></i><span class="name">essays</span>
  #     <ul class="depth-1">
  #       <li>
  #         <i class="icon-folder-close"></i><span class="name">derp</span>
  #         <ul class="depth-2">
  #           <li>
  #             <i class="icon-folder-close"></i><span class="name">merp</span>
  #             <ul class="depth-3">
  #               <li><i class="icon-file-alt"></i><span class="name">hi.txt</span></li>
  #             </ul>
  #           </li>
  #         </ul>
  #       </li>
  #     </ul>
  #   </li>
  # </ul>
  # @return[String]
  def nested_array_to_html(nodes)
    classes = "depth-#{ nodes.first[:depth] }"
    classes += " folder-tree" if nodes.first[:depth].zero?

    html = "<ul class=\"#{ classes }\">"
    nodes.each do |node|
      html += "<li>"

      if node[:children]
        html += '<i class="icon-folder-close"></i>'
      else
        html += '<i class="icon-file-alt"></i>'
      end

      html += "<span class=\"name\">#{ node[:name].strip }</span>"
      unless (node[:children].nil? || node[:children].empty?)
        html += nested_array_to_html(node[:children]) 
      end
      html += '</li>'
    end

    html += '</ul>'

    html
  end

  # Transforms a nested text list into an Array of hashes with depth values.
  # Input:
  #   pages
  #     about.md
  #   posts
  #   essays
  #     derp
  #       merp
  #         hi.txt
  # 
  # Output:
  #   [
  #     { name: "pages", depth: 0 },
  #     { name: "about.md", depth: 1 },
  #     { name: "posts", depth: 0 },
  #     { name: "essays", depth: 0 },
  #     { name: "derp", depth: 1 },
  #     { name: "merp", depth: 2 },
  #     { name: "merp", depth: 3 }
  #   ]
  # @returns[Array]
  def text_list_to_flat_array(sub_context)
    indent_position = sub_context.lines.first.to_s =~ /\S/ || 0
    results = []

    sub_context.lines.each_with_index do |line, i|
      new_line = line[indent_position..-1]
      name = line.strip
      indent = new_line =~ /\S/ || 0
      depth = (indent / 2)
      data = {
        name: name,
        indent: indent,
        depth: depth
      }

      next if name.empty?

      previous_indent = i.zero? ? false : results[i-1][:indent]
      puts "i #{i}, prev: #{previous_indent}, indent: #{indent}"
      unless valid_nesting?(previous_indent, indent)
        raise "Illegal nesting: " +
              "#{ indent } spaces at line ##{ i+i } \"#{ name }\""
      end

      # assume no period is a folder-name.
      data[:children] = [] if File.extname(line.strip).empty?

      results << data
    end

    results
  end

  # Tranforms a flat Array of objects with depths into nested children structure
  #
  # Input:
  #   [
  #     { name: "pages", depth: 0 },
  #     { name: "about.md", depth: 1 },
  #     { name: "posts", depth: 0 },
  #     { name: "essays", depth: 0 },
  #     { name: "derp", depth: 1 },
  #     { name: "merp", depth: 2 },
  #     { name: "merp", depth: 3 }
  #   ]
  #
  # Output:
  #  [{ name: "pages", depth: 0, children: [{name: "about.md", depth: 1}] },
  #   { name: "posts", depth: 0, children: [] },
  #  { name: "essays",
  #    depth: 0,
  #    children: 
  #     [{name: "derp",
  #       depth: 1,
  #       children: 
  #        [{name: "merp",
  #          depth: 2,
  #          children: [{name: "hi.txt", depth: 3}]}]}]}]
  # @returns[Array]
  def flat_array_to_nested_array(nodes)
    output = []
    nodes.each do |node|
      reference = output
      node[:depth].times {
        reference.last[:children] ||= []
        reference = reference.last[:children]
      }

      reference << node
    end

    output
  end

  def valid_nesting?(previous, current)
    (current%2).zero? && ( !previous || (current - 2) <= previous ) 
  end
end

Ruhoh::Views::MasterView.__send__(:include, FolderTree)