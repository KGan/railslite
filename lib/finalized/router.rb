module RailsLite
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

  class Route
    attr_reader :pattern, :http_method, :controller_class, :action_name

    def initialize(path, method, classaction)
      @path = path
      @pattern = parse_path(path)
      controller, action = classaction.split('#')
      @controller_class = (controller + 'Controller').classify.constantize
      @action_name = action.to_sym
      @http_method = method
    end

    # checks if pattern matches path and method matches request method
    def matches?(req)
      method = req.request_method
      method ||= :get
      return (method.to_s.downcase == http_method.to_s.downcase) && !!(pattern.match(req.path))
    end

    # use pattern to pull out route params (save for later?)
    # instantiate controller and call controller action
    def run(req, res)
      m = pattern.match(req.path)
      route_params = Hash[m.names.zip(m.captures)]
      controller = controller_class.new(req, res, route_params)
      controller.invoke_action(action_name)
    end

    private
    def parse_path(path)
      Regexp.new('^' + path.gsub(/\/:([[\w][^\/]]+)/, "\/(?<\\1>\\d+)") + '$')
    end
  end

  class Router
    attr_reader :routes

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

    # evaluate the proc in the context of the instance
    # for syntactic sugar :)
    def draw(&proc)
      self.instance_eval(&proc)
    end

    # make each of these methods that
    # when called add route
    [:get, :post, :put, :delete].each do |http_method|
      define_method http_method do |path, classaction, name = nil|
        add_route(path, http_method, classaction, name)
      end
    end

    # should return the route that matches this request
    def match(req)
      @routes.find{|route| route.matches?(req)}
    end

    # either throw 404 or call run on a matched route
    def run(req, res)
      matched_route = match(req)
      if matched_route
        matched_route.run(req, res)
      else
        res.status = 404
        res.body = "route not found"
      end
    end
  end
end