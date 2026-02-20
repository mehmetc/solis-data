# frozen_string_literal: true

# Compatibility patch for multi_json with json gem 2.x on Ruby 3.4+
#
# The multi_json gem (1.19.1) calls `except` on JSON::State objects,
# but in newer json gem versions, JSON::State no longer responds to
# Hash-like methods. This patch adds the missing `except` method.
#
# See: https://github.com/intridea/multi_json/issues/187

require 'json'

module JSON
  module Ext
    module Generator
      class State
        unless method_defined?(:except)
          def except(*keys)
            to_h.except(*keys)
          end
        end
      end
    end
  end
end
