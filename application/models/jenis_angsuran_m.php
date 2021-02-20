<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_angsuran_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}
	
	//Added
	public function import_db($data) {
		if(is_array($data)) {

			$pair_arr = array();
			foreach ($data as $rows) {
				//if(trim($rows['A']) == '') { continue; }
				// per baris
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['ket'] = $val; }
					if($key == 'B') { $pair['aktif'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('jns_angsuran', $pair_arr);
		} else {
			return FALSE;
		}
	}
}