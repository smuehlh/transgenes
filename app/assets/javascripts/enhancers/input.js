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
    bind_to_input_file();
};

function bind_to_input_textarea() {
    forms.find("textarea").on('input', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');

        thisinput_size = $(this).val().length;
        thisinput_maxsize = $(this).attr('maxlength');
        if (thisinput_size === 0) {
            thisform.find(":submit").prop('disabled', true);
        }
        if (thisinput_size >= thisinput_maxsize) {
            thisform.find("[id^=text-alert]").show();
            thisform.find("textarea").val('');
            thisform.find(":submit").prop('disabled', true);
        } else {
            thisform.find("[id^=text-alert]").hide();
        }
    });
};

function bind_to_input_file() {
    forms.find("input:file").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("textarea").val('');
    });
};