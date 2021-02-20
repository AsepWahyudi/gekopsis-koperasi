<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_deposito_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}
	
	//Added
	public function import_db($data) {
		if(is_array($data)) {

			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['jns_deposito'] = $val; }
					if($key == 'B') { $pair['jumlah'] = $val; }
					if($key == 'C') { $pair['bunga'] = $val; }
					if($key == 'D') { $pair['fixed'] = $val; }
					if($key == 'E') { $pair['tenor'] = $val; }
					if($key == 'F') { $pair['tampil'] = $val; }
					if($key == 'G') { $pair['auto_simpan'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('jns_deposito', $pair_arr);
		} else {
			return FALSE;
		}
	}
}