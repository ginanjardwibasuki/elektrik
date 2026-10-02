<?php
include '../helper/function.php';

$auth = new Auth($db);
$pn = new Partnumber($db);

if ($auth->cekSession() == 0) {
    redirect("login.php");
} else {
	$username = $_SESSION['login']['username'];
}

if (isset($_POST['edit'])) {
    header('Content-Type: application/json');
	$response = $pn->editPartNumber($_POST);
	echo json_encode($response);
    exit;
}

if (isset($_POST['tambah'])) {
    header('Content-Type: application/json');
    $response = $pn->addPartNumber($_POST);
    echo json_encode($response);
    exit;
}

if (isset($_POST['copy'])) {
	header('Content-Type: application/json');
    $response = $pn->copyAll($_POST);
	echo json_encode($response);
    exit;
}

if (isset($_POST['hapus'])) {
	$pn->hapus($_POST);
}

if (isset($_POST['hapussemua'])) {
	$pn->hapusSemua($_POST);
}

require('templates/header.php');

error_reporting(E_ALL);
ini_set('display_errors', 1);


$hasAlert = isset($_SESSION['alert']);
$alertData = $hasAlert ? $_SESSION['alert'] : null;
unset($_SESSION['alert']);


?>


<link rel="stylesheet" type="text/css" href="assets/css/posisi.css?v=28">



<script src="assets/js/sparepart-datatables.js?v=2"></script>
<script src="assets/js/sparepart.js?v=11"></script>
<script src="assets/js/sparepart-edit-modal.js"></script>
<script src="assets/js/alert.js?v=2"></script>

<link rel="stylesheet" href="assets/css/custom_table.css">

<script>
const sessionAlert = <?= json_encode([
    "show" => $hasAlert,
    "status" => $alertData['color'] ?? '',
    "message" => $alertData['msg'] ?? ''
]) ?>;
</script>



<h1 style="
  font-size: 30px;
  margin: 10px;
  color: white;
  text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.25);
  display: flex;
  align-items: center;
  gap: 12px;
">
  <i class="fa-solid fa-gears" style="color: #ffc107;"></i> SPAREPART
</h1>
<a data-bs-toggle="modal" data-bs-target="#modalTambah" class="float">
  <i class="fa fa-plus my-float"></i>
</a>
<a data-bs-toggle="modal" data-bs-target="#modalLogout" class="logout">
  <i class="fa-solid fa-right-from-bracket my-logout"></i>
</a>
<a data-bs-toggle="modal" data-bs-target="#modalMenu" class="menu">
  <i class="fa-solid fa-gear my-menu"></i>
</a>
<!-- Modal tambah -->
<div class="modal fade" id="modalTambah" tabindex="-1" aria-labelledby="modalTambahLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content shadow-sm border-0" style="border-radius: 12px;">
      <div class="modal-header text-white" style="background: linear-gradient(135deg, #42a5f5, #64b5f6); border-top-left-radius: 12px; border-top-right-radius: 12px;">
        <h5 class="modal-title" id="modalTambahLabel">
          <i class="fa-solid fa-circle-plus me-2"></i> Tambah Sparepart Baru
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Tutup"></button>
      </div>

      <div class="modal-body px-4 py-3">
        <form id="formTambahSparepart" action="" method="POST" autocomplete="off" enctype="multipart/form-data">
          
          <label for="gambar" class="form-label">
            <i class="fa-solid fa-image me-2 text-primary"></i> Gambar
          </label>
          <input type="file" class="form-control mb-3" accept="image/*" name="gambar" />

          <label for="name" class="form-label">
            <i class="fa-solid fa-tag me-2 text-success"></i> Nama Part
          </label>
          <input type="text" name="name" class="form-control input mb-3" required>

          <label for="part_number" class="form-label">
            <i class="fa-solid fa-barcode me-2 text-info"></i> Part Number
          </label>
          <input type="text" name="part_number" class="form-control input mb-3" required>

          <label for="keywordInput" class="form-label">
            <i class="fa-solid fa-keyboard me-2 text-warning"></i> Keyword
          </label>
          <div class="border rounded p-2 mb-3" id="keywordContainer">
            <div id="tagWrapper" class="d-flex flex-wrap gap-2 mb-2"></div>
            <textarea name="keywordInput" id="keywordInput" class="form-control input" rows="2" placeholder="Ketik keyword lalu tekan koma (,) atau enter (⏎)" autocomplete="off"></textarea>
            <input type="hidden" name="keyword" id="inputankeyword">
          </div>

          <label for="vendor" class="form-label">
            <i class="fa-solid fa-building me-2 text-secondary"></i> Vendor
          </label>
          <select class="form-select mb-2" name="vendor" required>
            <option value="NONE">NONE</option>
            <option value="EDJS">EDJS</option>
            <option value="LOGISTIK">LOGISTIK</option>
            <option value="COMEX">COMEX</option>
            <option value="SLP">SLP</option>
          </select>
        
      </div>

      <div class="modal-footer justify-content-between px-4 pb-3">
        <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
          <i class="fa-solid fa-ban me-1"></i> Batal
        </button>
        <button type="submit" id="tambah" name="tambah" class="btn btn-primary px-4">
          <i class="fa-solid fa-circle-check me-1"></i> Submit
        </button>
        </form>
      </div>
    </div>
  </div>
</div>
<!-- end modal tambah -->
<!-- Modal copydatabase -->
<div class="modal fade" id="modalCopy" tabindex="-1" aria-labelledby="modalCopyLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content shadow-sm border-0" style="border-radius: 12px;">
      <div class="modal-header text-white" style="background: linear-gradient(135deg, #2196f3, #64b5f6); border-top-left-radius: 12px; border-top-right-radius: 12px;">
        <h5 class="modal-title" id="modalCopyLabel">
          <i class="fa-solid fa-database me-2"></i> Copy Database Sparepart
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>

      <div class="modal-body px-4 py-3">
        <form id="copyForm" action="" method="POST" autocomplete="off" enctype="multipart/form-data">
          <label for="user" class="form-label fw-semibold">
            <i class="fa-solid fa-user-gear me-2 text-primary"></i> Pilih Nama Pengguna
          </label>
          <select class="form-select" id="user" name="user" required>
            <option value="">-- Pilih --</option>
			<?php
				$options = $pn->getUserPartOptions();
				foreach ($options as $opt) {
					echo "<option value=\"{$opt['value']}\">{$opt['label']}</option>";
				}
			  ?>
          </select>

          <div class="mt-4 p-3 rounded fw-medium" style="background-color: #fff3cd; color: #856404; box-shadow: inset 0 0 6px rgba(0,0,0,0.05);">
            <i class="fa-solid fa-triangle-exclamation me-2 text-warning"></i>
            Data dari pengguna terpilih akan disalin ke akun Anda.<br>
            <span class="text-decoration-underline">Partnumber yang sudah kamu miliki tidak akan hilang.</span>
          </div>
      </div>

      <div class="modal-footer justify-content-between px-4 pb-3">
        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
          <i class="fa-solid fa-ban me-1"></i> Batal
        </button>
        <button type="submit" name="copy" class="btn btn-primary">
          <i class="fa-solid fa-clone me-1"></i> Submit
        </button>
		</form>
      </div>
    </div>
  </div>
</div>
<!-- end modal copydatabase -->
<!-- Modal logout -->
<div class="modal fade" id="modalLogout" tabindex="-1" aria-labelledby="logoutLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content shadow-sm border-0" style="border-radius: 12px;">
      <div class="modal-header text-white" style="background: linear-gradient(135deg, #ef5350, #e53935); border-top-left-radius: 12px; border-top-right-radius: 12px;">
        <h5 class="modal-title" id="logoutLabel">
          <i class="fa-solid fa-right-from-bracket me-2"></i> Konfirmasi Logout
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Tutup"></button>
      </div>
      <div class="modal-body text-center" style="padding: 24px 20px; font-size: 15px;">
        <p class="text-muted">
          <i class="fa-solid fa-circle-info text-danger me-2"></i>
          Anda akan keluar dari sesi saat ini.<br>Pastikan semua perubahan sudah disimpan.
        </p>
      </div>
      <div class="modal-footer justify-content-center gap-3" style="padding: 16px;">
        <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
          <i class="fa-solid fa-xmark me-1"></i> Batal
        </button>
        <a href="logout.php" class="btn btn-danger px-4">
          <i class="fa-solid fa-right-from-bracket me-1"></i> Logout
        </a>
      </div>
    </div>
  </div>
</div>
<!-- end modal logout -->
<!-- Modal menu -->
<div class="modal fade" id="modalMenu" tabindex="-1" aria-labelledby="modalMenuLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content shadow-sm border-0" style="border-radius: 12px;">
      <div class="modal-header text-white" style="background: linear-gradient(135deg, #2196f3, #4caf50); border-top-left-radius: 12px; border-top-right-radius: 12px;">
        <h5 class="modal-title" id="modalMenuLabel">
          <i class="fa-solid fa-bars me-2"></i> Menu Sparepart
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body px-4 py-3">
        <div class="d-grid gap-3">
          <button class="btn btn-outline-primary d-flex justify-content-between align-items-center" data-bs-toggle="modal" data-bs-target="#modalCopy">
            <span><i class="fa-solid fa-copy me-2"></i> Copy Database</span>
            <i class="fa-solid fa-arrow-right"></i>
          </button>
          <button class="btn btn-outline-danger d-flex justify-content-between align-items-center" data-bs-toggle="modal" data-bs-target="#modalHapusSemua">
            <span><i class="fa-solid fa-trash-can me-2"></i> Hapus Semua Partnumber</span>
            <i class="fa-solid fa-circle-exclamation"></i>
          </button>
        </div>
      </div>
      <div class="modal-footer justify-content-center">
        <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
          <i class="fa-solid fa-circle-xmark me-1"></i> Tutup Menu
        </button>
      </div>
    </div>
  </div>
</div>
<!-- end modal menu -->
<table style="table-layout: fixed; width:100%;" class="table" id="dataTable" cellspacing="0">
  <marquee style="color: black; background: white;">Selamat datang <?= $username; ?>, gunakan kolom "Cari sparepart" untuk mempermudah pencarian data. </marquee>
  <thead>
    <tr>
      <th style="text-align: center;">Gambar</th>
      <th style="text-align: center;">Nama</th>
      <th style="text-align: center;">Copy</th>
      <th style="text-align: center;">Opsi</th>
      <th style="text-align: center;">ID</th>
      <th style="text-align: center;">Part Number</th>
      <th style="text-align: center;">Vendor</th>
      <th style="text-align: center;">Keyword</th>
    </tr>
  </thead>
  <tbody></tbody>
</table>
<div class="input-group mb-3 px-2">
  <span class="input-group-text" id="basic-addon1">🔍</span>
  <input type="text" class="form-control" placeholder="Cari sparepart" aria-label="Username" aria-describedby="basic-addon1" id="searchbox">
</div>
<!-- start modal tampilkan -->
<div class="modal fade" id="dataModal" tabindex="-1" aria-labelledby="dataModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-centered">
    <div class="modal-content shadow-sm rounded-4">
      <div class="modal-header bg-primary text-white">
        <h5 class="modal-title" id="dataModalLabel">
          <i class="fas fa-box-open me-2"></i> Detail Sparepart
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>

      <div class="modal-body p-4">
        <div class="row gy-3 align-items-center">
          <!-- Gambar -->
          <div class="col-md-6 text-center">
            <img id="modalImage" src="assets/images/noimage.png" alt="Preview Gambar" style="width: 340px; height: 340px; object-fit: cover; border-radius: 10px; box-shadow: rgba(0, 0, 0, 0.25) 3px 3px 3px, rgba(0, 0, 0, 0.22) 0px 10px 10px; margin-left: -7px;">
          </div>

          <!-- Informasi -->
          <div class="col-md-6">
			<div class="mb-3">
              <i class="fas fa-tag text-info me-2"></i>
              <strong>Nama Part:</strong> <span id="modalName"></span>
            </div>
            <div class="mb-3">
              <i class="fas fa-barcode text-primary me-2"></i>
              <strong>Part Number:</strong> <span id="modalPartNumber"></span>
            </div>
            <div class="mb-3">
              <i class="fas fa-truck text-success me-2"></i>
              <strong>Vendor:</strong> <span id="modalVendor"></span>
            </div>
            <div>
              <i class="fas fa-key text-warning me-2"></i>
              <strong>Keyword:</strong>
              <div id="modalKeywordTags" class="mt-2 d-flex flex-wrap gap-2"></div>
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
<!-- start modal edit -->
<div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <form id="formEditSparepart" action="" method="POST" autocomplete="off" enctype="multipart/form-data">
        <div class="modal-header bg-primary text-white">
          <h5 class="modal-title" id="editModalLabel">
            <i class="fas fa-edit me-2"></i> Edit Data
          </h5>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <input type="hidden" name="edit">
          <input type="hidden" id="editId" name="id">

          <div class="position-relative">
			<img id="editGambar1" src="assets/images/noimage.png" alt="Gambar Part"
			  class="img-fluid"
			  style="height: 180px; object-fit: cover; width: 100%;">

			<!-- Overlay tombol ganti -->
			<div class="position-absolute top-50 start-50 translate-middle text-light">
			  <button type="button" class="btn btn-sm btn-outline-light" onclick="document.getElementById('editGambar2').click();">
				<i class="fas fa-camera-retro me-1"></i> Ganti Gambar
			  </button>
			</div>
		  </div>

		  <div class="card-body py-2 px-3 bg-light">
			<small class="text-muted">
			  <i class="fas fa-image text-danger me-1"></i> Klik tombol di atas atau gambar untuk mengganti
			</small>
		  </div>

          <div class="wrapper">
            <input type="file" accept="image/*" id="editGambar2" name="gambar" style="display:none;" />
            <input id="exist_gambar" type="hidden" name="exist_gambar">
          </div>

          <label for="editName" class="mt-2"><i class="fas fa-tag me-1 text-success"></i> Nama Part</label>
          <input id="editName" type="text" name="name" class="form-control">

          <label for="editPartNumber" class="mt-2"><i class="fas fa-barcode me-1 text-danger"></i> Part Number</label>
          <input id="editPartNumber" type="text" name="part_edit" class="form-control">
          <input id="part_ori" type="hidden" name="part_ori">

          <label for="editVendor" class="mt-2"><i class="fas fa-truck me-1 text-info"></i> Vendor</label>
          <select id="editVendor" class="form-select" name="vendor" required>
            <option value="EDJS">EDJS</option>
            <option value="LOGISTIK">LOGISTIK</option>
            <option value="COMEX">COMEX</option>
            <option value="SLP">SLP</option>
            <option value="NONE">NONE</option>
          </select>
		  
		  <label for="editkeywordInput" class="form-label">
            <i class="fa-solid fa-keyboard me-2 text-warning"></i> Keyword
          </label>
          <div class="border rounded p-2 mb-3" id="editkeywordContainer">
            <div id="edittagWrapper" class="d-flex flex-wrap gap-2 mb-2"></div>
            <textarea id="editkeywordInput" name="editkeywordInput" class="form-control input" rows="2" placeholder="Ketik keyword lalu tekan koma (,) atau enter (⏎)" autocomplete="off"></textarea>
            <input type="hidden" name="keyword" id="editinputankeyword">
          </div>
        </div>

        <div class="modal-footer justify-content-between">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
            <i class="fas fa-times me-1"></i> Batal
          </button>
          <button type="submit" name="submit" class="btn btn-success">
            <i class="fas fa-save me-1"></i> Update
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
<!-- end modal edit -->
<!-- start modal hapus -->
<div class="modal fade" id="modalHapus" tabindex="-1" aria-labelledby="modalHapusLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form action="" method="POST" autocomplete="off" enctype="multipart/form-data">
        <div class="modal-header bg-danger text-white">
          <h5 class="modal-title" id="modalHapusLabel">
            <i class="fas fa-exclamation-triangle me-2"></i> Konfirmasi Hapus
          </h5>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body text-center">
          <i class="fas fa-trash-alt fa-3x text-danger mb-3"></i>
          <p>Apakah Anda yakin ingin menghapus data ini?</p>
          <input type="hidden" id="deleteId" name="id">
          <input type="hidden" id="deleteGambar" name="gambar">
        </div>

        <div class="modal-footer justify-content-between">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
            <i class="fas fa-times me-1"></i> Batal
          </button>
          <button type="submit" name="hapus" class="btn btn-danger">
            <i class="fas fa-trash me-1"></i> Hapus
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
<!-- end modal hapus -->
<!-- start modal hapussemua -->
<div class="modal fade" id="modalHapusSemua" tabindex="-1" aria-labelledby="modalHapusSemuaLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content shadow-sm border-0" style="border-radius: 12px;">
      <div class="modal-header text-white" style="background: linear-gradient(135deg, #f44336, #e53935); border-top-left-radius: 12px; border-top-right-radius: 12px;">
        <h5 class="modal-title">
          <i class="fa-solid fa-trash-can me-2"></i> Konfirmasi Hapus Semua
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Tutup"></button>
      </div>

      <form action="" method="POST" autocomplete="off" enctype="multipart/form-data">
        <div class="modal-body px-4 pt-3">
          <div class="alert alert-warning d-flex align-items-center" role="alert">
            <i class="fa-solid fa-triangle-exclamation me-2 fa-lg text-warning"></i>
            <div>
              Tindakan ini akan <strong>menghapus seluruh data sparepart</strong>.<br>Harap masukkan kata sandi akun untuk melanjutkan.
            </div>
          </div>

          <label for="password" class="form-label fw-semibold">
            <i class="fa-solid fa-key me-2 text-secondary"></i> Kata Sandi
          </label>
          <input type="password" name="password" id="password" class="form-control rounded" placeholder="Masukkan password" onkeypress="return event.keyCode !== 13" required>
        </div>

        <div class="modal-footer justify-content-between px-4 pb-3">
          <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
            <i class="fa-solid fa-ban me-1"></i> Batal
          </button>
          <button type="submit" name="hapussemua" class="btn btn-danger px-4">
            <i class="fa-solid fa-trash me-1"></i> Hapus Semua
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
<!-- end modal hapussemua -->
<!-- Start Footer -->
<footer class="text-center" style="margin-bottom: 100px;">
  <small id="creditText" style="transition: opacity 0.4s ease;">© <?= date('Y'); ?> Tim Elektrik Adaro Energy</small>
</footer>
<!-- End Footer -->
</div>
<!-- Overflow hidden -->
</body>
</html>