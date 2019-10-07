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
  let kind = "p";
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
  } else {
    stretchLevel = 12;
  }
  return stretchLevel;
}

function calcParenShift(element) {
  let shift = getHeight(element) / 2 - getBaselineCenter(element);
  if (shift >= -0.3 && shift <= 0.3) {
    shift = 0;
  }
  return shift;
}

function modifyParen(element) {
  let leftElement = element.previousElementSibling;
  let rightElement = element.nextElementSibling;
  let kind = calcParenKind(element);
  let stretchLevel = calcParenStretchLevel(element);
  let shift = calcParenShift(element);
  leftElement.textContent = DATA["paren"][kind][stretchLevel][0];
  rightElement.textContent = DATA["paren"][kind][stretchLevel][1];
  leftElement.style.verticalAlign = "" + shift + "em";
  rightElement.style.verticalAlign = "" + shift + "em";
}

function calcSuperscriptShift(baseElement, scriptElement) {
  let fontRatio = getFontSize(baseElement) / getFontSize(scriptElement);
  let shift = (getHeight(baseElement) - getBaselineCenter(baseElement) - 0.1) * fontRatio;
  return shift;
}

function calcSubscriptShift(baseElement, scriptElement) {
  let fontRatio = getFontSize(baseElement) / getFontSize(scriptElement);
  let shift = (-getBaselineCenter(baseElement) + 0.2) * fontRatio;
  return shift;
}

function modifySuperscript(element) {
  let baseElement = element.children[0];
  let scriptElement = element.children[1];
  let shift = calcSuperscriptShift(baseElement, scriptElement);
  scriptElement.style.verticalAlign = "" + shift + "em";
}

function modifySubscript(element) {
  let baseElement = element.children[0];
  let scriptElement = element.children[1];
  let shift = calcSubscriptShift(baseElement, scriptElement);
  scriptElement.style.verticalAlign = "" + shift + "em";
}


function modifySubsuperscript(element) {
  let baseElement = element.children[0];
  let subscriptElement = element.children[1];
  let superscriptElement = element.children[2];
  let lowerWidth = getWidth(subscriptElement);
  let upperWidth = getWidth(superscriptElement);
  let lowerShift = calcSubscriptShift(baseElement, subscriptElement);
  let upperShift = calcSuperscriptShift(baseElement, superscriptElement);
  let upperMargin = -getWidth(subscriptElement);
  let lowerMargin = 0;
  if (baseElement.children[0].classList.contains("int")) {
    lowerMargin -= 0.6;
    lowerWidth -= 0.6;
    upperMargin += 0.6;
  }
  subscriptElement.style.verticalAlign = "" + lowerShift + "em";
  superscriptElement.style.verticalAlign = "" + upperShift + "em";
  superscriptElement.style.marginLeft = "" + upperMargin + "em";
  subscriptElement.style.marginLeft = "" + lowerMargin + "em";
  if (lowerWidth > upperWidth) {
    superscriptElement.style.width = "" + lowerWidth + "em";
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

function getBaselineCenter(element) {
  let bottom = element.getBoundingClientRect().bottom;
  let baselineLocator = document.createElement("img");
  element.appendChild(baselineLocator);
  baselineLocator.style.verticalAlign = "baseline";
  let baseline = baselineLocator.getBoundingClientRect().bottom;
  element.removeChild(baselineLocator);
  let baselineHeight = bottom - baseline;
  let baselineHeightEm = baselineHeight / getFontSize(element) + 0.3;
  return baselineHeightEm;
}

function renderDebug(element) {
  let clientRect = element.getBoundingClientRect()
  let baselineCenter = getBaselineCenter(element) * getFontSize(element);
  let line = document.createElement("div");
  let upperBox = document.createElement("div");
  let lowerBox = document.createElement("div");
  line.style.position = "absolute";
  line.style.borderTop = "1px #FF000088 solid";
  line.style.width = "" + clientRect.width + "px";
  line.style.height = "1px";
  line.style.top = "" + (clientRect.bottom - baselineCenter) + "px";
  line.style.left = "" + clientRect.left + "px";
  upperBox.style.position = "absolute";
  upperBox.style.backgroundColor = "#FF000033";
  upperBox.style.width = "" + clientRect.width + "px";
  upperBox.style.height = "" + (clientRect.height - baselineCenter) + "px";
  upperBox.style.top = "" + clientRect.top + "px";
  upperBox.style.left = "" + clientRect.left + "px";
  lowerBox.style.position = "absolute";
  lowerBox.style.backgroundColor = "#FFFF0033";
  lowerBox.style.width = "" + clientRect.width + "px";
  lowerBox.style.height = "" + baselineCenter + "px";
  lowerBox.style.top = "" + (clientRect.top + clientRect.height - baselineCenter) + "px";
  lowerBox.style.left = "" + clientRect.left + "px";
  document.body.appendChild(line);
  document.body.appendChild(upperBox);
  document.body.appendChild(lowerBox);
}

function execute() {
  document.querySelectorAll("math-sup").forEach(modifySuperscript);
  document.querySelectorAll("math-sub").forEach(modifySubscript);
  document.querySelectorAll("math-subsup").forEach(modifySubsuperscript);
  document.querySelectorAll(".md-sqrt").forEach(modifyRadical);
  document.querySelectorAll(".md-paren").forEach(modifyParen);
}

window.onload = execute;