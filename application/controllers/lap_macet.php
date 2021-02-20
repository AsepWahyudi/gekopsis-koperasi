<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_macet extends OperatorController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_macet_m');
		$this->load->model('bunga_m');
	}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Kredit Macet';

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

		if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
			//
		} else {
			$_GET['tgl_dari'] = date('Y') . '-01-01';
			$_GET['tgl_samp'] = date('Y') . '-12-31';
		}

		$config = array();
		$config["base_url"] = base_url() . "lap_macet/index/halaman";
		$config["total_rows"] = $this->lap_macet_m->get_jml_data_tempo(); // banyak data
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
		$this->data["data_tempo"] = $this->lap_macet_m->get_data_tempo($config["per_page"], $offset); // panggil seluruh data aanggota
		$this->data["conf_bunga"] = $this->bunga_m->get_key_val();
		$this->data["halaman"] = $this->pagination->create_links();
		$this->data["offset"] = $offset;
		
		$this->data['isi'] = $this->load->view('lap_macet_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);

	}

	function cetak() {

		$data_tempo = $this->lap_macet_m->lap_data_tempo();
		$conf_bunga = $this->bunga_m->get_key_val();
		if($data_tempo == FALSE) {
			echo 'Data Kosong';
			exit();
			//redirect('lap_tempo');
		}

		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$tanggal = $_GET['periode']; 
		} else {
			$tanggal = date('Y-m'); 
		}

		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$txt_periode_arr = explode('-', $tanggal);
			if(is_array($txt_periode_arr)) {
				$periode = 'Periode '.$txt_periode_arr['1'] . ' ' . $txt_periode_arr['0'];
				$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];
				$vlabel="Periode ";
			}
		} else {
			$txt_periode =" ";
			$vlabel= " ";
		}

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
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Kredit Macet '.$vlabel . $txt_periode .' </span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
		$html .= '
		<table width="100%" cellspacing="0" cellpadding="3" border="1">
		<tr class="header_kolom">
			<th style="width:5%;" > No. </th>
			<th style="width:10%;"> Kode Pinjam</th>
			<th style="width:10%;"> Nama</th>
			<th style="width:10%;"> Tanggal Pinjam  </th>
			<th style="width:10%;"> Tanggal Tempo  </th>
			<th style="width:10%;"> Lama Pinjam  </th>
			<th style="width:8%; "> Mulai Bulan Tertunggak </th>
			<th style="width:8%; "> Total Bulan Tertunggak </th>
			<th style="width:10%;"> Jumlah Tagihan  </th>
			<th style="width:10%;"> Sudah <br> Dibayar  </th>
			<th style="width:10%;"> Sisa Tagihan  </th>
		</tr>';

		$no = 1;
		$jml_tagihan = 0;
		$jml_dibayar = 0;
		$jml_sisa = 0;
		$jmlblntunggak = 0;
		$mulainunggak="-";
		foreach ($data_tempo as $rows) {

			$tgl_pinjam = explode(' ', $rows->tgl_pinjam);
			$tgl_pinjam = jin_date_ina($tgl_pinjam[0],'p');

			$tgl_tempo = explode(' ', $rows->tempo);
			$tgl_tempo1 = jin_date_ina($tgl_tempo[0],'p');

			$jml_bayar = $this->general_m->get_jml_bayar($rows->id); 
			$jml_denda = $this->general_m->get_jml_denda($rows->id); 
			$total_tagihan = $rows->tagihan + $jml_denda->total_denda;
			$sisa_tagihan = $total_tagihan - $jml_bayar->total;

			$jml_tagihan += $total_tagihan;
			$jml_dibayar += $jml_bayar->total;
			$jml_sisa += $sisa_tagihan;

			$denda_hari = $conf_bunga['denda_hari'];
			$jmlangscurrent = 0;
			for ($z=1; $z <= $rows->lama_angsuran; $z++) { 
                $tgl = date("d", strtotime($rows->tgl_pinjam));
                $bln = date("m", strtotime($rows->tgl_pinjam));
                $thn = date("Y", strtotime($rows->tgl_pinjam));
                $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
                $tgl_tempo_var = $tglpinjam;
                $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$z." month"));
                $date_now = date("Y-m-d");
                if(date("m",strtotime($tgl_tempo)) == date("m",strtotime($date_now))){
                    if($date_now > $tgl_tempo){
						$jmlangscurrent = $z;
                    } else {
						$jmlangscurrent = $z -1;
					} 
				
					if ($jmlangscurrent > $rows->bulan_sdh_angsur) {
						$jmlblntunggak = $jmlangscurrent - $rows->bulan_sdh_angsur;
						if ($rows->bulan_sdh_angsur > 0) {
							$jmltgk = $rows->bulan_sdh_angsur + 1;
							$mulainunggak = date("m", strtotime($tglpinjam . " +".$jmltgk." month"));
							$mulainunggak = jin_nama_bulan($mulainunggak);
							
						} else {
							$mulainunggak = date("m", strtotime($rows->tgl_pinjam . " +1 month"));
							$mulainunggak = jin_nama_bulan($mulainunggak);
						}
					} 	
				
					break;
					
                } 
			}

      if ($jmlblntunggak > 0) {
			$html .= '
			<tr>
				<td class="h_tengah">'.$no++.'</td>
				<td class="h_tengah">'.$rows->nomor_pinjaman.'</td>
				<td class="h_kiri">'.$rows->nama.'</td>
				<td class="h_tengah">'.$tgl_pinjam.'</td>
				<td class="h_tengah">'.$tgl_tempo1.'</td>
				<td class="h_tengah">'.$rows->lama_angsuran.' Bulan</td>
				<td class="h_tengah">'.$mulainunggak.'</td>
				<td class="h_tengah">'.$jmlblntunggak.' Bulan</td>
				<td class="h_kanan">'.number_format(nsi_round($total_tagihan),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($jml_bayar->total),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
			</tr>';
    }
    else {
      $jml_tagihan = $jml_tagihan - $total_tagihan;
  $jml_dibayar = $jml_dibayar - $jml_bayar->total;
  $jml_sisa = $jml_sisa - $sisa_tagihan;
    }
  }

		$html .= '
		<tr class="header_kolom">
			<td colspan="8" class="h_tengah"><strong>Jumlah Total</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tagihan),2,',','.').'</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_dibayar),2,',','.').'</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_sisa),2,',','.').'</strong></td>
		</tr>';
		$html.='</table>';
		$pdf->nsi_html($html);
		$pdf->Output('lap_macet'.date('Ymd_His') . '.pdf', 'I');
	} 

	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$data_tempo = $this->lap_macet_m->lap_data_tempo();
		$conf_bunga = $this->bunga_m->get_key_val();
		if($data_tempo == FALSE) {
			echo 'Data Kosong';
			exit();
			//redirect('lap_tempo');
		}

		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$tanggal = $_GET['periode']; 
		} else {
			$tanggal = date('Y-m'); 
		}

		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$txt_periode_arr = explode('-', $tanggal);
			if(is_array($txt_periode_arr)) {
				$periode = 'Periode '.$txt_periode_arr['1'] . ' ' . $txt_periode_arr['0'];
				$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];
				$vlabel="Periode ";
			}
		} else {
			$txt_periode =" ";
			$vlabel= " ";
		}


		$html = '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		<span class="txt_judul">Laporan Kredit Macet '.$vlabel.' '.$txt_periode.' </span>';
		$html .= '
		<table width="100%" cellspacing="0" cellpadding="3" border="1">
		<tr class="header_kolom">
			<th style="width:5%;" > No. </th>
			<th style="width:10%;"> Nama</th>
			<th style="width:10%;"> Kode Pinjam</th>
			<th style="width:10%;"> Tanggal Pinjam  </th>
			<th style="width:10%;"> Tanggal Tempo  </th>
			<th style="width:10%;"> Lama Pinjam  </th>
			<th style="width:8%; "> Mulai Bulan Tertunggak </th>
			<th style="width:8%; "> Total Bulan Tertunggak </th>
			<th style="width:15%;"> Jumlah Tagihan  </th>
			<th style="width:15%;"> Sudah <br> Dibayar  </th>
			<th style="width:15%;"> Sisa Tagihan  </th>
		</tr>';

		$no = 1;
		$jml_tagihan = 0;
		$jml_dibayar = 0;
		$jml_sisa = 0;
		$jmlblntunggak = 0;
		$mulainunggak="-";
		foreach ($data_tempo as $rows) {

			$tgl_pinjam = explode(' ', $rows->tgl_pinjam);
			$tgl_pinjam = jin_date_ina($tgl_pinjam[0],'p');

			$tgl_tempo = explode(' ', $rows->tempo);
			$tgl_tempo1 = jin_date_ina($tgl_tempo[0],'p');

			$jml_bayar = $this->general_m->get_jml_bayar($rows->id); 
			$jml_denda = $this->general_m->get_jml_denda($rows->id); 
			$total_tagihan = $rows->tagihan + $jml_denda->total_denda;
			$sisa_tagihan = $total_tagihan - $jml_bayar->total;

			$jml_tagihan += $total_tagihan;
			$jml_dibayar += $jml_bayar->total;
			$jml_sisa += $sisa_tagihan;

			$denda_hari = $conf_bunga['denda_hari'];
			$jmlangscurrent = 0;
			for ($z=1; $z <= $rows->lama_angsuran; $z++) { 
                $tgl = date("d", strtotime($rows->tgl_pinjam));
                $bln = date("m", strtotime($rows->tgl_pinjam));
                $thn = date("Y", strtotime($rows->tgl_pinjam));
                $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
                $tgl_tempo_var = $tglpinjam;
                $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$z." month"));
                $date_now = date("Y-m-d");
                if(date("m",strtotime($tgl_tempo)) == date("m",strtotime($date_now))){
                    if($date_now > $tgl_tempo){
						$jmlangscurrent = $z;
                    } else {
						$jmlangscurrent = $z -1;
					} 
				
					if ($jmlangscurrent > $rows->bulan_sdh_angsur) {
						$jmlblntunggak = $jmlangscurrent - $rows->bulan_sdh_angsur;
						if ($rows->bulan_sdh_angsur > 0) {
							$jmltgk = $rows->bulan_sdh_angsur + 1;
							$mulainunggak = date("m", strtotime($tglpinjam . " +".$jmltgk." month"));
							$mulainunggak = jin_nama_bulan($mulainunggak);
							
						} else {
							$mulainunggak = date("m", strtotime($rows->tgl_pinjam . " +1 month"));
							$mulainunggak = jin_nama_bulan($mulainunggak);
						}
					} 	
				
					break;
					
                } 
			}

			$html .= '
			<tr>
				<td class="h_tengah">'.$no++.'</td>
				<td class="h_kiri">'.$rows->nama.'</td>
				<td class="h_tengah">'.$rows->nomor_pinjaman.'</td>
				<td class="h_tengah">'.$tgl_pinjam.'</td>
				<td class="h_tengah">'.$tgl_tempo1.'</td>
				<td class="h_tengah">'.$rows->lama_angsuran.' Bulan</td>
				<td class="h_tengah">'.$mulainunggak.'</td>
				<td class="h_tengah">'.$jmlblntunggak.' Bulan</td>
				<td class="h_kanan">'.number_format(nsi_round($total_tagihan),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($jml_bayar->total),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
			</tr>';
		}

		$html .= '
		<tr class="header_kolom">
			<td colspan="8" class="h_tengah"><strong>Jumlah Total</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tagihan),2,',','.').'</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_dibayar),2,',','.').'</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_sisa),2,',','.').'</strong></td>
		</tr>';
		$html.='</table>';

		echo $html;
		die();
	}
}