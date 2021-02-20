<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_akun_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}
	
	//Added
	public function import_db($data) {
		$maxid = 0;
		$this->db->trans_start();
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				//$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['no_akun'] = str_replace(' ', '', $val); }
					if($key == 'B') { $pair['nama_akun'] = $val; }
					if($key == 'C') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', str_replace(' ', '', $val));
						$query = $this->db->get();
						if($query->num_rows()>0){ 
							$pair['induk_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['induk_akun'] = NULL;
						}
					}
					if($key == 'D') { 
						$this->db->select('*');
						$this->db->from('kelompok_akun');
						$this->db->where('nama_kelompok', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){ 
							$pair['kelompok_akunid'] = $query->row()->kelompok_akunid; 
						} else {
							$pair['kelompok_akunid'] = NULL;
						}
					}
					if($key == 'E') { $pair['kelompok_laporan'] = $val; }
					if($key == 'F') { $pair['jenis_akun'] = $val; }
					if($key == 'G') { $pair['aktif'] = $val; }
					if($key == 'H') { $pair['saldo_normal'] = str_replace(' ', '', $val); }
					
					/*
					$row = $this->db->query('SELECT MAX(jns_akun_id) AS `maxid` FROM `jns_akun`')->row();
					if ($row) {
						$maxid = $row->maxid; 
						$maxid = $maxid + 1;
						$pair['jns_akun_id'] = $maxid;
					}
					*/
				}
				$pair_arr[] = $pair;
				//var_dump($pair);die();
				$this->db->insert('jns_akun', $pair);
			}
			//return $this->db->insert_batch('jns_akun', $pair_arr);
			$this->db->trans_complete();
			if ($this->db->trans_status() === FALSE)
			{
				return false;
			} else {
				return true;
			}
		} else {
			return FALSE;
		}
	}
}