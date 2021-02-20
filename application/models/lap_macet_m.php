<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_macet_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}

	//panggil data simpanan
	function get_data_tempo($limit, $start) {
		$this->db->select('v_hitung_pinjaman.id AS id,v_hitung_pinjaman.nomor_pinjaman AS nomor_pinjaman,v_hitung_pinjaman.tempo AS tempo,v_hitung_pinjaman.tgl_pinjam AS tgl_pinjam, v_hitung_pinjaman.tagihan AS tagihan, v_hitung_pinjaman.lama_angsuran AS lama_angsuran, 
		tbl_anggota.nama AS nama, SUM(tbl_pinjaman_d.jumlah_bayar) AS jum_bayar, SUM(tbl_pinjaman_d.denda_rp) AS jum_denda,v_hitung_pinjaman.bln_sudah_angsur AS bulan_sdh_angsur');
		$this->db->from('v_hitung_pinjaman');
		
		$this->db->join('tbl_anggota', 'tbl_anggota.id = v_hitung_pinjaman.anggota_id', 'LEFT');
		$this->db->join('tbl_pinjaman_d', 'tbl_pinjaman_d.pinjam_id = v_hitung_pinjaman.id', 'LEFT');

		if(isset($_GET['periode']) && $_GET['periode']) {
			$tgl_arr = explode('-', $_GET['periode']);
			$thn = $tgl_arr[0];
			$bln = $tgl_arr[1];
			$where = "YEAR(tempo) = '".$thn."' AND  MONTH(tempo) = '".$bln."' ";
			$this->db->where($where);
		} 
		if(isset($_GET['jenis_anggota_id']) && $_GET['jenis_anggota_id'] != "") {
			$where_category = "tbl_anggota.jns_anggotaid = '".$_GET['jenis_anggota_id']."'";
			$this->db->where($where_category);
		}
		if(isset($_GET['anggota_id']) && $_GET['anggota_id']) {
			$where_anggota = "tbl_anggota.id = '".$_GET['anggota_id']."'";
			$this->db->where($where_anggota);
		}

		$this->db->where('lunas','Belum');
		$this->db->order_by('v_hitung_pinjaman.tempo', 'ASC');
		$this->db->group_by('v_hitung_pinjaman.id');
		$this->db->limit($limit, $start);
		$query = $this->db->get();
		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_jml_data_tempo() {
		$this->db->where('lunas', 'Belum');
		return $this->db->count_all_results('v_hitung_pinjaman');
	}

	//panggil data jenis simpan untuk laporan
	function lap_data_tempo() {
		$this->db->select('v_hitung_pinjaman.id AS id,v_hitung_pinjaman.nomor_pinjaman AS nomor_pinjaman,v_hitung_pinjaman.tempo AS tempo,v_hitung_pinjaman.tgl_pinjam AS tgl_pinjam, v_hitung_pinjaman.tagihan AS tagihan, v_hitung_pinjaman.lama_angsuran AS lama_angsuran,
		v_hitung_pinjaman.biaya_adm AS adm,  v_hitung_pinjaman.pokok_angsuran AS pokok_angsuran, v_hitung_pinjaman.bunga_pinjaman AS bunga_pinjaman,v_hitung_pinjaman.bln_sudah_angsur AS bulan_sdh_angsur,
		tbl_anggota.ktp AS ktp, tbl_anggota.nama AS nama, tbl_anggota.id AS anggota_id,SUM(tbl_pinjaman_d.jumlah_bayar) AS jum_bayar, SUM(tbl_pinjaman_d.denda_rp) AS jum_denda');
	
		$this->db->from('v_hitung_pinjaman');
		$this->db->join('tbl_anggota', 'tbl_anggota.id = v_hitung_pinjaman.anggota_id', 'LEFT');
		$this->db->join('tbl_pinjaman_d', 'tbl_pinjaman_d.pinjam_id = v_hitung_pinjaman.id', 'LEFT');
		
		if(isset($_GET['periode']) && $_GET['periode']) {
			$tgl_arr = explode('-', $_GET['periode']);
			$thn = $tgl_arr[0];
			$bln = $tgl_arr[1];
			$where = "YEAR(tempo) = '".$thn."' AND  MONTH(tempo) = '".$bln."' ";
			$this->db->where($where);
		} 
		if(isset($_GET['jenis_anggota_id']) && $_GET['jenis_anggota_id'] != "") {
			$where_category = "tbl_anggota.jns_anggotaid = '".$_GET['jenis_anggota_id']."'";
			$this->db->where($where_category);
		}
		if(isset($_GET['anggota_id']) && $_GET['anggota_id']) {
			$where_anggota = "tbl_anggota.id = '".$_GET['anggota_id']."'";
			$this->db->where($where_anggota);
		}
		$this->db->where('lunas','Belum');
		$this->db->order_by('v_hitung_pinjaman.tempo', 'ASC');
		$this->db->group_by('v_hitung_pinjaman.id');
		
		$query = $this->db->get();
		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
}