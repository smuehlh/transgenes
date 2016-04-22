window.App ||= {}

App.init = ->
    $('[data-toggle="tooltip"]').tooltip();
    $("input:file").fileupload({
        autoUpload: true
    });

$(document).on "page:change", ->
  App.init()