//


const DIRECTIONS = ["west", "southWest", "south", "southEast", "east", "northEast", "north", "northWest"];
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
      let startDirection = this.parseDirection(match[2]) || this.determineDirection(startDimension, endDimension);
      let endDirection = this.parseDirection(match[4]) || this.determineDirection(endDimension, startDimension);
      let startPoint = startDimension[startDirection];
      let endPoint = endDimension[endDirection];
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

  calcLabelPoint(basePoint, labelDimension, angle) {
    let distance = 5 / 18;
    let epsilon = Math.PI / 90;
    let direction = "realEast";
    if (angle <= -Math.PI + epsilon) {
      direction = "realEast";
    } else if (angle <= -Math.PI / 2 - epsilon) {
      direction = "realNorthEast";
    } else if (angle <= -Math.PI / 2 + epsilon) {
      direction = "realNorth";
    } else if (angle <= -epsilon) {
      direction = "realNorthWest";
    } else if (angle <= epsilon) {
      direction = "realWest";
    } else if (angle <= Math.PI / 2 - epsilon) {
      direction = "realSouthWest";
    } else if (angle <= Math.PI / 2 + epsilon) {
      direction = "realSouth";
    } else if (angle <= Math.PI - epsilon) {
      direction = "realSouthEast";
    } else {
      direction = "realEast";
    }
    let x = basePoint[0] + Math.cos(angle) * distance + labelDimension.realNorthWest[0] - labelDimension[direction][0];
    let y = basePoint[1] - Math.sin(angle) * distance + labelDimension.realNorthWest[1] - labelDimension[direction][1];
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

  determineDirection(baseDimension, destinationDimension) {
    let angle = this.calcAngle(baseDimension.center, destinationDimension.center);
    let direction = "west";
    for (let i = 0 ; i < 8 ; i ++) {
      let firstAngle = (i == 0) ? -Math.PI : this.calcAngle(baseDimension.center, baseDimension[DIRECTIONS[i]]);
      let secondAngle = (i == 7) ? Math.PI : this.calcAngle(baseDimension.center, baseDimension[DIRECTIONS[i + 1]]);
      let maxAngle = (firstAngle + secondAngle) / 2;
      if (angle <= maxAngle) {
        direction = DIRECTIONS[i];
        break;
      }
    }
    return direction;
  }

  calcAngle(baseCoords, destinationCoords) {
    let x = destinationCoords[0] - baseCoords[0];
    let y = destinationCoords[1] - baseCoords[1];
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
    let margin = 5 / 18;
    dimension.northWest = [left - margin, top - margin];
    dimension.north = [left + width / 2, top - margin];
    dimension.northEast = [left + width + margin, top - margin];
    dimension.west = [left - margin, top + height - lowerHeight];
    dimension.center = [left + width / 2, top + height - lowerHeight];
    dimension.east = [left + width + margin, top + height - lowerHeight];
    dimension.southWest = [left - margin, top + height + margin];
    dimension.south = [left + width / 2, top + height + margin];
    dimension.southEast = [left + width + margin, top + height + margin];
    dimension.realNorthWest = [left, top];
    dimension.realNorth = [left + width / 2, top];
    dimension.realNorthEast = [left + width, top];
    dimension.realWest = [left, top + height - lowerHeight];
    dimension.realCenter = [left + width / 2, top + height - lowerHeight];
    dimension.realEast = [left + width, top + height - lowerHeight];
    dimension.realSouthWest = [left, top + height];
    dimension.realSouth = [left + width / 2, top + height];
    dimension.realSouthEast = [left + width, top + height];
    return dimension;
  }

}