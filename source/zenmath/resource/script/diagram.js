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
    let placeConfig = arrowElement.getAttribute("data-place");
    let match = placeConfig.match(/(\d+)(?:\.(\w+))?-(\d+)(?:\.(\w+))?/);
    if (match) {
      let startElement = cellElements[parseInt(match[1]) - 1];
      let endElement = cellElements[parseInt(match[3]) - 1];
      let startDimension = this.calcDimension(graphic, startElement);
      let endDimension = this.calcDimension(graphic, endElement);
      let startPoint = null;
      let endPoint = null;
      if (match[2]) {
        startPoint = startDimension[this.parseDirection(match[2])];
      } else {
        startPoint = this.calcEdgePoint(startDimension, endDimension);
      }
      if (match[4]) {
        endPoint = endDimension[this.parseDirection(match[4])];
      } else {
        endPoint = this.calcEdgePoint(endDimension, startDimension);
      }
      return {startPoint, endPoint};
    } else {
      let startPoint = [0, 0];
      let endPoint = [0, 0];
      return {startPoint, endPoint};
    }
  }

  determineLabelPoint(graphic, labelElement, arrowSpec) {
    let labelDimension = this.calcDimension(graphic, labelElement);
    let startPoint = arrowSpec.startPoint;
    let endPoint = arrowSpec.endPoint;
    let basePoint = [(startPoint[0] + endPoint[0]) / 2, (startPoint[1] + endPoint[1]) / 2];
    let angle = this.calcAngle(startPoint, endPoint) + Math.PI / 2;
    if (labelElement.getAttribute("inv")) {
      angle += Math.PI;
    }
    if (angle > Math.PI) {
      angle -= Math.PI * 2;
    }
    let point = this.calcLabelPoint(basePoint, labelDimension, angle);
    return point;
  }

  calcEdgePoint(baseDimension, destinationDimension) {
    let margin = 5 / 18;
    let angle = this.calcAngle(baseDimension.center, destinationDimension.center);
    let southWestAngle = this.calcAngle(baseDimension.center, baseDimension.southWest);
    let southEastAngle = this.calcAngle(baseDimension.center, baseDimension.southEast);
    let northEastAngle = this.calcAngle(baseDimension.center, baseDimension.northEast);
    let northWestAngle = this.calcAngle(baseDimension.center, baseDimension.northWest);
    let x = 0;
    let y = 0;
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

  createArrow(arrowSpec) {
    let startPoint = arrowSpec.startPoint;
    let endPoint = arrowSpec.endPoint;
    let arrow = this.createSvgElement("path");
    arrow.setAttribute("d", "M " + startPoint[0] + " " + startPoint[1] + " L " + endPoint[0] + " " + endPoint[1]);
    arrow.setAttribute("marker-end", "url(#tip-normal)");
    return arrow;
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