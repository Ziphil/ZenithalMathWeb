//


class Modifier {

  modify() {
    console.info("[Zotica] Start");
    let startDate = new Date();
    let elements = [];
    elements.push(...document.querySelectorAll("math-subsup"));
    elements.push(...document.querySelectorAll("math-underover"));
    elements.push(...document.querySelectorAll("math-rad.mod"));
    elements.push(...document.querySelectorAll("math-fence.mod"));
    elements.push(...document.querySelectorAll("math-diagram"));
    elements.push(...document.querySelectorAll("math-step"));
    elements = elements.sort((first, second) => {
      return this.getDepth(second) - this.getDepth(first);
    });
    elements.forEach((element) => {
      let name = element.localName;
      if (name == "math-subsup") {
        SubsuperModifier.execute(element);
      } else if (name == "math-underover") {
        UnderoverModifier.execute(element);
        if (element.classList.contains("wid") && element.classList.contains("mod")) {
          WideModifier.execute(element);
        }
      } else if (name == "math-rad") {
        RadicalModifier.execute(element);
      } else if (name == "math-fence") {
        FenceModifier.execute(element);
      } else if (name == "math-diagram") {
        DiagramModifier.execute(element);
      } else if (name == "math-step") {
        TreeModifier.execute(element);
      }
    });
    let finishDate = new Date();
    let elapsedTime = ((finishDate - startDate) / 1000).toFixed(4);
    console.info("[Zotica] Finish (" + elements.length + " elements, " + elapsedTime + " seconds)");
  }

  modifyDebug() {
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

  getOffsetLeft(element, fontElement) {
    let offset = element.offsetLeft / this.getFontSize(fontElement || element);
    return offset;
  }

  getOffsetRight(element, fontElement) {
    let offset = (element.offsetParent.offsetWidth - element.offsetLeft - element.offsetWidth) / this.getFontSize(fontElement || element);
    return offset;
  }

  getDepth(element) {
    let depth = 0;
    if (element.zoticaDepth != undefined) {
      depth = element.zoticaDepth;
    } else {
      let parent = element.parentNode;
      if (parent) {
        depth = this.getDepth(parent) + 1;
      } else {
        depth = 0;
      }
    }
    element.zoticaDepth = depth;
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