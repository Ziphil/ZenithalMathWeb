//


function stretchParen(element) {
  let height = getHeight(element);
  let kind = "p";
  for (let clazz of element.classList) {
    let match;
    if (match = clazz.match(/st-paren-(\w+)/)) {
      kind = match[1];
    }
  }
  let stretchLevel = 0;
  if (height <= 1) {
    stretchLevel = 1;
  } else if (height <= 1 + 0.26 * 1) {
    stretchLevel = 2;
  } else if (height <= 1 + 0.26 * 2) {
    stretchLevel = 3;
  } else if (height <= 1 + 0.26 * 3) {
    stretchLevel = 4;
  } else if (height <= 1 + 0.26 * 4) {
    stretchLevel = 5;
  } else if (height <= 1 + 0.26 * 5) {
    stretchLevel = 6;
  } else if (height <= 1 + 0.26 * 6) {
    stretchLevel = 7;
  } else if (height <= 1 + 0.26 * 7) {
    stretchLevel = 8;
  } else if (height <= 1 + 0.26 * 8) {
    stretchLevel = 9;
  } else if (height <= 1 + 0.26 * 9) {
    stretchLevel = 10;
  } else if (height <= 1 + 0.26 * 10) {
    stretchLevel = 11;
  } else {
    stretchLevel = 12;
  }
  let leftElement = element.previousElementSibling;
  let rightElement = element.nextElementSibling;
  leftElement.textContent = DATA["paren"][kind][stretchLevel][0];
  rightElement.textContent = DATA["paren"][kind][stretchLevel][1];
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

function execute() {
  console.log("Executed");
  document.querySelectorAll(".st-paren").forEach(stretchParen);
}

window.onload = execute;