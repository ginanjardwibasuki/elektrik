// Call the dataTables jQuery plugin
$(document).ready(function() {
  $('#dataTable').DataTable({
	"pagingType": "simple",
	"pageLength": 6,
	"deferRender": true,
	"paging": true,
    "lengthMenu": [[6, 10, -1], [6, 10, "All"]],
	"scrollY":        false,
    "scrollX":        false
  });
  var dataTable = $('#dataTable').dataTable();
    $("#searchbox").on( "focus", function() {
	  
	  setTimeout(
  function() 
  {
    window.scrollTo(0, document.body.scrollHeight);
  }, 500);
	});
	$("#searchbox").keyup(function() {
        dataTable.fnFilter(this.value);
		window.scrollTo(0, document.body.scrollHeight);
    }); 
});
