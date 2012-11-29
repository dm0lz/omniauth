require 'bundler/setup'
require 'sinatra'
require 'omniauth-facebook'
require 'omniauth-twitter'
require 'pry'
require 'haml'
require 'mongo'
require 'g11n'

SCOPE = 'email,read_stream,publish_stream,read_friendlists,read_insights,create_event,ads_management,manage_notifications'

unless File.exists? "config/config.yaml"
  puts "config/config.yaml is missing"
  Process.exit
else
  CONFIG = SymbolMatrix.new "config/config.yaml"
end

class OmniauthConnect < Sinatra::Base
  
  set :protection, :except => :frame_options
  enable :sessions

  use Rack::Session::Cookie

  use OmniAuth::Builder do
    provider :facebook, CONFIG.facebook_app_id, CONFIG.facebook_app_secret, :scope => SCOPE
    provider :twitter, CONFIG.twitter_consumer_key, CONFIG.twitter_consumer_secret
  end
  
  get '/' do
    if session['access_token']
        @gold_token = session['access_token']
        @name = session['name']
        @foto = session['picture']
        @ciudad = session['location']
        @email = session['email']
        @provider = session['provider']
        
        haml :index
    else
        haml :login_page
    end
  end

  get '/logout' do
    session['access_token'] = nil
    session['access_secret'] = nil
    redirect '/'
  end

  get '/auth/:provider/callback' do    

  session['access_token'] = request.env['omniauth.auth']['credentials'].token
  session['access_secret'] = request.env['omniauth.auth']['credentials'].secret
  session['name'] = request.env['omniauth.auth']['info'].name
  session['location'] = request.env['omniauth.auth']['info'].location
  session['picture'] = request.env['omniauth.auth']['info'].image
  session['email'] = request.env['omniauth.auth']['info'].email
  session['provider'] = request.env['omniauth.auth'].provider
  session['id'] = request.env['omniauth.auth']['uid'].to_i
  session['time'] = Time.parse(request.env['omniauth.auth']['extra']['raw_info']['created_at']).to_i
  session['description'] = request.env['omniauth.auth']['extra']['raw_info']['description']
  session['screen_name'] = request.env['omniauth.auth']['extra']['raw_info']['screen_name']

  to_be_inserted = { 
  "additionalType" => [ "http://getfetcher.net/Item" ], 
  "Item#id" => [ session['id'] ], 
  "name" => [session['name']], 
  "User#dateRegistered" => [ session['time'] ], 
  "description" => [ session['description'] ], 
  "url" => [ "https://twitter.com/" + session['screen_name'] ], 
  "accessToken" => session['access_token'], 
  "accessSecret" => session['access_secret'] 
}


    case params[:provider]
      when "facebook"
        unless fb_already_in_db? request.env['omniauth.auth']['uid'].to_i
          person_User_Collection.insert to_be_inserted 
        end
      when "twitter"
        unless tw_already_in_db? request.env['omniauth.auth']['uid'].to_i
          person_User_Collection.insert to_be_inserted
        end
    end
    #binding.pry
    redirect '/'
  end

  get '/auth/failure' do
    'You Must Allow the application to access your data !!! Deja que facebook te foree !!'
  end

  helpers do
    def fb_already_in_db? uid
      not person_User_Collection.find( :id => uid ).to_a.empty?
    end    
    def tw_already_in_db? uid
      not person_User_Collection.find( :id => uid ).to_a.empty?
    end
    def client
      @client ||= Mongo::Connection.new("mongocfg1.fetcher")
    end
    def db
      @db ||= client['test']
    end
    def columnsCollection
      coll = db['columns']
    end
    def usersCollection
      coll = db['users']
    end    
    def person_User_Collection
      coll = db['http://schema.org/Person/User']
    end
  end


end







