// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on("turbolinks:load", function() {
    $('[data-toggle="tooltip"]').tooltip();
});

// adapt jquery-validate for bootstrap
$.validator.setDefaults({
    errorElement: "span",
    errorClass: "help-block",
    highlight: function (element, errorClass, validClass) {
        $(element).closest('.form-group-validation').addClass('has-error');
    },
    unhighlight: function (element, errorClass, validClass) {
        $(element).closest('.form-group-validation').removeClass('has-error');
    },
    errorPlacement: function (error, element) {
        if (element.parent('.input-group').length || element.prop('type') === 'checkbox' || element.prop('type') === 'radio') {
            error.insertAfter(element.parent());
        } else {
            error.insertAfter(element);
        }
    }
});

$.validator.addMethod(
    "regex",
    function(value, element, regexp) {
        var re = new RegExp(regexp);
        return this.optional(element) || re.test(value);
    },
    "Please enter only {0}."
);

// mimic the original accept method, which checks file mimetype and extension
$.validator.addMethod(
    "laxAccept",
    function(value, element, regexp) {
        regexp = "\\.(" + regexp.replace(/\./g, "").replace(/,/g, "|") + ")$";
        var re = new RegExp(regexp, "i");
        return this.optional(element) || re.test(value);
    },
    "Please enter a file with a valid extension."
);