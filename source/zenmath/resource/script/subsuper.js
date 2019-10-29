//


class SubsuperModifier extends Modifier {

  modify(element) {
    let baseElement = Array.from(element.children).find((child) => child.localName == "math-base");
    let subElement = Array.from(element.children).find((child) => child.localName == "math-sub");
    let superElement = Array.from(element.children).find((child) => child.localName == "math-sup");
    let baseSymbolElement = Array.from(baseElement.children).find((child) => child.localName == "math-o");
    let subWidth = (subElement) ? this.getWidth(subElement) : 0;
    let superWidth = (superElement) ? this.getWidth(superElement) : 0;
    let subShift = (subElement) ? this.calcSubShift(baseElement, subElement, superElement) : 0;
    let superShift = (superElement) ? this.calcSuperShift(baseElement, superElement, subElement) : 0;
    let subMargin = 0;
    let superMargin = (subElement) ? -this.getWidth(subElement) : 0;
    if (baseSymbolElement && element.classList.contains("int")) {
      subWidth -= 0.6;
      subMargin -= 0.6;
      superMargin += 0.6;
    }
    if (subElement) {
      subElement.style.verticalAlign = "" + subShift + "em";
      subElement.style.marginLeft = "" + subMargin + "em";
    }
    if (superElement) {
      superElement.style.verticalAlign = "" + superShift + "em";
      superElement.style.marginLeft = "" + superMargin + "em";
    }
    if (superElement && subWidth > superWidth) {
      superElement.style.width = "" + subWidth + "em";
    }
  }

  calcSubShift(baseElement, subElement, superElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(subElement);
    let shiftConst = -0.3
    if (superElement || baseElement.parentNode.classList.contains("int")) {
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
    if (subElement || baseElement.parentNode.classList.contains("int")) {
      shiftConst = -0.1
    }
    let height = this.getUpperHeight(baseElement);
    console.log({sup: height});
    if (height < 0.5125) {
      height = 0.5125;
    }
    let shift = (height + shiftConst) * fontRatio;
    return shift;
  }

}