define (require) ->
  ko = require "knockout"
  require "hammer"

  stop = (event) ->
    event.gesture.preventDefault()
    event.stopPropagation()
    return
  
  DragToggle = ->
    @toggledOffset = -96
    @maximumOffset = 36
    @minimumOffset = @toggledOffset - @maximumOffset
    @toggleDirection = 'left'
    return

  DragToggle::setContainerOffset = ($el, percent, animate) ->
    $el.removeClass("animate")
    $el.addClass("animate") if animate
    if (Modernizr.csstransforms3d)
      $el.css("transform", "translate3d(#{percent}px,0,0) scale3d(1,1,1)")
      return
    if (Modernizr.csstransforms)
      $el.css("transform", "translate(#{percent}px,0)")
      return
    $el.css("right", (($(window).width() / 50) * percent)+"px")
    return

  DragToggle::handleDrag = ($el, touchState, toggleState, event) =>
    windowWidth = $(window).width()
    return unless windowWidth < 767
    touchState("drag")
    stop(event)

    dragOffset = ((100 / windowWidth)*event.gesture.deltaX) / .5

    if !toggleState() and dragOffset < @minimumOffset
      @setContainerOffset($el, @minimumOffset)

    unless toggleState()
      if dragOffset < @minimumOffset
        @setContainerOffset($el, @minimumOffset)
      else if dragOffset > @maximumOffset
        @setContainerOffset($el, @maximumOffset)
        toggleState(false)
      else if dragOffset > @minimumOffset
        @setContainerOffset($el, dragOffset)
    else
      if dragOffset + @toggledOffset > @maximumOffset
        @setContainerOffset($el, @maximumOffset)
      else if dragOffset + @toggledOffset < @minimumOffset
        @setContainerOffset($el, @minimumOffset)
        toggleState(true)
      else
        @setContainerOffset($el, dragOffset + @toggledOffset)

    return

  DragToggle::handleSwipe = (touchState, toggleState, event) =>
    return unless $(window).width() < 767
    touchState("swipe")
    stop(event)
    toggleState(event.gesture.direction is @toggleDirection)
    return

  DragToggle::handleRelease = ($el, touchState, toggleState, event) =>
    stop(event)
    return if touchState() is ""
    unless Math.abs(event.gesture.deltaX) > ($(window).width() / 6)
      return @setContainerOffset($el, (if toggleState() then @toggledOffset else 0), true)
    toggleState(event.gesture.direction is @toggleDirection)
    touchState("")
    @setContainerOffset($el, (if toggleState() then @toggledOffset else 0), true)
    return

  DragToggle::init = (element, valueAccessor) ->
    $el = $(element)
    @setContainerOffset($el, 0)

    toggleState = value?.toggleField ? ko.observable(false)
    touchState = ko.observable("")
    button = $(".mobile-tab", $el)
    actions = $(".actions", $el)

    $el.hammer().on "dragleft dragright", (event) =>
      @handleDrag($el, touchState, toggleState, event)
      return
    $el.hammer().on "swipeleft swiperight", (event) =>
      @handleSwipe(touchState, toggleState, event)
      return
    $el.hammer().on "release", (event) =>
      @handleRelease($el, touchState, toggleState, event)
      return
    if button?
      button.hammer().on "tap", ->
        toggleState(not toggleState())
        return

    ko.computed =>
      isToggled = toggleState()
      offset = if isToggled then @toggledOffset else 0
      removeClass = if isToggled then "not-active" else "active"
      addClass = if isToggled then "active" else "not-active"

      @setContainerOffset($el, offset, !ko.computedContext.isInitial())
      if actions?
        actions.removeClass removeClass
        actions.addClass addClass
      return
    return

  DragToggle::register = ->
    ko.bindingHandlers.dragToggle = {init: @init}

  return DragToggle