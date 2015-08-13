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
  fetch(url, headers: { 'Accept': 'application/json' })
    .then (response) ->
      switch response.status
        when 200 then response.json()
        when 410 then throw new Error("Gone")
        else throw new Error(response.statusText)

createTask = (description) ->
  fetch "/vermillion/tasks",
      method: 'post'
      headers: 
        'Content-Type': 'application/json'
        'Accept': 'application/json'
      body: JSON.stringify(description)
    .then (response) ->
      throw new Error(response.status + " " + response.statusText) unless response.status == 202
      response.headers.get('Location')

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

class @Vermillion
  constructor: (element) ->
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

  start: (@storage = localStorage, @storageKey = "vermillionTasks") ->
    @_tasks[url] = new Task(@_element, url) for url in trackedUrls(@storage, @storageKey)
    delay(0).then => @update()
    task for url, task of @_tasks

  update: -> (task.update() for url, task of @_tasks)

  run: (description) -> createTask(description).then (url) => @track(url)

#################################### THE FOLLOWING IS FOR TESTING, AND SIMULATES WHAT THE HOST PAGE WILL DO #####################################
logEvents = (event) -> console.log "CONTAINER SAW EVENT", event.type, event

document.addEventListener "DOMContentLoaded", ->
  div = document.body.insertBefore(tag('div'), document.body.firstChild)
  div.addEventListener 'discarded', logEvents
  div.addEventListener 'progress', logEvents
  window.vermillion = new Vermillion(div)
  tasks = vermillion.start()       # returns an array of task objects
  console.log "start", tasks

  # console.log "running", vermillion.run({ url: "test.mp4" })

# want the following api:
#    vermillion = new Vermillion(document.body)
#    vermillion.start(window.localStorage, "vermillionTasks")   => [Task]               -- allows attaching event handlers early
#    task = vermillion.run(description)                         => Task                 -- allows attaching event handlers on launch
#    {status,description,...} = task                                                    -- accessors for control properties
#    task.then({detail})
#    task.catch(error)
#    vermillion.addEventListener('change', function(event) { {task, href} = event.detail; });

# localStorage.setItem("test", "this is a test");
# localStorage.getItem("test") => "this is a test"
# localStorage.removeItem("test")
# localStorage.length => the number of keys
# localStorage.key(n) => the nth key
# localStorage.clear()
# fires "storage" events with {key, oldValue, newValue, url, storageArea}
