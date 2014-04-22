define ->
  ActivityTracker = (dataservice) ->
    @ds = dataservice
    return

  ActivityTracker::log = (activity, activityInfo) ->
    data =  
      activity: activity
      activityInfo: activityInfo
    @ds.post('/activity/navigation', data)
    # TODO: implement error handling or something
    #.catch ->

  return ActivityTracker
