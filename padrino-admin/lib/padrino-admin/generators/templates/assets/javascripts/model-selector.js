!function($) {
  'use strict';

  $(function() {
    var selector = $("#model-selector");
    selector.change(function(){
      var path = $(this).children(':selected').val();
      if(path !== ""){
        location.href = path;
      }
    });
  });
}(window.jQuery);
