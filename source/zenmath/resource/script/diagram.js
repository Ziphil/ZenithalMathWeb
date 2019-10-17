//


function modifyDiagram(element) {
  cellElements = Array.from(element.children).filter((element) => element.localName == "math-cell");
  arrowElements = Array.from(element.children).filter((element) => element.localName == "math-arrow");
  let graphic = createDiagramGraphic(element);
  element.appendChild(graphic);
  for (let arrowElement of arrowElements) {
    let placeConfig = arrowElement.getAttribute("data-place");
    let match;
    if (match = placeConfig.match(/(\d+)-(\d+)/)) {
      let startPlace = match[1];
      let endPlace = match[2];
      let startElement = cellElements[parseInt(startPlace) - 1];
      let endElement = cellElements[parseInt(endPlace) - 1];
      let arrow = createDiagramArrow(graphic, startElement, endElement, "east", "west");
      graphic.appendChild(arrow);
    }
  }
}

function createDiagramArrow(graphic, startElement, endElement, startPosition, endPosition) {
  let startDimension = calcDiagramDimension(graphic, startElement);
  let endDimension = calcDiagramDimension(graphic, endElement);
  let startCoords = startDimension[startPosition];
  let endCoords = endDimension[endPosition];
  let arrow = createSvgElement("path");
  arrow.setAttribute("d", "M " + startCoords[0] + " " + startCoords[1] + " L " + endCoords[0] + " " + endCoords[1]);
  return arrow;
}

function createDiagramGraphic(element) {
  let width = getWidthPx(element);
  let height = getHeightPx(element);
  let graphic = createSvgElement("svg");
  graphic.setAttribute("width", width + "px");
  graphic.setAttribute("height", height + "px");
  graphic.setAttribute("viewBox", "0 0 " + width + " " + height);
  return graphic;
}

function createSvgElement(name) {
  let element = document.createElementNS("http://www.w3.org/2000/svg", name);
  return element;
}

function calcDiagramDimension(graphic, element) {
  let dimension = {};
  let graphicTop = graphic.getBoundingClientRect().top + window.pageYOffset;
  let graphicLeft = graphic.getBoundingClientRect().left + window.pageXOffset;
  let top = element.getBoundingClientRect().top + window.pageYOffset - graphicTop;
  let left = element.getBoundingClientRect().left + window.pageXOffset - graphicLeft;
  let width = getWidthPx(element);
  let height = getHeightPx(element);
  let lowerHeight = getLowerHeightPx(element);
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