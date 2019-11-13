//


class TreeModifier extends Modifier {

  modify(element) {
    let antecendentParentElement = this.findChild(element, "math-num");
    let firstAntecedentElement = antecendentParentElement.children[0];
    let lastAntecedentElement = antecendentParentElement.children[antecendentParentElement.children.length - 1];
    let firstContentElement = this.calcContentElement(firstAntecedentElement);
    let lastContentElement = this.calcContentElement(lastAntecedentElement);
    let leftLabelElement = element.previousElementSibling;
    let rightLabelElement = element.nextElementSibling;
    let wholeWidth = this.getWidth(element);
    let leftExtrusion = (this.getWidth(firstAntecedentElement) - this.getWidth(firstContentElement)) / 2;
    let rightExtrusion = (this.getWidth(lastAntecedentElement) - this.getWidth(lastContentElement)) / 2;
    let leftLabelWidth = this.getWidth(leftLabelElement, element);
    let rightLabelWidth = this.getWidth(rightLabelElement, element);
    let lineWidth = wholeWidth - leftExtrusion - rightExtrusion;
    antecendentParentElement.style.setProperty("margin-left", "" + (-leftExtrusion - leftLabelWidth) + "em", "important");
    antecendentParentElement.style.setProperty("margin-right", "" + (-rightExtrusion - rightLabelWidth) + "em", "important");
  }

  calcContentElement(antecedentElement) {
    let contentElement = null;
    if (antecedentElement.localName == "math-axiom") {
      contentElement = antecedentElement;
    } else {
      let fractionElement = this.findChild(antecedentElement, "math-frac");
      let consequenceWrapperElement = this.findChild(fractionElement, "math-denwrap");
      let consequenceElement = this.findChild(consequenceWrapperElement, "math-den");
      contentElement = this.findChild(consequenceElement, "math-cont");
    }
    return contentElement;
  }

}