<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Cetak_simpanan_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}


	//panggil data simpanan
	function lap_data_simpanan($id) {
		$this->db->select('*');
		$this->db->from('tbl_trans_sp');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data penarikan
	function lap_data_penarikan($id) {
		$this->db->select('*');
		$this->db->from('tbl_trans_sp');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	function get_jenis_simpanan($jenis_id,$anggota_id) {
		$this->load->model('lap_kas_anggota_m');
		$tot_simpn = $this->lap_kas_anggota_m->get_jml_simpanan($jenis_id, $anggota_id);
		$tot_tarik = $this->lap_kas_anggota_m->get_jml_penarikan($jenis_id, $anggota_id);
		$saldo = $tot_simpn->jml_total - $tot_tarik->jml_total;
		return $saldo;
	}

	//panggil data anggota
	function get_data_anggota($id) {
		$this->db->select('*');
		$this->db->from('tbl_anggota');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
	
	//panggil data simpan
	function get_jenis_simpan($id) {
		$this->db->select('*');
		$this->db->from('jns_simpan');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
}

