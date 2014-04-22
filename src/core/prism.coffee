define (require) ->
  Error = require 'OTCore/error'

  Prism = (@ds) ->
    @offset = - new Date().getTimezoneOffset()
    return

  Prism::start = ->
    try
      clientCookie = document.cookie
      if (clientCookie.indexOf('ottz') < 0)
        document.cookie = 'ottz=' + @offset + '; path=/'
      @ds.post("/visit")
      .catch (error) -> 
        e = new Error("Failed to post visit")
        e.setInnerError error
        e.log()
        return
    catch error
      e = new Error("Failed to track")
      e.setInnerError error
      e.log()
    return

  return Prism
