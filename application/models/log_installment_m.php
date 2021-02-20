<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class log_installment_m extends CI_Model {

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
	function lap_data_log() {
		$kode_transaksi = isset($_GET['kode_transaksi']) ? $_GET['kode_transaksi'] : '';
		$cari_nama = isset($_GET['cari_nama']) ? $_GET['cari_nama'] : '';
		$cari_anggota = isset($_GET['cari_anggota']) ? $_GET['cari_anggota'] : '';
		$sql = '';
        $sql ='SELECT a.id AS id, a.nomor_pinjaman as nomor_pinjaman, b.ktp as ktp, a.ags_per_bulan as angsuran, a.tempo AS tempo, a.lunas AS lunas, a.tenor as tenor, a.tgl_pinjam AS tgl_pinjam, a.tagihan AS tagihan, a.lama_angsuran AS lama_angsuran,
		a.biaya_adm AS adm,  a.pokok_angsuran AS pokok_angsuran, a.bunga_pinjaman AS bunga_pinjaman,
		b.ktp AS ktp, b.nama AS nama, b.id AS anggota_id
        FROM
	    v_hitung_pinjaman a
		left join tbl_anggota b on b.id = a.anggota_id
        left join tbl_pinjaman_d c on c.pinjam_id = a.id';
        $sql .= ' where lunas = "Belum"';
		$q = array('kode_transaksi' => $kode_transaksi, 
			'cari_anggota' => $cari_anggota,
            'cari_nama' => $cari_nama
        );
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = $q['kode_transaksi'];
				$sql .=" AND (a.nomor_pinjaman LIKE '".$q['kode_transaksi']."' OR anggota_id LIKE '".$q['kode_transaksi']."') ";
			} else {
				if($q['cari_anggota'] != '') {
					$sql .=" AND b.jns_anggotaid = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND b.nama LIKE '%".$q['cari_nama']."%' ";
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

	//panggil data simpanan untuk esyui
	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql ='SELECT a.id AS id, a.nomor_pinjaman as nomor_pinjaman, b.ktp as ktp, a.ags_per_bulan as angsuran, a.tempo AS tempo, a.lunas AS lunas, a.tenor as tenor, a.tgl_pinjam AS tgl_pinjam, a.tagihan AS tagihan, a.lama_angsuran AS lama_angsuran,
		a.biaya_adm AS adm,  a.pokok_angsuran AS pokok_angsuran, a.bunga_pinjaman AS bunga_pinjaman,
		b.ktp AS ktp, b.nama AS nama, b.id AS anggota_id
        FROM
	    v_hitung_pinjaman a
		left join tbl_anggota b on b.id = a.anggota_id
        left join tbl_pinjaman_d c on c.pinjam_id = a.id';
        $sql .= ' where lunas in ("Belum","Lunas") ';
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = $q['kode_transaksi'];
				$sql .=" AND (a.nomor_pinjaman LIKE '%".$q['kode_transaksi']."%') ";
			} else {

				if($q['cari_anggota'] != '') {
					$sql .=" AND b.jns_anggotaid = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND b.nama LIKE '%".$q['cari_nama']."%' ";
				}	
			}
        }
       
        $sql .= 'group by a.id ';
		$sql .= 'order by a.tempo ASC ';
		
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	
	function get_data_excel($q='') {
		$sql ='SELECT a.id AS id, a.nomor_pinjaman as nomor_pinjaman, b.ktp as ktp, a.ags_per_bulan as angsuran, a.tempo AS tempo, a.lunas AS lunas, a.tenor as tenor, a.tgl_pinjam AS tgl_pinjam, a.tagihan AS tagihan, a.lama_angsuran AS lama_angsuran,
		a.biaya_adm AS adm,  a.pokok_angsuran AS pokok_angsuran, a.bunga_pinjaman AS bunga_pinjaman,
		b.ktp AS ktp, b.nama AS nama, b.id AS anggota_id
        FROM
	    v_hitung_pinjaman a
		left join tbl_anggota b on b.id = a.anggota_id
        left join tbl_pinjaman_d c on c.pinjam_id = a.id';
        $sql .= ' where lunas = "Belum"';
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = $q['kode_transaksi'];
				$sql .=" AND (a.nomor_pinjaman LIKE '%".$q['kode_transaksi']."%') ";
			} else {

				if($q['cari_anggota'] != '') {
					$sql .=" AND b.jns_anggotaid = '".$q['cari_anggota']."' ";
				}	
				if($q['cari_nama'] != '') {
					$sql .=" AND b.nama LIKE '%".$q['cari_nama']."%' ";
				}	
			}
        }
       
        $sql .= 'group by a.id ';
		$sql .= 'order by a.tempo ASC ';
		
		$result['count'] = $this->db->query($sql)->num_rows();
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	//menghitung jumlah denda harus dibayar
	function get_jml_denda($id) {
		$this->db->select('SUM(denda_rp) AS total_denda');
		$this->db->from('tbl_pinjaman_d');
		$this->db->where('pinjam_id',$id);
		$query = $this->db->get();
		return $query->row();
	}

	
}