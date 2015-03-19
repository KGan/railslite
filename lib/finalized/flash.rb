module RailsLite
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
end