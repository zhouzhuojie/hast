$.windowActive = false;

$.isWindowActive = function () {
    return $.windowActive;
};

$(window).focus(function() {
    $.windowActive = true;
});

$(window).blur(function() {
    $.windowActive = false;
});
