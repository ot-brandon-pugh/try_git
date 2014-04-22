define (require) ->
  Error = require("OTCore/error")
  
  # Brandon and I don't think we need this for the SPA...
  # So I'm commenting it out for now
  #
  # window.onload = ->
  #   $.disableErrors = false
  #   return
  # window.onbeforeunload = ->
  #   $.disableErrors = true
  #   return
  
  # We never set this to false, so I'm setting it to always be true...
  $.support.cors = true

  # For use with capi, need to pass apiUrl as baseUrl
  Dataservice = (@baseUrl = "", @logoffUrl = "") ->
    return

  # Use this to generate mock data for static SPA
  # saveMockData = (method, url, request, response) ->
  #   window.mockData = {} unless window.mockData
  #   window.mockData.printJSON = ->
  #     JSON.stringify window.mockData
  #   window.mockData[method] = {} unless window.mockData[method]
  #   fakeUrl = url.replace(ot.config.baseApiUrl, "fakeUrl").replace(ot.config.accountNumber, "xxxxxxxx")
  #   window.mockData[method][fakeUrl] = response
  #   return response

  # Use this to generate API documentation
  # Dataservice::saveMockData = (method, url, request, response) ->
  #   window.mockData = {} unless window.mockData
  #   window.mockData.printJSON = ->
  #     JSON.stringify window.mockData
  #   window.mockData[method] = {} unless window.mockData[method]
  #   fakeUrl = url.replace(ot.config.baseApiUrl, "").replace(ot.config.accountNumber, "xxxxxxxx")
  #   window.mockData[method][fakeUrl] = {request: request, response: response}
  #   return response

  Dataservice::send = (method, url, data) ->
    url = @baseUrl + url
    requestData = ""
    requestData = JSON.stringify(data) unless method is "GET"
    requestSettings = 
      url: url
      type: method
      async: true
      data: requestData
      contentType: "application/json"
    
    requestSettings.beforeSend = @beforeSend if @beforeSend?

    return When.promise((resolve, reject) ->
      requestSettings.success = resolve
      requestSettings.error = reject
      $.support.cors = true
      $.ajax(requestSettings)
    ).then((response) ->
      if (typeof response is "string" && response isnt "")
        response = JSON.parse(response)
      return response
    # ).then((response) => return @saveMockData(method, url, data ? "", response)
    ).catch((xhr) =>
      # See comment above for why we aren't doing this
      # return if $.disableErrors

      # loggoff if logoffUrl is provided
      if (xhr.status is 403 or xhr.status is 401) and @logoffUrl isnt ""
        window.location.replace(@logoffUrl)
      
      # Don't swallow the error here, throw it on down the chain
      severity = if xhr.status in [401, 403] then "warning" else "error"
      error = new Error("Failed to #{method} data to/from #{url}: #{xhr.status}", severity, xhr.status)
      throw error
    )

  Dataservice::get = (url) -> @send("GET", url, {})

  Dataservice::post = (url, data) -> @send("POST", url, data)

  Dataservice::put = (url, data) -> @send("PUT", url, data)

  Dataservice::remove = (url) -> @send("DELETE", url, "")

  return Dataservice