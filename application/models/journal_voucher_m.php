<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class journal_voucher_m extends CI_Model {

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
			return $this->db->insert_batch('journal_voucher', $pair_arr);
		} else {
			return FALSE;
		}
	}

	public function import_journal_db($data) {
		if(is_array($data)) {
			
				$this->db->trans_start();
				$arrHeader = array();
				$pairHeader = array();
				$jvoucherid = "";
				$journalno = "";
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
								$jvoucherid = $query->row()->journal_voucherid;
                $this->db->delete('journal_voucher_det',array('journal_voucher_id'=>$jvoucherid));
							}
							$pair['journal_no'] = $val;
							$journalno = $val;
						}
						if($key == 'journal_date') { $pair['journal_date'] = $val; }
						if($key == 'jns_transaksi') { $pair['jns_transaksi'] = $val; }
						if($key == 'headernote') { $pair['headernote'] = $val; }
						
						$result = $this->db->replace('journal_voucher', $pair);

					}
				}
					
				
        //detail
				$pair_arr = array();
				$dtlvoucherid=0;
				$dtljnsakunid = 0;
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
							$this->db->where('journal_no', trim($val));
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pairdtl['journal_voucher_id'] = $query->row()->journal_voucherid;
								$dtlvoucherid = $query->row()->journal_voucherid;
							} else {
								$pairdtl['journal_voucher_id'] = "0";
								$dtlvoucherid = "0";
							}
							$journalno = $val;
						}
						if($key == 'E') { 
							$this->db->select('jns_akun_id');
							$this->db->from('jns_akun');
							$this->db->where('no_akun', trim($val));
							$query = $this->db->get();
							if ($query->num_rows() > 0) {
								$pairdtl['jns_akun_id']  = $query->row()->jns_akun_id;
								$dtljnsakunid =  $query->row()->jns_akun_id;
							} else {
								$dtljnsakunid = "0";
							}	
						}

						if ( $dtljnsakunid == "0"){
							if($key == 'F') {
								$this->db->select('jns_akun_id');
								$this->db->from('jns_akun');
								$this->db->where('nama_akun', $val);
								$query = $this->db->get();
								if ($query->num_rows() > 0) {
									$pairdtl['jns_akun_id']  = $query->row()->jns_akun_id;
									$dtljnsakunid = $query->row()->jns_akun_id;
								} else {
									$pairdtl['jns_akun_id'] = "0";
									$dtljnsakunid = "0";
								}
							}
						}

						if($key == 'G') { $pairdtl['debit'] = $val; $dtldebit = $val; }
						if($key == 'H') { $pairdtl['credit'] = $val; $dtlcredit = $val; }
						
						if($key == 'I') { 
							$this->db->select('*');
							$this->db->from('jns_cabang');
							$this->db->where('kode_cabang', trim($val));
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
						
						$this->db->select('*');
						$this->db->from('journal_voucher_det');
						$this->db->where('journal_voucher_id', $dtlvoucherid);
						$this->db->where('jns_akun_id', $dtljnsakunid);
						//$this->db->where('credit', $dtlcredit);
						//$this->db->where('debit', $dtldebit);
						//$query = $this->db->get();
            $query = $this->db->get();
            if($query->num_rows()>0) {
              $dtlvoucherdetid =  $query->row()->journal_voucher_detid;
            } else {
              $pairdtl['journal_voucher_detid'] = $dtlvoucherdetid;
              $dtlvoucherdetid = "0";
            }
					}
          $this->db->insert('journal_voucher_det', $pairdtl);
/*
						if ($dtljnsakunid != "0") {
								if ($dtlvoucherdetid != "") {
									$pairdtl['journal_voucher_detid'] = $dtlvoucherdetid;
									$this->db->replace('journal_voucher_det', $pairdtl);
								} else {
									var_dump($pairdtl,' ',$dtlvoucherdetid);die();
								}
						} */					
				}

				$this->db->trans_complete();

				if ($this->db->trans_status() === FALSE) {
					return false;
				}
				else {
					return true;
				}

			
		} else {
			return FALSE;
		}
	}

	function get_data_transaksi_ajax($offset, $limit, $q='', $sort, $order) {
		$sql = "SELECT a.*
			FROM journal_voucher a
      ";
		if(is_array($q)) {
      $sql .= " WHERE coalesce(journal_no,'') like '%".$q['journal_no']."%' ";
			if ($q['tgl_dari'] != '') {
        $date = date_create($q['tgl_dari']);
				$sql .= " and DATE(journal_date) >= '".date_format($date,'Y-m-d')."'";
			}
			if ($q['tgl_sampai'] != '') {
        $date = date_create($q['tgl_sampai']);
				$sql .= " AND DATE(journal_date) <= '".date_format($date,'Y-m-d')."'";			
			}
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" ORDER BY {$sort} {$order} ";
    $sql .=" LIMIT {$offset},{$limit} ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}

	public function validasi($id){
		$this->db->set('validasi_status', 'X');
		$this->db->where('journal_voucherid', $id);
		return $this->db->update('journal_voucher');
	}

	function lap_data_journal() {
		$cari_journalno = isset($_GET['cari_journalno']) ? $_GET['cari_journalno'] : '';
		$tgl_dari = isset($_GET['tgl_dari']) ? $_GET['tgl_dari'] : '';
		$tgl_sampai = isset($_GET['tgl_sampai']) ? $_GET['tgl_sampai'] : '';
		$sql = '';
		$sql = " SELECT *
				FROM journal_voucher a ";
		$q = array( 
			'cari_journalno'	=> $cari_journalno,
			'tgl_dari' 		=> $tgl_dari, 
			'tgl_sampai' 	=> $tgl_sampai);
		if(is_array($q)) {
			if($q['cari_journalno'] != '') {
				$sql .="WHERE a.journal_no = ".$q['cari_journalno']." ";

				$q['tgl_dari'] = date("yy-m-d", strtotime($q['tgl_dari']));
				$q['tgl_sampai'] = date("yy-m-d", strtotime($q['tgl_sampai']));
				if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
					$sql .=" AND DATE(a.journal_date) >= '".$q['tgl_dari']."' ";
					$sql .=" AND DATE(a.journal_date) <= '".$q['tgl_sampai']."' ";
				}
			}	
			
			if($q['tgl_dari'] != '' && $q['tgl_sampai'] != '') {
				$q['tgl_dari'] = date("yy-m-d", strtotime($q['tgl_dari']));
				$q['tgl_sampai'] = date("yy-m-d", strtotime($q['tgl_sampai']));
				$sql .=" WHERE DATE(a.journal_date) >= '".$q['tgl_dari']."' ";
				$sql .=" AND DATE(a.journal_date) <= '".$q['tgl_sampai']."' ";
			}
			
		}
		$sql .=" GROUP BY a.journal_no ORDER BY a.journal_date ASC ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	function lap_detail_journal($journal_voucherid) {
		$sql = '';
		$sql = " SELECT *
				FROM journal_voucher_det a
				WHERE journal_voucher_id = ".$journal_voucherid;
		//$sql .="GROUP BY journal_no ORDER BY journal_date ASC ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	public function purge($id) {
		// TRANSACTIONAL DB START
		$this->db->trans_start();
		
		//detail
		$this->db->delete('journal_voucher_det', array('journal_voucher_id' => $id));

		//header
		$this->db->delete('journal_voucher', array('journal_voucherid' => $id));

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			return FALSE;
		} else {
			$this->db->trans_complete();
			return TRUE;
		}
		// TRANSACTIONAL DB END
	}

	function lap_jv() {
		$cari_journalno = isset($_GET['cari_journalno']) ? $_GET['cari_journalno'] : '';
		$sql = '';
		$sql = " SELECT *
				FROM journal_voucher a ";
		$q = array( 
			'cari_journalno'	=> $cari_journalno
		);
		if(is_array($q)) {
			if($q['cari_journalno'] != '') {
				$sql .="WHERE a.journal_no = '".$q['cari_journalno']."' ";
			}		
		}
		$sql .=" GROUP BY a.journal_no ORDER BY a.journal_date ASC ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}

	function lap_detail_jv($journal_voucherid) {
		$sql = '';
		$sql = " SELECT *
				FROM journal_voucher_det a
				LEFT JOIN jns_akun b ON a.jns_akun_id = b.jns_akun_id
				LEFT JOIN jns_cabang c ON a.jns_cabangid = c.jns_cabangid 
				WHERE journal_voucher_id = ".$journal_voucherid;
		//$sql .="GROUP BY journal_no ORDER BY journal_date ASC ";
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return FALSE;
		}
	}
}