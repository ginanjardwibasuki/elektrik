import express from 'express';
import puppeteer from 'puppeteer';
import { Queue, Worker } from 'bullmq';
import http from 'http';
import fs from 'fs';
import { Server } from 'socket.io';
import crypto from "crypto";

const app = express();
const server = http.createServer(app);

const io = new Server(server);
const connection = {
    host: '127.0.0.1',
    port: 6379,
    maxRetriesPerRequest: null,
    enableOfflineQueue: true,
    retryStrategy: (times) => Math.min(times * 100, 3000)
};

const postQueue = new Queue('battery-post-tasks', { connection });
import { pool } from "./main/Database.js";

app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
    res.header("Access-Control-Allow-Headers", "Content-Type");
    next();
});
app.use(express.urlencoded({ extended: true }));

// Fungsi pembantu untuk mencetak log dengan timestamp presisi
function logAksi(pesan) {
    const waktu = new Date().toLocaleString('id-ID', { timeZone: 'Asia/Makassar' }); // Sesuaikan timezone dengan server/daerahmu
    console.log(`[${waktu}] ${pesan}`);
}

// Fungsi pembantu untuk mencari selector dengan log otomatis
async function cariElemen(page, selector, deskripsi) {
    logAksi(`Mencari elemen: "${deskripsi}" (${selector})...`);
    try {
        const elemen = await page.waitForSelector(selector, { visible: true, timeout: 30000 });
        logAksi(`[SUKSES] Elemen "${deskripsi}" ditemukan.`);
        return elemen;
    } catch (error) {
        logAksi(`[GAGAL] Elemen "${deskripsi}" TIDAK ditemukan dalam 30 detik.`);
        throw error;
    }
}

// Fungsi pembantu untuk mengisi input dengan log otomatis
async function isiInput(page, selector, deskripsi, nilai, socket, pesanSocket) {
    const elemen = await cariElemen(page, selector, deskripsi);
    logAksi(`Mengisi "${deskripsi}" dengan nilai: "${nilai}"`);
    await elemen.click();
    await elemen.type(nilai);
    await elemen.press('Enter');
    logAksi(`[SUKSES] Selesai mengisi "${deskripsi}".`);
    if (socket && pesanSocket) {
        socket.emit('status_update', pesanSocket);
    }
}

app.post('/auto', async (req, res) => {
    const { pic, unit, hm, soc1, zi1, rcc1, cca1, sae1, volt1, soc2, zi2, rcc2, cca2, sae2, volt2, soc1_2, zi1_2, rcc1_2, cca1_2, sae1_2, volt1_2, cp, sc, sca,rv, tv } = req.body;	
	const unique_id = generateUniqueId();
	
	if (
        !pic || !unit || !hm || !soc1 || !zi1 || !rcc1 || !cca1 || !sae1 || !volt1 || 
        !soc2 || !zi2 || !rcc2 || !cca2 || !sae2 || !volt2 || !soc1_2 || !zi1_2 || 
        !rcc1_2 || !cca1_2 || !sae1_2 || !volt1_2 || !cp || !sc || !sca || !rv || !tv
    ) {
        return res.status(400).send("Semua variabel diperlukan. Pastikan tidak ada yang kosong.");
    }

    res.status(200).send(`Scraping untuk ${pic} ditambahkan ke antrian.`);

    await postQueue.add('post-battery', 
        { pic, unit, hm, soc1, zi1, rcc1, cca1, sae1, volt1, soc2, zi2, rcc2, cca2, sae2, volt2, soc1_2, zi1_2, rcc1_2, cca1_2, sae1_2, volt1_2, cp, sc, sca,rv, tv, unique_id }, 
		{
			attempts: 5,
			backoff: { type: 'exponential', delay: 3000 },
			removeOnFail: false
		}
	);
	io.emit('status_update', { status: "added", message: `Input data HT140-0${unit} ditambahkan ke antrian.` });
	pool.query('INSERT INTO battery_input (unique_id, pic, unit, status) VALUES (?, ?, ?, ?)', 
		[unique_id, pic, unit, 'antrian'], 
		(err, results) => {
			if (err) { logAksi(`[DB ERROR] Gagal insert data: ${err.message}`); return; }
			logAksi(`[DB] Data berhasil dimasukkan untuk ID: ${unique_id}`);
		}
	);
});

const worker = new Worker('battery-post-tasks', async (job) => {
    const unitLabel = `HT140-0${job.data.unit}`;
    io.emit('status_update', { status: unitLabel, message: `Memulai input data.` });
    
    pool.query('UPDATE battery_input SET status = ? WHERE unique_id = ?', ['proses', job.data.unique_id], (err) => {
        if (err) logAksi(`[DB ERROR] Gagal update status ke 'proses': ${err.message}`);
    });
    logAksi(`--- MEMULAI PROSES SCRAPING UNTUK UNIT: ${unitLabel} ---`);

    // const user_data_dir = '/tmp/puppeteer_battery_cache';
    const browser = await puppeteer.launch({
        headless: true,
        // userDataDir: user_data_dir,
		executablePath: '/usr/bin/chromium-browser',
        args: [
            "--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage",
            "--disable-gpu", "--disable-software-rasterizer", "--disable-extensions",
            "--disable-background-networking", "--disable-default-apps", "--disable-sync",
            "--disable-translate", "--enable-aggressive-dom-release", "--disable-site-isolation-trials"
        ]
    });

    logAksi("Browser berhasil diluncurkan.");
    const page = await browser.newPage();

    await page.setRequestInterception(true);
    page.on('request', (request) => {
        const resourceType = request.resourceType();
        if (resourceType === 'image' || resourceType === 'font') {
            request.abort();
        } else {
            request.continue();
        }
    });

    await page.setViewport({ width: 1366, height: 768 });

    logAksi("Membuka URL AppSheet...");
    await page.goto('https://www.appsheet.com/start/f6eb2eef-d4b8-42c3-a513-4e9f71fa5c2c?platform=desktop#vss=H4sIAAAAAAAAA6WS0U_CMBDG_xVzz8XUgcnsm44-LAY0Y5KI5aHSLlnc1oUVlSz7370hi8RgGPWxd_e7ft-Xq-E91R8zK1dvwF7qn9e93gKDWkC8LbUAJiAwhV2bTAARMJX5d3HCp08CGmjI-ewjj8KHcRhczHg0DwPuuufuNo559LzDl6TDra6A1f0dMHfzBFKlC5smqV63e1oK-T2D7ZbAQjuPDiHfWPma6Z1InG-w5BSWg-Rja_rK_80esdJBfxEEImMsdpTGgyMwllYim5dY8qh3PaCjAfXjK8qGHqPe5fBm5FHfX0CvjA4OwSGaA7pvInvkdBDd4D_84x-JWW0qreZo7HxDVVjwz1IWamIUSkpkVunmC34C4P7_AwAA&view=BATTERY&appName=PERIODICSERVICEAPP-789464963');

    // Pencarian Elemen Pemuatan Awal
    logAksi("Menunggu deteksi elemen header atau dialog izin...");
    await page.waitForFunction(() => {
        const xpathElement = document.evaluate('//h6[text()="When you use this app, the app creator may receive:"]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
        const selectorElement = document.querySelector('#ReactRoot > div > header > div > h6');
        window.selectedElement = xpathElement ? "1" : selectorElement ? "2" : null;
        return !!xpathElement || !!selectorElement;
    });

    const selectedElement = await page.evaluate(() => window.selectedElement);
    logAksi(`[LOG CABANG] Elemen yang muncul lebih dulu: Rute ${selectedElement}`);

    if (selectedElement === "1") {
        logAksi("Menekan tombol dialog izin AppSheet (Rute 1)...");
        const button = await page.evaluateHandle(() => {
            return document.evaluate('/html/body/div[16]/div[3]/div/div/div[2]/div/div[2]/button[2]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
        });
        await button.click();
        
        await cariElemen(page, '#ReactRoot > div > header > div > h6', 'Header AppSheet');

        logAksi("Memulai loop deteksi '.EmptyView'...");
        while (true) {
            const emptyViewExists = await page.evaluate(() => document.querySelector('.EmptyView') !== null);
            if (!emptyViewExists) {
                logAksi("Loading data selesai ('.EmptyView' tidak ada).");
                io.emit('status_update', { status: unitLabel, message: `Loading halaman selesai.` });
                break;
            }
            await delay(500);
        }
    } else {
        logAksi("Menunggu teks 'Syncing...' muncul (Rute 2)...");
        while (true) {
            const jsHandle = await page.evaluateHandle(() => Array.from(document.getElementsByTagName('p')).find(el => el.innerHTML.includes('Syncing...')));
            const elementExists = await jsHandle.evaluate(el => !!el);
            if (elementExists) {
                logAksi("Indikator 'Syncing...' terdeteksi.");
                io.emit('status_update', { status: unitLabel, message: `Syncing...` });
                break;
            }
            await delay(500);
        }

        logAksi("Menunggu teks 'Syncing...' menghilang...");
        while (true) {
            const jsHandle = await page.evaluateHandle(() => Array.from(document.getElementsByTagName('p')).find(el => el.innerHTML.includes('Syncing...')));
            const elementExists = await jsHandle.evaluate(el => !!el);
            if (!elementExists) {
                logAksi("Sinkronisasi AppSheet selesai.");
                io.emit('status_update', { status: unitLabel, message: `Sync complete...` });
                break;
            }
            await delay(500);
        }
    }

    const textSelector = await cariElemen(page, '#ReactRoot > div > header > div > h6', 'Judul Halaman');
    const fullTitle = await textSelector.evaluate(el => el.textContent);
    logAksi(`Judul halaman terbaca: "${fullTitle}"`);

    const addBtn = await cariElemen(page, 'button[aria-label="Add"]', 'Tombol Add');
    await addBtn.click();
    logAksi("Tombol Add berhasil diklik.");

    // INPUT FORM OTOMATIS
    await isiInput(page, '[aria-label="PIC"]', 'Input PIC', job.data.pic, io, { status: unitLabel, message: `Input pic selesai.` });
    await isiInput(page, '[aria-label="Code Unit"]', 'Input Code Unit', `HT140-0${job.data.unit}`, io, { status: unitLabel, message: `Input code unit selesai.` });
    await isiInput(page, '[aria-label="HM Unit"]', 'Input HM Unit', job.data.hm, io, { status: unitLabel, message: `Input HM unit selesai.` });

    // Battery 1
    await isiInput(page, '[aria-label="Battery 1 (SOC)"]', 'SOC Baterai 1', job.data.soc1, io, { status: unitLabel, message: `Input Battery 1 (SOC) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 (Zi)"]', 'Zi Baterai 1', job.data.zi1, io, { status: unitLabel, message: `Input Battery 1 (Zi) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 (RCC)"]', 'RCC Baterai 1', job.data.rcc1, io, { status: unitLabel, message: `Input Battery 1 (RCC) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 (CCA SAE)"]', 'CCA Baterai 1', job.data.cca1, io, { status: unitLabel, message: `Input Battery 1 (CCA) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 (SAE EN)"]', 'SAE Baterai 1', job.data.sae1, io, { status: unitLabel, message: `Input Battery 1 (SAE) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 (Voltage)"]', 'Volt Baterai 1', job.data.volt1, io, { status: unitLabel, message: `Input Battery 1 (Voltage) selesai.` });

    const rcc1 = parseFloat(job.data.rcc1);
    let rcc1Target;
    if (rcc1 < 70) {
        logAksi("[LOGIKA] RCC1 < 70: Memilih Extreme Weak.");
        rcc1Target = '#__TableEntryScreenBATTERY_SchemaBattery_1__Result_ > div > div > div:nth-child(3) > span > div > span';
    } else if (rcc1 < 86) {
        logAksi("[LOGIKA] RCC1 < 86: Memilih Marginal.");
        rcc1Target = '#__TableEntryScreenBATTERY_SchemaBattery_1__Result_ > div > div > div:nth-child(2) > span > div > span';
    } else {
        logAksi("[LOGIKA] RCC1 >= 86: Memilih Normal.");
        rcc1Target = '#__TableEntryScreenBATTERY_SchemaBattery_1__Result_ > div > div > div:nth-child(1) > span > div > span';
    }
    const clickRcc1 = await cariElemen(page, rcc1Target, 'Status RCC Baterai 1');
    await clickRcc1.click();

    // Battery 2
    await isiInput(page, '[aria-label="Battery 2 (SOC)"]', 'SOC Baterai 2', job.data.soc2, io, { status: unitLabel, message: `Input Battery 2 (SOC) selesai.` });
    await isiInput(page, '[aria-label="Battery 2 (Zi)"]', 'Zi Baterai 2', job.data.zi2, io, { status: unitLabel, message: `Input Battery 2 (Zi) selesai.` });
    await isiInput(page, '[aria-label="Battery 2 (RCC)"]', 'RCC Baterai 2', job.data.rcc2, io, { status: unitLabel, message: `Input Battery 2 (RCC) selesai.` });
    await isiInput(page, '[aria-label="Battery 2 (CCA SAE)"]', 'CCA Baterai 2', job.data.cca2, io, { status: unitLabel, message: `Input Battery 2 (CCA) selesai.` });
    await isiInput(page, '[aria-label="Battery 2 (SAE EN)"]', 'SAE Baterai 2', job.data.sae2, io, { status: unitLabel, message: `Input Battery 2 (SAE) selesai.` });
    await isiInput(page, '[aria-label="Battery 2 (Voltage)"]', 'Volt Baterai 2', job.data.volt2, io, { status: unitLabel, message: `Input Battery 2 (Voltage) selesai.` });

    const rcc2 = parseFloat(job.data.rcc2);
    let rcc2Target;
    if (rcc2 < 70) {
        logAksi("[LOGIKA] RCC2 < 70: Memilih Extreme Weak.");
        rcc2Target = '#__TableEntryScreenBATTERY_SchemaBattery_2__Result_ > div > div > div:nth-child(3) > span > div > span';
    } else if (rcc2 < 86) {
        logAksi("[LOGIKA] RCC2 < 86: Memilih Marginal.");
        rcc2Target = '#__TableEntryScreenBATTERY_SchemaBattery_2__Result_ > div > div > div:nth-child(2) > span > div > span';
    } else {
        logAksi("[LOGIKA] RCC2 >= 86: Memilih Normal.");
        rcc2Target = '#__TableEntryScreenBATTERY_SchemaBattery_2__Result_ > div > div > div:nth-child(1) > span > div > span';
    }
    const clickRcc2 = await cariElemen(page, rcc2Target, 'Status RCC Baterai 2');
    await clickRcc2.click();

    // Battery 1_2 (Seri)
    await isiInput(page, '[aria-label="Battery 1 & 2 (SOC)"]', 'SOC Seri', job.data.soc1_2, io, { status: unitLabel, message: `Input Battery Seri (SOC) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 & 2 (Zi)"]', 'Zi Seri', job.data.zi1_2, io, { status: unitLabel, message: `Input Battery Seri (Zi) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 & 2 (RCC)"]', 'RCC Seri', job.data.rcc1_2, io, { status: unitLabel, message: `Input Battery Seri (RCC) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 & 2 (CCA SAE)"]', 'CCA Seri', job.data.cca1_2, io, { status: unitLabel, message: `Input Battery Seri (CCA) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 & 2 (SAE EN)"]', 'SAE Seri', job.data.sae1_2, io, { status: unitLabel, message: `Input Battery Seri (SAE) selesai.` });
    await isiInput(page, '[aria-label="Battery 1 & 2 (Voltage)"]', 'Volt Seri', job.data.volt1_2, io, { status: unitLabel, message: `Input Battery Seri (Voltage) selesai.` });

    const rcc12 = parseFloat(job.data.rcc1_2);
    let rcc12Target;
    if (rcc12 < 70) {
        logAksi("[LOGIKA] RCC Seri < 70: Memilih Extreme Weak.");
        rcc12Target = '#__TableEntryScreenBATTERY_SchemaBattery_1___2__Result_ > div > div > div:nth-child(3) > span > div > span';
    } else if (rcc12 < 86) {
        logAksi("[LOGIKA] RCC Seri < 86: Memilih Marginal.");
        rcc12Target = '#__TableEntryScreenBATTERY_SchemaBattery_1___2__Result_ > div > div > div:nth-child(2) > span > div > span';
    } else {
        logAksi("[LOGIKA] RCC Seri >= 86: Memilih Normal.");
        rcc12Target = '#__TableEntryScreenBATTERY_SchemaBattery_1___2__Result_ > div > div > div:nth-child(1) > span > div > span';
    }
    const clickRcc12 = await cariElemen(page, rcc12Target, 'Status RCC Baterai Seri');
    await clickRcc12.click();

    // Crank & Voltage
    await isiInput(page, '[aria-label="Crank Power"]', 'Crank Power', job.data.cp, io, { status: unitLabel, message: `Input Crank Power selesai.` });
    await isiInput(page, '[aria-label="Starter Current"]', 'Starter Current', job.data.sc, io, { status: unitLabel, message: `Input Starter Current selesai.` });
    await isiInput(page, '[aria-label="Starter Current Active"]', 'Starter Current Active', job.data.sca, io, { status: unitLabel, message: `Input Starter Current Active selesai.` });
    await isiInput(page, '[aria-label="Ripple Voltage"]', 'Ripple Voltage', job.data.rv, io, { status: unitLabel, message: `Input Ripple Voltage selesai.` });
    await isiInput(page, '[aria-label="Terminal Voltage"]', 'Terminal Voltage', job.data.tv, io, { status: unitLabel, message: `Input Terminal Voltage selesai.` });

    // Logika Replace Battery
    if (rcc1 < 86) {
        logAksi("[LOGIKA] RCC1 < 86: Mengeset Replace Battery 1 = YES.");
        const replaceB1 = await cariElemen(page, '#__TableEntryScreenBATTERY_SchemaReplace_Battery_1 > div > div > div:nth-child(2) > span', 'Opsi Yes Replace Baterai 1');
        await replaceB1.click();
        await isiInput(page, '[aria-label="SN Battery 1"]', 'Serial Number Baterai 1', '-');
    } else {
        logAksi("[LOGIKA] RCC1 >= 86: Mengeset Replace Battery 1 = NO.");
        const keepB1 = await cariElemen(page, '#__TableEntryScreenBATTERY_SchemaReplace_Battery_1 > div > div > div:nth-child(1) > span', 'Opsi No Replace Baterai 1');
        await keepB1.click();
    }

    if (rcc2 < 86) {
        logAksi("[LOGIKA] RCC2 < 86: Mengeset Replace Battery 2 = YES.");
        const replaceB2 = await cariElemen(page, '#__TableEntryScreenBATTERY_SchemaReplace_Battery_2 > div > div > div:nth-child(2) > span', 'Opsi Yes Replace Baterai 2');
        await replaceB2.click();
        await isiInput(page, '[aria-label="SN Battery 2"]', 'Serial Number Baterai 2', '-');
    } else {
        logAksi("[LOGIKA] RCC2 >= 86: Mengeset Replace Battery 2 = NO.");
        const keepB2 = await cariElemen(page, '#__TableEntryScreenBATTERY_SchemaReplace_Battery_2 > div > div > div:nth-child(1) > span', 'Opsi No Replace Baterai 2');
        await keepB2.click();
    }

    // Penyimpanan
    const saveBtn = await cariElemen(page, 'xpath=/html/body/div[17]/div[3]/div/div[1]/div/div/div[2]/span/button[3]/span[1]', 'Tombol Save Akhir');
    await saveBtn.click();
    logAksi("Tombol Save telah ditekan.");
    io.emit('status_update', { status: unitLabel, message: `Menyimpan.` });

    let syncingDetected = false;
    logAksi("Memulai loop deteksi kata 'Syncing...' pasca simpan.");
    while (true) {
        const syncingExists = await page.evaluate(() => document.body.innerText.includes("Syncing..."));

        if (syncingExists && !syncingDetected) {
            logAksi("AppSheet mulai melakukan Syncing data ke cloud.");
            io.emit('status_update', { status: unitLabel, message: `Syncing...` });
            syncingDetected = true;
        }

        if (!syncingExists && syncingDetected) {
            logAksi("Syncing selesai. Data berhasil diunggah.");
            io.emit('status_update', { status: unitLabel, message: `Sync complete...` });
            break; 
        }
        await delay(500);
    }

    io.emit('status_update', { status: "finish", message: `Input ${unitLabel} selesai.` });
    pool.query('UPDATE battery_input SET status = ? WHERE unique_id = ?', ['selesai', job.data.unique_id], (err) => {
        if (err) logAksi(`[DB ERROR] Gagal update status ke 'selesai': ${err.message}`);
        else logAksi(`[DB] Sukses memperbarui status ke 'selesai'.`);
    });

    logAksi(`--- SELESAI PROSES SCRAPING UNTUK UNIT: ${unitLabel} ---`);
    await browser.close();
}, { 
    connection, 
    lockDuration: 1200000,
    stalledInterval: 5000,
	concurrency: 1
});


function delay(time) {
   return new Promise(function(resolve) { 
       setTimeout(resolve, time)
   });
}

function generateUniqueId() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let uniqueId = "";
    for (let i = 0; i < 10; i++) {
        uniqueId += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return uniqueId;
}

server.listen(2083, () => {
    logAksi('Server running at port 2083');
});