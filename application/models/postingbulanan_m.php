<?php if (!defined('BASEPATH')) exit('No direct script access allowed');

class Postingbulanan_m extends CI_Model {

	function posting() {	
    $tgl_arr = "";
    $thn= "";
    $bln= "";
    $vid= "";
    $postby = $this->data['u_name'];
    $vresult = FALSE;
    if($_REQUEST['periode'] != "") {
			$tgl_arr = explode('-', $_REQUEST['periode']);
			$thn = $tgl_arr[0];
			$bln = $tgl_arr[1];
    } else {
      return $this->session->set_flashdata('error', 'Mohon bulan dan tahun posting di isi');
    }
        
    $fixed_asset = $this->get_data_fixed_asset();
    $sewa_kantor = $this->get_data_sewa_kantor();
    if(isset($fixed_asset) && isset($sewa_kantor)){
      //journal fixed asset
      $this->db->trans_start();
      foreach($fixed_asset as $row){
        $sql = "CALL JournalPostingBulanan(". $row->kode_asset_id.",'".$postby."',".$bln.",".$thn.")";
        $this->db->query($sql);
      }
        
      //journal sewa kantor
      foreach($sewa_kantor as $row){
        $sql = "CALL JournalByrDiMuka(". $row->id.",'".$postby."',".$bln.",".$thn.")";
        $this->db->query($sql);
      }
      $this->db->trans_complete();
      $vresult = true;
    } else {
      $this->session->set_flashdata('error', 'Master data empty');
      $vresult = false;
    }
    return $vresult;
  }

  function get_data_fixed_asset() {
    $this->db->select('*');
    $this->db->from('fixed_asset');
    $query = $this->db->get();
    if($query->num_rows()>0){
      $out = $query->result();
      return $out;
    } else {
      return FALSE;
    }
  }

  function get_data_sewa_kantor() {
    $this->db->select('*');
    $this->db->from('sewa_kantor');
    $query = $this->db->get();
    if($query->num_rows()>0){
      $out = $query->result();
      return $out;
    } else {
      return FALSE;
    }
  }
}