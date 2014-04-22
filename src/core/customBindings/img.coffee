define (require) ->
  ko = require "knockout"

  Img = ->
    return

  Img::init = (element, valueAccessor) ->
    $element = $(element)

    #hook up image error handling
    $element.error ->
      value = ko.utils.unwrapObservable(valueAccessor())
      fallback = ko.utils.unwrapObservable(value.fallback)
      $element.attr("src", fallback)
    return

  Img::update = (element, valueAccessor) ->
    value = ko.utils.unwrapObservable(valueAccessor())
    src = ko.utils.unwrapObservable(value.src)
    fallback = ko.utils.unwrapObservable(value.fallback)
    $(element).attr("src", src ? fallback)
    return

  Img::register = ->
    ko.bindingHandlers.img = {init: (=> @init.apply(@, arguments)), update: (=> @update.apply(@, arguments))}

  Img.bindingName = "img"

  return Img