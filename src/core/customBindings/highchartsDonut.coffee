define (require) ->
  ko = require "knockout"
  require "highcharts"
  # Highcharts must be globally defined

  HighchartsDonut = ->
    @limits =
      maxScore: 850
      great: 760
      good: 680
      fair: 600

    @fillColors =
      default: "#e4e4e4"
      score: "#008dbe"
      scoreHighlight: "#00b6fb"
      increase: "#32af4a"
      decrease: "#fe0505"
    return

  HighchartsDonut::getHCConfig = (series, element, title, selectedRating) ->
    config =
      title: title
      credits: {enabled: false}
      tooltip: {enabled: false}
      chart:
        renderTo: element
        type: "pie"
        height: 182
        width:  182
        animation:
          duration: 150
      series: [series]
      plotOptions:
        pie:
          allowPointSelect: false
          dataLabels: {enabled: false}
          slicedOffset: 2
    if selectedRating?
      config.plotOptions.pie.point =
        events:
          mouseOver: ->
            # TODO: Fix animation bug where from mouseOver
            #return unless doneAnimating() or !Modernizr.csstransforms3d
            @select(true)
            return
          click: ->
            @select(true)
            return
          select: (e) ->
            e.target.update {y: e.target.y + 8}
            selectedRating(@rating)
            return
          unselect: (e) ->
            e.target.update {y: e.target.y - 8}
            return
    return config

  HighchartsDonut::getRating = (score) ->
    return "POOR" if score < @limits.fair
    return "FAIR" if score < @limits.good
    return "GOOD" if score < @limits.great
    return "GREAT"

  HighchartsDonut::getTitle = (score, showChange, oldScore, title, bureau, isLoading) ->
    if showChange and score - oldScore isnt 0
      direction = if score - oldScore > 0 then "up" else "down"
      changeArrow = "<span class='donut-arrow-#{direction}'></span>"
    else
      changeArrow = ""
    text = ""
    if score > 0
      text = """
        <div class='hcDonut-innerCircle'>
          <div class='hcDonut-contentWrap'>
            <p class='hcDonut-text-title'>#{title}</p>
            <h1 class='hcDonut-score'>#{changeArrow}#{score}</h1>
            <p class='hcDonut-text-title'>#{bureau}</p>
            <p class='hcDonut-text-rating'>#{@getRating(score)}</p>
          </div>
        </div>
      """
    else 
      if isLoading
        text = """
          <div class='hcDonut-innerCircle'>
            <div class='hcDonut-contentWrap'>
              <div class='hcDonut-loadingWave loadingWave'></div>
            </div>
          </div>
        """
      else
        text = """
          <div class='hcDonut-innerCircle'>
            <div class='hcDonut-contentWrap'>
              <p class='hcDonut-text-title'>#{title}</p>
              <h1 class='hcDonut-score'>?</h1>
            </div>
          </div>
        """

    return {
      text: text
      useHTML: true
      align: 'center'
      verticalAlign: 'middle'
      y: 0
    }

  HighchartsDonut::getSeries = (score, showChange, oldScore, animateInitial) ->
    list = []
    if showChange
      change = Math.abs(score - oldScore)
      pointsLeft = Math.min(score, oldScore)
    else
      change = 0
      pointsLeft = score

    fillColor = @fillColors.score
    highlightColor = @fillColors.scoreHighlight
    defaultFillColor = @fillColors.default
    changeColor = if score - oldScore > 0 then @fillColors.increase else @fillColors.decrease

    addSection = (points, limit, rating) ->
      section = {color: fillColor, y: limit, rating: rating, marker: {states: {hover: {enabled: false}}}}
      if points is 0
        fillColor = defaultFillColor
        section.color = fillColor
        list.push section
        return 0
      else
        section.marker.states.select =
          enabled: true
          color: highlightColor

      section.y = Math.min(limit, points)
      list.push section
      if points <= limit
        fillColor = changeColor
        changeLeft = change
        change = 0
        return changeLeft if limit is points
        return addSection(changeLeft, limit - points, rating)

      return Math.max(0, points - limit)

    pointsLeft = addSection pointsLeft, @limits.fair, "POOR"
    pointsLeft = addSection pointsLeft, @limits.good - @limits.fair, "FAIR"
    pointsLeft = addSection pointsLeft, @limits.great - @limits.good, "GOOD"
    pointsLeft = addSection pointsLeft, @limits.maxScore - @limits.great, "GREAT"

    if animateInitial?()
      animate = true
      animateInitial(false)
    else
      animate = false

    return {
      name: "Score"
      data: list
      size: 170
      innerSize: "75%"
      animation: animate
    }

  HighchartsDonut::updateChart = (chart, score, showChange, oldScore, title, bureau, isLoading) ->
    oldSeries = chart.series[0]
    oldSeries.remove(false) if oldSeries?.remove?
    chart.addSeries @getSeries(score, showChange, oldScore, (-> not isLoading))

    chart.setTitle @getTitle(score, showChange, oldScore, title, bureau, isLoading)

    chart.redraw()
    return

  HighchartsDonut::init = (element, valueAccessor) ->
    animationFinished = false

    value = valueAccessor()
    score = ko.unwrap value.score
    title = ko.unwrap value.title
    bureau = ko.unwrap value.bureau

    showChange = value.hasOwnProperty("oldScore")
    oldScore = ko.unwrap value.oldScore
    isLoading = if value.hasOwnProperty("loading") then ko.unwrap(value.loading) else false
    selectedRating = if value.hasOwnProperty("selectedRating") and value.selectedRating.subscribe? then value.selectedRating else null

    title ?= "NEW SCORE"
    bureau ?= ""

    alreadyDrawn = false
    series = @getSeries(score, showChange, oldScore, value.animateInitial)
    titleConfig = @getTitle(score, showChange, oldScore, title, bureau, isLoading)
    chart = new Highcharts.Chart(@getHCConfig(series, element, titleConfig, selectedRating))

    if value.score.subscribe?
      value.score.subscribe (newScore) =>
        @updateChart(chart, newScore, showChange, value.oldScore?(), title, bureau, value.loading?())

    if value.oldScore?.subscribe?
      value.oldScore.subscribe (newOldScore) =>
        @updateChart(chart, value.score(), showChange, newOldScore, title, bureau, value.loading?())

    if value.loading?.subscribe?
      value.loading.subscribe (loading) =>
        @updateChart(chart, value.score(), showChange, value.oldScore?(), title, bureau, loading)

    return

  HighchartsDonut::register = ->
    ko.bindingHandlers.hcDonut = {init: => @init.apply(@, arguments)}

  HighchartsDonut.bindingName = "hcDonut"

  return HighchartsDonut