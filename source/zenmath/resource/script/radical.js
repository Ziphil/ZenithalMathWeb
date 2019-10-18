//


class RadicalModifier extends Modifier {

  modify(element) {
    let surdElement = element.children[0];
    let surdSymbolElement = surdElement.children[0];
    let contentElement = element.children[1];
    let stretchLevel = this.calcStretchLevel(element);
    surdSymbolElement.textContent = DATA["radical"][stretchLevel];
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