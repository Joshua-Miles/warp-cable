require "warp/cable/railtie"

class HttpController < ActionController::Base
      
  def self.bind(warp)
    warp.public_methods(false).each do | method |

      define_method(method) do 
        begin
          warp.action_name = method.to_s
          warp.run_callbacks(:process_action)
          warp.send(method, params) do | result |
            render json: result
          end
        rescue => exception
          render json: exception.message 
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
          warp.action_name = method.to_s
          warp.run_callbacks(:process_action)
          warp.send method, params do | result |
            transmit({ :$subscription_id => params[:$subscription_id], payload: result })
          end
        rescue => exception
          transmit({ :$subscription_id => params[:$subscription_id], payload: exception.message })
        end
      end

    end
  end

end

module WarpCable

    class Controller < AbstractController::Base

      attr_accessor :action_name
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
          name = resource.to_s.camelize
          
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