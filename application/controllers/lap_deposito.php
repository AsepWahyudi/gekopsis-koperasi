<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_deposito extends OperatorController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_deposito_m');
	}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Data Deposito';

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

		$config = array();
		$config["base_url"] = base_url() . "lap_deposito/index/halaman";
		$config["total_rows"] = $this->lap_deposito_m->get_jml_data_deposito(); // banyak data
		$config["per_page"] = 10;
		$config["uri_segment"] = 4;
		$config['use_page_numbers'] = TRUE;

		$config['full_tag_open'] = '<ul class="pagination">';
		$config['full_tag_close'] = '</ul>';

		$config['first_link'] = '&laquo; First';
		$config['first_tag_open'] = '<li class="prev page">';
		$config['first_tag_close'] = '</li>';

		$config['last_link'] = 'Last &raquo;';
		$config['last_tag_open'] = '<li class="next page">';
		$config['last_tag_close'] = '</li>';

		$config['next_link'] = 'Next &rarr;';
		$config['next_tag_open'] = '<li class="next page">';
		$config['next_tag_close'] = '</li>';

		$config['prev_link'] = '&larr; Previous';
		$config['prev_tag_open'] = '<li class="prev page">';
		$config['prev_tag_close'] = '</li>';

		$config['cur_tag_open'] = '<li class="active"><a href="">';
		$config['cur_tag_close'] = '</a></li>';

		$config['num_tag_open'] = '<li class="page">';
		$config['num_tag_close'] = '</li>';

		$this->pagination->initialize($config);
		$offset = ($this->uri->segment(4)) ? $this->uri->segment(4) : 0;
		if($offset > 0) {
			$offset = ($offset * $config['per_page']) - $config['per_page'];
		}
		$this->data["data_jns_deposito"] = $this->lap_deposito_m->get_data_jenis_deposito($config["per_page"], $offset); // panggil seluruh data aanggota
		$this->data["halaman"] = $this->pagination->create_links();
		$this->data["offset"] = $offset;
		
		$this->data['isi'] = $this->load->view('lap_deposito_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);

	}

	function cetak() {
		$deposito = $this->lap_deposito_m->lap_jenis_deposito();
		if($deposito == FALSE) {
			echo 'DATA KOSONG';
			//redirect('lap_deposito');
			exit();
		}

		
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
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Saldo Kas Deposito Periode '.$tgl_periode_txt.' </span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
		$html.='<table width="100%" cellspacing="0" cellpadding="3" border="1">
		<tr class="header_kolom">
			<th style="width:5%;"> No. </th>
			<th style="width:35%;"> Jenis Akun </th>
			<th style="width:20%;"> Deposito  </th>
			<th style="width:20%;"> Penarikan  </th>
			<th style="width:20%;"> Jumlah  </th>
		</tr>';

		$no = 1;
		$deposito_arr = array();
		$deposito_row_total = 0; 
		$deposito_total = 0; 
		$penarikan_total = 0; 
		foreach ($deposito as $jenis) {

			$deposito_arr[$jenis->id] = $jenis->jns_deposito;
			$nilai_s = $this->lap_deposito_m->get_jml_deposito($jenis->id);
			$nilai_p = $this->lap_deposito_m->get_jml_penarikan($jenis->id);

			$deposito_row=$nilai_s->jml_total; 
			$penarikan_row=$nilai_p->jml_total;
			$sub_total = $deposito_row - $penarikan_row; 

			$deposito_total += $deposito_row;
			$penarikan_total += $penarikan_row;
			$deposito_row_total += $sub_total;

			$html .= '
			<tr>
				<td class="h_tengah">'.$no++.'</td>
				<td>'.$jenis->jns_deposito.'</td>
				<td class="h_kanan">'. number_format($deposito_row).'</td>
				<td class="h_kanan">'. number_format($penarikan_row).'</td>
				<td class="h_kanan">'. number_format($sub_total).'</td>
			</tr>';
		}
		$html .= '
		<tr class="header_kolom">
			<td colspan="2" class="h_tengah"><strong>Jumlah Total</strong></td>
			<td class="h_kanan"><strong>'.number_format($deposito_total).'</strong></td>
			<td class="h_kanan"><strong>'.number_format($penarikan_total).'</strong></td>
			<td class="h_kanan"><strong>'.number_format($deposito_row_total).'</strong></td>
		</tr>';
		$html .= '</table>';
		$pdf->nsi_html($html);
		$pdf->Output('lap_deposito'.date('Ymd_His') . '.pdf', 'I');
	}

	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$deposito = $this->lap_deposito_m->lap_jenis_deposito();
		if($deposito == FALSE) {
			echo 'DATA KOSONG';
			//redirect('lap_deposito');
			exit();
		}

		
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

		$html = '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		<span class="txt_judul">Laporan Saldo Kas deposito Periode '.$tgl_periode_txt.' </span>';
		$html.='<table width="100%" cellspacing="0" cellpadding="3" border="1">
		<tr class="header_kolom">
			<th style="width:5%;"> No. </th>
			<th style="width:35%;"> Jenis Akun </th>
			<th style="width:20%;"> deposito  </th>
			<th style="width:20%;"> Penarikan  </th>
			<th style="width:20%;"> Jumlah  </th>
		</tr>';

		$no = 1;
		$deposito_arr = array();
		$deposito_row_total = 0; 
		$deposito_total = 0; 
		$penarikan_total = 0; 
		foreach ($deposito as $jenis) {

			$deposito_arr[$jenis->id] = $jenis->jns_deposito;
			$nilai_s = $this->lap_deposito_m->get_jml_deposito($jenis->id);
			$nilai_p = $this->lap_deposito_m->get_jml_penarikan($jenis->id);

			$deposito_row=$nilai_s->jml_total; 
			$penarikan_row=$nilai_p->jml_total;
			$sub_total = $deposito_row - $penarikan_row; 

			$deposito_total += $deposito_row;
			$penarikan_total += $penarikan_row;
			$deposito_row_total += $sub_total;

			$html .= '
			<tr>
				<td class="h_tengah">'.$no++.'</td>
				<td>'.$jenis->jns_deposito.'</td>
				<td class="h_kanan">'. number_format($deposito_row).'</td>
				<td class="h_kanan">'. number_format($penarikan_row).'</td>
				<td class="h_kanan">'. number_format($sub_total).'</td>
			</tr>';
		}
		$html .= '
		<tr class="header_kolom">
			<td colspan="2" class="h_tengah"><strong>Jumlah Total</strong></td>
			<td class="h_kanan"><strong>'.number_format($deposito_total).'</strong></td>
			<td class="h_kanan"><strong>'.number_format($penarikan_total).'</strong></td>
			<td class="h_kanan"><strong>'.number_format($deposito_row_total).'</strong></td>
		</tr>';
		$html .= '</table>';

		echo $html;
		die();
	}
}