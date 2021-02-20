<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_tempo extends OperatorController {

public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_tempo_m');
		$this->load->model('angsuran_m');
	}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Pembayaran Kredit';

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
		$config["base_url"] = base_url() . "lap_tempo/index/halaman";
		$config["total_rows"] = $this->lap_tempo_m->get_jml_data_tempo(); // banyak data
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
		$this->data["data_tempo"] = $this->lap_tempo_m->get_data_tempo($config["per_page"], $offset); // panggil seluruh data aanggota
		$this->data["halaman"] = $this->pagination->create_links();
		$this->data["offset"] = $offset;
		$this->data["s_wajib"] = $this->angsuran_m->get_simpanan_wajib();
		$this->data['isi'] = $this->load->view('lap_tempo_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function cetak() {
    $data_tempo = $this->lap_tempo_m->cetak_data_tempo();
    
		if($data_tempo == FALSE) {
			echo 'DATA KOSONG';
			exit();
		}
		$temp_month = "";
		$temp_year = "";
		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$tanggal = $_GET['periode']; 
			
		} else {
			$tanggal = ""; 
		}

		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$txt_periode_arr = explode('-', $tanggal);
			if(is_array($txt_periode_arr)) {
				$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];
				$vlabel="Periode ";
					
				$temp_month = date("F", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
				$temp_year =date("Y", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
			}
		} else {
			$txt_periode =" ";
			$vlabel= " ";
    }
    
    $jenis_anggota = isset($_GET['jenis_anggota_id'])?$_GET['jenis_anggota_id']:0;		

     $this->load->library('Pdf');
     $pdf = new Pdf('L', 'mm', 'A3', true, 'UTF-8', false);
	 $pdf->set_nsi_header(TRUE);
	 $width = $pdf->pixelsToUnits(850); 
	 $height = $pdf->pixelsToUnits(559);

     $pdf->AddPage('L','A3');
     $html = '<style>
	             .h_tengah {text-align: center;}
	             .h_kiri {text-align: left;}
	             .h_kanan {text-align: right;}
	             .txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
	             .header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
         		</style>
         '.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Tagihan Angsuran Pinjaman '.$vlabel . $txt_periode.' </span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';

      $html.='<table width="100%" cellspacing="0" cellpadding="3" border="1">
		<tr class="header_kolom">
			<th style="width:50px;" > No. </th>
			<th style="width:80px;"> Kode Pinjam</th>
			<th style="width:110px;"> Anggota</th>
			<th style="width:100px;"> Nomor Rekening</th>
			<th style="width:80px;"> Tanggal Pinjam  </th>
			<th style="width:80px;"> Tanggal Tempo  </th>
			<th style="width:5%;"> Lama Pinjam </th>
			<th style="width:7%;"> Simpanan Wajib  </th>
			<th style="width:7%";> Angsuran Pokok </th>
			<th style="width:7%;"> Angsuran Bunga </th>
			<th style="width:8%;"> Admin Angsuran  </th>
			<th style="width:8%;"> Jumlah Tagihan  </th>
			<th style="width:7%;"> Tunggakan  </th>
			<th style="width:8%;"> Sisa <br> Tagihan  </th>
		</tr>';

		$no = 1;
		$jml_tagihan = 0;
		$jml_dibayar = 0;
		$jml_sisa = 0;
		$jml_tunggakan = 0;
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		$ketemu = "";
		foreach ($data_tempo as $rows) {

			if ($tanggal != "") {
				for ($i=1; $i <= $rows->lama_angsuran; $i++) { 
					if($rows->tenor == 'Bulan'){
						$temp_tgl_tempo_var = substr($rows->tgl_pinjam, 0, 10);
						$temp_tgl_tempo = date("Y-m-d", strtotime($temp_tgl_tempo_var . " +".$i." month"));
					}
					else if($rows->tenor == 'Minggu'){
						$temp_tgl_tempo_var = $rows->tgl_pinjam;
						$temp_tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." week"));
					}
					else{
						$tgl_tempo_var = $rows->tgl_pinjam;
						$temp_tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." day"));
					}
					$month=date("F",strtotime($temp_tgl_tempo));
					$year=date("Y",strtotime($temp_tgl_tempo));
					if ($temp_month === $month && $temp_year === $year) {
						$ketemu = 'Y';
						break;
					} else {
						$ketemu = 'N';
					}
				}
			}
			
			if ($ketemu == 'Y' || $ketemu == "") {	
						$anggota = $this->general_m->get_data_anggota($rows->anggota_id);
						$tgl_pinjam = explode(' ', $rows->tgl_pinjam);
						$tgl_pinjam = jin_date_ina($tgl_pinjam[0],'p');

						$tgl_tempo = explode(' ', $rows->tempo);
						$tgl_tempo = jin_date_ina($tgl_tempo[0],'p');

						$jml_bayar = $this->general_m->get_jml_bayar($rows->id); 
						$jml_denda = $this->general_m->get_jml_denda($rows->id); 
						$total_tunggakan = 0;
						$tunggakan = 0;
						if ($rows->jenis_pinjaman == 9) {
              $total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $rows->adminangsuran;
              $sisa_tagihan = ($total_tagihan * $rows->lama_angsuran) - $jml_bayar->total;
            } else {
              $total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $s_wajib->jumlah;
              $sisa_tagihan = ($rows->pokok_angsuran * $rows->lama_angsuran) - $jml_bayar->total;
              
            }

            if ($rows->bln_sudah_angsur != 0) {
              $tunggakan = ($rows->ags_per_bulan + $s_wajib->jumlah) * $rows->bln_sudah_angsur;
              if ($tunggakan > $jml_bayar->total){
                $total_tunggakan = $tunggakan - $jml_bayar->total;
              } else {
                $total_tunggakan = 0;
              }
            } else {
              $tunggakan = ($rows->ags_per_bulan + $s_wajib->jumlah) * $rows->selisih_bulan;
              if ($tunggakan > $jml_bayar->total){
                $total_tunggakan = $tunggakan - $jml_bayar->total;
              } else {
                $total_tunggakan = 0;
              }
            }

						$jml_tagihan += $total_tagihan;
						$jml_dibayar += $jml_bayar->total;
						$jml_sisa += $sisa_tagihan;
						$jml_tunggakan += $total_tunggakan;

						$html.='
							<tr>
								<td class="h_tengah"> '.$no++.'</td>
								<td class="h_tengah"> '.$rows->nomor_pinjaman.'</td>
								<td> '.$anggota->ktp.'<br> '.$anggota->nama.'</td>
								<td> '.$anggota->nomor_rekening.'</td>
								<td class="h_tengah"> '.$tgl_pinjam.'</td>
								<td class="h_tengah"> '.$tgl_tempo.'</td>
								<td class="h_tengah"> '.$rows->lama_angsuran.' bln</td>
                <td class="h_kanan"> '.(($rows->jenis_pinjaman == 9)?0:number_format(nsi_round($s_wajib->jumlah),2,',','.')).'</td>
                <td class="h_kanan"> '.number_format(nsi_round($rows->pokok_angsuran),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($rows->bunga_pinjaman),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($rows->adminangsuran),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($total_tagihan),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($tunggakan),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
							</tr>
						';
				}
		}
	$html.='
			<tr class="header_kolom">
				<td colspan="11" class="h_tengah"><strong>Jumlah Total</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tagihan)).'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tunggakan)).'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_sisa)).'</strong></td>
			</tr>';
        $html.='</table>';
        $pdf->nsi_html($html);
        $pdf->Output('lap_tempo'.date('Ymd_His') . '.pdf', 'I');
	} 
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$data_tempo = $this->lap_tempo_m->excel_data_tempo();

		if($data_tempo == FALSE) {
			echo 'DATA KOSONG';
			exit();
		}
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();

		$temp_month = "";
		$temp_year = "";
		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$tanggal = $_GET['periode']; 
			
		} else {
			$tanggal = ""; 
		}

		if(isset($_GET['periode']) && $_GET['periode'] !="") {
			$txt_periode_arr = explode('-', $tanggal);
			if(is_array($txt_periode_arr)) {
				$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];
				$vlabel="Periode ";
					
				$temp_month = date("F", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
				$temp_year =date("Y", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
			}
		} else {
			$txt_periode =" ";
			$vlabel= " ";
		}

     $html = '<style>
	             .h_tengah {text-align: center;}
	             .h_kiri {text-align: left;}
	             .h_kanan {text-align: right;}
	             .txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
	             .header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
         		</style>
         Laporan Tagihan Angsuran Pinjaman '.$vlabel . $txt_periode.' ';
      $html.='<table width="100%" cellspacing="0" cellpadding="3" border="1">
		<tr class="header_kolom">
			<th style="width:5%;" > No. </th>
			<th style="width:9%;"> Kode Pinjam</th>
			<th style="width:13%;"> Anggota</th>
			<th style="width:8%;"> Nomor Rekening</th>
			<th style="width:8%;"> Tanggal Pinjam  </th>
			<th style="width:8%;"> Tanggal Tempo  </th>
			<th style="width:5%;"> Lama Pinjam </th>
			<th style="width:7%;"> Simpanan Wajib  </th>
			<th style="width:7%";> Angsuran Pokok  </th>
			<th style="width:7%;"> Angsuran Bunga  </th>
			<th style="width:7%;"> Admin Angsuran  </th>
			<th style="width:8%;"> Jumlah Tagihan  </th>
			<th style="width:7%;"> Tunggakan  </th>
			<th style="width:8%;"> Sisa <br> Tagihan  </th>
		</tr>';

		$no = 1;
		$jml_tagihan = 0;
		$jml_dibayar = 0;
		$jml_sisa = 0;
		$jml_tunggakan = 0;
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		$ketemu = "";
		foreach ($data_tempo as $rows) {

			if ($tanggal != "") {
				for ($i=1; $i <= $rows->lama_angsuran; $i++) { 
					if($rows->tenor == 'Bulan'){
						$temp_tgl_tempo_var = substr($rows->tgl_pinjam, 0, 10);
						$temp_tgl_tempo = date("Y-m-d", strtotime($temp_tgl_tempo_var . " +".$i." month"));
					}
					else if($rows->tenor == 'Minggu'){
						$temp_tgl_tempo_var = $rows->tgl_pinjam;
						$temp_tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." week"));
					}
					else{
						$tgl_tempo_var = $rows->tgl_pinjam;
						$temp_tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." day"));
					}
					$month=date("F",strtotime($temp_tgl_tempo));
					$year=date("Y",strtotime($temp_tgl_tempo));
					if ($temp_month === $month && $temp_year === $year) {
						$ketemu = 'Y';
						break;
					} else {
						$ketemu = 'N';
					}
				}
			}
			
			if ($ketemu == 'Y' || $ketemu == "") {	
						$anggota = $this->general_m->get_data_anggota($rows->anggota_id);
						$tgl_pinjam = explode(' ', $rows->tgl_pinjam);
						$tgl_pinjam = jin_date_ina($tgl_pinjam[0],'p');

						$tgl_tempo = explode(' ', $rows->tempo);
						$tgl_tempo = jin_date_ina($tgl_tempo[0],'p');

						$jml_bayar = $this->general_m->get_jml_bayar($rows->id); 
						$jml_denda = $this->general_m->get_jml_denda($rows->id); 
						$total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $s_wajib->jumlah;
						$sisa_tagihan = ($rows->pokok_angsuran * $rows->lama_angsuran) - $jml_bayar->total;
						$total_tunggakan = 0;
						$tunggakan = 0;
						if ($rows->jenis_pinjaman == 9) {
              $total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $rows->adminangsuran;
              $sisa_tagihan = ($total_tagihan * $rows->lama_angsuran) - $jml_bayar->total;
            } else {
              $total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $s_wajib->jumlah;
              $sisa_tagihan = ($rows->pokok_angsuran * $rows->lama_angsuran) - $jml_bayar->total;
              
            }

            if ($rows->bln_sudah_angsur != 0) {
              $tunggakan = ($rows->ags_per_bulan + $s_wajib->jumlah) * $rows->bln_sudah_angsur;
              if ($tunggakan > $jml_bayar->total){
                $total_tunggakan = $tunggakan - $jml_bayar->total;
              } else {
                $total_tunggakan = 0;
              }
            } else {
              $tunggakan = ($rows->ags_per_bulan + $s_wajib->jumlah) * $rows->selisih_bulan;
              if ($tunggakan > $jml_bayar->total){
                $total_tunggakan = $tunggakan - $jml_bayar->total;
              } else {
                $total_tunggakan = 0;
              }
            }

						$jml_tagihan += $total_tagihan;
						$jml_dibayar += $jml_bayar->total;
						$jml_sisa += $sisa_tagihan;
						$jml_tunggakan += $total_tunggakan;

						$html.='
							<tr>
								<td class="h_tengah"> '.$no++.'</td>
								<td class="h_tengah"> '.$rows->nomor_pinjaman.'</td>
								<td> '.$anggota->ktp.'<br> '.$anggota->nama.'</td>
								<td> '.$anggota->nomor_rekening.'</td>
								<td class="h_tengah"> '.$tgl_pinjam.'</td>
								<td class="h_tengah"> '.$tgl_tempo.'</td>
								<td class="h_tengah"> '.$rows->lama_angsuran.' bln</td>
								<td class="h_kanan"> '.number_format(nsi_round($s_wajib->jumlah),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($rows->pokok_angsuran),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($rows->bunga_pinjaman),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($rows->adminangsuran),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($total_tagihan),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($tunggakan),2,',','.').'</td>
								<td class="h_kanan"> '.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
							</tr>
						';
				}
		}
	$html.='
			<tr class="header_kolom">
				<td colspan="11" class="h_tengah"><strong>Jumlah Total</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tagihan),2,',','.').'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tunggakan),2,',','.').'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_sisa),2,',','.').'</strong></td>
			</tr>';
        $html.='</table>';

		echo $html;
		die();

	}
}