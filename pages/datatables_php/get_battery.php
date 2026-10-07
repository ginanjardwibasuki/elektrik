<?php
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Easy set variables
 */

// DB table to use
$table = 'battery_input';

// Table's primary key
$primaryKey = 'id';

// Array of database columns which should be read and sent back to DataTables.
// The `db` parameter represents the column name in the database, while the `dt`
// parameter represents the DataTables column identifier. In this case object
// parameter names
$columns = array(
	array( 'db' => 'id', 'dt' => 'id' ),
    array( 'db' => 'pic', 'dt' => 'pic' ),
    array( 'db' => 'unit', 'dt' => 'unit' ),
    array( 'db' => 'status', 'dt' => 'status' ),
    array( 'db' => 'tanggal', 'dt' => 'tanggal' )
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

echo json_encode(
	SSP::complex($_GET, $sql_details, $table, $primaryKey, $columns, null, $where)
);
