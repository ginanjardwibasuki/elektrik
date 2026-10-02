<?php
$pdo = new PDO("mysql:host=localhost;dbname=elektrik", "root", "anjarokz1234", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
]);

$pdfs = $pdo->query("SELECT * FROM pdf_log ORDER BY uploaded_at DESC")->fetchAll(PDO::FETCH_ASSOC);
$screenshots = $pdo->query("SELECT * FROM screenshot_log ORDER BY uploaded_at DESC")->fetchAll(PDO::FETCH_ASSOC);

function fileExistsOnServer(string $filename): bool {
    $uploadDir = realpath(__DIR__ . '/../../webhook/portalvtt/uploads');
    return $uploadDir && file_exists($uploadDir . '/' . $filename);
}
?>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>📁 File Manager</title>
    <style>
        body { background: #0f0f0f; color: #00FF00; font-family: Consolas, monospace; padding: 20px; }
        h2 { margin-top: 40px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #00FF00; padding: 8px; text-align: center; }
        input[type="text"] { width: 80%; padding: 4px; background: #000; color: #00FF00; border: 1px solid #00FF00; }
        button { padding: 6px 12px; background: #1f1f1f; color: #00FF00; border: none; cursor: pointer; }
        button:hover { background: #00FF00; color: #0f0f0f; }
        .missing { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>📁 File Upload Manager</h1>

    <h2>📄 PDF Files</h2>
    <table>
        <tr><th>Original Name</th><th>Alias Name</th><th>Username</th><th>Actions</th></tr>
        <?php foreach ($pdfs as $file): ?>
        <tr>
            <td><?= htmlspecialchars($file['original_name']) ?></td>
            <td>
                <form action="rename.php" method="POST">
                    <input type="hidden" name="id" value="<?= $file['id'] ?>">
                    <input type="hidden" name="type" value="pdf">
                    <input type="text" name="alias_name" value="<?= htmlspecialchars($file['alias_name']) ?>">
                    <button type="submit">Rename</button>
                </form>
            </td>
            <td><?= htmlspecialchars($file['username']) ?></td>
            <td>
                <?php if (fileExistsOnServer($file['original_name'])): ?>
                    <a href="/webhook/portalvtt/uploads/<?= urlencode($file['original_name']) ?>" download="<?= htmlspecialchars($file['alias_name']) ?>">
                        <button>Download</button>
                    </a>
                <?php else: ?>
                    <span class="missing">❌ File tidak tersedia</span>
                <?php endif; ?>
                <form action="delete.php" method="POST" onsubmit="return confirm('Yakin mau hapus?');" style="display:inline;">
                    <input type="hidden" name="id" value="<?= $file['id'] ?>">
                    <input type="hidden" name="type" value="pdf">
                    <button type="submit">Delete</button>
                </form>
            </td>
        </tr>
        <?php endforeach; ?>
    </table>

    <h2>🖼️ Screenshot Files</h2>
    <table>
        <tr><th>Original Name</th><th>Alias Name</th><th>Username</th><th>Actions</th></tr>
        <?php foreach ($screenshots as $file): ?>
        <tr>
            <td><?= htmlspecialchars($file['original_name']) ?></td>
            <td>
                <form action="rename.php" method="POST">
                    <input type="hidden" name="id" value="<?= $file['id'] ?>">
                    <input type="hidden" name="type" value="screenshot">
                    <input type="text" name="alias_name" value="<?= htmlspecialchars($file['alias_name']) ?>">
                    <button type="submit">Rename</button>
                </form>
            </td>
            <td><?= htmlspecialchars($file['username']) ?></td>
            <td>
                <?php if (fileExistsOnServer($file['original_name'])): ?>
                    <a href="/webhook/portalvtt/uploads/<?= urlencode($file['original_name']) ?>" download="<?= htmlspecialchars($file['alias_name']) ?>">
                        <button>Download</button>
                    </a>
                <?php else: ?>
                    <span class="missing">❌ File tidak tersedia</span>
                <?php endif; ?>
                <form action="delete.php" method="POST" onsubmit="return confirm('Yakin mau hapus?');" style="display:inline;">
                    <input type="hidden" name="id" value="<?= $file['id'] ?>">
                    <input type="hidden" name="type" value="screenshot">
                    <button type="submit">Delete</button>
                </form>
            </td>
        </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>