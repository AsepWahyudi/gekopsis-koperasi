<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Pelunasan_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}

	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT v_hitung_pinjaman.* , tbl_anggota.category
				FROM v_hitung_pinjaman
				JOIN tbl_anggota ON tbl_anggota.id = v_hitung_pinjaman.anggota_id";
		$where = " WHERE lunas='Lunas'  ";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = $q['kode_transaksi'];
				$where .=" AND (v_hitung_pinjaman.nomor_pinjaman LIKE '".$q['kode_transaksi']."'";
			} else {
				if($q['cari_nama'] != '') {
					$where .=" AND tbl_anggota.nama LIKE '%".$q['cari_nama']."%' ";
					// $sql .= " LEFT JOIN tbl_anggota ON (v_hitung_pinjaman.anggota_id = tbl_anggota.id) ";
				}
				if($q['cari_anggota'] != '') {
					$where .=" AND tbl_anggota.jns_anggotaid = '".$q['cari_anggota']."' ";
				}				
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$where .=" AND DATE(tgl_pinjam) >= '".$q['tgl_dari']."' ";
					$where .=" AND DATE(tgl_pinjam) <= '".$q['tgl_sampai']."' ";
				}
			}
		}
		$sql .= $where;
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY {$sort} {$order} ";
		$sql .=" LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
}