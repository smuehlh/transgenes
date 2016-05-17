class App.Enhancer
    constructor: (@el) ->
        @setup_form()
        @setup_view()
        @el.find("form").bind("input", @update_form)
        @el.find("form").find(":submit[value=Reset]").bind("click", @reset_form)
        @el.find('form').find("input:file").bind("change", @upload_file)
        @el.filter("[id^=input-view]").bind("contentchange", @update_view)

    reset_form: =>
        @el.find("form").find("textarea").val('')
        @el.find("form").find("input:file").val('')
        @el.find("form").find("#multigene-options").empty()
        @el.find("form").find("#multigene-info-container").empty()

    setup_form: =>
        @el.find("form").find(".alert").hide()
        @el.find("form").find("textarea").val('')
        @el.find("form").find(":submit[value=Save]").prop('disabled', true)
        @el.find("form").find(":submit[value=Reset]").prop('disabled', true)

    setup_view: =>
        $("#input-view-alert").hide()
        @el.find("[id^=view-button]").prop('disabled', true)

    upload_file: =>
        @update_form
        @el.find("form").submit()

    update_form: =>
        textlength = @el.find("textarea").val().length
        filelength = @el.find("form").find("input:file").val().length
        maxlength = Number(@el.find("textarea").attr('maxlength'))
        if textlength > 0 || filelength > 0
            @el.find("form").find(":submit[value=Save]").prop('disabled', false)
            @el.find("form").find(":submit[value=Reset]").prop('disabled', false)
        else
            @el.find("form").find(":submit[value=Save]").prop('disabled', true)
            @el.find("form").find(":submit[value=Reset]").prop('disabled', true)
        if textlength < maxlength
            @el.find("form").find(".alert").hide()
        else
            @el.find("form").find(".alert").show()

    update_view: =>
        textlength = @el.find(".input-view-text").text().length
        if textlength > 0
            @el.find("[id^=view-button]").prop('disabled', false)
            $("#input-view-alert").toggle() # 'show' not working
        else
            @el.find("[id^=view-button]").prop('disabled', true)
            $("#input-view-alert").toggle() # 'hide' not working

$(document).on "page:change", ->
    cds = new App.Enhancer $("[id^=input-][id$=-cds]")
    five = new App.Enhancer $("[id^=input-][id$=-five]")
    three = new App.Enhancer $("[id^=input-][id$=-three]")