define ->

  bureaus =
    "Equifax": 1
    "Experian": 2
    "TransUnion": 4
    "All": 7

  CheckBureau = (rawBureau, bureau) ->
    switch rawBureau
      when 1 then bureau is "Equifax"
      when 2 then bureau is "Experian"
      when 3 then bureau is "Equifax" or bureau is "Experian"
      when 4 then bureau is "TransUnion"
      when 5 then bureau is "Equifax" or bureau is "TransUnion"
      when 6 then bureau is "Experian" or bureau is "TransUnion"
      when 7 then bureau is "Equifax" or bureau is "Experian" or bureau is "TransUnion"
      else false

  ContainsComponent = (list, component, bureau) ->
    if bureau?
      return list.some (c) -> c.name is component and CheckBureau(c.rawBureau, bureau)
    else
      return list.some (c) -> c.name is component
  HasAll = (array, list, bureau) -> not (array.some (e) -> not ContainsComponent(list, e, bureau))
  HasAtLeastOne = (array, list, bureau) -> array.some (e) -> ContainsComponent(list, e, bureau)
  VerifyComponent = (component, list, all, bureau) ->
    return false unless list instanceof Array
    return ContainsComponent(list, component, bureau) unless component instanceof Array
    if all
      return HasAll component, list, bureau
    else
      return HasAtLeastOne component, list, bureau
  FindComponent = (component, list) ->
    return c for c in list when c.name is component
    return null

  CustomerModel = (@app, @ds, @capi, rawModel) ->
    @lastPingTime = new Date()
    @map(rawModel) if rawModel?
    @isPremium = ->
      return /premium/i.test(@layout)
    @isPlus = ->
      return /plus/i.test(@layout)
    @isMonitoringOnly = ->
      return /monitoringonly/i.test(@layout)
    @app.on("account:changed").then () =>
      @refresh()

    return

  CustomerModel::map = (rawModel) ->
    {
      @accountNumber,
      @activeComponents,
      @activeRecurringComponents,
      @billingDescriptor,
      @brand,
      @canCancel,
      @currentProductPrice,
      @currentPurchaseId,
      @customerCarePhoneNumber,
      @firstName,
      @fulfillmentPartner,
      @globalClientId,
      @hasMemberBenefitsTab,
      @inactiveComponents,
      @isActive,
      @isAuthenticated,
      @isModular,
      @isMonitoringActive,
      @isSuspended,
      @layout,
      @manualAuthCustomerCarePhoneNumber,
      @memberId,
      @name,
      @productLine,
      @trialDays
    } = rawModel
    @brand.fullName = "#{@brand.name}&reg;" if @brand?
    return

  CustomerModel::refresh = ->
    return @ds.post("/refresh").catch()
    .then =>
      @capi.get("")
    .then (response) =>
      @map(response) if response?
      @app.trigger "customer:changed"
      return @

  CustomerModel::HasActiveRecurringProductBureau = (component, bureau, all = false) ->
    return VerifyComponent component, @activeRecurringComponents, all, bureau

  CustomerModel::HasActiveProductBureau = (component, bureau, all = false) ->
    return VerifyComponent component, @activeComponents, all, bureau

  CustomerModel::HasActiveProduct = (component, all = false) ->
    return VerifyComponent component, @activeComponents, all

  CustomerModel::HasActiveRecurringProduct = (component, all = false) ->
    return VerifyComponent component, @activeRecurringComponents, all

  CustomerModel::HasInactiveProduct = (component, all = false) ->
    return VerifyComponent component, @inactiveComponents, all

  CustomerModel::HasInactiveProductBureau = (component, bureau, all = false) ->
    return VerifyComponent component, @inactiveComponents, all, bureau

  CustomerModel::HasProductBureau = (component, bureau, all = false) ->
    return @HasActiveRecurringProductBureau(component, bureau, all) or @HasInactiveProductBureau(component, bureau, all)

  CustomerModel::GetBureausForComponent = (component) ->
    list = []
    foundComponent = FindComponent(component, @activeRecurringComponents) ?
      FindComponent(component, @activeComponents) ?
      FindComponent(component, @inactiveComponents)
    list.push "Equifax" if foundComponent.rawBureau & bureaus["Equifax"]
    list.push "Experian" if foundComponent.rawBureau & bureaus["Experian"]
    list.push "TransUnion" if foundComponent.rawBureau & bureaus["TransUnion"]
    return list

  CustomerModel::PrettyComponentBureaus = (component) ->
    list = @GetBureausForComponent(component)
    switch list.length
      when 3 then "#{list[0]}&reg;, #{list[1]}&reg;, and #{list[2]}&reg;"
      when 2 then "#{list[0]}&reg; and #{list[1]}&reg;"
      when 1 then "#{list[0]}&reg;"
      else ""

  return CustomerModel
