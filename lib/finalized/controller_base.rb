require 'uri'
require 'activesupport'
require 'json'
require 'webrick'
require 'active_support/core_ext'
require 'erb'
module RailsLite
  class ControllerBase
    include RouteHelper
    attr_reader :params, :req, :res


    def initialize(req, res, route_params = {})
      @req, @res = req, res
      @params = Phase5::Params.new(req, route_params)
      flash
    end

    def invoke_action(name)
      if validate_auth_token
        self.send(name)
        render(name) unless already_built_response?
        set_auth_token
      else
        raise 'Bad Auth Token'
      end
    end

    def redirect_to(url)
      unless already_built_response?
        @already_built_response = true
        @res.status = 302
        session.store_session(@res)
        @res['location'] = url
      else
        raise 'cannot render/redirect more than once'
      end
    end

    # use ERB and binding to evaluate templates
    # pass the rendered html to render_content
    def render(template_name)
      folder = self.class.name.underscore
      filepath = "views/#{folder}/#{template_name}.html.erb"
      html_str = File.read(filepath)
      rendered = ERB.new(html_str).result(binding)
      render_content(rendered, "text/html")
    end

    def already_built_response?
      @already_built_response ||= false
    end

    # Populate the response with content.
    # Set the response's content type to the given type.
    # Raise an error if the developer tries to double render.
    def render_content(content, content_type)
      unless already_built_response?
        res.body = content
        res.content_type = content_type
        session.store_session(@res)
        @already_built_response = true
      else
        raise 'cannot render/redirect more than once'
      end
    end

    # method exposing a `Session` object
    def session
      @session ||= Session.new(req)
    end

    def flash
      @flash ||= Flash.new(session)
    end

    private
    def set_auth_token
      session['authenticity_token'] = SecureRandom.urlsafe_base64
    end
    def validate_auth_token
      body_params = URI::decode_www_form(req.body)
      body_auth_token = body_params.find {|e| e.first == 'authenticity_token'}
      body_auth_token == Session.new(req)['authenticity_token']
    end
  end
end