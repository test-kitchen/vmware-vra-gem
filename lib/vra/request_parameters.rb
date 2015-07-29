#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
