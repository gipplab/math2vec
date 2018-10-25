require 'yaml'
require 'settingslogic'
require 'archive/tar/minitar'
require 'zlib'
require 'concurrent'
require_relative 'extract'

NUM_OF_FILES = 3

module PlaneText

  module HashRefinement
    refine Hash do
      def hmap
        Hash[self.map {|k, v| yield k, v }]
      end
    end
  end

  class Config < Settingslogic
    source "config.yaml"
    suppress_errors true
    load!
  end

  module Common

    def extract(doc, conf={})
      conf = {
        remove_whitespace: true,
        replace_newlines: ' ',
        replace_all_newlines: true,
        use_xpath: true,
        opaque_unknowns: true,
        newline: [],
        mark_displacement: false
      }.merge(conf)
      PaperVu::Extract::Document.new(doc, conf)
    end


    def save_progress_file(progress_file, progress_data)
      File.write(progress_file, YAML.dump(progress_data))
    end

    def get_progress_data(progress_file)
      # find the user data pertaining to current dataset
      if File.exist?(progress_file)
        YAML.load(File.read(progress_file))
      else
        {
          processed_files: [],
          tags: {
            independent: [],
            decoration: [],
            object: [],
            metainfo: []
          }
        }
      end
    end

    def to_xpath(selectors)
      selectors.map { |tag, attr, *values|
        xpath = "//#{tag}"
        if !values.empty?
          values.each do |value|
            xpath += "[contains(concat(' ', normalize-space(@#{attr}), ' '), ' #{value} ')]"
          end
        elsif attr
          xpath += "[@#{attr}]"
        end
        xpath
      }
    end

    def to_selector(tag, attr=nil, *values)
      if !values.empty?
        "#{tag}[#{attr}: #{values.join(' ')}]"
      elsif attr
        "#{tag}[#{attr}]"
      else
        "#{tag}"
      end
    end

  end

  class UnknownSearcher
    include Common
    using HashRefinement

    attr_reader :selectors, :unknown_standoffs, :done, :total
    def initialize(dataset_dir, progress_file, limit=1)
      @dataset_dir = dataset_dir
      @progress_file = progress_file
      @all = limit == :all
      @limit = (Integer === limit && limit > 0) ? limit : nil
      @max_threads = 8
    end

    def per_doc(&block)
      @per_doc = block
    end

    def run
      progress_data = get_progress_data(@progress_file)

      @unknown_standoffs = Concurrent::Array.new
      all_files = Dir.chdir(@dataset_dir) { |dir|
        Dir['**/*.{xml,xhtml,html}']
      }

      processed_files = @all && [] || progress_data[:processed_files] || all_files
      unprocessed_files = all_files - processed_files

      processed_files_TS = Concurrent::Array.new
      processed_files_TS.concat(processed_files)

      @selectors = {
        displaced: to_xpath(progress_data[:tags][:independent]),
        ignored: to_xpath(progress_data[:tags][:decoration]),
        replaced: to_xpath(progress_data[:tags][:object]),
        removed: to_xpath(progress_data[:tags][:metainfo])
      }

      thread_pool = Concurrent::FixedThreadPool.new(@max_threads)

      dirty_files = 0
      proc_files = 0
      current_process = 0
      start_time = Time.now.to_f

      printf(
        "Processed %3d%% [%-50s] %06d/%06d %02d:%02d:%06.3f \r",
        0,
        "",
        proc_files,
        NUM_OF_FILES,
        0,
        0,
        0.0
      )

      unprocessed_files.each do |xml_file_name|
        xml_file = File.absolute_path(xml_file_name, @dataset_dir)
        xml = File.read(xml_file)
        read_as_html = xml_file_name[-5..-1] == '.html'
        write_as_xhtml = xml_file_name[-5..-1] != '.xml'
        opts = {
          file_name: xml_file_name,
          read_as_html: read_as_html,
          write_as_xhtml: write_as_xhtml,
          deactivate_scripts: write_as_xhtml
        }.merge(@selectors)

        thread_pool.post do
          doc = extract(xml, opts)
          @per_doc[xml_file, doc] if @per_doc # writes files

          # atomic operations are not thread safe
          @unknown_standoffs += doc.unknown_standoffs
          if doc.unknown_standoffs.empty?
            # atomic operations are not thread safe
            processed_files_TS << xml_file_name
          else
            dirty_files += 1
            # stop limit functionality for simplicity in multi threading environment
            #break if @limit && dirty_files >= @limit
          end

          proc_files += 1
          current_process = 100*proc_files/NUM_OF_FILES
          time = (Time.now.to_f - start_time).to_f/1000.to_f

          printf(
            "Processed %3d%% [%-50s] %06d/%06d %02d:%02d:%06.3f \r",
            current_process,
            "=" * (current_process/2),
            proc_files,
            NUM_OF_FILES,
            (time/3600),
            (time/60)%60,
            time%60
          )
        end
      end

      thread_pool.shutdown
      thread_pool.wait_for_termination

      print "\nProcess terminate. Cleaning up...\n"

      if processed_files_TS.length == all_files.length
        progress_data.delete(:processed_files)
      else
        progress_data[:processed_files] = processed_files_TS
      end
      save_progress_file(@progress_file, progress_data) unless @all

      @selectors = progress_data[:tags].hmap { |type, selector_list|
        selector_texts = selector_list.map { |selector_array|
          to_selector(*selector_array)
        }
        [type, selector_texts]
      }

      @done = processed_files_TS.length
      @total = all_files.length
      self
    end

    def insert_standoff_data(unknowns, standoff, attr_name)
      attr = unknowns[standoff.name][attr_name] ||= [
        {}, # words
        [], # instances
        {} # distinct combos TODO
      ]
      instance_data = [
        standoff.start_offset, # start
        standoff.end_offset, # end
        standoff.file_name, # file name
        standoff.attributes[attr_name] # value
      ]
      index = attr[1].size
      attr[1] << instance_data
      [attr, index]
    end

    def tree
      {}.tap { |unknowns|
        @unknown_standoffs.each do |standoff|
          unknowns[standoff.name] ||= {}
          if standoff.attributes.empty?
            attr, index = *insert_standoff_data(unknowns, standoff, '')
          else
            standoff.attributes.each do |name, values|
              attr, index = *insert_standoff_data(unknowns, standoff, name)
              words = values.split(/\s+/)
              if words.empty?
                (attr[0][''] ||= []) << index
              else
                words.each do |word|
                  (attr[0][word] ||= []) << index
                end
              end
            end
          end
        end
      }
    end
  end

  class TarGzipPacker
    def initialize
      @stringio = StringIO.new
      gz = Zlib::GzipWriter.new(@stringio)
      @out = Archive::Tar::Minitar::Output.new(gz)
      yield self and close if block_given?
    end

    def add_entry(name, string)
      # Minitar doesn't handle UTF-8 well
      bytes = string.dup
      bytes.force_encoding('ASCII')

      stats = {
        mode: 0o644,
        mtime: Time.new,
        size: bytes.size,
        gid: nil,
        uid: nil
      }
      @out.tar.add_file_simple(name.to_s, stats) do |os|
        os.write(bytes)
      end
      self
    end

    def close
      return unless @out
      @out.close
      @out = nil
      self
    end

    def to_s
      close
      @stringio.string
    end
  end
end
