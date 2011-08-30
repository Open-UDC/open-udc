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
}).call(this);
