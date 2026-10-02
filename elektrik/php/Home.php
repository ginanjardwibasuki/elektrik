<?php
class Home
{

    private $db;
    public $sesi;
    function __construct($db)
    {
        $this->db = $db;
    }

    public function tableCount($table,$user)
    {
        $result = mysqli_query($this->db, "SELECT COUNT(*) as cnt FROM $table WHERE owner='$user'");
        $count = mysqli_fetch_assoc($result)['cnt'];
        return $count;
    }

    public function timeAgo($tanggal)
    {
        mysqli_query($this->db, "SELECT CONCAT ( TIMESTAMPDIFF(DAY,`$tanggal`, NOW())) AS `hari`,
        CONCAT ( TIMESTAMPDIFF(HOUR, TIMESTAMPADD(DAY, TIMESTAMPDIFF(DAY, `$tanggal`, NOW()), `$tanggal`), NOW())) AS `jam`,
        CONCAT ( TIMESTAMPDIFF(MINUTE, TIMESTAMPADD(HOUR, TIMESTAMPDIFF(HOUR, `$tanggal`, NOW()), `$tanggal`), NOW())) AS `menit`
        FROM `aktivitas`");
        return array('hari' => 4, 'jam' => 5, 'menit' => 6);
    }

}