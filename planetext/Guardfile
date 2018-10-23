guard 'rack', :port => 9292 do
  watch 'Gemfile.lock'
  watch %r{^app/.*rb$}
  watch %r{^lib/.rb$}
  watch 'config.yaml'
end

guard 'coffeescript',
    :input => 'app/assets/coffee',
    :output => 'app/public/js'

guard 'compass',
    :configuration_file => 'Compassfile' do
  watch %r{^app/assets/sass/(.*)\.s[ac]ss}
end
