
@validateAveryOnsiteRequestForm = () ->

  # accumulate error messages as we go, alert once at the end
  errors = []
  
  # How many item barcodes in total?
  barcodes = $('input[name="itemBarcodes[]"]')
  barcodes_count = barcodes.length
  # How many item barcodes are checked?
  checked_barcodes = $('input[name="itemBarcodes[]"]:checked')
  checked_barcodes_count = checked_barcodes.length
  
  # If there are zero barcodes, that's OK for certain Avery items
  # But if there are barcodes, at least one needs to be checked
  if barcodes_count > 0 && checked_barcodes_count < 1
    errors.push "  * You must select at least one barcode."

  # Avery Onsite use requires a seat reservation
  if ($('#seatNumber').val().length == 0) || ($('#seatDate').val().length == 0) || ($('#seatTime').val().length == 0)
    errors.push "  * You must fill in your seat reservation details (seat number, date, and time) before making an On-Site Use request"
  
  # IF WE HAVE ERRORS, alert the user, and fail the form validation
  if errors.length > 0
    message = "Please correct the following before submitting this form:\n\n"
    message = message + errors.join("\n")
    # message = message + "\n\nFor citation assistance please contact a reference librarian:\n"
    # message = message + "http://library.columbia.edu/research/askalibrarian.html"
    alert message
    return false

  # IF WE HAVE NO ERROR - return true, let the form proceed
  return true
