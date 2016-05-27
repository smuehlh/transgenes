$(document).ready(function() {
    inputs = $("[id^=input-tab]>form");
    previews = $("[id^=input-view]");
    params = $("#new_submit .params-form");

    clear_forms();

    bind_eventhandlers_to_input_elements();
    bind_eventhandlers_to_preview_elements();
});

$(document).on('page:load', function() {
    clear_forms();
    hide_textboxes();
    disable_form_elements();
});

function clear_forms() {
    inputs.find("textarea").val('');
    inputs.find("input:file").val('');
    inputs.find("[id^=multigene-options]").empty();
};

function hide_textboxes() {
    inputs.find("[id^=text-alert]").hide();
    previews.filter(".alert").hide();
};

function disable_form_elements() {
    inputs.find(":submit").prop('disabled', true);
    previews.find(":button").prop('disabled', true);
    init_params_partial();
};

function bind_eventhandlers_to_input_elements() {
    bind_to_input_textarea();
    bind_to_input_file();
    bind_to_save_button();
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
        thisform.find("input[type=hidden][name*=commit]").val("Save");
        thisform.submit();
    });
};

function bind_to_save_button() {
    inputs.find(":submit[value=Save]").on('click', function() {
        var thisform = $(this).closest("form");
        thisform.find("input[type=hidden][name*=commit]").val("Save");
    });
};

function bind_to_reset_button() {
    inputs.find(":submit[value=Reset]").on('click', function() {
        var thisform = $(this).closest("form");
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');
        thisform.find("textarea").val('');
        thisform.find(":submit").prop('disabled', true);
        thisform.find("input[type=hidden][name*=commit]").val("Reset");
        thisform.submit();
    });
}

function bind_to_select_list() {
    inputs.find("#records_line").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("input[type=hidden][name*=commit]").val("Save");
        thisform.submit();
    });
};

function bind_to_content_change() {
    previews.on('contentchange', function() {
        var thiscontent = $(this).find(".modal-body").text();
        if (thiscontent.match("Not specified")) {
            previews.filter(".alert").hide();
            init_params_partial();
        } else {
            previews.filter(".alert").show();
            $(this).find(":button").prop('disabled', false);
            enable_params_partial();
        }
    });
};

function init_params_partial() {
    params.filter(":input[type=checkbox]").removeAttr('checked');
    params.filter(":input").prop("disabled", true);
};

function enable_params_partial() {
    params.filter(":input").prop("disabled", false);
};