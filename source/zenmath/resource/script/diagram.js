//


const ANGLE_EPSILON = Math.PI / 90;

const UNIT = 1 / 18;
const ARROW_MARGIN = 8 * UNIT;
const LABEL_DISTANCE = 4 * UNIT;


class DiagramModifier extends Modifier {

  modify(element) {
    let arrowElements = Array.from(element.children).filter((child) => child.localName == "math-arrow");
    let cellElements = Array.from(element.children).filter((child) => child.localName == "math-cellwrap").map((child) => child.children[0]);
    let backgroundColor = this.getBackgroundColor(element);
    let graphic = this.createGraphic(element);
    element.appendChild(graphic);
    for (let arrowElement of arrowElements) {
      let arrowSpec = this.determineArrowSpec(graphic, arrowElement, cellElements, arrowElements);
      let arrows = this.createArrows(arrowSpec, backgroundColor);
      graphic.append(...arrows);
      let labelPoint = this.determineLabelPoint(graphic, arrowElement, arrowSpec);
      let fontRatio = this.getFontSize(graphic) / this.getFontSize(arrowElement);
      arrowElement.style.left = "" + (labelPoint[0] * fontRatio) + "em";
      arrowElement.style.top = "" + (labelPoint[1] * fontRatio) + "em";
    }
    let pathElements = Array.from(graphic.children).filter((child) => child.localName == "path");
    let extrusion = this.calcExtrusion(graphic, arrowElements.concat(pathElements));
    element.style.marginTop = "" + extrusion.top + "em";
    element.style.marginBottom = "" + extrusion.bottom + "em";
    element.style.marginLeft = "" + extrusion.left + "em";
    element.style.marginRight = "" + extrusion.right + "em";
  }

  determineArrowSpec(graphic, arrowElement, cellElements, arrowElements) {
    let spec = {};
    let startConfigString = arrowElement.getAttribute("data-start");
    let endConfigString = arrowElement.getAttribute("data-end");
    let startConfig = this.parseEdgeConfig(startConfigString, graphic, cellElements, arrowElements);
    let endConfig = this.parseEdgeConfig(endConfigString, graphic, cellElements, arrowElements);
    if (startConfig && endConfig) {
      let bendAngleString = arrowElement.getAttribute("data-bend");
      if (bendAngleString) {
        spec.bendAngle = parseFloat(bendAngleString) * Math.PI / 180;
      }
      let shiftString = arrowElement.getAttribute("data-shift");
      if (shiftString) {
        spec.shift = parseFloat(shiftString) * UNIT;
      }
      let startElement = startConfig.element;
      let endElement = endConfig.element;
      let startDimension = startConfig.dimension;
      let endDimension = endConfig.dimension;
      if (startConfig.point) {
        spec.startPoint = startConfig.point;
      } else {
        spec.startPoint = this.calcEdgePoint(startDimension, endDimension, spec.bendAngle, spec.shift);
      }
      if (endConfig.point) {
        spec.endPoint = endConfig.point;
      } else {
        spec.endPoint = this.calcEdgePoint(endDimension, startDimension, -spec.bendAngle, -spec.shift);
      }
    } else {
      spec.startPoint = [0, 0];
      spec.endPoint = [0, 0];
    }
    let labelPositionString = arrowElement.getAttribute("data-pos");
    if (labelPositionString) {
      spec.labelPosition = parseFloat(labelPositionString) / 100;
    }
    let lineCountString = arrowElement.getAttribute("data-line");
    if (lineCountString) {
      spec.lineCount = parseInt(lineCountString);
    }
    let dashed = !!arrowElement.getAttribute("data-dash");
    if (dashed) {
      spec.dashed = true;
    }
    let inverted = !!arrowElement.getAttribute("data-inv");
    if (inverted) {
      spec.inverted = true;
    }
    let mark = !!arrowElement.getAttribute("data-mark");
    if (mark) {
      spec.mark = true;
    }
    let tipKindsString = arrowElement.getAttribute("data-tip");
    spec.tipKinds = this.parseTipKinds(tipKindsString, spec.lineCount);
    spec.intrudedStartPoint = this.calcIntrudedPoint(spec.startPoint, spec.endPoint, spec.bendAngle, spec.tipKinds.start);
    spec.intrudedEndPoint = this.calcIntrudedPoint(spec.endPoint, spec.startPoint, -spec.bendAngle, spec.tipKinds.end);
    return spec;
  }

  determineLabelPoint(graphic, labelElement, arrowSpec) {
    let labelDimension = this.calcDimension(graphic, labelElement);
    let startPoint = arrowSpec.startPoint;
    let endPoint = arrowSpec.endPoint;
    let bendAngle = arrowSpec.bendAngle;
    let position = (arrowSpec.labelPosition == undefined) ? 0.5 : arrowSpec.labelPosition;
    let basePoint = [0, 0];
    let angle = 0;
    if (bendAngle != undefined) {
      let controlPoint = this.calcControlPoint(startPoint, endPoint, bendAngle);
      let basePointX = (1 - position) * (1 - position) * startPoint[0] + 2 * (1 - position) * position * controlPoint[0] + position * position * endPoint[0];
      let basePointY = (1 - position) * (1 - position) * startPoint[1] + 2 * (1 - position) * position * controlPoint[1] + position * position * endPoint[1];
      let speedX = -2 * (1 - position) * startPoint[0] + 2 * (1 - 2 * position) * controlPoint[0] + 2 * position * endPoint[0];
      let speedY = -2 * (1 - position) * startPoint[1] + 2 * (1 - 2 * position) * controlPoint[1] + 2 * position * endPoint[1];
      basePoint = [basePointX, basePointY];
      angle = this.calcAngle([0, 0], [speedX, speedY]) + Math.PI / 2;
    } else {
      let basePointX = (1 - position) * startPoint[0] + position * endPoint[0];
      let basePointY = (1 - position) * startPoint[1] + position * endPoint[1];
      basePoint = [basePointX, basePointY];
      angle = this.calcAngle(startPoint, endPoint) + Math.PI / 2;
    }
    if (arrowSpec.inverted) {
      angle += Math.PI;
    }
    angle = this.normalizeAngle(angle);
    let point;
    if (arrowSpec.mark) {
      let pointX = basePoint[0] + labelDimension.northWest[0] - labelDimension.center[0];
      let pointY = basePoint[1] + labelDimension.northWest[0] - labelDimension.center[1];
      point = [pointX, pointY];
    } else {
      point = this.calcLabelPoint(basePoint, labelDimension, angle, arrowSpec.lineCount);
    }
    return point;
  }

  calcEdgePoint(baseDimension, destinationDimension, bendAngle, shift) {
    let margin = ARROW_MARGIN;
    let angle = this.calcAngle(baseDimension.center, destinationDimension.center) + (bendAngle || 0);
    let shiftAngle = angle + Math.PI / 2;
    let southWestAngle = this.calcAngle(baseDimension.center, baseDimension.southWestMargined);
    let southEastAngle = this.calcAngle(baseDimension.center, baseDimension.southEastMargined);
    let northEastAngle = this.calcAngle(baseDimension.center, baseDimension.northEastMargined);
    let northWestAngle = this.calcAngle(baseDimension.center, baseDimension.northWestMargined);
    let x = 0;
    let y = 0;
    angle = this.normalizeAngle(angle);
    shiftAngle = this.normalizeAngle(shiftAngle);
    if (angle >= southWestAngle && angle <= southEastAngle) {
      x = baseDimension.center[0] + (baseDimension.center[1] - baseDimension.southMargined[1]) / Math.tan(angle);
      y = baseDimension.southMargined[1];
    } else if (angle >= southEastAngle && angle <= northEastAngle) {
      x = baseDimension.eastMargined[0];
      y = baseDimension.center[1] + (baseDimension.center[0] - baseDimension.eastMargined[0]) * Math.tan(angle);
    } else if (angle >= northEastAngle && angle <= northWestAngle) {
      x = baseDimension.center[0] + (baseDimension.center[1] - baseDimension.northMargined[1]) / Math.tan(angle);
      y = baseDimension.northMargined[1];
    } else if (angle >= northWestAngle || angle <= southWestAngle) {
      x = baseDimension.westMargined[0];
      y = baseDimension.center[1] + (baseDimension.center[0] - baseDimension.westMargined[0]) * Math.tan(angle);
    }
    if (shift) {
      x += Math.cos(shiftAngle) * shift;
      y -= Math.sin(shiftAngle) * shift;
    }
    return [x, y];
  }

  calcIntrudedPoint(basePoint, destinationPoint, bendAngle, tipKind) {
    if (tipKind != "none") {
      let angle = this.calcAngle(basePoint, destinationPoint) + (bendAngle || 0);
      let distance = DATA["arrow"][tipKind]["extrusion"];
      angle = this.normalizeAngle(angle);
      let intrudedPointX = basePoint[0] + distance * Math.cos(angle);
      let intrudedPointY = basePoint[1] - distance * Math.sin(angle);
      let intrudedPoint = [intrudedPointX, intrudedPointY];
      return intrudedPoint;
    } else {
      return basePoint;
    }
  }

  calcLabelPoint(basePoint, labelDimension, angle, lineCount) {
    let distance = LABEL_DISTANCE + ((lineCount || 1) - 1) * 0.09;
    let direction = "east";
    if (angle <= -Math.PI + ANGLE_EPSILON) {
      direction = "east";
    } else if (angle <= -Math.PI / 2 - ANGLE_EPSILON) {
      direction = "northEast";
    } else if (angle <= -Math.PI / 2 + ANGLE_EPSILON) {
      direction = "north";
    } else if (angle <= -ANGLE_EPSILON) {
      direction = "northWest";
    } else if (angle <= ANGLE_EPSILON) {
      direction = "west";
    } else if (angle <= Math.PI / 2 - ANGLE_EPSILON) {
      direction = "southWest";
    } else if (angle <= Math.PI / 2 + ANGLE_EPSILON) {
      direction = "south";
    } else if (angle <= Math.PI - ANGLE_EPSILON) {
      direction = "southEast";
    } else {
      direction = "east";
    }
    let x = basePoint[0] + Math.cos(angle) * distance + labelDimension.northWest[0] - labelDimension[direction][0];
    let y = basePoint[1] - Math.sin(angle) * distance + labelDimension.northWest[1] - labelDimension[direction][1];
    return [x, y];
  }

  parseEdgeConfig(string, graphic, cellElements, arrowElements) {
    let config = null;
    let match = string.match(/(?:(\d+)|([A-Za-z]\w*))(?:\:(\w+))?/);
    if (match) {
      let element = null;
      if (match[1]) {
        let number = parseInt(match[1]) - 1;
        element = cellElements[number];
      } else if (match[2]) {
        let candidates = cellElements.map((candidate) => candidate.parentNode).concat(arrowElements);
        let name = match[2];
        element = candidates.find((candidate) => candidate.getAttribute("data-name") == name);
      }
      if (element) {
        let dimension = this.calcDimension(graphic, element);
        let point = null;
        if (match[3]) {
          point = this.parsePoint(match[3], dimension);
        }
        config = {element, dimension, point};
      }
    }
    return config;
  }

  parsePoint(string, dimension) {
    let point = null;
    let match;
    if (match = string.match(/^n(|w|e)|s(|w|e)|w|e|c$/)) {
      if (string == "nw") {
        point = dimension.northWestMargined;
      } else if (string == "n") {
        point = dimension.northMargined;
      } else if (string == "ne") {
        point = dimension.northEastMargined;
      } else if (string == "e") {
        point = dimension.eastMargined;
      } else if (string == "se") {
        point = dimension.southEastMargined;
      } else if (string == "s") {
        point = dimension.southMargined;
      } else if (string == "sw") {
        point = dimension.southWestMargined;
      } else if (string == "w") {
        point = dimension.westMargined;
      } else if (string == "c") {
        point = dimension.center;
      }
    } else if (match = string.match(/^(t|r|b|l)([\d.]+)$/)) {
      let direction = match[1];
      let position = parseFloat(match[2]) / 100;
      let pointX = null;
      let pointY = null;
      if (direction == "t") {
        pointX = (1 - position) * dimension.northWestMargined[0] + position * dimension.northEastMargined[0];
        pointY = dimension.northMargined[1];
      } else if (direction == "r") {
        pointX = dimension.eastMargined[0];
        pointY = (1 - position) * dimension.northEastMargined[1] + position * dimension.southEastMargined[1];
      } else if (direction == "b") {
        pointX = (1 - position) * dimension.southWestMargined[0] + position * dimension.southEastMargined[0];
        pointY = dimension.southMargined[1];
      } else if (direction == "l") {
        pointX = dimension.westMargined[0];
        pointY = (1 - position) * dimension.northWestMargined[1] + position * dimension.southWestMargined[1];
      }
      if (pointX != null && pointY != null) {
        point = [pointX, pointY];
      }
    }
    return point;
  }

  parseTipKinds(string, lineCount) {
    let tipKinds = {start: "none", end: "normal"};
    if (string != null) {
      let specifiedTipKinds = string.split(/\s*,\s*/);
      for (let specifiedTipKind of specifiedTipKinds) {
        let spec = DATA["arrow"][specifiedTipKind];
        if (spec) {
          tipKinds[spec.edge] = specifiedTipKind;
        }
        if (specifiedTipKind == "none") {
          tipKinds.end = "none";
        }
      }
    }
    if (lineCount == 2) {
      if (tipKinds.start != "none") {
        tipKinds.start = "d" + tipKinds.start;
      }
      if (tipKinds.end != "none") {
        tipKinds.end = "d" + tipKinds.end;
      }
    } else if (lineCount == 3) {
      if (tipKinds.start != "none") {
        tipKinds.start = "t" + tipKinds.start;
      }
      if (tipKinds.end != "none") {
        tipKinds.end = "t" + tipKinds.end;
      }
    }
    return tipKinds;
  }

  calcAngle(basePoint, destinationPoint) {
    let x = destinationPoint[0] - basePoint[0];
    let y = destinationPoint[1] - basePoint[1];
    let angle = -Math.atan2(y, x);
    return angle;
  }

  normalizeAngle(angle) {
    let normalizedAngle = (angle + Math.PI) % (Math.PI * 2) - Math.PI;
    return normalizedAngle;
  }

  createArrows(arrowSpec, backgroundColor) {
    let startPoint = arrowSpec.intrudedStartPoint;
    let endPoint = arrowSpec.intrudedEndPoint;
    let bendAngle = arrowSpec.bendAngle;
    let lineCount = (arrowSpec.lineCount == undefined) ? 1 : arrowSpec.lineCount;
    let command = "M " + startPoint[0] + " " + startPoint[1];
    if (bendAngle != undefined) {
      let controlPoint = this.calcControlPoint(startPoint, endPoint, bendAngle)
      command += " Q " + controlPoint[0] + " " + controlPoint[1] + ", " + endPoint[0] + " " + endPoint[1];
    } else {
      command += " L " + endPoint[0] + " " + endPoint[1];
    }
    let arrows = [];
    for (let i = 0 ; i < lineCount ; i ++) {
      let arrow = this.createSvgElement("path");
      arrow.setAttribute("d", command);
      if (arrowSpec.tipKinds.start != "none" && i == lineCount - 1) {
        arrow.setAttribute("marker-start", "url(#tip-" + arrowSpec.tipKinds.start +")");
      }
      if (arrowSpec.tipKinds.end != "none" && i == lineCount - 1) {
        arrow.setAttribute("marker-end", "url(#tip-" + arrowSpec.tipKinds.end + ")");
      }
      if (arrowSpec.dashed && i % 2 == 0) {
        arrow.classList.add("dashed");
      }
      if (i == 0) {
        arrow.classList.add("base");
      } else if (i == 1) {
        arrow.classList.add("cover");
        arrow.style.stroke = backgroundColor;
      } else if (i == 2) {
        arrow.classList.add("front");
      }
      if (lineCount == 2) {
        arrow.classList.add("double");
      } else if (lineCount == 3) {
        arrow.classList.add("triple");
      }
      arrows.push(arrow);
    }
    return arrows;
  }

  calcControlPoint(startPoint, endPoint, bendAngle) {
    let x = (endPoint[0] + startPoint[0] + (endPoint[1] - startPoint[1]) * Math.tan(bendAngle)) / 2;
    let y = (endPoint[1] + startPoint[1] - (endPoint[0] - startPoint[0]) * Math.tan(bendAngle)) / 2;
    return [x, y];
  }

  calcExtrusion(graphic, elements) {
    let fontSize = this.getFontSize(graphic);
    let xOffset =  window.pageXOffset;
    let yOffset =  window.pageYOffset;
    let graphicRect = graphic.getBoundingClientRect();
    let graphicTop = graphicRect.top + yOffset
    let graphicBottom = graphicRect.bottom + yOffset;
    let graphicLeft = graphicRect.left + xOffset;
    let graphicRight = graphicRect.right + xOffset;
    let extrusion = {top: 0, bottom: 0, left: 0, right: 0};
    for (let element of elements) {
      let rect = element.getBoundingClientRect();
      let topExtrusion = -(rect.top + yOffset - graphicTop) / fontSize;
      let bottomExtrusion = (rect.bottom + yOffset - graphicBottom) / fontSize;
      let leftExtrusion = -(rect.left + xOffset - graphicLeft) / fontSize;
      let rightExtrusion = (rect.right + xOffset - graphicRight) / fontSize;
      if (topExtrusion > extrusion.top) {
        extrusion.top = topExtrusion;
      }
      if (bottomExtrusion > extrusion.bottom) {
        extrusion.bottom = bottomExtrusion;
      }
      if (leftExtrusion > extrusion.left) {
        extrusion.left = leftExtrusion;
      }
      if (rightExtrusion > extrusion.right) {
        extrusion.right = rightExtrusion;
      }
    }
    return extrusion;
  }

  createGraphic(element) {
    let width = this.getWidth(element);
    let height = this.getHeight(element);
    let graphic = this.createSvgElement("svg");
    graphic.setAttribute("viewBox", "0 0 " + width + " " + height);
    let definitionElement = this.createSvgElement("defs");
    let tipSpecKeys = Object.keys(DATA["arrow"]);
    for (let tipSpecKey of tipSpecKeys) {
      let tipSpec = DATA["arrow"][tipSpecKey];
      let markerElement = this.createSvgElement("marker");
      let markerPathElement = this.createSvgElement("path");
      markerElement.setAttribute("id", "tip-" + tipSpecKey);
      markerElement.setAttribute("refX", tipSpec["x"]);
      markerElement.setAttribute("refY", tipSpec["y"]);
      markerElement.setAttribute("markerWidth", tipSpec["width"]);
      markerElement.setAttribute("markerHeight", tipSpec["height"]);
      markerElement.setAttribute("markerUnits", "userSpaceOnUse");
      markerElement.setAttribute("orient", "auto");
      markerPathElement.setAttribute("d", tipSpec["command"]);
      markerElement.appendChild(markerPathElement);
      definitionElement.appendChild(markerElement);
    }
    graphic.appendChild(definitionElement);
    return graphic;
  }

  createSvgElement(name) {
    let element = document.createElementNS("http://www.w3.org/2000/svg", name);
    return element;
  }

  calcDimension(graphic, element) {
    let dimension = {};
    let margin = ARROW_MARGIN;
    let fontSize = this.getFontSize(graphic)
    let graphicTop = graphic.getBoundingClientRect().top + window.pageYOffset;
    let graphicLeft = graphic.getBoundingClientRect().left + window.pageXOffset;
    let top = (element.getBoundingClientRect().top + window.pageYOffset - graphicTop) / fontSize;
    let left = (element.getBoundingClientRect().left + window.pageXOffset - graphicLeft) / fontSize;
    let width = this.getWidth(element, graphic);
    let height = this.getHeight(element, graphic);
    let lowerHeight = this.getLowerHeight(element, graphic);
    dimension.northWest = [left, top];
    dimension.north = [left + width / 2, top];
    dimension.northEast = [left + width, top];
    dimension.west = [left, top + height - lowerHeight];
    dimension.center = [left + width / 2, top + height - lowerHeight];
    dimension.east = [left + width, top + height - lowerHeight];
    dimension.southWest = [left, top + height];
    dimension.south = [left + width / 2, top + height];
    dimension.southEast = [left + width, top + height];
    dimension.northWestMargined = [left - margin, top - margin];
    dimension.northMargined = [left + width / 2, top - margin];
    dimension.northEastMargined = [left + width + margin, top - margin];
    dimension.westMargined = [left - margin, top + height - lowerHeight];
    dimension.centerMargined = [left + width / 2, top + height - lowerHeight];
    dimension.eastMargined = [left + width + margin, top + height - lowerHeight];
    dimension.southWestMargined = [left - margin, top + height + margin];
    dimension.southMargined = [left + width / 2, top + height + margin];
    dimension.southEastMargined = [left + width + margin, top + height + margin];
    return dimension;
  }

  getBackgroundColor(element) {
    let currentElement = element;
    let color = "white";
    while (currentElement && currentElement instanceof Element) {
      let currentColor = window.getComputedStyle(currentElement).backgroundColor;
      if (currentColor != "rgba(0, 0, 0, 0)" && currentColor != "transparent") {
        color = currentColor;
        break;
      }
      currentElement = currentElement.parentNode;
    }
    return color;
  }

}