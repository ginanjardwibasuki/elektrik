document.addEventListener("DOMContentLoaded", function () {
  const credit = document.getElementById("creditText");
  const versions = [
    `© ${new Date().getFullYear()} Designed by Ginanjar Dwi Basuki`,
    `© ${new Date().getFullYear()} Tim Elektrik Adaro Energy`
  ];
  let index = 0;

  setInterval(() => {
    credit.style.opacity = "0";
    setTimeout(() => {
      index = (index + 1) % versions.length;
      credit.innerHTML = versions[index];
      credit.style.opacity = "1";
    }, 400);
  }, 3000);
});