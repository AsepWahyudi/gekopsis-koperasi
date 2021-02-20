<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class kategori_asset_m extends CI_Model {
	
	public function __construct(){
		parent::__construct();
	}
	public function import_db($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['kategori_asset'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('kategori_asset', $pair_arr);
		} else {
			return FALSE;
		}
	}
}