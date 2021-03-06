//


class FenceModifier extends Modifier {

  modify(element) {
    let contentElements = this.findChildren(element, "math-cont");
    let leftElement = this.findChild(element, "math-left");
    let rightElement = this.findChild(element, "math-right");
    let centerElement = this.findChild(element, "math-center");
    let parentElements = [leftElement, rightElement, centerElement];
    let kinds = this.calcKinds(element);
    for (let position of [0, 1, 2]) {
      let parentElement = parentElements[position];
      let kind = kinds[position];
      if (position == 2) {
        position = 0;
      }
      if (parentElement && kind != "none") {
        let stretchLevel = this.calcStretchLevel(contentElements, kind, position);
        if (stretchLevel != null) {
          this.modifyStretch(contentElements, parentElement, kind, stretchLevel, position);
        } else {
          this.appendStretch(contentElements, parentElement, kind, position);
        }
      }
    }
  }

  modifyStretch(contentElements, parentElement, kind, stretchLevel, position) {
    let symbolElement = parentElement.children[0];
    let shift = this.calcShift(contentElements, stretchLevel);
    symbolElement.textContent = DATA["fence"][kind][position][stretchLevel];
    parentElement.style.verticalAlign = "" + shift + "em";
  }

  appendStretch(contentElements, parentElement, kind, position) {
    let stretchElement = document.createElement("math-vstretch");
    let hasStart = !!DATA["fence"][kind][position]["start"];
    let hasEnd = !!DATA["fence"][kind][position]["end"];
    let hasMiddle = !!DATA["fence"][kind][position]["middle"];
    let startElement = null;
    let endElement = null;
    let middleElement = null;
    if (hasStart) {
      startElement = document.createElement("math-start");
      startElement.textContent = DATA["fence"][kind][position]["start"];
      stretchElement.append(startElement);
    }
    if (hasMiddle) {
      middleElement = document.createElement("math-middle");
      middleElement.textContent = DATA["fence"][kind][position]["middle"];
      stretchElement.append(middleElement);
    }
    if (hasEnd) {
      endElement = document.createElement("math-end");
      endElement.textContent = DATA["fence"][kind][position]["end"];
      stretchElement.append(endElement);
    }
    parentElement.removeChild(parentElement.children[0]);
    parentElement.appendChild(stretchElement);
    let barSize = (hasMiddle) ? 2 : 1;
    let barHeight = this.calcBarHeight(contentElements, startElement, endElement, middleElement);
    let stretchShift = this.calcStretchShift(contentElements);
    for (let i = 0 ; i < barSize ; i ++) { 
      let barWrapperElement = document.createElement("math-barwrap");
      let barElement = document.createElement("math-bar");
      barElement.textContent = DATA["fence"][kind][position]["bar"];
      barWrapperElement.style.height = "" + barHeight + "em";
      barWrapperElement.append(barElement);
      if (i == 0) {
        stretchElement.insertBefore(barWrapperElement, stretchElement.children[(hasStart) ? 1 : 0]);
      } else {
        stretchElement.insertBefore(barWrapperElement, stretchElement.children[(hasStart) ? 3 : 2]);
      }
    }
    stretchElement.style.verticalAlign = "" + stretchShift + "em";
  }

  calcKinds(element) {
    let leftKind = "paren";
    let rightKind = "paren";
    let centerKind = "vert";
    if (element.getAttribute("data-left")) {
      leftKind = element.getAttribute("data-left");
    }
    if (element.getAttribute("data-right")) {
      rightKind = element.getAttribute("data-right");
    }
    if (element.getAttribute("data-center")) {
      centerKind = element.getAttribute("data-center");
    }
    return [leftKind, rightKind, centerKind];
  }

  calcMaxStretchLevel(kind, position) {
    let keys = Object.keys(DATA["fence"][kind][position]);
    let maxStretchLevel = 0;
    for (let key of keys) {
      if (key.match(/^\d+$/) && parseInt(key) > maxStretchLevel) {
        maxStretchLevel = parseInt(key);
      }
    }
    return maxStretchLevel;
  }

  calcWholeHeight(elements) {
    let upperHeights = [];
    let lowerHeights = [];
    for (let element of elements) {
      upperHeights.push(this.getUpperHeight(element));
      lowerHeights.push(this.getLowerHeight(element));
    }
    let maxUpperHeight = Math.max(...upperHeights);
    let maxLowerHeight = Math.max(...lowerHeights);
    return maxUpperHeight + maxLowerHeight;
  }

  calcStretchLevel(elements, kind, position) {
    let heightAbs = this.calcWholeHeight(elements) * 1000;
    let maxStretchLevel = this.calcMaxStretchLevel(kind, position);
    let stretchLevel = null;
    for (let i = 0 ; i <= maxStretchLevel ; i ++) {
      if (heightAbs <= 1059 + 242 * i) {
        stretchLevel = i;
        break;
      }
    }
    if (stretchLevel == null && !DATA["fence"][kind][position]["bar"]) {
      stretchLevel = maxStretchLevel;
    }
    return stretchLevel;
  }

  calcShift(elements, stretchLevel) {
    let shift = this.calcWholeHeight(elements) / 2 - Math.max(...elements.map((element) => this.getLowerHeight(element)));
    if (stretchLevel == 0) {
      shift = 0;
    }
    return shift;
  }

  calcBarHeight(elements, startElement, endElement, middleElement) {
    let wholeHeight = this.calcWholeHeight(elements);
    let startHeight = (startElement) ? this.getHeight(startElement) : 0;
    let endHeight = (endElement) ? this.getHeight(endElement) : 0;
    let middleHeight = (middleElement) ? this.getHeight(middleElement) : 0;
    let height = wholeHeight - startHeight - endHeight - middleHeight;
    if (middleElement) {
      height = height / 2;
    }
    if (height < 0) {
      height = 0;
    }
    return height;
  }

  calcStretchShift(elements) {
    let shift = Math.max(...elements.map((element) => this.getUpperHeight(element))) - 0.95;
    return shift;
  }

}