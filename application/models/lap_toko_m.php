<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_toko_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}

	//menghitung jumlah tagihan
	function get_jml_pinjaman() {
		$this->db->select('SUM(jumlah) AS jml_total, SUM(provinsi) as jml_prv');
		$this->db->from('v_hitung_pinjaman');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}

	function get_data_lap_toko() {
		$sql = 'select tbl_barang.id as id_brng, tbl_barang.nm_barang as nm_barang,(select sum(jumlah) from tbl_transaksi_toko where id_barang = id_brng) as jumlah,(select sum(jumlah) from tbl_transaksi_toko where id_barang = id_brng and tipe="masuk") as jml_masuk,(select sum(harga) from tbl_transaksi_toko where id_barang = id_brng and tipe="masuk") as hrg_masuk,(select sum(jumlah) from tbl_transaksi_toko where id_barang = id_brng and tipe="keluar") as jml_keluar,(select sum(harga) from tbl_transaksi_toko where id_barang = id_brng and tipe="keluar") as hrg_keluar from tbl_barang left join tbl_transaksi_toko on tbl_transaksi_toko.id_barang = tbl_barang.id';

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];

			$sql .=" where DATE(tbl_transaksi_toko.tgl) >= '".$tgl_dari."' and DATE(tbl_transaksi_toko.tgl) <= '".$tgl_samp."'";
		} 

		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	function get_data_lap_pinjaman_toko() {
		$sql = "SELECT a.*, b.jns_pinjaman, c.nama, d.nm_barang FROM tbl_pinjaman_h a 
				JOIN jns_pinjaman b ON b.id = a.jenis_pinjaman
				JOIN tbl_anggota c ON c.id = a.anggota_id
				JOIN tbl_barang d ON d.id = a.barang_id
				WHERE b.transaksi_toko = 'Y'";

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];

			$sql .=" and DATE(a.tgl_pinjam) >= '".$tgl_dari."' and DATE(a.tgl_pinjam) <= '".$tgl_samp."'";
		} 

		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	// jumlah yg harus diangsur
	function get_jml_estimasi_angsur() {
		$this->db->select('SUM(ags_per_bulan * lama_angsuran) AS jml_total');
		$this->db->from('v_hitung_pinjaman');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}

	//jumlah biaya adm
	function get_jml_biaya_adm() {
		$this->db->select('SUM(biaya_adm * lama_angsuran) AS jml_total');
		$this->db->from('v_hitung_pinjaman');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}

	//jumlah bunga
	function get_jml_bunga() {
		$this->db->select('SUM(bunga_pinjaman * lama_angsuran) AS jml_total');
		$this->db->from('v_hitung_pinjaman');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}


	//menghitung jumlah tagihan
	function get_jml_tagihan() {
		$this->db->select('SUM(tagihan) AS jml_total');
		$this->db->from('v_hitung_pinjaman');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah angsuran
	function get_jml_angsuran() {
		$this->db->select('SUM(jumlah_bayar) AS jml_total');
		$this->db->from('tbl_pinjaman_d');
		$this->db->join('tbl_pinjaman_h', 'tbl_pinjaman_h.id = tbl_pinjaman_d.pinjam_id', 'LEFT');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tbl_pinjaman_h.tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tbl_pinjaman_h.tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}

	//menghitung jumlah denda harus dibayar
	function get_jml_denda() {
		$this->db->select('SUM(denda_rp) AS total_denda');
		$this->db->from('tbl_pinjaman_d');
		$this->db->join('tbl_pinjaman_h', 'tbl_pinjaman_h.id = tbl_pinjaman_d.pinjam_id', 'LEFT');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tbl_pinjaman_h.tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tbl_pinjaman_h.tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}

	//hitung jumlah peminjam aktif
	function get_peminjam_aktif() {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		
		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->num_rows();
	}

	//hitung jumlah peminjam lunas
	function get_peminjam_lunas() {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('lunas','Lunas');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->num_rows();
	}

	//hitung jumlah peminjam belum lunas
	function get_peminjam_belum() {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('lunas','Belum');

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->num_rows();
	}

	function get_data_akun_dapat() {
		$this->db->select('*');
		$this->db->from('jns_akun');
		$this->db->where('aktif', 'Y');
		$this->db->where('laba_rugi', 'PENDAPATAN');
		$this->db->where('CHAR_LENGTH(kd_aktiva) >', '1', FALSE);
		$this->db->_protect_identifiers = FALSE;
		$this->db->order_by('LPAD(kd_aktiva, 1, 0) ASC, LPAD(kd_aktiva, 5, 1)', 'ASC');
		$this->db->_protect_identifiers = TRUE;
		$query = $this->db->get();
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_data_akun_biaya() {
		$this->db->select('*');
		$this->db->from('jns_akun');
		$this->db->where('aktif', 'Y');
		$this->db->where('laba_rugi', 'BIAYA');
		$this->db->where('CHAR_LENGTH(kd_aktiva) >', '1', FALSE);
		$this->db->_protect_identifiers = FALSE;
		$this->db->order_by('LPAD(kd_aktiva, 1, 0) ASC, LPAD(kd_aktiva, 5, 1)', 'ASC');
		$query = $this->db->get();
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}


	function get_jml_akun($akun) {
			$this->db->select('SUM(debet) AS jum_debet, SUM(kredit) AS jum_kredit');
			$this->db->from('v_transaksi');
			$this->db->where('transaksi', $akun);

			if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$this->db->where('DATE(tgl) >= ', ''.$tgl_dari.'');
		$this->db->where('DATE(tgl) <= ', ''.$tgl_samp.'');

		$query = $this->db->get();
		return $query->row();
	}
	
	// Lap Toko Baru
	
	function get_data_lap_transaksi_toko() {
		$sql = 'SELECT tbl_transaksi_toko.*,tbl_barang.nm_barang, c.nama FROM tbl_transaksi_toko INNER JOIN tbl_barang ON tbl_barang.id=tbl_transaksi_toko.id_barang
				JOIN tbl_anggota c ON c.id =tbl_transaksi_toko.anggota_id';

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];

			$sql .=" where DATE(tbl_transaksi_toko.tgl) >= '".$tgl_dari."' and DATE(tbl_transaksi_toko.tgl) <= '".$tgl_samp."'";
		} 

		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
	
	function get_data_excel() {
		$sql = "SELECT a.*, b.jns_pinjaman, c.nama, d.nm_barang FROM tbl_pinjaman_h a 
				JOIN jns_pinjaman b ON b.id = a.jenis_pinjaman
				JOIN tbl_anggota c ON c.id = a.anggota_id
				JOIN tbl_barang d ON d.id = a.barang_id
				WHERE b.transaksi_toko = 'Y'";

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];

			$sql .=" and DATE(a.tgl_pinjam) >= '".$tgl_dari."' and DATE(a.tgl_pinjam) <= '".$tgl_samp."'";
		} 

		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
}