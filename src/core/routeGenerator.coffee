define ->
  RouteGenerator = (@routes = [], @additionalParameters = []) ->
    return

  RouteGenerator::getRoutes = ->
    return @routes unless @additionalParameters.length > 0
    routeList = []
    for route in @routes
      for parameter in @additionalParameters
        route[parameter.key] = parameter.value unless route[parameter.key]?
      routeList.push route
    return routeList

  RouteGenerator::appendRouteParameter = (key, value) ->
    @additionalParameters.push {key: key, value: value}
    return

  RouteGenerator::addRoutes = (routes, overrides) ->
    if overrides?
      for route in routes
        for key of overrides
          route[key] = overrides[key]
        @routes.push route
    else
      @routes = @routes.concat(routes)
    return

  return RouteGenerator