#!/usr/bin/env ruby

require 'bundler/setup'
require_relative '../lib/planetext'
require 'slim'
require 'fileutils'
require 'set'
require 'rack-flash'
require 'warden'

module PlaneText

  class App < Sinatra::Application
    include PlaneText::Common
    Config['datadir'] ||= File.join(settings.root, 'data')

    set :haml, format: :html5
    set :method_override, true
    set :static, true
    set :public_folder, File.join(settings.root, 'app/public')
    set :views, File.join(settings.root, 'app/views')
    enable :sessions
    set :session_secret, Config.webapp.session_secret

    configure :production do
      set :haml, ugly: true
      set :clean_trace, true
    end

    use Rack::Flash
    use Warden::Manager do |manager|
      manager.default_strategies :password
      manager.failure_app = self
    end

    Warden::Manager.before_failure do |env, opts|
      env['REQUEST_METHOD'] = "POST"
    end

    Warden::Strategies.add(:password) do
      def valid?
        params["username"] || params["password"]
      end
    
      def authenticate!
        user = params["username"]
        user = nil unless (users = Config.webapp.users) && (passwd = users[user]) && passwd == params["password"]
        puts "LOGIIIIN #{user}, #{passwd}"
        user.nil? ? fail!("Could not log in") : success!(user)
      end
    end

    def authorize!
      env['warden'].authenticate!
    end
    def authorized?
      env['warden'].authenticated?
    end
    def ensure_authorized!
      halt 403 unless authenticated?
    end

    get '/login' do
      slim :login
    end
    post '/login' do
      authorize!
      flash[:success] = 'Successfully logged in'
      redirect url('/')
    end
    get '/logout' do
      env['warden'].logout
      flash[:success] = 'Successfully logged out'
      redirect url('/')
    end
    post '/unauthenticated' do
      flash[:username] = params[:username]
      flash[:error] = 'Could not authenticate'
      redirect to url('/login')
    end


    def ensure_sandboxed(subdir, dir)
      abs_subdir = File.expand_path(subdir)
      abs_dir = File.expand_path(dir)
      halt 403 unless abs_subdir[0, abs_dir.length] == abs_dir
    end

    get '/' do
      # choose dataset -> dataset/:name
      # import dataset -> AJAX PUT dataset/:name, client redirect TODO
      # delete dataset -> AJAX DELETE datasets/:name
      datasets = Dir[File.join(Config.datadir, '*')].
        map { |file| File.basename(file) }
      slim :index, locals: {
        datasets: datasets,
        app_url: url("/"),
        authorized: authorized?,
        editing: Config.webapp.editing && authorized?
      }
    end

    put '/new/:dataset' do |dataset|
      ensure_authorized!
      halt 403 unless Config.webapp.editing
      dataset_dir = File.join(Config.datadir, dataset)
      ensure_sandboxed(dataset_dir, Config.datadir)
      FileUtils.mkdir(dataset_dir)
    end

    delete '/dataset/:dataset' do |dataset|
      ensure_authorized!
      halt 403 unless Config.webapp.editing
      dataset_dir = File.join(Config.datadir, dataset)
      ensure_sandboxed(dataset_dir, Config.datadir)
      FileUtils.rm_rf(dataset_dir)
    end


    def get_dataset_dir(dataset)
      File.join(Config.datadir, dataset).tap do |dataset_dir|
        ensure_sandboxed(dataset_dir, Config.datadir)
        halt 404 unless File.directory?(dataset_dir)
      end
    end

    def get_progress_file(dataset, sid)
      sid = session[:session_id]
      session_root = File.absolute_path(Config.webapp.session_dir || 'sessions', settings.root)
      session_dir = File.join(session_root, sid)
      ensure_sandboxed(session_dir, session_root)
      FileUtils.mkdir_p(session_dir)
      File.join(session_dir, dataset)
    end

    get '/dataset/:dataset' do |dataset|
      dataset_dir = get_dataset_dir(dataset)
      progress_file = get_progress_file(dataset, session[:session_id])
      doc_limit = session[:doc_limit] || 5

      unknown = UnknownSearcher.new(dataset_dir, progress_file, doc_limit).run

      autosubmit = session[:autosubmit]
      autosubmit = true if autosubmit.nil?
      slim :step, {
        locals: {
          dataset_url: url("/dataset/#{dataset}"),
          app_url: url("/"),
          autosubmit: autosubmit,
          doc_limit: doc_limit,
          unknown: unknown
        }
      }
    end

    CONTENT_TYPES = {
      'html' => 'text/html',
      'xhtml' => 'application/xhtml+xml',
      'xml' => 'text/xml'
    }

    get '/dataset/:dataset/file/*' do |dataset, filename|
      dataset_dir = get_dataset_dir(dataset)
      file = File.join(dataset_dir, params[:splat].first)
      ensure_sandboxed(file, dataset_dir)
      begin
        if file =~ /\.(xml|x?html)/
          content = File.read(file)
          extension = $1
          progress_file = get_progress_file(dataset, session[:session_id])
          progress_data = get_progress_data(progress_file)
          read_as_html = extension == 'html'
          write_as_xhtml = extension == 'html' || extension == 'xhtml'
          opts = {
            displaced: to_xpath(progress_data[:tags][:independent]),
            ignored: to_xpath(progress_data[:tags][:decoration]),
            replaced: to_xpath(progress_data[:tags][:object]),
            removed: to_xpath(progress_data[:tags][:metainfo]),
            file_name: filename,
            read_as_html: read_as_html,
            deactivate_scripts: write_as_xhtml,
            write_as_xhtml: write_as_xhtml
          }
          doc = extract(content, opts)
          content_type CONTENT_TYPES[extension]
          doc.enriched_xml
        else
          send_file file
        end
      rescue Errno::ENOENT
        halt 404, 'Not found'
      end
    end

    post '/dataset/:dataset/upload' do |dataset|
      ensure_authorized!
      halt 403 unless Config.webapp.editing
      dataset_dir = get_dataset_dir(dataset)
      files = {}
      params.each do |key, file|
        next unless file.instance_of?(Hash)
        file_name = File.join(dataset_dir, file[:filename])
        ensure_sandboxed(file_name, dataset_dir)
        files[file_name] =file
      end

      files.each do |file_name, file|
        FileUtils.mv(file[:tempfile], file_name)
      end

      ""
    end

    get '/dataset/:dataset/output' do |dataset|
      dataset_dir = get_dataset_dir(dataset)
      progress_file = get_progress_file(dataset, session[:session_id])
      content_type 'application/x-gzip'
      attachment dataset + ".tgz"
      dataset_path = Pathname.new(dataset_dir)
      TarGzipPacker.new do |tgz|
        searcher = UnknownSearcher.new(dataset_dir, progress_file, :all)
        searcher.per_doc do |xml_file, doc|
          out = Pathname.new(xml_file).relative_path_from(dataset_path)
          tgz.add_entry out, doc.enriched_xml
          tgz.add_entry out.sub_ext('.txt'), doc.text
          tgz.add_entry out.sub_ext('.ann'), doc.brat_ann
        end
        searcher.run
      end.to_s
    end

    get '/dataset/:dataset/progress' do |dataset|
      get_dataset_dir(dataset) # for ensure_sandboxed
      progress_file = get_progress_file(dataset, session[:session_id])
      content_type 'application/x-yaml'
      attachment dataset + ".yaml"
      File.read(progress_file)
    end

    COLUMNS = [:independent, :decoration, :object, :metainfo]
    post '/dataset/:dataset/step' do |dataset|
      get_dataset_dir(dataset) # for ensure_sandboxed
      progress_file = get_progress_file(dataset, session[:session_id])
      progress_data = get_progress_data(progress_file)
      changes = JSON.parse(params[:changes])
      changes.each do |change|
        pos = change["pos"].to_i
        selector = change["selector"]
        column = change["column"]
        previous = change["previous"]
        md = /^([^\]\[]+)(?:\[([^:]*)(?::\s*([^\]]*))?\])?/.match(selector)
        halt 403, "Invalid selector #{selector}" unless md
        _, tag, attr, values = *md
        data = [tag, attr, *(values || "").split].compact

        if previous && !previous.empty?
          previous = previous.to_sym
          halt 403, "Invalid origin column #{previous}" unless COLUMNS.include?(previous)
          deleted = progress_data[:tags][previous].delete(data)
          progress_data[:processed_files] = [] if deleted
        end

        if column && !column.empty?
          column = column.to_sym
          halt 403, "Invalid target column #{column}" unless COLUMNS.include?(column)
          if pos == -1
            progress_data[:tags][column] << data
          else
            progress_data[:tags][column].insert(pos, data)
          end
        end
      end
      save_progress_file(progress_file, progress_data)
      ""
    end

    post '/config' do
      session[:autosubmit] = params[:autosubmit] == "true" if params[:autosubmit]
      session[:doc_limit] = params[:doc_limit].to_i if params[:doc_limit]
      ""
    end
  end
end
