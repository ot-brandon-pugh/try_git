define (require) ->
  ko = require "knockout"

  RealtimeValue = ->
    return

  RealtimeValue::init = (element, valueAccessor, allBindings, viewModel, bindingContext) ->
    #overload allBindings methods to inject valueUpdate binding
    overloadedAllBindings =
      has: (bindingKey) ->
        (bindingKey is "valueUpdate") or allBindings.has(bindingKey)

      get: (bindingKey) ->
        binding = allBindings.get(bindingKey)
        binding = "afterkeydown"  if bindingKey is "valueUpdate"
        return binding
    
    ko.bindingHandlers.value.init element, valueAccessor, overloadedAllBindings, viewModel, bindingContext
    return

  RealtimeValue::register = ->
    ko.bindingHandlers.realtimeValue = {init: @init, update: ko.bindingHandlers.value.update}

  return RealtimeValue