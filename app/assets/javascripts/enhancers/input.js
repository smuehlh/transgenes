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

    forms.find("textarea").on('input', function() {
        var thisform = $(this).closest("form");
        thisform.find(":submit").prop('disabled', false);
        thisform.find("[id^=multigene-options]").empty();
        thisform.find("input:file").val('');
    });

};

function init_preview_partial() {
    $("#input-view-alert").hide();
    $(".well").find(":button").prop('disabled', true);
};