//


const ARROW_TIP_SPECS = {
  normal: {refX: 5, refY: 3, width: 10, height: 6, command: "M 0 0 L 5 3 L 0 6"}
}

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
  arrow.setAttribute("marker-end", "url(#tip-normal)");
  return arrow;
}

function createDiagramGraphic(element) {
  let width = getWidthPx(element);
  let height = getHeightPx(element);
  let graphic = createSvgElement("svg");
  graphic.setAttribute("width", width + "px");
  graphic.setAttribute("height", height + "px");
  graphic.setAttribute("viewBox", "0 0 " + width + " " + height);
  let definitionElement = createSvgElement("defs");
  let tipSpecKeys = Object.keys(ARROW_TIP_SPECS);
  for (let tipSpecKey of tipSpecKeys) {
    let tipSpec = ARROW_TIP_SPECS[tipSpecKey];
    let markerElement = createSvgElement("marker");
    let markerPathElement = createSvgElement("path");
    markerElement.setAttribute("id", "tip-" + tipSpecKey);
    markerElement.setAttribute("refX", tipSpec.refX);
    markerElement.setAttribute("refY", tipSpec.refY);
    markerElement.setAttribute("markerWidth", tipSpec.width);
    markerElement.setAttribute("markerHeight", tipSpec.height);
    markerPathElement.setAttribute("d", tipSpec.command);
    markerElement.appendChild(markerPathElement);
    definitionElement.appendChild(markerElement);
  }
  graphic.appendChild(definitionElement);
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
  let margin = getFontSize(element) / 18 * 3;
  dimension.northWest = [left - margin, top - margin];
  dimension.north = [left + width / 2, top - margin];
  dimension.northEast = [left + width + margin, top - margin];
  dimension.west = [left - margin, top + height - lowerHeight];
  dimension.center = [left + width / 2, top + height - lowerHeight];
  dimension.east = [left + width + margin, top + height - lowerHeight];
  dimension.southWest = [left - margin, top + height + margin];
  dimension.south = [left + width / 2, top + height + margin];
  dimension.southEast = [left + width + margin, top + height + margin];
  return dimension;
}