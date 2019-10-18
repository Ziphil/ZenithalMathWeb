//


const DIRECTIONS = ["west", "southWest", "south", "southEast", "east", "northEast", "north", "northWest"];
const ARROW_TIP_SPECS = {
  normal: {refX: 6, refY: 4, width: 7, height: 8, command: "M 1 1 L 6 4 L 1 7"}
}


class DiagramModifier extends Modifier {

  modify(element) {
    let cellElements = Array.from(element.children).filter((child) => child.localName == "math-cellwrap").map((child) => child.children[0]);
    let arrowElements = Array.from(element.children).filter((child) => child.localName == "math-arrow");
    let graphic = this.createGraphic(element);
    element.appendChild(graphic);
    for (let arrowElement of arrowElements) {
      let placeConfig = arrowElement.getAttribute("data-place");
      let match;
      if (match = placeConfig.match(/(\d+)(?:\.(\w+))?-(\d+)(?:\.(\w+))?/)) {
        let startElement = cellElements[parseInt(match[1]) - 1];
        let endElement = cellElements[parseInt(match[3]) - 1];
        let startDimension = this.calcDimension(graphic, startElement);
        let endDimension = this.calcDimension(graphic, endElement);
        let startPosition = this.parsePosition(match[2]) || this.determinePosition(startDimension, endDimension);
        let endPosition = this.parsePosition(match[4]) || this.determinePosition(endDimension, startDimension);
        let arrow = this.createArrow(startDimension, endDimension, startPosition, endPosition);
        graphic.appendChild(arrow);
        let arrowDimension = this.calcDimension(graphic, arrowElement, graphic);
        let startPoint = startDimension[startPosition];
        let endPoint = endDimension[endPosition];
        let basePoint = [(startPoint[0] + endPoint[0]) / 2, (startPoint[1] + endPoint[1]) / 2];
        let angle = this.calcAngle(startPoint, endPoint) + Math.PI / 2;
        if (angle > Math.PI) {
          angle -= Math.PI * 2;
        }
        let point = this.calcLabelPoint(basePoint, arrowDimension, angle);
        arrowElement.style.top = "" + (point.top / 0.8) + "em";
        arrowElement.style.left = "" + (point.left / 0.8) + "em";
      }
    }
  }

  parsePosition(string) {
    let position = null;
    if (string == "west" || string == "w") {
      position = "west";
    } else if (string == "southwest" || string == "sw") {
      position = "southWest";
    } else if (string == "south" || string == "s") {
      position = "south";
    } else if (string == "southeast" || string == "se") {
      position = "southEast";
    } else if (string == "east" || string == "e") {
      position = "east";
    } else if (string == "northeast" || string == "ne") {
      position = "northEast";
    } else if (string == "north" || string == "n") {
      position = "north";
    } else if (string == "northwest" || string == "nw") {
      position = "northWest";
    }
    return position;
  }

  determinePosition(baseDimension, destinationDimension) {
    let angle = this.calcAngle(baseDimension.center, destinationDimension.center);
    let position = "west";
    for (let i = 0 ; i < 8 ; i ++) {
      let firstAngle = (i == 0) ? -Math.PI : this.calcAngle(baseDimension.center, baseDimension[DIRECTIONS[i]]);
      let secondAngle = (i == 7) ? Math.PI : this.calcAngle(baseDimension.center, baseDimension[DIRECTIONS[i + 1]]);
      let maxAngle = (firstAngle + secondAngle) / 2;
      if (angle <= maxAngle) {
        position = DIRECTIONS[i];
        break;
      }
    }
    return position;
  }

  calcLabelPoint(basePoint, labelDimension, angle) {
    let distance = 5 / 18;
    let epsilon = Math.PI / 90;
    let position = "realEast";
    if (angle <= -Math.PI + epsilon) {
      position = "realEast";
    } else if (angle <= -Math.PI / 2 - epsilon) {
      position = "realNorthEast";
    } else if (angle <= -Math.PI / 2 + epsilon) {
      position = "realNorth";
    } else if (angle <= -epsilon) {
      position = "realNorthWest";
    } else if (angle <= epsilon) {
      position = "realWest";
    } else if (angle <= Math.PI / 2 - epsilon) {
      position = "realSouthWest";
    } else if (angle <= Math.PI / 2 + epsilon) {
      position = "realSouth";
    } else if (angle <= Math.PI - epsilon) {
      position = "realSouthEast";
    } else {
      position = "realEast";
    }
    let top = basePoint[1] - Math.sin(angle) * distance + labelDimension.realNorthWest[1] - labelDimension[position][1];
    let left = basePoint[0] + Math.cos(angle) * distance + labelDimension.realNorthWest[0] - labelDimension[position][0];
    return {top, left};
  }

  calcAngle(baseCoords, destinationCoords) {
    let x = destinationCoords[0] - baseCoords[0];
    let y = destinationCoords[1] - baseCoords[1];
    let angle = -Math.atan2(y, x);
    return angle;
  }

  createArrow(startDimension, endDimension, startPosition, endPosition) {
    let startCoords = startDimension[startPosition];
    let endCoords = endDimension[endPosition];
    let arrow = this.createSvgElement("path");
    arrow.setAttribute("d", "M " + startCoords[0] + " " + startCoords[1] + " L " + endCoords[0] + " " + endCoords[1]);
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

  calcDimension(graphic, element, fontElement) {
    let dimension = {};
    let fontSize = this.getFontSize(fontElement || element)
    let graphicTop = graphic.getBoundingClientRect().top + window.pageYOffset;
    let graphicLeft = graphic.getBoundingClientRect().left + window.pageXOffset;
    let top = (element.getBoundingClientRect().top + window.pageYOffset - graphicTop) / fontSize;
    let left = (element.getBoundingClientRect().left + window.pageXOffset - graphicLeft) / fontSize;
    let width = this.getWidth(element, fontElement);
    let height = this.getHeight(element, fontElement);
    let lowerHeight = this.getLowerHeight(element, fontElement);
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