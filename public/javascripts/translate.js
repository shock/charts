  google.load("language", "1");

  
  jQuery.fn.translate = function() {
    jQuery.each( jQuery(this), function(i,v) {
      var text_el = jQuery(v);
      if( text_el.is("input") )
        var text = text_el.val();
      else
        var text = text_el.html();
      google.language.detect(text, function(result) {
        if (!result.error && result.language && (result.language != translate_to_language)) {
          google.language.translate(text, result.language, translate_to_language,
          function(result) {
            if (result.translation) {
              if( text_el.is("input") )
                text_el.val(result.translation);
              else
                text_el.html(result.translation);
            }
          });
        }
      });
    });
  }
