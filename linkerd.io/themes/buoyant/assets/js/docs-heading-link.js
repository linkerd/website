const docsHeadings = document.querySelectorAll(".docs h1, .docs h2, .docs h3, .docs h4, .docs h5");
docsHeadings.length > 0 ? addListenersToDocsHeadings(docsHeadings) : "";

function addListenersToDocsHeadings(headings) {
    headings.forEach(heading => {
        heading.addEventListener('click', updateWindowLocation);
    })
}

function updateWindowLocation(event) {
    const currentURL = window.location.href.split("#")[0];
    const newPath = this.id
    window.location.href = `${currentURL}#${newPath}`;
}
