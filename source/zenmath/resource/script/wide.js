//


function calcWideKind(element) {
  let kind = "widetilde";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/^wide-(\w*)$/)) {
      kind = match[1];
    }
  }
  return kind;
}

function calcWideMaxStretchLevel(kind, position) {
  let keys = Object.keys(DATA["wide"][kind][position]);
  let maxStretchLevel = -1;
  for (let key of keys) {
    if (key.match(/^\d+$/) && DATA["wide"][kind][position][key] && parseInt(key) > maxStretchLevel) {
      maxStretchLevel = parseInt(key);
    }
  }
  return maxStretchLevel;
}

function calcWideStretchLevel(element, kind, position) {
  let width = getWidth(element);
  let maxStretchLevel = calcWideMaxStretchLevel(kind, position);
  let stretchLevel = 0;
  if (width <= 0.79 && maxStretchLevel >= 0) {
    stretchLevel = 0;
  } else if (width <= 1.25 && maxStretchLevel >= 1) {
    stretchLevel = 1;
  } else if (width <= 1.71 && maxStretchLevel >= 2) {
    stretchLevel = 2;
  } else if (width <= 2.15 && maxStretchLevel >= 3) {
    stretchLevel = 3;
  } else if (width <= 2.61 && maxStretchLevel >= 4) {
    stretchLevel = 4;
  } else {
    if (DATA["wide"][kind][position]["bar"]) {
      stretchLevel = null;
    } else {
      stretchLevel = maxStretchLevel;
    }
  }
  return stretchLevel;
}

function calcWideBarWidth(element, beginElement, endElement, middleElement) {
  let wholeWidth = getWidth(element);
  let beginWidth = (beginElement) ? getWidth(beginElement) : 0;
  let endWidth = (endElement) ? getWidth(endElement) : 0;
  let middleWidth = (middleElement) ? getWidth(middleElement) : 0;
  let width = wholeWidth - beginWidth - endWidth - middleWidth;
  if (middleElement) {
    width = width / 2;
  }
  if (width < 0) {
    width = 0;
  }
  return width;
}

function modifyWide(element) {
  let baseWrapperElement = Array.from(element.children).find((element) => element.localName == "math-basewrap");
  let overElement = Array.from(element.children).find((element) => element.localName == "math-over");
  let contentElement = baseWrapperElement.children[0];
  let parentElements = [baseWrapperElement.children[1], overElement];
  let kind = calcWideKind(element);
  for (let position of [0, 1]) {
    let parentElement = parentElements[position];
    if (parentElement) {
      let stretchLevel = calcWideStretchLevel(contentElement, kind, position);
      if (stretchLevel != null) {
        modifyWideStretch(contentElement, parentElement, kind, stretchLevel, position);
      } else {
        appendWideStretch(contentElement, parentElement, kind, position);
      }
    }
  }
}

function modifyWideStretch(contentElement, parentElement, kind, stretchLevel, position) {
  let symbolElement = parentElement.children[0];
  symbolElement.textContent = DATA["wide"][kind][position][stretchLevel];
  parentElement.classList.add("s" + stretchLevel);
}

function appendWideStretch(contentElement, parentElement, kind, position) {
  let stretchElement = document.createElement("math-hstretch");
  let hasBegin = !!DATA["wide"][kind][position]["beg"];
  let hasEnd = !!DATA["wide"][kind][position]["end"];
  let hasMiddle = !!DATA["wide"][kind][position]["mid"];
  let beginElement = null;
  let endElement = null;
  let middleElement = null;
  if (hasBegin) {
    beginElement = document.createElement("math-beg");
    beginElement.textContent = DATA["wide"][kind][position]["beg"];
    stretchElement.append(beginElement);
  }
  if (hasMiddle) {
    middleElement = document.createElement("math-mid");
    middleElement.textContent = DATA["wide"][kind][position]["mid"];
    stretchElement.append(middleElement);
  }
  if (hasEnd) {
    endElement = document.createElement("math-end");
    endElement.textContent = DATA["wide"][kind][position]["end"];
    stretchElement.append(endElement);
  }
  parentElement.classList.add("sinf");
  parentElement.removeChild(parentElement.children[0]);
  parentElement.appendChild(stretchElement);
  let barSize = (hasMiddle) ? 2 : 1;
  let barWidth = calcWideBarWidth(contentElement, beginElement, endElement, middleElement);
  for (let i = 0 ; i < barSize ; i ++) { 
    let barElement = document.createElement("math-bar");
    let barContentElement = document.createElement("math-barcont");
    barContentElement.textContent = DATA["wide"][kind][position]["bar"];
    barElement.style.width = "" + barWidth + "em";
    barElement.append(barContentElement);
    if (i == 0) {
      stretchElement.insertBefore(barElement, stretchElement.children[(hasBegin) ? 1 : 0]);
    } else {
      stretchElement.insertBefore(barElement, stretchElement.children[(hasBegin) ? 3 : 2]);
    }
  }
}