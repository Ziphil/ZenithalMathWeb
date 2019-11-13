//


class Modifier {

  modify() {
    let outerThis = this;
    let byDepthDescending = function (first, second) {
      return outerThis.getDepth(second) - outerThis.getDepth(first);
    }
    Array.from(document.querySelectorAll("math-subsup, math-underover")).sort(byDepthDescending).forEach((element) => {
      if (element.localName == "math-subsup") {
        SubsuperModifier.execute(element);
      } else if (element.localName == "math-underover") {
        UnderoverModifier.execute(element);
      }
    });
    document.querySelectorAll("math-rad.mod").forEach((element) => {
      RadicalModifier.execute(element);
    });
    document.querySelectorAll("math-fence.mod").forEach((element) => {
      FenceModifier.execute(element);
    });
    document.querySelectorAll("math-underover.wid.mod").forEach((element) => {
      WideModifier.execute(element);
    });
    document.querySelectorAll("math-diagram").forEach((element) => {
      DiagramModifier.execute(element);
    });
    Array.from(document.querySelectorAll("math-frac.inf")).sort(byDepthDescending).forEach((element) => {
      TreeModifier.execute(element);
    });
    document.querySelectorAll("debug").forEach((element) => {
      let modifier = new Modifier();
      modifier.renderDebug(element);
    });
  }

  getFontSize(element) {
    let fontSizeString = window.getComputedStyle(element).fontSize;
    let fontSize = parseFloat(fontSizeString);
    return fontSize;
  }

  getWidthPx(element) {
    let width = element.getBoundingClientRect().width;
    return width;
  }

  getWidth(element, fontElement) {
    let width = this.getWidthPx(element) / this.getFontSize(fontElement || element);
    return width;
  }

  getHeightPx(element) {
    let height = element.getBoundingClientRect().height;
    return height;
  }

  getHeight(element, fontElement) {
    let height = this.getHeightPx(element) / this.getFontSize(fontElement || element);
    return height;
  }

  getLowerHeightPx(element) {
    let bottom = element.getBoundingClientRect().bottom + window.pageYOffset;
    let locator = document.createElement("math-sys-locator");
    element.appendChild(locator);
    locator.style.verticalAlign = "baseline";
    let baselineBottom = locator.getBoundingClientRect().bottom + window.pageYOffset;
    let height = bottom - baselineBottom + this.getFontSize(element) * 0.3;
    element.removeChild(locator);
    return height;
  }

  getLowerHeight(element, fontElement) {
    let height = this.getLowerHeightPx(element) / this.getFontSize(fontElement || element);
    return height;
  }

  getUpperHeightPx(element) {
    let height = this.getHeightPx(element) - this.getLowerHeightPx(element);
    return height;
  }

  getUpperHeight(element, fontElement) {
    let height = this.getHeight(element, fontElement) - this.getLowerHeight(element, fontElement);
    return height;
  }

  getDepth(element) {
    let currentElement = element;
    let depth = 0;
    while (currentElement) {
      currentElement = currentElement.parentNode;
      depth += 1;
    }
    return depth;
  }  

  findChild(element, name) {
    return Array.from(element.children).find((child) => child.localName == name);
  }

  findChildren(element, name) {
    return Array.from(element.children).filter((child) => child.localName == name);
  }

  renderDebug(element) {
    let clientRect = element.getBoundingClientRect();
    let scrollOffset = window.pageYOffset;
    let lowerHeight = this.getLowerHeightPx(element);
    let upperHeight = this.getUpperHeightPx(element);
    let line = document.createElement("div");
    let upperBox = document.createElement("div");
    let lowerBox = document.createElement("div");
    line.style.position = "absolute";
    line.style.borderTop = "1px #FF000088 solid";
    line.style.width = "" + clientRect.width + "px";
    line.style.height = "1px";
    line.style.top = "" + (clientRect.bottom - lowerHeight + scrollOffset) + "px";
    line.style.left = "" + clientRect.left + "px";
    lowerBox.style.position = "absolute";
    lowerBox.style.backgroundColor = "#FFFF0033";
    lowerBox.style.width = "" + clientRect.width + "px";
    lowerBox.style.height = "" + lowerHeight + "px";
    lowerBox.style.top = "" + (clientRect.top + upperHeight + scrollOffset) + "px";
    lowerBox.style.left = "" + clientRect.left + "px";
    upperBox.style.position = "absolute";
    upperBox.style.backgroundColor = "#FF000033";
    upperBox.style.width = "" + clientRect.width + "px";
    upperBox.style.height = "" + upperHeight + "px";
    upperBox.style.top = "" + (clientRect.top + scrollOffset) + "px";
    upperBox.style.left = "" + clientRect.left + "px";
    document.body.appendChild(line);
    document.body.appendChild(lowerBox);
    document.body.appendChild(upperBox);
  }

  static execute(element) {
    let modifier = new this();
    modifier.modify(element);
  }

}