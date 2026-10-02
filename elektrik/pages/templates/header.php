<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tim Elektrik</title>
	
	<!-- Bootstrap -->
	<link rel="stylesheet" type="text/css" href="assets/bootstrap/bootstrap.min.css">
	<script src="assets/bootstrap/bootstrap.min.js"></script>

	<link rel="stylesheet" type="text/css" href="assets/css/style.css?v=31">

	<!-- <link href="assets/icon/fontawesome-pro_v6.7.2_web/css/all.css" rel="stylesheet" /> -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" crossorigin="anonymous" referrerpolicy="no-referrer" />
	<script src="assets/jquery/3.5.1/jquery.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
	<script src="assets/datatables/datatables.js"></script>
	<link rel="stylesheet" type="text/css" href="assets/datatables/datatables.css">
	<!-- <link href="assets/icon/fontawesome/css/fontawesome.css" rel="stylesheet" />
	<link href="assets/icon/fontawesome/css/brands.css" rel="stylesheet" />
	<link href="assets/icon/fontawesome/css/solid.css" rel="stylesheet" /> -->
	<script src="assets/js/ceksesi.js"></script>
	<script src="assets/js/footer.js?v=4"></script>
</head>

<body>
    <div class="navigation">
        <ul class="nav nav-tabs">
            <li class="nav-item list <?php echo ($_SERVER['PHP_SELF'] == '/pages/home.php' ? ' active' : '');?>">
                <a href="javascript:delay('home.php')">
                    <span class="icon">
                        <ion-icon name="home-outline"></ion-icon>
                    </span>
                    <span class="text">Home</span>
                    <span class="circle"></span>
                </a>
            </li>
			<li class="nav-item list <?php echo ($_SERVER['PHP_SELF'] == '/pages/dtc.php' ? ' active' : '');?>">  
				<a href="javascript:delay('dtc.php')">  
					<span class="icon">  
                        <ion-icon name="hardware-chip-outline"></ion-icon>  
					</span>  
					<span class="text">DTC</span>  
					<span class="circle"></span>  
				</a>  
			</li>
            <li class="nav-item list <?php echo ($_SERVER['PHP_SELF'] == '/pages/sparepart.php' ? ' active' : '');?>">
                <a href="javascript:delay('sparepart.php')">
                    <span class="icon">
						<ion-icon name="reader-outline"></ion-icon>
                    </span>
                    <span class="text">Part</span>
                    <span class="circle"></span>
                </a>
            </li>
            <li class="nav-item list <?php echo ($_SERVER['PHP_SELF'] == '/pages/battery.php' ? ' active' : '');?>">
                <a href="javascript:delay('battery.php')">
                    <span class="icon">
                        <ion-icon name="battery-dead-outline"></ion-icon>
                    </span>
                    <span class="text">Battery</span>
                    <span class="circle"></span>
                </a>
            </li>
            <li class="nav-item list <?php echo ($_SERVER['PHP_SELF'] == '/pages/history.php' ? ' active' : '');?>">
                <a href="javascript:delay('history.php')">
                    <span class="icon">
                        <ion-icon name="book-outline"></ion-icon>
                    </span>
                    <span class="text">History</span>
                    <span class="circle"></span>
                </a>
            </li>
            <li class="nav-item list <?php echo ($_SERVER['PHP_SELF'] == '/pages/settings.php' ? ' active' : '');?>">
                <a href="javascript:delay('settings.php')">
                    <span class="icon">
                        <ion-icon name="settings-outline"></ion-icon>
                    </span>
                    <span class="text">Settings</span>
                    <span class="circle"></span>
                </a>
            </li>
            <div class="indicator"></div>
        </ul>
    </div>

    <script type="module" src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.esm.js"></script>
    <script nomodule src="https://unpkg.com/ionicons@5.5.2/dist/ionicons/ionicons.js"></script>
    <script src="assets/js/script.js"></script>
	<script>function delay (URL) {setTimeout( function() { window.location = URL }, 500 );}</script>
	<div style="overflow: hidden;">