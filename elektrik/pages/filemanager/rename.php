<?php
// Konfigurasi
$dbHost = "localhost";
$dbName = "elektrik";
$dbUser = "root";
$dbPass = "anjarokz1234";
$uploadDir = realpath(__DIR__ . '/../../webhook/uploads');

// Input
$id         = $_POST['id']         ?? null;
$type       = $_POST['type']       ?? null;
$new_alias  = $_POST['alias_name'] ?? null;

// Validasi input
if (!$id || !$type || !$new_alias) {
    http_response_code(400);
    exit("❌ Data tidak lengkap.");
}

// Validasi tipe
$table = match ($type) {
    'pdf'        => 'pdf_log',
    'screenshot' => 'screenshot_log',
    default      => null
};

if (!$table) {
    http_response_code(400);
    exit("❌ Tipe file tidak valid.");
}

// Validasi folder upload
if (!$uploadDir || !is_dir($uploadDir)) {
    http_response_code(500);
    exit("❌ Folder uploads tidak ditemukan.");
}

try {
    // Koneksi database
    $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName", $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);

    // Ambil original dan alias dari database
    $stmt = $pdo->prepare("SELECT original_name, alias_name FROM $table WHERE id = ?");
    $stmt->execute([$id]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$result) {
        http_response_code(404);
        exit("❌ File tidak ditemukan di database.");
    }

    $original_name = $result['original_name'];
    $alias_name    = $result['alias_name'];

    // Cek file fisik berdasarkan original_name
    $file_path = $uploadDir . '/' . $original_name;
    if (!file_exists($file_path)) {
        // Fallback ke alias_name
        $file_path = $uploadDir . '/' . $alias_name;
        if (!file_exists($file_path)) {
            http_response_code(404);
            exit("❌ File tidak ditemukan di server (original & alias).");
        }
    }

    // Update alias_name di database
    $update = $pdo->prepare("UPDATE $table SET alias_name = ? WHERE id = ?");
    $update->execute([$new_alias, $id]);

    // Optional: log perubahan alias (audit trail)
    /*
    $log = $pdo->prepare("INSERT INTO alias_history (file_id, old_alias, new_alias, changed_at) VALUES (?, ?, ?, NOW())");
    $log->execute([$id, $alias_name, $new_alias]);
    */

    // Redirect atau respon sukses
    header("Location: index.php");
    exit;

} catch (PDOException $e) {
    http_response_code(500);
    exit("❌ Error DB: " . $e->getMessage());
}