class App.Sequence
    constructor: (@el) ->
        @setup_form()
# setup_form
# update_form

    setup_form: =>
        @el.find("form").find(".alert").hide()
        @el.find("form").find("textarea").val('')
        @el.find("form").find(":submit[value=Save]").prop('disabled', true)
        @el.find("form").find(":submit[value=Reset]").prop('disabled', true)
        @el.filter("button").prop('disabled', true)

$(document).on "page:change", ->
    cds = new App.Sequence $("[id^=input-][id$=-cds]")
    five = new App.Sequence $("[id^=input-][id$=-five]")
    three = new App.Sequence $("[id^=input-][id$=-three]")