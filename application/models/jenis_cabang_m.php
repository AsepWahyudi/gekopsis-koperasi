<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_cabang_m extends CI_Model {
	
	public function __construct(){
		parent::__construct();
	}
	public function import_db($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['kode_cabang'] = $val; }
					if($key == 'B') { $pair['nama_cabang'] = $val; }
					if($key == 'C') { $pair['alamat_cabang'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('jns_cabang', $pair_arr);
		} else {
			return FALSE;
		}
	}
}