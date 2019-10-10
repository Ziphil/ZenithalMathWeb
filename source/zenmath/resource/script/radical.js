//


function calcRadicalStretchLevel(element) {
  let height = getHeight(element);
  let stretchLevel = 0;
  if (height <= 1.35) {
    stretchLevel = 0;
  } else if (height <= 1.35 + 0.5 * 1) {
    stretchLevel = 1;
  } else if (height <= 1.35 + 0.5 * 2) {
    stretchLevel = 2;
  } else {
    stretchLevel = 3;
  }
  return stretchLevel;
}

function modifyRadical(element) {
  let surdElement = element.children[0];
  let surdSymbolElement = surdElement.children[0];
  let contentElement = element.children[1];
  let stretchLevel = calcRadicalStretchLevel(element);
  surdElement.classList.add("s" + stretchLevel);
  surdSymbolElement.textContent = DATA["radical"][stretchLevel];
}