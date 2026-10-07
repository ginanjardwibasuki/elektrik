$(document).ready(function() {
    var table = $('#dataTable').DataTable({
        "processing": true,
        "serverSide": true,
        "lengthChange": false,
        "pagingType": "simple",
        "pageLength": 6,
        "deferRender": true,
        "paging": true,
        "lengthMenu": [[6, 10, 15, 20], [6, 10, 15, 20]],
        "ajax": "datatables_php/get_sparepart.php",
        "columns": [
            {
                "data": "gambar",
                "render": function(data, type, row) {
                    var imageUrl = data ? data : 'assets/images/noimage.png';
                    return `
                        <img src="${imageUrl}" 
                             style="width:42px;height:42px;object-fit:cover;border-radius:10px;
                                    box-shadow:rgba(0,0,0,0.25) 3px 3px 3px,rgba(0,0,0,0.22) 0px 10px 10px;" 
                             onclick="openDataModal('${row.id}', '${row.name}', '${row.part_number}', '${row.vendor}', '${imageUrl}', '${row.keyword}', '${row.copy}')">
                    `;
                }
            },
            {
                "data": "name",
                "render": function(data, type, row) {
                    return `<strong>${data}</strong><br><span style="color:gray;">P/N: ${row.part_number}</span>`;
                }
            },
            {
                "data": null,
                "render": function(data, type, row) {
                    return `
                        <button class="btn btn-secondary btn-sm" onclick="copyText('${row.name}', '${row.part_number}')">
                            <i class="fas fa-copy"></i>
                        </button>
                    `;
                }
            },
            {
                "data": null,
                "render": function(data, type, row) {
                    return `
                        <button class="btn btn-primary btn-sm" style="margin-right:5px;" 
                                onclick="editData('${row.id}', '${row.gambar}', '${row.name}', '${row.part_number}', '${row.vendor}', '${row.keyword}')">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-danger btn-sm" onclick="deleteData('${row.id}', '${row.gambar}')">
                            <i class="fas fa-trash-alt"></i>
                        </button>
                    `;
                }
            },
            { "data": "id" },
            { "data": "part_number" },
            { "data": "vendor" },
            { "data": "keyword" }
        ],
        "columnDefs": [
            { "targets": 0, "width": "12%", "searchable": false },
            { "targets": 1, "width": "40%", "searchable": true, "orderable": true, "className": "custom-style truncate-text" },
            { "targets": 2, "width": "10%", "searchable": false, "orderable": false },
            { "targets": 3, "width": "20%", "searchable": false, "orderable": false, "className": "text-end" },
            { "targets": 4, "visible": false, "searchable": false, "orderable": false },
            { "targets": 5, "visible": false, "searchable": true },
            { "targets": 6, "visible": false, "searchable": false },
            { "targets": 7, "visible": false, "searchable": true }
        ],
        "order": [[1, 'asc']]
    });

    $('#searchbox').on('keyup', function(){
        table.search(this.value).draw();
        $('#dataTable_filter input').val(this.value);
    });
});