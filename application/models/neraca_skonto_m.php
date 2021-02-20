<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class neraca_skonto_m extends CI_Model {
	
	public function __construct(){
		parent::__construct();
	}
	public function import_db($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['kelompok_akunid_debet'] = $val; }
					if($key == 'B') { $pair['jns_akun_id_debet'] = $val; }
					if($key == 'C') { $pair['value_debet'] = $val; }
					if($key == 'D') { $pair['kelompok_akunid_kredit'] = $val; }
					if($key == 'E') { $pair['jns_akun_id_kredit'] = $val; }
					if($key == 'F') { $pair['value_kredit'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('neraca_skonto', $pair_arr);
		} else {
			return FALSE;
		}
	}
}