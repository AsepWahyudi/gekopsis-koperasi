<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_buku_besar extends OperatorController {
	public function __construct() {
		parent::__construct();
		$this->load->helper('fungsi');
		$this->load->model('lap_buku_besar_m');
		$this->load->model('general_m');
	}	

	public function index() {
		error_reporting(0);
		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Buku Besar';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

		#include daterange
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		//number_format
		$this->data['js_files'][] = base_url() . 'assets/extra/fungsi/number_format.js';

		//$this->data["nama_kas"] = $this->lap_buku_besar_m->get_nama_kas(); 
		$this->data["jenis_akun"] = $this->lap_buku_besar_m->get_nama_akun(); 
		
		$this->data['isi'] = $this->load->view('lap_buku_besar_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function cetak() {
    	$jenis_akun = $this->lap_buku_besar_m->get_nama_akun(); 

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;

		
		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('L');
		$html = '<style>
					.h_tengah {text-align: center;}
					.h_kiri {text-align: left;}
					.h_kanan {text-align: right;}
					.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
					.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
				</style>
				'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Buku Besar Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
		$no = 1;
		$total_saldo = 0;
		$saldo = 0;
		$jmlD = 0;
		$jmlk = 0;
		foreach ($jenis_akun as $data=> $key) {
      		$transJ = $this->lap_buku_besar_m->get_data_journal_id($key->jns_akun_id);

			$html.= '<h3>'.$key->no_akun.' '.$key->nama_akun.'</h3>';
			$html.= '<table  width="90%" cellspacing="0" cellpadding="3" border="1" nobr="true">
			<tr class="header_kolom">
				<th class="h_tengah" style="width:5%;"> No</th>
				<th class="h_tengah" style="width:10%;"> No Jurnal</th>
				<th class="h_tengah" style="width:10%;"> Tanggal </th>
				<th class="h_tengah" style="width:20%;"> Keterangan </th>
				<th class="h_tengah" style="width:20%;"> Cabang </th>
				<th class="h_tengah" style="width:15%;"> Debet </th>
				<th class="h_tengah" style="width:15%;"> Kredit </th>
				<th class="h_tengah" style="width:15%;"> Saldo </th>
			</tr>';
			$no = 1;
			$namaakun = "";
			$keterangan ="";
			$nomorakun ="";
			$saldo = 0;
			//$jmlD = $jmlD;
			//$jmlk = $jmlk;
			$jmlD = 0;
			$jmlK = 0;
				foreach ($transJ as $dataJ=> $rows) {
						$tglD = explode(' ', $rows->journal_date);
						$txt_tanggalD = jin_date_ina($tglD[0],'p');

						if($key->no_akun !=""){
						$nomorakun = $key->no_akun;
						} else {
						$nomorakun = "-";
						}

						if($key->nama_akun !=""){
						$namaakun = $key->nama_akun;
						} else {
						$namaakun = "-";
						}

						if($rows->itemnote != ""){
						$keterangan = $rows->itemnote;
						} else {
						$keterangan = "-";
						}

						if($rows->credit != 0) {
						$jmlK += $rows->credit;
						$rows->debit = 0;
						}
						if($rows->debit != 0) {
						$jmlD += $rows->debit;
						$rows->credit = 0;
						}
						$saldo = $jmlD - $jmlK;

						$html.= '<tr>
							<td class="h_tengah"> '.$no++.' </td>
							<td> '.$rows->journal_no.'</td>
							<td class="h_tengah"> '.$txt_tanggalD.' </td>
							<td> '.$keterangan.'</td>
							<td> '.$rows->kode_cabang.'</td>
							<td class="h_kanan"> '.number_format(nsi_round($rows->debit),2,',','.').' </td>
							<td class="h_kanan"> '.number_format(nsi_round($rows->credit),2,',','.').' </td>';
							if ($rows->debit != 0) {
								$html .= '<td class="h_kanan">'.number_format(nsi_round($rows->debit),2,',','.').'</td>';
						    } else if ( $rows->credit != 0) { 
								$html .= '<td class="h_kanan">'.number_format(nsi_round($rows->credit),2,',','.').'</td>';
						    } else {	
								$html .= '<td class="h_kanan">'.number_format(nsi_round(0),2,',','.').'</td>';
						    } 
						$html .= '</tr>';
				}
			$html.= '<tr>
							<td class="h_tengah"></td>
							<td></td>
							<td class="h_tengah"> </td>
							<td colspan="4">TOTAL SALDO '.$key->no_akun . ' ' .$key->nama_akun.'</td>
							<td class="h_kanan"> '.number_format(nsi_round($saldo),2,',','.').' </td>
						</tr>';
			$html.= '</table>';
			$saldo = 0;
  		}

		$pdf->nsi_html($html);
		$pdf->Output('lap_buku_besar'.date('Ymd_His') . '.pdf', 'I');
	}

	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$jenis_akun = $this->lap_buku_besar_m->get_nama_akun(); 

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			$tgl_dari = $_REQUEST['tgl_dari'];
			$tgl_samp = $_REQUEST['tgl_samp'];
		} else {
			$tgl_dari = date('Y') . '-01-01';
			$tgl_samp = date('Y') . '-12-31';
		}
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;

		$html = '<style>
					.h_tengah {text-align: center;}
					.h_kiri {text-align: left;}
					.h_kanan {text-align: right;}
					.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
					.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
				</style>
				<span class="txt_judul">Laporan Buku Besar Periode '.$tgl_periode_txt.'</span>';
		$no = 1;
		$total_saldo = 0;
		$saldo = 0;
		$jmlD = 0;
		$jmlk = 0;
		foreach ($jenis_akun as $data=> $key) {
			$transJ = $this->lap_buku_besar_m->get_data_journal_id($key->jns_akun_id);

		  $html.= '<h3>'.$key->no_akun.' '.$key->nama_akun.'</h3>';
		  $html.= '<table  width="90%" cellspacing="0" cellpadding="3" border="1" nobr="true">
		  <tr class="header_kolom">
			  <th class="h_tengah" style="width:5%;"> No</th>
			  <th class="h_tengah" style="width:10%;"> No Jurnal</th>
			  <th class="h_tengah" style="width:10%;"> Tanggal </th>
			  <th class="h_tengah" style="width:20%;"> Keterangan </th>
			  <th class="h_tengah" style="width:20%;"> Cabang </th>
			  <th class="h_tengah" style="width:15%;"> Debet </th>
			  <th class="h_tengah" style="width:15%;"> Kredit </th>
			  <th class="h_tengah" style="width:15%;"> Saldo </th>
		  </tr>';
		  $no = 1;
		  $namaakun = "";
		  $keterangan ="";
		  $nomorakun ="";
		  $jmlD = 0;
		  $jmlK = 0;
			  foreach ($transJ as $dataJ=> $rows) {
					  $tglD = explode(' ', $rows->journal_date);
					  $txt_tanggalD = jin_date_ina($tglD[0],'p');

					  if($key->no_akun !=""){
					  $nomorakun = $key->no_akun;
					  } else {
					  $nomorakun = "-";
					  }

					  if($key->nama_akun !=""){
					  $namaakun = $key->nama_akun;
					  } else {
					  $namaakun = "-";
					  }

					  if($rows->itemnote != ""){
					  $keterangan = $rows->itemnote;
					  } else {
					  $keterangan = "-";
					  }

					  if($rows->credit != 0) {
					  $jmlK += $rows->credit;
					  $rows->debit = 0;
					  }
					  if($rows->debit != 0) {
					  $jmlD += $rows->debit;
					  $rows->credit = 0;
					  }
					  $saldo = $jmlD - $jmlK;

					  $html.= '<tr>
						  <td class="h_tengah"> '.$no++.' </td>
						  <td> '.$rows->journal_no.'</td>
						  <td class="h_tengah"> '.$txt_tanggalD.' </td>
						  <td> '.$keterangan.'</td>
						  <td> '.$rows->kode_cabang.'</td>
						  <td class="h_kanan"> '.number_format(nsi_round($rows->debit),2,',','.').' </td>
						  <td class="h_kanan"> '.number_format(nsi_round($rows->credit),2,',','.').' </td>';
						  if ($rows->debit != 0) {
							$html .= '<td class="h_kanan">'.number_format(nsi_round($rows->debit),2,',','.').'</td>';
						} else if ( $rows->credit != 0) { 
							$html .= '<td class="h_kanan">'.number_format(nsi_round($rows->credit),2,',','.').'</td>';
						} else {	
							$html .= '<td class="h_kanan">'.number_format(nsi_round(0),2,',','.').'</td>';
						} 
					$html .= '</tr>';
			  }
		  $html.= '<tr>
						  <td class="h_tengah"></td>
						  <td></td>
						  <td class="h_tengah"> </td>
						  <td colspan="4">TOTAL SALDO '.$key->no_akun . ' ' .$key->nama_akun.'</td>
						  <td class="h_kanan"> '.number_format(nsi_round($saldo ),2,',','.').' </td>
					  </tr>';
		  $html.= '</table>';
		}
		
		echo $html;
		die();

	}
}