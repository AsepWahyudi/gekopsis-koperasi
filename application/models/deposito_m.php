<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Deposito_m extends CI_Model {

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
	function lap_data_deposito() {
		$kode_transaksi = isset($_REQUEST['kode_transaksi']) ? $_REQUEST['kode_transaksi'] : '';
		$cari_simpanan = isset($_REQUEST['cari_simpanan']) ? $_REQUEST['cari_simpanan'] : '';
		$cari_nama = isset($_REQUEST['cari_nama']) ? $_REQUEST['cari_nama'] : '';
		$cari_anggota = isset($_REQUEST['cari_anggota']) ? $_REQUEST['cari_anggota'] : '';
		$tgl_dari = isset($_REQUEST['tgl_dari']) ? $_REQUEST['tgl_dari'] : '';
		$tgl_sampai = isset($_REQUEST['tgl_sampai']) ? $_REQUEST['tgl_sampai'] : '';
		$sql = '';
		$sql = " SELECT tbl_trans_dp.*,tbl_anggota.category FROM tbl_trans_dp 
				JOIN tbl_anggota ON tbl_anggota.id = tbl_trans_dp.anggota_id
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
					$sql .=" AND tbl_trans_dp.jenis_id = '".$q['cari_simpanan']."%' ";
				}
				if($q['cari_anggota'] != '') {
					$sql .=" AND tbl_anggota.category = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND tbl_trans_dp.anggota_nama LIKE '%".$q['cari_nama']."%' ";
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

	//panggil data jenis deposito
	function get_jenis_deposito($id) {
		$this->db->select('*');
		$this->db->from('jns_deposito');
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
	function get_jml_deposito() {
		$this->db->select('SUM(jumlah) AS jml_total');
		$this->db->from('tbl_trans_dp');
		$this->db->where('dk','D');
		$query = $this->db->get();
		return $query->row();
	}

	//panggil data simpanan untuk esyui
	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT tbl_trans_dp.*,tbl_anggota.category FROM tbl_trans_dp 
				JOIN tbl_anggota ON tbl_anggota.id = tbl_trans_dp.anggota_id
				WHERE dk='D' ";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRD', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND (tbl_trans_dp.id LIKE '%".$q['kode_transaksi']."%') ";
			} else {
				if($q['cari_deposito'] != '') {
					$sql .=" AND tbl_trans_dp.jenis_id = '".$q['cari_deposito']."%' ";
				}
				if($q['cari_anggota'] != '') {
					$sql .=" AND tbl_anggota.category = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND tbl_trans_dp.anggota_nama LIKE '%".$q['cari_nama']."%' ";
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
		// if($this->input->post('tenor') <> '0'){
			$lunas = 'Belum';
		// }
		// else{
			// $lunas = '-';
		// }
		if($this->input->post('tenor') <> '0'){
			$tenor = $this->input->post('tenor');
		}
		else{
			$tenor = 1;
		}
		
		//$str = $this->input->post('jenis_id');
		//$exploded = explode("|",$str);
		//$jenis_id = $exploded[0];
		//$jenis_id = $str;
		//$auto_simpan = $exploded[2];
		
		$data = array(			
			'tgl_transaksi'		=>	$this->input->post('tgl_transaksi'),
			'anggota_id'			=>	$this->input->post('anggota_id'),
			'jenis_id'				=>	$this->input->post('jenis_id'),
			'jumlah'				=>	str_replace(',', '', $this->input->post('jumlah')),
			'tenor'					=>	$tenor,
			'bunga'					=>	$this->input->post('bunga'),
			'keterangan'			=> $this->input->post('ket'),
			'akun'					=>	'Setoran',
			'dk'					=>	'D',
			'anggota_nama'			=> 	$this->input->post('anggota_nama'),
			'kas_id'				=>	$this->input->post('kas_id'),
			'user_name'				=> $this->data['u_name'],
			'nama_penyetor'			=> $this->input->post('nama_penyetor'),
			'no_identitas'			=> $this->input->post('no_identitas'),
			'alamat'					=> $this->input->post('alamat'),
			'lunas'					=> $lunas,
			'buat_ulang'			=> '' //$auto_simpan
			);
		return $this->db->insert('tbl_trans_dp', $data);
	}

	public function update($id)
	{
		if(str_replace(',', '', $this->input->post('jumlah')) <= 0) {
			return FALSE;
		}
		$tanggal_u = date('Y-m-d H:i');
		$this->db->where('id', $id);
		return $this->db->update('tbl_trans_dp',array(
			'tgl_transaksi'		=>	$this->input->post('tgl_transaksi'),
			'jenis_id'				=>	$this->input->post('jenis_id'),
			'tenor'					=>	$this->input->post('tenor'),
			'bunga'					=>	$this->input->post('bunga'),
			'jumlah'				=>	str_replace(',', '', $this->input->post('jumlah')),
			'keterangan'			=> $this->input->post('ket'),
			'kas_id'				=>	$this->input->post('kas_id'),
			'update_data'			=> $tanggal_u,
			'user_name'				=> $this->data['u_name'],
			'nama_penyetor'			=> $this->input->post('nama_penyetor'),
			'no_identitas'			=> $this->input->post('no_identitas'),
			'alamat'				=> $this->input->post('alamat')
			));
	}

	public function approve($id){
		$this->db->set('is_approve', 'X');
		$this->db->set('approve_by', $this->data['u_name']);
		$this->db->where('id', $id);
		return $this->db->update('tbl_trans_dp');
	}


	public function delete($id) {
		return $this->db->delete('tbl_trans_dp', array('id' => $id)); 
	}
	
	function get_data_excel() {
		$sql = "SELECT a.*, b.identitas, b.departement, c.jns_deposito FROM tbl_trans_dp a
				JOIN tbl_anggota b ON b.id = a.anggota_id
				JOIN jns_deposito c ON a.jenis_id = c.id";
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
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['tgl_transaksi'] = $val; }
					if($key == 'B') { $pair['anggota_id'] = (int)str_replace("AG","",$val);}
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
					if($key == 'D') { $pair['jumlah'] = $val; }
					if($key == 'E') { $pair['keterangan'] = $val; }
					if($key == 'F') { $pair['nama_penyetor'] = $val; }
					if($key == 'G') { $pair['no_identitas'] = $val; }
					if($key == 'H') { $pair['alamat'] = $val; }
				}
				$pair['akun'] = 'Setoran';
				$pair['dk'] = 'D';
				$pair['kas_id'] = 1;
				$pair['user_name'] = $this->data['u_name'];
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('tbl_trans_dp', $pair_arr);
		} else {
			return FALSE;
		}
	}
	
	//ambil data depsotio header berdasarkan ID
	function get_data_deposito($id) {
		//$sql = "SELECT a.*,a.tgl_transaksi + INTERVAL a.tenor MONTH AS tempo,a.jumlah / a.tenor AS pokok_angsuran  FROM tbl_trans_dp a WHERE a.id = $id ";
		$sql = "SELECT a.*,a.tgl_transaksi + INTERVAL a.tenor MONTH AS tempo,((((a.jumlah * a.bunga/100)) / a.tenor) + (a.jumlah / a.tenor))  AS pokok_angsuran  FROM tbl_trans_dp a WHERE a.id = $id ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
	
	function get_simulasi_deposito($simpan_id) {
		$row = $this->get_data_deposito($simpan_id);
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
		$this->db->from('tbl_trans_dp_d');
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
		$this->db->from('tbl_trans_dp_d');
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
		$sql = "SELECT * FROM tbl_trans_dp_d WHERE deposito_id=".$id."";
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
		$ags_ke = $this->general_m->get_record_bayar_deposito($this->input->post('pinjam_id')) + 1;
		$jumlah = str_replace(',', '', $this->input->post('jml_bayar')) * 1;
		$jumlah_bayar = $jumlah;
		$data = array(			
						'tgl_bayar'		=>	$this->input->post('tgl_transaksi'),
						'deposito_id'		=>	$this->input->post('pinjam_id'),
						'angsuran_ke'	=>	$ags_ke,
						'jumlah_bayar'	=>	str_replace(',', '', $this->input->post('angsuran')),
						'keterangan'	=>	$this->input->post('ket'),
						'username'		=> $this->data['u_name']
						);
		///// SQL START
		$this->db->trans_start();
		$this->db->insert('tbl_trans_dp_d', $data);

		if($jumlah_bayar == 0) {
			$status = 'Lunas';} 
			else {
			$status = 'Belum';}
		$data = array('lunas' => $status);
		$this->db->where('id', $this->input->post('pinjam_id'));
		$this->db->update('tbl_trans_dp', $data);

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
		return $this->db->update('tbl_trans_dp_d',array(
			'tgl_bayar'		=> $this->input->post('tgl_transaksi'),
			'update_data'	=> $tanggal_u,
			'keterangan'	=>	$this->input->post('ket'),
			'username'		=> $this->data['u_name']
		));
	}
	

	
	public function delete_angsuran($id, $master_id) {
		// cek apakah yg dihapus adalah bukan yg terakhir
		
		$this->db->select('MAX(id) AS id_akhir');
		$this->db->where('deposito_id', $master_id);
		$qu_akhir = $this->db->get('tbl_trans_dp_d');
		$row_akhir = $qu_akhir->row();
		if($row_akhir->id_akhir != $id) {
			return false;
		} else {
			$this->db->delete('tbl_trans_dp_d', array('id' => $id));
			$this->auto_status_lunas($master_id);
		}
		
		$this->db->delete('tbl_trans_dp_d', array('id' => $id));
		if($this->auto_status_lunas($master_id)) {
			return TRUE;
		}
	}
	
	function auto_status_lunas($master_id) {
		$pinjam = $this->general_m->get_data_deposito($master_id);
		$tagihan = $pinjam->tenor * $pinjam->pokok_angsuran;
		$total_tagihan = $tagihan;
		if($total_tagihan <= 0) {
			$status = 'Lunas';} 
		else {
			$status = 'Belum';}
		$data = array('lunas' => $status);
		$this->db->where('id', $master_id);
		$this->db->update('tbl_trans_dp_d', $data);
		return TRUE;
	}

	function get_level_by_id($username) {
		$this->db->select('level');
		$this->db->from('tbl_user');
		$this->db->where('u_name', $username);
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
}