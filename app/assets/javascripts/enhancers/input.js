$(document).ready(function() {
    forms = $("form");
    init_input_partial();
    bind_eventhandlers_to_input_elements();
    init_preview_partial();
});

function init_input_partial() {
    forms.find("[id^=text-alert]").hide();
    forms.find(":submit").prop('disabled', true);
    forms.find("textarea").val('');
    forms.find("input:file").val('');
    forms.find("[id^=multigene-options]").empty();
};

function init_preview_partial() {
    $("#input-view-alert").hide();
    $(".well").find(":button").prop('disabled', true);
};

function bind_eventhandlers_to_input_elements() {
    bind_to_input_textarea();
};

function bind_to_input_textarea() {
    forms.find("textarea").on('input', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');
    });
};