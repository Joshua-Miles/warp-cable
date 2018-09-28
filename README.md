# Warp Cable

Warp Cable is tool for rapid development of socket-based rails applications.

## Installation

There are two sides to using Warp Cable:
* Server-side
* Client-side

### Server Installation 

Add this to your gem file:
`gem "warp-cable", git: "https://github.com/Joshua-Miles/warp-cable.git"`

Then run 
`bundle install`

### Client Installation
Using Webpack (currently the only officially supported method of installation):

`npm install warp-cable-client`

Then, in your project

```
const API_DOMAIN = 'http://locahost:3000/cable'
import WarpCable from 'warp-cable-client'
let api = WarpCable(API_DOMAIN)

```

## Usage

Warp Cable allows you to create special controllers in your Rails Project called Warp Controllers.

You would create these inside your controllers folder: `controllers/<DOMAIN>_warp_controller.rb`
For Example: `controllers/users_warp_controller.rb`
Inside, we would extend `WarpCable::Controller`:

```
class UsersWarpController extends WarpCable::Controller
    ...
end

```
This class will function very similarly to a normal Rails controller for an API, with the exception that we will `yield <output>`, rather than `render json: <output>`: 

```
class UsersWarpController extends WarpCable::Controller

    def index(params)
        User.after_create do
            yield User.all
        end
        User.after_update do
            yield User.all
        end
        User.after_destroy do
            yield User.all
        end
        yield User.all
    end

    def show(params)
        User.after_update do | user |
            if(params[:id] == user.id)
                yield User.find(params[:id])
            end
        end
        yield User.find(params[:id])
    end

    def create(params)
        User.create(user_params)
    end

    def destroy(params)
        User.destroy(params[:id])
    end

    def update(params)
        user = User.find(params[:id])
        user.update(user_params)
    end

    def user_params
        params.permit(:first_name)
    end

end

```

As you can see, in this example we listen to the ActiveRecord model for resource updates, then re-yield the output when the relevant data changes. To make these controller methods accessable, we need to add to the `app/config/routes.rb`:

```

Rails.application.routes.draw do
  warp_resources :users
end

```

`warp_resources` is a method in Rails' routing engine which is added by WarpCable and creates wss and http access to a single controller.

On our client, we have access to the methods `subscribe` and `trigger`. Subscribe accepts a controller name, a method name (any method you have defined in the WarpController), an object of params, and a callback function:

```
const API_DOMAIN = 'http://locahost:3000/cable'
import WarpCable from 'warp-cable-client'
let api = WarpCable(API_DOMAIN)

api.subscribe('Users', 'index', {}, users => {
    console.log('Recieved:',users)
})

// Console => '[]'

```

The callback to subscribe will be called every time data is `yield`ed from the controller method it subscribed to.

Trigger accepts the same arguments, but no callback (future versions may return a promise or accept a callback for error handling):

```

 api.trigger('Users', 'create', { first_name: 'James' })

 // Console => '[ { id: 1, first_name: 'James' } ]'

```

Functionally the trigger method is similar to subscribe, but semantically denotes an action being made on state (persisted information) as opposed to a request for existing state.







