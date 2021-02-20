<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_trans_toko extends OperatorController {

public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_shu_m');
		$this->load->model('lap_toko_m');
		error_reporting();
	}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Laporan Toko';

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

		$this->data['all'] = $this->lap_toko_m->get_data_lap_transaksi_toko();	

		//$this->data['data_pasiva'] = $this->lap_shu_m->get_data_akun_pasiva();

		$this->data['isi'] = $this->load->view('lap_trans_toko_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);

	}
	
	function cetak_laporan() {
		
		
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
		$pdf = new Pdf('P', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('P');
		$html = '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Transkasi Toko Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
		$html .= '
		<table width="100%" cellspacing="0" cellpadding="3" border="1">
			<tr class="header_kolom">
				<th style="width:5%;" > No. </th>
				<th style="width:20%;">Nama Anggota </th>
				<th style="width:20%;">Nama Barang </th>
				<th style="width:15%;"> Jumlah</th>
				<th style="width:15%;"> Harga</th>
				<th style="width:25%;"> Keterangan</th>
			</tr>';
			$data_laporan = $this->lap_toko_m->get_data_lap_transaksi_toko();	
			foreach($data_laporan->result_array() as $is){
				$no = 1;
				
				$html.='
				<tr>
					<td class="h_tengah">'.$no++.'</td>
					<td>'.$is->nama.'</td>
					<td>'.$is->nm_barang.'</td>
					<td>'.number_format($is->jumlah).'</td>
					<td>'.number_format($is->harga).'</td>
					<td>'.$is->keterangan.'</td>
				</tr>';
			}
			$html .= '</table>';
			$pdf->nsi_html($html);
			$pdf->Output('lap_trans_toko_'.date('Ymd_His') . '.pdf', 'I');
		} 

}