define (require) ->
  ko = require "knockout"

  Accordion = ->
    return

  Accordion::init = (element, valueAccessor) ->
    value = valueAccessor() ? {}
    value.group ?= true
    expandedSection = {}
    newValueAccessor =
      expanded: (section) ->
        return unless value.group
        expandedSection.collapse() if expandedSection?.collapse? and expandedSection isnt section
        expandedSection = section
      onExpand: value.onExpand
      onCollapse: value.onCollapse
    if value?.content?
      newValueAccessor.content = value.content
    
    sectionSelector = "[data-expandable]"
    if value?.controls?
      sectionSelector += ", " + value.controls
    
    sections = $(element).find(sectionSelector)
    for section, i in sections
      section.expand = value.open? and value.open is i
      ko.bindingHandlers.expandable.init section, (->newValueAccessor)

  Accordion::register = ->
    ko.bindingHandlers.accordion = {init: => @init.apply(@, arguments)}

  Accordion.bindingName = "accordion"
  
  return Accordion