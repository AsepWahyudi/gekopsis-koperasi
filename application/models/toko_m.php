<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Toko_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}

	#panggil data kas
	function get_data_kas() {
		$this->db->select('*');
		$this->db->from('tbl_transaksi_toko');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	#panggil data kas
	function get_data_nama($id) {
		$this->db->select('*');
		$this->db->from('tbl_barang');
		$this->db->where('id',$id);
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}


//panggil nama kas
	function get_nama_kas_id($id) {
		$this->db->select('*');
		$this->db->from('tbl_transaksi_toko');
		$this->db->where('id',$id);
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
	
	//panggil data simpanan untuk laporan 
	function lap_data_transfer() {
		$kode_transaksi = isset($_REQUEST['kode_transaksi']) ? $_REQUEST['kode_transaksi'] : '';
		$tgl_dari = isset($_REQUEST['tgl_dari']) ? $_REQUEST['tgl_dari'] : '';
		$tgl_sampai = isset($_REQUEST['tgl_sampai']) ? $_REQUEST['tgl_sampai'] : '';
		$sql = '';
		$sql = " SELECT * FROM tbl_trans_kas WHERE akun='Transfer' ";
		$q = array('kode_transaksi' => $kode_transaksi, 
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRF', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND id LIKE '".$q['kode_transaksi']."' ";
			} else {		
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$sql .=" AND DATE(tgl_catat) >= '".$q['tgl_dari']."' ";
					$sql .=" AND DATE(tgl_catat) <= '".$q['tgl_sampai']."' ";
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

	//hitung jumlah total 
	function get_jml_transfer() {
		$this->db->select('SUM(jumlah) AS jml_total');
		$this->db->from('tbl_transaksi_toko');
		$this->db->where('akun','Transfer');
		$query = $this->db->get();
		return $query->row();
	}

	//panggil data simpanan untuk esyui
	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT tbl_transaksi_toko.*,tbl_barang.nm_barang, c.nama FROM tbl_transaksi_toko INNER JOIN tbl_barang ON tbl_barang.id=tbl_transaksi_toko.id_barang
				JOIN tbl_anggota c ON c.id =tbl_transaksi_toko.anggota_id";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = str_replace('TRF', '', $q['kode_transaksi']);
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$sql .=" AND id LIKE '".$q['kode_transaksi']."' ";
			} else {
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$sql .=" AND DATE(tgl_catat) >= '".$q['tgl_dari']."' ";
					$sql .=" AND DATE(tgl_catat) <= '".$q['tgl_sampai']."' ";
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
		if($this->input->post('tipe') == 'keluar'){
			$anggota_id = $this->input->post('anggota_id');
		}
		else{
			$anggota_id = 0;
		}
		$data = array(			
			'tgl'					=>	$this->input->post('tgl_transaksi'),
			'anggota_id'				=> $anggota_id,
			'id_barang'					=>	$this->input->post('barang_id'),
			'harga'					=>	str_replace(',', '', $this->input->post('harga')),
			'jumlah'				=>	str_replace(',', '', $this->input->post('jumlah')),
			'keterangan'			=>	$this->input->post('ket'),
			'tipe'					=>	$this->input->post('tipe'),
			);
		return $this->db->insert('tbl_transaksi_toko', $data);
	}

	public function update($id)
	{
		if(str_replace(',', '', $this->input->post('jumlah')) <= 0) {
			return FALSE;
		}
		$tanggal_u = date('Y-m-d H:i');
		$this->db->where('id', $id);
		return $this->db->update('tbl_transaksi_toko',array(
			'tgl'					=>	$this->input->post('tgl_transaksi'),
			'id_barang'					=>	$this->input->post('barang_id'),
			'harga'					=>	str_replace(',', '', $this->input->post('harga')),
			'jumlah'				=>	str_replace(',', '', $this->input->post('jumlah')),
			'keterangan'			=>	$this->input->post('ket'),
			'tipe'					=>	$this->input->post('tipe'),
			));
	}

	public function delete($id){
		return $this->db->delete('tbl_transaksi_toko', array('id' => $id)); 
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
					if($key == 'A') { $pair['tgl'] = $val; }
					if($key == 'B') { 
						$this->db->select('*');
						$this->db->from('tbl_barang');
						$this->db->where('nm_barang', $val);
						$query = $this->db->get();
						if($query->num_rows()>0){
							$pair['id_barang'] = $query->row()->id; 
						} else {
							$pair['id_barang'] = 0; 
						}
					}
					if($key == 'C') { $pair['harga'] = $val; }
					if($key == 'D') { $pair['jumlah'] = $val; }
					if($key == 'E') { $pair['keterangan'] = $val; }
					if($key == 'F') { $pair['tipe'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			//var_dump($pair_arr);
			//return 1;
			return $this->db->insert_batch('tbl_transaksi_toko', $pair_arr);
		} else {
			return FALSE;
		}
	}
	
	function get_data_excel() {
		$sql = "SELECT a.*, b.nm_barang FROM tbl_transaksi_toko a 
				JOIN tbl_barang b ON b.id = a.id_barang";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
}