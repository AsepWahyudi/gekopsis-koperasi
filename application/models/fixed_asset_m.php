<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class fixed_asset_m extends CI_Model {

	public function __construct(){
		parent::__construct();
	}
	
	//Added
	public function import_db($data) {
		if(is_array($data)) {

			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['journal_no'] = $val; }
					if($key == 'B') { $pair['journal_date'] = $val; }
					if($key == 'C') { $pair['jns_transaksi'] = $val; }
					if($key == 'D') { $pair['headernote'] = $val; }
				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('fixed_asset', $pair_arr);
		} else {
			return FALSE;
		}
	}

	public function import_fixed_asset($data) {
		if(is_array($data)) {
			$pair_arr = array();
			foreach ($data as $rows) {
				$pair = array();
				foreach ($rows as $key => $val) {
					if($key == 'A') { $pair['kode_asset'] = $val; }
					if($key == 'B') { $pair['nama_asset'] = $val; }
					if($key == 'C') { $pair['lokasi_asset'] = $val; }
					if($key == 'D') { 
							$this->db->select('*');
							$this->db->from('kategori_asset');
							$this->db->where('kategori_asset', $val);
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pair['kategori_asset'] = $query->row()->kategori_asset_id;
							} else {
								$pair['kategori_asset'] = "0";
							}
					}
					if($key == 'E') { $pair['status'] = $val; }
					if($key == 'F') { $pair['tanggal_efektif'] = $val; }
					if($key == 'G') { $pair['harga_perolehan'] = $val; }
					if($key == 'H') { $pair['akumulasi_penyusutan'] = $val; }
					if($key == 'I') { $pair['nilai_buku'] = $val; }
					if($key == 'J') { $pair['depresia'] = $val; }
					if($key == 'K') { $pair['usia_fiskal'] = $val; }
					if($key == 'L') { 
							$this->db->select('*');
							$this->db->from('tbl_barang');
							$this->db->where('nm_barang', $val);
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pair['barang_id'] = $query->row()->id;
							} else {
								$pair['barang_id'] = "0";
							}
					}
					if($key == 'M') { 
						$this->db->select('*');
						$this->db->from('jns_cabang');
						$this->db->where('nama_cabang', $val);
						$query = $this->db->get();
						if ($query->num_rows() > 0) {
							$pair['jns_cabangid'] = $query->row()->jns_cabangid;
						} else {
							$pair['jns_cabangid'] = NULL;
						}
				}


				}
				$pair_arr[] = $pair;
			}
			return $this->db->insert_batch('fixed_asset', $pair_arr);
		} else {
			return FALSE;
		}
		
		/*
		if(is_array($data)) {
	
				$arrHeader = array();
				$pairHeader = array();
				foreach ($data as $rows) {
					$pair = array();
					foreach ($rows as $key => $val) {
						if($key == 'A') { $pair['journal_no'] = $val; }
						if($key == 'B') { $pair['journal_date'] = $val; }
						if($key == 'C') { $pair['jns_transaksi'] = $val; }
						if($key == 'D') { $pair['headernote'] = $val; }
					}
					$pairHeader[] = $pair;
				}

				$pairHeader = array_map("unserialize", array_unique(array_map("serialize", $pairHeader)));
				foreach ($pairHeader as $rows) {
					foreach ($rows as $key => $val) {
						if($key == 'journal_no') {
							$this->db->select('journal_voucherid');
							$this->db->from('journal_voucher');
							$this->db->where('journal_no', $val);
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pair['journal_voucherid'] = $query->row()->journal_voucherid;
							}
							$pair['journal_no'] = $val;
						}
						if($key == 'journal_date') { $pair['journal_date'] = $val; }
						if($key == 'jns_transaksi') { $pair['jns_transaksi'] = $val; }
						if($key == 'headernote') { $pair['headernote'] = $val; }
						
						$result = $this->db->replace('journal_voucher', $pair);
						if ($result === TRUE) {
							$vresult = TRUE;
						} else {
							return FALSE;
						}
					}
				}
					
				
				//detail
				
				$pair_arr = array();
				$dtlvoucherid="";
				$dtljnsakunid = "";
				$dtldebit = "";
				$dtlcredit = "";
				$dtlcabangid = "";
				$dtlitemnote = "";
				$dtlvoucherdetid = "";
				foreach ($data as $rows) {
					//$pair = array();
					foreach ($rows as $key => $val) {
						if($key == 'A') { 
							$this->db->select('journal_voucherid');
							$this->db->from('journal_voucher');
							$this->db->where('journal_no', $val);
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pairdtl['journal_voucher_id'] = $query->row()->journal_voucherid;
								$dtlvoucherid = $query->row()->journal_voucherid;
							} else {
								$pairdtl['journal_voucher_id'] = "";
								$dtlvoucherid = "";
							}
							$journalno = $val;
						}
						if($key == 'E') { 
							$this->db->select('jns_akun_id');
							$this->db->from('jns_akun');
							$this->db->where('no_akun', $val);
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pairdtl['jns_akun_id']  = $query->row()->jns_akun_id;
								$dtljnsakunid =  $query->row()->jns_akun_id;
							} else {
								$pairdtl['jns_akun_id'] = "0";
								$dtljnsakunid = "0";
							}	
						}
						if($key == 'G') { $pairdtl['debit'] = $val; $dtldebit = $val; }
						if($key == 'H') { $pairdtl['credit'] = $val; $dtlcredit = $val; }
						
						if($key == 'I') { 
							$this->db->select('*');
							$this->db->from('jns_cabang');
							$this->db->where('kode_cabang', $val);
							$query = $this->db->get();
							if($query->num_rows()>0){
								$pairdtl['jns_cabangid'] = $query->row()->jns_cabangid; 
								$dtlcabangid = $query->row()->jns_cabangid;
							} else {
								$pairdtl['jns_cabangid'] = "0";
								$dtlcabangid = "0";
							}
						}
						
						if($key == 'J') { $pairdtl['itemnote'] = $val; $dtlitemnote = $val; }
							$this->db->select('journal_voucher_detid');
							$this->db->from('journal_voucher_det');
							$this->db->where('journal_voucher_id', $dtlvoucherid);
							$this->db->where('jns_akun_id', $dtljnsakunid);
							$this->db->where('debit', $dtldebit);
							$this->db->where('credit', $dtlcredit);
							$this->db->where('jns_cabangid',$dtlcabangid);
							$this->db->where('itemnote', $dtlitemnote);
							$query = $this->db->get();
							if($query->num_rows()>0){
								$dtlvoucherdetid =  $query->row()->journal_voucher_detid;
							} else {
								$dtlvoucherdetid = "";
							}
							
					}
					
					if (isset($dtlvoucherdetid)) {
						$pairdtl['journal_voucher_detid'] = $dtlvoucherdetid;
						$result = $this->db->replace('journal_voucher_det', $pairdtl);
					} else {
						$result = $this->db->insert('journal_voucher_det', $pairdtl);
					}

					if ($result === TRUE) {
						$vresult = TRUE;
					} else {
						return FALSE;
					}
				}
				
			return $vresult;
			
		} else {
			return FALSE;
		}
		*/
	}

	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT *
			FROM fixed_asset
			";
		if(is_array($q)) {
			$sql .= " WHERE kode_asset like '%%' ";
			$sql .= " AND nama_asset like '%%' ";
			
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		//$sql .=" ORDER BY {$sort} {$order} ";
		//$sql .=" LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
}