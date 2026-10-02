<?php
ob_start();
ini_set('session.gc_maxlifetime', 36000);
session_set_cookie_params(36000);
session_start();

require('koneksi.php');
require('../php/Auth.php');
require('../php/Partnumber.php');
require('../php/Home.php');
require('../php/Settings.php');
include 'ImageResize.php';

function redirect($target)
{
    echo '<script>window.location = "' . $target . '";</script>';
    exit;
}

function setNotif($type, $msg)
{
    $_SESSION['alert'] = ['color' => $type, 'msg' => $msg];
    return;
}

function uploadImage($file,$page)
{
    $target_dir = "../gambar/";
    $target_file = $target_dir . basename($file['name']);
    $ext = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));
	$allow = ['png', 'gif', 'jpg', 'jpeg'];
    if ($file["size"] > 10000000) {
        $_SESSION['alert'] = ['color' => 'danger', 'msg' => 'File gambar melebihi 10MB!'];
        redirect($page.'.php');
        exit;
    } elseif (!in_array($ext, $allow)) {
        $_SESSION['alert'] = ['color' => 'danger', 'msg' => 'Format gambar tidak diizinkan!'];
        redirect($page.'.php');
        exit;
    }
    $namefile = round(microtime(true)) . mt_rand() . '.' . $ext;
    $target = $target_dir . $namefile;
    if (move_uploaded_file($file["tmp_name"], $target)) {
		$image = new \Gumlet\ImageResize($target);
		$image->resizeToHeight(500);
		$image->save($target);
        return $target;
    }
    return false;
}

ob_end_clean();
?>