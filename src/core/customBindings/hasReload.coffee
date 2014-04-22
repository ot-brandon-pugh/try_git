define (require) ->
  ko = require "knockout"

  HasReload = ->
    return

  HasReload::init = (element, valueAccessor) ->
    $el = $(element)
    $el.hide()
    if(valueAccessor().reloadComponent)
      $el.show()
    return

  HasReload::register = ->
    ko.bindingHandlers.hasReload = {init: @init}

  return HasReload