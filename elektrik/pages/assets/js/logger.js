$(document).ready(function () {
  const loggerSpan = document.getElementById("logContent");
  const floatingLogger = document.getElementById("floatingLogger");

  const socketUrl = (typeof CONFIG !== 'undefined' && CONFIG.SOCKET_URL) 
                    ? CONFIG.SOCKET_URL 
                    : window.location.origin;

  const socket = io(socketUrl, {
    transports: ['websocket', 'polling']
  });

  const statusIcon = {
    success: '<i class="fa-solid fa-circle-check text-success me-2"></i>',
    error:   '<i class="fa-solid fa-circle-xmark text-danger me-2"></i>',
    warning: '<i class="fa-solid fa-triangle-exclamation text-warning me-2"></i>',
    info:    '<i class="fa-solid fa-info-circle text-primary me-2"></i>',
    finish:  '<i class="fa-solid fa-circle-check text-success me-2"></i>'
  };

  socket.on("status_update", function (data) {
    const statusKey = data.status?.toLowerCase();
    const icon = statusIcon[statusKey] || statusIcon.info;
    const message = `<strong>[${data.status}]</strong> ${data.message}`;

    if (loggerSpan) loggerSpan.innerHTML = icon + message;
    if (floatingLogger) floatingLogger.style.display = "block";

    console.log("Log Update:", data);

    if (statusKey === "finish") {
      setTimeout(function() {
        window.location.reload();
      }, 2000);
    }
  });
});