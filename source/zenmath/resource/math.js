//


function modifyRadical(element) {
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

function modifyParen(element) {
  let height = getHeight(element);
  let kind = "p";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/md-paren-(\w+)/)) {
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
  let shift = getHeight(element) / 2 - getBaselineCenter(element);
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

function modifySuperscript(element) {
  let baseElement = element.children[0];
  let scriptElement = element.children[1];
  let fontRatio = getFontSize(baseElement) / getFontSize(scriptElement);
  let shift = (getHeight(baseElement) - getBaselineCenter(baseElement)) * fontRatio;
  scriptElement.style.verticalAlign = "" + shift + "em";
}

function modifySubscript(element) {
  let baseElement = element.children[0];
  let scriptElement = element.children[1];
  let fontRatio = getFontSize(baseElement) / getFontSize(scriptElement);
  let shift = -getBaselineCenter(baseElement) * fontRatio;
  scriptElement.style.verticalAlign = "" + shift + "em";
}

function modifySubsuperscript(element) {
  let baseElement = element.children[0];
  let subscriptElement = element.children[1];
  let superscriptElement = element.children[2];
  let fontRatio = getFontSize(baseElement) / getFontSize(subscriptElement);
  let lowerShift = -getBaselineCenter(baseElement) * fontRatio;
  let upperShift = (getHeight(baseElement) - getBaselineCenter(baseElement)) * fontRatio;
  let upperMargin = -getWidth(subscriptElement);
  subscriptElement.style.verticalAlign = "" + lowerShift + "em";
  superscriptElement.style.verticalAlign = "" + upperShift + "em";
  superscriptElement.style.marginLeft = "" + upperMargin + "em";
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

function renderBaselineCenter(element) {
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