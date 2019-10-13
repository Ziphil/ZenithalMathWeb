//


function calcRadicalStretchLevel(element) {
  let heightAbs = getHeight(element) * 1000;
  let stretchLevel = null;
  for (let i = 0 ; i <= 3 ; i ++) {
    if (heightAbs <= DATA["radical"]["height"][i]) {
      stretchLevel = i;
      break;
    }
  }
  if (stretchLevel == null) {
    stretchLevel = 3;
  }
  return stretchLevel;
}

function modifyRadical(element) {
  let surdElement = element.children[0];
  let surdSymbolElement = surdElement.children[0];
  let contentElement = element.children[1];
  let stretchLevel = calcRadicalStretchLevel(element);
  surdSymbolElement.textContent = DATA["radical"][stretchLevel];
}