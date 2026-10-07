$(document).ready(function() {
    $("html, body").animate({ scrollTop: $(document).height() }, 1000);
    
    var table = $('#dataTable').DataTable({
        "processing": true,
        "serverSide": true,
        "lengthChange": false,
        "pagingType": "simple",
        "pageLength": 4,
        "deferRender": true,
        "paging": true,
        "autoWidth": false,
        "ajax": "datatables_php/get_dtc.php",
		"language": {
			"lengthMenu": "Tampilkan _MENU_ entri",
			"zeroRecords": "Tidak ditemukan data yang cocok",
			"info": "Data _START_ - _END_ dari total _TOTAL_ entri",
			"infoEmpty": "Data 0 - 0 dari 0 entri",
			"infoFiltered": "(difilter dari total _MAX_ entri)",
		},
columns: [
    {
      data: "node",
      render: function(data, type, row) {
        return `
          <div style="text-align:left;">
            <div style="font-weight:600; font-size:15px; color:#2c3e50;">${row.node}</div>
            <div style="font-size:13px; color:#5dade2; font-style:italic;">${row.dtc_iso}</div>
          </div>
        `;
      }
    },
    { data: "dtc_iso", visible: false },
    {
      data: "proprietary_name",
      render: function(data) {
        return `<div class="gradient-box" title="${data}">${data}</div>`;
      }
    },
    {
  data: null,
  render: function(_, __, row) {
    return `
      <button onclick="openDetailModal(
        '${row.node}', '${row.dtc_iso}', '${row.proprietary_name}',
        '${row.ftb_name}', '${row.failure_event}', 
        '${row.possible_root_cause}', '${row.workshop_action}'
      )" style="
        background: linear-gradient(to right, #d6eaf8, #aed6f1);
        border: none;
        border-radius: 50%;
        padding: 10px;
        font-size: 16px;
        color: #2c3e50;
        box-shadow: 0 2px 6px rgba(0,0,0,0.1);
        transition: all 0.3s ease;
        display: inline-flex;
        align-items: center;
        justify-content: center;
      "
      onmouseover="this.style.transform='scale(1.15)'"
      onmouseout="this.style.transform='scale(1)'">
        🔎
      </button>
    `;
  }
}
  ],
	"columnDefs": [
	  { "targets": 0, "width": "14%", "searchable": true, "orderable": false },
	  { "targets": 1, "visible": false, "searchable": true, "orderable": false },
	  { "targets": 2, "searchable": true, "width": "50%" },
	  { "targets": 3, "searchable": false, "orderable": false, "width": "10%" }
	]
    });
	
    $('#searchbox').on('keyup', function(){
        table.search(this.value).draw();
        $('#dataTable_filter input').val(this.value);
    });
	
});