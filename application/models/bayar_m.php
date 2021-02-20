<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Bayar_m extends CI_Model {
	public function __construct() {
		parent::__construct();
	}

	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT * 
				FROM
				(SELECT v_hitung_pinjaman.* , tbl_anggota.jns_anggotaid, (`tgl_pinjam` + INTERVAL (TIMESTAMPDIFF(MONTH, tgl_pinjam, NOW())) MONTH) AS tgl_tempo_asis
				FROM v_hitung_pinjaman
				JOIN tbl_anggota ON tbl_anggota.id = v_hitung_pinjaman.anggota_id ) as vtbl_hitung_pinjaman";
		$where = " WHERE lunas='Belum'  ";
		if(is_array($q)) {
			if($q['kode_transaksi'] != '') {
				$q['kode_transaksi'] = $q['kode_transaksi'] * 1;
				$where .=" AND (nomor_pinjaman LIKE '%".$q['kode_transaksi']."%') ";
			} else {
				if($q['cari_nama'] != '') {
					$where .=" AND nama LIKE '%".$q['cari_nama']."%' ";
				}
				if($q['cari_anggota'] != '') {
					$where .=" AND jns_anggotaid = '".$q['cari_anggota']."' ";
				}
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$where .=" AND DATE(tgl_tempo_asis) >= '".$q['tgl_dari']."' ";
					$where .=" AND DATE(tgl_tempo_asis) <= '".$q['tgl_sampai']."' ";
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
	
	// Added by Gani
	public function import_db($data) {
		if(is_array($data)) {

			$this->db->trans_start();

			$pair_arr = array();
			$id_pinjam = 0;
			$jumlah_bayar = 0;
			$inspinjam = true;
			foreach ($data as $rows) {

				//$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { 
						if ($val != "") {
								$row_pinjam = $this->get_data_by_nomor_pinjam($val);
								if (isset($row_pinjam->id)) {
									$pair['pinjam_id'] = $row_pinjam->id;
									$id_pinjam = $row_pinjam->id;
									$inspinjam = true;
								} else {
									$inspinjam = false;
								}
						} else {
							return false;
						}
					}
					if($inspinjam === true) {
							if($key == 'B') { 
								if ($val != "") {
									$valb = date('H:i');
									$val = $val.' '.$valb;
									$pair['tgl_bayar'] = $val; 
								} else {
									return false;
								}
							}
							$ags_ke = $this->general_m->get_record_bayar($id_pinjam) + 1;
							$pair['angsuran_ke'] = $ags_ke; 
							if($key == 'C') { 
								if ($val != "") {
									$pair['jumlah_bayar'] = $val; 
									$jumlah_bayar = $val;
								} else {
									return false;
								}
							}
							if($key == 'D') { $pair['denda_rp'] = $val; }
							if($key == 'E') { $pair['terlambat'] = $val; }
							if($key == 'F') { $pair['keterangan'] = $val; }
					}
				}

				if($inspinjam === true) {
						$pair['ket_bayar'] = 'Angsuran';
						$pair['dk'] = 'D';
						$pair['kas_id'] = 1;
						$pair['jns_trans'] = 48;
						$pair['user_name'] = $this->data['u_name'];

						$this->db->insert('tbl_pinjaman_d', $pair);

						$s_wajib = $this->angsuran_m->get_simpanan_wajib();
						$data_pinjam = $this->general_m->get_data_pinjam ($id_pinjam);
						$tagihan = ($data_pinjam->ags_per_bulan + $s_wajib->jumlah) * $data_pinjam->lama_angsuran;
						$hitung_dibayar = $this->general_m->get_jml_bayar($id_pinjam);
						$dibayar = $hitung_dibayar->total;
						$hitung_denda = $this->general_m->get_jml_denda($id_pinjam);
						$jml_denda = $hitung_denda->total_denda;
						$sisa_bayar = $tagihan - $dibayar;
						$total_bayar = $sisa_bayar + $jml_denda;
						//var_dump($jumlah_bayar,' ',$dibayar, ' ',$tagihan);die();
						if($sisa_bayar == 0) {
							$status = 'Lunas';
							$data = array('lunas' => $status);
						} else {
							$status = 'Belum';
								if($jumlah_bayar == $total_bayar) {
									$status = 'Lunas';
								} else {
									$status = 'Belum';
								}
								$data = array('lunas' => $status);
						}
						
						$this->db->where('id', $id_pinjam);
						$this->db->update('tbl_pinjaman_h', $data);
				}
				
			}

			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				// error insert
				return FALSE;
			} else {
				$this->db->trans_complete();
				return TRUE;
			}
		} else {
			return FALSE;
		}
	}
	
	function get_data_excel() {
		$sql = "SELECT  a.*, b.nama, b.identitas FROM v_hitung_pinjaman a
				JOIN tbl_anggota b ON b.id = a.anggota_id
				WHERE lunas='Belum' ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	//ambil data pinjaman header berdasarkan nomor pinjaman
	function get_data_by_nomor_pinjam($nomorpinjam) {
		$this->db->select('*');
		$this->db->from('tbl_pinjaman_h');
		$this->db->where('nomor_pinjaman',$nomorpinjam);
		$query = $this->db->get();
		if($query->num_rows() > 0){
			$out = $query->row();
			return $out;
		} else {
			return FALSE;
		}
	}
}

