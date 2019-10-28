//


class SubsuperModifier extends Modifier {

  modify(element) {
    let baseElement = Array.from(element.children).find((child) => child.localName == "math-base");
    let subElement = Array.from(element.children).find((child) => child.localName == "math-sub");
    let superElement = Array.from(element.children).find((child) => child.localName == "math-sup");
    let baseSymbolElement = Array.from(baseElement.children).find((child) => child.localName == "math-o");
    let subWidth = (subElement) ? this.getWidth(subElement) : 0;
    let superWidth = (superElement) ? this.getWidth(superElement) : 0;
    let subShift = (subElement) ? this.calcSubShift(baseElement, subElement) : 0;
    let superShift = (superElement) ? this.calcSuperShift(baseElement, superElement) : 0;
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

  calcSubShift(baseElement, subElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(subElement);
    let shift = (this.getLowerHeight(baseElement) - 0.18) * fontRatio;
    return -shift;
  }

  calcSuperShift(baseElement, superElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(superElement);
    let shift = (this.getUpperHeight(baseElement) - 0) * fontRatio;
    return shift;
  }

}