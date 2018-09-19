
function close_popup_button() {
  // If we're inside a pop-up window, 
  if (window.opener && window.opener != window) {
    button = '<button type="button" onclick="window.close();">Close Window</button>';
    buttonDiv = document.getElementById('close_popup_button');
    if (typeof(buttonDiv) != 'undefined' && buttonDiv != null) {
      buttonDiv.innerHTML = button;
    }
  }
}