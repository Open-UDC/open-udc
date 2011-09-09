soca = ($) ->
  app = $.sammy '#container', () ->
    this.use 'Couch', 'st'
    this.get '#/', (ctx) ->
      # do something with ctx
    
  $ () ->
    app.run('#/')
  
soca jQuery
