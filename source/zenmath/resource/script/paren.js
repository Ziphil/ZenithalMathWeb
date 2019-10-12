//


function calcParenKinds(element) {
  let leftKind = "paren";
  let rightKind = "paren";
  let centerKind = "paren";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/^left-(\w*)$/)) {
      leftKind = match[1];
    } else if (match = clazz.match(/^right-(\w*)$/)) {
      rightKind = match[1];
    } else if (match = clazz.match(/^center-(\w*)$/)) {
      centerKind = match[1]
    }
  }
  return [leftKind, rightKind, centerKind];
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

function calcParenWholeHeight(elements) {
  let upperHeights = [];
  let lowerHeights = [];
  for (let element of elements) {
    upperHeights.push(getUpperHeight(element));
    lowerHeights.push(getLowerHeight(element));
  }
  let maxUpperHeight = Math.max(...upperHeights);
  let maxLowerHeight = Math.max(...lowerHeights);
  return maxUpperHeight + maxLowerHeight;
}

function calcParenStretchLevel(elements, kind, position) {
  let heightAbs = calcParenWholeHeight(elements) * 1000;
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

function calcParenShift(elements) {
  let shift = calcParenWholeHeight(elements) / 2 - Math.max(...elements.map((element) => getLowerHeight(element)));
  return shift;
}

function calcParenBarHeight(elements, topElement, bottomElement, middleElement) {
  let wholeHeight = calcParenWholeHeight(elements);
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

function calcParenStretchShift(elements) {
  let shift = -Math.max(...elements.map((element) => getLowerHeight(element))) + 0.25;
  return shift;
}

function modifyParen(element) {
  let contentElements = Array.from(element.children).filter((element) => element.localName == "math-parencont");
  let leftElement = Array.from(element.children).find((element) => element.localName == "math-left");
  let rightElement = Array.from(element.children).find((element) => element.localName == "math-right");
  let centerElement = Array.from(element.children).find((element) => element.localName == "math-center");
  let parentElements = [leftElement, rightElement, centerElement];
  let kinds = calcParenKinds(element);
  for (let position of [0, 1, 2]) {
    let parentElement = parentElements[position];
    let kind = kinds[position];
    if (position == 2) {
      position = 0;
    }
    if (parentElement && kind != "none") {
      let stretchLevel = calcParenStretchLevel(contentElements, kind, position);
      if (stretchLevel != null) {
        modifyParenStretch(contentElements, parentElement, kind, stretchLevel, position);
      } else {
        appendParenStretch(contentElements, parentElement, kind, position);
      }
    }
  }
}

function modifyParenStretch(contentElements, parentElement, kind, stretchLevel, position) {
  let symbolElement = parentElement.children[0];
  let shift = calcParenShift(contentElements);
  symbolElement.textContent = DATA["paren"][kind][position][stretchLevel];
  parentElement.style.verticalAlign = "" + shift + "em";
  parentElement.classList.add("s" + stretchLevel);
}

function appendParenStretch(contentElements, parentElement, kind, position) {
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
  let barHeight = calcParenBarHeight(contentElements, topElement, bottomElement, middleElement);
  let stretchShift = calcParenStretchShift(contentElements);
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