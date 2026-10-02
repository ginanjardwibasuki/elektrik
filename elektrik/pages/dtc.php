<?php
include '../helper/function.php';

$auth = new Auth($db);

if ($auth->cekSession() == 0) {
    redirect("login.php");
} else {
	$username = $_SESSION['login']['username'];
}

require('templates/header.php');
?>
<script src="assets/js/dtc.js?v=2"></script>
<script src="assets/js/dtc-datatables.js?v=21"></script>
<link rel="stylesheet" href="assets/css/custom_table.css">
<link rel="stylesheet" href="assets/css/dtc.css">

<h1 style="
  font-size: 30px;
  margin: 10px;
  color: white;
  text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.25);
  display: flex;
  align-items: center;
  gap: 12px;
">
  <i class="fa-solid fa-diagram-project" style="color:#ffc107;"></i> DTC LIST
</h1>

<div class="page-content-wrapper py-4">
  <div class="container">
    <div class="card shadow-sm border-0">
      <div class="card-header bg-warning text-dark fw-bold">
        <i class="fa-solid fa-table-list me-2"></i> Tabel Pencarian DTC
      </div>
      <div class="card-body">
        <div class="table-responsive">
          <!-- <table style="table-layout: fixed; width:100%;" class="table table-bordered align-middle text-center" id="dataTable"> -->
		  <table class="table table-bordered align-middle text-center" id="dataTable">
			<marquee style="color: black; background: white;">Selamat datang <?= $username; ?>, gunakan kolom "Cari kode" untuk mempermudah pencarian DTC list. </marquee>
            <thead class="table-light">
              <tr>
				<th>KOMPONEN</th>
                <th>KODE</th>
				<th>PROPRIETARY</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- start modal tampilkan -->
<div class="modal fade" id="dataModal" tabindex="-1" aria-labelledby="dataModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <div class="modal-content border border-primary-subtle rounded-4 shadow">
      
      <div class="modal-header bg-gradient bg-primary text-white">
        <h5 class="modal-title" id="dataModalLabel">
          <i class="fas fa-microchip me-2"></i> Detail DTC
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>

      <div class="modal-body px-4 py-3" style="max-height: 75vh; overflow-y: auto;">
        <div class="row gy-4">
          
          <div class="col-md-6">
            <div class="p-3 rounded bg-light border-start border-info border-4">
              <small class="text-secondary"><i class="fas fa-cogs me-2 text-info"></i>Control Unit</small><br>
              <span class="fw-bold" id="controlunit"></span>
            </div>
            <div class="p-3 rounded bg-light border-start border-primary border-4">
              <small class="text-secondary"><i class="fas fa-barcode me-2 text-primary"></i>Kode Error</small><br>
              <span class="fw-bold" id="kodeerror"></span>
            </div>
            <div class="p-3 rounded bg-light border-start border-success border-4">
              <small class="text-secondary"><i class="fas fa-cube me-2 text-success"></i>Komponen Terkait</small><br>
              <span id="komponen"></span>
            </div>
            <div class="p-3 rounded bg-light border-start border-warning border-4">
              <small class="text-secondary"><i class="fas fa-exclamation-triangle me-2 text-warning"></i>Jenis Masalah</small><br>
              <span id="jenismasalah"></span>
            </div>
          </div>

          <div class="col-md-6">
            <div class="p-3 rounded bg-light border-start border-danger border-4">
              <small class="text-secondary"><i class="fas fa-bug me-2 text-danger"></i>Detail Kesalahan</small><br>
              <span id="detailkesalahan"></span>
            </div>
			<br>
            <div class="p-3 rounded bg-light border-start border-warning border-4">
              <small class="text-secondary"><i class="fas fa-search me-2 text-warning"></i>Analisa Masalah</small><br>
              <span id="analisamasalah"></span>
            </div>
			<br>
            <div class="p-3 rounded bg-light border-start border-success border-4">
              <small class="text-secondary"><i class="fas fa-tools me-2 text-success"></i>Pengecekan dan Perbaikan</small><br>
              <span id="rekomendasiperbaikan"></span>
            </div>
          </div>

        </div>
      </div>

      <div class="modal-footer bg-light">
        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
          <i class="fas fa-times me-1"></i> Tutup
        </button>
      </div>
    </div>
  </div>
</div>
<!-- end modal tampilkan -->

<div class="input-group mb-3 px-2">
	<span class="input-group-text" id="basic-addon1">🔍</span>
	<input type="text" class="form-control" placeholder="Cari kode" aria-label="Username" aria-describedby="basic-addon1" id="searchbox">
</div>

<footer class="text-center" style="margin-bottom: 100px;">
  <small id="creditText" style="transition: opacity 0.4s ease;">© <?= date('Y'); ?> Tim Elektrik Adaro Energy</small>
</footer>
</div> <!-- Overflow hidden -->
</body>

</html>