<?php
class Auth
{

    private $db;
    public $sesi;
    function __construct($db)
    {
        $this->db = $db;
    }

    function cekSession()
	{
		$login = isset($_SESSION['login']) ? $_SESSION['login'] : null;
		if ($login == true) {
			return true;
		} else {
			return false;
		}
	}

    public function login($post)
    {
        $user = filter_var(mysqli_real_escape_string($this->db, $_POST["username"]), FILTER_SANITIZE_STRING);
        $password = filter_var(mysqli_real_escape_string($this->db, $_POST["password"]), FILTER_SANITIZE_STRING);
        $check = mysqli_query($this->db, "SELECT * FROM akun WHERE username = '$user' ");
        if (mysqli_num_rows($check) > 0) {
            $datauser = mysqli_fetch_assoc($check);

            if ($password == $datauser['password']) {
                if(!empty($_POST["remember"])) {
                    setcookie ("username",$_POST["username"],time()+ (3600 * 365 * 24 * 60 * 60));
                    setcookie ("password",$_POST["password"],time()+ (3600 * 365 * 24 * 60 * 60));
                } else {
                    if(isset($_COOKIE["username"])) {
                     setcookie ("username","");
                   }
                   if(isset($_COOKIE["password"])) {
                     setcookie ("password","");
                   }
                }
                $_SESSION['login'] = $datauser;
                $this->sesi = $_SESSION['login'];
                header('Location: '.$datauser["beranda"].'.php');
                exit;				
            } else {
				setcookie ("username","");
				setcookie ("password","");
                $_SESSION['alert'] = ['color' => 'danger', 'msg' => 'Username atau password salah!'];
                header('Location: login.php');
                exit;
            }
        } else {
			setcookie ("username","");
			setcookie ("password","");
            $_SESSION['alert'] = ['color' => 'danger', 'msg' => 'Username tidak terdaftar!'];
            header('Location: login.php');
            exit;
        }
    }

	public function changePass($post)
    {
		$oldpass=$post['oldpass'];
		$newpass=$post['newpass'];
		$confnewpass=$post['confnewpass'];
        $username = $_SESSION['login']['username'];
        if (strlen($newpass) < 6) {
			setNotif("error", "Password minimal 6 karakter!");
            redirect('pengaturan.php');
        }
        if ($newpass != $confnewpass) {
			setNotif("error", "Konfirmasi kata sandi tidak sesuai!");
            redirect('pengaturan.php');
        }
        $cek = mysqli_query($this->db, "SELECT * FROM akun WHERE username = '$username'");
        if (mysqli_num_rows($cek) > 0) {
            $datauser = mysqli_fetch_assoc($cek);

            if ($oldpass == $datauser['password']) {
                if (mysqli_query($this->db, "UPDATE akun SET password = '$newpass' WHERE username = '$username' ") === true) {
					setNotif("success", "Ganti kata sandi berhasil silahkan login dengan password yang baru!");
                    session_destroy();
                    redirect('login.php');
                }
				setNotif("error", "Kesalahan system!");
                redirect('pengaturan.php');
            }
			setNotif("error", "Kata sandi lama salah!");
            redirect('pengaturan.php');
        }
    }

}
?>