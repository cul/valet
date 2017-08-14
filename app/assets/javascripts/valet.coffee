

# When displaying the user-info panel inside
#  a drop-down nav menu, don't close menu on click,
#  leave open to let the user copy/paste/etc.
$ -> 
  $('.user-info').click (e) ->
    e.stopPropagation()

$ ->
  $('#log_file_table').DataTable( {
    pageLength: 100,
    lengthMenu: [ [20, 50, 100, -1], [20, 50, 100, "All"] ],
    dom: '<"top"flip>'
  } )




  