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
    let consequentWrapperElement = this.findChild(element, "math-conwrap");
    let lineElement = this.findChild(consequentWrapperElement, "math-line");
    let consequentElement = this.findChild(consequentWrapperElement, "math-con");
    let contentElement = this.findChild(consequentElement, "math-cont");
    let fontRatio = this.getFontSize(element) / this.getFontSize(leftLabelElement);
    let leftLabelWidth = this.getWidth(leftLabelElement, element);
    let rightLabelWidth = this.getWidth(rightLabelElement, element);
    let contentWidth = this.getWidth(contentElement);
    let wholeWidth = this.getWidth(element);
    let leftExtrusion = 0;
    let rightExtrusion = 0;
    if (firstContentElement.localName != "math-axiom") {
      leftExtrusion = this.getOffsetLeft(firstContentElement);
    }
    if (lastContentElement.localName != "math-axiom") {
      rightExtrusion = this.getOffsetRight(lastContentElement);
    }
    let lineWidth = wholeWidth - leftExtrusion - rightExtrusion;
    let leftMargin = (lineWidth - contentWidth) / 2 + leftExtrusion;
    consequentElement.style.setProperty("margin-left", "" + leftMargin + "em");
    if (leftExtrusion > this.getOffsetLeft(contentElement) - leftLabelWidth) {
      leftExtrusion = this.getOffsetLeft(contentElement) - leftLabelWidth;
    }
    if (rightExtrusion > this.getOffsetRight(contentElement) - rightLabelWidth) {
      rightExtrusion = this.getOffsetRight(contentElement) - rightLabelWidth;
    }
    lineWidth = wholeWidth - leftExtrusion - rightExtrusion;
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
      let consequentElement = this.findChild(consequenceWrapperElement, "math-con");
      contentElement = this.findChild(consequentElement, "math-cont");
    }
    return contentElement;
  }

}