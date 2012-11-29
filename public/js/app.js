$( function () {
  $("a[href='#mail']").click( function() {
    if ($("#email").hasClass("short")) {
      $("html, body").animate({ "scrollTop": 300 }, 500);
      $("#email").removeClass("short");    
    } else {
      $("html, body").animate({ "scrollTop": 0 }, 500);
      $("#email").addClass("short");          
    }
  });
});