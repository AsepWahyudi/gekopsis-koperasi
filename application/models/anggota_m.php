<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class anggota_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}
	
	//Added
	public function import_db($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				// per baris
				//$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { 
						$this->db->select('*');
						$this->db->from('jns_anggota');
						$this->db->where('nama', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$id_jnsanggota = $query->row()->id; 
							$kodejnsanggota = $query->row()->kode;
						} else {
							$kodejnsanggota = 0;
						}
						$pair['jns_anggotaid'] = $id_jnsanggota;
						
						$maxid = '';
						$maxid = $this->db->query("SELECT CONCAT('".$kodejnsanggota."',lpad(MAX(REPLACE(no_anggota,'".$kodejnsanggota."',''))+1,6,'0')) AS maxid FROM tbl_anggota WHERE no_anggota LIKE '".$kodejnsanggota."%'")->row()->maxid;
						if($maxid != ''){
							$maxid = $maxid;
						} else {
							if ($maxid == NULL) {
								$maxid = $kodejnsanggota .'000001';
							} else {
								return false;
							}
						}
						$vnomor_anggota = $maxid;
					}
					if($key == 'B') { $pair['no_anggota'] = $vnomor_anggota; }
					if($key == 'C') { $pair['tgl_daftar'] = $val; }
					if($key == 'D') { $pair['nama'] = $val; }
					if($key == 'E') { 
						if ($val != '') {
							$pair['identitas'] = $val; 
						} else {
							$pair['identitas'] = "0";
						}	
					}
					if($key == 'F') { $pair['jk'] = $val; }
					if($key == 'G') { $pair['tmp_lahir'] = $val; }
					if($key == 'H') { $pair['tgl_lahir'] = $val; }
					if($key == 'I') { $pair['agama'] = $val; }
					if($key == 'J') { $pair['status'] = $val; }
					if($key == 'K') { $pair['pendidikan'] = $val; }
					if($key == 'L') { $pair['ktp'] = $val; }
					if($key == 'M') { $pair['alamat'] = $val; }
					if($key == 'N') { $pair['kelurahan'] = $val; }
					if($key == 'O') { $pair['kecamatan'] = $val; }
					if($key == 'P') { $pair['kota'] = $val; }
					if($key == 'Q') { $pair['kode_pos'] = $val; }
					if($key == 'R') { $pair['notelp'] = $val; }
					if($key == 'S') { $pair['ibu_kandung'] = $val; }
					if($key == 'T') { $pair['pekerjaan'] = $val; }
					if($key == 'U') { $pair['nomor_rekening'] = $val; }
					if($key == 'V') { $pair['nama_bank'] = $val; }

				}
				$pair_arr[] = $pair;
				 
				if ($this->db->insert('tbl_anggota', $pair)) {
					$vreturn = TRUE;
				} else {
					$vreturn = FALSE;
				}
			}
			return $vreturn;
			//return $this->db->insert_batch('tbl_anggota', $pair_arr);
		} else {
			return FALSE;
		}
	}
}