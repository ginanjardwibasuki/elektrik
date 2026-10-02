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
		"searching": false,
		"info": false,
		"autoWidth": false,
		headerCallback: function(thead) {$(thead).find('th').each(function(index) {if ([0,1, 2, 3, 4].includes(index)) $(this).hide();});},
        "ajax": "datatables_php/get_battery.php",
        "columns": [
            { "data": "id" },
            { 
                "data": "pic",
				"createdCell": function(td) {
					$(td).attr("style", "white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100px;");
				},
                "render": function(data, type, row) {
                    return data.split(" ")[1] || data; // Ambil kata kedua setelah angka
                }
            },
            { "data": "unit" },
            { "data": "status" },
            {
				"data": "tanggal",
				"render": function(data, type, row) {
					let date = new Date(data);
					let formattedDate = date.toLocaleDateString('id-ID', { 
						day: '2-digit', 
						month: '2-digit', 
						year: '2-digit' 
					}).replace(/\//g, '-'); // Mengubah '/' menjadi '-'
					return formattedDate;
				}
			}
        ],
		columnDefs: [
            { targets: 0, visible: false },
			{ targets: 1, width: "20%"},
			{
                targets: 2, width: "25%",
                render: function(data) {
					return `HT ${data}`;
				}

            },
			{
				targets: 3, width: "25%",
				render: function(data) {
					let color = "secondary";

					if (data === "proses") {
						color = "info";
					} else if (data === "selesai") {
						color = "success";
					}

					return `<span class="badge bg-${color}">${data}</span>`;
				}
			},
			{ targets: 4, width: "30%"}
        ],
        "order": [[0, 'desc']]
    });
});