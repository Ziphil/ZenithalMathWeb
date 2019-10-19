//


const ARROW_TIP_SPECS = {
  normal: {refX: 6, refY: 4, width: 7, height: 8, command: "M 1 1 L 6 4 L 1 7"}
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
  }

  determineArrowSpec(graphic, arrowElement, cellElements) {
    let spec = {};
    let startConfigString = arrowElement.getAttribute("data-start");
    let endConfigString = arrowElement.getAttribute("data-end");
    let startConfig = this.parseEdgeConfig(startConfigString, cellElements);
    let endConfig = this.parseEdgeConfig(endConfigString, cellElements);
    if (startConfig && endConfig) {
      let startElement = startConfig.element;
      let endElement = endConfig.element;
      let startDimension = this.calcDimension(graphic, startElement);
      let endDimension = this.calcDimension(graphic, endElement);
      let bendAngleString = arrowElement.getAttribute("data-bend");
      if (bendAngleString) {
        spec.bendAngle = parseFloat(bendAngleString) * Math.PI / 180;
      }
      if (startConfig.direction) {
        spec.startPoint = startDimension[startConfig.direction];
      } else {
        spec.startPoint = this.calcEdgePoint(startDimension, endDimension, spec.bendAngle);
      }
      if (endConfig.direction) {
        spec.endPoint = endDimension[endConfig.direction];
      } else {
        spec.endPoint = this.calcEdgePoint(endDimension, startDimension, -spec.bendAngle);
      }
    } else {
      spec.startPoint = [0, 0];
      spec.endPoint = [0, 0];
    }
    return spec;
  }

  determineLabelPoint(graphic, labelElement, arrowSpec) {
    let labelDimension = this.calcDimension(graphic, labelElement);
    let startPoint = arrowSpec.startPoint;
    let endPoint = arrowSpec.endPoint;
    let bendAngle = arrowSpec.bendAngle;
    let position = 0.5;
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
      basePoint = [(startPoint[0] + endPoint[0]) / 2, (startPoint[1] + endPoint[1]) / 2];
      angle = this.calcAngle(startPoint, endPoint) + Math.PI / 2;
    }
    if (labelElement.getAttribute("data-inv")) {
      angle += Math.PI;
    }
    angle = this.normalizeAngle(angle);
    let point = this.calcLabelPoint(basePoint, labelDimension, angle);
    return point;
  }

  calcEdgePoint(baseDimension, destinationDimension, bendAngle) {
    let margin = 5 / 18;
    let angle = this.calcAngle(baseDimension.center, destinationDimension.center) + (bendAngle || 0);
    let southWestAngle = this.calcAngle(baseDimension.center, baseDimension.southWest);
    let southEastAngle = this.calcAngle(baseDimension.center, baseDimension.southEast);
    let northEastAngle = this.calcAngle(baseDimension.center, baseDimension.northEast);
    let northWestAngle = this.calcAngle(baseDimension.center, baseDimension.northWest);
    let x = 0;
    let y = 0;
    angle = this.normalizeAngle(angle);
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

  parseEdgeConfig(string, cellElements) {
    let match = string.match(/(\d+)(?:\.(\w+))?/);
    if (match) {
      let number = parseInt(match[1]) - 1;
      let direction = this.parseDirection(match[2]);
      let element = cellElements[number];
      return {element, direction};
    } else {
      return null;
    }
  }

  parseDirection(string) {
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
    return direction;
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
    arrow.setAttribute("marker-end", "url(#tip-normal)");
    return arrow;
  }

  calcControlPoint(startPoint, endPoint, bendAngle) {
    let x = (endPoint[0] + startPoint[0] + (endPoint[1] - startPoint[1]) * Math.tan(bendAngle)) / 2;
    let y = (endPoint[1] + startPoint[1] - (endPoint[0] - startPoint[0]) * Math.tan(bendAngle)) / 2;
    return [x, y];
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