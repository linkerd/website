document.addEventListener("DOMContentLoaded", function() {

  let isSticky = false;

  const mainMenu = document.getElementById("mainMenu");
  const expandMenuBtn = document.getElementById("expandMenuBtn");
  const navbar = document.getElementById("navbar");

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

  // Dropdowns

  const dropdowns = document.querySelectorAll(".dropdown");

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

  // Search

  const searchForm = document.getElementById("searchForm");
  const searchInput = document.getElementById("searchInput");
  const searchToggle = document.getElementById("searchToggle");
  const githubStars = document.getElementById("githubStars");

  searchToggle.addEventListener("click", function() {
    if (searchForm.style.display == "none") {
      searchForm.style.display = "block";
      githubStars.style.display = "none";
      searchToggle.innerHTML = '<i class="fas fa-times"></i>';
      searchInput.focus();
    } else {
      searchForm.style.display = "none";
      githubStars.style.display = "flex";
      searchToggle.innerHTML = '<i class="fas fa-search"></i>';
    }
  });

});
