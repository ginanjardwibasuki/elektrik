window.addEventListener("DOMContentLoaded", () => {
    if (sessionAlert?.show) {
        Swal.fire({
            icon: sessionAlert.status || "info",
            title: sessionAlert.status === "success" ? "✅ Berhasil!" :
                   sessionAlert.status === "error"   ? "❌ Gagal!" :
                   sessionAlert.status === "warning" ? "⚠️ Peringatan!" : "ℹ️ Info",
            text: sessionAlert.message || "Operasi selesai.",
            showConfirmButton: false,
            timer: 1800,
            timerProgressBar: true
        });
    }
});