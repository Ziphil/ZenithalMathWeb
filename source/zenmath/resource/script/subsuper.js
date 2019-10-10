//


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
  let subWidth = getWidth(subElement);
  let supWidth = getWidth(superElement);
  let subShift = calcSubShift(baseElement, subElement);
  let superShift = calcSuperShift(baseElement, superElement);
  let subMargin = 0;
  let superMargin = -getWidth(subElement);
  if (baseSymbolElement.classList.contains("int")) {
    subWidth -= 0.6;
    subMargin -= 0.6;
    superMargin += 0.6;
  }
  subElement.style.verticalAlign = "" + subShift + "em";
  superElement.style.verticalAlign = "" + superShift + "em";
  superElement.style.marginLeft = "" + superMargin + "em";
  subElement.style.marginLeft = "" + subMargin + "em";
  if (subWidth > supWidth) {
    superElement.style.width = "" + subWidth + "em";
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