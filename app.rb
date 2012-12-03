require "bundler"
Bundler.require :default
require 'json'
require './downmark_it'

@api_key     = ENV["API_KEY"]
@api_secret  = ENV["API_SECRET"]
@api_site    = "https://api.crowdbase.com"

$client = OAuth2::Client.new(@api_key, @api_secret, :site => @api_site)

class FocusNotes < Sinatra::Base

  include Sinatra::ContentFor

  enable :sessions
  set :sessions, true
  set :public_folder, 'public'
  set :scss, :cache_location => File.join(File.dirname(__FILE__), "tmp/sass-cache")
  configure { set :session_secret, "markdown-rules" }

  before(/\/notes*/) do
    return redirect 'signin' unless session["access_token"]

    @user = OAuth2::AccessToken.new($client, session["access_token"]) if session["access_token"]
    @user_id = session["user_id"]

    request = @user.get "/v1/users/#{@user_id}/notes"
    @notes = JSON.parse(request.response.env[:body], :symbolize_names => true)[:body]
  end

  get "/assets/:stylesheet.css" do
    scss :"/assets/#{params[:stylesheet]}"
  end

  get '/' do
    haml :index
  end

  get '/signin' do
    session["user_id"]      = nil
    session["user_name"]    = nil
    session["avatar_url"]   = nil
    session["access_token"] = nil

    haml :signin, layout: false
  end

  post '/signin' do
    access_token = $client.password.get_token(params["email"], params["password"], :subdomain => params["subdomain"])
    request = access_token.get "/v1/me"
    session["access_token"] = access_token.token
    user = JSON.parse(request.response.env[:body], :symbolize_names => true)[:body]

    session["user_id"]    = user[:id]
    session["user_name"]  = user[:complete_name]
    session["avatar_url"] = user[:avatar_url]

    redirect to("notes/new")
  end

  get '/notes/new' do
    haml :new
  end

  post '/notes/:id' do
    @user.put("/v1/notes/#{params[:id]}", body: { title: params["title"], body: params["content"] })

    redirect to("notes/#{params[:id]}")
  end

  get '/notes/:id' do
    request = @user.get("/v1/notes/#{params[:id]}")
    @note = JSON.parse(request.response.env[:body], :symbolize_names => true)[:body]

    haml :show
  end

  get '/notes/:id/edit' do
    request = @user.get("/v1/notes/#{params[:id]}")
    @note = JSON.parse(request.response.env[:body], :symbolize_names => true)[:body]
    @content = DownmarkIt.to_markdown(@note[:body])

    haml :edit
  end

  get '/notes/:id/delete' do
    @user.delete("/v1/notes/#{params[:id]}")

    redirect to("notes")
  end

  post '/notes' do
    request = @user.post("/v1/notes", body: { title: params["title"], body: params["content"] })
    note = JSON.parse(request.response.env[:body], :symbolize_names => true)[:body]

    redirect to("notes/#{note[:id]}")
  end

  not_found do
    redirect to("notes/new")
  end

end
