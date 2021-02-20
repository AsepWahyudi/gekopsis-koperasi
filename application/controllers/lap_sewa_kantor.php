<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_sewa_kantor extends OperatorController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('lap_sewa_kantor_m');
		$this->load->model('general_m');
	}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Sewa Kantor';

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

		$config = array();
		$config["base_url"] = base_url() . "lap_sewa_kantor/index/halaman";
		if (count($_GET) > 0) $config['suffix'] = '?' . http_build_query($_GET, '', "&");
		$config['first_url'] = $config['base_url'].'?'.http_build_query($_GET);
		$config["total_rows"] = $this->lap_sewa_kantor_m->get_jml_data();
		$config["per_page"] = 20;
		$config["uri_segment"] = 4;
		$config['num_links'] = 10;
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

		$this->data["data_sewakantor"] = $this->lap_sewa_kantor_m->get_data_sewakantor($config["per_page"], $offset);
		$this->data["data_cabang"] = $this->lap_sewa_kantor_m->get_data_cabang($config["per_page"], $offset);
		$this->data["halaman"] = $this->pagination->create_links();
		$this->data["offset"] = $offset;
		$this->data['isi'] = $this->load->view('lap_sewaktr_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function cetak() {

		$transaksi = $this->lap_trans_kas_m->lap_trans_kas();
		if($transaksi == FALSE) {
			//redirect('lap_trans_kas');
			echo 'DATA KOSONG';
			exit();
		}

		$saldo_sblm = $this->lap_trans_kas_m->get_saldo_sblm();

		$tgl_dari = $_REQUEST['tgl_dari'];
		$tgl_samp = $_REQUEST['tgl_samp'];
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;

		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('L');

		$html = '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Saldo Kas Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
		$html.='<table cellspacing="0" cellpadding="3" border="1" nobr="true">
		<tr class="header_kolom">
			<th class="h_tengah" style="width:4%;" > No. </th>
			<th class="h_tengah" style="width:8%;"> Tanggal </th>
			<th class="h_tengah" style="width:15%;"> Jenis Transaksi </th>
			<th class="h_tengah" style="width:23%;"> Keterangan </th>
			<th class="h_tengah" style="width:10%;"> Dari Kas  </th>
			<th class="h_tengah" style="width:10%;"> Untuk Kas  </th>
			<th class="h_tengah" style="width:10%;"> Debet </th>
			<th class="h_tengah" style="width:10%;"> Kredit </th>
			<th class="h_tengah" style="width:10%;"> Saldo  </th>
		</tr>';
		$html .='<tr bgcolor="#FFFFEE">
						<td class="h_kanan" colspan="8"> <strong>SALDO SEBELUMNYA</strong></td>
						<td class="h_kanan" ><strong>'.number_format(nsi_round($saldo_sblm),2,',','.').'</strong></td>
					</tr>';
		$no = 1;
		$saldo = $saldo_sblm;
		foreach ($transaksi as $row) {
			$saldo += ($row->debet - $row->kredit);

			$tgl = explode(' ', $row->tgl);
			$txt_tanggal = jin_date_ina($tgl[0],'p');
			$dari_kas = $this->lap_trans_kas_m->get_nama_kas_id($row->dari_kas);
			$untuk_kas = $this->lap_trans_kas_m->get_nama_kas_id($row->untuk_kas);
			$nm_akun = $this->lap_trans_kas_m->get_nama_akun_id($row->transaksi);

			switch ($row->tbl) {
				case 'A':
				$kode = 'TPJ';
				break;
				
				case 'B':
				$kode = 'TBY';
				break;
				
				case 'C':
				if($row->dari_kas == NULL) {
					$kode = 'TRD';
				} else {
					$kode = 'TRK';
				}
				break;
				
				case 'D':
				$kode = 'TRF';
				if($row->dari_kas == NULL) {
					$ket = 'Pemasukan Kas';
					$kode = 'TKD';
				}
				if($row->untuk_kas == NULL) {
					$kode = 'TKK';
				}
				break;
				
				default:
				$ket = '';
				$kode = '';
				break;
			}

			if ($row->dari_kas == NULL) {
				$dari_kas = '-';
			} else {
				$dari_kas = $dari_kas->nama;
			}

			if ($row->untuk_kas == NULL) {
				$untuk_kas = '-';
			} else {
				$untuk_kas = $untuk_kas->nama;
			}
			$html .= '
			<tr>
				<td class="h_tengah"> '.$no++.'</td>
				<td class="h_tengah"> '.$txt_tanggal.'</td>
				<td class="h_kiri"> '.@$nm_akun->jns_trans.'</td>
				<td class="h_kiri"> '.$row->ket.'</td>
				<td class="h_kiri"> '.$dari_kas.'</td>
				<td class="h_kiri"> '.$untuk_kas.'</td>
				<td class="h_kanan"> '.number_format(nsi_round($row->debet),2,',','.').'</td>
				<td class="h_kanan"> '.number_format(nsi_round($row->kredit),2,',','.').'</td>
				<td class="h_kanan"> '.number_format(nsi_round($saldo),2,',','.').'</td>
			</tr>';
		}

		$html.='</table>';
		$pdf->nsi_html($html);
		$pdf->Output('lap_kas'.date('Ymd_His') . '.pdf', 'I');
	} 

	function list_cabang() {
		$q = isset($_POST['q']) ? $_POST['q'] : '';
		$r = $this->uri->segment('3');
		$data   = $this->lap_sewa_kantor_m->get_data_cabang_ajax($q,$r);
		$i	= 0;
		$rows   = array(); 
		foreach ($data['data'] as $r) {
			$rows[$i]['nama'] = $r->nama_cabang;
			$rows[$i]['id'] = $r->jns_cabangid;
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}
}