define (require) ->
  Error = require "OTCore/error"

  # The most basic usage is to instantiate an error handler, and pass
  # the instance.handle reference to a catch call in a promise chain.
  # Example:
  #   errorHandler = new ErrorHandler()
  #   getStuf().catch(errorHandler.handle)
  ErrorHandler = ->
    @hasError = ko.observable false
    @onErrorHandler = null

    @handle = (error) => @handleError(error)
    return

  # The passed function will be used every time an error is handled
  # with the specific instance of ErrorHandler. This passed function
  # will be called with the error object passed to handle.
  # When the passed function returns:
  #   null: proceeds to handle original error with handleInternal
  #   true: indicates error is handled, nothing else happens
  #   {some object}: calls handleInternal with the new error object
  # If the passed function throws an error, that error is caught and
  # passed to handleInternal.
  # Example:
  #   errorHandler = new ErrorHandler()
  #   errorHandler.onError (error) ->
  #     doStufWithError(error)
  #     return
  #
  #   getStuf().catch(errorHandler.handle)
  #
  ErrorHandler::onError = (fn) ->
    @onErrorHandler = fn
    return

  # This returns a function that when invoked will call the passed
  # function before proceeding with the normal handle behavior.
  # If a custom handler was passed to onError for this instance of
  # ErrorHandler, that function will be invoked before handleInternal.
  # When the function returns:
  #   null: proceeds to the next step in the handle process
  #   true: indicates error is handled, nothing else happens
  #   {some object}: passes the new error object on to the next step
  # If the function throws an error, that error is caught and passed
  # to the next step.
  #
  # Example:
  #   errorHandler = new ErrorHandler()
  #   customHandler = (error) ->
  #     doThingsWithError(error)
  #     throw error
  #
  #   getStuf().catch(errorHandler.handleWith(customHandler))
  #
  ErrorHandler::handleWith = (fn) ->
    return (error) =>
      wrappedError = @wrapError(error)
      try
        isHandled = fn(wrappedError)
      catch e
        return @handleError(e)

      unless isHandled is true
        return @handleError(isHandled ? wrappedError)
      return

  ErrorHandler::handleError = (error) ->
    wrappedError = @wrapError(error)
    return @handleInternal(wrappedError) unless @onErrorHandler?
    try
      isHandled = @onErrorHandler(wrappedError)
    catch e
      return @handleInternal(e)

    unless isHandled is true
      return @handleInternal(isHandled ? wrappedError)
    return

  ErrorHandler::handleInternal = (error) ->
    wrappedError = @wrapError(error)
    @hasError(true) if wrappedError.severity != 'info'

    wrappedError.log()
    return

  ErrorHandler::wrapError = (error) ->
    # Make sure we have a fully qualified error
    return error if error instanceof Error
    message = if error?.message? then error.message else "Javascript Error"
    e = new Error(message)
    e.setInnerError(error) if error?
    return e
  
  return ErrorHandler