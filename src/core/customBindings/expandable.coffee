define (require) ->
  ko = require "knockout"

  Expandable = ->
    return

  Expandable::init = (element, valueAccessor) ->
    value = valueAccessor()
    # First, try to find the content div using the selector
    # set with data-expandable attribute
    target = element.getAttribute("data-expandable")
    content = $(target)
    
    # If that fails, try to find a nested element using the
    # selector passed through the data-binding
    if content.length is 0 and value?.content?
      content = $(element).find(value.content)
    
    # The last fallback is to use the next sibling div
    unless content.length > 0
      content = $(element.nextElementSibling)

    content.collapse = (noTransition) ->
      if value?.onCollapse? and typeof value.onCollapse is "function"
        value.onCollapse($(element), content)
      $(element).removeClass("expanded")
      content.collapsed = true
      content.removeClass("expanding")
      content.expandedHeight = content.height()
      content.css "max-height", content.expandedHeight + "px"
      if window.transitionend and not noTransition
        setTimeout (=>
          content.addClass("expanding")
          content.css "max-height", "0px"
        ), 0
        setTimeout (->content.removeClass("expanding")), 200
      else
        content.css "max-height", "0px"
      return

    content.expand = (noTransition) ->
      if value?.expanded?
        value.expanded(content)
      if value?.onExpand? and typeof value.onExpand is "function"
        value.onExpand($(element), content)
      $(element).addClass("expanded")
      content.collapsed = false
      childHeight = $(content.children()[0]).outerHeight(true)
      if window.transitionend and not noTransition
        content.addClass("expanding")
        content.css "max-height", (if content.expandedHeight > childHeight then content.expandedHeight else childHeight) + "px"
        setTimeout (->
          content.removeClass("expanding")
          content.css("max-height", "")
        ), 200
      else
        content.css "max-height", ""
      return

    content.toggleCollapse = ->
      return if content.hasClass("expanding")
      if content.collapsed
        content.expand()
      else
        content.collapse()
      return

    # Default to collapse unless has 'in' class...
    content.css "overflow", "hidden"
    unless content.hasClass("in") or element.expand
      content.collapse(true)
    else
      content.expand(true)

    newValueAccessor = -> return {action: -> content.toggleCollapse()}
    ko.bindingHandlers.tap.init(element, newValueAccessor)

  Expandable::register = ->
    ko.bindingHandlers.expandable = {init: => @init.apply(@, arguments)}

  Expandable.bindingName = "expandable"
      
  return Expandable