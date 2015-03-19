require_relative '../phase3/controller_base'
require_relative './session'

module Phase4
  class ControllerBase < Phase3::ControllerBase
    # Set the response status code and header
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
  end
end
