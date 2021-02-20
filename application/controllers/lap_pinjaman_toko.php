<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_pinjaman_toko extends OperatorController {

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
		$this->data['judul_sub'] = 'Laporan Pinjaman Toko';

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

		$this->data['all'] = $this->lap_toko_m->get_data_lap_pinjaman_toko();	

		//$this->data['data_pasiva'] = $this->lap_shu_m->get_data_akun_pasiva();

		$this->data['isi'] = $this->load->view('lap_pinjaman_toko_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);

	}
	
	function cetak_laporan(){
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
		$html = '<style>
					.h_tengah {text-align: center;}
					.h_kiri {text-align: left;}
					.h_kanan {text-align: right;}
					.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
					.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
				</style>
				'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Pinjaman Toko '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
				$html .= '
				<table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
				<tr class="header_kolom">
					<th width:5%> No. </th>
					<th width:15%>Nama Anggota </th>
					<th width:15%>Nama Barang </th>
					<th width=15%>Jumlah</th>
					<th width=10%>Lunas</th>
					<th width=10%>Lama Angsuran</th>
					<th width=20%>Keterangan</th>
				</tr>';

		$data = $this->lap_toko_m->get_data_lap_pinjaman_toko();	
		$no = 1;
		foreach ($data['data'] as $is) {

			$html .= '<tr>
				<td>'.$no.'</td>
				<td>'.$is->nama.'</td>
				<td>'.ucwords($is->nm_barang).'</td>
				<td>'.number_format($is->jumlah).'</td>
				<td>'.$is->lunas.'</td>
				<td>'.number_format($is->lama_angsuran).'</td>
				<td>'.$is->keterangan.'</td>
			</tr>';
			$no++;
		}
		$html .= '</table>';
		$pdf->nsi_html($html);
		$pdf->Output('lap_neraca'.date('Ymd_His') . '.pdf', 'I');
    }
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->lap_toko_m->get_data_excel();
		$i	= 1;
		$rows   = array(); 
		
		
		echo "
			<table border='1' cellpadding='5'>
			  <tr>
				<th>No</th>
				<th>Nama Anggota</th>
				<th>Nama Barang</th>
				<th>Jumlah</th>
				<th>Lunas</th>
				<th>Lama Angsuran</th>
				<th>Keterangan</th>
			  </tr>
  		";
		foreach ($data['data'] as $is) {
			echo "
			<tr>
				<td>$i</td>
				<td>$is->nama</td>
				<td>$is->nm_barang)</td>
				<td>$is->jumlah</td>
				<td>$is->lunas</td>
				<td>$is->lama_angsuran</td>
				<td>$is->keterangan</td>
			</tr>
			";
			$i++;
		}
		
		echo "</table>";
		
		die();
	}

}