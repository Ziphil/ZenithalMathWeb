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

function calcWideStretchLevel(element, kind) {
  let width = getWidth(element);
  let maxStretchLevel = Object.keys(DATA["wide"][kind]).map((s) => s.match(/^\d+$/)).reduce((s, t) => Math.max(s, t));
  let stretchLevel = 0;
  if (width <= 0.79) {
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
    if (DATA["wide"][kind]["bar"]) {
      stretchLevel = null;
    } else {
      stretchLevel = maxStretchLevel;
    }
  }
  return stretchLevel;
}

function modifyWide(element) {
  let baseWrapperElement = Array.from(element.children).find((s) => s.localName == "math-basewrap");
  let overElement = Array.from(element.children).find((s) => s.localName == "math-over");
  let contentElement = baseWrapperElement.children[0];
  let parentElements = [baseWrapperElement.children[1], overElement];
  let kind = calcWideKind(element);
  for (let position of [0, 1]) {
    let parentElement = parentElements[position];
    if (parentElement) {
      let stretchLevel = calcWideStretchLevel(contentElement, kind);
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
  symbolElement.textContent = DATA["wide"][kind][stretchLevel][position];
  parentElement.classList.add("s" + stretchLevel);
}

function appendWideStretch(contentElement, parentElement, kind, position) {
}