//


function calcParenKind(element) {
  let kind = "paren";
  for (let clazz of element.classList) {
    if (!clazz.match(/^md(\w*)$/)) {
      kind = clazz;
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

function calcParenBarHeight(element, topElement, bottomElement, middleElement) {
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

function calcParenStretchShift(element) {
  let shift = -getLowerHeight(element) + 0.25;
  return shift;
}

function modifyParen(element) {
  let contentElement = element.children[1];
  let parentElements = [element.children[0], element.children[2]];
  let kind = calcParenKind(element);
  let stretchLevel = calcParenStretchLevel(contentElement, kind);
  for (let position of [0, 1]) {
    let parentElement = parentElements[position];
    if (stretchLevel != null) {
      modifyParenStretch(contentElement, parentElement, kind, stretchLevel, position);
    } else {
      appendParenStretch(contentElement, parentElement, kind, position);
    }
  }
}

function modifyParenStretch(contentElement, parentElement, kind, stretchLevel, position) {
  let symbolElement = parentElement.children[0];
  let shift = calcParenShift(contentElement);
  symbolElement.textContent = DATA["paren"][kind][stretchLevel][position];
  parentElement.style.verticalAlign = "" + shift + "em";
  parentElement.classList.add("s" + stretchLevel);
}

function appendParenStretch(contentElement, parentElement, kind, position) {
  let stretchElement = document.createElement("math-vstretch");
  let hasTop = !!DATA["paren"][kind]["top"];
  let hasBottom = !!DATA["paren"][kind]["bot"];
  let hasMiddle = !!DATA["paren"][kind]["mid"];
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
  parentElement.classList.add("sinf");
  parentElement.removeChild(parentElement.children[0]);
  parentElement.appendChild(stretchElement);
  let barSize = (hasMiddle) ? 2 : 1;
  let barHeight = calcParenBarHeight(contentElement, topElement, bottomElement, middleElement);
  let stretchShift = calcParenStretchShift(contentElement);
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