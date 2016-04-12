class App.Sequence
    constructor: (@el) ->
        @el.find(":reset").prop('disabled', true)
        @el.bind("input", @enable_reset)
        @el.bind("change", @send)

    enable_reset: =>
        @el.find(":reset").prop('disabled', false)
        # todo only if input.length > 0

    # send: =>
    #     @el.submit()

$(document).on "page:change", ->
    seq = new App.Sequence $("#input-sequence-form")
