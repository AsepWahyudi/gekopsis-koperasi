<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Data_barang_m extends CI_Model {

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
					if($key == 'A') { $pair['nm_barang'] = $val; }
					if($key == 'B') { $pair['type'] = $val; }
					if($key == 'C') { $pair['merk'] = $val; }
					if($key == 'D') { $pair['harga'] = $val; }
					if($key == 'E') { $pair['jml_brg'] = $val; }
					if($key == 'F') { $pair['ket'] = $val; }
					if($key == 'G') { $pair['inventory'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('tbl_barang', $pair_arr);
		} else {
			return FALSE;
		}
	}
}