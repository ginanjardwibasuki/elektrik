<?php
include '../../php/Auth.php';
session_start();

 $auth = new Auth($db);
 if ($auth->cekSession() == 0) {
    header("Location: ../login.php");
	exit;
} else {
	$username = $_SESSION['login']['username'];
}
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Easy set variables
 */

// DB table to use
$table = 'sparepart';

// Table's primary key
$primaryKey = 'id';

// Array of database columns which should be read and sent back to DataTables.
// The `db` parameter represents the column name in the database, while the `dt`
// parameter represents the DataTables column identifier. In this case object
// parameter names
$columns = array(
    array( 'db' => 'gambar', 'dt' => 'gambar'),
	array( 'db' => 'name', 'dt' => 'name' ),
	array( 'db' => 'id', 'dt' => 'id' ),
    array( 'db' => 'part_number', 'dt' => 'part_number' ),
    array( 'db' => 'vendor', 'dt' => 'vendor' ),
    array( 'db' => 'keyword', 'dt' => 'keyword' )
);

// SQL server connection information
$sql_details = array(
	'user' => 'root',
	'pass' => 'anjarokz1234',
	'db'   => 'elektrik',
	'host' => 'localhost'
);


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * If you just want to use the basic configuration for DataTables with PHP
 * server-side, there is no need to edit below this line.
 */

require( 'ssp.class.php' );

$where = "owner = '{$username}'";
echo json_encode(
	SSP::complex($_GET, $sql_details, $table, $primaryKey, $columns, null, $where)
);
