define (require) ->
  Error = require 'OTCore/error'

  WhenRequire = (reqPath) ->
    deferred = When.defer()
    require [reqPath], (m) -> deferred.resolve m
    return deferred.promise

  # modelParameters should be expressed as objects with a key and value
  # i.e. {key: "someParameter", value: "someValue"}
  ModelFactory = (@baseModelPath = "", @modelParameters = []) ->
    @modelStore = {}
    return

  ModelFactory::clear = ->
    @modelStore = {}
    return

  ModelFactory::createModel = (identifier, specifier, Model) ->
    params =
      identifier: identifier
      specifier: specifier
    
    for parameter in @modelParameters
      params[parameter.key] = parameter.value
    
    model = new Model(params)
    return model

  ModelFactory::getModel = (modelName, reload, specifier = '') ->
    specifier = specifier.toLowerCase()
    identifier = modelName + specifier

    storedModel = @modelStore[identifier]

    #if modelName is "myAccountModel"
    #  debugger

    # If we've already promised this model, use the same promise
    return storedModel if storedModel? and storedModel.then?

    # If we've already loaded the model before, re-use that model
    if storedModel?
      return When(storedModel) unless reload and storedModel.load?
      return storedModel.load().then(-> storedModel)

    promise = WhenRequire("#{@baseModelPath}#{modelName}")
    .then((Model) => @createModel(identifier, specifier, Model))
    .catch (reason) ->
      error = new Error("Failed to load module FreshApp/models/#{modelName}")
      error.setInnerError reason
      throw error
    .then (model) ->
      return model.load().then(-> model) if model.load?
      return model
    .catch (reason) =>
      @modelStore[identifier] = null #TODO: set error status instead
      error = new Error("Failed to load model #{modelName}")
      error.setInnerError reason
      throw error
    .then (model) =>
      @modelStore[identifier] = model
      return model

    # I'm a little worried that this could replace a correctly loaded model
    # may need to refactor again to use a dfd
    @modelStore[identifier] = promise

    return promise
  
  return ModelFactory
