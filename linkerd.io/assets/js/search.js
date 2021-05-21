function initSearchPage(dataUrl, tagFieldName) {
  var searchData;
  var tags = [];
  var selectedTags = [];
  var searchItemsVisible = 6;
  var lunrIndex;

  var featuredItems = document.getElementById("featuredItems");
  var resultsHeader = document.getElementById("resultsHeader");

  var searchInput = document.getElementById("searchInput");
  var searchResult = document.getElementById("searchResult");
  // var filterList = document.getElementById("filterList");
  // var resetFiltersButton = document.getElementById("resetFilters");

  var pagination = document.getElementById("pagination");

  var searchCancelationToken;

  fetch(dataUrl)
    .then(function (response) {
      return response.json();
    })
    .then(function (response) {
      searchData = response;

      lunrIndex = lunr(function () {
        this.ref("uri");
        this.field("title", {
          boost: 20
        });
        this.field(tagFieldName, {
          boost: 5
        });
        this.field("content");

        response.forEach(function (page) {
          this.add(page);
          if (page[tagFieldName]) {
            page[tagFieldName].forEach(function (tag) {
              if (tags.indexOf(tag) === -1) {
                tags.push(tag);
              }
            });
          }
        }, this);
      });
    })
    .then(initSearch)
    .catch(function (e) {
      console.log("Error occurred while lunr search init", e);
    });

  function search(query) {
    var lunrResult = lunrIndex.search(query);
    var results = lunrResult.map(function (result) {
      return searchData.filter(function (page) {
        return page.uri === result.ref;
      })[0];
    });

    if (selectedTags.length) {
      results = results.filter(function (page) {
        //fing all the matching tags
        var matchedTags = selectedTags.filter(function (tag) {
          return page[tagFieldName]
            ? page[tagFieldName].indexOf(tag) > -1
            : false;
        });
        return matchedTags.length === selectedTags.length;

        // find if any matching tag
        // var matchedTags = page.tags.filter(function(tag) {
        //   return selectedTags.indexOf(tag) > -1;
        // });
        // return matchedTags.length > 0;
      });
    }
    return results.sort(function (a, b) {
      // desc
      if (a.sortDate > b.sortDate) {
        return -1;
      }
      if (a.sortDate < b.sortDate) {
        return 1;
      }
      return 0;
    });
  }

  function initSearch() {
    // resetSearchItemsVisible();
    // refreshFilters();
    // refreshSearch(search(searchInput.value || "*"));

    searchInput.addEventListener("input", function (event) {
      var value = event.target.value;
      if (value.length) {
        featuredItems.style.display = "none";
        resultsHeader.innerText = "Search results";
      } else {
        featuredItems.style.display = "block";
        resultsHeader.innerText = "Recently Added";
      }
      resetSearchItemsVisible();
      refreshSearch(search(value || "*"));
    });

    // resetFiltersButton.addEventListener("click", function () {
    //   selectedTags = [];
    //    refreshFilters();
    //   refreshSearch(search(searchInput.value || "*"));
    // });
  }

  function resetSearchItemsVisible() {
    searchItemsVisible = 10;
  }

  function refreshSearch(results) {
    pagination.style.display = "none";
    if (searchCancelationToken) {
      clearTimeout(searchCancelationToken);
    } else {
      setResultElementLoader();
    }
    searchCancelationToken = setTimeout(() => {
      if (results.length <= searchItemsVisible) {
        pagination.style.display = "none";
      } else {
        pagination.style.display = "";
      }
      refreshSearchResult(results.slice(0, searchItemsVisible));
      searchCancelationToken = null;
    }, 400);
  }

  function refreshFilters() {
    filterList.innerHTML = "";
    var resultItems = tags.map(buildFilterItem);
    filterList.insertAdjacentHTML("beforeend", resultItems.join(""));
    var filterElements = document.getElementsByClassName("filterElement");
    Array.prototype.filter.call(filterElements, function (el) {
      el.addEventListener("click", function () {
        var tag = el.innerText;
        var elIndex = selectedTags.indexOf(tag);
        if (elIndex === -1) {
          selectedTags.push(tag);
        } else {
          selectedTags.splice(elIndex, 1);
        }
        el.classList.toggle("is-active");

        refreshSearch(search(searchInput.value || "*"));
      });
    });
  }

  function refreshSearchResult(results) {
    searchResult.innerHTML = "";
    if (results.length) {
      var resultItems = results.map(buildResultElement);
      searchResult.insertAdjacentHTML("beforeend", resultItems.join(""));
    } else {
      searchResult.insertAdjacentHTML(
        "beforeend",
        '<div class="container has-text-weight-semibold has-text-centered">We couldn\'t find a match for "' +
        searchInput.value +
        '". Please try another search.</div>'
      );
    }
  }

  function setResultElementLoader() {
    searchResult.innerHTML = '<div class="search-loader" />';
  }

  function buildResultElement(item) {
    return (
      '<div class="column is-half">' +
      '<a class="has-text-color" href="' + item.uri + '">' +
      '<div class="box related-card-box">' +
      '<article class="related-card media">' +
      '<div class="media-left">' +
      '<figure class="image is-128x128 level-item">' +
      '<img src="' + (item.thumbnail ? item.thumbnail : '/images/identity/svg/linkerd_primary_color_white.svg') + '" alt="featured image" />' +
      '</figure>' +
      '</div>' +
      '<div class="media-content">' +
      '<div class="content">' +
      '<div class="level is-mobile related-card-header">' +
      '<div class="level-left">' +
      '<span class="level-item is-hidden-mobile">' + (item.type === "Blog" ? item.readingTime : item.type) + '</span>' +
      '</div>' +
      '<div class="level-right">' +
      '<span class="level-item">' + item.date + '</span>' +
      '</div>' +
      '</div>' +
      '<h3 class="title has-text-weight-semibold is-3 is-marginless">' + item.title + '</h3>' +
      '</div>' +
      '</div>' +
      '</article>' +
      '</div>' +
      '</a>' +
      '</div>'
    );
  }

  function buildFilterItem(tag) {
    var isSelected = selectedTags.indexOf(tag) > -1;
    return (
      '<li class="filterElement column is-vcentered is-one-quarter' +
      (isSelected ? "is-active" : "") +
      '">' +
      tag +
      "</li>"
    );
  }
}
