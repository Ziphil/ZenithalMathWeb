//


function stretchRadical(element) {
  let height = getHeight(element) + 0.15;
  let stretchLevel = 0;
  if (height <= 1.5) {
    stretchLevel = 0;
  } else if (height <= 1.5 + 0.5 * 1) {
    stretchLevel = 1;
  } else if (height <= 1.5 + 0.5 * 2) {
    stretchLevel = 2;
  } else {
    stretchLevel = 3;
  }
  let surdElement = element.previousElementSibling;
  let surdSymbolElement = surdElement.children[0];
  surdElement.classList.add("s" + stretchLevel);
  surdSymbolElement.textContent = DATA["radical"][stretchLevel];
}

function stretchParen(element) {
  let height = getHeight(element);
  let kind = "p";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/st-paren-(\w+)/)) {
      kind = match[1];
    }
  }
  let stretchLevel = 0;
  if (height <= 1) {
    stretchLevel = 0;
  } else if (height <= 1 + 0.25 * 1) {
    stretchLevel = 1;
  } else if (height <= 1 + 0.25 * 2) {
    stretchLevel = 2;
  } else if (height <= 1 + 0.25 * 3) {
    stretchLevel = 3;
  } else if (height <= 1 + 0.25 * 4) {
    stretchLevel = 4;
  } else if (height <= 1 + 0.25 * 5) {
    stretchLevel = 5;
  } else if (height <= 1 + 0.25 * 6) {
    stretchLevel = 6;
  } else if (height <= 1 + 0.25 * 7) {
    stretchLevel = 7;
  } else if (height <= 1 + 0.25 * 8) {
    stretchLevel = 8;
  } else if (height <= 1 + 0.25 * 9) {
    stretchLevel = 9;
  } else if (height <= 1 + 0.25 * 10) {
    stretchLevel = 10;
  } else if (height <= 1 + 0.25 * 11) {
    stretchLevel = 11;
  } else {
    stretchLevel = 12;
  }
  let shift = getHeight(element) / 2 - getBaselineHeight(element) - 0.25;
  if (shift >= -0.3 && shift <= 0.3) {
    shift = 0;
  }
  let leftElement = element.previousElementSibling;
  let rightElement = element.nextElementSibling;
  leftElement.textContent = DATA["paren"][kind][stretchLevel][0];
  rightElement.textContent = DATA["paren"][kind][stretchLevel][1];
  leftElement.style.verticalAlign = "" + shift + "em";
  rightElement.style.verticalAlign = "" + shift + "em";
}

function getFontSize(element) {
  let fontSizeString = window.getComputedStyle(element).fontSize;
  let fontSize = parseFloat(fontSizeString);
  return fontSize;
}

function getWidth(element) {
  let width = element.getBoundingClientRect().width;
  let widthEm = width / getFontSize(element);
  return widthEm;
}

function getHeight(element) {
  let height = element.getBoundingClientRect().height;
  let heightEm = height / getFontSize(element);
  return heightEm;
}

function getBaselineHeight(element){
  let bottom = element.getBoundingClientRect().bottom;
  let baselineLocator = document.createElement("img");
  element.appendChild(baselineLocator);
  baselineLocator.style.verticalAlign = "baseline";
  let baseline = baselineLocator.getBoundingClientRect().bottom;
  element.removeChild(baselineLocator);
  let baselineHeight = bottom - baseline;
  let baselineHeightEm = baselineHeight / getFontSize(element)
  return baselineHeightEm;
}

function execute() {
  document.querySelectorAll(".st-sqrt").forEach(stretchRadical);
  document.querySelectorAll(".st-paren").forEach(stretchParen);
}

window.onload = execute;