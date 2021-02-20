<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class General_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}

	//panggil data anggota untuk combo 
	function get_data_anggota_ajax($q,$r) {
		$sql = "SELECT * FROM tbl_anggota WHERE aktif='Y' ";
		if($r !='') {
			$sql .=" AND (jns_anggotaid = '$r') ";
		}
		if($q !='') {
			$sql .=" AND (ktp LIKE '%{$q}%' OR nama LIKE '%{$q}%') ";
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY ktp ASC ";
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	function get_data_category_ajax($q) {
		$sql = "SELECT * FROM jns_anggota WHERE status='Y' ";
		if($q !='') {
			$sql .=" AND (nama LIKE '%{$q}%') ";
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY id ASC ";
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	//panggil data anggota berdasarkan ID
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

	//panggil data anggota tanpa ID
	function get_anggota() {
		$this->db->select('*');
		$this->db->from('tbl_anggota');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data anggota tanpa ID
	function get_category() {
		$this->db->select('*');
		$this->db->from('jns_anggota');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}


	//panggil data pengajuan
	function get_pengajuan() {
		$this->db->select('*');
		$this->db->from('jns_pengajuan');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data anggota tanpa ID
	function get_anggota2() {
		$this->db->select('*');
		$this->db->from('tbl_anggota');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}


	//hitung jumlah anggota
	function get_jml_anggota($id) {
		$this->db->select('id');
		$this->db->from('tbl_anggota');
		$this->db->where('aktif','Y');
		$query = $this->db->get();
		return $query->num_rows();
	}

	//panggil data jenis simpanan dengan id
	function get_jns_simpanan($id) {
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

	//panggil data jenis deposito
	// debaluk, 5-10-2019
	function get_id_deposito() {
		$this->db->select('*');
		$this->db->from('jns_deposito');
		$this->db->where('tampil', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
	
	function get_jns_deposito($id) {
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

		//panggil data jenis akun
		function get_jns_akun($id) {
			$this->db->select('*');
			$this->db->from('jns_akun');
			$this->db->where('jns_akun_id',$id);
			$query = $this->db->get();
			if($query->num_rows()>0){
				$out = $query->result();
				return $out;
			} else {
				return FALSE;
			}
		}

		function get_id_akun() {
			$this->db->select('*');
			$this->db->from('jns_akun');
			$query = $this->db->get();
			if($query->num_rows()>0){
				$out = $query->result();
				return $out;
			} else {
				return FALSE;
			}
		}

		//panggil data cabang by id
		function get_jns_cabang($id) {
			$this->db->select('*');
			$this->db->from('jns_cabang');
			$this->db->where('jns_cabangid',$id);
			$query = $this->db->get();
			if($query->num_rows()>0){
				$out = $query->result();
				return $out;
			} else {
				return FALSE;
			}
		}

		function get_data_cabang() {
			$this->db->select('*');
			$this->db->from('jns_cabang');
			$query = $this->db->get();
			if($query->num_rows()>0){
				$out = $query->result();
				return $out;
			} else {
				return FALSE;
			}
		}
	
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
	
	function get_jml_bayar_deposito($id) {		//hitung jumlah deposito yang sudah di bayar
		$this->db->select('SUM(jumlah_bayar) AS total');
		$this->db->from('tbl_trans_dp_d');
		$this->db->where('deposito_id',$id);
		$query = $this->db->get();
		return $query->row();
	}
	
	function get_record_bayar_deposito($id) {  //hitung sudah di bayar depositonya
		$this->db->select('id');
		$this->db->from('tbl_trans_dp_d');
		$this->db->where('deposito_id',$id);
		$query = $this->db->get();
		return $query->num_rows();
	}
	/*selesai deposito */
	
	//panggil data jenis simpanan
	function get_id_simpanan() {
		$this->db->select('*');
		$this->db->from('jns_simpan');
		$this->db->where('tampil', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//panggil data jenis pinjaman
	function get_id_pinjaman() {
		$this->db->select('*');
		$this->db->from('jns_pinjaman');
		$this->db->where('tampil', 'Y');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	//menghitung jumlah pinjaman seluruhnya
	function get_total_pinjaman() {
		$this->db->select('SUM(tagihan) AS total');
		$this->db->from('v_hitung_pinjaman');
		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah yang sudah dibayar dengan id pinjam
	function get_jml_bayar($id) {
		$this->db->select('SUM(jumlah_bayar) AS total');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id',$id);
		$query = $this->db->get();
		return $query->row();
	}
	//menghitung jumlah yang sudah dibayar dengan id simpan
	function get_jml_bayar_simpanan($id) {
		$this->db->select('SUM(jumlah_bayar) AS total');
		$this->db->from('tbl_trans_sp_d');
		$this->db->where('simpan_id',$id);
		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah yang sudah dibayar seluruhnya
	function get_total_dibayar() {
		$this->db->select('SUM(jumlah_bayar) AS total');
		$this->db->from('tbl_pinjaman_d');
		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah denda harus dibayar dengan ID pinjam
	function get_jml_denda($id) {
		$this->db->select('SUM(denda_rp) AS total_denda');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id',$id);
		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah   denda seluruhnya
	function get_total_denda() {
		$this->db->select('SUM(denda_rp) AS total_denda');
		$this->db->from('tbl_pinjaman_d');
		$query = $this->db->get();
		return $query->row();
	}

	//mecari banyaknya data yg diinput pinjaman detail
	function get_record_bayar($id) {
		$this->db->select('id');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id',$id);
		$this->db->where('ket_bayar','Angsuran');
		$query = $this->db->get();
		return $query->num_rows();
	}
	
	//mecari banyaknya data yg diinput simpanan detail
	function get_record_bayar_simpanan($id) {
		$this->db->select('id');
		$this->db->from('tbl_trans_sp_d');
		$this->db->where('simpan_id',$id);
		$query = $this->db->get();
		return $query->num_rows();
	}

	//ambil data pinjaman header berdasarkan ID
	function get_data_pinjam($id) {
		$this->db->select('*');
    $this->db->from('v_hitung_pinjaman');
    //$this->db->from('tbl_pinjaman_h a');
		$this->db->where('id',$id);
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
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

	//panggil data pinjaman tanpa id
	function data_pinjaman() {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}


	//panggil data pinjaman detail berdasarkan pinjam ID
	function get_data_pembayaran($id) {
		$this->db->select('*');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id', $id);
		$this->db->order_by('id', 'ASC');
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data pinjaman detail berdasarkan ID
	function get_data_pembayaran_by_id($id) {
		$this->db->select('*');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('id', $id);
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}

	//panggil data denda dan tempo 
	function get_semua_denda_by_pinjaman($master_id) {
		$pinjam = $this->get_data_pinjam($master_id);
		$this->db->select('MAX(angsuran_ke) AS angsuran_ke');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id', $master_id);
		$query = $this->db->get();
		$ags = $query->row();
		$ags_ke = $ags->angsuran_ke;

		$sisa_ags_det = $pinjam->lama_angsuran - ($ags_ke) ;
		// DENDA
		$denda_semua = 0;
		$tgl_pinjam = substr($pinjam->tgl_pinjam, 0, 7) . '-01';
		$tgl_tempo = date('Y-m-d', strtotime("+".$ags_ke." months", strtotime($tgl_pinjam)));
		$tgl_bayar = date('Y-m-d');
		$data_bunga_arr = $this->bunga_m->get_key_val();
		$denda_hari = $data_bunga_arr['denda_hari'];
		$tgl_tempo = str_replace('-', '', $tgl_tempo);
		$tgl_bayar = str_replace('-', '', $tgl_bayar);
		$tgl_toleransi = $tgl_bayar - ($tgl_tempo - 1);
		if ( $tgl_toleransi > $denda_hari ) { // 20140615 - 20140600
			$denda_semua = ($data_bunga_arr['denda'] * $sisa_ags_det);
		}
		return $denda_semua;
	}	
	
	//data data jenis anggota
	function get_jenis_anggota() {
		$this->db->select('*');
		$this->db->from('jns_anggota');
		$this->db->order_by('nama', 'ASC');
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
	
	function get_jenis_anggota_by_id($id) {
		$this->db->select('*');
		$this->db->from('jns_anggota');
		$this->db->where_in('id', $id);
		$this->db->order_by('nama', 'ASC');
		$query = $this->db->get();

		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
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

	//panggil data kategori asset by id
	function get_kategori_asset($id) {
		$this->db->select('*');
		$this->db->from('kategori_asset');
		$this->db->where('kategori_asset_id',$id);
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

}

