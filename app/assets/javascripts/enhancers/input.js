$(document).ready(function() {
    init_input_partial();
    init_preview_partial();
});

function init_input_partial() {
    var forms = $("form");
    forms.find("[id^=text-alert]").hide();
    forms.find(":submit").prop('disabled', true);
};

function init_preview_partial() {

};