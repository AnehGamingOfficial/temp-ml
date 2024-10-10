  document.addEventListener('contextmenu', function(e) {
  e.preventDefault();
}, false);

document.onkeydown = function(e) {
  if (e.keyCode == 123 || (e.ctrlKey && e.shiftKey && e.keyCode == 'I'.charCodeAt(0))) {
    return false;
  }
}
