require "warp/cable/railtie"

class HttpController < ActionController::Base
      
  def self.bind(warp)
    warp.public_methods(false).each do | method |

      define_method(method) do 
        warp.send(method, params) do | result |
          render json: result
        end
      end

    end
  end
  
end

class SocketController < ActionCable::Channel::Base

  def self.bind(warp)
    warp.public_methods(false).each do | method |

      define_method(method) do | data |
        params =  ActionController::Parameters.new(data['params'])
        warp.params = params
        begin
          warp.run_callbacks(:process_action)
          warp.send method, params do | result |
            transmit({ method: method, payload: result })
          end
        rescue Exception
          transmit({ method: method, payload: Exception })
        end
      end

    end
  end

end

module WarpCable

    class Controller 

      include AbstractController::Callbacks
      extend AbstractController::Callbacks::ClassMethods

      def performed?
        true
      end

      def params=(params)
        @params = params
      end

      def params 
        @params
      end

      def headers=(params)
        @params = params
      end

      def headers 
        @params
      end

    end

    module Router

      def warp_resources(*resources)
        resources(*resources)
        resources.each do | resource |
          name = resource.slice(0,1).capitalize + resource.slice(1..-1)
          
          controller_name = "#{name}Controller"
          channel_name = "#{name}Channel"
          
          http = Class.new(HttpController)
          socket = Class.new(SocketController)
          
          warp = Object.const_get("#{name}WarpController").new

          http.bind(warp)
          socket.bind(warp)
          
          Object.const_set(channel_name, socket)
          Object.const_set(controller_name, http)
        end
      end
    end

    module Rails
      class Engine < ::Rails::Engine
      end
    end

end

ActionDispatch::Routing::Mapper.send :include, WarpCable::Router