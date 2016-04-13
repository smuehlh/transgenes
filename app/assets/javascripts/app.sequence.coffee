class App.Sequence
    constructor: (@el) ->
        @disable_controll()
        @el.bind("input", @enable_controll)
        @el.bind("reset", @disable_controll)
        @el.bind("change", @send)

    disable_controll: =>
        @el.find(":reset").prop('disabled', true)
        @el.find(":submit").prop('disabled', true)

    enable_controll: =>
        if @el.find("textarea").val().length > 0
            @el.find(":reset").prop('disabled', false)
            @el.find(":submit").prop('disabled', false)
        else
            @disable_controll()

    send: =>
        @el.submit()

$(document).on "page:change", ->
    cds = new App.Sequence $("#input-cds-form")
    five = new App.Sequence $("#input-five-form")
    three = new App.Sequence $("#input-three-form")
