window.addEventListener("DOMContentLoaded", function() {
  var goToPrevPageBtn = document.getElementById("goToPrevPage");
  goToPrevPageBtn.addEventListener("click", function() {
    window.history.back();
  });
});
