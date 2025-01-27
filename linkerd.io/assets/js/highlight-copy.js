// Add copy button to all codeblocks that have been highlighed by Hugo 
window.addEventListener(
  "DOMContentLoaded",
  function (event) {
    const iconClass = "icon icon--xs";
    const copyIcon = `<svg class="${iconClass}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M19,21H8V7H19M19,5H8A2,2 0 0,0 6,7V21A2,2 0 0,0 8,23H19A2,2 0 0,0 21,21V7A2,2 0 0,0 19,5M16,1H4A2,2 0 0,0 2,3V17H4V3H16V1Z" /></svg>`;
    const copiedIcon = `<svg class="${iconClass}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M21,7L9,19L3.5,13.5L4.91,12.09L9,16.17L19.59,5.59L21,7Z" /></svg>`;
    // Skip any highlighted codeblocks with .disable-copy
    const preList = document.querySelectorAll(".highlight:not(.disable-copy) > pre");
    if (preList) {
      for (let pre of preList) {
        const code = pre.querySelector("code");
        const btn = document.createElement("a");
        btn.setAttribute("href", "#");
        btn.classList.add("icon-button");
        btn.classList.add("icon-button--primary");
        btn.innerHTML = copyIcon;
        btn.addEventListener(
          "click",
          function (event) {
            event.preventDefault();
            navigator.clipboard.writeText(code.textContent.trim() + "\n");
            btn.innerHTML = copiedIcon;
            setTimeout(function () {
              btn.innerHTML = copyIcon;
            }, 3000);
          },
          false,
        );
        const div = document.createElement("div");
        div.classList.add("highlight__copy");
        div.append(btn);
        pre.insertBefore(div, code);
      }
    }
  },
  false,
);
