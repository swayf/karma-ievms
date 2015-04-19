# # index

# This module exports a unique Karma launcher for each supported ievms virtual
# machine. The [iectrl](http://xdissent.github.io/iectrl) module is used to
# manage the virtual machine lifecycle. See `iectrl.IEVM.names` for the
# complete list of names.

iectrl = require 'iectrl'
url = require 'url'


class IEVMLauncher
  constructor: (@name, @id, @args) ->

    # Get a IEVM instance for the given name.
    [@vm] = iectrl.IEVM.find @name
    # Start off uncaptured and not running.
    @wasRunning = false
    @captured = false

  start: (url) ->
    # Replace `localhost` with the internal host IP as seen from within the vm.
    vmUrl = "#{url}?id=#{@id}".replace 'localhost', iectrl.IEVM.hostIp

    urlObj = url.parse vmUrl, true

    if @args['x-ua-compatible']
      urlObj.query['x-ua-compatible'] = @args['x-ua-compatible']
    
    delete urlObj.search
    vmUrl = url.format urlObj

    # Check to see if the vm is already running.
    @vm.running().then (running) =>
      # Store whether the vm was running initially.
      @wasRunning = running
      # Open the URL in IE and bail if the vm is already running.
      return @vm.open vmUrl if running
      # Start the vm and open the URL in IE when it's ready.
      @vm.start(true).then => @vm.open vmUrl

  kill: (done) ->
    # Close the IE window.
    @vm.close().then =>
      # Bail out and leave the motor running if it was previously.
      return done() if @wasRunning
      # Stop the vm (saving its state).
      @vm.stop().then => done()

  markCaptured: -> @captured = true
  isCaptured: -> @captured


# Create a factory function for each of the ievms virtual machine names.
for name in iectrl.IEVM.names
  do (name) ->
    launcher = (id, args) -> 
      new IEVMLauncher name, id, args

    launcher.$inject = ['id','args']

    exports["launcher:#{name}"] = ['type', launcher]
