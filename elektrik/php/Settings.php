<?php
class Settings
{

    private $db;
    public $sesi;
    function __construct($db)
    {
        $this->db = $db;
    }
	
	public function fotoProfil()
	{
		$username = $_SESSION['login']['username'];

		$result = mysqli_query($this->db, "SELECT foto FROM akun WHERE username = '$username' LIMIT 1");

		if ($result && mysqli_num_rows($result) > 0) {
			$row = mysqli_fetch_assoc($result);
			$foto = $row['foto'] ?? '';
			return !empty($foto) ? $foto : 'assets/images/nofotoprofile.png';
		}

		return 'assets/images/nofotoprofile.png';
	}
	
	public function namaLengkap()
	{
		$username = $_SESSION['login']['username'];

		$result = mysqli_query($this->db, "SELECT nama FROM akun WHERE username = '$username' LIMIT 1");

		if ($result && ($row = mysqli_fetch_assoc($result))) {
			$nama = trim($row['nama'] ?? '');
			return $nama;
		}
		return '';

	}

}
?>