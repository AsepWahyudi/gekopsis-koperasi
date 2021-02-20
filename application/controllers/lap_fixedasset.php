<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_fixedasset extends OperatorController {
public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_fixedasset_m');
		//error_reporting(0);
	}	

	public function index() {
    $periode = isset($_GET['periode'])?$_GET['periode'].'-01':date('Y-m-d');
    $periode = substr(jin_date_ina($periode,'p'),3,strlen(jin_date_ina($periode,'p')));
    $kode_asset = isset($_GET['kode_asset'])?$_GET['kode_asset']:'';
    $nama_asset = isset($_GET['nama_asset'])?$_GET['nama_asset']:'';
    $kat_asset = isset($_GET['kat_asset'])?$_GET['kat_asset']:'';
    
    $this->load->library("pagination");
		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Data Fixed Asset';

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
		$this->data["data_asset"] = $this->lap_fixedasset_m->get_data(); 
		$this->data['periode'] = $periode;
		$this->data['kode_asset'] = $kode_asset;
		$this->data['nama_asset'] = $nama_asset;
		$this->data['kat_asset'] = $kat_asset;
		$this->data['isi'] = $this->load->view('lap_fixedasset_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function list_kat_asset() {
		$q = isset($_POST['q']) ? $_POST['q'] : '';
		$r = $this->uri->segment('3');
		$data   = $this->lap_fixedasset_m->get_data_kasset_ajax($q,$r);
		$i	= 0;
		$rows   = array(); 
		foreach ($data['data'] as $r) {
			$rows[$i]['nama'] = $r->kategori_asset;
			$rows[$i]['id'] = $r->kategori_asset_id;
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	function cetak() {
    $data = $this->lap_fixedasset_m->get_data();
    $periode = isset($_GET['periode'])?$_GET['periode'].'-01':date('Y-m-d');
    $periode = substr(jin_date_ina($periode,'p'),3,strlen(jin_date_ina($periode,'p')));
		if($data == FALSE) {
			//redirect('lap_anggota');
			echo 'DATA KOSONG';
			exit();
		}

		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A1', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('L','A3');
		$html = '';
		$html .= '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 15pt; font-weight: bold; padding-bottom: 12px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Fixed Asset <br>Periode: '.$periode.'<br><br></span>', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
			<table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
				<tr class="header_kolom">
        <th style="width:10%;" > Kode Asset</th>
        <th style="width:15%;"> Nama Asset </th>
        <th style="width:10%;"> Lokasi Asset </th>
        <th style="width:10%;"> Kategori Asset </th>
        <th style="width:5%;"> Status  </th>
        <th style="width:6%;"> Tanggal Efektif  </th>
        <th style="width:8%;"> Harga Perolehan </th>
        <th style="width:6%;"> Usia Fiskal </th>
        <th style="width:10%;"> Akumulasi Penyusutan </th>					
        <th style="width:10%;"> Nilai Buku </th>					
        <th style="width:10%;"> Depresiasi Per Bulan </th>		
				</tr>';
		$no =1;
		$batas = 1;
		foreach ($data as $row) {
			if($batas == 0) {
				$html .= '
				<tr class="header_kolom" pagebreak="true">
					<th style="width:10%;" > Kode Asset</th>
					<th style="width:15%;"> Nama Asset </th>
					<th style="width:10%;"> Lokasi Asset </th>
					<th style="width:10%;"> Kategori Asset </th>
					<th style="width:5%;"> Status  </th>
					<th style="width:8%;"> Tanggal Efektif  </th>
					<th style="width:8%;"> Harga Perolehan </th>
					<th style="width:6%;"> Usia Fiskal </th>
					<th style="width:10%;"> Akumulasi Penyusutan </th>					
					<th style="width:10%;"> Nilai Buku </th>					
					<th style="width:10%;"> Depresiasi Per Bulan </th>			
            </tr>';
            $batas = 1;
			}
      $batas++;
      $kat_assets = $this->general_m->get_kategori_asset($row->kategori_asset);
			$html .= '
			<tr nobr="true">
				<td class="h_kiri">'.$row->kode_asset.' </td>
				<td class="h_kiri">'.$row->nama_asset.'</td>
				<td class="h_kiri">'.$row->lokasi_asset.'</td>
				<td class="h_kiri">'.$kat_assets[0]->kategori_asset.'</td>
				<td class="h_kiri">'.$row->status.'</td>
				<td class="h_kiri">'.jin_date_ina($row->tanggal_efektif,'p').'</td>
				<td class="h_kanan">'.$row->harga_perolehan.'</td>
				<td class="h_kanan">'.$row->usia_fiskal.'</td>
				<td class="h_kanan">'.$row->akumulasi_penyusutan.'</td>
				<td class="h_kanan">'.$row->nilai_buku.'</td>
				<td class="h_kanan">'.$row->depresia.'</td>
			</tr>'; 
		}
		$html .= '</table>';
		$pdf->nsi_html($html);
		$pdf->Output('lap_anggota'.date('Ymd_His') . '.pdf', 'I');
	} 

	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$data = $this->lap_fixedasset_m->get_data();
    $periode = isset($_GET['periode'])?$_GET['periode'].'-01':date('Y-m-d');
    $periode = substr(jin_date_ina($periode,'p'),3,strlen(jin_date_ina($periode,'p')));
		if($data == FALSE) {
			//redirect('lap_anggota');
			echo 'DATA KOSONG';
			exit();
		}
		$html = '';
		$html .= '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 15pt; font-weight: bold; padding-bottom: 12px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		<span class="txt_judul">Laporan Fixed Asset <br>Periode: '.$periode.'<br><br></span>
			<table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
				<tr class="header_kolom">
        <th style="width:10%;" > Kode Asset</th>
        <th style="width:15%;"> Nama Asset </th>
        <th style="width:10%;"> Lokasi Asset </th>
        <th style="width:10%;"> Kategori Asset </th>
        <th style="width:5%;"> Status  </th>
        <th style="width:6%;"> Tanggal Efektif  </th>
        <th style="width:8%;"> Harga Perolehan </th>
        <th style="width:6%;"> Usia Fiskal </th>
        <th style="width:10%;"> Akumulasi Penyusutan </th>					
        <th style="width:10%;"> Nilai Buku </th>					
        <th style="width:10%;"> Depresiasi Per Bulan </th>		
				</tr>';
		$no =1;
		$batas = 1;
		foreach ($data as $row) {
			if($batas == 0) {
				$html .= '
				<tr class="header_kolom" pagebreak="true">
					<th style="width:10%;" > Kode Asset</th>
					<th style="width:15%;"> Nama Asset </th>
					<th style="width:10%;"> Lokasi Asset </th>
					<th style="width:10%;"> Kategori Asset </th>
					<th style="width:5%;"> Status  </th>
					<th style="width:8%;"> Tanggal Efektif  </th>
					<th style="width:8%;"> Harga Perolehan </th>
					<th style="width:6%;"> Usia Fiskal </th>
					<th style="width:10%;"> Akumulasi Penyusutan </th>					
					<th style="width:10%;"> Nilai Buku </th>					
					<th style="width:10%;"> Depresiasi Per Bulan </th>			
            </tr>';
            $batas = 1;
			}
      $batas++;
      $kat_assets = $this->general_m->get_kategori_asset($row->kategori_asset);
			$html .= '
			<tr nobr="true">
				<td class="h_kiri">'.$row->kode_asset.' </td>
				<td class="h_kiri">'.$row->nama_asset.'</td>
				<td class="h_kiri">'.$row->lokasi_asset.'</td>
				<td class="h_kiri">'.$kat_assets[0]->kategori_asset.'</td>
				<td class="h_kiri">'.$row->status.'</td>
				<td class="h_kiri">'.jin_date_ina($row->tanggal_efektif,'p').'</td>
				<td class="h_kanan">'.$row->harga_perolehan.'</td>
				<td class="h_kanan">'.$row->usia_fiskal.'</td>
				<td class="h_kanan">'.$row->akumulasi_penyusutan.'</td>
				<td class="h_kanan">'.$row->nilai_buku.'</td>
				<td class="h_kanan">'.$row->depresia.'</td>
			</tr>'; 
		}
		$html .= '</table>';

		echo $html;
		die();

	}
}