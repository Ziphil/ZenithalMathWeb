//


class WideModifier extends Modifier {

  modify(element) {
    let baseWrapperElement = Array.from(element.children).find((child) => child.localName == "math-basewrap");
    let overElement = Array.from(element.children).find((child) => child.localName == "math-over");
    let contentElement = baseWrapperElement.children[0];
    let parentElements = [baseWrapperElement.children[1], overElement];
    let kind = this.calcKind(element);
    for (let position of [0, 1]) {
      let parentElement = parentElements[position];
      if (parentElement) {
        let stretchLevel = this.calcStretchLevel(contentElement, kind, position);
        if (stretchLevel != null) {
          this.modifyStretch(contentElement, parentElement, kind, stretchLevel, position);
        } else {
          this.appendStretch(contentElement, parentElement, kind, position);
        }
      }
    }
  }

  modifyStretch(contentElement, parentElement, kind, stretchLevel, position) {
    let symbolElement = parentElement.children[0];
    symbolElement.textContent = DATA["wide"][kind][position][stretchLevel];
  }

  appendStretch(contentElement, parentElement, kind, position) {
    let stretchElement = document.createElement("math-hstretch");
    let hasBegin = !!DATA["wide"][kind][position]["beg"];
    let hasEnd = !!DATA["wide"][kind][position]["end"];
    let hasMiddle = !!DATA["wide"][kind][position]["mid"];
    let beginElement = null;
    let endElement = null;
    let middleElement = null;
    if (hasBegin) {
      beginElement = document.createElement("math-beg");
      beginElement.textContent = DATA["wide"][kind][position]["beg"];
      stretchElement.append(beginElement);
    }
    if (hasMiddle) {
      middleElement = document.createElement("math-mid");
      middleElement.textContent = DATA["wide"][kind][position]["mid"];
      stretchElement.append(middleElement);
    }
    if (hasEnd) {
      endElement = document.createElement("math-end");
      endElement.textContent = DATA["wide"][kind][position]["end"];
      stretchElement.append(endElement);
    }
    parentElement.removeChild(parentElement.children[0]);
    parentElement.appendChild(stretchElement);
    let barSize = (hasMiddle) ? 2 : 1;
    let barWidth = this.calcBarWidth(contentElement, beginElement, endElement, middleElement);
    for (let i = 0 ; i < barSize ; i ++) { 
      let barWrapperElement = document.createElement("math-barwrap");
      let barElement = document.createElement("math-bar");
      barElement.textContent = DATA["wide"][kind][position]["bar"];
      barWrapperElement.style.width = "" + barWidth + "em";
      barWrapperElement.append(barElement);
      if (i == 0) {
        stretchElement.insertBefore(barWrapperElement, stretchElement.children[(hasBegin) ? 1 : 0]);
      } else {
        stretchElement.insertBefore(barWrapperElement, stretchElement.children[(hasBegin) ? 3 : 2]);
      }
    }
  }

  calcKind(element) {
    let kind = "widetilde";
    for (let clazz of element.classList) {
      let match;
      if (match = clazz.match(/^wide-(\w*)$/)) {
        kind = match[1];
      }
    }
    return kind;
  }

  calcMaxStretchLevel(kind, position) {
    let keys = Object.keys(DATA["wide"][kind][position]);
    let maxStretchLevel = -1;
    for (let key of keys) {
      if (key.match(/^\d+$/) && DATA["wide"][kind][position][key] && parseInt(key) > maxStretchLevel) {
        maxStretchLevel = parseInt(key);
      }
    }
    return maxStretchLevel;
  }

  calcStretchLevel(element, kind, position) {
    let widthAbs = this.getWidth(element) * 1000;
    let maxStretchLevel = this.calcMaxStretchLevel(kind, position);
    let stretchLevel = null;
    for (let i = 0 ; i <= maxStretchLevel ; i ++) {
      if (widthAbs <= DATA["wide"][kind][position]["width"][i]) {
        stretchLevel = i;
        break;
      }
    }
    if (stretchLevel == null && !DATA["wide"][kind][position]["bar"]) {
      stretchLevel = maxStretchLevel;
    }
    return stretchLevel;
  }

  calcBarWidth(element, beginElement, endElement, middleElement) {
    let wholeWidth = this.getWidth(element);
    let beginWidth = (beginElement) ? this.getWidth(beginElement) : 0;
    let endWidth = (endElement) ? this.getWidth(endElement) : 0;
    let middleWidth = (middleElement) ? this.getWidth(middleElement) : 0;
    let width = wholeWidth - beginWidth - endWidth - middleWidth;
    if (middleElement) {
      width = width / 2;
    }
    if (width < 0) {
      width = 0;
    }
    return width;
  }

}