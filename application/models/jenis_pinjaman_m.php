<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_pinjaman_m extends CI_Model {

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
					if($key == 'A') { $pair['jns_pinjaman'] = $val; }
					if($key == 'B') { $pair['jumlah'] = $val; }
					if($key == 'C') { $pair['bunga'] = $val; }
					if($key == 'D') { $pair['fixed'] = $val; }
					if($key == 'E') { $pair['biaya_adm'] = $val; }
					if($key == 'F') { $pair['simpanan_pokok'] = $val; }
					if($key == 'G') { $pair['biaya_materai'] = $val; }
					if($key == 'H') { $pair['biaya_asuransi'] = $val; }
					if($key == 'I') { $pair['max'] = $val; }
					if($key == 'J') { $pair['tampil'] = $val; }
					if($key == 'K') { $pair['tenor'] = $val; }
					if($key == 'L') { $pair['transaksi_toko'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			
			return $this->db->insert_batch('jns_pinjaman', $pair_arr);
		} else {
			return FALSE;
		}
	}
}