//initialize metismenu
$("#metismenu").metisMenu();
//initialize slideout
var slideout = new Slideout({
    'panel': document.getElementById('panel'),
    'menu': document.getElementById('menu'),
    'padding': 300,
    'tolerance': 70
});
//for closing menu on page click
function close(eve) {
    eve.preventDefault();
    slideout.close();
}
//make the hamburger animation correct when using touch events
slideout
    .on('beforeopen', function() {
        this.panel.classList.add('panel-open');
        $(".hamburger").toggleClass("is-active");
        $(".header-hamburger").toggleClass("fixed-open");
    })
    .on('open', function() {
        this.panel.addEventListener('click', close);
    })
    .on('beforeclose', function() {
        this.panel.classList.remove('panel-open');
        this.panel.removeEventListener('click', close);
        $(".hamburger").removeClass("is-active");
        $(".header-hamburger").removeClass("fixed-open");
    });
// Toggle button
$('.toggle-button').on('click', function() {
    slideout.toggle();
});
