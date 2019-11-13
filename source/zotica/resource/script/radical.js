//


class RadicalModifier extends Modifier {

  modify(element) {
    let squareElement = this.findChild(element, "math-sqrt");
    let indexElement = this.findChild(element, "math-index");
    let surdElement = this.findChild(squareElement, "math-surd");
    let contentElement = this.findChild(squareElement, "math-cont");
    let surdSymbolElement = surdElement.children[0];
    let stretchLevel = this.calcStretchLevel(contentElement);
    surdSymbolElement.textContent = DATA["radical"][stretchLevel];
    if (indexElement) {
      this.modifyIndex(element, indexElement);
    }
  }

  modifyIndex(element, indexElement) {
    let width = this.getWidth(indexElement);
    let fontRatio = this.getFontSize(element) / this.getFontSize(indexElement);
    if (width / fontRatio < 0.5) {
      let margin = 0.5 * fontRatio - width;
      indexElement.style.marginLeft = "" + margin + "em";
    }
  }

  calcStretchLevel(element) {
    let heightAbs = this.getHeight(element) * 1000;
    let stretchLevel = null;
    for (let i = 0 ; i <= 3 ; i ++) {
      if (heightAbs <= DATA["radical"]["height"][i]) {
        stretchLevel = i;
        break;
      }
    }
    if (stretchLevel == null) {
      stretchLevel = 3;
    }
    return stretchLevel;
  }

}