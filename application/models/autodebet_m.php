<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Autodebet_m extends CI_Model {
		public function __construct() {
		parent::__construct();
	}

	function get_data_pinjam($status_anggota) {
		if($status_anggota == 1){
			$anggota = 'anggota';
		}
		else{
			$anggota = 'anggota luarbiasa';
		}
		$query = $this->db->query("
									SELECT a.* FROM v_hitung_pinjaman a 
									JOIN tbl_anggota b ON b.id = a.anggota_id
									WHERE a.lunas = 'Belum' 
									-- AND b.status_anggota = '$anggota'
								");
		return $query;
	}
	
	function get_auto_debet_setting() {
		$query = $this->db->query("
									SELECT * FROM setting_autodebet a 
								");
		return $query;
	}
	
	function last_autodebet_anggota() {
		$query = $this->db->query("
									SELECT * FROM history_autodebet a 
									-- WHERE a.status_anggota = 1
									ORDER BY a.id DESC LIMIT 1
								");
		return $query;
	}
	
	function last_autodebet_anggota_luarbiasa() {
		$query = $this->db->query("
									SELECT * FROM history_autodebet a 
									WHERE a.status_anggota = 2
									ORDER BY a.id DESC LIMIT 1
								");
		return $query;
	}
	
	function get_nama_kas() {
		$query = $this->db->query("
									SELECT * FROM nama_kas_tbl a 
								");
		return $query;
	}
	
	function lap_autodebet_per_simpanan($start_date,$end_date,$jenis_id,$anggota_id) {
		$query = $this->db->query("
									SELECT SUM(a.jumlah_bayar) AS total , a.simpan_id, b.anggota_nama
									FROM tbl_trans_sp_d a
									JOIN tbl_trans_sp b ON b.id = a.simpan_id
									WHERE a.keterangan = 'auto_debet_system' AND a.tgl_bayar BETWEEN '$start_date' AND '$end_date' AND b.jenis_id = '$jenis_id' AND b.anggota_id = '$anggota_id'
									GROUP BY a.simpan_id, b.anggota_id
								");
		return $query;
	}
	
	function lap_autodebet_per_pinjaman($start_date,$end_date,$anggota_id) {
		$query = $this->db->query("
									SELECT SUM(a.jumlah_bayar) AS total , c.jns_pinjaman  FROM tbl_pinjaman_d a
									JOIN tbl_pinjaman_h b ON b.id = a.pinjam_id
									JOIN jns_pinjaman c ON c.id = b.jenis_pinjaman
									WHERE a.keterangan = 'auto_debet_system' AND a.tgl_bayar BETWEEN '$start_date' AND '$end_date' AND b.anggota_id = '$anggota_id'
									GROUP BY a.pinjam_id
								");
		return $query;
	}
	
	function get_data_simpan($status_anggota) {
		if($status_anggota == 1){
			$anggota = 'anggota';
		}
		else{
			$anggota = 'anggota luarbiasa';
		}
		$query = $this->db->query("
									SELECT a.*, CEILING(a.jumlah / a.tenor) AS angsuran_per_bulan,
									(SELECT COUNT(v.id)+1 FROM tbl_trans_sp_d v WHERE v.simpan_id = a.id) AS angsuran_ke
									FROM tbl_trans_sp a 
									JOIN tbl_anggota b ON b.id = a.anggota_id
									WHERE a.lunas = 'Belum' 
									-- AND b.status_anggota = '$anggota'
								");
		return $query;
	}
}	