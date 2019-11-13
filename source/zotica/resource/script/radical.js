//


class RadicalModifier extends Modifier {

  modify(element) {
    let squareElement = Array.from(element.children).find((child) => child.localName == "math-sqrt");
    let indexElement = Array.from(element.children).find((child) => child.localName == "math-index");
    let surdElement = Array.from(squareElement.children).find((child) => child.localName == "math-surd");
    let contentElement = Array.from(squareElement.children).find((child) => child.localName == "math-cont");
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