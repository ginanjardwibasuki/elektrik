setInterval(function() {
    fetch("../php/sessionCheck.php")
        .then(response => response.text())
        .then(status => {
            if (status.trim() !== "1") { 
                window.location.href = "login.php";
            }
        });
}, 5000);