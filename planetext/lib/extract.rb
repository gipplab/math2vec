#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'settingslogic'
require 'pathname'
require 'nokogiri'
require 'optparse'
require 'fileutils'
require 'json'
require_relative "html_entity_map"



module PaperVu
  module Extract
    DEFAULT_DIR = 'data'
    DEFAULT_CONFIG = 'extract.yaml'

    class Document
      attr_reader :unknown_standoffs, :brat_ann, :text, :enriched_xml

      PREFIX = "kmcs-"
      REPLACEMENT_FORMAT = "__%{node}_%{count}__"

      class Standoff
        attr_reader :displacement_name, :name, :attributes, :file_name
        attr_accessor :start_offset, :end_offset
        def initialize(start_offset, end_offset, name, attributes, file_name, displacement_name)
          @start_offset = start_offset
          @end_offset = end_offset
          @name = name
          @attributes = attributes
          @file_name = file_name
          @displacement_name = displacement_name
        end

        def to_s
          "#{@start_offset}\t#{@end_offset}\t#{@name}\t#{@attributes}"
        end

        def <=>(other)
          result = start_offset <=> other.start_offset
          if result != 0
            result
          else
            other.end_offset <=> end_offset
          end
        end
      end


      def initialize(str, opts={})
        str = HTMLEntityMap.replace(str)
        @opts = opts
        @document =
          if @opts[:read_as_html]
            Nokogiri::HTML(str, nil, 'UTF-8')
          else
            Nokogiri::XML(str, nil, 'UTF-8')
          end
        if @opts[:use_xpath]
          @namespaces = @document.collect_namespaces
        else
          @document.remove_namespaces!
          @namespaces = nil
        end
        @replacement_sequence = Hash.new(0)
        @unknown_standoffs = {}
        @displacements = {}
        @offset = 0
        @brat_ann = []
        @ann_count = 0
        replace_cdata!
        deactivate_scripts! if @opts[:deactivate_scripts]
        collect_notable_elements

        remove_whitespace!(@document.root) if @opts[:remove_whitespace]
        note_replacements!(@document.root)
        displacement_text = note_displacements!
        save_format_option = @opts[:write_as_xhtml] ?
          Nokogiri::XML::Node::SaveOptions::AS_XHTML :
          Nokogiri::XML::Node::SaveOptions::AS_XML
        @enriched_xml = @document.root.to_xml(:save_with => save_format_option | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).
          # Apparently a bug in Nokogiri makes this necessary:
          gsub(%r{(xmlns="http://www\.w3\.org/1999/xhtml") \1}, "\\1")
        replace!
        @text =
          if @document.root
            @document.root.content + displacement_text
          else
            displacement_text
          end
        @brat_ann = @brat_ann.join("\n")
      end

      def select_elements(selectors)
        return [] if selectors.nil? || selectors.empty?

        if @opts[:use_xpath]
          @document.xpath(selectors.join('|'), @namespaces)
        else
          @document.css(selectors.join(','))
        end
      end

      def collect_notable_elements
        @replaced = select_elements(@opts[:replaced])
        @removed = select_elements(@opts[:removed])
        @displaced = select_elements(@opts[:displaced])
        @ignored = select_elements(@opts[:ignored])
        @newline = select_elements(@opts[:newline])
      end

      def deactivate_scripts!
        @document.css('script').each do |node|
          if @opts[:read_as_html]
            # HTML does not interpret entities inside script tags
            # Possible false positives in strings :( XXX
            node.inner_html = node.inner_html.gsub(/<!--(.*)-->/m, '\1')
          end
          type = node['type']
          if !type
            node['type'] = "application/#{PREFIX}DEFAULT"
          elsif (match = %r{^(text|application)/(x-)?(javascript)$}i.match(type))
            node['type'] = "#{match[1]}/#{match[2]}#{PREFIX}#{match[3]}"
          end
          language = node['language']
          if language && 'javascript' == language.downcase
            node['language'] = PREFIX + language
          end
        end
        @document.css('noscript').each do |node|
          content = node.to_xhtml
          content.gsub!(/<!--(.*?)-->/, "<!-#{PREFIX}$1-#{PREFIX}>")
          node.replace("<!--#{PREFIX}#{content}-->")
        end
      end

      def replace_cdata!
        @document.search('//*/text()').select(&:cdata?).each do |cdata|
          text = @document.create_text_node(cdata.text)
          cdata.replace(text)
        end
      end

      def remove_whitespace!(node=@document)
        if node.text?
          text = node.content

          # replace
          # * starting and ending whitespace that includes
          #   line breaks with a single line break
          #   e.g. text between closing and opening tags,
          #        "</p>\n     <p>" -> "</p>\n</p>"
          # * multiple whitespace with single whitespace
          text = text.
            sub(/^\s*?\n\s*/, "\n").
            sub(/\s*?\n\s*$/, "\n").
            gsub(/\s\s+/, ' ')

          # remove newlines from inside the string
          if replace_newlines = @opts[:replace_newlines]
            if @opts[:replace_all_newlines]
              text.gsub!(/\u00ad?\n/, replace_newlines)
            else
              text.gsub!(/(?<=\S)\u00ad?\n(?=\S)/, replace_newlines)
            end
          end

          # trim the element is at the start/end of a tag
          # e.g. "<p> foo </p>" -> "<p>foo</p>"
          # but not if it is inside:
          # e.g. "<p><b>bar</b> foo <b>bar</b></p>" unchanged
          text.gsub!(/^\s/, '') unless node.previous_sibling
          text.gsub!(/\s$/, '') unless node.next_sibling

          node.content = text
        else
          node.children.each do |child|
            remove_whitespace!(child)
          end
        end
      end

      def note_replacements!(node=@document, displacement_name=nil, displacement_data=nil)
        return if node.comment?

        if node.text?
          @offset += node.text.length
          if !displacement_name.nil?
            displacement_data << node.text
          end
        else
          name = node.name
          recurse_displaced = false
          replacement =
            if @replaced.include?(node)
              create_ann = true
              replacement = REPLACEMENT_FORMAT %
                { node: name.upcase, count: @replacement_sequence[name] }
              @replacement_sequence[name] += 1
              if !displacement_name.nil?
                displacement_data << replacement
              end
              replacement
            elsif @newline.include?(node)
              node["#{PREFIX}r"] = "\n"
            elsif @removed.include?(node)
              node["#{PREFIX}r"] = ""
            elsif @displaced.include?(node)
              displacement_name = "#{REPLACEMENT_FORMAT}" %
                { node: "IND_#{name.upcase}", count: @replacement_sequence[name] }
              @replacement_sequence[name] += 1
              displacement_data = String.new
              @displacements[displacement_name] = [node, @offset, displacement_data]
              recurse_displaced = true
              @opts[:mark_displacement] ? displacement_name : ""
            elsif @ignored.include?(node)
              false
            end

          if replacement == false # ignored
            node.children.each do |child|
              note_replacements!(child, displacement_name, displacement_data)
            end
          elsif replacement # replaced
            node["#{PREFIX}r"] = replacement
            replacement_end = @offset + replacement.length

            if create_ann
              @ann_count += 1
              @brat_ann << "T#{@ann_count}\t#{name} #{@offset} #{replacement_end}\t#{replacement}"
              if ["math", "abbr", "cite", "ul"].include? name
                text = node.to_s.gsub(/\n/, ' ')
              else
                text = node.text.gsub(/\n/, ' ')
              end
              @brat_ann << "##{@ann_count}\tAnnotatorNotes T#{@ann_count}\t#{text}"
            end

            if recurse_displaced
              node.children.each do |child|
                note_replacements!(child, displacement_name, displacement_data)
              end
            end

            @offset = replacement_end
          else # unknown
            @unknown_standoffs[node] = @offset

            if @opts[:opaque_unknowns]
              @offset += node.content.length
            else
              node.children.each do |child|
                note_replacements!(child, displacement_name, displacement_data)
              end
            end

            attributes = node.attributes.inject({}) { |h, t| h[t[0]] = t[1].to_s; h }
            namespaced_name = node.namespace ?
              "#{node.namespace.prefix || 'xmlns'}:#{node.name}" :
              node.name
            @unknown_standoffs[node] =
                Standoff.new(@unknown_standoffs[node], @offset, namespaced_name, attributes, @opts[:file_name], displacement_name)
          end
        end
      end

      def note_displacements!
        @displacements.map do |displacement_name, displaced_info|
          displaced_node, displaced_offset, displaced_data = *displaced_info
          displaced_text = displaced_data #displaced_node.text
          displacement_mod_name = @opts[:mark_displacement] ? displacement_name.sub('IND', 'IND_TEXT')[1..-2] + ":\n" : ''
          displaced_header = "\n\n\n#{displacement_mod_name}"
          displaced_text_all = displaced_header + displaced_text
          displaced_info[2] = @offset + displaced_header.length - displaced_offset
          displaced_node["#{PREFIX}d"] = "#{@offset + displaced_header.length},#{@offset + displaced_text_all.length}"
          @offset += displaced_text.length
          displaced_header + displaced_text
        end.join('')
      end

      def replace!
        @document.css("[#{PREFIX}r]").each do |node|
          node.replace(Nokogiri::XML::Text.new(node["#{PREFIX}r"], @document))
        end
        @unknown_standoffs.each do |node, standoff|
          next unless standoff.displacement_name
          displaced_delta = @displacements[standoff.displacement_name][2]
          standoff.start_offset += displaced_delta
          standoff.end_offset += displaced_delta
        end
        @unknown_standoffs = @unknown_standoffs.values.sort
      end

      def self.process_file(path, basedir, opts={})
        relpath = path.dirname.relative_path_from(basedir)
        outdir = opts[:outdir] + relpath
        FileUtils.mkdir_p(outdir) if opts[:force]
        outfile_extfree = outdir + path.basename('.*')

        str = File.read(path, encoding: 'UTF-8')
        doc = Document.new(str, opts)

        File.open("#{outfile_extfree}.standoffs", "w") do |f|
          f.write(doc.unknown_standoffs.join("\n"))
        end

        File.open("#{outfile_extfree}.xhtml", 'w') do |f|
          f.write(doc.enriched_xml)
        end

        File.open("#{outfile_extfree}.txt", 'w') do |f|
          f.write(doc.text)
        end

        File.open("#{outfile_extfree}.ann", 'w') do |f|
          f.puts(doc.brat_ann)
        end
      end

      def self.process_dir(dir, basedir, opts)
        Pathname.glob(dir + '*').each do |path|
          if path.directory? && path != opts[:outdir]
            process_dir(path, basedir, opts)
          elsif %w(.html .xhtml).include?(path.extname)
            process_file(path, basedir, opts)
          end
        end
      end
    end


    if $0 == __FILE__
      self_path = Pathname.new($0)
      self_name = self_path.basename
      outdir = nil
      force = false
      config = Pathname.new(ENV['HOME'] || '~') + ('.' + PaperVu::Extract::DEFAULT_CONFIG)
      config = self_path.dirname + PaperVu::Extract::DEFAULT_CONFIG unless config.file?

      option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #$0 [options] <xhtml_source>"
        opts.on '-o', '--output DIR', "Output directory (#{DEFAULT_DIR})" do |dir|
          outdir = Pathname.new(dir)
        end
        opts.on '-c', '--config FILE', "Configuration file (#{config})" do |file|
          config = Pathname.new(file)
        end
        opts.on '-f', '--[no-]force', "Create output directory if absent (#{force})" do |bool|
          force = bool
        end
        opts.on_tail '-h', '--help', 'Show this message' do
          puts opts
          exit
        end
      end
      option_parser.parse!
      unless ARGV.length == 1
        $stderr.puts "Error: #{self_name} expects exactly one file or directory.\nUse `#$0 -h` for help."
        exit
      end

      $config = YAML::load(File.read(config), encoding: 'UTF-8')

      path = Pathname.new(ARGV[0])
      path_is_dir = path.directory?

      outdir = $config["outdir"] =
        if outdir
          Pathname.new(outdir)
        elsif path_is_dir
          Pathname.new(DEFAULT_DIR)
        else
          path.dirname + PaperVu::Extract::DEFAULT_DIR
        end

      unless outdir.directory?
        if force
          outdir.mkpath
        else
          $stderr.puts "Error: #{outdir} is not a directory"
          exit
        end
      end

      $config['force'] = force

      if path_is_dir
        Document.process_dir(path, path, $config)
      else
        Document.process_file(path, path.dirname, $config)
      end

    end
  end
end
