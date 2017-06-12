# frozen_string_literal: true
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

    def set_parameters(key, value_data, parent = nil)
      if value_data.key?(:type)
        if parent.nil?
          set(key, value_data[:type], value_data[:value])
        else
          parent.add_child(Vra::RequestParameter.new(key, value_data[:type], value_data[:value]))
        end
      else
        if parent.nil?
          p = set(key, nil, nil)
        else
          p = parent.add_child(Vra::RequestParameter.new(key, nil, nil))
        end
        
        value_data.each do |k, data|
          set_parameters(k, data, p)
        end
      end
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
    attr_accessor :key, :type, :value, :children
    def initialize(key, type, value)
      @key   = key
      @type  = type
      @value = value
      @children = []
    end

    def to_h
      {
        "key" => @key,
        "value" => {
          "type" => @type,
          "value" => format_value,
        },
      }
    end

    def to_json
      if @value.nil? && @type.nil?
        children_to_json = ""
        @children.each do |c|
          children_to_json += c.to_json
        end
      else
        "\"#{@key}\" : {
          \"data\": {
            #{children_to_json.chop}
          }
        }"
      end
    end

    def format_value
      case @type
      when "integer"
        @value.to_i
      when "string"
        @value.to_s
      else
        @value.to_s
      end
    end
  end
end
