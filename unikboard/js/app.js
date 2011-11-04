(function() {
  var soca;
  soca = function($) {
    var app;
    app = $.sammy('#container', function() {
      this.use('Couch', 'st');
      return this.get('#/', function(ctx) {});
    });
    return $(function() {
      return app.run('#/');
    });
  };
  soca(jQuery);
  $("#_attachments").change(function() {
    $(":submit").show();
    return $("#publish").submit();
  });
  $('#publish').submit(function() {
    var ext, name;
    ext = /.gpg$/;
    name = $("#_attachments:file").val();
    if (!ext.test(name)) {
      alert('The uploaded grain is not a *.gpg file');
      return;
    }
    $("#publish").ajaxSubmit({
      url: "/upload",
      resetForm: true,
      success: function(data, statusText) {
        alert('File uploaded');
        return $(":submit").hide();
      }
    });
    return false;
  });
}).call(this);
