$(document).ready(function() {
    init_input_partial();
    init_preview_partial();
});

function init_input_partial() {
    var forms = $("form");
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