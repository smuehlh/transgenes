window.App ||= {}

App.init = ->
    $("a, span, i, div").tooltip();
    $("input:file").fileupload({
        autoUpload: true
    });

$(document).on "page:change", ->
  App.init()