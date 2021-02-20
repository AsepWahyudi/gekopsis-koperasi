<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class repayment_schedule_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}


	// data sisa pinjaman
	function get_sisa_pinjaman($anggota_id) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('lunas', 'Belum');
		$this->db->where('anggota_id', $anggota_id);
		$query = $this->db->get();

		$out = array();
		$out['sisa_jml'] 			= 0;
		$out['sisa_tagihan'] = 0;
		$out['sisa_ags'] 		= 0;
		if($query->num_rows() > 0) {
			$result = $query->result();
			$item = 0;
			$sisa_tagihan = 0;
			$sisa_ags = 0;
			foreach ($result as $row) {
				$item++;
				$sisa_tagihan += $row->tagihan - $this->get_jml_bayar($row->id);
				$sisa_ags += $row->lama_angsuran - $this->get_sisa_ags($row->id);
			}
			$out['sisa_jml'] = $item;
			$out['sisa_tagihan'] = $sisa_tagihan;
			$out['sisa_ags'] = $sisa_ags;
			return $out;
		} else {
			return $out;
		}

	}

	function get_jml_bayar($pinjam_id) {
		$this->db->select('SUM(jumlah_angsuran) AS total');
		$this->db->from('repayment_schedule_d');
		$this->db->where('pinjam_id', $pinjam_id);
		$query = $this->db->get();
		$row = $query->row();
		return $row->total;
	}

	function get_sisa_ags($pinjam_id) {
		$this->db->select('MAX(angsuran_ke) AS angsuran_ke');
		$this->db->from('repayment_schedule_d');
		$this->db->where('pinjam_id', $pinjam_id);
		$query = $this->db->get();
		$row = $query->row();
		return $row->angsuran_ke;
	}

	//data kas
	function get_data_kas() {
		$this->db->select('*');
		$this->db->from('nama_kas_tbl');
		$this->db->where('aktif', 'Y');
		$this->db->where('tmpl_pinjaman', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//data jenis angsuran
	function get_data_angsuran() {
		$this->db->select('*');
		$this->db->from('jns_angsuran');
		$this->db->where('aktif', 'Y');
		$this->db->order_by('ket', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//data Bunga
	function get_data_bunga() {
		$this->db->select('*');
		$this->db->from('suku_bunga');
		$this->db->where('opsi_key', 'bg_pinjam');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//data biaya adm
	function get_biaya_adm() {
		$this->db->select('*');
		$this->db->from('suku_bunga');
		$this->db->where('opsi_key', 'biaya_adm');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//data data barang
	function get_id_barang() {
		$this->db->select('*');
		$this->db->from('tbl_barang');
		$this->db->order_by('nm_barang', 'ASC');
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_id_akun() {
		$this->db->select('*');
		$this->db->from('jns_akun');
		$this->db->order_by('jns_akun_id', 'ASC');
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//data barang berdasarkan ID
	function get_data_barang($id) {
		$this->db->select('*');
		$this->db->from('tbl_barang');
		$this->db->where('id',$id);
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return array();
		}
	}

	//data jenis pinjaman berdasarkan ID
	function get_jenis_pinjaman($id) {
		$this->db->select('*');
		$this->db->from('jns_pinjaman');
		$this->db->where('id',$id);
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return array();
		}
	}


	//data anggota
	function lap_data_anggota() {
		$this->db->select('*');
		$this->db->from('tbl_anggota');
		$this->db->where('aktif', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//ambil data pinjaman header berdasarkan ID peminjam
	function get_data_pinjam_id($id) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('anggota_id',$id);
		$query = $this->db->get();

		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}

	//ambil data pengajuan berdasarkan ID
	function get_data_pengajuan($id) {
		$sql_tampil = "SELECT 
			a.id AS id, a.anggota_id AS anggota_id, a.tgl_input AS tgl_input, a.jenis AS jenis, a.nominal AS nominal, a.lama_ags AS lama_ags, a.keterangan AS keterangan, a.status AS status, a.alasan AS alasan, a.tgl_update AS tgl_update, a.tgl_cair AS tgl_cair,
			b.identitas AS identitas, b.nama AS nama, b.departement AS departement
			FROM tbl_pengajuan AS a
			LEFT JOIN tbl_anggota AS b ON b.id = a.anggota_id
		 	WHERE a.id = ".$id."";
		$query = $this->db->query($sql_tampil);
		if($query->num_rows() > 0) {
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}	


	function get_simulasi_pinjaman($pinjam_id) {
		$row = $this->get_data_pinjam($pinjam_id);
		$this->load->model('bunga_m');
		if($row) {
			$out = array();
			$conf_bunga = $this->bunga_m->get_key_val();
			//$denda_hari = sprintf('%02d', $conf_bunga['denda_hari']);
			$denda_hari = $conf_bunga['denda_hari'];
			$biaya_admin = $conf_bunga['biaya_adm'];
			$tgl_tempo_next = 0;
			for ($i=1; $i <= $row->lama_angsuran; $i++) { 
				$odat = array();
                $odat['angsuran_pokok'] = $row->pokok_angsuran * 1;
                $odat['simpanan_wajib'] = $row->simpanan_wajib;
				$odat['tgl_pinjam'] = substr($row->tgl_pinjam, 0, 10);
				$odat['biaya_adm'] = $row->biaya_administrasi;
				$odat['bunga_pinjaman'] = $row->bunga_pinjaman;
				$odat['provisi_pinjaman'] = $row->provisi_pinjaman;
				$odat['jumlah_ags'] = $row->ags_per_bulan;
				
				if($row->tenor == 'Bulan'){
					$tgl = date("d", strtotime($row->tgl_pinjam));
					$bln = date("m", strtotime($row->tgl_pinjam));
					$thn = date("Y", strtotime($row->tgl_pinjam));
					$tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
					$tgl_tempo_var = $tglpinjam;
					$tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." month"));
				}
				else if($row->tenor == 'Minggu'){
					$tgl = date("d", strtotime($row->tgl_pinjam));
					$bln = date("m", strtotime($row->tgl_pinjam));
					$thn = date("Y", strtotime($row->tgl_pinjam));
					$tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
					$tgl_tempo_var = $tglpinjam;
					$tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." week"));
				}
				else{
					$tgl = date("d", strtotime($row->tgl_pinjam));
					$bln = date("m", strtotime($row->tgl_pinjam));
					$thn = date("Y", strtotime($row->tgl_pinjam));
					$tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
					$tgl_tempo_var = $tglpinjam;
					$tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." day"));
				}
				$odat['tgl_tempo'] = $tgl_tempo;
				$out[] = $odat;
			}
			return $out;
		} else {
			return FALSE;
		}
	}

	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT a.*
				FROM v_hitung_repayment a
				JOIN tbl_anggota b ON b.id = a.anggota_id ";
		$where = " WHERE dk like '%%' ";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
					$q['kode_transaksi'] = str_replace('PJ', '', $q['kode_transaksi']);
					$q['kode_transaksi'] = str_replace('AG', '', $q['kode_transaksi']);
					$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
					$where .=" AND a.nomor_pinjaman LIKE '%".$q['kode_transaksi']."%' OR a.anggota_id LIKE '%".$q['kode_transaksi']."%' ";
				} else {
					if($q['cari_nama'] != '') {
						$where .=" AND b.nama LIKE '%".$q['cari_nama']."%' ";
					}							
					if($q['cari_anggota'] != '') {
						$where .=" AND b.jns_anggotaid = '".$q['cari_anggota']."' ";
					}
					if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
						$where .=" AND DATE(tgl_pinjam) >= '".$q['tgl_dari']."' ";
						$where .=" AND DATE(tgl_pinjam) <= '".$q['tgl_sampai']."' ";
					}
			}
		}
		$sql .= $where;
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .= " ORDER BY {$sort} {$order} ";
		$sql .= " LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	public function create($filename) {
	
		//if (str_replace(',', '', $this->input->post('jumlah')) <= 0) {
		//	return FALSE;
		//}

		// TRANSACTIONAL DB COMMIT
		$this->db->trans_start();

		$data = array(			
			'tgl_pinjam'				=>	$this->input->post('tgl_pinjam'),
			'anggota_id'				=>	$this->input->post('anggota_id'),
			'nomor_pinjaman'			=>	$this->input->post('nomor_pinjaman'),
			'jenis_pinjaman'			=>	$this->input->post('jenis_id'),
			'plafond_pinjaman'			=>	str_replace(',', '', $this->input->post('plafond_pinjaman')),
			'plafond_pinjaman_akun'		=>	str_replace(',', '', $this->input->post('plafond_pinjaman_akun')),
			'lama_angsuran'				=>	$this->input->post('lama_angsuran'),
			'angsuran_per_bulan'		=>	str_replace(',', '', $this->input->post('angsuran_bulanan')),
			'no_perjanjian_kredit'		=>	$this->input->post('nomor_pk'),
			'nomor_rekening'			=>	$this->input->post('rekening_tabungan'),
			'nomor_pensiunan'			=>	$this->input->post('nomor_pensiunan'),
			'jumlah'					=>	str_replace(',', '', $this->input->post('jumlah')),
			'bunga'						=>	$this->input->post('bunga'),
			'biaya_adm'					=>	str_replace(',', '', $this->input->post('biaya_adm')),
			'dk'						=>	'K',
			'kas_id'					=>	$this->input->post('kas_id'),
			'jns_trans'					=>	'7',
			'user_name'					=> $this->data['u_name'],
			'keterangan'				=> $this->input->post('ket'),
			'biaya_asuransi'			=> $this->input->post('biaya_asuransi'),
			'biaya_asuransi_akun'		=> str_replace(',', '', $this->input->post('biaya_asuransi_akun')),
			'biaya_administrasi'		=> str_replace(',', '', $this->input->post('biaya_adm')),
			'biaya_administrasi_akun'	=> str_replace(',', '', $this->input->post('biaya_adm_akun')),
			'biaya_materai'				=> str_replace(',', '', $this->input->post('biaya_materai')),
			'biaya_materai_akun'		=> str_replace(',', '', $this->input->post('biaya_materai_akun')),
			'simpanan_pokok'			=> str_replace(',', '', $this->input->post('simpanan_pokok')),
			'simpanan_pokok_akun'		=> str_replace(',', '', $this->input->post('simpanan_pokok_akun')),
			'pokok_bulan_satu'			=> str_replace(',', '', $this->input->post('pokok_bulan_satu')),
			'pokok_bulan_satu_akun'		=> str_replace(',', '', $this->input->post('pokok_bulan_satu_akun')),
			'pokok_bulan_dua'			=> str_replace(',', '', $this->input->post('pokok_bulan_dua')),
			'pokok_bulan_dua_akun'		=> str_replace(',', '', $this->input->post('pokok_bulan_dua_akun')),
			'bunga_bulan_satu'			=> str_replace(',', '', $this->input->post('bunga_bulan_satu')),
			'bunga_bulan_satu_akun'		=> str_replace(',', '', $this->input->post('bunga_bulan_satu_akun')),
			'bunga_bulan_dua'			=> str_replace(',', '', $this->input->post('bunga_bulan_dua')),
			'bunga_bulan_dua_akun'		=> str_replace(',', '', $this->input->post('bunga_bulan_dua_akun')),
			'simpanan_wajib'			=> str_replace(',', '', $this->input->post('simpanan_wajib')),
			'simpanan_wajib_akun'		=> str_replace(',', '', $this->input->post('simpanan_wajib_akun')),
			'pencairan_bersih'			=> str_replace(',', '', $this->input->post('pencairan_bersih')),
			'jns_cabangid'				=> str_replace(',', '', $this->input->post('jenis_cabang'))
			);
		
		$this->db->insert('repayment_schedule_h', $data);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			return FALSE;
		} else {
			$this->db->trans_complete();
			return TRUE;
		}
	}


	public function delete($id) {
		// TRANSACTIONAL DB START
		$this->db->trans_start();

        $this->db->delete('repayment_schedule_d', array('pinjam_id' => $id));
		$this->db->delete('repayment_schedule_h', array('id' => $id));

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			return FALSE;
		} else {
			$this->db->trans_complete();
			return TRUE;
		}
		// TRANSACTIONAL DB END
	}
	
	public function import_db_nasabah($data) {
        $this->load->model('bunga_m');
        $conf_bunga = $this->bunga_m->get_key_val();
        $denda_hari = $conf_bunga['denda_hari'];
        $lama_angsuran = 0;
        $vtenor = "";
        $this->db->trans_start();
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { 
						$this->db->select('*');
						$this->db->from('tbl_anggota');
						$this->db->where('nama', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['anggota_id'] = $query->row()->id; 
						} else {
							return FALSE;
						} 
					}
					
					if($key == 'B') { $pair['nomor_pinjaman'] = $val;}
					if($key == 'C') { $pair['tgl_pinjam'] = $val; }
					if($key == 'D') { 
						$this->db->select('*');
						$this->db->from('jns_pinjaman');
						$this->db->like('jns_pinjaman', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
                            $pair['jenis_pinjaman'] = $query->row()->id; 
						} else {
							return FALSE;
						}  
					}
					
					if($key == 'E') { 
						if ($val != "") {
							$pair['plafond_pinjaman'] = $val;
						} else {
							return false;
						} 
					}
					if($key == 'F') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['plafond_pinjaman_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['plafond_pinjaman_akun'] = $val;
						} 	
					}
					if($key == 'G') { 
                        if ($val != "") {
                            $pair['lama_angsuran'] = $val; 
                            $lama_angsuran = $val;
                        } else {
                            return false;
                        }
                    }
					if($key == 'H') { $pair['bunga'] = $val; }
					if($key == 'I') { $pair['angsuran_per_bulan'] = $val; }
					if($key == 'J') { 
						$this->db->select('*');
						$this->db->from('nama_kas_tbl');
						$this->db->where('nama', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['kas_id'] = $query->row()->id; 
						} else {
							$pair['kas_id'] = $val;
						} 	
					}			
					if($key == 'K') { $pair['no_perjanjian_kredit'] = $val; }
					if($key == 'L') { $pair['nomor_rekening'] = $val; }
					if($key == 'M') { $pair['nomor_pensiunan'] = $val;}
					if($key == 'N') { $pair['biaya_asuransi'] = $val; }
					if($key == 'O') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['biaya_asuransi_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['biaya_asuransi_akun'] = $val;
						} 	
					}
					if($key == 'P') { $pair['biaya_administrasi'] = $val;}
					if($key == 'Q') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['biaya_administrasi_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['biaya_administrasi_akun'] =$val; 
						} 	
					}
					if($key == 'R') { $pair['biaya_materai'] = $val; }
					if($key == 'S') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['biaya_materai_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['biaya_materai_akun'] = $val; 
						} 	
					}
					if($key == 'T') { $pair['simpanan_pokok'] = $val; }
					if($key == 'U') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['simpanan_pokok_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['simpanan_pokok_akun'] = $val;
						} 	
					}
					if($key == 'V') { $pair['pokok_bulan_satu'] = $val; }
					if($key == 'W') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['pokok_bulan_satu_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['pokok_bulan_satu_akun'] = $val; 
						} 	
					}
					if($key == 'X') { $pair['bunga_bulan_satu'] = $val; }
					if($key == 'Y') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['bunga_bulan_satu_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['bunga_bulan_satu_akun'] = $val;
						} 	
					}
					if($key == 'Z') { $pair['pencairan_bersih'] = $val; }
					if($key == 'AA') { 
						$this->db->select('*');
						$this->db->from('jns_akun');
						$this->db->where('no_akun', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['pencairan_bersih_akun'] = $query->row()->jns_akun_id; 
						} else {
							$pair['pencairan_bersih_akun'] = $val;
						} 	
					}
					$this->db->select('*');
					$this->db->from('tbl_user');
					$this->db->where('u_name', $this->session->userdata('u_name'));
					$query = $this->db->get();
					if($query->num_rows()>0){
						$pair['user_name'] = $query->row()->u_name; 
					} else {
						return FALSE;
                    } 	
                   
					
                }
                $this->db->insert('repayment_schedule_h', $pair);
                if ($this->db->trans_status() === FALSE) {
                    $this->db->trans_rollback();
                    return FALSE;
                } else {
                    $result = TRUE;
                }
                $pinjam_id = $this->db->insert_id();
                $lama_angsuran = intval($pair['lama_angsuran']);
                for ($z=1; $z <= $lama_angsuran; $z++) { 
                    
                    $paird['pinjam_id'] =  $pinjam_id;
                    $paird['bulan_ke'] =  $z;
                    $paird['pokok_angsuran'] = $pair['plafond_pinjaman'] / $pair['lama_angsuran'];
                    $paird['bunga_angsuran'] = round(((($pair['plafond_pinjaman'] / $pair['lama_angsuran']) * $pair['bunga']) / 100),-(2));
                    $this->db->select('jumlah');
                    $this->db->from('jns_simpan');
                    $this->db->where('jns_simpan', 'SIMPANAN WAJIB ANGGOTA LUAR BIASA');
                    $query = $this->db->get();
                    if($query->num_rows()>0){
                        $paird['simpanan_wajib'] = $query->row()->jumlah; 
                    } else {
                        return FALSE;
                    } 
                    $paird['jumlah_angsuran'] = $paird['pokok_angsuran'] + $paird['bunga_angsuran'] + $paird['simpanan_wajib'];
                    $this->db->select('*');
						$this->db->from('jns_pinjaman');
						$this->db->like('jns_pinjaman', $pair['jenis_pinjaman']);
						$query = $this->db->get();
						if($query->num_rows()>0){
                            $vtenor = $query->row()->tenor; 
						} else {
							return FALSE;
						}
                    if($vtenor == 'Bulan'){
                        $tgl = date("d", strtotime($pair['tgl_pinjam']));
                        $bln = date("m", strtotime($pair['tgl_pinjam']));
                        $thn = date("Y", strtotime($pair['tgl_pinjam']));
                        $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
                        $tgl_tempo_var = $tglpinjam;
                        $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$z." month"));
                    }
                    else if($vtenor == 'Minggu'){
                        $tgl = date("d", strtotime($pair['tgl_pinjam']));
                        $bln = date("m", strtotime($pair['tgl_pinjam']));
                        $thn = date("Y", strtotime($pair['tgl_pinjam']));
                        $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
                        $tgl_tempo_var = $tglpinjam;
                        $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." week"));
                    }
                    else{
                        $tgl = date("d", strtotime($pair['tgl_pinjam']));
                        $bln = date("m", strtotime($pair['tgl_pinjam']));
                        $thn = date("Y", strtotime($pair['tgl_pinjam']));
                        $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
                        $tgl_tempo_var = $tglpinjam;
                        $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." day"));
                    }
                    $paird['tgl_tempo'] = $tgl_tempo;
                    $paird['update_data'] = date("Y-m-d h:i:m");
                    $vusername = $this->session->userdata('u_name');
                    $this->db->select('*');
                    $this->db->from('tbl_user');
                    $this->db->where('u_name', $vusername);
                    $query = $this->db->get();
                    if($query->num_rows()>0){
                        $pair['user_name'] = $query->row()->u_name; 
                    } else {
                        return FALSE;
                    } 	
                   
                    $this->db->insert('repayment_schedule_d', $paird);
                    if ($this->db->trans_status() === FALSE) {
                        $this->db->trans_rollback();
                        return FALSE;
                    } else {
                        $result = TRUE;
                    }
                }
                
				//$pair_arr[] = $pair;
				
            }
            $this->db->trans_complete();
        
			return $result;
			
		} else {
			return FALSE;
		}
	}
	
	
	function get_data_excel() {
		$sql = "SELECT a.*, b.nama FROM v_hitung_pinjaman  a
				JOIN tbl_anggota b ON b.id = a.anggota_id
				WHERE dk like '%%' ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}


	function lap_cetak_pinjaman($id){
		$sql = " SELECT * FROM repayment_schedule_h b  WHERE id =".$id."";
		$result['count'] = $this->db->query($sql)->num_rows();
		$result['data'] = $this->db->query($sql)->result();
		return $result;
    }
    
    	//ambil data pinjaman header berdasarkan ID
	function get_data_pinjam($id) {
		$this->db->select('*');
		$this->db->from('v_hitung_repayment');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
    }


}