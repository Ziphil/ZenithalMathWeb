//


class SubsuperModifier extends Modifier {

  modify(element) {
    let baseElement = Array.from(element.children).find((child) => child.localName == "math-base");
    let subElement = Array.from(element.children).find((child) => child.localName == "math-sub");
    let superElement = Array.from(element.children).find((child) => child.localName == "math-sup");
    let leftSubElement = Array.from(element.children).find((child) => child.localName == "math-lsub");
    let leftSuperElement = Array.from(element.children).find((child) => child.localName == "math-lsup");
    let baseSymbolElement = Array.from(baseElement.children).find((child) => child.localName == "math-o");
    let subWidth = (subElement) ? this.getWidth(subElement) : 0;
    let superWidth = (superElement) ? this.getWidth(superElement) : 0;
    let leftSubWidth = (leftSubElement) ? this.getWidth(leftSubElement) : 0;
    let leftSuperWidth = (leftSuperElement) ? this.getWidth(leftSuperElement) : 0;
    let subShift = (subElement) ? this.calcSubShift(baseElement, subElement, superElement) : 0;
    let superShift = (superElement) ? this.calcSuperShift(baseElement, superElement, subElement) : 0;
    let leftSubShift = (leftSubElement) ? this.calcSubShift(baseElement, leftSubElement, leftSuperElement) : 0;
    let leftSuperShift = (leftSuperElement) ? this.calcSuperShift(baseElement, leftSuperElement, leftSubElement) : 0;
    let subMargin = 0;
    let superMargin = (subElement) ? -this.getWidth(subElement) : 0;
    let leftSubMargin = (leftSuperElement) ? -this.getWidth(leftSuperElement) : 0;
    let leftSuperMargin = 0;
    if (baseSymbolElement && element.classList.contains("int")) {
      let difference = (element.classList.contains("inl")) ? 0.3 : 0.6
      subWidth -= difference;
      subMargin -= difference;
      if (superElement) {
        superMargin += difference;
      }
    }
    if (subElement) {
      subElement.style.verticalAlign = "" + subShift + "em";
      subElement.style.marginLeft = "" + subMargin + "em";
    }
    if (superElement) {
      superElement.style.verticalAlign = "" + superShift + "em";
      superElement.style.marginLeft = "" + superMargin + "em";
    }
    if (leftSubElement) {
      leftSubElement.style.verticalAlign = "" + leftSubShift + "em";
      leftSubElement.style.marginRight = "" + leftSubMargin + "em";
    }
    if (leftSuperElement) {
      leftSuperElement.style.verticalAlign = "" + leftSuperShift + "em";
      leftSuperElement.style.marginRight = "" + leftSuperMargin + "em";
    }
    if (superElement && subWidth > superWidth) {
      superElement.style.width = "" + subWidth + "em";
    }
    if (leftSubElement && leftSuperWidth > leftSubWidth) {
      leftSubElement.style.width = "" + leftSuperWidth + "em";
    }
  }

  calcSubShift(baseElement, subElement, superElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(subElement);
    let shiftConst = -0.3
    if (superElement || (baseElement.parentNode.classList.contains("int") && !baseElement.parentNode.classList.contains("inl"))) {
      shiftConst = -0.2
    }
    let height = this.getLowerHeight(baseElement);
    if (height < 0.4875) {
      height = 0.4875;
    }
    let shift = (height + shiftConst) * fontRatio;
    return -shift;
  }

  calcSuperShift(baseElement, superElement, subElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(superElement);
    let shiftConst = -0.2;
    if (subElement || (baseElement.parentNode.classList.contains("int") && !baseElement.parentNode.classList.contains("inl"))) {
      shiftConst = -0.1
    }
    let height = this.getUpperHeight(baseElement);
    if (height < 0.5125) {
      height = 0.5125;
    }
    let shift = (height + shiftConst) * fontRatio;
    return shift;
  }

}