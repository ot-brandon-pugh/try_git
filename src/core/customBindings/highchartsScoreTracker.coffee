define (require) ->
  ko = require "knockout"
  require "highcharts"
  # Highcharts must be globally defined

  HighchartsScoreTracker = ->
    return

  HighchartsScoreTracker::getHCConfig = (element, categories, series) ->
    config =
      title: null
      credits:
        enabled: false
      chart:
        renderTo: element
        type: "line"
        plotBackgroundColor: '#e0f0f8'
        height: 312
        marginLeft: 35
      yAxis:
        title: null
        min: 350
        max: 850
        tickInterval: 50
        gridLineColor: "#9ed2e6"
        plotLines: [{
          color: "#058dc0"
          width: 2
          value: 850
          zIndex: 3
        }]
        labels: 
          step: 2
      legend:
        enabled: false
        floating: true
        align: "left"
        verticalAlign: "top"
        borderRadius: 0
        y: -10
        padding: 6
        itemMarginTop: 3
        itemMarginBottom: 3
        itemStyle:
          fontSize: '15px'
      tooltip:
        useHTML: true
        borderRadius: 0
        borderWidth: 0
        shadow: false
        formatter: ->
          rating = "GREAT"
          rating = "GOOD" if this.y <= 759
          rating = "FAIR" if this.y <= 679
          rating = "POOR" if this.y <= 599
          """
          <div class='text-center'>
          <h2 class='ttscore'>#{this.y}</h2> 
          <b>#{rating}</b>
          </div>
          """
      xAxis:
        categories: categories
        lineColor: "#058dc0"
        lineWidth: 2
      series: series
    return config

  HighchartsScoreTracker::toggleSeries = (chart, seriesName, visible) ->
    series = chart.get(seriesName)
    if visible
      series.show()
    else
      series.hide()
    return

  HighchartsScoreTracker::setupSeries = (chart, series) ->
    series.visible.subscribe((visible) => @toggleSeries(chart, series.name, visible)) if chart? and series.visible?.subscribe?
    series.id = series.name
    series.marker =
      radius: 5
      symbol: "circle"
      states:
        hover:
          fillColor: "#ffffff"
          lineColor: series.color
          lineWidth: 2
    return series

  HighchartsScoreTracker::updateSeries = (chart, newSeries) ->
    # The duplicate remove functionality is necessary due to
    # some wierd state issues with highcharts
    for oldSeries in chart.series
      oldSeries.remove(false) if oldSeries?.remove?
    for series in newSeries
      oldSeries = chart.get(series.name)
      oldSeries.remove(false) if oldSeries?.remove?
      chart.addSeries(@setupSeries(chart, series), false)
    chart.redraw()
    return

  HighchartsScoreTracker::init = (element, valueAccessor) ->
    value = valueAccessor()
    categories = ko.unwrap value.categories
    series = ko.unwrap value.series

    configuredSeries = (@setupSeries(null, s) for s in series)
    config = @getHCConfig(element, categories, configuredSeries)

    chart = new Highcharts.Chart(config)

    #for s in series
    #  s.visible.subscribe((visible) => @toggleSeries(chart, s.name, visible)) if s.visible?.subscribe?

    value.categories.subscribe (categories) -> chart.xAxis[0].setCategories(categories)
    value.series.subscribe (series) => @updateSeries(chart, series)

    reflowChart = => chart.reflow()

    value.widgetEvents.on "attached", ->
      setTimeout reflowChart, 100
    return

  HighchartsScoreTracker::register = ->
    ko.bindingHandlers.highchart = {init: => @init.apply(@, arguments)}

  HighchartsScoreTracker.bindingName = "highchart"

  return HighchartsScoreTracker