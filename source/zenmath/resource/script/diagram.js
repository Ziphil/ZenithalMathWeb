//


const UNIT = 1 / 18;
const ARROW_TIP_SPECS = {
  normal: {refX: 6, refY: 4, width: 7, height: 8, command: "M 1 1 L 6 4 L 1 7"},
  tail: {refX: 6, refY: 4, width: 7, height: 8, command: "M 1 1 L 6 4 L 1 7"}
}


class DiagramModifier extends Modifier {

  modify(element) {
    let arrowElements = Array.from(element.children).filter((child) => child.localName == "math-arrow");
    let cellElements = Array.from(element.children).filter((child) => child.localName == "math-cellwrap").map((child) => child.children[0]);
    let graphic = this.createGraphic(element);
    element.appendChild(graphic);
    for (let arrowElement of arrowElements) {
      let arrowSpec = this.determineArrowSpec(graphic, arrowElement, cellElements);
      let arrow = this.createArrow(arrowSpec);
      graphic.appendChild(arrow);
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
      let startElement = startConfig.element;
      let endElement = endConfig.element;
      let startDimension = startConfig.dimension;
      let endDimension = endConfig.dimension;
      let bendAngleString = arrowElement.getAttribute("data-bend");
      let shiftString = arrowElement.getAttribute("data-shift");
      let labelPositionString = arrowElement.getAttribute("data-pos");
      if (bendAngleString) {
        spec.bendAngle = parseFloat(bendAngleString) * Math.PI / 180;
      }
      if (shiftString) {
        spec.shift = parseFloat(shiftString) * UNIT;
      }
      if (labelPositionString) {
        spec.labelPosition = parseFloat(labelPositionString) / 100;
      }
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
    spec.startTipKind = arrowElement.getAttribute("data-start-tip") || "none";
    spec.endTipKind = arrowElement.getAttribute("data-end-tip") || "normal";
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
    let point = this.calcLabelPoint(basePoint, labelDimension, angle);
    return point;
  }

  calcEdgePoint(baseDimension, destinationDimension, bendAngle, shift) {
    let margin = 5 / 18;
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

  calcLabelPoint(basePoint, labelDimension, angle) {
    let distance = 5 / 18;
    let epsilon = Math.PI / 90;
    let direction = "east";
    if (angle <= -Math.PI + epsilon) {
      direction = "east";
    } else if (angle <= -Math.PI / 2 - epsilon) {
      direction = "northEast";
    } else if (angle <= -Math.PI / 2 + epsilon) {
      direction = "north";
    } else if (angle <= -epsilon) {
      direction = "northWest";
    } else if (angle <= epsilon) {
      direction = "west";
    } else if (angle <= Math.PI / 2 - epsilon) {
      direction = "southWest";
    } else if (angle <= Math.PI / 2 + epsilon) {
      direction = "south";
    } else if (angle <= Math.PI - epsilon) {
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
      let point = this.parsePoint(match[2], dimension);
      return {element, dimension, point};
    } else {
      return null;
    }
  }

  parsePoint(string, dimension) {
    let direction = null;
    if (string == "west" || string == "w") {
      direction = "west";
    } else if (string == "southwest" || string == "sw") {
      direction = "southWest";
    } else if (string == "south" || string == "s") {
      direction = "south";
    } else if (string == "southeast" || string == "se") {
      direction = "southEast";
    } else if (string == "east" || string == "e") {
      direction = "east";
    } else if (string == "northeast" || string == "ne") {
      direction = "northEast";
    } else if (string == "north" || string == "n") {
      direction = "north";
    } else if (string == "northwest" || string == "nw") {
      direction = "northWest";
    }
    let point = null;
    if (direction) {
      point = dimension[direction];
    }
    return point;
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

  createArrow(arrowSpec) {
    let startPoint = arrowSpec.startPoint;
    let endPoint = arrowSpec.endPoint;
    let bendAngle = arrowSpec.bendAngle;
    let command = "M " + startPoint[0] + " " + startPoint[1];
    if (bendAngle != undefined) {
      let controlPoint = this.calcControlPoint(startPoint, endPoint, bendAngle)
      command += " Q " + controlPoint[0] + " " + controlPoint[1] + ", " + endPoint[0] + " " + endPoint[1];
    } else {
      command += " L " + endPoint[0] + " " + endPoint[1];
    }
    let arrow = this.createSvgElement("path");
    arrow.setAttribute("d", command);
    if (arrowSpec.startTipKind != "none") {
      arrow.setAttribute("marker-start", "url(#tip-" + arrowSpec.startTipKind +")");
    }
    if (arrowSpec.endTipKind != "none") {
      arrow.setAttribute("marker-end", "url(#tip-" + arrowSpec.endTipKind +")");
    }
    return arrow;
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
    let tipSpecKeys = Object.keys(ARROW_TIP_SPECS);
    for (let tipSpecKey of tipSpecKeys) {
      let tipSpec = ARROW_TIP_SPECS[tipSpecKey];
      let markerElement = this.createSvgElement("marker");
      let markerPathElement = this.createSvgElement("path");
      markerElement.setAttribute("id", "tip-" + tipSpecKey);
      markerElement.setAttribute("refX", tipSpec.refX);
      markerElement.setAttribute("refY", tipSpec.refY);
      markerElement.setAttribute("markerWidth", tipSpec.width);
      markerElement.setAttribute("markerHeight", tipSpec.height);
      markerElement.setAttribute("orient", "auto");
      markerPathElement.setAttribute("d", tipSpec.command);
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