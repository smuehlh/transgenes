class App.Sequence
    constructor: (@el) ->
        @init()
        @el.bind("input", @enable_controll)
        @el.bind("input", @show_alert)
        @el.bind("reset", @disable_controll)
        @el.bind("change", @send)

    init: =>
        @disable_controll()
        @hide_alert()
        @el.find("textarea").val('')

    disable_controll: =>
        @el.find(":reset").prop('disabled', true)
        @el.find(":submit").prop('disabled', true)

    enable_controll: =>
        if @el.find("textarea").val().length > 0
            @el.find(":reset").prop('disabled', false)
            @el.find(":submit").prop('disabled', false)
        else
            @disable_controll()

    hide_alert: =>
        @el.find(".alert").hide()

    show_alert: =>
        if @el.find("textarea").val().length == Number(@el.find("textarea").attr('maxlength'))
            @el.find(".alert").show()
        else
            @hide_alert()

    send: =>
        @el.submit()

$(document).on "page:change", ->
    cds = new App.Sequence $("#input-cds-form")
    five = new App.Sequence $("#input-five-form")
    three = new App.Sequence $("#input-three-form")
