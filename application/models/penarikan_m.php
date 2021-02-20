<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Penarikan_m extends CI_Model {
	public function __construct() {
		parent::__construct();
	}

	#panggil data kas
	function get_data_kas() {
		$this->db->select('*');
		$this->db->from('nama_kas_tbl');
		$this->db->where('aktif', 'Y');
		$this->db->where('tmpl_penarikan', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data penarikan untuk laporan 
	function lap_data_penarikan() {
		$kode_transaksi = isset($_REQUEST['kode_transaksi']) ? $_REQUEST['kode_transaksi'] : '';
		$cari_simpanan = isset($_REQUEST['cari_simpanan']) ? $_REQUEST['cari_simpanan'] : '';
		$cari_anggota = isset($_REQUEST['cari_anggota']) ? $_REQUEST['cari_anggota'] : '';
		$cari_nama = isset($_REQUEST['cari_nama']) ? $_REQUEST['cari_nama'] : '';
		$tgl_dari = isset($_REQUEST['tgl_dari']) ? $_REQUEST['tgl_dari'] : '';
		$tgl_sampai = isset($_REQUEST['tgl_sampai']) ? $_REQUEST['tgl_sampai'] : '';
		$sql = '';
		$sql = " SELECT tbl_trans_sp.*,tbl_anggota.category FROM tbl_trans_sp 
				JOIN tbl_anggota ON tbl_anggota.id = tbl_trans_sp.anggota_id
				WHERE dk='K'  ";
		$q = array('kode_transaksi' => $kode_transaksi, 
			'cari_simpanan' => $cari_simpanan,
			'cari_anggota' => $cari_anggota,
			'cari_nama' => $cari_nama,
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRK', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND (tbl_trans_sp.id LIKE '".$q['kode_transaksi']."') ";
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
	function get_jml_penarikan() {
		$this->db->select('SUM(jumlah) AS jml_total');
		$this->db->from('tbl_trans_sp');
		$this->db->where('dk','K');
		$query = $this->db->get();
		return $query->row();
	}

	//panggil data simpanan untuk esyui
	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT tbl_trans_sp.*,tbl_anggota.category FROM tbl_trans_sp 
				JOIN tbl_anggota ON tbl_anggota.id = tbl_trans_sp.anggota_id
				WHERE dk='K' ";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRK', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND (tbl_trans_sp.id LIKE '".$q['kode_transaksi']."') ";
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
		$data = array(			
			'tgl_transaksi'		=>	$this->input->post('tgl_transaksi'),
			'anggota_id'			=>	$this->input->post('anggota_id'),
			'jenis_id'				=>	$this->input->post('jenis_id'),
			'jumlah'					=>	str_replace(',', '', $this->input->post('jumlah')),
			'keterangan'			=> $this->input->post('ket'),
			'akun'					=>	'Penarikan',
			'dk'						=>	'K',
			'anggota_nama'			=> 	$this->input->post('anggota_nama'),
			'kas_id'					=>	$this->input->post('kas_id'),
			'user_name'				=> $this->data['u_name'],
			'nama_penyetor'			=> $this->input->post('nama_penyetor'),
			'no_identitas'			=> $this->input->post('no_identitas'),
			'alamat'					=> $this->input->post('alamat')
			);
		return $this->db->insert('tbl_trans_sp', $data);
	}


	public function update($id) {
		if(str_replace(',', '', $this->input->post('jumlah')) <= 0) {
			return FALSE;
		}
		
		$tanggal_u = date('Y-m-d H:i');
		$this->db->where('id', $id);
		return $this->db->update('tbl_trans_sp',array(
			'tgl_transaksi'		=>	$this->input->post('tgl_transaksi'),
			'jenis_id'				=>	$this->input->post('jenis_id'),
			'jumlah'					=>	str_replace(',', '', $this->input->post('jumlah')),
			'keterangan'			=> $this->input->post('ket'),
			'kas_id'					=>	$this->input->post('kas_id'),
			'update_data'			=> $tanggal_u,
			'user_name'				=> $this->data['u_name'],
			'nama_penyetor'			=> $this->input->post('nama_penyetor'),
			'no_identitas'			=> $this->input->post('no_identitas'),
			'alamat'					=> $this->input->post('alamat')
			));
		
	}

	public function approve($id){
		$tgl_approve = date('Y-m-d H:i');
		$this->db->set('is_approve', 'X');
		$this->db->set('approve_by', $this->data['u_name']);
		$this->db->set('approve_date', $tgl_approve);
		$this->db->where('id', $id);
		return $this->db->update('tbl_trans_sp');
	}

	public function delete($id) {
		return $this->db->delete('tbl_trans_sp', array('id' => $id)); 
	}
	
	function get_data_excel() {
		$sql = "SELECT a.*, b.identitas, b.departement, c.jns_simpan FROM tbl_trans_sp a
				JOIN tbl_anggota b ON b.id = a.anggota_id
				JOIN jns_simpan c ON a.jenis_id = c.id
				WHERE dk='K'";
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
				$pair['akun'] = 'Penarikan';
				$pair['dk'] = 'K';
				$pair['kas_id'] = 1;
				$pair['user_name'] = $this->data['u_name'];
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('tbl_trans_sp', $pair_arr);
		} else {
			return FALSE;
		}
	}
}