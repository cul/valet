
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



# # LOTS of logic specific to ReCAP requests,
# # to support multiple-offsite-holdings situation
# $ ->
#   $('.recap_holding_detail').click ->
#
#     # First, re-enable the clicked holding
#     click_target_id = this.id
#     $(this).find('.item_check_box').prop('disabled', false)
#
#     # Next, clear and disable all checkboxs in all other holdings
#     $('.all_recap_holding_details .recap_holding_detail').each ->
#       if this.id != click_target_id
#         $(this).find('.item_check_box').each ->
#           $(this).prop('checked', false)
#           $(this).prop('disabled', true)
#
#     # AND ALSO
#     # our hidden form params need to be set to
#     # the values of the clicked holding
#     location_code = $(this).data('location-code')
#     $('input[name=location_code]').val(location_code)
#
#     customer_code = $(this).data('customer-code')
#     $('input[name=customer_code]').val(customer_code)
#
#
