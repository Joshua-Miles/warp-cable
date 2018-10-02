//= require action_cable
(function() {
    let cable = ActionCable.createConsumer('ws://localhost:3000/cable');
    let channels = new Object

    class EventEmitter {
        constructor(options){
            this.options = options;
            this.bin = {};
        }
    
        on(events, callback){
            const EventManager = this; 
            if(typeof events == 'string' || typeof events == 'number'){
                return events+'|@|'+EventManager.provision(events, callback);
            }
            return false;
        }
    
        cancel(eventID){
            const EventManager = this;
            let [event, id] = eventID.split('|@|')
            if(typeof this.bin[event] != 'undefined' && this.bin[event][id]){
                delete this.bin[event][id]
                return true;
            }
            return false
        }
    
        emit(event,  data){
            if(typeof this.bin[event] != 'undefined'){
                
                this.bin[event].forEach(resolve => { if(typeof resolve == 'function') resolve(data) }); 
            }
        }
    
        provision(namespace, resolve){
            let EventManager = this; 
            if(typeof this.bin[namespace] == 'undefined'){
                EventManager.bin[namespace] = new Array;
            }
            return EventManager.bin[namespace].push(resolve) -1;
        }
    }

    class Channel extends EventEmitter{

        constructor(controller){
            super();
            channels[controller] = this
            this.ready = new Promise( resolve => {
                this.cable = cable.subscriptions.create(
                    {
                        channel: `${controller}Channel`,
                    }, 
                    {
                        received: response => {
                            this.emit(response.$subscription_id, response.payload)
                        },
                        connected: function() {
                            resolve()
                        }
                    }
                );
            })
        }

        
        perform(method, params){
            this.cable.perform(method, { params })
        }

    }

    let id = 0;
    this.subscribe = function(controller, method, params = new Object, callback = () => void(0)){
      let channel = channels[controller] || new Channel(controller)
      params.$subscription_id = id++
      channel.ready.then( () => channel.perform(method, params) )
      channel.on(params.$subscription_id, callback)
    }

    this.trigger = function(controller, method, params = new Object, callback = () => void(0)){
        let channel = channels[controller] || new Channel(controller)
        channel.ready.then( () => channel.perform(method, params) )
        channel.on(params.$subscription_id, callback)
    }
  
  }).call(this);