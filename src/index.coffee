{EventEmitter}  = require 'events'
raspi           = require 'raspi'
gpio            = require 'raspi-gpio'
debug           = require('debug')('meshblu-connector-raspi-gpio:index')

class Connector extends EventEmitter
  constructor: ->
    @pins = {}
    @names = {}
    @timeouts = {}

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  _pinChangeSend: (x, name, value) =>
    debug 'emit', name, value, new Date().getTime()
    x.emit 'message', { devices: "*", data: {component:name, value:value}}

  pinChange: (name, value) =>
    debug 'pinChange', name, value, new Date().getTime()
    try 
      clearTimeout(@timeouts[name])
    catch
      null
    @timeouts[name] = setTimeout(@_pinChangeSend.bind(null, this, name, value), 50)

  configurePin: (component) =>
    debug 'configuring pin', component.name, component.pin
    pullsetting = if component?.pullsetting? then component.pullsetting else "Pull none"
    args = {}
    args.pin = component.pin
    peripheral = undefined
    switch component.direction
      when "input"
        args.pullResistor = gpio.PULL_UP if pullsetting == "Pull up"
        args.pullResistor = gpio.PULL_DOWN if pullsetting == "Pull down"
        args.pullResistor = gpio.PULL_NONE if pullsetting == "Pull none"
        debug 'x', args
        peripheral = new gpio.DigitalInput(args)        
        peripheral.on('change', @pinChange.bind(null, component.name));
      when "output"
        peripheral = new gpio.DigitalOutput(args)     
    @pins[component.pin] = {}
    @pins[component.pin].direction = component.direction
    @pins[component.pin].pullsetting = pullsetting
    @pins[component.pin].name = component.name
    @pins[component.pin].peripheral = peripheral
  
  deconfigurePin: (pin) =>
    debug 'deconfiguring pin', pin
    # This is messy but I can't see a nice way with this library to deconfigure a pin
    # Remove any change watchers
    @pins[pin].peripheral.removeAllListeners()
    delete @pins[pin]
    
  writePin: (name, value) =>
    debug 'writing to pin', name, value
    return unless @names[name]?
    return unless @pins[@names[name]]?
    return unless @pins[@names[name]].direction == "output"
    @pins[@names[name]].peripheral.write(value)
    
  onConfig: (device={}) =>
    { @options } = device
    debug 'on config', @options
    if @options?.components?
      configuredpins = {}
      for component in @options.components
        if component?.direction? and component?.name? and component?.pin?
          pullsetting = if component?.pullsetting? then component.pullsetting else "Pull none"
          # Are we using this pin already?
          if @pins[component.pin]?
            debug 'pin already configured', component.pin
            if @pins[component.pin].direction != component.direction or @pins[component.pin].pullsetting != component.pullsetting
              # Material difference in config - reconfigure
              @deconfigurePin component.pin
              @configurePin component
            else
              @pins[component.pin].name = component.name
          else
            @configurePin component
          configuredpins[component.pin] = true

      # Deconfigure any pins we have configured before but no longer require
      for pin of @pins
        if not configuredpins[pin]?
          debug 'No longer need pin', pin
          @deconfigurePin pin    

      # Create a name-> pin lookup table
      @names = {}
      for pin of @pins
        @names[@pins[pin].name] = pin
        @timeouts[@pins[pin].name] = undefined
        
  start: (device, callback) =>
    debug 'started'
    raspi.init(() =>
      @onConfig device
    )
    callback()

module.exports = Connector
