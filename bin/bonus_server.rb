require 'webrick'
require 'uri'
require_relative '../lib/bonus/flash.rb'
require_relative '../lib/phase6/router'

# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

$cats = [
    { id: 1, name: "Curie" },
    { id: 2, name: "Markov" }
]

$statuses = [
    { id: 1, cat_id: 1, text: "Curie loves string!" },
    { id: 2, cat_id: 2, text: "Markov is mighty!" },
    { id: 3, cat_id: 1, text: "Curie is cool!" }
]

class StatusesController < Bonus::ControllerBase
  def index
    statuses = $statuses.select do |s|
      s[:cat_id] == Integer(params['cat_id'])
    end

    unless flash['error']
      flash['error'] = 'this is shown from last time'
      session['token'] = 'laksjlkfjk'
      flash.now['error'] = 'first'
    end
    render_content(statuses.to_s + ' hi ' + "#{flash['error']}", "text/text")
  end
end

class CatsController < Bonus::ControllerBase
  def index
    # debugger
    unless flash['error']
      flash['error'] = '[flash]this is shown from last time there was no flash'
      session['token'] = 'This is a cookiez'
      flash.now['error'] = 'first-flash [this was rendered if there was no flash]'
    end
    render_content($cats.to_s + ' hi ' + "#{flash['error']}", "text/HTML")
  end

  def create
    @cat = Cat.new(fname: 'lulcagt', lname: 'thingy', owner_id: 1)
    if @cat.save
      render 'cats_controller/show'
    else
      render 'fail'
    end
  end
end

router = Bonus::Router.new
router.draw do
  get '/cats', 'cats#index'
  get '/cats/:cat_id/statuses', 'statuses#index'
  post '/cats', 'cats#create'
  # get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  rack_lite(req)
  route = router.run(req, res)
end

def rack_lite(req)
  intercept_method(req)
end

def intercept_method(req)
  method_matcher = /\[_method\]=(get|put|patch|delete|post)/i
  if method_matcher.match(req.body)
    req.request_method = $1
  end
end



trap('INT') { server.shutdown }
server.start
