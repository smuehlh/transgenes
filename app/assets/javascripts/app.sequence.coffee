class App.Sequence
    constructor: (@el) ->
        @el.find(":button").first().prop('disabled', true)
        @el.bind("input", @enable_reset)

    enable_reset: =>
        @el.find(":button").first().prop('disabled', false)

$(document).on "page:change", ->
    seq = new App.Sequence $("#input-sequence-form")
