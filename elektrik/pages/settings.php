<?php
include '../helper/function.php';

$auth = new Auth($db);
$st = new Settings($db);

if ($auth->cekSession() == 0) {
    redirect("login.php");
} else {
	$username = $_SESSION['login']['username'];
}

require('templates/header.php');
?>

<link rel="stylesheet" href="assets/css/settings.css">

<h1 style="
  font-size: 30px;
  margin: 10px;
  color: white;
  text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.25);
  display: flex;
  align-items: center;
  gap: 12px;
">
  <i class="fa-solid fa-diagram-project" style="color:#ffc107;"></i> PENGATURAN
</h1>


<div class="page-content-wrapper py-4">
  <div class="container">
    <div class="card shadow-sm border-0">
      <div class="card-body">
        <form>
          <h5 class="mb-4 fw-bold text-center">Edit Profile</h5>

          <!-- Foto Profil -->
          <div class="mb-4 d-flex flex-column gap-3 align-items-center justify-content-center">
            <div class="shadow rounded-circle overflow-hidden" style="width: 120px; height: 120px;">
              <img src="<?= $st->fotoProfil(); ?>"
                   alt="Profile Photo"
                   class="img-fluid w-100 h-100 object-fit-cover">
            </div>
            <button type="button" class="btn btn-outline-primary btn-sm px-4 rounded-pill" data-bs-toggle="modal" data-bs-target="#modalPhoto">
              <i class="fa-solid fa-image me-1"></i> Change Photo
            </button>
          </div>

          <!-- Tombol Edit -->
          <div class="d-grid gap-3">
            <button type="button" class="btn btn-light border d-flex align-items-center justify-content-between px-3 py-2"
                    data-bs-toggle="modal" data-bs-target="#modalName">
              <span><i class="fa-solid fa-user me-2"></i>Ubah Nama Lengkap</span>
              <i class="fa-solid fa-pen-to-square"></i>
            </button>

            <button type="button" class="btn btn-light border d-flex align-items-center justify-content-between px-3 py-2"
                    data-bs-toggle="modal" data-bs-target="#modalWhatsApp">
              <span><i class="fa-brands fa-whatsapp me-2"></i>Ubah Nomor WhatsApp</span>
              <i class="fa-solid fa-pen-to-square"></i>
            </button>
			
			<button type="button" class="btn btn-light border d-flex align-items-center justify-content-between px-3 py-2"
                    data-bs-toggle="modal" data-bs-target="#modalPassword">
              <span><i class="fa-solid fa-lock me-2"></i>Ubah Password</span>
              <i class="fa-solid fa-pen-to-square"></i>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>

<!-- Modal Nama -->
<div class="modal fade" id="modalName" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Ubah Nama Lengkap</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="text" class="form-control" value="<?= $st->namaLengkap(); ?>">
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
        <button class="btn btn-primary">Simpan</button>
      </div>
    </div>
  </div>
</div>

<!-- Modal WhatsApp -->
<div class="modal fade" id="modalWhatsApp" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Ubah Nomor WhatsApp</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="tel" class="form-control" placeholder="Nomor baru...">
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
        <button class="btn btn-primary">Simpan</button>
      </div>
    </div>
  </div>
</div>

<!-- Modal Password -->
<div class="modal fade" id="modalPassword" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Ubah Password</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="password" class="form-control mb-2" placeholder="Password lama">
        <input type="password" class="form-control mb-2" placeholder="Password baru">
		<input type="password" class="form-control" placeholder="Ulangi password baru">
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
        <button class="btn btn-primary">Simpan</button>
      </div>
    </div>
  </div>
</div>
  
</div> <!-- Overflow hidden -->
</body>

</html>