class App.Sequence
    constructor: (@el) ->
        @init()
        @el.bind("input", @enable_reset)
        @el.bind("change", @send)

    init: =>
        @el.find(":reset").prop('disabled', true)
        @el.find(":submit").css({"visibility":"hidden"});

    enable_reset: =>
        @el.find(":reset").prop('disabled', false)

    send: =>
        @el.submit()

$(document).on "page:change", ->
    seq = new App.Sequence $("#input-sequence-form")
