$(document).ready(function() {
    inputs = $("[id^=input-tab]>form");
    previews = $("[id^=input-view]");
    params = $("#new_enhanced_gene .params-form");

    clear_forms();
    hide_alerts();
    disable_form_elements();

    bind_eventhandlers_to_input_elements();
    bind_eventhandlers_to_preview_elements();
    bind_eventhandlers_to_params_elements();

    bind_validate_to_input();
    bind_autocomplete_to_input();
});

$(document).on('page:load', function() {
    clear_forms();
    hide_alerts();
    disable_form_elements();
});

function clear_forms() {
    inputs.find("textarea").val('');
    inputs.find("input:file").val('');
    inputs.find("input:text").val('');
    inputs.find("[id^=multigene-options]").empty();
};

function hide_alerts() {
    inputs.find(".alert").hide();
    previews.filter(".alert").hide();
};

function disable_form_elements() {
    inputs.find(":submit").prop('disabled', true);
    previews.find(":button").prop('disabled', true);
    init_params_partial();
};

function bind_eventhandlers_to_input_elements() {
    bind_to_accordion();
    bind_to_input_textarea();
    bind_to_input_file();
    bind_to_input_text();
    bind_to_save_button();
    bind_to_reset_button();
    // NOTE: do not bind to_select_list here, since the element will be created later
};

function bind_eventhandlers_to_preview_elements() {
    bind_to_content_change();
};

function bind_eventhandlers_to_params_elements() {
    bind_to_checkbox_change();
};

function bind_to_accordion() {
    inputs.find(".panel-collapse").on('hide.bs.collapse', function() {
        // display as collapsed panel
        var thispanelhead = $(this).prev();
        thispanelhead.find(".glyphicon").removeClass("glyphicon-collapse-up").addClass("glyphicon-collapse-down");
        thispanelhead.find("[title]").attr('data-original-title', "Click to expand").tooltip("show");
    });
    inputs.find(".panel-collapse").on('show.bs.collapse', function() {
        // display as expanded panel
        var thispanelhead = $(this).prev();
        thispanelhead.find(".glyphicon").removeClass("glyphicon-collapse-down").addClass("glyphicon-collapse-up");
        thispanelhead.find("[title]").attr('data-original-title', "Click to collapse").tooltip("show");
    });
};

function bind_to_input_textarea() {
    inputs.find("textarea").on('input', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');
        thisform.find("input:text").val('');

        var thisinput_size = $(this).val().length;
        var thisinput_maxsize = $(this).attr('maxlength');
        if (thisinput_size === 0) {
            thisform.find(":submit").prop('disabled', true);
        }
        if (thisinput_size >= thisinput_maxsize) {
            thisform.find("[id^=error-alert] .alert-danger").show();
            thisform.find("[id^=error-alert-text]").text("Reached maximum input size. Please use file upload instead.");
            thisform.find("textarea").val('');
            thisform.find(":submit").prop('disabled', true);
        } else {
            thisform.find("[id^=error-alert] .alert-danger").hide();
        }
    });
};

function bind_to_input_file() {
    inputs.find("input:file").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("textarea").val('');
        thisform.find("input:text").val('');
        thisform.find("input[type=hidden][name*=commit]").val("Save");
        thisform.submit();
    });
};

function bind_to_input_text() {
    inputs.find("input:text").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("textarea").val('');
        thisform.find("input:file").val('');
        thisform.find(":submit").prop('disabled', false);
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
        thisform.find("input:text").val('');
        thisform.find("textarea").val('');
        thisform.find(":submit").prop('disabled', true);
        thisform.find("input[type=hidden][name*=commit]").val("Reset");
        thisform.submit();
    });
}

function bind_to_select_list() {
    inputs.find("#records_line").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("input[type=hidden][name*=commit]").val("Line");
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

function bind_to_checkbox_change() {
    params.filter("#enhanced_gene_keep_first_intron").on('click', function() {
        toggle_stats_depending_on_intron_checkbox();
    });
}

function init_params_partial() {
    params.filter(":input[type=checkbox]").removeAttr('checked');
    params.filter(":input").prop("disabled", true);

    params.filter("#enhanced_gene_keep_first_intron").prop('checked', true);
    params.filter("#enhanced_gene_strategy_humanize").prop('checked', true);
};

function enable_params_partial() {
    params.filter(":input").prop("disabled", false);
};

function toggle_stats_depending_on_intron_checkbox() {
    if (params.filter("#enhanced_gene_keep_first_intron").prop('checked')) {
        $("#stats-with-first-intron").show();
        $("#stats-without-first-intron").hide();
    } else {
        $("#stats-with-first-intron").hide();
        $("#stats-without-first-intron").show();
    }
};

function bind_validate_to_input() {
    // 'input:text' being '[name="ensembl[gene_id]"]'
    var ensembl_maxsize = inputs.find("input:text").attr('maxlength');
    var ensembl_validation = inputs.find("input:text").data('valid') || '^ENSG\d+(?:\.\d+)?$';

    inputs.each(function() {
        $(this).validate({
            ignore: [], // don't ignore hidden fields, i.e. in collapsed accordion panels
            rules: {
                "ensembl[gene_id]": {
                    regex: ensembl_validation,
                    maxlength: ensembl_maxsize // just in case ... maxlength is already defined (and ensured) in input-field
                }
            },
            messages: {
                "ensembl[gene_id]": {
                    regex: "Please enter a valid Ensemble gene ID."
                }
            }
        });
    });
};

function bind_autocomplete_to_input() {
    var engine = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
            url: '/enhancers/ensembl_autocomplete?query=%QUERY',
            wildcard: '%QUERY',
            transform: function(d){
                engine.add(d);
            }
        }
    });

    var promise = engine.initialize();

    // promise
    // .done(function() { console.log('success!'); })
    // .fail(function() { console.log('err!'); });

    inputs.find("input:text").typeahead({
        source: engine.ttAdapter()
    });
};