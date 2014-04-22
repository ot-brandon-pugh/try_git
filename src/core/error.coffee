define ->
  systemKeys = ["message", "severity", "innerError", "originalError", "__moduleId__"]

  Error = (@message = "Javascript Error", @severity = "error", @status = 0) ->
    @logErrorUrl = ot?.config?.logErrorUrl ? "/log/error"
    @logged = false
    return

  Error::setInnerError = (error) ->
    if error instanceof Error
      @innerError = error
    else
      @originalError = error
    return

  Error::getSeverity = ->
    return @severity if (["info", "warning", "error", "critical"]).indexOf(@severity) > -1
    return "error"

  Error::capiFriendly = (error) ->
    data = {}
    data.message = error.message ? "Javascript Error"
    data.severity = error.getSeverity()
    data.context = []
    data.innerError = null
    if error.innerError?
      data.innerError = @capiFriendly(error.innerError) if error.innerError instanceof Error
    else
      data.context.push {key: "url", value: window.location.href}
      data.context.push {key: "userAgent", value: window.navigator.userAgent}
    for key of error when systemKeys.indexOf(key) is -1 and typeof error[key] isnt "function"
      data.context.push {key: key, value: error[key]}
    data.context.push {key: "originalStack", value: error.originalError.stack} if error.originalError?.stack?
    return data

  Error::console = (error) ->
    if ot?.config?.isDev and window.console?.debug?
      window.console.debug "ERROR:"
      window.console.debug error
    return

  Error::log = (timeout) ->
    try
      @console @
      error = @capiFriendly(@)
      timeout = 0 unless timeout?
      unless @logged or error.severity == 'info'
        return @postError(error, timeout).then -> @logged = true
    catch e
      @console e
    return When()

  $.support.cors = true  
  Error::postError = (error, timeout) ->
    return When.promise (resolve, reject) ->
      $.ajax
        url: @logErrorUrl
        type: "POST"
        async: true
        data: JSON.stringify(error)
        contentType: "application/json"
        success: resolve
        error: reject
        timeout: timeout

  return Error