<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Sewa_kantor_m extends CI_Model {
	
	public function __construct(){
		parent::__construct();
	}
	public function import_db($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { 
                        $this->db->select('*');
						$this->db->from('jns_cabang');
						$this->db->where('nama_cabang', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['cabang_id'] = $query->row()->jns_cabangid; 
							$vcabang=true;
						} 
						else {
							$pair['cabang_id'] = 0;
						}
					}
						if($key == 'B') { $pair['awal_sewa'] = $val; }
						if($key == 'C') { $pair['akhir_sewa'] = $val; }
						if($key == 'D') { $pair['saldo'] = $val; }
						if($key == 'E') { $pair['jangka_waktu'] = $val; }

				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('sewa_kantor', $pair_arr);
		} else {
			return FALSE;
		}
	}
}