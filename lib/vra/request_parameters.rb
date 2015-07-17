module Vra
  class RequestParameters
    def initialize
      @entries = {}
    end

    def set(key, type, value)
      @entries[key] = Vra::RequestParameter.new(key, type, value)
    end

    def delete(key)
      @entries.delete(key)
    end

    def all_entries
      @entries.values
    end
  end

  class RequestParameter
    attr_accessor :key, :type, :value
    def initialize(key, type, value)
      @key   = key
      @type  = type
      @value = value
    end

    def to_h
      {
        'key' => @key,
        'value' => {
          'type' => @type,
          'value' => format_value
        }
      }
    end

    def format_value
      case @type
      when 'integer'
        @value.to_i
      when 'string'
        @value.to_s
      else
        @value.to_s
      end
    end
  end
end
