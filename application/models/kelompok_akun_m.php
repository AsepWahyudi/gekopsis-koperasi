<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Kelompok_akun_m extends CI_Model {
	
	public function __construct(){
		parent::__construct();
	}
	public function import_db($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['nama_kelompok'] = $val; }
					if($key == 'B') { $pair['no_urut'] = $val; }
					if($key == 'C') { $pair['status'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('kelompok_akun', $pair_arr);
		} else {
			return FALSE;
		}
	}
}