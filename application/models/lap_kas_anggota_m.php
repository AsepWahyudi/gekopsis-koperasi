<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_kas_anggota_m extends CI_Model {
	public function __construct() {
		parent::__construct();
	}

	//menghitung jumlah simpanan
	function get_jml_simpanan($jenis, $id) {
		$this->db->select('SUM(jumlah) AS jml_total');
		$this->db->from('tbl_trans_sp');
		$this->db->where('anggota_id',$id);
		$this->db->where('dk','D');
		$this->db->where('jenis_id', $jenis);
		$query = $this->db->get();
		return $query->row();
	}

	//panggil data jenis simpan
	function get_jenis_simpan() {
		$this->db->select('*');
		$this->db->from('jns_simpan');
		$this->db->where('tampil','Y');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//menghitung jumlah penarikan
	function get_jml_penarikan($jenis, $id) {
		$this->db->select('SUM(jumlah) AS jml_total');
		$this->db->from('tbl_trans_sp');
		$this->db->where('dk','K');
		$this->db->where('anggota_id', $id);
		$this->db->where('jenis_id', $jenis);
		$query = $this->db->get();
		return $query->row();
	}

	function get_data_anggota($limit, $start, $q='') {
		$anggota_id = isset($_GET['anggota_id']) ? $_GET['anggota_id'] : '';
		$jenis_anggota_id = isset($_GET['jenis_anggota_id']) ? $_GET['jenis_anggota_id'] : '';
		$sql = '';
		$sql = "SELECT * FROM tbl_anggota WHERE aktif='Y'";
		$q = array('anggota_id' => $anggota_id, 'jenis_anggota_id' => $jenis_anggota_id);
		if (is_array($q)){
			if($q['jenis_anggota_id'] != '') {
				$sql .=" AND jns_anggotaid = '".$q['jenis_anggota_id']."'";
			}
			if($q['anggota_id'] != '') {
				$q['anggota_id'] = str_replace('AG', '', $q['anggota_id']);
				$sql .=" AND (id LIKE '".$q['anggota_id']."' OR nama LIKE '".$q['anggota_id']."') ";
			}
		}
		$sql .= "LIMIT ".$start.", ".$limit." ";
		//$this->db->limit($limit, $start);
		
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}

	}
	
	function get_data_anggota_excel() {
		$anggota_id = isset($_GET['anggota_id']) ? $_GET['anggota_id'] : '';
		$jenis_anggota_id = isset($_GET['jenis_anggota_id']) ? $_GET['jenis_anggota_id'] : '';
		$sql = '';
		$sql = "SELECT * FROM tbl_anggota WHERE aktif='Y'";
		$q = array('anggota_id' => $anggota_id, 'jenis_anggota_id' => $jenis_anggota_id);
		if (is_array($q)){
			if($q['jenis_anggota_id'] != '') {
				$sql .=" AND category = '".$q['jenis_anggota_id']."'";
			}
			if($q['anggota_id'] != '') {
				$q['anggota_id'] = str_replace('AG', '', $q['anggota_id']);
				$sql .=" AND (id LIKE '".$q['anggota_id']."' OR nama LIKE '".$q['anggota_id']."') ";
			}
		}
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
	
	//panggil data anggota
	function lap_data_anggota() {
		$anggota_id = isset($_GET['anggota_id']) ? $_GET['anggota_id'] : '';
		$jenis_anggota_id = isset($_GET['jenis_anggota_id']) ? $_GET['jenis_anggota_id'] : '';
		$sql = '';
		$sql = "SELECT * FROM tbl_anggota WHERE aktif='Y'";
		$q = array('anggota_id' => $anggota_id, 'jenis_anggota_id' => $jenis_anggota_id);
		if (is_array($q)){
			if($q['jenis_anggota_id'] != '') {
				$sql .=" AND category = '".$q['jenis_anggota_id']."'";
			}
			if($q['anggota_id'] != '') {
				$q['anggota_id'] = str_replace('AG', '', $q['anggota_id']);
				$sql .=" AND (id LIKE '".$q['anggota_id']."') ";
			}
		}
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_jml_data_anggota() {
		$this->db->where('aktif', 'Y');
		return $this->db->count_all_results('tbl_anggota');
	}

//ambil data pinjaman header berdasarkan ID peminjam
	function get_data_pinjam($id) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('anggota_id',$id);
		$this->db->where('lunas','Belum');
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return array();
		}
	}


	function get_peminjam_lunas($id) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('lunas','Lunas');
		$this->db->where('anggota_id',$id);
		$query = $this->db->get();
		return $query->num_rows();
	}

	function get_peminjam_tot($id) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('anggota_id',$id);
		$query = $this->db->get();
		return $query->num_rows();
	}

	//menghitung jumlah yang sudah dibayar
	function get_jml_pinjaman($id) {
		$this->db->select('SUM(jumlah) AS total');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('anggota_id',$id);
		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah yang sudah dibayar
	function get_jml_tagihan($id) {
		$this->db->select('SUM(tagihan) AS total');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('anggota_id',$id);
		$query = $this->db->get();
		return $query->row();
	}


	//menghitung jumlah yang sudah dibayar
	function get_jml_bayar($id) {
		$this->db->select('SUM(jumlah_bayar) AS total');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id',$id);
		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah denda harus dibayar
	function get_jml_denda($id) {
		$this->db->select('SUM(denda_rp) AS total_denda');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id',$id);
		$query = $this->db->get();
		return $query->row();
	}

	function get_data_transaksi($id) {
		$sql = "SELECT v_hitung_pinjaman.* FROM v_hitung_pinjaman ";
		$where = " WHERE dk = 'K' ";

		$where .=" AND tbl_anggota.id='".$id."' ";
		$sql .= " LEFT JOIN tbl_anggota ON (v_hitung_pinjaman.anggota_id = tbl_anggota.id) ";

		$sql .= $where;

		$result['data'] = $this->db->query($sql)->result();

		return $result;
	}

	//data barang berdasarkan ID
	function get_data_barang($id) {
		$this->db->select('*');
		$this->db->from('tbl_barang');
		$this->db->where('id',$id);
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return array();
		}
	}

	function get_pinjaman_anggota($id){
		$detail_pinjaman = $this->db->query('select b.nm_barang, v.* FROM v_hitung_pinjaman as v left join tbl_barang as b on b.id = v.barang_id where anggota_id = '.$id)->result();
		return $detail_pinjaman;
	}

}

