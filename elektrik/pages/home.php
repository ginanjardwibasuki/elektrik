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



</div> <!-- Overflow hidden -->
</body>

</html>