require 'rubygems'
require 'sinatra'
require 'typhoeus'
require 'yajl/json_gem'
require 'active_record'
require 'uuidtools'

ROOT = File.expand_path( File.dirname( __FILE__ ) )

# default port
set :port, 3010

# options
options = Hash[*ARGV]

# config
default_env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
environment = options['-e'] ? options['-e'] : default_env
config_path = ROOT + "/../config/database.yml"
config_yaml = YAML::load( File.open( config_path ) )

# db connexion
ActiveRecord::Base.establish_connection( config_yaml[ environment ] )

# lib
%w( achievable ).each do |model|
  require ROOT + "/../lib/#{model}"
end

# models
%w( game map node_type node artificial_intelligence artificial_intelligence_game ).each do |model|
  require ROOT + "/../app/models/#{model}"
end

# achievements
%w( achievement games_played_achievement ).each do |model|
  require ROOT + "/../app/models/achievements/#{model}"
end

# start a random fight, on a random map with random (2!) ais
get '/random' do
  map = Map.first(:order=>"RAND()")
  ais = ArtificialIntelligence.find(:all, :limit=>2, :order=>"RAND()")
  run map, ais
  
  200
end

# start a fight for map X with ais Y, Z, ...
# params[:map_id] : Map ID
# params[:ai_ids] : List of AI ids
get '/fight' do
  begin
    map = Map.find(params[:map_id])
    ais = ArtificialIntelligence.find(params[:ai_ids])
    run map, ais
  rescue Exception => e
    log( e )

    # return Forbidden HTTP Status
    return 403
  end

  200
end

def run map, ais
  map.init( ais )
  game = Game.new
  game.map = map

  Thread.new do
    begin
      game.run
    rescue Exception => e
      log( e )
    end
  end
end

def log string
  open('errors.log', 'a') do |f|
    f.puts "#{DateTime.now} : #{request.path_info} #{params.inspect}"
    f.puts string
    f.puts "--------------------------------------------------------"
  end
end
