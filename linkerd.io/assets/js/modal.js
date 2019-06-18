function showImageModal(url) {
  var modal = document.getElementById('galleryModal')
  var image = document.getElementById('galleryModalImage')

  image.src = url
  modal.classList.toggle('is-active')
}

function hideImageModal() {
  var modal = document.getElementById('galleryModal')
  modal.classList.toggle('is-active')
}
