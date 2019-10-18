//


class SubsuperModifier extends Modifier {

  modify(element) {
    let baseElement = element.children[0];
    let baseSymbolElement = baseElement.children[0];
    let subElement = element.children[1];
    let superElement = element.children[2];
    let subWidth = this.getWidth(subElement);
    let supWidth = this.getWidth(superElement);
    let subShift = this.calcSubShift(baseElement, subElement);
    let superShift = this.calcSuperShift(baseElement, superElement);
    let subMargin = 0;
    let superMargin = -this.getWidth(subElement);
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

  calcSubShift(baseElement, subElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(subElement);
    let shift = (this.getLowerHeight(baseElement) - 0.2) * fontRatio;
    return -shift;
  }

  calcSuperShift(baseElement, superElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(superElement);
    let shift = (this.getUpperHeight(baseElement) - 0.1) * fontRatio;
    return shift;
  }

}