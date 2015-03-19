module Phase6
  class Route
    attr_reader :pattern, :http_method, :controller_class, :action_name

    def initialize(pattern, http_method, controller_class, action_name)
      @pattern, @http_method, @controller_class, @action_name =
          pattern, http_method, controller_class, action_name
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
  end

  class Router
    attr_reader :routes

    def initialize
      @routes = []
    end

    # simply adds a new route to the list of routes
    def add_route(pattern, method, controller_class, action_name)
      @routes << Route.new(pattern, method, controller_class, action_name)
    end

    # evaluate the proc in the context of the instance
    # for syntactic sugar :)
    def draw(&proc)
      self.instance_eval(&proc)
    end

    # make each of these methods that
    # when called add route
    [:get, :post, :put, :delete].each do |http_method|
      define_method http_method do |pattern, controller_class, action_name|
        add_route(pattern, http_method, controller_class, action_name)
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
