$(document).ready(function() {
    inputs = $("[id^=input-tab]>form");
    previews = $("[id^=input-view]");
    params = $("#new_submit");
    init_input_partial();
    init_preview_partial();
    init_params_parital();

    bind_eventhandlers_to_input_elements();
    bind_eventhandlers_to_preview_elements();
});

function init_input_partial() {
    inputs.find("[id^=text-alert]").hide();
    inputs.find(":submit").prop('disabled', true);
    inputs.find("textarea").val('');
    inputs.find("input:file").val('');
    inputs.find("[id^=multigene-options]").empty();
};

function init_preview_partial() {
    previews.filter(".alert").hide();
    previews.find(":button").prop('disabled', true);
};

function init_params_parital() {
    params.find(":input").removeAttr('checked');
    params.find(":input").prop("disabled", true);
    params.find(":submit").prop("disabled", true);
};

function bind_eventhandlers_to_input_elements() {
    bind_to_input_textarea();
    bind_to_input_file();
    bind_to_reset_button();
    // NOTE: do not bind to_select_list here, since the element will be created later
};

function bind_eventhandlers_to_preview_elements() {
    bind_to_content_change();
};

function bind_to_input_textarea() {
    inputs.find("textarea").on('input', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');

        var thisinput_size = $(this).val().length;
        var thisinput_maxsize = $(this).attr('maxlength');
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
    inputs.find("input:file").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("textarea").val('');
    });
};

function bind_to_reset_button() {
    inputs.find(":submit[value=Reset]").on('click', function() {
        var thisform = $(this).closest("form");
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');
        thisform.find("textarea").val('');
        thisform.find(":submit").prop('disabled', true);
        thisform.submit();
    });
}

function bind_to_select_list() {
    inputs.find("#records_line").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit[value=Save]").click();
    });
};

function bind_to_content_change() {
    previews.on('contentchange', function() {
        var thiscontent = $(this).find(".modal-body").text();
        if (thiscontent.match("Not specified")) {
            $(this).find(":button").prop('disabled', true);
            previews.filter(".alert").hide();
            init_params_parital();
        } else {
            // NOTE button is enabled by default.
            previews.filter(".alert").show();
            enable_params_partial();
        }
    });
};

function enable_params_partial() {
    params.find(":input").prop("disabled", false);
    params.find(":submit").prop("disabled", false);
};