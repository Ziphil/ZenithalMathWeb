//


function modifyUnderover(element) {
  let underElement = element.children[1].children[1];
  let overElement = element.children[0];
  if (underElement.children.length > 0) {
    element.classList.add("under");
  } else {
    underElement.parentNode.removeChild(underElement);
  }
  if (overElement.children.length > 0) {
    element.classList.add("over");
  } else {
    element.removeChild(overElement);
  }
}