<?php
include '../helper/function.php';
include '../helper/url_config.php';

$auth = new Auth($db);
$pn = new Partnumber($db);

if ($auth->cekSession() == 0) {
    redirect("login.php");
} else {
	$username = $_SESSION['login']['username'];
	$pic = isset($_SESSION['login']['username']) ? $_SESSION['login']['username'] : "Tidak ada PIC";
    if ($pic === "ginanjar") {
        $pic = "0118025 GINANJAR DWI BASUKI";
    } elseif ($pic === "ivan") {
        $pic = "0117268 IVAN MUHAMMAD IRSYAD";
    } elseif ($pic === "hendri") {
        $pic = "80004144 HENDRI KURNIAWAN";
    } elseif ($pic === "anwar") {
        $pic = "80000631 ANWAR BAYU SUTRISNO";
	} elseif ($pic === "sajati") {
        $pic = "0116240 SAJATI ADHI NUGROHO";
	} elseif ($pic === "andi") {
        $pic = "1032021 ANDIYANDI";
    } else {
        header("Location: home.php");
        exit();
    }


}

require('templates/header.php');
?> <script src="assets/jquery/3.5.1/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script src="https://cdn.socket.io/4.4.1/socket.io.min.js" integrity="sha384-fKnu0iswBIqkjxrhQCTZ7qlLHOFEgNkRmK2vaO/LbTZSXdJfAu6ewRBdwHPhBo/H" crossorigin="anonymous"></script>
<script src="assets/js/logger.js"></script>
<script src="assets/js/post_battery.js"></script>
<script src="assets/js/battery-datatables.js"></script>
<script src="assets/js/footer.js"></script>
<script src="assets/js/config.js"></script>
<link rel="stylesheet" href="assets/css/battery.css">
<script src="assets/datatables/datatables.js"></script>
<link rel="stylesheet" type="text/css" href="assets/datatables/datatables.css">
<h1 style="font-size: 30px; margin-top: 5px; margin-left: 10px; color: white; display: flex; align-items: center; gap: 12px; text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.25);"><i class="fa-solid fa-battery-bolt" style="color: #ffc107;"></i> BATTERY</h1>
<div class="container">

  <div class="card mb-3">
    

    
    <div class="card-body" style="overflow: hidden; height: auto; margin-left: -25px;">

            <table id="dataTable" class="table table-striped" style="width: 100%; table-layout: fixed;">
                <thead>
                    <tr>
                        <th>ID</th>
						<th>PIC</th>
                        <th>UNIT</th>
                        <th>STATUS</th>
						<th>TANGGAL</th>
                    </tr>
                </thead>
                <tbody>
                </tbody>
            </table>

		
		<!-- Floating Log Status (tersembunyi awalnya) -->
		<div id="floatingLogger" style="
		  display: block;
		  position: fixed;
		  top: 70px;
		  left: 50%;
		  transform: translateX(-50%);
		  background: rgba(255, 255, 255, 0.9);
		  backdrop-filter: blur(3px);
		  padding: 10px 20px;
		  border-radius: 16px;
		  font-size: 15px;
		  font-family: 'Segoe UI', sans-serif;
		  z-index: 1050;
		  max-width: 92%;
		  box-shadow: 0 6px 18px rgba(0,0,0,0.15);
		  white-space: nowrap;
		  overflow: hidden;
		  text-overflow: ellipsis;
		  transition: all 0.3s ease;
		">
		  <i class="fa-solid fa-wave-square me-2 text-primary"></i>
		  <span id="logContent" class="text-dark fw-semibold">Menunggu update log...</span>
		</div>
    </div>
</div>
  <div class="card shadow-sm p-3 rounded-3">
  <form id="batteryForm" action="<?= SOCKET_URL; ?>/auto" method="POST">

    <input type="hidden" id="pic" name="pic" value="<?= $pic; ?>">

    <!-- CODE UNIT + HM -->
    <div class="row mb-3">
      <div class="col-7">
        <label for="unit" class="form-label">
          <i class="fa-solid fa-truck-bolt me-2 text-success"></i> CODE UNIT:
        </label>
        <div class="input-group">
          <span class="input-group-text">HT140-0</span>
          <input type="number" class="form-control" id="unit" name="unit" required>
        </div>
      </div>
      <div class="col-5">
        <label for="inHM" class="form-label">
          <i class="fa-solid fa-hourglass-half me-2 text-warning"></i> HM:
        </label>
        <input type="number" class="form-control" id="inHM" name="inHM">
      </div>
    </div>

    <!-- Hidden Input Parameters -->
    <?php
    $fields = [
      "hm","soc1","zi1","rcc1","cca1","sae1","volt1","soc2","zi2","rcc2","cca2","sae2","volt2",
      "soc1_2","zi1_2","rcc1_2","cca1_2","sae1_2","volt1_2","cp","sc","sca","rv","tv"
    ];
    foreach ($fields as $field) {
      echo "<input type='hidden' id='{$field}' name='{$field}'>";
    }
    ?>

    <!-- Toggle Button for Voltase / RCC -->
    <div class="text-center mt-3">
      <button type="button" class="btn btn-secondary btn-sm" id="toggleVoltase">
        <i class="fa-solid fa-bolt me-1"></i> Tampilkan Input
      </button>
    </div>

    <!-- SOC Row -->
    <div class="row mt-3" id="voltaseRow" style="display:none;">
      <label class="form-label">
        <i class="fa-solid fa-battery-half me-2 text-info"></i> SOC:
      </label>
      <?php foreach (["1" => "insoc1", "2" => "insoc2", "S" => "insoc3"] as $label => $id): ?>
        <div class="col-4">
          <div class="input-group">
            <span class="input-group-text"><?= $label ?></span>
            <input type="number" class="form-control" id="<?= $id ?>" name="<?= $id ?>">
          </div>
        </div>
      <?php endforeach; ?>
    </div>

    <!-- RCC Row -->
    <div class="row mt-3" id="rccRow" style="display:none;">
      <label class="form-label">
        <i class="fa-solid fa-gauge-high me-2 text-danger"></i> RCC:
      </label>
      <?php foreach (["1" => "inrcc1", "2" => "inrcc2", "S" => "inrcc3"] as $label => $id): ?>
        <div class="col-4">
          <div class="input-group">
            <span class="input-group-text"><?= $label ?></span>
            <input type="number" class="form-control text-center" id="<?= $id ?>" name="<?= $id ?>">
          </div>
        </div>
      <?php endforeach; ?>
    </div>

    <!-- Action Buttons -->
    <div class="d-flex gap-3 mt-4">
      <button type="button" class="btn btn-danger px-4" id="clearForm">
        <i class="fa-solid fa-eraser me-1"></i> Clear
      </button>
      <button type="button" class="btn btn-primary flex-grow-1 px-4" id="openModal">
        <i class="fa-solid fa-arrow-up-right-from-square me-1"></i> Submit
      </button>
    </div>
  </form>

  <!-- Modal Preview -->
  <div class="modal fade" id="dataModal" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content shadow-sm">
        <div class="modal-header bg-light">
          <h5 class="modal-title">
            <i class="fa-solid fa-list-check me-2 text-primary"></i> Data Input
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body" style="max-height: 400px; overflow-y: auto;">
          <div id="picUnitContainer" class="mb-3 p-3 rounded border">
            <strong><i class="fa-solid fa-id-card me-1"></i> PIC:</strong>
            <span id="picValue"></span><br>
            <strong><i class="fa-solid fa-truck me-1"></i> Code Unit:</strong> HT140-0<span id="unitValue"></span><br>
            <strong><i class="fa-solid fa-clock me-1"></i> HM:</strong>
            <span id="HMValue"></span>
          </div>

          <table class="table table-bordered table-sm">
            <thead class="table-light">
              <tr>
                <th><i class="fa-solid fa-layer-group"></i> Kategori</th>
                <th><i class="fa-solid fa-sliders"></i> Parameter</th>
                <th><i class="fa-solid fa-chart-line"></i> Nilai</th>
              </tr>
            </thead>
            <tbody id="modalContent">
              <!-- Dinamis dari JS -->
            </tbody>
          </table>
        </div>
        <div class="modal-footer justify-content-between px-3 pb-3">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
            <i class="fa-solid fa-ban me-1"></i> Batal
          </button>
          <button type="button" class="btn btn-success" id="confirmSubmit">
            <i class="fa-solid fa-paper-plane me-1"></i> Konfirmasi & Kirim
          </button>
        </div>
      </div>
    </div>
  </div>
</div>


<!-- Start Footer -->
<footer class="text-center" style="margin-bottom: 120px;">
  <small id="creditText" style="transition: opacity 0.4s ease;">© <?= date('Y'); ?> Tim Elektrik Adaro Energy</small>
</footer>
<!-- End Footer -->
</div>
</div>

</body>
</html>
