
@validateAveryOnsiteRequestForm = () ->

  if ($('#seatNumber').val().length == 0) || ($('#seatDate').val().length == 0) || ($('#seatTime').val().length == 0)
    alert "You must fill in your seat reservation details (seat number, date, and time) before making an On-Site Use request"
    return false
  