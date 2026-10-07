<?php
include '../helper/function.php';

$auth = new Auth($db);

if ($auth->cekSession() == 1) {
    redirect("home.php");
}

if (isset($_POST['login'])) {
    var_dump($auth->login($_POST));
}

?>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Portal Login</title>
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="expires" content="-1" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
    <link rel="stylesheet" href="assets/css/login.css" media="screen">
	<style>
        .input-container {
            position: relative;
            display: inline-block;
        }

        input[type="password"] {
			font-family: monospace; /* Gunakan font monospaced agar karakter terlihat seragam */
			text-align: center; /* Menengahkan teks */
		}


        .toggle-password {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            cursor: pointer;
            font-size: 16px;
        }
    </style>

	
  </head>
  <body class='login'>
    <form class="vertical-form" action="" method="post" background="#A03472" autocomplete="off">
      <div style="margin:0;padding:0;display:inline"></div>
      <legend>
        <img class="logo" src="assets/images/logo.png" />
      </legend>


      <input id="username" name="username" type="text" placeholder="Username" size="30" value="<?php if(isset($_COOKIE['username'])) { echo $_COOKIE['username']; } ?>">
	  	  <div class="input-container">
			<input id="password" name="password" type="password" label="false" placeholder="Password" size="30" value="<?php if(isset($_COOKIE['password'])) { echo $_COOKIE['password']; } ?>">
			<button type="button" class="toggle-password" onclick="togglePassword()">👁️</button>
		</div>
      <br>
      <div class="container">
        <label for="checkbox-1">
          <input type="checkbox" id="checkbox-1" name="remember" <?php if(isset($_COOKIE['username'])) { ?> checked <?php } ?>> 💡 Ingat password </label>
      </div>
      <br>
      <input name="login" type="submit" value="MASUK" />
    </form>
    <script type="text/javascript">
      document.getElementById("username").focus();
    </script>
	<script>
    function togglePassword() {
        const passwordField = document.getElementById("password");
        const button = document.querySelector(".toggle-password");
        
        if (passwordField.type === "password") {
            passwordField.type = "text";
            button.textContent = "🙈"; // Ubah ikon ke mata tertutup
        } else {
            passwordField.type = "password";
            button.textContent = "👁️"; // Ubah ikon ke mata terbuka
        }
    }
</script>

  </body>
</html>