<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_fixedasset_m extends CI_Model {
	public function __construct() {
		parent::__construct();
	}

	function get_data($q='') {
    $periode = isset($_GET['periode'])?$_GET['periode'].'-01':date('Y-m-d');
    $bln = date('m',strtotime($periode));
    $thn = date('Y',strtotime($periode));
		$kode_asset = isset($_GET['kode_asset']) ? $_GET['kode_asset'] : '';
		$nama_asset = isset($_GET['nama_asset']) ? $_GET['nama_asset'] : '';
		$kat_asset = isset($_GET['kat_asset']) ? $_GET['kat_asset'] : '';
		$sql = "SELECT * 
    FROM fixed_asset_history
    where periodmonth = ".$bln." and periodyear = ".$thn." ";
		$q = array('kode_asset' => $kode_asset, 'nama_asset' => $nama_asset, 'kategori_asset' => $kat_asset);
		if (is_array($q)){
			if($q['kode_asset'] != '') {
				$sql .=" and kode_asset like '%".$q['kode_asset']."%'";
			}
			if($q['nama_asset'] != '') {
				$sql .=" and nama_asset like '%".$q['nama_asset']."%'";
			}
			if($q['kategori_asset'] != '') {
				$sql .=" and kategori_asset like '%".$q['kategori_asset']."%'";
			}
		}	
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
  }
  
  function get_jml_data() {
		return $this->db->count_all_results('fixed_asset_history');
	}

	function get_data_kasset_ajax($q) {
		$sql = "SELECT * FROM kategori_asset ";
		if($q !='') {
			$sql .=" WHERE kategori_asset like '%$q%' ";
		}
		$result['count'] = $this->db->query($sql)->num_rows();
		$sql .=" LIMIT 50 ";
		$result['data'] = $this->db->query($sql)->result();
		return $result;
	}
}