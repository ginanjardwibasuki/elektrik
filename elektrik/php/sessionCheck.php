<?php
include '../helper/function.php';

$auth = new Auth($db);

echo $auth->cekSession();

?>