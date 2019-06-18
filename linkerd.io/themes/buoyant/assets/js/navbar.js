document.addEventListener("DOMContentLoaded", function() {

  var isSticky = false;

  var mainMenu = document.getElementById("mainMenu");
  var expandMenuBtn = document.getElementById("expandMenuBtn");
  var navbar = document.getElementById("navbar");

  window.addEventListener("scroll", function() {
    if (window.scrollY !== 0 && !isSticky) {
      window.requestAnimationFrame(function() {
        navbar.classList.toggle("has-shadow");
        isSticky = true;
      });
    }

    if (window.scrollY === 0 && isSticky) {
      window.requestAnimationFrame(function() {
        navbar.classList.toggle("has-shadow");
        isSticky = false;
      });
    }
  });


  expandMenuBtn.addEventListener("click", function() {
    mainMenu.classList.toggle("is-active");
  });
});
