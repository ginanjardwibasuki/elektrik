$(document).ready(function() {
	window.openDataModal = function(id, name, partNumber, vendor, imageSrc, keyword) {
	  document.getElementById("modalName").innerText = name;
	  document.getElementById("modalPartNumber").innerText = partNumber;
	  document.getElementById("modalVendor").innerText = vendor;
	  document.getElementById("modalImage").src = imageSrc;

	  // Tampilkan keyword sebagai tag
	  const keywordContainer = document.getElementById("modalKeywordTags");
	  keywordContainer.innerHTML = ""; // Reset
	  keyword.split(',').forEach(kw => {
		if (kw.trim()) {
		  const tag = document.createElement("span");
		  tag.className = "badge bg-warning text-dark px-3 py-2";
		  tag.textContent = kw.trim();
		  keywordContainer.appendChild(tag);
		}
	  });

	  const myModal = new bootstrap.Modal(document.getElementById('dataModal'));
	  myModal.show();
	};

	window.editData = function(id, gambar, name, partNumber, vendor, keyword) {
        document.getElementById("editId").value = id;
        document.getElementById("editGambar1").src = gambar && gambar !== "null" ? gambar : "assets/images/noimage.png";
        document.getElementById("exist_gambar").value = gambar;
        document.getElementById("editName").value = name;
        document.getElementById("editPartNumber").value = partNumber;
        document.getElementById("part_ori").value = partNumber;
        document.getElementById("editinputankeyword").value = keyword;
        
        document.getElementById("editVendor").value = vendor;

        var editModal = new bootstrap.Modal(document.getElementById('editModal'));
        editModal.show();
    }

	window.deleteData = function(id, gambar) {
        document.getElementById("deleteId").value = id;
        document.getElementById("deleteGambar").value = gambar;
        
        var modalHapus = new bootstrap.Modal(document.getElementById('modalHapus'));
        modalHapus.show();
    }

	window.copyText = function(name, partNumber) {
        const copiedText = `Nama: ${name} \n Part Number: ${partNumber}`;
        navigator.clipboard.writeText(copiedText).then(() => {
            Swal.fire({
                title: 'Copied!',
                html: `<pre>${copiedText}</pre>`,
                icon: 'success',
                timer: 2000,
                showConfirmButton: false
            });
        }).catch(err => {
            Swal.fire({
                title: 'Error!',
                text: 'Unable to copy text',
                icon: 'error'
            });
        });
    }

    const gambarElement = document.getElementById("editGambar1");
    const inputFile = document.getElementById("editGambar2");

    gambarElement.addEventListener("click", () => inputFile.click());

    inputFile.addEventListener("change", (event) => {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => gambarElement.src = e.target.result;
            reader.readAsDataURL(file);
        }
    });
	
  const modalMenu = document.getElementById('modalMenu');
  const modalCopy = new bootstrap.Modal(document.getElementById('modalCopy'));
  const modalHapusSemua = new bootstrap.Modal(document.getElementById('modalHapusSemua'));

  // Saat tombol Copy diklik di dalam modal Menu
  modalMenu.querySelector('[data-bs-target="#modalCopy"]').addEventListener('click', function (e) {
    e.preventDefault(); // Hindari default modal behavior

    // Setelah modalMenu ditutup, baru buka modalCopy
    modalMenu.addEventListener('hidden.bs.modal', function openCopyModalOnce() {
      modalCopy.show();
      modalMenu.removeEventListener('hidden.bs.modal', openCopyModalOnce);
    });

    // Tutup modalMenu lebih dulu
    const menuModalInstance = bootstrap.Modal.getInstance(modalMenu);
    menuModalInstance.hide();
  });
  
  // Saat tombol Copy diklik di dalam modal Menu
  modalMenu.querySelector('[data-bs-target="#modalHapusSemua"]').addEventListener('click', function (e) {
    e.preventDefault(); // Hindari default modal behavior

    // Setelah modalMenu ditutup, baru buka modalCopy
    modalMenu.addEventListener('hidden.bs.modal', function openmodalHapusSemuaOnce() {
      modalHapusSemua.show();
      modalMenu.removeEventListener('hidden.bs.modal', openmodalHapusSemuaOnce);
    });

    // Tutup modalMenu lebih dulu
    const menuModalInstance = bootstrap.Modal.getInstance(modalMenu);
    menuModalInstance.hide();
  });
  
  const textarea = document.getElementById('keywordInput');
  const tagWrapper = document.getElementById('tagWrapper');
  const keywordsvalue = document.getElementById('inputankeyword');
  const keywords = [];

  function updateTextarea() {
	keywordsvalue.value = keywords.join(', ');
  }

  function createTag(label) {
    const tag = document.createElement('span');
    tag.className = 'tag';
    tag.textContent = label;

    const removeBtn = document.createElement('button');
    removeBtn.className = 'remove';
    removeBtn.innerHTML = '&times;';
    removeBtn.onclick = function () {
      const index = keywords.indexOf(label);
      if (index !== -1) keywords.splice(index, 1);
      tagWrapper.removeChild(tag);
      updateTextarea();
    };

    tag.appendChild(removeBtn);
    tagWrapper.appendChild(tag);
  }

	// Trigger ketika user mengetik koma
	textarea.addEventListener('input', function () {
	  const value = textarea.value;
	  if (value.includes(',')) {
		const raw = value.replace(',', '').trim();
		if (raw && !keywords.includes(raw)) {
		  keywords.push(raw);
		  createTag(raw);
		  updateTextarea();
		}
		textarea.value = '';
	  }
	});

	// Trigger ketika user menekan Enter
	textarea.addEventListener('keydown', function (e) {
	  if (e.key === 'Enter') {
		e.preventDefault(); // Hindari line break di textarea
		const raw = textarea.value.trim();
		if (raw && !keywords.includes(raw)) {
		  keywords.push(raw);
		  createTag(raw);
		  updateTextarea();
		}
		textarea.value = '';
	  }
	});

modalTambah.addEventListener('hidden.bs.modal', function () {
    keywords.length = 0;
    tagWrapper.innerHTML = '';
    textarea.value = '';
  });

document.getElementById('formTambahSparepart').addEventListener('submit', function (e) {
    e.preventDefault();

    const form = e.target;
    const formData = new FormData(form);
    formData.append('tambah', '1');

    $("#modalTambah").modal("hide");

    Swal.fire({
    title: '<span style="font-weight:600; font-size:1.2rem;">🚀 Mengupload file...</span>',
    html: `
        <div style="
            background: linear-gradient(90deg, #e0f7fa, #fce4ec);
            padding: 12px 14px;
            border-radius: 8px;
            margin-bottom: 14px;
            font-size: 0.85rem;
            color: #333;
            text-align: justify;
            box-shadow: inset 0 0 6px rgba(0,0,0,0.05);">
            💡 <strong>Tip:</strong> Gunakan file gambar beresolusi kecil agar proses upload lebih cepat dan stabil.
        </div>
        <div class="progress" style="
            height: 22px;
            background-color: #eeeeee;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: inset 0 1px 3px rgba(0,0,0,0.2);">
            <div id="uploadProgressBar" class="progress-bar" role="progressbar" style="
                width: 0%;
                background: linear-gradient(90deg, #64b5f6, #81c784);
                font-weight: bold;
                transition: width 0.4s ease;">
                0%
            </div>
        </div>
    `,
        allowOutsideClick: false,
        showConfirmButton: false,
        didOpen: () => {

            const xhr = new XMLHttpRequest();
            xhr.open("POST", window.location.pathname, true);

            xhr.upload.onprogress = function (e) {
                if (e.lengthComputable) {
                    const percent = Math.round((e.loaded / e.total) * 100);
                    const bar = document.getElementById('uploadProgressBar');
                    bar.style.width = percent + "%";
                    bar.textContent = percent + "%";
                }
            };

            xhr.onload = function () {
                try {
                    const data = JSON.parse(xhr.responseText);
                    if (data.success) {
						Swal.fire({
							icon: "success",
							title: "Berhasil!",
							text: data.message || "Upload selesai.",
							background: "linear-gradient(135deg, #feffdd, #fefefe)",
							color: "#2c3e50",
							showConfirmButton: false,
							timer: 1800,
							timerProgressBar: true,
							didOpen: () => {
								const swalContainer = Swal.getPopup();
								if (swalContainer) {
									swalContainer.style.borderRadius = "12px";
									swalContainer.style.boxShadow = "0 6px 18px rgba(0,0,0,0.1)";
									swalContainer.style.border = "1px solid #d1e7dd";
									swalContainer.style.backdropFilter = "blur(6px)";
									swalContainer.style.animation = "scaleIn 0.4s ease";
								}
							}
						}).then(() => {
							window.location.reload();
						});
					} else {
                        throw new Error(data.message || "Upload gagal.");
                    }
                } catch (err) {
                    Swal.fire({
                        icon: "warning",
                        title: "Gagal menambahkan data.",
                        text: err.message,
                        showConfirmButton: false,
                        timer: 3000
                    }).then(() => {
                            window.location.reload();
                        });
                }
            };

            xhr.onerror = function () {
                Swal.fire({
                    icon: "question",
                    title: "Error jaringan?",
                    text: "Tidak bisa terhubung ke server.",
                    showConfirmButton: false,
                    timer: 3000
                }).then(() => {
                            window.location.reload();
                        });
            };

            xhr.send(formData);
        }
    });
});

document.getElementById("copyForm").addEventListener("submit", function (e) {
    e.preventDefault();

    const formData = new FormData(e.target);
	formData.append('copy', '1');
    const modalCopy = bootstrap.Modal.getInstance(document.getElementById('modalCopy'));
    if (modalCopy) modalCopy.hide();

    let progress = 0;

    Swal.fire({
		title: '<span style="font-weight:600; font-size:1.2rem;">📁 Menyalin database sparepart...</span>',
		html: `
			<div style="
				background: linear-gradient(90deg, #e0f7fa, #fce4ec);
				padding: 12px 14px;
				border-radius: 8px;
				margin-bottom: 14px;
				font-size: 0.85rem;
				color: #333;
				text-align: justify;
				box-shadow: inset 0 0 6px rgba(0,0,0,0.05);">
				🧠 <strong>Info:</strong> File salinan akan disesuaikan secara otomatis dan disimpan sesuai struktur pengguna aktif. Proses ini mungkin memakan waktu tergantung jumlah data.
			</div>
			<div class="progress" style="
				height: 22px;
				background-color: #eeeeee;
				border-radius: 10px;
				overflow: hidden;
				box-shadow: inset 0 1px 3px rgba(0,0,0,0.2);">
				<div id="progressBar" class="progress-bar" role="progressbar" style="
					width: 0%;
					background: linear-gradient(90deg, #64b5f6, #81c784);
					font-weight: bold;
					color: #fff;
					transition: width 0.4s ease;">
					0%
				</div>
			</div>
		`,
		showConfirmButton: false,
		allowOutsideClick: false,
        didOpen: () => {
            const barEl = document.getElementById("progressBar");

            fetch(window.location.pathname, {
                method: "POST",
                body: formData
            });

            const interval = setInterval(() => {
                progress += Math.floor(Math.random() * 10) + 3; // random 5–12%

                if (progress > 100) progress = 100;
                barEl.style.width = progress + "%";
                barEl.textContent = progress + "%";

                if (progress >= 100) {
                    clearInterval(interval);
                    Swal.fire({
                        icon: "success",
                        title: "Selesai!",
                        text: "Copy data selesai!",
                        showConfirmButton: false,
                        timer: 1500
                    }).then(() => window.location.reload());
                }
            }, 300);
        }
    });
});

document.getElementById('formEditSparepart').addEventListener('submit', function (e) {
    e.preventDefault();

    const form = e.target;
    const formData = new FormData(form);
    formData.append('edit', '1');

    $("#editModal").modal("hide");

    Swal.fire({
    title: '<span style="font-weight:600; font-size:1.2rem;">🚀 Mengupdate data...</span>',
    html: `
        <div style="
            background: linear-gradient(90deg, #e0f7fa, #fce4ec);
            padding: 12px 14px;
            border-radius: 8px;
            margin-bottom: 14px;
            font-size: 0.85rem;
            color: #333;
            text-align: justify;
            box-shadow: inset 0 0 6px rgba(0,0,0,0.05);">
            💡 <strong>Tip:</strong> Gunakan file gambar beresolusi kecil agar proses upload lebih cepat dan stabil.
        </div>
        <div class="progress" style="
            height: 22px;
            background-color: #eeeeee;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: inset 0 1px 3px rgba(0,0,0,0.2);">
            <div id="uploadProgressBar" class="progress-bar" role="progressbar" style="
                width: 0%;
                background: linear-gradient(90deg, #64b5f6, #81c784);
                font-weight: bold;
                transition: width 0.4s ease;">
                0%
            </div>
        </div>
    `,
        allowOutsideClick: false,
        showConfirmButton: false,
        didOpen: () => {

            const xhr = new XMLHttpRequest();
            xhr.open("POST", window.location.pathname, true);

            xhr.upload.onprogress = function (e) {
                if (e.lengthComputable) {
                    const percent = Math.round((e.loaded / e.total) * 100);
                    const bar = document.getElementById('uploadProgressBar');
                    bar.style.width = percent + "%";
                    bar.textContent = percent + "%";
                }
            };

            xhr.onload = function () {
                try {
                    const data = JSON.parse(xhr.responseText);
                    if (data.success) {
						Swal.fire({
							icon: "success",
							title: "Berhasil!",
							text: data.message || "Update selesai.",
							background: "linear-gradient(135deg, #feffdd, #fefefe)",
							color: "#2c3e50",
							showConfirmButton: false,
							timer: 1800,
							timerProgressBar: true,
							didOpen: () => {
								const swalContainer = Swal.getPopup();
								if (swalContainer) {
									swalContainer.style.borderRadius = "12px";
									swalContainer.style.boxShadow = "0 6px 18px rgba(0,0,0,0.1)";
									swalContainer.style.border = "1px solid #d1e7dd";
									swalContainer.style.backdropFilter = "blur(6px)";
									swalContainer.style.animation = "scaleIn 0.4s ease";
								}
							}
						}).then(() => {
							window.location.reload();
						});
					} else {
                        throw new Error(data.message || "Update gagal.");
                    }
                } catch (err) {
                    Swal.fire({
                        icon: "warning",
                        title: "Gagal menambahkan data.",
                        text: err.message,
                        showConfirmButton: false,
                        timer: 3000
                    }).then(() => {
                            window.location.reload();
                        });
                }
            };

            xhr.onerror = function () {
                Swal.fire({
                    icon: "question",
                    title: "Error jaringan?",
                    text: "Tidak bisa terhubung ke server.",
                    showConfirmButton: false,
                    timer: 3000
                }).then(() => {
                            window.location.reload();
                        });
            };

            xhr.send(formData);
        }
    });
});


});