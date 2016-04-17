class App.Enhancer
    constructor: (@el) ->
        @setup_form()
        @setup_view()
        @el.find("form").bind("input", @update_form)
        @el.find("form").find(":submit[value=Reset]").bind("click", @reset_form)

    reset_form: =>
        @el.find("form").find("textarea").val('')

    setup_form: =>
        @el.find("form").find(".alert").hide()
        @el.find("form").find("textarea").val('')
        @el.find("form").find(":submit[value=Save]").prop('disabled', true)
        @el.find("form").find(":submit[value=Reset]").prop('disabled', true)

    setup_view: =>
        @el.find("[id^=view-button]").prop('disabled', true)

    update_form: =>
        textlength = @el.find("textarea").val().length
        maxlength = Number(@el.find("textarea").attr('maxlength'))
        if textlength > 0
            @el.find("form").find(":submit[value=Save]").prop('disabled', false)
            @el.find("form").find(":submit[value=Reset]").prop('disabled', false)
        else
            @el.find("form").find(":submit[value=Save]").prop('disabled', true)
            @el.find("form").find(":submit[value=Reset]").prop('disabled', true)
        if textlength < maxlength
            @el.find("form").find(".alert").hide()
        else
            @el.find("form").find(".alert").show()

    # TODO
    # update_view

$(document).on "page:change", ->
    cds = new App.Enhancer $("[id^=input-][id$=-cds]")
    five = new App.Enhancer $("[id^=input-][id$=-five]")
    three = new App.Enhancer $("[id^=input-][id$=-three]")