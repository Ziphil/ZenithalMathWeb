//


function execute() {
  document.querySelectorAll("math-subsup").forEach(modifySubsuper);
  document.querySelectorAll("math-underover").forEach(modifyUnderover);
  document.querySelectorAll("math-sqrt.mod").forEach(modifyRadical);
  document.querySelectorAll("math-paren.mod").forEach(modifyParen);
  document.querySelectorAll("math-underover.wide.mod").forEach(modifyWide);
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