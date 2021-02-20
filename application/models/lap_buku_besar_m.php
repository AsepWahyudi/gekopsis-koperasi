<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_buku_besar_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}

	//panggil data jenis kas untuk laporan
	function get_nama_kas() {
		$this->db->select('*');
		$this->db->from('nama_kas_tbl');
		$this->db->where('aktif','Y');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//panggil data jenis kas untuk laporan
	function get_transaksi_kas($kas_id) {
		$this->db->select('*');
		$this->db->from('v_transaksi');
		
		if(isset($_GET['tgl_dari']) && isset($_GET['tgl_samp'])) {
			$tgl_dari = $_GET['tgl_dari'];
			$tgl_samp = $_GET['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}

		$where = "(DATE(tgl) >= '".$tgl_dari."' AND  DATE(tgl) <= '".$tgl_samp."') AND (dari_kas = '".$kas_id."' OR  untuk_kas = '".$kas_id."')";
		$this->db->where($where);
		//var_dump($this->db);die();
		$this->db->order_by('tgl', 'ASC');
		$query = $this->db->get();

		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}


	function get_nama_akun_id($id) {
		$this->db->select('*');
		$this->db->from('jns_akun');
		$this->db->where('jns_akun_id', $id);
		$query = $this->db->get();

		if($query->num_rows() > 0) {
			$out = $query->row();
			return $out;
		} else {
			$out = (object) array('nama' => '');
			return $out;
		}
	}	

	function get_nama_akun() {
		$this->db->select('jns_akun_id,no_akun,nama_akun');
    $this->db->from('jns_akun');
    $this->db->where("jenis_akun = 'SUB AKUN'");
		$query = $this->db->get();

		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}	

	function get_data_journal_id($id) {
    if(isset($_GET['tgl_dari']) && isset($_GET['tgl_samp'])) {
			$tgl_dari = $_GET['tgl_dari'];
			$tgl_samp = $_GET['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
    	$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;
    
		$this->db->select('*');
		$this->db->from('journal_voucher_det');
		$this->db->join('journal_voucher', 'journal_voucher.journal_voucherid = journal_voucher_det.journal_voucher_id', 'LEFT');
		$this->db->join('jns_cabang', 'jns_cabang.jns_cabangid = journal_voucher_det.jns_cabangid', 'LEFT');
		$this->db->where('validasi_status','X');
		$this->db->where('journal_date >=', $tgl_dari);
		$this->db->where('journal_date <=', $tgl_samp);
		$this->db->where('jns_akun_id', $id);
		$query = $this->db->get();
		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
}