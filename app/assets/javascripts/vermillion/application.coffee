do ->
  unless window.CustomEvent?
    CustomEvent = (event, params) ->
      params ||= { bubbles: false, cancelable: false, detail: undefined }
      evt = document.createEvent('CustomEvent')
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
      evt

    CustomEvent.prototype = window.Event.prototype
    window.CustomEvent = CustomEvent

class CustomEventTarget
  constructor: ->
    @listeners = {}

  addEventListener: (type, callback) ->
    callbacks = @listeners[type]
    @listeners[type] = callbacks = [] unless callbacks?
    index = callbacks.indexOf(callback)
    return unless index < 0
    callbacks.push(callback)
    undefined

  removeEventListener: (type, callback) ->
    callbacks = @listeners[type]
    return unless callbacks?
    index = callbacks.indexOf(callback)
    callbacks.splice(index, 1) unless index < 0
    undefined

  dispatchEvent: (event) ->
    throw Error("event is null.") unless event?
    throw Error("event is not initialized.") unless event.type
    callbacks = @listeners[event.type]?.slice(0) || []
    for callback in callbacks when callbacks.indexOf(callback) >= 0
      try
        callback.call(this, event)
      catch
        undefined
    event.defaultPrevented

sleep = (delay) -> new Promise (resolve, reject) -> setTimeout(resolve, delay)

class Task extends CustomEventTarget
  constructor: (url) ->
    Object.defineProperty @, 'url', get: -> url

  update: ->
    $this = this
    fetch(@url, headers: { 'Accept': 'application/json' })
      .then (response) ->
        switch response.status
          when 200 then response.json()
          when 410 then throw new Error("Gone")
          else throw new Error(response.statusText)
      .then (message) ->
        $this.detail = message.task
        $this.dispatchEvent(new CustomEvent('progress', detail: $this)) if $this.detail.status == 'running'

class TaskMemory extends CustomEventTarget
  constructor: (@service, @storage, @storageKey = "vermillionTasks") ->
    super()
    @runningTasks = (new Task(url) for url in @taskUrls())
    for task in @runningTasks.slice()
      task.update()
        .then (status) =>
          @scheduleUpdateFor(task) unless @service.dispatchEvent(new CustomEvent('discovered', cancelable: true, detail: task))
        .catch (error) =>
          console.log "discard", task.url, error.message
          @removeTask(task)

  scheduleUpdateFor: (task) ->
    task.update().then (detail) ->
      console.log "updated to", task.detail
      switch task.detail.status || 'pending'
        when 'pending'
          sleep(500).then => @scheduleUpdateFor(task)
          console.log "rescheduled (pending)"
        when 'failed'
          # notify and stop tracking
          console.log "notify failed"
        when 'completed'
          # notify and stop tracking
          console.log "notify completed"
        when 'running'
          # notify progress
          @dispatchEvent(new CustomEvent('progress', cancelable: true, detail: task))
          sleep(5000).then => @scheduleUpdateFor(task)

  updateStorage: ->
    @storage.setItem @storageKey, JSON.stringify(task.url for task in @runningTasks)

  taskUrls: -> 
    JSON.parse(@storage.getItem(@storageKey) || "[]")

  addTask: (task) ->
    @runningTasks.push(task)
    @scheduleUpdateFor(task)
    @updateStorage()

  removeTask: (task) ->
    index = @runningTasks.indexOf(task)
    @runningTasks.splice(index, 1) unless index < 0
    @updateStorage()

createTask = (description) ->
  fetch "/vermillion/tasks",
    method: 'post'
    headers: 
      'Content-Type': 'application/json'
      'Accept': 'application/json'
    body: JSON.stringify(description)

class @Vermillion extends CustomEventTarget
  start: (storage) ->
    @taskMemory = new TaskMemory(this, storage)
    @taskMemory.addEventListener 'discovered', (event) =>
      event.preventDefault() if @dispatchEvent(new CustomEvent('discovered', cancelable: true, detail: event.detail))

  run: (description) ->
    createTask(description).then (response) =>
      throw new Error(response.status + " " + response.statusText) unless response.status == 202
      url = response.headers.get('Location')
      task = new Task(url)
      @taskMemory.addTask(task)
      task

test = new @Vermillion()
test.start(localStorage)
test.addEventListener 'discovered', (event) ->
  console.warn "discovered", event.detail

if true
  test.run url: 'test.mp4'
    .then (task) ->
      console.log "task", task.url
      task.update().then (detail) ->
        console.log "detail", detail

# want the following api:
#    task = vermillion.run({description});
#    task.detail => { status, description, ... }
#    task.status().then({status, ...})
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
