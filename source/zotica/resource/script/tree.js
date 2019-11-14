//


class TreeModifier extends Modifier {

  modify(element) {
    let antecendentContainerElement = this.findChild(element, "math-ant");
    let firstAntecedentElement = antecendentContainerElement.children[0];
    let lastAntecedentElement = antecendentContainerElement.children[antecendentContainerElement.children.length - 1];
    let firstContentElement = this.calcContentElement(firstAntecedentElement);
    let lastContentElement = this.calcContentElement(lastAntecedentElement);
    let leftLabelElement = element.previousElementSibling;
    let rightLabelElement = element.nextElementSibling;
    let fontSize = this.getFontSize(element);
    let fontRatio = fontSize / this.getFontSize(leftLabelElement);
    let firstAntecedentWidth = this.getWidth(firstAntecedentElement);
    let lastAntecedentWidth = this.getWidth(lastAntecedentElement);
    let firstContentWidth = this.getWidth(firstContentElement);
    let lastContentWidth = this.getWidth(lastContentElement);
    let leftLabelWidth = this.getWidth(leftLabelElement, element);
    let rightLabelWidth = this.getWidth(rightLabelElement, element);
    let wholeWidth = this.getWidth(element);
    let leftExtrusion = 0;
    let rightExtrusion = 0;
    if (firstContentElement.localName != "math-axiom") {
      leftExtrusion = firstContentElement.offsetLeft / fontSize;
    }
    if (lastContentElement.localName != "math-axiom") {
      rightExtrusion = (lastContentElement.offsetParent.offsetWidth - lastContentElement.offsetLeft - lastContentElement.offsetWidth) / fontSize;
    }
    let lineWidth = wholeWidth - leftExtrusion - rightExtrusion;
    let consequentElement = this.findChild(element, "math-conwrap");
    let lineElement = this.findChild(consequentElement, "math-line");
    lineElement.style.setProperty("width", "" + lineWidth + "em", "important");
    lineElement.style.setProperty("margin-left", "" + leftExtrusion + "em", "important");
    element.style.setProperty("margin-right", "" + (-rightExtrusion) + "em", "important");
    if (rightLabelWidth < rightExtrusion) {
      rightLabelElement.style.setProperty("margin-right", "" + ((rightExtrusion - rightLabelWidth) * fontRatio) + "em", "important");
    }
    element.style.setProperty("margin-left", "" + (-leftExtrusion) + "em", "important");
    if (leftLabelWidth < leftExtrusion) {
      leftLabelElement.style.setProperty("margin-left", "" + ((leftExtrusion - leftLabelWidth) * fontRatio) + "em", "important");
    }
  }

  calcContentElement(antecedentElement) {
    let contentElement = null;
    if (antecedentElement.localName == "math-axiom") {
      contentElement = antecedentElement;
    } else {
      let stepElement = this.findChild(antecedentElement, "math-step");
      let consequenceWrapperElement = this.findChild(stepElement, "math-conwrap");
      let consequenceElement = this.findChild(consequenceWrapperElement, "math-con");
      contentElement = this.findChild(consequenceElement, "math-cont");
    }
    return contentElement;
  }

}