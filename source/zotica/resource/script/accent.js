//


class AccentModifier extends Modifier {

  modify(element) {
    let baseWrapperElement = this.findChild(element, "math-basewrap");
    let overElement = this.findChild(element, "math-over");
    let contentElement = baseWrapperElement.children[0];
    let parentElements = [baseWrapperElement.children[1], overElement];
    for (let position of [0, 1]) {
      let parentElement = parentElements[position];
      if (parentElement) {
        this.modifyPosition(contentElement, parentElement, position);
      }
    }
  }

  modifyPosition(contentElement, parentElement, position) {
    let charElement = contentElement.children[0];
    let string = charElement && charElement.textContent;
    if (string && string.length == 1 && contentElement.children.length == 1) {
      let char = string.substring(0, 1);
      let shift = DATA["shift"][position][char];
      if (shift) {
        let marginString;
        if (position == 0) {
          marginString = window.getComputedStyle(parentElement).marginTop;
        } else {
          marginString = window.getComputedStyle(parentElement).marginBottom;
        }
        let margin = parseFloat(marginString) / this.getFontSize(parentElement);
        if (position == 0) {
          parentElement.style.marginTop = "" + (margin + shift) + "em";
        } else {
          parentElement.style.marginBottom = "" + (margin - shift) + "em";
        }
      }
    }
  }

}