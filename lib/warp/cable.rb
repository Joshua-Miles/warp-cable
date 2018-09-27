require "warp/cable/railtie"

class HttpController < ActionController::Base
      
  def self.bind(hyper)
    hyper.public_methods(false).each do | method |

      define_method(method) do 
        hyper.send(method, params) do | result |
          render json: result
        end
      end

    end
  end
  
end

class SocketController < ActionCable::Channel::Base

  def self.bind(hyper)
    hyper.public_methods(false).each do | method |

      define_method(method) do | data |
        params =  ActionController::Parameters.new(data['params'])
        hyper.params = params
        hyper.send method, params do | result |
          transmit({ method: method, payload: result })
        end
      end

    end
  end

end

module Hyper

    class Controller 

      def params=(params)
        @params = params
      end

      def params 
        @params
      end

    end

    module Router

      def hyper_resources(*resources)
        resources(*resources)
        resources.each do | resource |
          name = "#{resource}Controller"
          name = name.slice(0,1).capitalize + name.slice(1..-1)
          
          http = Class.new(HttpController)
          socket = Class.new(SocketController)
          
          hyper = Object.const_get("Hyper#{name}").new

          http.bind(hyper)
          socket.bind(hyper)

          controller_name = name
          channel_name = "#{name}Channel"
          
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

ActionDispatch::Routing::Mapper.send :include, Hyper::Router