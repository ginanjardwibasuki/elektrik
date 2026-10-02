<?php
include '../helper/function.php';
$pn = new Partnumber($db);

try {
    $pn->addPartNumber($_POST);
    echo json_encode([
        'success' => true,
        'message' => 'Data berhasil disimpan.'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . $e->getMessage()
    ]);
}
?>