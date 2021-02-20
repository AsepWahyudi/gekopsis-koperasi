<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_sewa_kantor_m extends CI_Model {
	public function __construct() {
		parent::__construct();
	}

	function get_data_sewakantor($limit, $start, $q='') {
		$cabang_id = isset($_GET['cabang_id']) ? $_GET['cabang_id'] : '';
		$sql = '';
		$sql = "SELECT * FROM sewa_kantor ";
		$q = array('cabang_id' => $cabang_id);
		if (is_array($q)){
			if($q['cabang_id'] != '') {
				$sql .=" where cabang_id = ".$q['cabang_id']." ";
			}
		}
		$sql .= "LIMIT ".$start.", ".$limit." ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}


	function get_jml_data() {
		return $this->db->count_all_results('sewa_kantor');
	}

	function get_data_cabang($q,$r) {
		$sql = '';
		$sql = "SELECT * FROM jns_cabang where 1";
		if($r !='') {
			$sql .=" AND (nama_cabang LIKE '%$r%' OR kode_cabang LIKE '%$r%') ";
		}
		if($q !='') {
			$sql .=" AND (nama_cabang LIKE '%$q%' OR kode_cabang LIKE '%$q%') ";
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY nama_cabang ASC ";
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;

	}

	function get_data_cabang_ajax($q) {
		$sql = "SELECT * FROM jns_cabang ";
		if($q !='') {
			$sql .=" WHERE nama_cabang like '%$q%' ";
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}


}