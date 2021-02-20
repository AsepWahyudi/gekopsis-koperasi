<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_pinjaman extends AdminController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('pinjaman_m');
		$this->load->model('angsuran_m');
		$this->load->model('bunga_m');
	}	


	function cetak_laporan() {
		$data_pinjam = $this->pinjaman_m->lap_data_pinjaman();
		if($data_pinjam == FALSE) {
			echo 'DATA KOSONG<br>Pastikan Filter Tanggal dengan benar.';
			exit();
		}

		$tgl_dari = $_GET['tgl_dari']; 
		$tgl_sampai = $_GET['tgl_sampai']; 
		$cari_status = $_GET['cari_status']; 
		$cari_anggota = $_GET['cari_anggota']; 
		$cari_nama = $_GET['cari_nama']; 

		if ($cari_status == "") {
			$status = "Status Pelunasan : Semua";
		} else {
			$status = "Status Pelunasan :". $cari_status ;
		}
		
		if ($cari_nama == "") {
			$nama_anggota = "Nama Anggota : Semua";
		} else {
			$nama_anggota = "Nama Anggota : ". $cari_nama ;
		}
		
		if ($cari_anggota == "") {
			$anggota = "Jenis Anggota : Semua";
		} else {
			$anggota_arr = array();
			$txt_anggota_temp = $this->general_m->get_jenis_anggota_by_id($cari_anggota);
			foreach ($txt_anggota_temp as $row) {
				$nama = $row->nama;
				array_push($anggota_arr, $nama);
			}
			$txt_anggota = implode(', ', $anggota_arr);
			
			$anggota = "Jenis Anggota : ". $txt_anggota ;
		}

		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('L');
		$html = '';
		$html .= '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 15pt; font-weight: bold; padding-bottom: 12px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Data Pinjaman <br></span> <span> Periode '.jin_date_ina($tgl_dari).' - '.jin_date_ina($tgl_sampai).' | '.$status.' | '.$nama_anggota.' | '.$anggota.'</span> ', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
		<table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
			<tr class="header_kolom">
				<th style="width:3%;" > No </th>
				<th style="width:28%;"> Identitas Anggota</th>
				<th style="width:25%;"> Pinjaman  </th>
				<th style="width:22%;"> Hitungan </th>
				<th style="width:22%;"> Tagihan  </th>
			</tr>';
		$no =1;
		$batas = 1;
		$total_pinjaman = 0;
		$total_denda = 0;
		$total_tagihan = 0;
		$tot_sdh_dibayar = 0;
		$tot_sisa_tagihan = 0;
		foreach ($data_pinjam as $r) {
			if($batas == 0) {
				$html .= '
				<tr class="header_kolom" pagebreak="false">
					<th style="width:3%;" > No </th>
					<th style="width:27%;"> Identitas Anggota</th>
					<th style="width:26%;"> Pinjaman  </th>
					<th style="width:22%;"> Hitungan </th>
					<th style="width:22%;"> Tagihan  </th>
				</tr>';
				$batas = 1;
			}
			$batas++;

			$barang = $this->pinjaman_m->get_data_barang($r->barang_id);   
			$anggota = $this->general_m->get_data_anggota($r->anggota_id);   
			$jml_bayar = $this->general_m->get_jml_bayar($r->id); 
			$jml_denda = $this->general_m->get_jml_denda($r->id); 
			$jml_tagihan = $r->tagihan + $jml_denda->total_denda;
			$sisa_tagihan = $jml_tagihan - $jml_bayar->total;


			//total pinjaman
			$total_pinjaman += @$r->jumlah;
			//total tagihan
			$total_tagihan += $jml_tagihan;
			//total dibayar
			$tot_sdh_dibayar += $jml_bayar->total;
			//sisa tagihan
			$tot_sisa_tagihan += $sisa_tagihan;

			//jabatan
			if ($anggota->jabatan_id == "1"){
				$jabatan = "Pengurus";
			} else {
				$jabatan = "Anggota";
			}

			//jk
			if ($anggota->jk == "L"){
				$jk = "Laki-laki";
			} else {
				$jk = "Perempuan";
			}

			$tgl_pinjam = explode(' ', $r->tgl_pinjam);
			$txt_tanggal = jin_date_ina($tgl_pinjam[0],'full');

			$tgl_tempo = explode(' ', $r->tempo);
			$txt_tempo = jin_date_ina($tgl_tempo[0],'full');

			// AG'.sprintf('%04d',$anggota->id).'
			$html .= '
			<tr nobr="true">
				<td class="h_tengah">'.$no++.' </td>
				<td>
					<table width="100%"> 
						<tr>
							<td width="20%">ID </td><td width="5%">:</td><td class="h_kiri" width="75%">'.$anggota->ktp.'</td>
						</tr>
						<tr>
							<td>Nama </td>
							<td>:</td>
							<td class="h_kiri"><strong>'.strtoupper($anggota->nama).'</strong></td>
						</tr>
						<tr>
							<td>Dept </td>
							<td>:</td>
							<td class="h_kiri">'.$anggota->departement.'</td>
						</tr>
						<tr>
							<td>L/P </td>
							<td>:</td>
							<td class="h_kiri">'.$jk.' </td>
						</tr>
						<tr>
							<td>Jabatan </td>
							<td>:</td>
							<td class="h_kiri">'.$jabatan.' </td>
						</tr>
						<tr>
							<td>Alamat </td>
							<td>:</td>
							<td class="h_kiri">'.$anggota->alamat.'<br>Telp. '. $anggota->notelp.'</td>
						</tr>
					</table>
				</td>
				<td>
					<table width="100%">
						<tr>
							<td width="44%"> Nomor Kontrak</td>
							<td width="6%">:</td>
							<td width="50%" class="h_kiri">'.$r->nomor_pinjaman.'</td>
						</tr>
						<tr>
							<td> Tanggal Pinjam</td>
							<td>:</td>
							<td class="h_kiri">'.$txt_tanggal.'</td>
						</tr>
						<tr>
							<td> Tanggal Tempo</td>
							<td>:</td>
							<td class="h_kiri">'.$txt_tempo.'</td>
						</tr>
						<tr>
							<td> Pokok Pinjaman</td>
							<td>:</td>
							<td class="h_kiri">'.number_format(@$r->jumlah,2,',','.').'</td>
						</tr>
						<tr>
							<td> Lama Pinjaman</td>
							<td>:</td>
							<td class="h_kiri">'.number_format(@$r->lama_angsuran,2,',','.').' Bulan</td>
						</tr>
						<tr>
							<td> Status Lunas</td>
							<td>:</td>
							<td class="h_kiri">'.@$r->lunas.'</td>
						</tr>
					</table>
				</td>
				<td>
					<table> 
						<tr>
							<td>Pokok Angsuran </td> 
							<td class="h_kanan"> '.number_format(@$r->pokok_angsuran,2,',','.').' </td>
						</tr>
						<tr>
							<td>Bunga Pinjaman </td>
							<td class="h_kanan"> '.number_format(@$r->bunga_pinjaman,2,',','.').'</td>
						</tr>
						<tr>
							<td>Biaya Admin </td>
							<td class="h_kanan">'.number_format(@$r->biaya_adm,2,',','.').'</td>
						</tr>
						<tr>
							<td>Jumlah Angsuran </td>
							<td class="h_kanan"> '.number_format(nsi_round(@$r->ags_per_bulan),2,',','.').'</td>
						</tr>
						<tr>
							<td>Jumlah Pinjaman </td>
							<td class="h_kanan"> <strong>'.number_format(nsi_round(@$r->ags_per_bulan * @$r->lama_angsuran),2,',','.').'</strong></td>
						</tr>
					</table>
				</td>
				<td>
					<table> 
						<tr>
							<td>Jumlah Tagihan </td> 
							<td class="h_kanan"> <strong>'.number_format(nsi_round(@$r->ags_per_bulan * @$r->lama_angsuran),2,',','.').'</strong></td>
						</tr>
						<tr>
							<td>Jumlah Denda </td> 
							<td class="h_kanan"> '.number_format(nsi_round($jml_denda->total_denda),2,',','.').' </td>
						</tr>
						<tr>
							<td>Dibayar </td>
							<td class="h_kanan"> '.number_format(nsi_round($jml_bayar->total),2,',','.').'</td>
						</tr>
						<tr>
							<td>Sisa Tagihan </td>
							<td class="h_kanan"><strong>'.number_format(nsi_round($sisa_tagihan),2,',','.').'</strong></td>
						</tr>
					</table>
				</td>
			</tr>';
			}

		$html .= '
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Total Pokok Pinjaman </strong> </td>
					<td class="h_kanan"><strong> '.number_format(nsi_round($total_pinjaman),2,',','.').' </strong></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Total Tagihan </strong> </td>
					<td class="h_kanan"><strong>'.number_format(nsi_round($total_tagihan),2,',','.').'</strong></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Total Dibayar </strong> </td>
					<td class="h_kanan"><strong>'.number_format(nsi_round($tot_sdh_dibayar),2,',','.').'</strong></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Sisa Tagihan </strong> </td>
					<td class="h_kanan"><strong>'.number_format(nsi_round($tot_sisa_tagihan),2,',','.').'</strong></td>
					<td></td>
				</tr>
			</table>';
		$pdf->nsi_html($html);
		$pdf->Output('pinjam'.date('Ymd_His') . '.pdf', 'I');
	} 

	function cetak_pj() {
		$vid = $_GET['cari_pinjamid'];
		$data_pinjaman = $this->pinjaman_m->lap_cetak_pinjaman ($vid);
		if($data_pinjaman == FALSE) {
			echo 'DATA KOSONG<br>Pastikan data benar.';
			exit();
		}
		
		//$kas_id = $this->angsuran_m->get_data_kas();
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();

		$tanggal = date('Y-m-d H:i');
		
		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A3',true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		//$pdf->AddPage('L');
		$resolution = array(400, 180);
		$pdf->AddPage('L', $resolution);

		$html = '';
		$html = '<br>';
		//header
		$html .= '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {text-align: center; font-size: 15pt; font-weight: bold; padding-bottom: 12px;}
			.txt_body {font-size: 6pt;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold; color: #0e0e0e; font-size: 6pt; }
			.header_notes {background-color: #cccccc; text-align: center; font-weight: bold; color: #0e0e0e; font-size: 10pt; }
		</style>';
				
	foreach ($data_pinjaman["data"] as $data=>$r) {
		$anggota = $this->general_m->get_data_anggota($r->anggota_id); 
		$jnspinjaman = $this->pinjaman_m->get_jenis_pinjaman($r->jenis_pinjaman);
		$akunplafond = $this->general_m->get_jns_akun($r->plafond_pinjaman_akun);
		$akunasuransi = $this->general_m->get_jns_akun($r->biaya_asuransi_akun);
		$akunpblnsatu = $this->general_m->get_jns_akun($r->pokok_bulan_satu_akun);
		$akunpblndua = $this->general_m->get_jns_akun($r->pokok_bulan_dua_akun);
		$akunbblnsatu = $this->general_m->get_jns_akun($r->bunga_bulan_satu_akun);
		$akunbblndua = $this->general_m->get_jns_akun($r->bunga_bulan_dua_akun);
		$akunadm = $this->general_m->get_jns_akun($r->biaya_administrasi_akun);
		$akunspokok = $this->general_m->get_jns_akun($r->simpanan_pokok_akun);
		$akunswajib = $this->general_m->get_jns_akun($r->simpanan_wajib_akun);
		$akunmaterai = $this->general_m->get_jns_akun($r->biaya_materai_akun);
		$akunbersih = $this->general_m->get_jns_akun(2);

		$hdate = date("d-M-Y", strtotime($r->tgl_pinjam));
		$html .= '<table width="100%" border="0">
				<tr>
					<td> 
						'.$pdf->nsi_box($text = '<span class="txt_judul">PINJAMAN <br></span>', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
					</td>
					<td class="h_tengah"> &nbsp; &nbsp; &nbsp;<b><font size="17px">'.$r->nomor_pinjaman.' </font></b> <br><br>
						PJ DATE: '.$hdate .
					'</td>
				</tr>'; 
		$html .= '<tr>
					<td colspan="2"> 
						<table width="30%" border ="1">
							<tr class="header_notes">
								<td>Notes </td>
							</tr>
							<tr class="h_tengah">
								<td> '.$jnspinjaman->jns_pinjaman.'</td>
							</tr>

						</table>
					</td>
				</tr>';

	
	$html .='</table><br><br>';
	$html .= '
	<table width="100%" cellspacing="0" cellpadding="2" border="1" border-collapse="collapse">
	<thead>
		<tr class="header_kolom">
			<td rowspan="2"> NAMA ANGGOTA</td>
			<td rowspan="2"> LAMA <br> ANGSURAN </td>
			<td rowspan="2"> ANGSURAN <br> PER BULAN</td>
			<td colspan="2"> PLAFOND </td>
			<td colspan="2"> POKOK </td>
			<td colspan="2"> BUNGA </td>
			<td colspan="2"> SIMPANAN </td>
			<td colspan="2"> BIAYA </td>
			<td colspan="2"> BIAYA </td>
			<td colspan="2"> POKOK </td>
			<td colspan="2"> BUNGA </td>
			<td colspan="2"> SIMPANAN </td>
			<td colspan="2"> BIAYA </td>
			<td colspan="2"> PENCAIRAN </td>
		</tr>
		<tr class="header_kolom">
			<td> Pinjaman </td>
			<td> Akun</td>
			<td> Bulan Satu</td>
			<td> Akun</td>
			<td> Bulan Satu</td>
			<td> Akun</td>
			<td> Wajib</td>
			<td> Akun</td>
			<td> Asuransi</td>
			<td> Akun</td>
			<td> Administrasi</td>
			<td> Akun</td>
			
			<td> Bulan Dua</td>
			<td> Akun</td>
			<td> Bulan Dua</td>
			<td> Akun</td>
			<td> Pokok</td>
			<td> Akun</td>
			<td> Materai</td>
			<td> Akun</td>
			<td> Bersih</td>
			<td> Akun</td>
		</tr>
		</thead>';
		$html .= '<tbody>
					<tr class="txt_body">
					<td class="h_kiri">'.$anggota->nama.'</td>
					<td class="h_tengah">'.$r->lama_angsuran.'</td>
					<td class="h_kanan">'.number_format($r->angsuran_per_bulan,2,',','.').'</td>
					<td class="h_kanan">'.number_format($r->plafond_pinjaman,2,',','.').'</td>
					<td class="h_tengah">'.$akunplafond[0]->no_akun .'<br>'.$akunplafond[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->pokok_bulan_satu,2,',','.').'</td>
					<td class="h_tengah">'.$akunpblnsatu[0]->no_akun .'<br>'.$akunpblnsatu[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->bunga_bulan_satu,2,',','.').'</td>
					<td class="h_tengah">'.$akunbblnsatu[0]->no_akun .'<br>'.$akunbblnsatu[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->simpanan_wajib,2,',','.').'</td>
					<td class="h_tengah">'.$akunswajib[0]->no_akun .'<br>'.$akunswajib[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->biaya_asuransi,2,',','.').'</td>
					<td class="h_tengah">'.$akunasuransi[0]->no_akun .'<br>'.$akunasuransi[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->biaya_administrasi,2,',','.').'</td>
					<td class="h_tengah">'.$akunadm[0]->no_akun .'<br>'.$akunadm[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->pokok_bulan_dua,2,',','.').'</td>
					<td class="h_tengah">'.$akunpblndua[0]->no_akun .'<br>'.$akunpblndua[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->bunga_bulan_dua,2,',','.').'</td>
					<td class="h_tengah">'.$akunbblndua[0]->no_akun .'<br>'.$akunbblndua[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->simpanan_pokok,2,',','.').'</td>
					<td class="h_tengah">'.$akunspokok[0]->no_akun .'<br>'.$akunspokok[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->biaya_materai,2,',','.').'</td>
					<td class="h_tengah">'.$akunmaterai[0]->no_akun .'<br>'.$akunmaterai[0]->nama_akun .'</td>
					<td class="h_kanan">'.number_format($r->pencairan_bersih,2,',','.').'</td>
					<td class="h_tengah">'.$akunbersih[0]->no_akun .'<br>'.$akunbersih[0]->nama_akun .'</td>
		</tr></tbody>';	
	}
	$html .= '</table>';
	$html .='<br><br>';
            $html .='<table width="100%" border="0">
            <tr>
                <td></td>
                <td class="h_tengah">Prepared By</td>
                <td class="h_tengah">Approved By</td>
            </tr>
            <tr >
                <td height="40px"></td>
            </tr>
            <tr>
                <td></td>
                <td class="h_tengah">...........................</td>
                <td class="h_tengah">...........................</td>
            </tr>
            </table>';
			
		$pdf->nsi_html($html);
		$pdf->Output('pinjaman'.date('Ymd_His') . '.pdf', 'I');	
	}

	function eksport_Excel() {
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$data_pinjam = $this->pinjaman_m->lap_data_pinjaman();
		if($data_pinjam == FALSE) {
			echo 'DATA KOSONG<br>Pastikan Filter Tanggal dengan benar.';
			exit();
		}

		$tgl_dari = $_GET['tgl_dari']; 
		$tgl_sampai = $_GET['tgl_sampai']; 
		$cari_status = $_GET['cari_status']; 
		$cari_anggota = $_GET['cari_anggota']; 
		$cari_nama = $_GET['cari_nama']; 

		if ($cari_status == "") {
			$status = "Status Pelunasan : Semua";
		} else {
			$status = "Status Pelunasan :". $cari_status ;
		}
		
		if ($cari_nama == "") {
			$nama_anggota = "Nama Anggota : Semua";
		} else {
			$nama_anggota = "Nama Anggota : ". $cari_nama ;
		}
		
		if ($cari_anggota == "") {
			$anggota = "Jenis Anggota : Semua";
		} else {
			$anggota_arr = array();
			$txt_anggota_temp = $this->general_m->get_jenis_anggota_by_id($cari_anggota);
			foreach ($txt_anggota_temp as $row) {
				$nama = $row->nama;
				array_push($anggota_arr, $nama);
			}
			$txt_anggota = implode(', ', $anggota_arr);
			
			$anggota = "Jenis Anggota : ". $txt_anggota ;
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
		<span class="txt_judul">Laporan Data Pinjaman <br></span> <span> Periode '.jin_date_ina($tgl_dari).' - '.jin_date_ina($tgl_sampai).' | '.$status.' | '.$nama_anggota.' | '.$anggota.'</span>
		<table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
			<tr class="header_kolom">
				<th style="width:3%;" > No </th>
				<th style="width:28%;"> Identitas Anggota</th>
				<th style="width:25%;"> Pinjaman  </th>
				<th style="width:22%;"> Hitungan </th>
				<th style="width:22%;"> Tagihan  </th>
			</tr>';
		$no =1;
		$batas = 1;
		$total_pinjaman = 0;
		$total_denda = 0;
		$total_tagihan = 0;
		$tot_sdh_dibayar = 0;
		$tot_sisa_tagihan = 0;
		foreach ($data_pinjam as $r) {
			if($batas == 0) {
				$html .= '
				<tr class="header_kolom" pagebreak="false">
					<th style="width:3%;" > No </th>
					<th style="width:27%;"> Identitas Anggota</th>
					<th style="width:26%;"> Pinjaman  </th>
					<th style="width:22%;"> Hitungan </th>
					<th style="width:22%;"> Tagihan  </th>
				</tr>';
				$batas = 1;
			}
			$batas++;

			$barang = $this->pinjaman_m->get_data_barang($r->barang_id);   
			$anggota = $this->general_m->get_data_anggota($r->anggota_id);   
			$jml_bayar = $this->general_m->get_jml_bayar($r->id); 
			$jml_denda = $this->general_m->get_jml_denda($r->id); 
			$jml_tagihan = $r->tagihan + $jml_denda->total_denda;
			$sisa_tagihan = $jml_tagihan - $jml_bayar->total;


			//total pinjaman
			$total_pinjaman += @$r->jumlah;
			//total tagihan
			$total_tagihan += $jml_tagihan;
			//total dibayar
			$tot_sdh_dibayar += $jml_bayar->total;
			//sisa tagihan
			$tot_sisa_tagihan += $sisa_tagihan;

			//jabatan
			if ($anggota->jabatan_id == "1"){
				$jabatan = "Pengurus";
			} else {
				$jabatan = "Anggota";
			}

			//jk
			if ($anggota->jk == "L"){
				$jk = "Laki-laki";
			} else {
				$jk = "Perempuan";
			}

			$tgl_pinjam = explode(' ', $r->tgl_pinjam);
			$txt_tanggal = jin_date_ina($tgl_pinjam[0],'full');

			$tgl_tempo = explode(' ', $r->tempo);
			$txt_tempo = jin_date_ina($tgl_tempo[0],'full');

			// AG'.sprintf('%04d',$anggota->id).'
			$html .= '
			<tr nobr="true">
				<td class="h_tengah">'.$no++.' </td>
				<td>
					<table width="100%"> 
						<tr>
							<td width="20%">ID </td><td width="5%">:</td><td class="h_kiri" width="75%">'.$anggota->ktp.'</td>
						</tr>
						<tr>
							<td>Nama </td>
							<td>:</td>
							<td class="h_kiri"><strong>'.strtoupper($anggota->nama).'</strong></td>
						</tr>
						<tr>
							<td>Dept </td>
							<td>:</td>
							<td class="h_kiri">'.$anggota->departement.'</td>
						</tr>
						<tr>
							<td>L/P </td>
							<td>:</td>
							<td class="h_kiri">'.$jk.' </td>
						</tr>
						<tr>
							<td>Jabatan </td>
							<td>:</td>
							<td class="h_kiri">'.$jabatan.' </td>
						</tr>
						<tr>
							<td>Alamat </td>
							<td>:</td>
							<td class="h_kiri">'.$anggota->alamat.'<br>Telp. '. $anggota->notelp.'</td>
						</tr>
					</table>
				</td>
				<td>
					<table width="100%">
						<tr>
							<td width="44%"> Nomor Kontrak</td>
							<td width="6%">:</td>
							<td width="50%" class="h_kiri">'.$r->nomor_pinjaman.'</td>
						</tr>
						<tr>
							<td> Tanggal Pinjam</td>
							<td>:</td>
							<td class="h_kiri">'.$txt_tanggal.'</td>
						</tr>
						<tr>
							<td> Tanggal Tempo</td>
							<td>:</td>
							<td class="h_kiri">'.$txt_tempo.'</td>
						</tr>
						<tr>
							<td> Pokok Pinjaman</td>
							<td>:</td>
							<td class="h_kiri">'.number_format(@$r->jumlah,2,',','.').'</td>
						</tr>
						<tr>
							<td> Lama Pinjaman</td>
							<td>:</td>
							<td class="h_kiri">'.number_format(@$r->lama_angsuran,2,',','.').' Bulan</td>
						</tr>
						<tr>
							<td> Status Lunas</td>
							<td>:</td>
							<td class="h_kiri">'.@$r->lunas.'</td>
						</tr>
					</table>
				</td>
				<td>
					<table> 
						<tr>
							<td>Pokok Angsuran </td> 
							<td class="h_kanan"> '.number_format(@$r->pokok_angsuran,2,',','.').' </td>
						</tr>
						<tr>
							<td>Bunga Pinjaman </td>
							<td class="h_kanan"> '.number_format(@$r->bunga_pinjaman,2,',','.').'</td>
						</tr>
						<tr>
							<td>Biaya Admin </td>
							<td class="h_kanan">'.number_format(@$r->biaya_adm,2,',','.').'</td>
						</tr>
						<tr>
							<td>Jumlah Angsuran </td>
							<td class="h_kanan"> '.number_format(nsi_round(@$r->ags_per_bulan),2,',','.').'</td>
						</tr>
						<tr>
							<td>Jumlah Pinjaman </td>
							<td class="h_kanan"> <strong>'.number_format(nsi_round(@$r->ags_per_bulan * @$r->lama_angsuran),2,',','.').'</strong></td>
						</tr>
					</table>
				</td>
				<td>
					<table> 
						<tr>
							<td>Jumlah Tagihan </td> 
							<td class="h_kanan"> <strong>'.number_format(nsi_round(@$r->ags_per_bulan * @$r->lama_angsuran),2,',','.').'</strong></td>
						</tr>
						<tr>
							<td>Jumlah Denda </td> 
							<td class="h_kanan"> '.number_format(nsi_round($jml_denda->total_denda),2,',','.').' </td>
						</tr>
						<tr>
							<td>Dibayar </td>
							<td class="h_kanan"> '.number_format(nsi_round($jml_bayar->total),2,',','.').'</td>
						</tr>
						<tr>
							<td>Sisa Tagihan </td>
							<td class="h_kanan"><strong>'.number_format(nsi_round($sisa_tagihan),2,',','.').'</strong></td>
						</tr>
					</table>
				</td>
			</tr>';
			}

		$html .= '
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Total Pokok Pinjaman </strong> </td>
					<td class="h_kanan"><strong> '.number_format(nsi_round($total_pinjaman),2,',','.').' </strong></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Total Tagihan </strong> </td>
					<td class="h_kanan"><strong>'.number_format(nsi_round($total_tagihan),2,',','.').'</strong></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Total Dibayar </strong> </td>
					<td class="h_kanan"><strong>'.number_format(nsi_round($tot_sdh_dibayar),2,',','.').'</strong></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="3" class="h_kanan"> <strong> Sisa Tagihan </strong> </td>
					<td class="h_kanan"><strong>'.number_format(nsi_round($tot_sisa_tagihan),2,',','.').'</strong></td>
					<td></td>
				</tr>
			</table>';
		echo $html;
		die();
	} 

}