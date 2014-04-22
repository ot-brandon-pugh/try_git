define (require) ->
  ko = require "knockout"
  require "hammer"

  Tap = (config = {}) ->
    @enableTap = config.enabled ? true

    # Setup phantom click collector
    @tapHelper = $("#tapHelper")
    unless $("#tapHelper").length > 0
      $("body").append("<div id='tapHelper' style='display: none; position: absolute; width: 3px; height: 3px; z-index: 5000;'></div>")
      @tapHelper = $("#tapHelper")
      @tapHelper.on "click", (event) ->
        # Caught the phantom click, prevent default
        if event.stopPropagation?
          event.stopPropagation()
        else
          event.cancelBubble = true
        event.preventDefault()
        @tapHelper.hide()
        return
    return

  Tap::preventPhantoms = (event) ->
    cssObj =
      left:"#{event.gesture.center.pageX - 1}px"
      top:"#{event.gesture.center.pageY - 1}px"
    @tapHelper.css(cssObj)
    @tapHelper.show()
    setTimeout (=>@tapHelper.hide()), 350
    return

  Tap::doAction = ($el, bindingValues) ->
    unless bindingValues.setFocus? and !bindingValues.setFocus
      $el.focus()
    if typeof bindingValues.action is "string"
      location.href = bindingValues.action
      return
    if typeof bindingValues.action is "function"
      bindingValues.action(bindingValues.args)
    return

  Tap::handleTap = (event, $el, bindingValues) ->
    @preventPhantoms(event)
    @doAction($el, bindingValues)
    if event.stopPropagation?
      event.stopPropagation()
    else
      event.cancelBubble = true
    return

  Tap::init = (element, valueAccessor) ->
    $el = $(element)
    if @enableTap
      $el.hammer({tap_max_touchtime: 500}).on "tap", (event) => @handleTap(event, $el, valueAccessor())
      $el.on "click", (event) =>
        event.preventDefault()
        @tapHelper.hide()
    else
      $el.on "click", => @doAction($el, valueAccessor())
    return

  Tap::register = ->
    ko.bindingHandlers.tap = {init: => @init.apply(@, arguments)}

  Tap.bindingName = "tap"

  return Tap