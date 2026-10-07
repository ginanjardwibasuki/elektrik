import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    socketPath: "/var/run/mysqld/mysqld.sock",
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test koneksi saat startup
pool.getConnection((err, connection) => {
    if (err) {
        console.error("Error koneksi:", err.message);
    } else {
        console.log("Database terhubung.");
        connection.release(); // Pastikan koneksi dilepaskan kembali ke pool
    }
});

export { pool };