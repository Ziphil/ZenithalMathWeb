//


class SubsuperModifier extends Modifier {

  modify(element) {
    let baseElement = this.findChild(element, "math-base");
    let subElement = this.findChild(element, "math-sub");
    let superElement = this.findChild(element, "math-sup");
    let leftSubElement = this.findChild(element, "math-lsub");
    let leftSuperElement = this.findChild(element, "math-lsup");
    this.modifySide(element, baseElement, subElement, superElement, "right");
    this.modifySide(element, baseElement, leftSubElement, leftSuperElement, "left");
  }

  modifySide(element, baseElement, subElement, superElement, side) {
    let bothShifts = this.calcBothShifts(baseElement, subElement, superElement);
    let subShift = bothShifts.sub;
    let superShift = bothShifts.super;
    let subMargin = 0;
    let superMargin = (subElement) ? -this.getWidth(subElement) : 0;
    let subWidth = (subElement) ? this.getWidth(subElement) : 0;
    let superWidth = (superElement) ? this.getWidth(superElement) : 0;
    if (side == "right" && element.classList.contains("int")) {
      let slope = (element.classList.contains("inl")) ? 0.3 : 0.6
      subWidth -= slope;
      subMargin -= slope;
      if (subElement) {
        superMargin += slope;
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
    if (side == "right" && superElement && subWidth > superWidth) {
      superElement.style.width = "" + subWidth + "em";
    }
    if (side == "left" && subElement && superWidth > subWidth) {
      subElement.style.width = "" + superWidth + "em";
    }
  }

  calcBothShifts(baseElement, subElement, superElement) {
    let subShift = (subElement) ? this.calcSubShift(baseElement, subElement) : 0;
    let superShift = (superElement) ? this.calcSuperShift(baseElement, superElement) : 0;
    if (subElement && superElement) {
      let subHeight = this.getHeight(subElement);
      let gap = -subShift + superShift - subHeight;
      if (gap < 0.2) {
        subShift -= (0.2 - gap) / 2;
        superShift += (0.2 - gap) / 2;
      }
    }
    return {sub: subShift, super: superShift};
  }

  calcSubShift(baseElement, subElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(subElement);
    let height = this.getLowerHeight(baseElement);
    if (height < 0.4875) {
      height = 0.4875;
    }
    let shiftConst = -0.25;
    if (baseElement.parentNode.classList.contains("int") && !baseElement.parentNode.classList.contains("inl")) {
      shiftConst = -0.15;
    }
    let shift = (height + shiftConst) * fontRatio;
    return -shift;
  }

  calcSuperShift(baseElement, superElement) {
    let fontRatio = this.getFontSize(baseElement) / this.getFontSize(superElement);
    let height = this.getUpperHeight(baseElement);
    if (height < 0.5125) {
      height = 0.5125;
    }
    let shiftConst = -0.2;
    if (baseElement.parentNode.classList.contains("int") && !baseElement.parentNode.classList.contains("inl")) {
      shiftConst = -0.1;
    }
    let shift = (height + shiftConst) * fontRatio;
    return shift;
  }

}