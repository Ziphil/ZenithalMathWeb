//


const ANGLE_EPSILON = Math.PI / 90;

const UNIT = 1 / 18;
const ARROW_MARGIN = 8 * UNIT;
const LABEL_DISTANCE = 4 * UNIT;


class DiagramModifier extends Modifier {

  modify(element) {
    let arrowElements = Array.from(element.children).filter((child) => child.localName == "math-arrow");
    let cellElements = Array.from(element.children).filter((child) => child.localName == "math-cellwrap").map((child) => child.children[0]);
    let graphic = this.createGraphic(element);
    element.appendChild(graphic);
    for (let arrowElement of arrowElements) {
      let arrowSpec = this.determineArrowSpec(graphic, arrowElement, cellElements);
      let arrows = this.createArrows(arrowSpec);
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

  determineArrowSpec(graphic, arrowElement, cellElements) {
    let spec = {};
    let startConfigString = arrowElement.getAttribute("data-start");
    let endConfigString = arrowElement.getAttribute("data-end");
    let startConfig = this.parseEdgeConfig(startConfigString, graphic, cellElements);
    let endConfig = this.parseEdgeConfig(endConfigString, graphic, cellElements);
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
    let tipKindsString = arrowElement.getAttribute("data-tip");
    spec.tipKinds = this.parseTipKinds(tipKindsString, spec.lineCount);
    spec.startPoint = this.calcIntrudedPoint(spec.startPoint, spec.endPoint, spec.bendAngle, spec.tipKinds.start);
    spec.endPoint = this.calcIntrudedPoint(spec.endPoint, spec.startPoint, -spec.bendAngle, spec.tipKinds.end);
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
    if (labelElement.getAttribute("data-inv")) {
      angle += Math.PI;
    }
    angle = this.normalizeAngle(angle);
    let point = this.calcLabelPoint(basePoint, labelDimension, angle, arrowSpec.lineCount);
    return point;
  }

  calcEdgePoint(baseDimension, destinationDimension, bendAngle, shift) {
    let margin = ARROW_MARGIN;
    let angle = this.calcAngle(baseDimension.center, destinationDimension.center) + (bendAngle || 0);
    let shiftAngle = angle + Math.PI / 2;
    let southWestAngle = this.calcAngle(baseDimension.center, baseDimension.southWest);
    let southEastAngle = this.calcAngle(baseDimension.center, baseDimension.southEast);
    let northEastAngle = this.calcAngle(baseDimension.center, baseDimension.northEast);
    let northWestAngle = this.calcAngle(baseDimension.center, baseDimension.northWest);
    let x = 0;
    let y = 0;
    angle = this.normalizeAngle(angle);
    shiftAngle = this.normalizeAngle(shiftAngle);
    if (angle >= southWestAngle && angle <= southEastAngle) {
      x = baseDimension.center[0] + (baseDimension.center[1] - baseDimension.south[1]) / Math.tan(angle);
      y = baseDimension.south[1] + margin;
    } else if (angle >= southEastAngle && angle <= northEastAngle) {
      x = baseDimension.east[0] + margin;
      y = baseDimension.center[1] + (baseDimension.center[0] - baseDimension.east[0]) * Math.tan(angle);
    } else if (angle >= northEastAngle && angle <= northWestAngle) {
      x = baseDimension.center[0] + (baseDimension.center[1] - baseDimension.north[1]) / Math.tan(angle);
      y = baseDimension.north[1] - margin;
    } else if (angle >= northWestAngle || angle <= southWestAngle) {
      x = baseDimension.west[0] - margin;
      y = baseDimension.center[1] + (baseDimension.center[0] - baseDimension.west[0]) * Math.tan(angle);
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

  parseEdgeConfig(string, graphic, cellElements) {
    let match = string.match(/(\d+)(?:\.(\w+))?/);
    if (match) {
      let number = parseInt(match[1]) - 1;
      let element = cellElements[number];
      let dimension = this.calcDimension(graphic, element);
      let point = null;
      if (match[2]) {
        point = this.parsePoint(match[2], dimension);
      }
      return {element, dimension, point};
    } else {
      return null;
    }
  }

  parsePoint(string, dimension) {
    let margin = ARROW_MARGIN;
    let pointX = null;
    let pointY = null;
    let match;
    if (match = string.match(/^n(|w|e)|s(|w|e)|w|e$/)) {
      if (string == "nw") {
        pointX = dimension.northWest[0] - margin;
        pointY = dimension.northWest[1] - margin;
      } else if (string == "n") {
        pointX = dimension.north[0];
        pointY = dimension.north[1] - margin;
      } else if (string == "ne") {
        pointX = dimension.northEast[0] + margin;
        pointY = dimension.northEast[1] - margin;
      } else if (string == "e") {
        pointX = dimension.east[0] + margin;
        pointY = dimension.east[1];
      } else if (string == "se") {
        pointX = dimension.southEast[0] + margin;
        pointY = dimension.east[1] + margin;
      } else if (string == "s") {
        pointX = dimension.south[0];
        pointY = dimension.south[1] + margin;
      } else if (string == "sw") {
        pointX = dimension.southWest[0] - margin;
        pointY = dimension.southWest[1] + margin;
      } else if (string == "w") {
        pointX = dimension.west[0] - margin;
        pointY = dimension.west[1];
      }
    } else if (match = string.match(/^(t|r|b|l)([\d.]+)$/)) {
      let direction = match[1];
      let position = parseFloat(match[2]) / 100;
      if (direction == "t") {
        pointX = (1 - position) * dimension.northWest[0] + position * dimension.northEast[0];
        pointY = dimension.north[1] - margin;
      } else if (direction == "r") {
        pointX = dimension.east[0] + margin;
        pointY = (1 - position) * dimension.northEast[1] + position * dimension.southEast[1];
      } else if (direction == "b") {
        pointX = (1 - position) * dimension.southWest[0] + position * dimension.southEast[0];
        pointY = dimension.south[1] + margin;
      } else if (direction == "l") {
        pointX = dimension.west[0] - margin;
        pointY = (1 - position) * dimension.northWest[1] + position * dimension.southWest[1];
      }
    }
    if (pointX != null && pointY != null) {
      return [pointX, pointY];
    } else {
      return null;
    }
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

  createArrows(arrowSpec) {
    let startPoint = arrowSpec.startPoint;
    let endPoint = arrowSpec.endPoint;
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
    return dimension;
  }

}