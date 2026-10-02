<?php
$id = $_POST['id'] ?? null;
$type = $_POST['type'] ?? null;

if (!$id || !$type) die("Data tidak lengkap.");

$pdo = new PDO("mysql:host=localhost;dbname=elektrik", "root", "anjarokz1234", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
]);

$table = $type === "pdf" ? "pdf_log" : "screenshot_log";

$stmt = $pdo->prepare("SELECT original_name FROM $table WHERE id = ?");
$stmt->execute([$id]);
$file = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$file) die("File tidak ditemukan.");

$path = __DIR__ . "/../../webhook/portalvtt/uploads/" . $file['original_name'];
if (file_exists($path)) unlink($path);

$delete = $pdo->prepare("DELETE FROM $table WHERE id = ?");
$delete->execute([$id]);

header("Location: index.php");