require 'uri'
require 'byebug'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    #
    # You haven't done routing yet; but assume route params will be
    # passed in as a hash to `Params.new` as below:
    def initialize(req, route_params = {})
      @params = route_params
      @req = req
      [req.query_string, req.body].each do |qs|
        parse_www_encoded_form(qs) if qs
      end
      @permitted_keys = []
      @required_keys = []
    end

    def [](key)
      @params[key]
    end

    def to_s
      @params.to_json.to_s
    end

    def permitted?(key)
      @permitted_keys.include? key
    end
    def required?(key)
      @required_keys.include? key
    end

    def require(*keys)
      @required_keys += keys
      unless @params.keys.all? { |param| keys.include? param }
        raise AttributeNotFoundError, "required key is missing"
      end
      values = @params.values_at(keys)
      Hash[keys.zip(values)]
    end

    def permit(*keys)
      @permitted_keys += keys
      values = @params.values_at(keys)
      Hash[keys.zip(values)]
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_www_encoded_form(www_encoded_form)
      query = URI::decode_www_form(www_encoded_form)
      query.each do |param|
        parsed_key = parse_key(param.first)
        new_entry = param.last
        parsed_key.reverse.each do |nested_key|
          z = Hash.new
          z[nested_key] = new_entry
          new_entry = z
        end
        @params.deep_merge!(new_entry) {|k,v1,v2| v1+v2}
      end
    end

    # this should return an array (and an array indicator)
    # user[address][street] should return ['user', 'address', 'street']
    def parse_key(key)
      [].tap do |array|
        key.split('[').each do |word|
          array << word.split(']').first
        end
      end
    end
  end
end
