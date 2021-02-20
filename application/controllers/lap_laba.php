<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_laba extends OperatorController {

public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_laba_m');
	}	

	public function index() {
		$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
		//$tgl_dari = isset($_GET['tgl_dari'])?$_GET['tgl_dari']:date('Y') . '-01-01';
		$tgl_dari = "";
		$thn_awal_dari = "";
		if (isset($_GET['tgl_dari'])){
			$tgl_dari = $_GET['tgl_dari'];
			$thn_awal_dari = date("Y",strtotime($_GET['tgl_dari']));
		} else {
			$tgl_dari = date('Y').'-01-01';
		}
		$end_tgl_dari = date("Y-m-t", strtotime($tgl_dari));
		$tgl_samp = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$first_tgl_samp = date('Y-m-01', strtotime($tgl_samp));
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$tgl_awal_dari = $thn_awal_dari.'-01-01';
		$tgl_awal_dari = jin_date_ina($tgl_awal_dari, 'p');
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$end_tgl_dari_txt = jin_date_ina($end_tgl_dari, 'p');
		$first_tgl_samp_txt = jin_date_ina($first_tgl_samp, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt .'  -  '. $tgl_samp_txt;
		$tgl_periode_txt2 = $tgl_awal_dari . ' - ' . $end_tgl_dari_txt .'   -   '. $tgl_awal_dari . ' - ' . $tgl_samp_txt;
		$tgl_periode_txt_c = $tgl_dari_txt .'  vs  '. $tgl_samp_txt;
		
		$this->load->library("pagination");

		$this->data['jenis_laporan'] = $jenis_laporan;
		$this->data['tgl_dari'] = $tgl_dari;
		$this->data['tgl_samp'] = $tgl_samp;
		$this->data['blnthn_dari'] = $blnthn_dari;
		$this->data['blnthn_samp'] = $blnthn_samp;
		$this->data['tgl_dari_txt'] = $tgl_dari_txt;
		$this->data['tgl_samp_txt'] = $tgl_samp_txt;
		$this->data['tgl_periode_txt'] = $tgl_periode_txt;
		$this->data['tgl_periode_txt2'] = $tgl_periode_txt2;
		$this->data['tgl_periode_txt_c'] = $tgl_periode_txt_c;


		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Laba Rugi';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

			#include seach
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		if ($jenis_laporan == 1) {
		$this->data['jml_pinjaman'] = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_samp);
		$this->data['jml_biaya_adm'] = $this->lap_laba_m->get_jml_biaya_adm($tgl_dari,$tgl_samp);
		$this->data['jml_bunga'] = $this->lap_laba_m->get_jml_bunga($tgl_dari,$tgl_samp);
		$this->data['jml_tagihan'] = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp);
		$this->data['jml_angsuran'] = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp);
		$this->data['jml_denda'] = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp);
		$this->data['data_dapat'] = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp);
		$this->data['data_biaya'] = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp);
		$this->data['total_dapat'] = $this->lap_laba_m->get_total_dapat($tgl_dari,$tgl_samp);
		$this->data['total_biaya'] = $this->lap_laba_m->get_total_biaya($tgl_dari,$tgl_samp);
		}

		if ($jenis_laporan == 2){
			$this->data['jml_pinjaman_old'] = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_dari,$jenis_laporan);
			$this->data['jml_pinjaman'] = $this->lap_laba_m->get_jml_pinjaman($tgl_samp,$tgl_samp,$jenis_laporan);
			
			$this->data['jml_biaya_adm_old'] = $this->lap_laba_m->get_jml_biaya_adm($tgl_dari,$tgl_dari,$jenis_laporan);
			$this->data['jml_biaya_adm'] = $this->lap_laba_m->get_jml_biaya_adm($tgl_samp,$tgl_samp,$jenis_laporan);

			$this->data['jml_bunga_old'] = $this->lap_laba_m->get_jml_bunga($tgl_dari,$tgl_dari,$jenis_laporan);
			$this->data['jml_bunga'] = $this->lap_laba_m->get_jml_bunga($tgl_samp,$tgl_samp,$jenis_laporan);
			
			$this->data['jml_tagihan_old'] = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_dari,$jenis_laporan);
			$this->data['jml_tagihan'] = $this->lap_laba_m->get_jml_tagihan($tgl_samp,$tgl_samp,$jenis_laporan);
			
			$this->data['jml_angsuran_old'] = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_dari,$jenis_laporan);
			$this->data['jml_angsuran'] = $this->lap_laba_m->get_jml_angsuran($tgl_samp,$tgl_samp,$jenis_laporan);
			
			$this->data['jml_denda_old'] = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_dari,$jenis_laporan);
			$this->data['jml_denda'] = $this->lap_laba_m->get_jml_denda($tgl_samp,$tgl_samp,$jenis_laporan);
			
			$this->data['data_dapat'] = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['data_biaya'] = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp,$jenis_laporan);

			$this->data['total_dapat'] = $this->lap_laba_m->get_total_dapat($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['total_biaya'] = $this->lap_laba_m->get_total_biaya($tgl_dari,$tgl_samp,$jenis_laporan);
		}
		$this->data['isi'] = $this->load->view('lap_laba_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function cetak() {
		$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
		$tgl_dari = "";
		if (isset($_GET['tgl_dari'])){
			$tgl_dari = $_GET['tgl_dari'];
		} else {
			$tgl_dari = date('Y').'-01-01';
		}
		$end_tgl_dari = date("Y-m-t", strtotime($tgl_dari));
		$tgl_samp = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$first_tgl_samp = date('Y-m-01', strtotime($tgl_samp));
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$thn_awal_dari = date("Y",strtotime($_GET['tgl_dari']));
		$tgl_awal_dari = $thn_awal_dari.'-01-01';
		$tgl_awal_dari = jin_date_ina($tgl_awal_dari, 'p');
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$end_tgl_dari_txt = jin_date_ina($end_tgl_dari, 'p');
		$first_tgl_samp_txt = jin_date_ina($first_tgl_samp, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt .'  -  '. $tgl_samp_txt;
		$tgl_periode_txt2 = $tgl_awal_dari . ' - ' . $end_tgl_dari_txt .'   -   '. $tgl_awal_dari . ' - ' . $tgl_samp_txt;
		$tgl_periode_txt_c = $tgl_awal_dari . ' s/d ' . $end_tgl_dari_txt .'   -   '. $tgl_awal_dari . ' s/d ' . $tgl_samp_txt;

		if ($jenis_laporan == 1) {
					$jml_pinjaman = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_samp);
					$jml_biaya_adm = $this->lap_laba_m->get_jml_biaya_adm($tgl_dari,$tgl_samp);
					$jml_bunga = $this->lap_laba_m->get_jml_bunga($tgl_dari,$tgl_samp);
					$jml_tagihan = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp);
					$jml_angsuran = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp);
					$jml_denda = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp);
					$data_dapat = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp);
					$data_biaya = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp);
					$total_dapat = $this->lap_laba_m->get_total_dapat($tgl_dari,$tgl_samp);
					$total_biaya = $this->lap_laba_m->get_total_biaya($tgl_dari,$tgl_samp);
					
				$this->load->library('Pdf');
				$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
				$pdf->set_nsi_header(TRUE);
				$pdf->AddPage('L');
				$html = '
					<style>
						.h_tengah {font-size: 8pt; text-align: center;}
						.h_midleft {font-size: 8pt; text-align: left;}
						.h_kiri {font-size: 8pt;text-align: left;}
						.h_kanan {font-size: 8pt;text-align: right;}
						.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
						.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
					</style>
					'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Laba / Rugi Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';

					$pinjaman = $jml_pinjaman->jml_total;
					$jml_prv = $jml_pinjaman->jml_prv;
					$biaya_adm = $jml_biaya_adm->jml_total; 
					$bunga = $jml_bunga->jml_total;
					$bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv); 
					$tagihan = $jml_tagihan->jml_total;
					$estimasi = $tagihan - $pinjaman;

					$sd_dibayar = $jml_angsuran->jml_total;
					$laba = $sd_dibayar - $pinjaman;

					$html .= 
					'<h3> Estimasi Data Pinjaman </h3>
						<table width="100%" cellspacing="0" cellpadding="3" border="1">
							<tr class="header_kolom">
								<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
								<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
								<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
							</tr>
							<tr>
								<td class="h_tengah"> 1 </td>
								<td> Jumlah Pinjaman</td>
								<td class="h_kanan">'.number_format(nsi_round($pinjaman),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 2 </td>
								<td> Pendapatan Biaya Administrasi</td>
								<td class="h_kanan">'.number_format(nsi_round($biaya_adm),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 3 </td>
								<td> Pendapatan Biaya Bunga</td>
								<td class="h_kanan">'.number_format(nsi_round($bunga),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 4 </td>
								<td> Jumlah Provisi	</td>
								<td class="h_kanan">'.number_format(nsi_round($jml_prv),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 5 </td>
								<td> Pendapatan Biaya Pembulatan</td>
								<td class="h_kanan">'.number_format(nsi_round($bulatan),2,',','.') .'</td>
							</tr>
							<tr class="header_kolom">
								<td colspan="2" class="h_kanan">Jumlah Tagihan</td>
								<td class="h_kanan">'.number_format($tagihan,2,',','.').'</td>
							</tr>
							<tr>
								<td colspan="2" class="h_kanan">Estimasi Pendapatan Pinjaman</td>
								<td class="h_kanan"><strong>'.number_format(nsi_round($estimasi),2,',','.') .'</strong></td>
							</tr>			
						</table>
								';
								
					$html .= '
					<h3> Pendapatan </h3>
						<table width="100%" cellspacing="0" cellpadding="3" border="1">
							<tr class="header_kolom">
								<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
								<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
								<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
							</tr>
							';
					$jml_dapat = 0;
					$no=1;
					$subtotal=0;
					$grandtotalp=0;
					foreach ($data_dapat as $data => $row) {
						$induka=$row->induk_akun;
						if ($row->induk_akun != '') { 
								$html .= '
								<tr>
									<td class="h_tengah">'.$no++.' </td>
									<td class="h_midleft"> '.$row->no_akun.' - '.$row->nama_akun.'</td>
									<td class="h_kanan">'.number_format(nsi_round($row->value),2,',','.').'</td>
								</tr>';
							$subtotal += $row->value;
						} else {
						
								$html .= '
								<tr>
									<td class="h_tengah">#</td>
									<td class="h_midleft"> <b>'.$row->no_akun.' - '.$row->nama_akun.'</b></td>
									<td class="h_kanan"></td>
								</tr>';

								
						}
						if($row->induk_akun != '' && @$data_dapat[$data+1]->induk_akun != $row->induk_akun) {
							$html .= '
									<tr>
										<td colspan="2" class="h_kanan"><b>Total</b></td>
										<td class="h_kanan">'.number_format(nsi_round($subtotal),2,',','.').'</td>
									</tr>';
									$subtotal=0;
						}
						$grandtotalp += $row->value;
					}

					$jml_p = $laba + $jml_dapat;
					
					$html .= '<tr class="header_kolom">
									<td colspan="2" class="h_kanan">Jumlah Pendapatan</td>
									<td class="h_kanan">'.number_format($grandtotalp,2,',','.').'</td>
								</tr>';
								
					$html .= '</table>';
					

					$html .= 
					'<h3> Biaya </h3>
						<table width="100%" cellspacing="0" cellpadding="3" border="1">
						<tr class="header_kolom">
							<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
							<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
							<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
						</tr>';
					$no=1;
					$jml_beban = 0;
					$subtotal=0;
					$grandtotal=0;
					foreach ($data_biaya as $data => $rows) {

						if ($rows->induk_akun != '') {
							$html .= '<tr>
										<td class="h_tengah">'.$no++.'</td>
										<td class="h_midleft">'.$rows->no_akun.' - '.$rows->nama_akun.'</td>
										<td class="h_kanan">'.number_format(nsi_round($rows->value),2,',','.').'</td>
									</tr>';
									$subtotal += $rows->value;
						} else {
							$no=1;
							$html .= '<tr>
										<td class="h_tengah">#</td>
										<td class="h_midleft"><b>'.$rows->no_akun.' - '.$rows->nama_akun.'</b></td>
										<td class="h_kanan">'.number_format(nsi_round($rows->value),2,',','.').'</td>
									</tr>';
						}
						if($rows->induk_akun != '' && @$data_biaya[$data+1]->induk_akun != $rows->induk_akun) {
							$html .= '
									<tr>
										<td colspan="2" class="h_kanan"><b>Total</b></td>
										<td class="h_kanan">'.number_format(nsi_round($subtotal),2,',','.').'</td>
									</tr>';
									$subtotal=0;
						}
						$grandtotal += $rows->value;
					}
					$html.= '
					<tr class="header_kolom">
						<td colspan="2" class="h_kanan"> Jumlah Biaya </td>
						<td class="h_kanan"> '.number_format($total_biaya->value,2,',','.').'</td>
					</tr>
					</table>

					
					<br>
					<br>
					
					<table width="100%" cellspacing="0" cellpadding="3" border="0">
					<tr class="header_kolom" style="background-color: #98FB98;">
						<td class="h_tengah"> Laba / Rugi </td>
						<td class="h_kanan">'.number_format(nsi_round($grandtotalp - $total_biaya->value),2,',','.') .'</td>
					</tr>
					</table>';
	} else {

		$jml_pinjaman = $this->lap_laba_m->get_jml_pinjaman($tgl_samp,$tgl_samp,2);
		$jml_pinjaman_old = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_dari,2);
		$jml_biaya_adm = $this->lap_laba_m->get_jml_biaya_adm($tgl_samp,$tgl_samp,2);
		$jml_biaya_adm_old = $this->lap_laba_m->get_jml_biaya_adm($tgl_dari,$tgl_dari,2);
		$jml_bunga = $this->lap_laba_m->get_jml_bunga($tgl_samp,$tgl_samp,2);
		$jml_bunga_old = $this->lap_laba_m->get_jml_bunga($tgl_dari,$tgl_dari,2);
		$jml_tagihan = $this->lap_laba_m->get_jml_tagihan($tgl_samp,$tgl_samp,2);
		$jml_tagihan_old = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_dari,2);
		$jml_angsuran = $this->lap_laba_m->get_jml_angsuran($tgl_samp,$tgl_samp,2);
		$jml_angsuran_old = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_dari,2);
		$jml_denda = $this->lap_laba_m->get_jml_denda($tgl_samp,$tgl_samp,2);
		$jml_denda_old = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_dari,2);
		$data_dapat = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp,2);
		$data_biaya = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp,2);
		$total_dapat = $this->lap_laba_m->get_total_dapat($tgl_dari,$tgl_samp,2);
		$total_biaya = $this->lap_laba_m->get_total_biaya($tgl_dari,$tgl_samp,2);
		$pinjaman = $jml_pinjaman->jml_total;
		$pinjamanold = $jml_pinjaman_old->jml_total;
		$biaya_adm = $jml_biaya_adm->jml_total; 
		$biaya_adm_old = $jml_biaya_adm_old->jml_total;
		$bunga = $jml_bunga->jml_total;
		$bunga_old = $jml_bunga_old->jml_total;
		$provisi = $jml_pinjaman->jml_prv;
		$provisi_old = $jml_pinjaman_old->jml_prv;
		$bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv);
		$bulatan_old = $jml_tagihan_old->jml_total - ($jml_pinjaman_old->jml_total + $jml_bunga_old->jml_total + $jml_biaya_adm_old->jml_total + $jml_pinjaman_old->jml_prv);
		$tagihan = $jml_tagihan->jml_total;
		$tagihan_old = $jml_tagihan_old->jml_total;
		$estimasi = $tagihan - $pinjaman;
		$estimasi_old = $tagihan_old - $pinjamanold;


					
				$this->load->library('Pdf');
				$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
				$pdf->set_nsi_header(TRUE);
				$pdf->AddPage('L');
				$html = '
					<style>
						.h_tengah {font-size: 8pt; text-align: center;}
						.h_midleft {font-size: 8pt; text-align: left;}
						.h_kiri {font-size: 8pt;text-align: left;}
						.h_kanan {font-size: 8pt;text-align: right;}
						.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
						.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
					</style>'

					
				.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Laba / Rugi Periode '.$tgl_periode_txt_c.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
					
				$html .= 
				'<h3> Estimasi Data Pinjaman </h3>
					<table class="table table-bordered">
					<tr class="header_kolom">
						<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
						<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
						<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_dari)).' </th>
						<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_samp)).'</th>
					</tr>';
					$html .= '
					<tr>
						<td class="h_tengah"> 1 </td>
						<td> Jumlah Pinjaman</td>
						<td class="h_kanan">'.
								number_format(nsi_round($pinjamanold),2,',','.').'<br>
							</td>
						<td class="h_kanan">'
								
								.number_format(nsi_round($pinjaman),2,',','.').'<br>
						</td>
					</tr>';	
					$html .= ' <tr>
					<td class="h_tengah"> 2 </td>
					<td> Pendapatan Biaya Administrasi</td>
					<td class="h_kanan">'
						.number_format(nsi_round($biaya_adm_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							.number_format(nsi_round($biaya_adm),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td class="h_tengah"> 3 </td>
					<td> Pendapatan Biaya Bunga</td>
					<td class="h_kanan">'
							
						.number_format(nsi_round($bunga_old),2,',','.').'<br>
						</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($bunga),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td class="h_tengah"> 4 </td>
					<td> Jumlah Provisi</td>
					<td class="h_kanan">'

							
							.number_format(nsi_round($provisi_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($provisi),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td class="h_tengah"> 5 </td>
					<td> Pendapatan Biaya Pembulatan</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($bulatan_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($bulatan),2,',','.').'<br>
					</td>
				</tr>		
				<tr class="header_kolom">
					<td colspan="2" class="h_kanan"> Jumlah Tagihan</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($tagihan_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($tagihan),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td colspan="2" class="h_kanan"> <strong>Estimasi Pendapatan Pinjaman</strong></td>
					<td class="h_kanan">'
							
						.'<strong>'.number_format(nsi_round($estimasi_old),2,',','.').'</strong>
					</td>
					<td class="h_kanan">'
							
							.'<strong>'.number_format(nsi_round($estimasi),2,',','.').'</strong>
					</td>
				</tr>';	
		$html .= '<br> <h3> Pendapatan </h3><tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_dari)).'</th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_samp)).'</th>
	</tr>';

	 $i=0; foreach($data_dapat as $data) {
		$html .= '<tr>';
		if ($data->induk_akun != '') { $i++; 
		$html .= '<td class="h_tengah">'.  $i  .'</td>
		<td>'. $data->no_akun.' - '.$data->nama_akun .'</td>
		<td class="h_kanan">' .number_format($data->valueold,2,',','.').'</td>
		<td class="h_kanan">' .number_format($data->value,2,',','.').'</td>';
	    } else { $i=0;
		$html .='<td class="h_tengah fa fa-h-square"></td>
		<td><strong>'. $data->no_akun.' - '.$data->nama_akun .'</strong></td>
		<td class="h_kanan"></td>
		<td class="h_kanan"></td>';
		}
		$html .='</tr>';
	 }

	 $html .=' <tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Pendapatan</td>
		<td class="h_kanan">'.number_format($total_dapat->valueold,2,',','.') .'</td>
		<td class="h_kanan">'. number_format($total_dapat->value,2,',','.'). '</td>
	</tr>';
	$html .= '<h3>Biaya </h3>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '.date("F Y",strtotime($blnthn_dari)).' </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '.date("F Y",strtotime($blnthn_samp)).' </th>
	</tr>';
		$i=0; foreach($data_biaya as $data) { 
	$html .= '<tr>';
		if ($data->induk_akun != '') { $i++; 
	$html .= '<td class="h_tengah">' .$i.'</td>
		<td>'.$data->no_akun.' - '.$data->nama_akun.'</td>
		<td class="h_kanan">'.number_format($data->valueold,2,',','.').'</td>
		<td class="h_kanan">'.number_format($data->value,2,',','.').'</td>';
		} else {$i=0;
	$html .= '<td class="h_tengah fa fa-h-square"></td>
		<td><strong>'.$data->no_akun.' - '.$data->nama_akun.'</strong></td>
		<td class="h_kanan"></td>
		<td class="h_kanan"></td>';
	 }
	 $html .= '</tr>';
	 }
	 $html .= '<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Biaya</td>
		<td class="h_kanan">'. number_format($total_biaya->valueold,2,',','.').'</td>
		<td class="h_kanan">'.number_format($total_biaya->value,2,',','.').'</td>
	</tr>
	<tr class="header_kolom">
		<td > </td>
		<td style="width:50%; vertical-align: middle; text-align:right">Laba Rugi </td>
		<td style="width:20%; vertical-align: middle; text-align:right">'. number_format($total_dapat->valueold - $total_biaya->valueold,2,',','.'). '</td>
		<td style="width:20%; vertical-align: middle; text-align:right">'.number_format($total_dapat->value - $total_biaya->value,2,',','.').'</td>
	</tr>';
		$html .='</table>';
	}
		$pdf->nsi_html($html);
		$pdf->Output('lap_laba_rugi'.date('Ymd_His') . '.pdf', 'I');
	} 

	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
		$tgl_dari = "";
		if (isset($_GET['tgl_dari'])){
			$tgl_dari = $_GET['tgl_dari'];
		} else {
			$tgl_dari = date('Y').'-01-01';
		}
		$end_tgl_dari = date("Y-m-t", strtotime($tgl_dari));
		$tgl_samp = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$first_tgl_samp = date('Y-m-01', strtotime($tgl_samp));
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$thn_awal_dari = date("Y",strtotime($_GET['tgl_dari']));
		$tgl_awal_dari = $thn_awal_dari.'-01-01';
		$tgl_awal_dari = jin_date_ina($tgl_awal_dari, 'p');
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$end_tgl_dari_txt = jin_date_ina($end_tgl_dari, 'p');
		$first_tgl_samp_txt = jin_date_ina($first_tgl_samp, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt .'  -  '. $tgl_samp_txt;
		$tgl_periode_txt2 = $tgl_awal_dari . ' - ' . $end_tgl_dari_txt .'   -   '. $tgl_awal_dari . ' - ' . $tgl_samp_txt;
		$tgl_periode_txt_c = $tgl_awal_dari . ' s/d ' . $end_tgl_dari_txt .'   -   '. $tgl_awal_dari . ' s/d ' . $tgl_samp_txt;
		
		
	if ($jenis_laporan == 1) {

		$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
		$tgl_dari = isset($_GET['tgl_dari'])?$_GET['tgl_dari']:date('Y') . '-01-01';
		$tgl_samp = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;

		$jml_pinjaman = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_samp);
		$jml_biaya_adm = $this->lap_laba_m->get_jml_biaya_adm($tgl_dari,$tgl_samp);
		$jml_bunga = $this->lap_laba_m->get_jml_bunga($tgl_dari,$tgl_samp);
		$jml_tagihan = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp);
		$jml_angsuran = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp);
		$jml_denda = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp);
		$data_dapat = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp);
		$data_biaya = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp);
		$total_dapat = $this->lap_laba_m->get_total_dapat($tgl_dari,$tgl_samp);
		$total_biaya = $this->lap_laba_m->get_total_biaya($tgl_dari,$tgl_samp);

	   $this->load->library('Pdf');
				$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
				$pdf->set_nsi_header(TRUE);
				$pdf->AddPage('L');
				$html = '
					<style>
						.h_tengah {font-size: 8pt; text-align: center;}
						.h_midleft {font-size: 8pt; text-align: left;}
						.h_kiri {font-size: 8pt;text-align: left;}
						.h_kanan {font-size: 8pt;text-align: right;}
						.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
						.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
					</style>
					'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Laba / Rugi Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';


	   $pinjaman = $jml_pinjaman->jml_total;
	   $jml_prv = $jml_pinjaman->jml_prv;
	   $biaya_adm = $jml_biaya_adm->jml_total; 
	   $bunga = $jml_bunga->jml_total;
	   $bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv); 
	   $tagihan = $jml_tagihan->jml_total;
	   $estimasi = $tagihan - $pinjaman;

	   $sd_dibayar = $jml_angsuran->jml_total;
	   $laba = $sd_dibayar - $pinjaman;

	   $html = '
					<style>
						.h_tengah {font-size: 8pt; text-align: center;}
						.h_midleft {font-size: 8pt; text-align: left;}
						.h_kiri {font-size: 8pt;text-align: left;}
						.h_kanan {font-size: 8pt;text-align: right;}
						.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
						.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
					</style>
					<span class="txt_judul">Laporan Laba / Rugi Periode '.$tgl_periode_txt.'</span>';

					$pinjaman = $jml_pinjaman->jml_total;
					$jml_prv = $jml_pinjaman->jml_prv;
					$biaya_adm = $jml_biaya_adm->jml_total; 
					$bunga = $jml_bunga->jml_total;
					$bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv); 
					$tagihan = $jml_tagihan->jml_total;
					$estimasi = $tagihan - $pinjaman;

					$sd_dibayar = $jml_angsuran->jml_total;
					$laba = $sd_dibayar - $pinjaman;

					$html .= 
					'<h3> Estimasi Data Pinjaman </h3>
						<table class="table table-bordered">
							<tr class="header_kolom">
								<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
								<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
								<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
							</tr>
							<tr>
								<td class="h_tengah"> 1 </td>
								<td> Jumlah Pinjaman</td>
								<td class="h_kanan">'.number_format(nsi_round($pinjaman),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 2 </td>
								<td> Pendapatan Biaya Administrasi</td>
								<td class="h_kanan">'.number_format(nsi_round($biaya_adm),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 3 </td>
								<td> Pendapatan Biaya Bunga</td>
								<td class="h_kanan">'.number_format(nsi_round($bunga),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 4 </td>
								<td> Jumlah Provisi	</td>
								<td class="h_kanan">'.number_format(nsi_round($jml_prv),2,',','.') .'</td>
							</tr>
							<tr>
								<td class="h_tengah"> 5 </td>
								<td> Pendapatan Biaya Pembulatan</td>
								<td class="h_kanan">'.number_format(nsi_round($bulatan),2,',','.') .'</td>
							</tr>
							<tr class="header_kolom">
								<td colspan="2" class="h_kanan">Jumlah Tagihan</td>
								<td class="h_kanan">'.number_format($tagihan).'</td>
							</tr>
							<tr>
								<td colspan="2" class="h_kanan">Estimasi Pendapatan Pinjaman</td>
								<td class="h_kanan"><strong>'.number_format(nsi_round($estimasi),2,',','.') .'</strong></td>
							</tr>			
						</table>
								';
								
					$html .= '
					<h3> Pendapatan </h3>
						<table class="table table-bordered">
							<tr class="header_kolom">
								<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
								<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
								<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
							</tr>
							';
					$jml_dapat = 0;
					$no=1;
					$subtotal=0;
					$grandtotalp=0;
					foreach ($data_dapat as $data => $row) {
						$induka=$row->induk_akun;
						if ($row->induk_akun != '') { 
								$html .= '
								<tr>
									<td class="h_tengah">'.$no++.' </td>
									<td class="h_midleft"> '.$row->no_akun.' - '.$row->nama_akun.'</td>
									<td class="h_kanan">'.number_format(nsi_round($row->value),2,',','.').'</td>
								</tr>';
							$subtotal += $row->value;
						} else {
						
								$html .= '
								<tr>
									<td class="h_tengah">#</td>
									<td class="h_midleft"> <b>'.$row->no_akun.' - '.$row->nama_akun.'</b></td>
									<td class="h_kanan"></td>
								</tr>';

								
						}
						if($row->induk_akun != '' && @$data_dapat[$data+1]->induk_akun != $row->induk_akun) {
							$html .= '
									<tr>
										<td colspan="2" class="h_kanan"><b>Total</b></td>
										<td class="h_kanan">'.number_format(nsi_round($subtotal),2,',','.').'</td>
									</tr>';
									$subtotal=0;
						}
						$grandtotalp += $row->value;
					}

					$jml_p = $laba + $jml_dapat;
					
					$html .= '<tr class="header_kolom">
									<td colspan="2" class="h_kanan">Jumlah Pendapatan</td>
									<td class="h_kanan">'.number_format($grandtotalp,2,',','.').'</td>
								</tr>';
								
					$html .= '</table>';
					

					$html .= 
					'<h3> Biaya </h3>
						<table class="table table-bordered">
						<tr class="header_kolom">
							<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
							<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
							<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
						</tr>';
					$no=1;
					$jml_beban = 0;
					$subtotal=0;
					$grandtotalb=0;
					foreach ($data_biaya as $data => $rows) {

						if ($rows->induk_akun != '') {
							$html .= '<tr>
										<td class="h_tengah">'.$no++.'</td>
										<td class="h_midleft">'.$rows->no_akun.' - '.$rows->nama_akun.'</td>
										<td class="h_kanan">'.number_format(nsi_round($rows->value),2,',','.').'</td>
									</tr>';
									$subtotal += $rows->value;
						} else {
							$no=1;
							$html .= '<tr>
										<td class="h_tengah">#</td>
										<td class="h_midleft"><b>'.$rows->no_akun.' - '.$rows->nama_akun.'</b></td>
										<td class="h_kanan">'.number_format(nsi_round($rows->value),2,',','.').'</td>
									</tr>';
						}
						if($rows->induk_akun != '' && @$data_biaya[$data+1]->induk_akun != $rows->induk_akun) {
							$html .= '
									<tr>
										<td colspan="2" class="h_kanan"><b>Total</b></td>
										<td class="h_kanan">'.number_format(nsi_round($subtotal),2,',','.').'</td>
									</tr>';
									$subtotal=0;
						}
						$grandtotalb += $rows->value;
					}
					$html.= '
					<tr class="header_kolom">
						<td colspan="2" class="h_kanan"> Jumlah Biaya </td>
						<td class="h_kanan"> '.number_format($total_biaya->value,2,',','.').'</td>
					</tr>
					</table>

					
					<br>
					<br>
					
					<table class="table table-bordered">
					<tr class="header_kolom" style="background-color: #98FB98;">
						<td colspan="2" class="h_tengah"> Laba / Rugi </td>
						<td class="h_kanan">'.number_format(nsi_round($grandtotalp - $total_biaya->value),2,',','.') .'</td>
					</tr>
					</table>';
	} else {
		$jml_pinjaman = $this->lap_laba_m->get_jml_pinjaman($tgl_samp,$tgl_samp,2);
		$jml_pinjaman_old = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_dari,2);
		$jml_biaya_adm = $this->lap_laba_m->get_jml_biaya_adm($tgl_samp,$tgl_samp,2);
		$jml_biaya_adm_old = $this->lap_laba_m->get_jml_biaya_adm($tgl_dari,$tgl_dari,2);
		$jml_bunga = $this->lap_laba_m->get_jml_bunga($tgl_samp,$tgl_samp,2);
		$jml_bunga_old = $this->lap_laba_m->get_jml_bunga($tgl_dari,$tgl_dari,2);
		$jml_tagihan = $this->lap_laba_m->get_jml_tagihan($tgl_samp,$tgl_samp,2);
		$jml_tagihan_old = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_dari,2);
		$jml_angsuran = $this->lap_laba_m->get_jml_angsuran($tgl_samp,$tgl_samp,2);
		$jml_angsuran_old = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_dari,2);
		$jml_denda = $this->lap_laba_m->get_jml_denda($tgl_samp,$tgl_samp,2);
		$jml_denda_old = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_dari,2);
		$data_dapat = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp,2);
		$data_biaya = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp,2);
		$total_dapat = $this->lap_laba_m->get_total_dapat($tgl_dari,$tgl_samp,2);
		$total_biaya = $this->lap_laba_m->get_total_biaya($tgl_dari,$tgl_samp,2);
		$pinjaman = $jml_pinjaman->jml_total;
		$pinjamanold = $jml_pinjaman_old->jml_total;
		$biaya_adm = $jml_biaya_adm->jml_total; 
		$biaya_adm_old = $jml_biaya_adm_old->jml_total;
		$bunga = $jml_bunga->jml_total;
		$bunga_old = $jml_bunga_old->jml_total;
		$provisi = $jml_pinjaman->jml_prv;
		$provisi_old = $jml_pinjaman_old->jml_prv;
		$bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv);
		$bulatan_old = $jml_tagihan_old->jml_total - ($jml_pinjaman_old->jml_total + $jml_bunga_old->jml_total + $jml_biaya_adm_old->jml_total + $jml_pinjaman_old->jml_prv);
		$tagihan = $jml_tagihan->jml_total;
		$tagihan_old = $jml_tagihan_old->jml_total;
		$estimasi = $tagihan - $pinjaman;
		$estimasi_old = $tagihan_old - $pinjamanold;

				$html = '
					<style>
						.h_tengah {font-size: 8pt; text-align: center;}
						.h_midleft {font-size: 8pt; text-align: left;}
						.h_kiri {font-size: 8pt;text-align: left;}
						.h_kanan {font-size: 8pt;text-align: right;}
						.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
						.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
					</style>
					<span class="txt_judul">Laporan Laba / Rugi Periode '.$tgl_periode_txt_c.'</span>
					<table class="table table-bordered">
					<tr class="header_kolom"><th>Estimasi Data Pinjaman</th></tr>
					<tr class="header_kolom">
						<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
						<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
						<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_dari)).' </th>
						<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_samp)).'</th>
					</tr>';
					$html .= '
					<tr>
						<td class="h_tengah"> 1 </td>
						<td> Jumlah Pinjaman</td>
						<td class="h_kanan">'.
								number_format(nsi_round($pinjamanold),2,',','.').'<br>
							</td>
						<td class="h_kanan">'
								
								.number_format(nsi_round($pinjaman),2,',','.').'<br>
						</td>
					</tr>';	
					$html .= ' <tr>
					<td class="h_tengah"> 2 </td>
					<td> Pendapatan Biaya Administrasi</td>
					<td class="h_kanan">'
						.number_format(nsi_round($biaya_adm_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							.number_format(nsi_round($biaya_adm),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td class="h_tengah"> 3 </td>
					<td> Pendapatan Biaya Bunga</td>
					<td class="h_kanan">'
							
						.number_format(nsi_round($bunga_old),2,',','.').'<br>
						</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($bunga),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td class="h_tengah"> 4 </td>
					<td> Jumlah Provisi</td>
					<td class="h_kanan">'

							
							.number_format(nsi_round($provisi_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($provisi),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td class="h_tengah"> 5 </td>
					<td> Pendapatan Biaya Pembulatan</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($bulatan_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($bulatan),2,',','.').'<br>
					</td>
				</tr>		
				<tr class="header_kolom">
					<td colspan="2" class="h_kanan"> Jumlah Tagihan</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($tagihan_old),2,',','.').'<br>
					</td>
					<td class="h_kanan">'
							
							.number_format(nsi_round($tagihan),2,',','.').'<br>
					</td>
				</tr>
				<tr>
					<td colspan="2" class="h_kanan"> <strong>Estimasi Pendapatan Pinjaman</strong></td>
					<td class="h_kanan">'
							
						.'<strong>'.number_format(nsi_round($estimasi_old),2,',','.').'</strong>
					</td>
					<td class="h_kanan">'
							
							.'<strong>'.number_format(nsi_round($estimasi),2,',','.').'</strong>
					</td>
				</tr>';	
		$html .= '<tr class="header_kolom"><th>Pendapatan</th></tr>
		<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_dari)).'</th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_samp)).'</th>
	</tr>';

	 $i=0; foreach($data_dapat as $data) {
		$html .= '<tr>';
		if ($data->induk_akun != '') { $i++; 
		$html .= '<td class="h_tengah">'.  $i  .'</td>
		<td>'. $data->no_akun.' - '.$data->nama_akun .'</td>
		<td class="h_kanan">' .number_format($data->valueold,2,',','.').'</td>
		<td class="h_kanan">' .number_format($data->value,2,',','.').'</td>';
	    } else { $i=0;
		$html .='<td class="h_tengah fa fa-h-square"></td>
		<td><strong>'. $data->no_akun.' - '.$data->nama_akun .'</strong></td>
		<td class="h_kanan"></td>
		<td class="h_kanan"></td>';
		}
		$html .='</tr>';
	 }

	 $html .=' <tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Pendapatan</td>
		<td class="h_kanan">'.number_format($total_dapat->valueold,2,',','.') .'</td>
		<td class="h_kanan">'. number_format($total_dapat->value,2,',','.'). '</td>
	</tr> <br>';
	$html .= '<p><tr class="header_kolom"><th>Biaya</th></tr>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_dari)) .'</th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan '. date("F Y",strtotime($blnthn_samp)) .'</th>
	</tr>';
		$i=0; foreach($data_biaya as $data) { 
	$html .= '<tr>';
		if ($data->induk_akun != '') { $i++; 
	$html .= '<td class="h_tengah">' .$i.'</td>
		<td>'.$data->no_akun.' - '.$data->nama_akun.'</td>
		<td class="h_kanan">'.number_format($data->valueold,2,',','.').'</td>
		<td class="h_kanan">'.number_format($data->value,2,',','.').'</td>';
		} else {$i=0;
	$html .= '<td class="h_tengah fa fa-h-square"></td>
		<td><strong>'.$data->no_akun.' - '.$data->nama_akun.'</strong></td>
		<td class="h_kanan"></td>
		<td class="h_kanan"></td>';
	 }
	 $html .= '</tr>';
	 }
	 $html .= '<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Biaya</td>
		<td class="h_kanan">'. number_format($total_biaya->valueold,2,',','.').'</td>
		<td class="h_kanan">'.number_format($total_biaya->value,2,',','.').'</td>
	</tr>
	<tr class="header_kolom">
		<td > </td>
		<td style="width:50%; vertical-align: middle; text-align:right">Laba Rugi </td>
		<td style="width:20%; vertical-align: middle; text-align:right">'. number_format($total_dapat->valueold - $total_biaya->valueold,2,',','.'). '</td>
		<td style="width:20%; vertical-align: middle; text-align:right">'.number_format($total_dapat->value - $total_biaya->value,2,',','.').'</td>
	</tr>';
		$html .='</table>';
	}
     

		echo $html;
		die();
	}

	
}