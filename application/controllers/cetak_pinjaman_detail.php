<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Cetak_pinjaman_detail extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
		$this->load->model('pinjaman_m');
		$this->load->model('angsuran_m');
		$this->load->model('setting_m');
	}	

	function cetak($id) {
		$row = $this->pinjaman_m->get_data_pinjam($id);
		if($row == FALSE) {
			echo 'DATA KOSONG';
        //redirect('angsuran_detail');
			exit();
    }
    
    $jenis_pinjam = $row->jenis_pinjam;

		$opsi_val_arr = $this->setting_m->get_key_val();
		foreach ($opsi_val_arr as $key => $value){
			$out[$key] = $value;
		}

		$this->load->library('Pdf');
		$pdf = new Pdf('P', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('P','FOLIO');
		$html = '';
		$html .= '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 12px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			.txt_content {font-size: 10pt; font-style: arial;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Detail Transaksi Pembayaran Kredit <br></span>', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
		<table width="100%" cellspacing="0" cellpadding="3" border="1" border-collapse= "collapse">';

			$anggota = $this->general_m->get_data_anggota($row->anggota_id);
			$angsuran = $this->angsuran_m->get_data_angsuran($row->id);

			$hitung_denda = $this->general_m->get_jml_denda($row->id);
			$hitung_dibayar = $this->general_m->get_jml_bayar($row->id);
			$sisa_ags = $this->general_m->get_record_bayar($row->id);
			$angsuran = $this->angsuran_m->get_data_angsuran($row->id);
			$s_wajib = $this->angsuran_m->get_simpanan_wajib();

			$tgl_bayar = explode(' ', $row->tgl_pinjam);
			$txt_tanggal = jin_date_ina($tgl_bayar[0]);   

			$tgl_tempo = explode(' ', $row->tempo);
      $tgl_tempo = jin_date_ina($tgl_tempo[0]); 
      $sisa_pokok = ($row->pokok_angsuran * $row->lama_angsuran) - ($row->pokok_angsuran * $row->bln_sudah_angsur);

			//AG'.sprintf('%05d', $row->anggota_id).'
			$html .='<table width="100%">   
			<tr>
				<td width="18%"> ID Anggota </td>
				<td width="2%"> : </td>
				<td width="45%"> '.$anggota->ktp.'</td>

				<td> Pokok Pinjaman </td>
				<td width="5%"> : Rp. </td>
				<td width="10%" class="h_kanan"> '.number_format($row->jumlah,2,',','.').'</td>
			</tr>
			<tr>
				<td> Nama Anggota </td>
				<td> : </td>
				<td> <strong>'.strtoupper($anggota->nama).'</strong></td>

				<td> Angsuran Pokok </td>
				<td> : Rp. </td>
        <td class="h_kanan"> '.(($jenis_pinjam == 9)?
        number_format(nsi_round(($row->plafond_pinjaman * ($row->biaya_adm / 100) / 12) / (1-1/pow(1+(($row->biaya_adm/100)/12),$row->lama_angsuran))),2,',','.'):
        number_format($row->pokok_angsuran,2,',','.')).'</td>
			</tr>
			<tr>
				<td> Dept </td>
				<td> : </td>
				<td> '.$anggota->departement.'</td>

				<td> Simpanan Wajib </td>
				<td> : Rp. </td>
				<td class="h_kanan"> '.(($jenis_pinjam == 9)?0:number_format($s_wajib->jumlah,2,',','.')).'</td>
			</tr>
			<tr>
				<td> Alamat </td>
				<td> : </td>
				<td> '.$anggota->alamat.'</td>

				<td> Angsuran Bunga </td>
				<td> : Rp. </td>
				<td class="h_kanan"> '.(($jenis_pinjam == 9)?0:number_format($row->bunga_pinjaman,2,',','.')).'</td>
			</tr>
			<tr>
				<td > Nomor Pinjam </td>
				<td > :  </td>
				<td > '.$row->nomor_pinjaman.'</td>

				<td> Jumlah Angsuran </td>
				<td> : Rp. </td>
        <td class="h_kanan"> '.(($jenis_pinjam == 9)?
        number_format(nsi_round(($row->plafond_pinjaman * ($row->biaya_adm / 100) / 12) / (1-1/pow(1+(($row->biaya_adm/100)/12),$row->lama_angsuran))),2,',','.'):
        number_format(nsi_round($row->ags_per_bulan + $s_wajib->jumlah),2,',','.')).'</td>
			</tr>
			<tr>
				<td> Tanggal Pinjam </td>
				<td> : </td>
				<td> '.$txt_tanggal.'</td>
				<td> Sisa Pokok </td>
				<td> : Rp. </td>
				<td class="h_kanan"> '.number_format(nsi_round($sisa_pokok),2,',','.').'</td>
			</tr>
			<tr>
				<td> Tanggal Tempo </td>
				<td> : </td>
				<td> '.$tgl_tempo.'</td>
			</tr>

			<tr>
				<td> Lama Pinjam </td>
				<td> : </td>
				<td> '.$row->lama_angsuran.' Bulan</td>
			</tr>';
			$html .= '</table>';

			$tagihan = ($row->ags_per_bulan + $s_wajib->jumlah) * $row->lama_angsuran;
			$dibayar = $hitung_dibayar->total;
			$jml_denda = $hitung_denda->total_denda;
			$sisa_bayar = $tagihan - $dibayar;
			$total_bayar = $sisa_bayar + $jml_denda;
			$sisa_angsuran = $row->lama_angsuran - $sisa_ags;

			$html .= '<br><br><strong> Detail Pembayaran </strong><br><br>';
			$html .= '<table width="80%">
			<tr>
				<td> Total Pinjaman</td><td class="h_kanan">'.number_format(nsi_round($tagihan),2,',','.').'</td>
				<td class="h_kanan"> Status Lunas </td> 
				<td class="h_kiri"> : '.$row->lunas.'</td>
			</tr>
			<tr>
				<td> Total Denda</td>
				<td class="h_kanan"> '.number_format(nsi_round($jml_denda),2,',','.').'</td>
			</tr>
			<tr>
				<td> Total Tagihan</td>
				<td class="h_kanan">'.number_format(nsi_round($tagihan + $jml_denda),2,',','.').'</td>
			</tr>
			<tr>
				<td> Sudah Dibayar </td>
				<td class="h_kanan"> '.number_format(nsi_round($dibayar),2,',','.').'</td>
			</tr>
			<tr>
				<td> Sisa Tagihan </td>
				<td class="h_kanan"> '.number_format(nsi_round($total_bayar ),2,',','.').'</td>
			</tr>
		</table> <br><br>';

		$simulasi_tagihan = $this->pinjaman_m->get_simulasi_pinjaman($id);

    $html .= '<br><br><strong> Simulasi Tagihan </strong><br><br>';
    if ($jenis_pinjam == 9) {
      $html .= '<table width="100%">
			<tr class="header_kolom">
				<th style="width:10%;"> Bln ke</th>
				<th style="width:10%;"> Sisa Pokok Awal</th>
				<th style="width:10%;"> Angsuran Pokok</th>
				<th style="width:10%;"> Angsuran Bunga</th>
				<th style="width:10%;"> Total Angsuran Ke Bank</th>
				<th style="width:10%;"> Sisa Pokok Akhir</th>
				<th style="width:10%;"> Administrasi Angsuran</th>
				<th style="width:10%;"> Total Angsuran Ke Debitur</th>
				<th style="width:20%;"> Tanggal Tempo</th>
			</tr>';
    } else {
		$html .= '<table width="100%">
			<tr class="header_kolom">
				<th style="width:10%;"> Bln ke</th>
				<th style="width:20%;"> Angsuran Pokok</th>
				<th style="width:20%;"> Angsuran Bunga</th>
				<th style="width:20%;"> Simpanan Wajib</th>
				<th style="width:10%;"> Jumlah Angsuran</th>
				<th style="width:20%;"> Tanggal Tempo</th>
			</tr>';
    }
		if(!empty($simulasi_tagihan)) {
			$no = 1;
			$row = array();
			$jml_pokok = 0;
			$jml_bunga = 0;
			$jml_ags = 0;
			$jml_swajib = 0;
      $jml_provisi = 0;
      $jml_sisa_pokok_awal = 0;
      $jml_total_angsuran_bank = 0;
      $jml_total_angsuran_debitur = 0;
      $jml_administrasi_angsuran = 0;
      $jml_sisa_pokok_akhir = 0;
			foreach ($simulasi_tagihan as $row) {
        $txt_tanggal = jin_date_ina($row['tgl_tempo']);
        if ($jenis_pinjam == 9) {
          $jml_sisa_pokok_awal += $row['sisa_pokok_awal'];
          $jml_total_angsuran_bank += $row['total_angsuran_bank'];
          $jml_total_angsuran_debitur += $row['total_angsuran_debitur'];
          $jml_administrasi_angsuran += $row['administrasi_angsuran'];
          $jml_sisa_pokok_akhir += $row['sisa_pokok_akhir'];
        } else {
				$jml_pokok += $row['angsuran_pokok'];
				$jml_bunga += $row['bunga_pinjaman'];
				$jml_swajib += $s_wajib->jumlah;
				$jml_ags += $row['jumlah_ags'];
        $jml_provisi += $row['provisi_pinjaman'];
        }
        if ($jenis_pinjam == 9) {
          $html .= '
          <tr >
            <td class="h_tengah">'.$no.'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['sisa_pokok_awal']),2,',','.').'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['angsuran_pokok']),2,',','.').'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['bunga_pinjaman']),2,',','.').'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['total_angsuran_bank']),2,',','.').'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['sisa_pokok_akhir']),2,',','.').'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['administrasi_angsuran']),2,',','.').'</td>
            <td class="h_kanan">'.number_format(nsi_round($row['total_angsuran_debitur']),2,',','.').'</td>
            <td class="h_kanan">'.$txt_tanggal.'</td>
          </tr>';
        } else {
				$html .= '
					<tr>
						<td class="h_tengah">'.$no.'</td>
						<td class="h_kanan">'.number_format(nsi_round($row['angsuran_pokok']),2,',','.').'</td>
						<td class="h_kanan">'.number_format(nsi_round($row['bunga_pinjaman']),2,',','.').'</td>
						<td class="h_kanan">'.number_format(nsi_round($s_wajib->jumlah),2,',','.').'</td>
						<td class="h_kanan">'.number_format(nsi_round($row['jumlah_ags'] + $s_wajib->jumlah),2,',','.').'</td>
						<td class="h_kanan">'.$txt_tanggal.'</td>
          </tr>';
        }
				$no++;
      }
    }

    if ($jenis_pinjam == 9) {
      $html .='
      <tr bgcolor='.$warna.'>
        <td class="h_tengah"><strong>Jumlah</strong></td>
        <td class="h_kanan"></td>
        <td class="h_kanan"><strong>'.number_format($jml_pokok,2,',','.').'</strong></td>
        <td class="h_kanan"><strong>'.number_format($jml_bunga,2,',','.').'</strong></td>
        <td class="h_kanan"><strong>'.number_format($jml_total_angsuran_bank,2,',','.').'</strong></td>
        <td class="h_kanan"></td>
        <td class="h_kanan"><strong>'.number_format($jml_administrasi_angsuran,2,',','.').'</strong></td>
        <td class="h_kanan"><strong>'.number_format($jml_total_angsuran_debitur,2,',','.').'</strong></td>
        <td class="h_kanan"></td>
      </tr>';
    } else {
    $html.= '<tr bgcolor="#eee">
          <td class="h_tengah"><strong>Jumlah</strong></td>
          <td class="h_kanan"><strong>'.number_format(nsi_round($jml_pokok),2,',','.').'</strong></td>
          <td class="h_kanan"><strong>'.number_format(nsi_round($jml_bunga),2,',','.').'</strong></td>
          <td class="h_kanan"><strong>'.number_format(nsi_round($jml_swajib),2,',','.').'</strong></td>
          <td class="h_kanan"><strong>'.number_format(nsi_round($jml_ags + $jml_swajib),2,',','.').'</strong></td>
          <td></td>
        </tr>
      </table>';
    }

    $html .= '</table>';

    $html .= '
    <br><br><strong> Detail Transaksi Pembayaran </strong><br><br>
<table width="100%">
	<tr class="header_kolom">
		<th style="width:5%;"> No. </th>
		<th style="width:12%;"> Kode Bayar</th>
		<th style="width:10%;"> Tanggal Bayar</th>
		<th style="width:10%;"> Angsuran Ke </th>
		<th style="width:15%;"> Jenis Pembayaran </th>
		<th style="width:20%;"> Jumlah Bayar</th>
		<th style="width:20%;"> Denda  </th>
		<th style="width:10%;"> User  </th>
  </tr>';

  $jml_tot = 0;
  $no = 1;

  if(empty($angsuran)) {
		$html .= '<code> Tidak Ada Transaksi Pembayaran</code>';
	} else {

		foreach ($angsuran as $row) {
			if(($no % 2) == 0) {
				$warna="#FAFAD2";
			} else {
				$warna="#FFFFFF";
			}

			$tgl_bayar = explode(' ', $row->tgl_bayar);
			$txt_tanggal = jin_date_ina($tgl_bayar[0]);
			$jml_tot += $row->jumlah_bayar;
			$jml_denda += $row->denda_rp;

			$html .= '
			<tr bgcolor='.$warna.'>
				<td class="h_tengah">'.$no++.'</td>
				<td class="h_tengah">'.'TBY'.sprintf('%05d', $row->id).'</td>
				<td class="h_tengah">'.$txt_tanggal.'</td>
				<td class="h_tengah">'.$row->angsuran_ke.'</td>
				<td class="h_kiri">'.$row->ket_bayar.'</td>
				<td class="h_kanan">'.number_format(nsi_round($row->jumlah_bayar),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($row->denda_rp),2,',','.').'</td>
				<td class="h_tengah">'.$row->user_name.'</td>
			</tr>';
		}
		$html .= '<tr bgcolor="#eee">
			<td class="h_tengah" colspan="5"><strong>Jumlah</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tot),2,',','.').'</strong></td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($jml_denda),2,',','.').'</strong></td>
			<td></td>
			</tr>';

    $html .= '</table>';
  }
		$pdf->nsi_html($html);
		$pdf->Output('detail'.date('Ymd_His') . '.pdf', 'I');
	}
}