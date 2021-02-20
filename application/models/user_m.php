<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class User_m extends CI_Model {

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
					if($key == 'A') { $pair['u_name'] = $val; }
					if($key == 'B') { $pair['real_name'] = $val; }
					if($key == 'C') { $pair['level'] = $val; }
					$initial_passwd='1e157dd5081c6699192c94068932336f5c00ebf5';
					$pair['pass_word'] = $initial_passwd;
					if($key == 'D') { 
						$this->db->select('*');
						$this->db->from('jns_cabang');
						$this->db->where('nama_cabang', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['jns_cabangid'] = $query->row()->jns_cabangid; 
						} else {
							$pair['jns_cabangid'] = ''; 
						}
					}
					if($key == 'E') { $pair['aktif'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('tbl_user', $pair_arr);
		} else {
			return FALSE;
		}
	}
}