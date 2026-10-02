$(document).ready(function() {
	function checkHMValues() {
    let inHM = document.getElementById("inHM").value;

    // Jika kosong, maka nilai yang dikirim adalah 100
    document.getElementById("hm").value = inHM === "" ? 0 : inHM;

}
	
	function checkSOCValues() {
    let insoc1 = document.getElementById("insoc1").value;
    let insoc2 = document.getElementById("insoc2").value;
    let insoc3 = document.getElementById("insoc3").value;

    // Jika kosong, maka nilai yang dikirim adalah 100
    document.getElementById("soc1").value = insoc1 === "" ? 100 : insoc1;
    document.getElementById("soc2").value = insoc2 === "" ? 100 : insoc2;
    document.getElementById("soc1_2").value = insoc3 === "" ? 100 : insoc3;

}

function checkRCCValues() {
    let inrcc1 = document.getElementById("inrcc1").value;
    let inrcc2 = document.getElementById("inrcc2").value;
    let inrcc3 = document.getElementById("inrcc3").value;

    // Jika kosong, maka nilai yang dikirim adalah 100
    document.getElementById("rcc1").value = inrcc1 === "" ? 100 : inrcc1;
    document.getElementById("rcc2").value = inrcc2 === "" ? 100 : inrcc2;
    document.getElementById("rcc1_2").value = inrcc3 === "" ? 100 : inrcc3;

}

	function calculateZI() {
// Ambil nilai RCC dan pastikan tidak kosong
let inrcc1 = document.getElementById("inrcc1").value.trim();
let inrcc2 = document.getElementById("inrcc2").value.trim();
let inrcc3 = document.getElementById("inrcc3").value.trim();

// Jika RCC kosong, gunakan nilai acak dalam rentang 2.56 - 3.17
let zi1 = inrcc1 === "" ? (Math.random() * (3.17 - 2.56) + 2.56).toFixed(2) : ((inrcc1 - 262.69) / -51.28).toFixed(2);
let zi2 = inrcc2 === "" ? Math.min((parseFloat(zi1) + (Math.random() * (0.05 - 0.02) + 0.02) * (Math.random() < 0.5 ? -1 : 1)), 3.17).toFixed(2) : ((inrcc2 - 262.69) / -51.28).toFixed(2);
let zi1_2 = inrcc3 === "" ? (Math.random() * (6.34 - 5.12) + 5.12).toFixed(2) : (-0.03625 * inrcc3 +  10.051).toFixed(2);





        document.getElementById("zi1").value = zi1;
        document.getElementById("zi2").value = zi2;
        document.getElementById("zi1_2").value = zi1_2;
    }
	
	function calculateCCAandSAE() {
		calculateZI();
    let zi1 = parseFloat(document.getElementById("zi1").value) || 0;
    let zi2 = parseFloat(document.getElementById("zi2").value) || 0;
    let zi1_2 = parseFloat(document.getElementById("zi1_2").value) || 0;

// Hitung CCA berdasarkan interpolasi linier
    let cca1 = Math.round(-452.59 * zi1 + 2473.23);
    let cca2 = Math.round(-452.59 * zi2 + 2473.23);
    let cca1_2 = Math.round(-150 * zi1_2 + 1976);

    // Hitung SAE berdasarkan interpolasi linier
    let sae1 = Math.round(-415.56 * zi1 + 2271.43);
    let sae2 = Math.round(-415.56 * zi2 + 2271.43);
    let sae1_2 = Math.round(-137.82 * zi1_2 + 1824.87);



    // Masukkan hasil ke input hidden
    document.getElementById("cca1").value = cca1;
    document.getElementById("cca2").value = cca2;
    document.getElementById("cca1_2").value = cca1_2;

    document.getElementById("sae1").value = sae1;
    document.getElementById("sae2").value = sae2;
    document.getElementById("sae1_2").value = sae1_2;
}

function calculateVolt() {
	let insoc1 = document.getElementById("insoc1").value;
    let insoc2 = document.getElementById("insoc2").value;
    let insoc3 = document.getElementById("insoc3").value;
	
	
	// Fungsi untuk memberikan nilai acak dalam rentang tertentu
    function getRandomVolt(min, max) {
        return (Math.random() * (max - min) + min).toFixed(2);
    }

    // Jika SOC kosong → Gunakan nilai acak, jika ada isi → Hitung volt secara linier
    let volt1 = insoc1 === "" ? getRandomVolt(12.72, 13.22) : (0.015 * insoc1 + 11.215).toFixed(2);
    let volt2 = insoc2 === "" ? getRandomVolt(12.72, 13.22) : (0.015 * insoc2 + 11.215).toFixed(2);
    let volt1_2 = insoc3 === "" ? (Math.random() * (25.85 - 25.40) + 25.40).toFixed(2) : (0.0225 * insoc3 + 23.15).toFixed(2);




    // Masukkan hasil ke input hidden
    document.getElementById("volt1").value = volt1;
    document.getElementById("volt2").value = volt2;
    document.getElementById("volt1_2").value = volt1_2;
}

function calculateCrank() {
	
let cp = Math.floor(Math.random() * (569 - 305) + 305);
let sc = Math.floor(Math.random() * (1657 - 412) + 412);
let sca = Math.floor(Math.random() * (700 - 400) + 400);
let rv = Math.floor(Math.random() * (28 - 12) + 12);
let tv = (Math.random() * (28.65 - 27.80) + 27.80).toFixed(2);

	document.getElementById("cp").value = cp;
    document.getElementById("sc").value = sc;
    document.getElementById("sca").value = sca;
	document.getElementById("rv").value = rv;
    document.getElementById("tv").value = tv;
}
	
	document.getElementById("openModal").addEventListener("click", function() {
		let codeUnitInput = document.getElementById("unit").value;

    // Validasi jika Code Unit kosong menggunakan SweetAlert
    if (codeUnitInput.trim() === "") {
        Swal.fire({
            icon: "warning",
            title: "Oops...",
            text: "Harap isi Code Unit terlebih dahulu!",
            confirmButtonColor: "#3085d6",
            confirmButtonText: "OK"
        });
        return; // Hentikan eksekusi jika Code Unit kosong
    }

		checkHMValues();
		checkSOCValues();
		checkRCCValues();
		calculateCCAandSAE();
		calculateVolt();
		calculateCrank();
		
        let formData = new FormData(document.getElementById("batteryForm"));
let batteryData = {
    "Battery 1": {},
    "Battery 2": {},
    "Battery Seri": {},
    "Crank": {}
};

// Mapping untuk mengganti nama key agar lebih jelas
const keyMapping = {
    "pic": "PIC",
    "unit": "Code Unit", // Hanya untuk ditampilkan di atas, tidak masuk tabel
    "hm": "HM",

    // Battery 1
    "soc1": "SOC", "zi1": "ZI", "rcc1": "RCC", "cca1": "CCA", "sae1": "SAE", "volt1": "Volt",

    // Battery 2
    "soc2": "SOC", "zi2": "ZI", "rcc2": "RCC", "cca2": "CCA", "sae2": "SAE", "volt2": "Volt",

    // Battery Seri
    "soc1_2": "SOC", "zi1_2": "ZI", "rcc1_2": "RCC", "cca1_2": "CCA", "sae1_2": "SAE", "volt1_2": "Volt",

    // Crank (Tanpa Code Unit)
    "cp": "CP", "sc": "SC", "sca": "SCA", "rv": "RV", "tv": "TV"
};

// Variabel untuk menyimpan PIC dan Code Unit terpisah
let picValue = formData.get("pic") || "";
let unitValue = formData.get("unit") || "";
let HMValue = formData.get("hm") || "";

// Mengelompokkan data ke dalam objek `batteryData`
formData.forEach((value, key) => {
    if (!["pic", "unit", "hm", "inHM", "inrcc1", "unit", "inrcc2", "inrcc3", "insoc1", "insoc2", "insoc3"].includes(key)) { // Abaikan key yang tidak perlu
        let newKey = keyMapping[key] || key;
        let category = key.includes("1") && !key.includes("_") ? "Battery 1" :
                       key.includes("2") && !key.includes("_") ? "Battery 2" :
                       key.includes("1_2") ? "Battery Seri" : "Crank";

        batteryData[category][newKey] = value;
    }
});

// Menampilkan Code Unit dan PIC di atas tabel
document.getElementById("unitValue").innerText = unitValue;
document.getElementById("picValue").innerText = picValue;
document.getElementById("HMValue").innerText = HMValue;

// Format tampilan dalam tabel scrollable
let output = "";

Object.keys(batteryData).forEach(category => {
    let firstRow = true;
    Object.keys(batteryData[category]).forEach(param => {
        output += `<tr>`;
        if (firstRow) {
            output += `<td rowspan='${Object.keys(batteryData[category]).length}'><strong>${category}</strong></td>`;
            firstRow = false;
        }
        output += `<td>${param}</td>
                   <td>${batteryData[category][param]}</td>
                   </tr>`;
    });
});

output += `</tbody></table>`;

// Menampilkan tabel dalam modal
document.getElementById("modalContent").innerHTML = output;

        // Tampilkan modal
        var dataModal = new bootstrap.Modal(document.getElementById("dataModal"));
        dataModal.show();
    });

document.getElementById("confirmSubmit").addEventListener("click", function(event) {
    event.preventDefault(); // Cegah form langsung dikirim

    let formData = new FormData(document.getElementById("batteryForm"));

    // ✅ Tutup modal **segera** saat tombol diklik
    $("#dataModal").modal("hide");

    // ✅ Tampilkan SweetAlert pertama tanpa menunggu server
    Swal.fire({
        position: "center",
        icon: "success",
        title: "Input sukses!",
        showConfirmButton: false,
        timer: 1500
    });

    $.ajax({
        url: "https://nodebattery.adaro-indonesia.my.id/auto",
        type: "POST",
        data: $(document.getElementById("batteryForm")).serialize(), // Kirim data dalam format URL-encoded
        success: function(response) {
            // ✅ Tampilkan SweetAlert kedua setelah server merespons sukses
            Swal.fire({
                position: "center",
                icon: "success",
                title: "Data telah diterima server!",
                showConfirmButton: false,
                timer: 1500
            });

			location.reload();
        },
        error: function(xhr) {
            Swal.fire({
                title: "Gagal!",
                text: "Terjadi kesalahan dalam pengiriman.",
                icon: "error",
                confirmButtonColor: "#d33"
            });
        }
    });
});

	
    function adjustScroll(event) {
        setTimeout(() => {
            event.target.scrollIntoView({ behavior: "smooth", block: "center" });
        }, 300); // Delay agar efek lebih natural setelah keyboard muncul
    }

    // Menambahkan event listener ke semua input
    document.querySelectorAll("input").forEach(input => {
        input.addEventListener("focus", adjustScroll);
    });

document.getElementById("clearForm").addEventListener("click", function() {
        // Menghapus nilai semua input
        document.getElementById("unit").value = "";
		document.getElementById("inHM").value = "";
        document.getElementById("inrcc1").value = "";
        document.getElementById("inrcc2").value = "";
        document.getElementById("inrcc3").value = "";
        document.getElementById("insoc1").value = "";
        document.getElementById("insoc2").value = "";
        document.getElementById("insoc3").value = "";
    });


function moveFocus(nextInputId, event) {
    if (event.target.value.length === 3 && event.inputType !== "deleteContentBackward") {
        setTimeout(() => {
            document.getElementById(nextInputId).focus();
        }, 100); // Jeda agar tidak terganggu keyboard virtual
    }
}

document.getElementById("unit").addEventListener("input", function(event) {
    if (event.target.value.length === 3 && event.inputType !== "deleteContentBackward") {
        setTimeout(() => {
            event.target.blur();
        }, 100);
    }
});

        document.getElementById("toggleVoltase").addEventListener("click", function() {
            var rccRow = document.getElementById("rccRow");
			var voltaseRow = document.getElementById("voltaseRow");
            var button = document.getElementById("toggleVoltase");

            if (voltaseRow.style.display === "none") {
                rccRow.style.display = "flex";
				voltaseRow.style.display = "flex";
                button.innerHTML = "&#x25B2; Sembunyikan Input";
				rccRow.scrollIntoView({ behavior: "smooth", block: "start" });
            } else {
                rccRow.style.display = "none";
				voltaseRow.style.display = "none";
                button.innerHTML = "&#x25BC; Tampilkan Input";
            }

        });

        function validateInput(inputField, maxLength) {
            inputField.addEventListener("input", function() {
                var input = this.value.replace(/\D/g, '').substring(0, maxLength);
                this.value = input;
            });
        }

function formatInput(inputField, formatLength, dotPosition) {
    inputField.addEventListener("input", function() {
        var input = this.value.replace(/\D/g, '').substring(0, formatLength); // Hanya angka

        // Jika input kosong, set nilai ke 100
        var numericValue = input === "" ? "" : parseInt(input, 10);

        // Pastikan nilainya tetap dalam rentang 0 - 100
        numericValue = Math.min(100, Math.max(0, numericValue));

        // SOC tetap tanpa titik, tetapi format titik diterapkan jika `dotPosition > 0`
        if (dotPosition > 0) {
            if (numericValue.toString().length === formatLength) {
                this.value = numericValue.toString().substring(0, dotPosition) + "." + numericValue.toString().substring(dotPosition);
            } else {
                this.value = numericValue;
            }
        } else {
            this.value = numericValue; // Nilai default diterapkan
        }
    });
}


        validateInput(document.getElementById("unit"), 3);
        validateInput(document.getElementById("inrcc1"), 3);
        validateInput(document.getElementById("inrcc2"), 3);
        validateInput(document.getElementById("inrcc3"), 3);
        validateInput(document.getElementById("insoc1"), 2);
        validateInput(document.getElementById("insoc2"), 2);
        validateInput(document.getElementById("insoc3"), 2);

// Terapkan ke input yang diperlukan
formatInput(document.getElementById("inrcc1"), 3, 0);
formatInput(document.getElementById("inrcc2"), 3, 0);
formatInput(document.getElementById("inrcc3"), 3, 0);
formatInput(document.getElementById("insoc1"), 3, 0);
formatInput(document.getElementById("insoc2"), 3, 0);
formatInput(document.getElementById("insoc3"), 3, 0);
});