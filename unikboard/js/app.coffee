soca = ($) ->
  app = $.sammy '#container', () ->
    this.use 'Couch', 'st'
    this.get '#/', (ctx) ->
      # do something with ctx
    
  $ () ->
    app.run('#/')
  
soca jQuery

$("#_attachments").change ->
  $(":submit").show()
  $("#publish").submit()

$('#publish').submit ->
  ext = /.gpg$/
  name = $("#_attachments:file").val()
  if (! ext.test(name))
    alert('The uploaded grain is not a *.gpg file')
    return

  $("#publish").ajaxSubmit
    url: "/upload",
    resetForm: true,
    success: (data, statusText) ->
      alert('File uploaded')
      $(":submit").hide()

  return false
