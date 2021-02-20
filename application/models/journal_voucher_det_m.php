<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class journal_voucher_det_m extends CI_Model {

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
					if($key == 'A') { $pair['journal_voucher_id'] = $val; }
					if($key == 'B') { $pair['jns_akun_id'] = $val; }
					if($key == 'C') { $pair['debit'] = $val; }
					if($key == 'D') { $pair['credit'] = $val; }
					if($key == 'E') { $pair['jns_cabangid'] = $val; }
					if($key == 'F') { $pair['itemnote'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('journal_voucher', $pair_arr);
		} else {
			return FALSE;
		}
	}

	public function get_data_list($q='') {
		$sql = "SELECT a.*,b.kode_cabang,c.no_akun,c.nama_akun,b.nama_cabang
			FROM journal_voucher_det a 
			left join jns_cabang b on b.jns_cabangid = a.jns_cabangid 
			left join jns_akun c on c.jns_akun_id = a.jns_akun_id 
			";
		$sql .= " WHERE journal_voucher_id = ". $q ." ORDER BY jns_akun_id ASC"; 
		$result['count'] = $this->db->query($sql)->num_rows();
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
}