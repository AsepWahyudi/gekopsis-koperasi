<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_kas_m extends CI_Model {

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
					if($key == 'A') { $pair['nama'] = $val; }
					if($key == 'B') { $pair['aktif'] = $val; }
					if($key == 'C') { $pair['tmpl_simpan'] = $val; }
					if($key == 'D') { $pair['tmpl_penarikan'] = $val; }
					if($key == 'E') { $pair['tmpl_pinjaman'] = $val; }
					if($key == 'F') { $pair['tmpl_bayar'] = $val; }
					if($key == 'G') { $pair['tmpl_pemasukan'] = $val; }
					if($key == 'H') { $pair['tmpl_pengeluaran'] = $val; }
					if($key == 'I') { $pair['tmpl_transfer'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('nama_kas_tbl', $pair_arr);
		} else {
			return FALSE;
		}
	}
}