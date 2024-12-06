window.addEventListener(
  "DOMContentLoaded",
  function (event) {
    let index = null;
    let lookup = null;
    let query = null;
    const target = document.querySelector(".search-results");
    const init = () => {
      const url = new URL(window.location);
      const q = url.searchParams.get("q");
      if (q) {
        query = q;
        loadSearchIndex();
      } else {
        window.location = "/";
      }
    };
    const loadSearchIndex = () => {
      const request = new XMLHttpRequest();
      request.open("GET", "/search.json");
      request.responseType = "json";
      request.addEventListener(
        "load",
        function (event) {
          lookup = {};
          index = lunr(function () {
            this.ref("uri");
            this.field("title");
            this.field("content");
            this.field("description");
            this.field("keywords", {boost: 5});
            for (let doc of request.response) {
              if (doc.section == "blog") {
                // Always show blog last in the search results
                this.add(doc, {boost: -1});
              } else {
                this.add(doc);
              }
              lookup[doc.uri] = doc;
            }
          });
          renderSearchResults();
        },
        false,
      );
      request.addEventListener("error", renderError, false);
      request.send(null);
    };
    const renderSearchResults = () => {
      const results = index.search(query);
      // Remove loader
      target.innerHTML = "";
      // Render header
      let template = document.getElementById("search-results-header-template");
      let node = template.content.cloneNode(true);
      let txt = "";
      if (results.length == 0) {
        txt = "No results found for";
      } else if (results.length == 1) {
        txt = "Found one result for";
      } else {
        txt = `Found ${results.length} results for`;
      }
      node.querySelector(".search-results-header__text").textContent = txt;
      node.querySelector(".search-results-header__query").textContent = query;
      if (results.length > 0) {
        const empty = node.querySelector(".search-results-header__empty");
        empty.parentNode.removeChild(empty);
      }
      target.appendChild(node);
      // Render results
      template = document.getElementById("search-results-entry-template");
      for (let result of results) {
        let doc = lookup[result.ref];
        //console.log(`${doc.uri}: ${result.score}`);
        let node = template.content.cloneNode(true);
        if (Array.isArray(doc.ancestors)) {
          node.querySelector(".search-results-entry__section").textContent = doc.ancestors.join(" / ");
        }
        node.querySelector(".search-results-entry__link").href = doc.uri;
        node.querySelector(".search-results-entry__link").textContent = doc.title;
        node.querySelector(".search-results-entry__summary").textContent = truncateWords(doc.content, 30);
        target.appendChild(node);
      }
    };
    const renderError = () => {
      let template = document.getElementById("search-results-error-template");
      let node = template.content.cloneNode(true);
      target.appendChild(node);
    };
    const truncateWords = (text, words) => {
      let match;
      let result = "";
      let wordCount = 0;
      let regexp = /(\S+)(\s*)/g;
      while ((match = regexp.exec(text))) {
        wordCount++;
        if (wordCount <= words) {
          result += match[0];
        } else {
          if (text.length > result.length) {
            result += "...";
          }
          break;
        }
      }
      return result;
    };
    init();
  },
  false,
);
