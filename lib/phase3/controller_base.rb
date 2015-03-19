require_relative '../phase2/controller_base'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'byebug'

module Phase3
  class ControllerBase < Phase2::ControllerBase
    # use ERB and binding to evaluate templates
    # pass the rendered html to render_content
    def render(template_name)
      folder = self.class.name.underscore
      filepath = "views/#{folder}/#{template_name}.html.erb"
      html_str = File.read(filepath)
      rendered = ERB.new(html_str).result(binding)
      render_content(rendered, "text/html")
    end
  end
end
