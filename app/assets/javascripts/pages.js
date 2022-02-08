// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready(function() {
    copy_buttons = $(":button","[id^=sample]");
    copy_buttons.on("click", function() {
        var text = document.getElementById($(this).attr("data-sample")).innerText;
        navigator.clipboard.writeText(text);
        $(this).attr("data-original-title", "Copied!").tooltip("show");
    });
});
