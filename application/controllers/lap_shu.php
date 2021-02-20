<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_shu extends OperatorController {

public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('lap_shu_m');
		$this->load->model('lap_laba_m');
		$this->load->model('lap_shu_anggota_m');
	}	

	public function index() {
		$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
		$tgl_dari = isset($_GET['tgl_dari'])?$_GET['tgl_dari']:date('Y') . '-01-01';
		$tgl_samp = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Sisa Hasil Usaha';
		
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
			$this->data['jml_tagihan'] = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp);
			$this->data['jml_angsuran'] = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp);
			$this->data['jml_denda'] = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp);
			$this->data['data_dapat'] = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp);
			$this->data['data_biaya'] = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp);
			
		}

		if ($jenis_laporan == 2){
			$this->data['jml_pinjaman'] = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['jml_tagihan'] = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['jml_angsuran'] = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['jml_denda'] = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['data_dapat'] = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp,$jenis_laporan);
			$this->data['data_biaya'] = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp,$jenis_laporan);
		}
			
		
		//$this->data['data_pasiva'] = $this->lap_shu_m->get_data_akun_pasiva();

		$this->data['isi'] = $this->load->view('lap_shu_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);

	}

	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;

		$tgl_dari = $_GET['tgl_dari'];
		$tgl_samp = $_GET['tgl_samp'];

		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
		$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;

		$anggota = $this->lap_shu_anggota_m->lap_data_anggota();
		$data_jns_simpanan = $this->lap_shu_anggota_m->get_jenis_simpan();

		if(empty($_GET['js_usaha']) && empty($_GET['js_modal']) && empty($_GET['tot_pendpatan']) && empty($_GET['tot_simpanan']) ) {
			echo 'Data Kosong';
			//redirect('lap_shu');
			exit();
		}

		$js_usaha = $_GET['js_usaha'];
		$tot_pendpatan = $_GET['tot_pendpatan'];

		$js_modal = $_GET['js_modal'];
		$tot_simpanan = $_GET['tot_simpanan'];

        $html = '';
        $html .= '
            <style>
                .h_tengah {text-align: center;}
                .h_kiri {text-align: left;}
                .h_kanan {text-align: right;}
                .txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 12px;}
                .header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
            </style>
            <span class="txt_judul">Laporan SHU Anggota <br> Periode '.$tgl_periode_txt.' </span>
            <table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
	            <tr class="header_kolom">
		            <th style="width:5%;" > No </th>
		            <th style="width:30%;"> Identitas  </th>
		            <th style="width:65%;" colspan="2"> Pembagian SHU </th>
            </tr>';
			$no =1;
			$batas = 1;
			foreach ($anggota as $row) {
				if($batas == 0) {
					$html .= '
					<tr class="header_kolom" pagebreak="false">
		            <th style="width:5%;" > No </th>
		            <th style="width:30%;"> Identitas  </th>
		            <th style="width:65%;" colspan="2"> Pembagian SHU </th>
	            </tr>';
	            $batas = 1;
				}
				$batas++;
			
			//pinjaman
			$pinjaman = $this->lap_shu_anggota_m->get_data_pinjam($row->id);
			$pinjam_id = @$pinjaman->id;
			//denda
			$denda = $this->lap_shu_anggota_m->get_jml_denda($pinjam_id);
			$tagihan= @$pinjaman->tagihan + $denda->total_denda;
			//dibayar
			$dibayar = $this->lap_shu_anggota_m->get_jml_bayar($pinjam_id);
			$sisa_tagihan = $tagihan - $dibayar->total;

			$laba_anggota = @$dibayar->total - @$pinjaman->jumlah;

			//jabatan
			if ($row->jabatan_id == "1"){
				$jabatan="Pengurus";
			}else{
				$jabatan="Anggota";
			}
			// AG'.sprintf('%04d',@$row->id).'
			$html .= '
         <tr nobr="true">
			<td rowspan="2" class="h_tengah" style="vertical-align: middle ">'.$no++.' </td>
			<td rowspan="2"> 
				<table>
					<tr>
						<td>Id Anggota</td>
						<td> : '.$row->identitas.' </td>
					</tr>
					<tr>
						<td>Nama Anggota </td>
						<td> : <strong>'.@$row->nama.'</strong></td>
					</tr>
					<tr>
						<td>Jabatan </td>
						<td> : '.@$jabatan.' - '.@$row->departement.' </td>
					</tr>
					<tr>
						<td>Alamat </td>
						<td> : '.@$row->alamat.' </td>
					</tr>
					<tr>
						<td>No. HP </td>
						<td> : '.@$row->notelp.' </td>
					</tr>
				</table>
			</td>';
			$html.='<td>';
			$simpanan_arr = array();
			$simpanan_row_anggota = 0; 

			foreach ($data_jns_simpanan as $jenis) {
				$simpanan_arr[$jenis->id] = $jenis->jns_simpan;
				$nilai_s = $this->lap_shu_anggota_m->get_jml_simpanan($jenis->id, $row->id);
				$nilai_p = $this->lap_shu_anggota_m->get_jml_penarikan($jenis->id, $row->id);
				
				$simpanan_row = $nilai_s->jml_total - $nilai_p->jml_total;
				$simpanan_row_anggota += $simpanan_row;
			}

			$shu_laba = 1;
			$shu_modal = 1;

			if ($shu_laba > 0 || $shu_modal > 0 ) {
				if($tot_pendpatan > 0) {
					$shu_laba = ($laba_anggota / $tot_pendpatan) * $js_usaha;
				} else {
					$shu_laba = 0;
				}
				if($tot_simpanan > 0) {
					$shu_modal = ($simpanan_row_anggota / $tot_simpanan) * $js_modal;
				} else {
					$shu_modal = 0;
				}
			}

			$html.= '<table width="100%">
						<tr>
							<td colspan="3"><strong>Jasa Usaha </strong></td>
						</tr>
						<tr>
							<td>Laba Anggota  </td>
							<td class="h_kanan">'.number_format(nsi_round($laba_anggota),2,',','.').'</td>
						</tr>
						<tr>
							<td>Total Laba </td>
							<td class="h_kanan">'.number_format(nsi_round($tot_pendpatan),2,',','.').'</td>
						</tr>
						<tr>
							<td>Jasa Usaha  </td>
							<td class="h_kanan">'.number_format(nsi_round($js_usaha),2,',','.').'</td>
						</tr>
						<tr>
							<td>SHU Jasa Usaha </td>
							<td colspan="3" class="h_kanan">'.number_format(nsi_round($shu_laba),2,',','.').'</td>
						</tr>
						</table></td>';
				$html.='<td><table width="100%">
						<tr>
							<td colspan="3"><strong>Modal Usaha </strong></td>
						</tr>
						<tr>
							<td>Simpanan Anggota</td>
							<td class="h_kanan">'.number_format($simpanan_row_anggota,2,',','.').'</td>
						</tr>
						<tr>
							<td>Total Simpanan </td>
							<td class="h_kanan">'.number_format($tot_simpanan,2,',','.').'</td>
						</tr>
						<tr>
							<td>Jasa Simpanan</td>
							<td class="h_kanan">'.number_format($js_modal,2,',','.').'</td>
						</tr>
						<tr>
							<td>SHU Jasa Modal</td>
							<td colspan="3" class="h_kanan">'.number_format($shu_modal,2,',','.').'</td>
						</tr>
						</table></td>';	
					$html.='</tr>
					<tr>
							<td><strong>SHU Diterima </strong></td>
							<td class="h_kanan"><strong>'.number_format($shu_laba + $shu_modal,2,',','.').'</strong></td>
					</tr>'; 
		}     
     $html .= '</table> <p></p>';

		if ($jenis_laporan == 1) {
			$jml_pinjaman = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_samp);
			$jml_tagihan = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp);
			$jml_angsuran = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp);
			$jml_denda = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp);
			$data_dapat = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp);
			$data_biaya = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp);
		}

		if ($jenis_laporan == 2){
			$jml_pinjaman = $this->lap_laba_m->get_jml_pinjaman($tgl_dari,$tgl_samp,$jenis_laporan);
			$jml_tagihan  = $this->lap_laba_m->get_jml_tagihan($tgl_dari,$tgl_samp,$jenis_laporan);
			$jml_angsuran = $this->lap_laba_m->get_jml_angsuran($tgl_dari,$tgl_samp,$jenis_laporan);
			$jml_denda  = $this->lap_laba_m->get_jml_denda($tgl_dari,$tgl_samp,$jenis_laporan);
			$data_dapat = $this->lap_laba_m->get_data_akun_dapat($tgl_dari,$tgl_samp,$jenis_laporan);
			$data_biaya = $this->lap_laba_m->get_data_akun_biaya($tgl_dari,$tgl_samp,$jenis_laporan);
		}
	
		$html .='<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Pembagian SHU Periode '. $tgl_periode_txt .'</p>';

		$sd_dibayar = $jml_angsuran->jml_total;
		$pinjaman = $jml_pinjaman->jml_total; 
		$laba_pinjaman = $sd_dibayar - $pinjaman;
		
		$jml_dapat = 0;
		foreach ($data_dapat as $row) {
			$jml_akun = $this->lap_shu_m->get_jml_akun($row->jns_akun_id);
			$jumlah = $jml_akun['debet'] + $jml_akun['kredit'];
			$jml_dapat += $jumlah;
		}
		
		$jml_beban = 0;
		foreach ($data_biaya as $rows) {
			$jml_akun = $this->lap_shu_m->get_jml_akun($rows->jns_akun_id);
			$jumlah = $jml_akun['debet'] + $jml_akun['kredit'];
			$jml_beban += $jumlah;
		}
		$jml_pendaptan = $laba_pinjaman + $jml_dapat;

		$shu_belum = $jml_pendaptan - $jml_beban;

		$jml_sp = $this->lap_shu_m->jml_simpanan();
		$jml_simpanan = $jml_sp->total;
		$jml_pn = $this->lap_shu_m->jml_penarikan();
		$jml_penarikan = $jml_pn->total;

		//ambil pajak 
		$opsi_val_arr = $this->lap_shu_m->get_key_val();
		foreach ($opsi_val_arr as $key => $value) {
			$out[$key] = $value;
		}
		$pajak = $shu_belum * $out['pjk_pph'] /100;
		$shu_stl_pajak = $shu_belum - $pajak;

		$jml_cadangan = $out['dana_cadangan'] * $shu_stl_pajak/100; 
		$jml_jasa_anggota = $out['jasa_anggota'] * $shu_stl_pajak/100; 
		$jml_dn_pengurus = $out['dana_pengurus'] * $shu_stl_pajak/100; 
		$jml_dn_karyawan = $out['dana_karyawan'] * $shu_stl_pajak/100; 
		$jml_dn_pend = $out['dana_pend'] * $shu_stl_pajak/100; 
		$jml_dn_sos = $out['dana_sosial'] * $shu_stl_pajak/100; 
		$jml_js_pemb_daerah_kerja = $out['js_pemb_daerah_kerja'] * $shu_stl_pajak/100; 
		$jml_jasa_dana_pembinaan = $out['jasa_dana_pembinaan'] * $shu_stl_pajak/100; 

		$jml_tot_simpanan = $jml_simpanan - $jml_penarikan;
		
		$jml_js_modal = $out['jasa_modal'] * $jml_jasa_anggota/100; 
		$jml_js_usaha = $out['jasa_usaha'] * $jml_jasa_anggota/100; 
		

		$html .='<table width="100%" cellspacing="0" cellpadding="3">
			<tr class="header_kolom">
				<td class="h_kiri" colspan="2">SHU Sebelum Pajak</td>
				<td class="h_kanan">' .number_format(nsi_round($shu_belum),2,',','.').'';
				$html .='</td></tr>';
			
			$html .= '<tr class="header_kolom">
				<td class="h_kiri" colspan="2"> Pajak PPh ('.$out['pjk_pph'].'%)</td>
				<td class="h_kanan">'.number_format($pajak,2,',','.').'</td>
			</tr>
			<tr class="header_kolom">
				<td class="h_kiri" colspan="2">SHU Setelah Pajak</td>
				<td class="h_kanan">'. number_format(nsi_round($shu_stl_pajak),2,',','.'). '';
				$html .= '</td>
			</tr>
			<tr>
				<td colspan="3"><strong>PEMBAGIAN SHU UNTUK DANA-DANA</strong></td>
			</tr>
			<tr>
				<td>Dana Cadangan</td>
				<td class="h_kanan">'. $out['dana_cadangan'].'% </td>
				<td class="h_kanan">'. number_format($jml_cadangan,2,',','.').'</td>
			</tr>
			<tr>
				<td>Jasa Anggota</td>
				<td class="h_kanan"> '. $out['jasa_anggota'].'%</td>
				<td class="h_kanan"> '.number_format($jml_jasa_anggota,2,',','.').'</td>
			</tr>
			<tr>
				<td>Dana Pengurus</td>
				<td class="h_kanan">'. $out['dana_pengurus'] .'%</td>
				<td class="h_kanan">'.number_format($jml_dn_pengurus,2,',','.'). '</td>
			</tr>
			<tr>
				<td>Dana Karyawan</td>
				<td class="h_kanan">'.$out['dana_karyawan'].' %</td>
				<td class="h_kanan">'. number_format($jml_dn_karyawan,2,',','.').'</td>
			</tr>
			<tr>
				<td>Dana Pendidikan</td>
				<td class="h_kanan">'.$out['dana_pend'].'%</td>
				<td class="h_kanan">'.number_format($jml_dn_pend,2,',','.').'</td>
			</tr>
			<tr>
				<td>Dana Sosial</td>
				<td class="h_kanan"> '.$out['dana_sosial'].'%</td>
				<td class="h_kanan">'.number_format($jml_dn_sos,2,',','.').'</td>
			</tr>
			<tr>
				<td>Jasa Pembangunan Daerah Kerja</td>
				<td class="h_kanan"> '.$out['js_pemb_daerah_kerja'].'%</td>
				<td class="h_kanan">'.number_format($jml_js_pemb_daerah_kerja,2,',','.').'</td>
			</tr>
			<tr>
				<td>Jasa Dana Pembinaan</td>
				<td class="h_kanan"> '.$out['jasa_dana_pembinaan'].'%</td>
				<td class="h_kanan">'.number_format($jml_jasa_dana_pembinaan,2,',','.').'</td>
			</tr>
			<tr>
				<td colspan="2"><strong>PEMBAGIAN SHU ANGGOTA</strong></td>
			</tr>

			<tr>
				<td>Jasa Usaha</td>
				<td class="h_kanan">'.$out['jasa_usaha'].'%</td>
				<td class="h_kanan">'. number_format(nsi_round($jml_js_usaha),2,',','.');
				$html .= '<input type="hidden" id="js_usaha" name="js_usaha" value="'.$jml_js_usaha.'">
				</td>
			</tr>
			<tr>
				<tr>
					<td>Jasa Modal</td>
					<td class="h_kanan">'.$out['jasa_modal'].'%</td>
					<td class="h_kanan">'.number_format(nsi_round($jml_js_modal),2,',','.');
						$html .='<input type="hidden" id="js_modal" name="js_modal" value="'.$jml_js_modal.'">
					</td>
				</tr>
				<td>Total Pendapatan Anggota</td>
				<td colspan="2" class="h_kanan">'.number_format(nsi_round($laba_pinjaman),2,',','.');
					$html .='<input type="hidden" id="tot_pendpatan" name="tot_pendpatan" value="'.$laba_pinjaman.'">
				</td>
			</tr>
			<tr>
				<td>Total Simpanan Anggota</td>
				<td colspan="2" class="h_kanan">'.number_format(nsi_round($jml_tot_simpanan),2,',','.').'
					<input type="hidden" id="tot_simpanan" name="tot_simpanan" value="'.$jml_tot_simpanan.'">
				</td>
			</tr>
		</table>
		';

		echo $html;
		die();


	}


}