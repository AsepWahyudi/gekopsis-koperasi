<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Simpanan_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}

	#panggil data kas
	function get_data_kas() {
		$this->db->select('*');
		$this->db->from('nama_kas_tbl');
		$this->db->where('aktif', 'Y');
		$this->db->where('tmpl_simpan', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data simpanan untuk laporan 
	function lap_data_simpanan() {
		$kode_transaksi = isset($_REQUEST['kode_transaksi']) ? $_REQUEST['kode_transaksi'] : '';
		$cari_simpanan = isset($_REQUEST['cari_simpanan']) ? $_REQUEST['cari_simpanan'] : '';
		$cari_nama = isset($_REQUEST['cari_nama']) ? $_REQUEST['cari_nama'] : '';
		$cari_anggota = isset($_REQUEST['cari_anggota']) ? $_REQUEST['cari_anggota'] : '';
		$tgl_dari = isset($_REQUEST['tgl_dari']) ? $_REQUEST['tgl_dari'] : '';
		$tgl_sampai = isset($_REQUEST['tgl_sampai']) ? $_REQUEST['tgl_sampai'] : '';
		$sql = '';
		$sql = " SELECT tbl_trans_sp.*,tbl_anggota.category FROM tbl_trans_sp 
				JOIN tbl_anggota ON tbl_anggota.id = tbl_trans_sp.anggota_id
				WHERE dk='D' ";
		$q = array('kode_transaksi' => $kode_transaksi, 
			'cari_simpanan' => $cari_simpanan,
			'cari_anggota' => $cari_anggota,
			'cari_nama' => $cari_nama,
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRD', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = str_replace('AG', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND (id LIKE '".$q['kode_transaksi']."' OR anggota_id LIKE '".$q['kode_transaksi']."') ";
			} else {
				if($q['cari_simpanan'] != '') {
					$sql .=" AND tbl_trans_sp.jenis_id = '".$q['cari_simpanan']."%' ";
				}
				if($q['cari_anggota'] != '') {
					$sql .=" AND tbl_anggota.category = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND tbl_trans_sp.anggota_nama LIKE '%".$q['cari_nama']."%' ";
				}	
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$sql .=" AND DATE(tgl_transaksi) >= '".$q['tgl_dari']."' ";
					$sql .=" AND DATE(tgl_transaksi) <= '".$q['tgl_sampai']."' ";
				}
			}
		}
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data anggota
	function get_data_anggota($id) {
		$this->db->select('*');
		$this->db->from('tbl_anggota');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data jenis simpan
	function get_jenis_simpan($id) {
		$this->db->select('*');
		$this->db->from('jns_simpan');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}

	//hitung jumlah total simpanan
	function get_jml_simpanan() {
		$this->db->select('SUM(jumlah) AS jml_total');
		$this->db->from('tbl_trans_sp');
		$this->db->where('dk','D');
		$query = $this->db->get();
		return $query->row();
	}

	//panggil data simpanan untuk esyui
	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT tbl_trans_sp.*,tbl_anggota.category FROM tbl_trans_sp 
				JOIN tbl_anggota ON tbl_anggota.id = tbl_trans_sp.anggota_id
				WHERE dk='D' ";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRD', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND (tbl_trans_sp.id LIKE '%".$q['kode_transaksi']."%') ";
			} else {
				if($q['cari_simpanan'] != '') {
					$sql .=" AND tbl_trans_sp.jenis_id = '".$q['cari_simpanan']."%' ";
				}
				if($q['cari_anggota'] != '') {
					$sql .=" AND tbl_anggota.category = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND tbl_trans_sp.anggota_nama LIKE '%".$q['cari_nama']."%' ";
				}	
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$sql .=" AND DATE(tgl_transaksi) >= '".$q['tgl_dari']."' ";
					$sql .=" AND DATE(tgl_transaksi) <= '".$q['tgl_sampai']."' ";
				}
			}
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY {$sort} {$order} ";
		$sql .=" LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	public function create() {
		if(str_replace(',', '', $this->input->post('jumlah')) <= 0) {
			return FALSE;
		}		
			$lunas = 'Belum';
		
		if( $this->input->post('tenor') != 0 ){
			$tenor = $this->input->post('tenor');
		}
		else{
			$tenor = 1;
		}
	
		$this->db->select('*');
		$this->db->from('jns_simpan');
		$this->db->where('id', $this->input->post('jenis_id'));
		$query = $this->db->get();
		if($query->num_rows()>0){
			$jenis_id = $query->row()->id; 
			$auto_simpan= $query->row()->auto_simpan; 
		}

		
		//$str = $this->input->post('jenis_id');
		//$exploded = explode("|",$str);
		//$jenis_id = $exploded[0];
		// $tenor = $exploded[1];
		//$auto_simpan = $exploded[2];
		
		$data = array(			
			'tgl_transaksi'		=>	$this->input->post('tgl_transaksi'),
			'anggota_id'			=>	$this->input->post('anggota_id'),
			'jenis_id'				=>	$jenis_id,
			'jumlah'				=>	str_replace(',', '', $this->input->post('jumlah')),
			'tenor'					=>	$tenor,
			'bunga'					=>	$this->input->post('bunga'),
			'keterangan'			=> $this->input->post('ket'),
			'akun'					=>	'Setoran',
			'dk'					=>	'D',
			'anggota_nama'			=> 	$this->input->post('anggota_nama'),
			'kas_id'				=>	$this->input->post('kas_id'),
			'user_name'				=> $this->data['u_name'],
			'jns_cabangid'		=> $this->input->post('jenis_cabang'),
			'nama_penyetor'			=> $this->input->post('nama_penyetor'),
			'no_identitas'			=> $this->input->post('no_identitas'),
			'alamat'					=> $this->input->post('alamat'),
			'lunas'					=> $lunas,
			'buat_ulang'					=> $auto_simpan
			);
		return $this->db->insert('tbl_trans_sp', $data);
	}

	public function update($id)
	{
		if(str_replace(',', '', $this->input->post('jumlah')) <= 0) {
			return FALSE;
		}
		$tanggal_u = date('Y-m-d H:i');
		$this->db->where('id', $id);
		return $this->db->update('tbl_trans_sp',array(
			'tgl_transaksi'		=>	$this->input->post('tgl_transaksi'),
			'jenis_id'				=>	$this->input->post('jenis_id'),
			'jumlah'					=>	str_replace(',', '', $this->input->post('jumlah')),
			'tenor'			=> $this->input->post('tenor'),
			'keterangan'			=> $this->input->post('ket'),
			'kas_id'					=>	$this->input->post('kas_id'),
			'update_data'			=> $tanggal_u,
			'user_name'				=> $this->data['u_name'],
			'nama_penyetor'		=> $this->input->post('nama_penyetor'),
			'no_identitas'			=> $this->input->post('no_identitas'),
			'jns_cabangid'			=> $this->input->post('jenis_cabang'),
			'alamat'					=> $this->input->post('alamat')
			));
	}

	public function approve($id){
		$this->db->trans_start();

			$approveby = $this->data['u_name'];
			$tgl_approve = date('Y-m-d H:i');
			$this->db->set('is_approve', 'X');
			$this->db->set('approve_by', $approveby);
			$this->db->set('approve_date', $tgl_approve);
			$this->db->where('id', $id);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			return false;
		} else {
			$sql = "CALL ApproveJournalSimpanan(".$id.",'".$approveby."')";
			$this->db->query($sql);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				return FALSE;
			} else {
				$this->db->trans_complete();
				return $this->db->update('tbl_trans_sp');
			}
		}
		
	}

	public function delete($id) {
		return $this->db->delete('tbl_trans_sp', array('id' => $id)); 
	}
	
	function get_data_excel() {
		$sql = "SELECT a.*, b.identitas, b.departement, c.jns_simpan FROM tbl_trans_sp a
				JOIN tbl_anggota b ON b.id = a.anggota_id
				JOIN jns_simpan c ON a.jenis_id = c.id";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
	
	public function import_db($data) {
		if(is_array($data)) {

			$pair_arr = array();
			foreach ($data as $rows) {
				//if(trim($rows['A']) == '') { continue; }
				// per baris
				$pair = array();
				$anggota = "";
				foreach ($rows as $key => $val) {	
					if($key == 'A') { 
						$valb = date('H:i');
						$val = $val.' '.$valb;
						$pair['tgl_transaksi'] = $val; 
					}
					if($key == 'B') { 
						$this->db->select('*');
						$this->db->from('tbl_anggota');
						$this->db->where('nama', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['anggota_id'] = $query->row()->id; 
							$pair['anggota_nama'] =  $val;
							$anggota =true;
						} else {
							$anggota = false;
						}
					}
					if ($anggota === true){
						
						if($key == 'C') { 
							$this->db->select('*');
							$this->db->from('jns_simpan');
							$this->db->where('jns_simpan', $val);
							$query = $this->db->get();
							if($query->num_rows()>0){
								$pair['jenis_id'] = $query->row()->id; 
							} else {
								$pair['jenis_id'] = 0; 
							}
						}
						
						if($key == 'D') { $pair['bunga'] = $val; }
						if($key == 'E') { $pair['jumlah'] = $val; }
						if($key == 'F') { 
							if($val != "") {
								$pair['tenor'] = $val; 
							} else {
								$pair['tenor'] = 1;
							}
							
						}
						if($key == 'G') { $pair['keterangan'] = $val; }
						if($key == 'H') { $pair['nama_penyetor'] = $val; }
						if($key == 'I') { $pair['no_identitas'] = $val; }
						if($key == 'J') { $pair['alamat'] = $val; }
					}
					
				}
				if($anggota === true){
					$pair['lunas'] = 'Belum';
					$pair['akun'] = 'Setoran';
					$pair['dk'] = 'D';
					$pair['kas_id'] = 1;
					$pair['user_name'] = $this->data['u_name'];
					$pair_arr[] = $pair;
				}
			}
			return $this->db->insert_batch('tbl_trans_sp', $pair_arr);
		} else {
			return FALSE;
		}
	}
	
	//ambil data simpanan header berdasarkan ID
	function get_data_simpanan($id) {
		$sql = "SELECT a.*,a.tgl_transaksi + INTERVAL a.tenor MONTH AS tempo,a.jumlah / a.tenor AS pokok_angsuran  FROM tbl_trans_sp a WHERE a.id = $id ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
	
	function get_simulasi_simpanan($simpan_id) {
		$row = $this->get_data_simpanan($simpan_id);
		if($row) {
			$out = array();
			$tgl_tempo_next = 0;
			for ($i=1; $i <= $row->tenor; $i++) { 
				$odat = array();
				$odat['angsuran_pokok'] = $row->jumlah * 1;
				$odat['tgl_pinjam'] = substr($row->tgl_transaksi, 0, 10);
				$odat['jumlah_ags'] = $row->pokok_angsuran;
				$tgl_tempo_var = substr($row->tgl_transaksi, 0, 7) . '-01';
				$tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." month"));
				$tgl = substr($row->tgl_transaksi,-11,-9);
				$tgl_tempo = substr($tgl_tempo, 0, 7) . '-' . $tgl;
				$odat['tgl_tempo'] = $tgl_tempo;
				$out[] = $odat;
			}
			return $out;
		} else {
			return FALSE;
		}
	}
	
	
	//panggil detail  angsuran
	function get_data_angsuran($simpan_id) {
		$this->db->select('*');
		$this->db->from('tbl_trans_sp_d');
		$this->db->where('simpan_id', $simpan_id);
		$this->db->order_by('tgl_bayar', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}
	
	//panggil data pinjaman detail berdasarkan ID
	function get_data_pembayaran_by_id($id) {
		$this->db->select('*');
		$this->db->from('tbl_trans_sp_d');
		$this->db->where('id', $id);
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
	
	function get_data_transaksi_ajax_detail($offset, $limit, $q='', $sort, $order, $id) {
		$sql = "SELECT * FROM tbl_trans_sp_d WHERE simpan_id=".$id."";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TBY', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND id LIKE '%".$q['kode_transaksi']."%'";
			}
			if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
				$sql .=" AND DATE(tgl_bayar) >= '".$q['tgl_dari']."' ";
				$sql .=" AND DATE(tgl_bayar) <= '".$q['tgl_sampai']."' ";
			}
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY {$sort} {$order} ";
		$sql .=" LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
	
	public function create_angsuran() {
		$ags_ke = $this->general_m->get_record_bayar_simpanan($this->input->post('pinjam_id')) + 1;
		$jumlah = str_replace(',', '', $this->input->post('jml_bayar')) * 1;
		$jumlah_bayar = $jumlah;
		$data = array(			
						'tgl_bayar'		=>	$this->input->post('tgl_transaksi'),
						'simpan_id'		=>	$this->input->post('pinjam_id'),
						'angsuran_ke'	=>	$ags_ke,
						'jumlah_bayar'	=>	str_replace(',', '', $this->input->post('angsuran')),
						'keterangan'	=>	$this->input->post('ket'),
						'username'		=> $this->data['u_name']
						);
		///// SQL START
		$this->db->trans_start();
		$this->db->insert('tbl_trans_sp_d', $data);

		if($jumlah_bayar == 0) {
			$status = 'Lunas';} 
			else {
			$status = 'Belum';}
		$data = array('lunas' => $status);
		$this->db->where('id', $this->input->post('pinjam_id'));
		$this->db->update('tbl_trans_sp', $data);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			// error insert
			return FALSE;
		} else {
			$this->db->trans_complete();
			return TRUE;
		}
		///// SQL END
	}
	
	public function update_angsuran($id) {
		$tanggal_u = date('Y-m-d H:i');
		$this->db->where('id', $id);
		return $this->db->update('tbl_trans_sp_d',array(
			'tgl_bayar'		=> $this->input->post('tgl_transaksi'),
			'update_data'	=> $tanggal_u,
			'keterangan'	=>	$this->input->post('ket'),
			'username'		=> $this->data['u_name']
		));
	}
	

	
	public function delete_angsuran($id, $master_id) {
		// cek apakah yg dihapus adalah bukan yg terakhir
		
		$this->db->select('MAX(id) AS id_akhir');
		$this->db->where('simpan_id', $master_id);
		$qu_akhir = $this->db->get('tbl_trans_sp_d');
		$row_akhir = $qu_akhir->row();
		if($row_akhir->id_akhir != $id) {
			return false;
		} else {
			$this->db->delete('tbl_trans_sp_d', array('id' => $id));
			$this->auto_status_lunas($master_id);
		}
		
		$this->db->delete('tbl_trans_sp_d', array('id' => $id));
		if($this->auto_status_lunas($master_id)) {
			return TRUE;
		}
	}
	
	function auto_status_lunas($master_id) {
		$pinjam = $this->general_m->get_data_simpanan($master_id);
		$tagihan = $pinjam->tenor * $pinjam->pokok_angsuran;
		$total_tagihan = $tagihan;
		if($total_tagihan <= 0) {
			$status = 'Lunas';} 
		else {
			$status = 'Belum';}
		$data = array('lunas' => $status);
		$this->db->where('id', $master_id);
		$this->db->update('tbl_trans_sp_d', $data);
		return TRUE;
	}
}