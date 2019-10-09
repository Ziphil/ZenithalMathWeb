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

function calcParenStretchLevel(element, kind) {
  let height = getHeight(element);
  let maxStretchLevel = Object.keys(DATA["paren"][kind]).map((s) => s.match(/^\d+$/)).reduce((s, t) => Math.max(s, t));
  let stretchLevel = 0;
  if (height <= 1) {
    stretchLevel = 0;
  } else if (height <= 1 + 0.27 * 1 && maxStretchLevel >= 1) {
    stretchLevel = 1;
  } else if (height <= 1 + 0.27 * 2 && maxStretchLevel >= 2) {
    stretchLevel = 2;
  } else if (height <= 1 + 0.27 * 3 && maxStretchLevel >= 3) {
    stretchLevel = 3;
  } else if (height <= 1 + 0.27 * 4 && maxStretchLevel >= 4) {
    stretchLevel = 4;
  } else if (height <= 1 + 0.27 * 5 && maxStretchLevel >= 5) {
    stretchLevel = 5;
  } else if (height <= 1 + 0.27 * 6 && maxStretchLevel >= 6) {
    stretchLevel = 6;
  } else if (height <= 1 + 0.27 * 7 && maxStretchLevel >= 7) {
    stretchLevel = 7;
  } else if (height <= 1 + 0.27 * 8 && maxStretchLevel >= 8) {
    stretchLevel = 8;
  } else if (height <= 1 + 0.27 * 9 && maxStretchLevel >= 9) {
    stretchLevel = 9;
  } else if (height <= 1 + 0.27 * 10 && maxStretchLevel >= 10) {
    stretchLevel = 10;
  } else if (height <= 1 + 0.27 * 11 && maxStretchLevel >= 11) {
    stretchLevel = 11;
  } else if (height <= 1 + 0.27 * 12 && maxStretchLevel >= 12) {
    stretchLevel = 12;
  } else {
    if (DATA["paren"][kind]["bar"]) {
      stretchLevel = null;
    } else {
      stretchLevel = maxStretchLevel;
    }
  }
  return stretchLevel;
}

function calcParenShift(element) {
  let shift = getHeight(element) / 2 - getLowerHeight(element);
  return shift;
}

function calcBarHeight(element, topElement, bottomElement, middleElement) {
  let wholeHeight = getHeight(element);
  let topHeight = (topElement) ? getHeight(topElement) : 0;
  let bottomHeight = (bottomElement) ? getHeight(bottomElement) : 0;
  let middleHeight = (middleElement) ? getHeight(middleElement) : 0;
  let height = wholeHeight - topHeight - bottomHeight - middleHeight;
  if (middleElement) {
    height = height / 2;
  }
  return height;
}

function calcStretchShift(element) {
  let shift = -getLowerHeight(element) + 0.25;
  return shift;
}

function modifyParen(element) {
  let contentElement = element.children[1];
  let parentElements = [element.children[0], element.children[2]];
  let kind = calcParenKind(element);
  for (let position of [0, 1]) {
    modifyEachParen(contentElement, parentElements[position], kind, position);
  }
}

function modifyEachParen(contentElement, parentElement, kind, position) {
  let stretchLevel = calcParenStretchLevel(contentElement, kind);
  if (stretchLevel != null) {
    let symbolElement = parentElement.children[0];
    let shift = calcParenShift(contentElement);
    symbolElement.textContent = DATA["paren"][kind][stretchLevel][position];
    parentElement.style.verticalAlign = "" + shift + "em";
  } else {
    let hasTop = !!DATA["paren"][kind]["top"]
    let hasBottom = !!DATA["paren"][kind]["bot"];
    let hasMiddle = !!DATA["paren"][kind]["mid"];
    appendParen(contentElement, parentElement, kind, position, hasTop, hasBottom, hasMiddle);
  }
}

function appendParen(contentElement, parentElement, kind, position, hasTop, hasBottom, hasMiddle) {
  let stretchElement = document.createElement("math-vstretch");
  let topElement = null;
  let bottomElement = null;
  let middleElement = null;
  if (hasTop) {
    topElement = document.createElement("math-top");
    topElement.textContent = DATA["paren"][kind]["top"][position];
    stretchElement.append(topElement);
  }
  if (hasMiddle) {
    middleElement = document.createElement("math-mid");
    middleElement.textContent = DATA["paren"][kind]["mid"][position];
    stretchElement.append(middleElement);
  }
  if (hasBottom) {
    bottomElement = document.createElement("math-bot");
    bottomElement.textContent = DATA["paren"][kind]["bot"][position];
    stretchElement.append(bottomElement);
  }
  parentElement.removeChild(parentElement.children[0]);
  parentElement.appendChild(stretchElement);
  let barSize = (hasMiddle) ? 2 : 1;
  let barHeight = calcBarHeight(contentElement, topElement, bottomElement, middleElement);
  let stretchShift = calcStretchShift(contentElement);
  for (let i = 0 ; i < barSize ; i ++) { 
    let barElement = document.createElement("math-bar");
    let barContentElement = document.createElement("math-barcont");
    barContentElement.textContent = DATA["paren"][kind]["bar"][position];
    barElement.style.height = "" + barHeight + "em";
    barElement.append(barContentElement);
    if (i == 0) {
      stretchElement.insertBefore(barElement, stretchElement.children[(hasTop) ? 1 : 0]);
    } else {
      stretchElement.insertBefore(barElement, stretchElement.children[(hasTop) ? 3 : 2]);
    }
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