//


function calcParenKinds(element) {
  let left_kind = "paren";
  let right_kind = "paren";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/^left-(\w*)$/)) {
      left_kind = match[1];
    } else if (match = clazz.match(/^right-(\w*)$/)) {
      right_kind = match[1];
    }
  }
  return [left_kind, right_kind];
}

function calcParenMaxStretchLevel(kind, position) {
  let keys = Object.keys(DATA["paren"][kind][position]);
  let maxStretchLevel = 0;
  for (let key of keys) {
    if (key.match(/^\d+$/) && parseInt(key) > maxStretchLevel) {
      maxStretchLevel = parseInt(key);
    }
  }
  return maxStretchLevel;
}

function calcParenStretchLevel(element, kind, position) {
  let heightAbs = getHeight(element) * 1000;
  let maxStretchLevel = calcParenMaxStretchLevel(kind, position);
  let stretchLevel = null;
  for (let i = 0 ; i <= maxStretchLevel ; i ++) {
    if (heightAbs <= 1159 + 242 * i) {
      stretchLevel = i;
      break;
    }
  }
  if (stretchLevel == null && !DATA["paren"][kind][position]["bar"]) {
    stretchLevel = maxStretchLevel;
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
  if (height < 0) {
    height = 0;
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
  let kinds = calcParenKinds(element);
  for (let position of [0, 1]) {
    let parentElement = parentElements[position];
    let kind = kinds[position];
    if (kind != "none") {
      let stretchLevel = calcParenStretchLevel(contentElement, kind, position);
      if (stretchLevel != null) {
        modifyParenStretch(contentElement, parentElement, kind, stretchLevel, position);
      } else {
        appendParenStretch(contentElement, parentElement, kind, position);
      }
    }
  }
}

function modifyParenStretch(contentElement, parentElement, kind, stretchLevel, position) {
  let symbolElement = parentElement.children[0];
  let shift = calcParenShift(contentElement);
  symbolElement.textContent = DATA["paren"][kind][position][stretchLevel];
  parentElement.style.verticalAlign = "" + shift + "em";
  parentElement.classList.add("s" + stretchLevel);
}

function appendParenStretch(contentElement, parentElement, kind, position) {
  let stretchElement = document.createElement("math-vstretch");
  let hasTop = !!DATA["paren"][kind][position]["top"];
  let hasBottom = !!DATA["paren"][kind][position]["bot"];
  let hasMiddle = !!DATA["paren"][kind][position]["mid"];
  let topElement = null;
  let bottomElement = null;
  let middleElement = null;
  if (hasTop) {
    topElement = document.createElement("math-top");
    topElement.textContent = DATA["paren"][kind][position]["top"];
    stretchElement.append(topElement);
  }
  if (hasMiddle) {
    middleElement = document.createElement("math-mid");
    middleElement.textContent = DATA["paren"][kind][position]["mid"];
    stretchElement.append(middleElement);
  }
  if (hasBottom) {
    bottomElement = document.createElement("math-bot");
    bottomElement.textContent = DATA["paren"][kind][position]["bot"];
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
    barContentElement.textContent = DATA["paren"][kind][position]["bar"];
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