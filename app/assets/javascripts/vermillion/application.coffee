do ->
  unless window.CustomEvent?
    CustomEvent = (event, params) ->
      params ||= { bubbles: false, cancelable: false, detail: undefined }
      evt = document.createEvent('CustomEvent')
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail)
      evt

    CustomEvent.prototype = window.Event.prototype
    window.CustomEvent = CustomEvent

delay = (ms) -> new Promise (resolve, reject) -> setTimeout(resolve, ms)

text = (s) -> document.createTextNode(s)
tag = (name, content..., attrs) ->
  result = document.createElement(name)
  result.appendChild(n) for n in content
  result.setAttribute(k, v) for k,v of attrs when attrs.hasOwnProperty(k)
  result

timeFormat = new Intl.DateTimeFormat('en-US', { weekday: "short", hour: "numeric", minute: "numeric", second: "numeric" })
parseTime = (s) -> if s? then new Date(s) else s
timeTag = (d) -> if d? then tag('time', text(timeFormat.format(d)), datetime: d.toISOString()) else tag('time')
updateTime = (element, d) ->
  element.innerText = timeFormat.format(d)
  element.setAttribute('datetime', d.toISOString())

showTask = (url) ->
  fetch(url, mode: 'cors', headers: { 'Accept': 'application/json' })
    .then (response) ->
      switch response.status
        when 200 then response.json()
        when 410 then throw new Error("Gone")
        else throw new Error(response.statusText)

createTask = (endpoint, details) ->
  fetch endpoint,
      method: 'post'
      mode: 'cors'
      body: JSON.stringify(details)
      headers: 
        'Content-Type': 'application/json'
        Accept: 'application/json'
    .then (response) ->
      if response.ok
        response.headers.get('Location')
      else
        response.json().then (detail) ->
          error = new Error(response.status + " " + response.statusText)
          error.detail = detail
          Promise.reject(error)

class Task
  constructor: (element, @url) ->
    description = tag('a', href: @url)
    status = tag('span', text('pending'))
    startedAt = timeTag()
    progress = tag('progress')
    finishedAt = timeTag()

    @element = element.appendChild(tag('li', description, text(' '), status, text(' '), startedAt, text(' '), progress, text(' '), finishedAt))

    future = undefined
    promise = new Promise (resolve, reject) -> future = { resolve, reject }

    Object.defineProperty @, 'promise',
      value: promise
      writable: false

    Object.defineProperty @, 'description',
      get: -> JSON.parse(description.innerText)
      set: (v) -> description.innerText = JSON.stringify(v)

    Object.defineProperty @, 'status',
      get: -> status.innerText
      set: (v) ->
        status.innerText = v
        switch v
          when 'completed' then future.resolve(this)
          when 'failed' then future.reject(this)

    Object.defineProperty @, 'startedAt',
      get: -> parseTime(startedAt.getAttribute('datetime'))
      set: (v) -> updateTime(startedAt, v)

    Object.defineProperty @, 'finishedAt',
      get: ->
        s = finishedAt.getAttribute('datetime')
        if s? then new Date(s) else s
      set: (v) -> updateTime(finishedAt, v)

    Object.defineProperty @, 'total',
      get: -> progress.max
      set: (v) ->
        v = Number(v)
        progress.max = if isNaN(v) then 100 else v

    Object.defineProperty @, 'progress',
      get: -> progress.value
      set: (v) ->
        v = Number(v)
        if isNaN(v) then progress.removeAttribute('value') else progress.value = v

    Object.defineProperty @, 'discard',
      enumerable: false
      value: =>
        @element.dispatchEvent(new CustomEvent('discarded', bubbles: true, detail: this))
        element.removeChild(@element)

  addEventListener: -> @element.addEventListener(arguments...)
  removeEventListener: -> @element.removeEventListener(arguments...)
  dispatchEvent: -> @element.dispatchEvent(arguments...)

  update: ->
    showTask(@url)
      .then ({task: detail}) =>
        @description = detail.description
        @status = detail.status
        @startedAt = new Date(detail.started_at) if detail.started_at?
        @finishedAt = new Date(detail.started_at) if detail.finished_at?
        @total = detail.total
        @progress = detail.progress
        switch detail.status
          when 'pending'
            delay(500).then => @update()
          when 'running'
            @element.dispatchEvent(new CustomEvent('progress', bubbles: true, detail: this))
            delay(5000).then => @update()
          when 'failed'
            @discard() if @element.dispatchEvent(new CustomEvent('failed', bubbles: true, detail: this))
          when 'completed'
            @discard() if @element.dispatchEvent(new CustomEvent('completed', bubbles: true, detail: this))
          else
            console?.error "unhandled status", detail.status
        this
      .catch (e) =>
        @discard()
        @

trackedUrls = (storage, storageKey) -> JSON.parse(storage.getItem(storageKey) || "[]")
updateTrackedUrls = (storage, storageKey, tasks) ->
  if tasks.length == 0
    storage.removeItem storageKey
  else
    storage.setItem storageKey, JSON.stringify(tasks)

###
# Sample usage:

window.vermillion = new Vermillion(document.body, "/vermillion/tasks")
vermillion.start()      # returns an array of already-running task objects, which can be ignored
  # optionally pass the key under which the task list will be stored (defaults to "vermillionTasks", and the storage to use (defaults to window.localStorage)

task = vermillion.run('job_type', { contents: "job description" })
# progress events (typically used to update a progress bar)
task.addEventListener 'progress', (event) -> console.log "progress", task.progress, '/', task.total
# completed/failed events
task.addEventListener 'completed', (event) -> console.log "completed", task
task.addEventListener 'failed', (event) -> console.log "failed", task
# alternatively:
task.promise.then((-> console.log "completed"), ((error) -> console.error "failed", error))
###

class @Vermillion
  constructor: (element, @serviceEndpoint = '/vermillion/tasks') ->
    element = document.querySelector(element) if typeof element == 'string'
    @_element = element.appendChild(tag('ul'))
    @_element.addEventListener 'discarded', (event) =>
      event.stopPropagation()
      delete @_tasks[event.detail.url]
      @updateTrackedUrls()
    @_tasks = {}

  updateTrackedUrls: -> updateTrackedUrls(@storage, @storageKey, Object.keys(@_tasks))

  track: (url) ->
    task = @_tasks[url] = new Task(@_element, url)
    @updateTrackedUrls()
    task.update()

  start: (@storageKey = "vermillionTasks", @storage = localStorage) ->
    @_tasks[url] = new Task(@_element, url) for url in trackedUrls(@storage, @storageKey)
    delay(0).then => @update()
    task for url, task of @_tasks

  update: -> (task.update() for url, task of @_tasks)

  run: (name, description) ->
    createTask(@serviceEndpoint, { name, description })
      .then (url) => @track(url)

