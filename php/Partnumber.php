<?php
class Partnumber
{

    private $db;
    public $sesi;
    function __construct($db)
    {
        $this->db = $db;
    }

	public function addPartNumber(array $post): array
	{
		$name        = mysqli_real_escape_string($this->db, $post['name']);
		$part_number = mysqli_real_escape_string($this->db, $post['part_number']);
		$vendor      = mysqli_real_escape_string($this->db, $post['vendor']);
		$keyword     = mysqli_real_escape_string($this->db, $post['keyword']);
		$username    = $_SESSION['login']['username'];

		$gambar = $_FILES['gambar']['error'] ? null : uploadImage($_FILES['gambar'], 'sparepart');

		$cek = mysqli_query($this->db, "SELECT 1 FROM sparepart WHERE part_number = '$part_number' AND owner = '$username'");
		if (mysqli_num_rows($cek) > 0) {
			return [
				'success' => false,
				'message' => 'Part number sudah ada sebelumnya!'
			];
		}

		$insert = mysqli_query($this->db, "
			INSERT INTO sparepart 
			VALUES (NULL, '$name', '$part_number', '$vendor', " . ($gambar ? "'$gambar'" : "NULL") . ", '$keyword', '$username')
		");

		if ($insert) {
			return [
				'success' => true,
				'message' => 'Part number berhasil ditambahkan!'
			];
		} else {
			return [
				'success' => false,
				'message' => 'Kesalahan sistem!'
			];
		}
	}

	public function editPartNumber(array $post)
	{
		$username = $_SESSION['login']['username'];
		$id       = mysqli_real_escape_string($this->db, $post['id']);
		$name     = mysqli_real_escape_string($this->db, $post['name']);
		$partEdit = mysqli_real_escape_string($this->db, $post['part_edit']);
		$partOri  = mysqli_real_escape_string($this->db, $post['part_ori']);
		$vendor   = mysqli_real_escape_string($this->db, $post['vendor']);
		$keyword  = mysqli_real_escape_string($this->db, $post['keyword']);
		$gambarLama = mysqli_real_escape_string($this->db, $post['exist_gambar']);

		if ($partEdit !== $partOri) {
			$cek = mysqli_query($this->db, "SELECT 1 FROM sparepart WHERE part_number = '$partEdit' AND owner = '$username'");
			if (mysqli_num_rows($cek) > 0) {
				return [
					'success' => false,
					'message' => 'Part number sudah ada sebelumnya!'
				];
			}
		}

		$gambarBaru = !empty($_FILES['gambar']['name']) ? uploadImage($_FILES['gambar'], 'sparepart') : null;
		if ($gambarBaru) {
			if (is_file($gambarLama)) {
				unlink($gambarLama);
			}
		}

		$gambarValue = $gambarBaru ? "'$gambarBaru'" : "gambar";
		$query = "
			UPDATE sparepart 
			SET name='$name', part_number='$partEdit', vendor='$vendor', gambar=$gambarValue, keyword='$keyword' 
			WHERE id='$id'
		";

		if (mysqli_query($this->db, $query)) {
			return [
				'success' => true,
				'message' => 'Sukses update data!'
			];
		} else {
			return [
				'success' => false,
				'message' => 'Kesalahan sistem!'
			];
		}

		exit;
	}

	public function hapus(array $post)
	{
		$id = mysqli_real_escape_string($this->db, $post['id']);
		$gambar = mysqli_real_escape_string($this->db, $post['gambar']);

		if (is_file($gambar)) {
			unlink($gambar);
		}
		if ($query = mysqli_query($this->db, "DELETE FROM sparepart WHERE id='$id'")) {
			$status = "success";
			$pesan = "Sukses menghapus data!";
		} else {
			$status = "error";
			$pesan = "Gagal menghapus data!";
		}
		setNotif($status, $pesan);
		redirect('sparepart.php');
	}
	
	public function hapusSemua(array $post)
	{
		$username = $_SESSION['login']['username'];
		$password = mysqli_real_escape_string($this->db, $post['password']);

		$result = mysqli_query($this->db, "SELECT password FROM akun WHERE username = '$username'");
		$user = mysqli_fetch_assoc($result);

		if (!$user || $password !== $user['password']) {
			setNotif("error", "Gagal hapus data, password salah!");
			redirect('sparepart.php');
			return;
		}

		$items = mysqli_query($this->db, "SELECT id, gambar FROM sparepart WHERE owner = '$username'");
		while ($row = mysqli_fetch_assoc($items)) {
			if (is_file($row['gambar'])) {
				unlink($row['gambar']);
			}
			mysqli_query($this->db, "DELETE FROM sparepart WHERE id = {$row['id']}");
		}

		setNotif('success', 'Berhasil hapus semua data!');
		redirect('sparepart.php');
	}
	
	public function copyAll(array $post)
	{
		$dicopy = $post['user'];
		$username = $_SESSION['login']['username'];
		$data = mysqli_query($this->db, "SELECT * FROM sparepart WHERE owner='$dicopy'");

		while ($d = mysqli_fetch_array($data)) {
			$part = $d['name'];
			$part_number = $d['part_number'];
			$vendor = $d['vendor'];
			$media = $d['gambar'];
			$tag = $d['keyword'];

			$check = mysqli_query($this->db, "SELECT 1 FROM sparepart WHERE part_number = '$part_number' AND owner = '$username'");
			if (mysqli_num_rows($check) == 0) {
				if (file_exists($media)) {
					$ext = pathinfo($media, PATHINFO_EXTENSION);
					$new_filename = '../gambar/' . time() . bin2hex(random_bytes(8)) . '.' . $ext;
					copy($media, $new_filename);
				} else {
					$new_filename = NULL;
				}
				mysqli_query($this->db, "INSERT INTO sparepart VALUES (NULL,'$part','$part_number','$vendor','$new_filename','$tag','$username')");
			}
		}

		return ["status" => "done"];
	}

	public function getUserPartOptions(): array
	{
		$options = [];
		$result = mysqli_query($this->db, "SELECT username FROM akun");

		while ($row = mysqli_fetch_assoc($result)) {
			$user = $row['username'];
			$countRes = mysqli_query($this->db, "SELECT COUNT(*) AS total FROM sparepart WHERE owner='$user'");
			$countRow = mysqli_fetch_assoc($countRes);
			$total = $countRow['total'];

			$options[] = [
				'value' => $user,
				'label' => ucfirst($user) . " ({$total} partnumber)"
			];
		}

		return $options;
	}

	public function noimage($image)
	{
		if(empty($image)){
			$image = 'assets/images/noimage.png';
		}
		return $image;
	}


}
?>