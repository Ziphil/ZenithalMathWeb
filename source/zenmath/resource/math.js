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
  let surdElement = element.previousElementSibling;
  let surdSymbolElement = surdElement.children[0];
  let stretchLevel = calcRadicalStretchLevel(element);
  surdElement.classList.add("s" + stretchLevel);
  surdSymbolElement.textContent = DATA["radical"][stretchLevel];
}

function calcParenKind(element) {
  let kind = "paren";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/md-paren-(\w+)/)) {
      kind = match[1];
    }
  }
  return kind;
}

function calcParenStretchLevel(element) {
  let height = getHeight(element);
  let stretchLevel = 0;
  if (height <= 1) {
    stretchLevel = 0;
  } else if (height <= 1 + 0.27 * 1) {
    stretchLevel = 1;
  } else if (height <= 1 + 0.27 * 2) {
    stretchLevel = 2;
  } else if (height <= 1 + 0.27 * 3) {
    stretchLevel = 3;
  } else if (height <= 1 + 0.27 * 4) {
    stretchLevel = 4;
  } else if (height <= 1 + 0.27 * 5) {
    stretchLevel = 5;
  } else if (height <= 1 + 0.27 * 6) {
    stretchLevel = 6;
  } else if (height <= 1 + 0.27 * 7) {
    stretchLevel = 7;
  } else if (height <= 1 + 0.27 * 8) {
    stretchLevel = 8;
  } else if (height <= 1 + 0.27 * 9) {
    stretchLevel = 9;
  } else if (height <= 1 + 0.27 * 10) {
    stretchLevel = 10;
  } else if (height <= 1 + 0.27 * 11) {
    stretchLevel = 11;
  } else if (height <= 1 + 0.27 * 12) {
    stretchLevel = 12;
  } else {
    stretchLevel = null;
  }
  return stretchLevel;
}

function calcParenShift(element) {
  let shift = getHeight(element) / 2 - getLowerHeight(element);
  if (shift >= -0.3 && shift <= 0.3) {
    shift = 0;
  }
  return shift;
}

function calcBarHeight(element, topElement, bottomElement, middleElement) {
  let height = 0;
  if (topElement && bottomElement) {
    if (middleElement) {
      height = (getHeight(element) - getHeight(topElement) - getHeight(bottomElement) - getHeight(middleElement)) / 2;
    } else {
      height = getHeight(element) - getHeight(topElement) - getHeight(bottomElement);
    }
  } else {
    height = getHeight(element);
  }
  return height;
}

function modifyParen(element) {
  let parentElements = [element.previousElementSibling, element.nextElementSibling];
  for (let position of [0, 1]) {
    modifyEachParen(element, parentElements[position], position);
  }
}

function modifyEachParen(contentElement, parentElement, position) {
  let kind = calcParenKind(contentElement);
  let stretchLevel = calcParenStretchLevel(contentElement);
  if (stretchLevel != null) {
    let symbolElement = parentElement.children[0];
    let shift = calcParenShift(contentElement);
    symbolElement.textContent = DATA["paren"][kind][stretchLevel][position];
    parentElement.style.verticalAlign = "" + shift + "em";
  } else {
    let hasEdge = true;
    let hasMiddle = !!DATA["paren"][kind]["mid"];
    appendParen(contentElement, parentElement, kind, position, hasEdge, hasMiddle);
  }
}

function appendParen(contentElement, parentElement, kind, position, hasEdge, hasMiddle) {
  let stretchElement = document.createElement("math-vstretch");
  let topElement = null;
  let bottomElement = null;
  let middleElement = null;
  if (hasEdge) {
    topElement = document.createElement("math-top");
    bottomElement = document.createElement("math-bot");
    topElement.textContent = DATA["paren"][kind]["top"][position];
    bottomElement.textContent = DATA["paren"][kind]["bot"][position];
    stretchElement.append(topElement, bottomElement);
    if (hasMiddle) {
      middleElement = document.createElement("math-mid");
      middleElement.textContent = DATA["paren"][kind]["mid"][position];
      stretchElement.insertBefore(middleElement, stretchElement.children[1]);
    }
  }
  parentElement.removeChild(parentElement.children[0]);
  parentElement.appendChild(stretchElement);
  let barSize = (hasMiddle) ? 2 : 1;
  let barHeight = calcBarHeight(contentElement, topElement, bottomElement, middleElement);
  let stretchShift = -getLowerHeight(contentElement) + 0.25;
  for (let i = 0 ; i < barSize ; i ++) { 
    let barElement = document.createElement("math-bar");
    let barContentElement = document.createElement("math-barcont");
    barContentElement.textContent = DATA["paren"][kind]["bar"][position];
    barElement.style.height = "" + barHeight + "em";
    barElement.append(barContentElement);
    stretchElement.insertBefore(barElement, stretchElement.children[2 * i + 1]);
  }
  stretchElement.style.verticalAlign = "" + stretchShift + "em";
}

function calcSubShift(baseElement, subElement) {
  let fontRatio = getFontSize(baseElement) / getFontSize(subElement);
  let shift = (getLowerHeight(baseElement) - 0.2) * fontRatio;
  return -shift;
}

function calcSuperShift(baseElement, superElement) {
  let fontRatio = getFontSize(baseElement) / getFontSize(superElement);
  let shift = (getUpperHeight(baseElement) - 0.1) * fontRatio;
  return shift;
}

function modifySubsuper(element) {
  let baseElement = element.children[0];
  let baseSymbolElement = baseElement.children[0];
  let subElement = element.children[1];
  let superElement = element.children[2];
  let lowerWidth = getWidth(subElement);
  let upperWidth = getWidth(superElement);
  let lowerShift = calcSubShift(baseElement, subElement);
  let upperShift = calcSuperShift(baseElement, superElement);
  let upperMargin = -getWidth(subElement);
  let lowerMargin = 0;
  if (baseSymbolElement.classList.contains("int")) {
    lowerMargin -= 0.6;
    lowerWidth -= 0.6;
    upperMargin += 0.6;
  }
  subElement.style.verticalAlign = "" + lowerShift + "em";
  superElement.style.verticalAlign = "" + upperShift + "em";
  superElement.style.marginLeft = "" + upperMargin + "em";
  subElement.style.marginLeft = "" + lowerMargin + "em";
  if (lowerWidth > upperWidth) {
    superElement.style.width = "" + lowerWidth + "em";
  }
  if (subElement.children.length > 0) {
    element.classList.add("sub");
  } else {
    element.removeChild(subElement);
  }
  if (superElement.children.length > 0) {
    element.classList.add("sup");
  } else {
    element.removeChild(superElement);
  }
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

function getLowerHeight(element) {
  let bottom = element.getBoundingClientRect().bottom + window.pageYOffset;
  let locator = document.createElement("img");
  element.appendChild(locator);
  locator.style.verticalAlign = "baseline";
  let baselineBottom = locator.getBoundingClientRect().bottom + window.pageYOffset;
  element.removeChild(locator);
  let heightPx = bottom - baselineBottom;
  let height = heightPx / getFontSize(element) + 0.3;
  return height;
}

function getUpperHeight(element) {
  let height = getHeight(element) - getLowerHeight(element);
  return height;
}

function renderDebug(element) {
  let clientRect = element.getBoundingClientRect();
  let scrollOffset = window.pageYOffset;
  let lowerHeight = getLowerHeight(element) * getFontSize(element);
  let upperHeight = getUpperHeight(element) * getFontSize(element);
  let line = document.createElement("div");
  let upperBox = document.createElement("div");
  let lowerBox = document.createElement("div");
  line.style.position = "absolute";
  line.style.borderTop = "1px #FF000088 solid";
  line.style.width = "" + clientRect.width + "px";
  line.style.height = "1px";
  line.style.top = "" + (clientRect.bottom - lowerHeight + scrollOffset) + "px";
  line.style.left = "" + clientRect.left + "px";
  lowerBox.style.position = "absolute";
  lowerBox.style.backgroundColor = "#FFFF0033";
  lowerBox.style.width = "" + clientRect.width + "px";
  lowerBox.style.height = "" + lowerHeight + "px";
  lowerBox.style.top = "" + (clientRect.top + upperHeight + scrollOffset) + "px";
  lowerBox.style.left = "" + clientRect.left + "px";
  upperBox.style.position = "absolute";
  upperBox.style.backgroundColor = "#FF000033";
  upperBox.style.width = "" + clientRect.width + "px";
  upperBox.style.height = "" + upperHeight + "px";
  upperBox.style.top = "" + (clientRect.top + scrollOffset) + "px";
  upperBox.style.left = "" + clientRect.left + "px";
  document.body.appendChild(line);
  document.body.appendChild(lowerBox);
  document.body.appendChild(upperBox);
}

function execute() {
  document.querySelectorAll("math-subsup").forEach(modifySubsuper);
  document.querySelectorAll(".md-sqrt").forEach(modifyRadical);
  document.querySelectorAll(".md-paren").forEach(modifyParen);
}

window.onload = execute;