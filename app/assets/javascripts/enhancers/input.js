$(document).ready(function() {
    inputs = $("[id^=input-tab]>form");
    params = $("#new_enhanced_gene .params-form");

    clear_forms();
    hide_alerts();
    set_defaults_params_partial();
    disable_form_elements();

    bind_eventhandlers_to_input_elements();
    bind_validate_to_input();
    bind_autocomplete_to_input();
    bind_eventhandlers_to_params_elements();
});

$(document).on('page:load', function() {
    clear_forms();
    hide_alerts();
    set_defaults_params_partial();
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
    $("[id^=unsaved-data]").hide();
};

function disable_form_elements() {
    inputs.find(":submit").prop('disabled', true);
    disable_params_partial();
};

function bind_eventhandlers_to_input_elements() {
    bind_to_accordion();
    bind_to_input_textarea();
    bind_to_input_file();
    bind_to_input_text();
    bind_to_select();
    bind_to_save_button();
    bind_to_reset_button();
    bind_to_submit();
    // NOTE: do not bind to_select_list here, since the element will be created later
};

function bind_eventhandlers_to_params_elements() {
    bind_to_show_more_button();
    bind_to_select_by_radios();
};

function bind_to_accordion() {
    inputs.find(".panel-collapse").on('hide.bs.collapse', function() {
        // display as collapsed panel
        var thispanelhead = $(this).prev();
        thispanelhead.find(".glyphicon").removeClass("glyphicon-collapse-up").addClass("glyphicon-collapse-down");
        thispanelhead.find("[title]").attr('data-original-title', "Click to expand").tooltip("hide");
    });
    inputs.find(".panel-collapse").on('show.bs.collapse', function() {
        // display as expanded panel
        var thispanelhead = $(this).prev();
        thispanelhead.find(".glyphicon").removeClass("glyphicon-collapse-down").addClass("glyphicon-collapse-up");
        thispanelhead.find("[title]").attr('data-original-title', "Click to collapse").tooltip("hide");
    });
};

function bind_to_input_textarea() {
    inputs.find("textarea").on('input', function() {
        var thisform = $(this).closest("form");
        thisform.find("input:file").val('');
        thisform.find("input:text").val('');

        var thisinput_size = $(this).val().length;
        var thisinput_maxsize = $(this).attr('maxlength');
        if (thisinput_size === 0) {
            thisform.find(":submit").prop('disabled', true);
        } else {
            thisform.find("[id^=error-alert]").hide();
        }
        if (thisinput_size >= thisinput_maxsize) {
            thisform.find("[id^=error-alert]").show();
            thisform.find("[id^=error-alert-text]").text("Reached maximum input size. Please use file upload instead.");
            thisform.find("textarea").val('');
            thisform.find(":submit").prop('disabled', true);
        }
        common_to_all_inputs(thisform);
    });
};

function bind_to_input_file() {
    inputs.find("input:file").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("textarea").val('');
        thisform.find("input:text").val('');
        common_to_all_inputs(thisform);
        thisform.submit();
    });
};

function bind_to_input_text() {
    inputs.find("input:text").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("textarea").val('');
        thisform.find("input:file").val('');
        common_to_all_inputs(thisform);
        thisform.submit();
    });
};

function bind_to_select() {
    inputs.find("select").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("textarea").val('');
        thisform.find("input:file").val('');
        common_to_all_inputs(thisform);
        thisform.submit();
    });
};

function common_to_all_inputs(thisform) {
    if (thisform.valid()) {
        thisform.find(":submit[value=Save]").removeClass("btn-outline");
        thisform.find("[id^=unsaved-data]").show();
        $("#unsaved-data").show();
    } else {
        thisform.find(":submit[value=Save]").addClass("btn-outline");
        thisform.find("[id^=unsaved-data]").hide();
        $("#unsaved-data").hide();
    }

    thisform.find(":submit[value=Reset]").prop('disabled', false);
    thisform.find(":submit[value=Save]").prop('disabled', ! thisform.valid()).text("Save");
    thisform.find("[id^=success-alert]").hide();
    thisform.find("[id^=multigene-options]").empty();
    thisform.find("input[type=hidden][name*=commit]").val("Save");
};

function bind_to_submit() {
    inputs.closest("form").on('submit', function() {
        $(this).find("[id^=unsaved-data]").hide();
        $("#unsaved-data").hide();
        $(this).closest("form").find(":submit").addClass("btn-outline");
        return true;
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

function bind_to_selecting_lines_list() {
    inputs.find("#records_line").on('change', function() {
        var thisform = $(this).closest("form");
        thisform.find("input[type=hidden][name*=commit]").val("Line");
        thisform.submit();
    });
};

function set_defaults_params_partial() {
    params.filter(":input[type=checkbox]").removeAttr('checked');
    params.filter("#enhanced_gene_keep_first_intron").prop('checked', true);
    params.filter(":input[value='humanize']").prop('checked', true);
};

function disable_params_partial() {
    params.filter(":input").prop("disabled", true);
    $(".params-inactive").show();
};


function enable_params_partial(enable_all_checkboxes = true) {
    params.filter(":input").prop("disabled", false);
    if (! enable_all_checkboxes) {
        params.filter(":input[value='humanize']").prop('checked', true);
        params.filter(":input[value='raw']").prop("disabled", true);
        $(".params-strategy-inactive").show();
    }
    $(".params-inactive").hide();
};

function bind_to_select_by_radios() {
    params.find("#records_line").on('change', function() {
    });
    params.filter(":input[name='enhanced_gene[strategy]']").on('change', function() {
        var checked = params.filter(":input[name='enhanced_gene[strategy]']:checked").val();
        if (checked == "max_gc") {
            params.filter(":input[name='enhanced_gene[select_by]']").prop('disabled', true);
            params.filter("#enhanced_gene_select_by_high").prop("disabled", false).prop("checked", true);
        } else {
            params.filter(":input[name='enhanced_gene[select_by]']").prop('disabled', false);
            params.filter("#enhanced_gene_select_by_mean").prop("checked", true);
        }
    });
};

function bind_to_show_more_button() {
    params.filter("button").on('click', function() {
        if ($(this).text() == $(this).data('text')) {
            $(this).text($(this).data('alt-text'));
        } else {
            $(this).text($(this).data('text'));
        }
    });
};

function bind_validate_to_input() {
    var enhancer_maxsize = inputs.find("textarea").attr('maxlength');
    var enhancer_validation = inputs.find("textarea").data('valid');
    var enhancer_extension = inputs.find("input:file").attr('accept') || 'gi,fas,fa,fasta';

    // 'input:text' being '[name="ensembl[gene_id]"]'
    var ensembl_maxsize = inputs.find("input:text").attr('maxlength');
    var ensembl_validation = inputs.find("input:text").data('valid') || '^ENST\d+(?:\.\d+)?$';

    var ese_validation = inputs.find("textarea[name='ese[data]']").data('valid');
    var ese_maxsize = inputs.find("textarea[name='ese[data]']").attr('maxlength');
    var ese_extension = inputs.find("input[name='ese[file]']").attr('accept') || 'txt';

    inputs.each(function() {
        $(this).validate({
            ignore: [], // don't ignore hidden fields, i.e. in collapsed accordion panels
            // NOTE
            // maxlenght and accepted extensions are already enforced by HTML5 input field attributes. the rules here provide a mere fallback.
            rules: {
                "ensembl[gene_id]": {
                    regex: ensembl_validation,
                    maxlength: ensembl_maxsize
                },
                "enhancer[data]": {
                    regex: enhancer_validation,
                    maxlength: enhancer_maxsize
                },
                "enhancer[file]": {
                    laxAccept: enhancer_extension
                },
                "ese[data]": {
                    regex: ese_validation,
                    maxlength: ese_maxsize
                },
                "ese[file]": {
                    laxAccept: ese_extension
                }
            },
            messages: {
                "ensembl[gene_id]": {
                    regex: "Please enter a valid Ensembl transcript ID."
                },
                "enhancer[data]": {
                    regex: "Please enter a valid FASTA or Genebank."
                },
                "enhancer[file]": {
                    laxAccept: "Please enter a plain text file with a valid FASTA or Genebank extension."
                },
                "ese[data]": {
                    regex: "Please enter a valid ESE motif."
                },
                "ese[file]": {
                    laxAccept: "Please enter a plain text file with a '.txt' extension."
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
        source: engine.ttAdapter(),
        showHintOnFocus: true,
        autoSelect: true
    });
};