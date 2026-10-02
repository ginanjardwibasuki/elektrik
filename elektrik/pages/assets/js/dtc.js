$(document).ready(function() {
	window.openDetailModal = function(
	  node,
	  dtc_iso,
	  proprietary_name,
	  ftb_name,
	  failure_event,
	  possible_root_cause,
	  workshop_action
	) {
	  document.getElementById("controlunit").innerText = node || '-';
	  document.getElementById("kodeerror").innerText = dtc_iso || '-';
	  document.getElementById("komponen").innerText = proprietary_name || '-';
	  document.getElementById("jenismasalah").innerText = ftb_name || '-';
	  document.getElementById("detailkesalahan").innerText = failure_event || '-';
	  document.getElementById("analisamasalah").innerText = possible_root_cause || '-';
	  document.getElementById("rekomendasiperbaikan").innerText = workshop_action || '-';

	  // Tampilkan modal (jika belum otomatis muncul)
	  const modalElement = new bootstrap.Modal(document.getElementById('dataModal'));
	  modalElement.show();
	};
});