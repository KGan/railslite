require_relative "../phase6/controller_base.rb"
require_relative "../phase6/router"
require_relative "../phase5/params.rb"
require_relative "../phase4/session.rb"

module RouteHelper
  def link_to(title, url, **options)
    defaults = {method: :get, class: 'link_to'}
    options = defaults.merge(options)
    (<<-HTML)
    <a data-method="#{options[:method]}" href="#{url}"
        class="#{options[:class]}"
        rel='nofollow'>#{title}</a>
    HTML
  end

  def button_to(title, url, **options)
    defaults = {method: :post, class: 'button_to'}
    options = defaults.merge(options)
    token = ''
    (<<-HTML)
          <form action="#{url}" method="post" class="#{options[:class]}">
            <input name='_method' type="hidden" value="#{options[:method]}"/>
            <input name=auth_token type=hidden value="#{token}"/>
          </form>
    HTML
  end
end

module Bonus
  class Flash  #Wow this is short
    def initialize(session)
      @session = session
      @flash = session['flash']
      session['flash'] = {}
    end

    def [](key)
      @flash[key] if @flash
    end

    def []=(key, val)
      @session['flash'][key] = val
    end

    def now
      @flash
    end
  end
##############################
  class ControllerBase < Phase6::ControllerBase
    include RouteHelper
    def initialize(req, res, route_params = {})
      @req, @res = req, res
      @params = Phase5::Params.new(req, route_params)
      flash
    end

    def flash
      @flash ||= Flash.new(session)
    end

    private
    def validate_auth_token
      body_params = URI::decode_www_form(req.body)
      body_auth_token = body_params.find {|e| e.first == 'authenticity_token'}
      body_auth_token == Session.new(req)['authenticity_token']
    end
  end
#############################
  class Route < Phase6::Route
    attr_reader :path
    def initialize(path, method, classaction)
      @path = path
      @pattern = parse_path(path)
      controller, action = classaction.split('#')
      @controller_class = (controller + 'Controller').classify.constantize
      @action_name = action.to_sym
      @http_method = method
    end


#  get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
# now get '/cats/:cat_id/', 'cats#show'

    private
    def parse_path(path)
      Regexp.new('^' + path.gsub(/\/:([[\w][^\/]]+)/, "\/(?<\\1>\\d+)") + '$')
    end
  end

  ##$#$#$##$#$#$$#$$$#$4
  class Router < Phase6::Router
    def initialize
      @routes = []
    end

    # simply adds a new route to the list of routes
    def add_route(path, method, classaction, name=nil)
      r = Route.new(path, method, classaction)
      @routes << r
      name ||= path.gsub(/^\//, '').gsub(/\//, '_')
      name += '_url'
      RouteHelper.send :define_method, name do |*args|
        n = path.match(/:\w+/)
        if n
          raise 'too few arguments' unless arg && (args.length == n.length-1)
          path.gsub(/:\w+/) { |z| arg.shift }
        else
          path
        end
      end
    end


    # make each of these methods that
    # when called add route
    [:get, :post, :put, :delete].each do |http_method|
      define_method http_method do |path, classaction, name = nil|
        add_route(path, http_method, classaction, name)
      end
    end
  end



end

