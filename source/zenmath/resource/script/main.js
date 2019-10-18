//


class Modifier {

  getFontSize(element) {
    let fontSizeString = window.getComputedStyle(element).fontSize;
    let fontSize = parseFloat(fontSizeString);
    return fontSize;
  }

  getWidthPx(element) {
    let width = element.getBoundingClientRect().width;
    return width;
  }

  getWidth(element) {
    let width = this.getWidthPx(element) / this.getFontSize(element);
    return width;
  }

  getHeightPx(element) {
    let height = element.getBoundingClientRect().height;
    return height;
  }

  getHeight(element) {
    let height = this.getHeightPx(element) / this.getFontSize(element);
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

  getLowerHeight(element) {
    let height = this.getLowerHeightPx(element) / this.getFontSize(element);
    return height;
  }

  getUpperHeightPx(element) {
    let height = this.getHeightPx(element) - this.getLowerHeightPx(element);
    return height;
  }

  getUpperHeight(element) {
    let height = this.getHeight(element) - this.getLowerHeight(element);
    return height;
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


function execute() {
  document.querySelectorAll("math-underover.acc").forEach((element) => {
    AccentModifier.execute(element);
  });
  document.querySelectorAll("math-subsup").forEach((element) => {
    SubsuperModifier.execute(element);
  });
  document.querySelectorAll("math-underover").forEach((element) => {
    UnderoverModifier.execute(element);
  });
  document.querySelectorAll("math-sqrt.mod").forEach((element) => {
    RadicalModifier.execute(element);
  });
  document.querySelectorAll("math-paren.mod").forEach((element) => {
    ParenModifier.execute(element);
  });
  document.querySelectorAll("math-underover.wide.mod").forEach((element) => {
    WideModifier.execute(element);
  });
  document.querySelectorAll("math-diagram").forEach((element) => {
    DiagramModifier.execute(element);
  });
}