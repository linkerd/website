document.addEventListener("DOMContentLoaded", function() {

  var isSticky = false;

  var mainMenu = document.getElementById("mainMenu");
  var expandMenuBtn = document.getElementById("expandMenuBtn");
  var navbar = document.getElementById("navbar");
  const dropdowns = document.querySelectorAll(".dropdown");

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

  dropdowns.forEach(el => {
    el.addEventListener("click", toggleDropdown);
  })

  window.addEventListener("click", closeDropdowns);
  
  function toggleDropdown(event) {
    event.stopPropagation();
    this.classList.toggle("is-active");
  }


  function closeDropdowns() {
    dropdowns.forEach(el => {
      if(el.classList.contains("is-active")) {
        el.classList.remove("is-active");
      }
    })
  }

});
