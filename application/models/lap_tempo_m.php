<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_tempo_m extends CI_Model {
	public function __construct() {
		parent::__construct();
	}

		//panggil data simpanan
	function get_data_tempo($limit, $start) {
		/*$sql = "SELECT * FROM (
			SELECT v_hitung_pinjaman.jenis_pinjaman as jenis_pinjaman,bunga,biaya_adm,plafond_pinjaman,
			  v_hitung_pinjaman.id AS id,v_hitung_pinjaman.tempo AS tempo,v_hitung_pinjaman.tgl_pinjam AS tgl_pinjam, v_hitung_pinjaman.ags_per_bulan as ags_per_bulan,v_hitung_pinjaman.tagihan AS tagihan, v_hitung_pinjaman.lama_angsuran AS lama_angsuran, 
        v_hitung_pinjaman.pokok_angsuran AS pokok_angsuran, TIMESTAMPDIFF(MONTH, v_hitung_pinjaman.tgl_pinjam, NOW())  as selisih_bulan,v_hitung_pinjaman.bln_sudah_angsur as bln_sudah_angsur,v_hitung_pinjaman.bunga_pinjaman AS bunga_pinjaman, v_hitung_pinjaman.biaya_adm AS adm, v_hitung_pinjaman.nomor_pinjaman AS nomor_pinjaman,
        tbl_anggota.ktp AS ktp, tbl_anggota.nomor_rekening AS rekening, tbl_anggota.nama AS nama,(`tgl_pinjam` + INTERVAL (TIMESTAMPDIFF(MONTH, tgl_pinjam, NOW())) MONTH) AS tgl_tempo_asis, tbl_anggota.jns_anggotaid as jns_anggotaid, tbl_anggota.id as anggotaid, lunas,
        v_hitung_pinjaman.tenor
        from v_hitung_pinjaman
        LEFT JOIN tbl_anggota on tbl_anggota.id = v_hitung_pinjaman.anggota_id
        Left JOIN  tbl_pinjaman_d on tbl_pinjaman_d.pinjam_id = v_hitung_pinjaman.id
        ) z ";*/
    
    $sql = "
      select b.id as anggota_id,a.nomor_pinjaman,b.nama,b.ktp,b.nomor_rekening as rekening,a.id, a.jenis_pinjaman,c.periode, a.lama_angsuran, date(a.tgl_pinjam) as tgl_pinjam,d.tenor,
      (a.tgl_pinjam + interval lama_angsuran month) AS tempo,c.angsuranpokok as pokok_angsuran, c.angsuranbunga as bunga_pinjaman,
      case when jenis_pinjaman = 9 then c.angsuranpokok + c.angsuranbunga + c.adminangsuran else c.jumlahangsuran end as `ags_per_bulan`, TIMESTAMPDIFF(MONTH, a.tgl_pinjam, NOW())  as selisih_bulan,
      (select IFNULL(MAX(z.`angsuran_ke`),0) from tbl_pinjaman_d z where z.pinjam_id = a.id) AS bln_sudah_angsur,a.plafond_pinjaman,a.biaya_adm,
      c.adminangsuran
      from tbl_pinjaman_h a
      left join tbl_anggota b on b.id = a.anggota_id
      left join tbl_pinjaman_simulasi c on c.tbl_pinjam_hid = a.id 
      left join jns_pinjaman d on d.id = a.jenis_pinjaman  
    ";
    $where = " WHERE lunas='Belum' ";
    $periode = isset($_GET['periode'])?$_GET['periode'].'-01':date('Y-m-d');
    $where .= " AND YEAR(periode) = year('".$periode."') AND  MONTH(periode) = month('".$periode."') ";
		/*if(isset($_GET['periode']) && $_GET['periode']) {
			$tgl_arr = explode('-', $_GET['periode']);
			$thn = $tgl_arr[0];
			$bln = $tgl_arr[1];
    }*/
		if(isset($_GET['jenis_anggota_id']) && $_GET['jenis_anggota_id'] != "") {
			$where .= " AND jns_anggotaid = '".$_GET['jenis_anggota_id']."'";
		}
		if(isset($_GET['anggota_id']) && $_GET['anggota_id']) {
			$where .= " AND anggotaid = '".$_GET['anggota_id']."'";
		}
		$sql .= $where;
		$sql .=" ORDER BY tempo ASC ";
    $sql .=" LIMIT {$start},{$limit} ";
		$query = $this->db->query($sql);
		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_jml_data_tempo() {
		$this->db->where('lunas', 'Belum');
		return $this->db->count_all_results('v_hitung_pinjaman');
	}

	//panggil data jenis simpan untuk laporan
	function lap_data_tempo() {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');

		if(isset($_GET['periode']) && $_GET['periode']) {
			$tgl_arr = explode('-', $_GET['periode']);
			$thn = $tgl_arr[0];
			$bln = $tgl_arr[1];
			$where = "YEAR(tempo) = '".$thn."' AND  MONTH(tempo) = '".$bln."' ";
			$this->db->where($where);
		} 

		$this->db->where('lunas','Belum');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function cetak_data_tempo() {
    $sql = "
    select b.id as anggota_id,a.nomor_pinjaman,b.nama,b.ktp,b.nomor_rekening as rekening,a.id, a.jenis_pinjaman,c.periode, a.lama_angsuran, date(a.tgl_pinjam) as tgl_pinjam,d.tenor,
    (a.tgl_pinjam + interval lama_angsuran month) AS tempo,c.angsuranpokok as pokok_angsuran, c.angsuranbunga as bunga_pinjaman,
    case when jenis_pinjaman = 9 then c.angsuranpokok + c.angsuranbunga + c.adminangsuran else c.jumlahangsuran end as `ags_per_bulan`, TIMESTAMPDIFF(MONTH, a.tgl_pinjam, NOW())  as selisih_bulan,
    (select IFNULL(MAX(z.`angsuran_ke`),0) from tbl_pinjaman_d z where z.pinjam_id = a.id) AS bln_sudah_angsur,a.plafond_pinjaman,a.biaya_adm,
    c.adminangsuran
    from tbl_pinjaman_h a
    left join tbl_anggota b on b.id = a.anggota_id
    left join tbl_pinjaman_simulasi c on c.tbl_pinjam_hid = a.id 
    left join jns_pinjaman d on d.id = a.jenis_pinjaman  
    ";
    $where = " WHERE lunas='Belum' ";
    $periode = ($_GET['periode'] != '')?$_GET['periode'].'-01':date('Y-m-d');
    $where .= " AND YEAR(periode) = year('".$periode."') AND  MONTH(periode) = month('".$periode."') ";
    if(isset($_GET['jenis_anggota_id']) && $_GET['jenis_anggota_id'] != "") {
			$where .= " AND jns_anggotaid = '".$_GET['jenis_anggota_id']."'";
		}
		if(isset($_GET['anggota_id']) && $_GET['anggota_id']) {
			$where .= " AND anggotaid = '".$_GET['anggota_id']."'";
		}
    $sql .= $where;
		$sql .=" ORDER BY tempo ASC ";
		$query = $this->db->query($sql);
		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function excel_data_tempo() {
		$sql = "
    select b.id as anggota_id,a.nomor_pinjaman,b.nama,b.ktp,b.nomor_rekening as rekening,a.id, a.jenis_pinjaman,c.periode, a.lama_angsuran, date(a.tgl_pinjam) as tgl_pinjam,d.tenor,
    (a.tgl_pinjam + interval lama_angsuran month) AS tempo,c.angsuranpokok as pokok_angsuran, c.angsuranbunga as bunga_pinjaman,
    case when jenis_pinjaman = 9 then c.angsuranpokok + c.angsuranbunga + c.adminangsuran else c.jumlahangsuran end as `ags_per_bulan`, TIMESTAMPDIFF(MONTH, a.tgl_pinjam, NOW())  as selisih_bulan,
    (select IFNULL(MAX(z.`angsuran_ke`),0) from tbl_pinjaman_d z where z.pinjam_id = a.id) AS bln_sudah_angsur,a.plafond_pinjaman,a.biaya_adm,
    c.adminangsuran
    from tbl_pinjaman_h a
    left join tbl_anggota b on b.id = a.anggota_id
    left join tbl_pinjaman_simulasi c on c.tbl_pinjam_hid = a.id 
    left join jns_pinjaman d on d.id = a.jenis_pinjaman  
    ";
    $where = " WHERE lunas='Belum' ";
    $periode = ($_GET['periode'] != '')?$_GET['periode'].'-01':date('Y-m-d');
    $where .= " AND YEAR(periode) = year('".$periode."') AND  MONTH(periode) = month('".$periode."') ";
    if(isset($_GET['jenis_anggota_id']) && $_GET['jenis_anggota_id'] != "") {
			$where .= " AND jns_anggotaid = '".$_GET['jenis_anggota_id']."'";
		}
		if(isset($_GET['anggota_id']) && $_GET['anggota_id']) {
			$where .= " AND anggotaid = '".$_GET['anggota_id']."'";
		}
		$sql .= $where;
    $sql .=" ORDER BY tempo ASC ";
		$query = $this->db->query($sql);
		if($query->num_rows()>0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}
}