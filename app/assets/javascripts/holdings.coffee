
@validateHoldingsForm = () ->

  # accumulate error messages as we go, alert once at the end
  errors = []
  
  # Which holding is selected?
  selected_request_type = $('input[name="mfhd_id"]:checked').val()
  
  # One of them must be selected
  if selected_request_type == undefined
    errors.push "  * You must select a holding."

  # IF WE HAVE ERRORS, alert the user, and fail the form validation
  if errors.length > 0
    message = "Please correct the following before submitting this form:\n\n"
    message = message + errors.join("\n")
    alert message
    return false

  # IF WE HAVE NO ERROR - return true, let the form proceed
  return true
