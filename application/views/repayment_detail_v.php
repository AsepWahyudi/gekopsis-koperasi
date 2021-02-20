<!-- Styler -->
<style type="text/css">
	.panel * {
		font-family: "Arial","​Helvetica","​sans-serif";
	}
	.fa {
		font-family: "FontAwesome";
	}
	.datagrid-header-row * {
		font-weight: bold;
	}
	.messager-window * a:focus, .messager-window * span:focus {
		color: blue;
		font-weight: bold;
	}
	.daterangepicker * {
		font-family: "Source Sans Pro","Arial","​Helvetica","​sans-serif";
		box-sizing: border-box;
	}
	.glyphicon	{font-family: "Glyphicons Halflings"}
	.form-control {
		height: 20px;
		padding: 4px;
	}	

	th {
		text-align: center;
		background: #3c8dbc;
		height: 30px;
		border-width: 1px;
		border-style: solid;
		color :#ffffff;
	}
</style>

<!-- buaat tanggal sekarang -->
<?php 
$s_wajib=0;
$jml_swajib=0;
$simp_wajib = $this->angsuran_m->get_simpanan_wajib();	
if (empty($simp_wajib)) {
	$s_wajib = 0;
} else {
	$s_wajib = $simp_wajib->jumlah;
}
$tagihan = ($row_pinjam->ags_per_bulan + $s_wajib) * $row_pinjam->lama_angsuran;
//$dibayar = $hitung_dibayar->total;
//$jml_denda=$hitung_denda->total_denda;
//$sisa_bayar = $tagihan - $dibayar;
//$total_bayar = $sisa_bayar + $jml_denda;

?>

<!-- menu atas -->
<?php
echo '<a href="'.site_url().'/repayment_schedule" class="btn btn-sm btn-danger" title="Kembali"> <i class="glyphicon glyphicon-circle-arrow-left"></i> Kembali </a>
<a href="'.site_url('cetak_repayment_detail').'/cetak/' . $row_pinjam->id . '"  title="Cetak Detail" class="btn btn-sm btn-success" target="_blank"> <i class="glyphicon glyphicon-print"></i> Cetak Detail</a>
'
;
	
?>
<p></p>
<!-- detail data anggota -->
<div class="box box-solid box-primary">
	<div class="box-header" title="Detail Repayment" data-toggle="" data-original-title="Detail Repayment">
		<h3 class="box-title"> Detail Repayment </h3> 
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-xs" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
		<table style="font-size: 13px; width:100%">
			<tr>
				<td style="width:10%; text-align:center;">
					<?php
					$photo_w = 3 * 30;
					$photo_h = 4 * 30;
					if($data_anggota->file_pic == '') {
						echo '<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="'.$photo_w.'" height="'.$photo_h.'" />';
					} else {
						echo '<img src="'.base_url().'uploads/anggota/' . $data_anggota->file_pic . '" alt="Foto" width="'.$photo_w.'" height="'.$photo_h.'" />';
					}
					?>
				</td> 
				<td>
					<table style="width:100%">
						<tr>
							<td><label class="text-green">Data Anggota</label></td>
						</tr>
						<?php //echo 'AG' . sprintf('%04d', $row_pinjam->anggota_id) . '' ?>
						<tr>
							<td> ID Anggota</td>
							<td> : </td>
							<td> <?php echo $data_anggota->ktp; ?></td>
						</tr>
						<tr>
							<td> Nama Anggota </td>
							<td> : </td>
							<td> <?php echo $data_anggota->nama; ?></td>
						</tr>
						<tr>
							<td> Dept </td>
							<td> : </td>
							<td> <?php echo $data_anggota->departement; ?></td>
						</tr>
						<tr>
							<td> Tempat, Tanggal Lahir  </td>
							<td> : </td>
							<td> <?php echo $data_anggota->tmp_lahir .', '. jin_date_ina ($data_anggota->tgl_lahir); ?></td>
						</tr>
						<tr>
							<td> Kota Tinggal</td> 
							<td> : </td>
							<td> <?php echo $data_anggota->kota; ?></td>
						</tr>
					</table>
				</td>
				<td>
					<table style="width:100%">
						<tr>
							<td><label class="text-green">Data Repayment</label></td>
						</tr>
						<tr>
							<td> Kode Pinjam</td>
							<td> : </td>
							<td> <?php echo $row_pinjam->nomor_pinjaman; ?> </td>
						</tr>
						<tr>
							<td> Tanggal Pinjam</td>
							<td> : </td>
							<td> <?php 
								$tanggal_arr = explode(' ', $row_pinjam->tgl_pinjam);
								$txt_tanggal_p = jin_date_ina($tanggal_arr[0], 'full');
								echo  $txt_tanggal_p; 
								?>
							</td>
						</tr>
						<tr>
							<td> Tanggal Tempo</td>
							<td> : </td>
							<td> <?php 
								$tanggal_arr = explode(' ', $row_pinjam->tempo);
								$txt_tanggal_t = jin_date_ina($tanggal_arr[0], 'full');
								echo  $txt_tanggal_t; 
								?>
							</td>
						</tr>
						<tr>
							<td> Lama Pinjaman</td> 
							<td> : </td>
							<td> <?php echo $row_pinjam->lama_angsuran.' '.$row_pinjam->tenor; ?></span></td>
						</tr>
					</table>
				</td>
				<td>
					<table style="width:100%">
						<tr>
							<td>
								<label></label>
							</td>
						</tr>
						<tr>
							<td> Pokok Pinjaman</td>
							<td> : </td>
							<td class="h_kanan"> <?php echo number_format(nsi_round($row_pinjam->plafond_pinjaman))?></td>
						</tr>
						<tr>
							<td> Angsuran Pokok </td>
							<td> : </td>
							<td class="h_kanan"> <?php echo number_format($row_pinjam->pokok_angsuran); ?></td>
						</tr>
						<tr>
							<td> Biaya dan Bunga </td>
							<td> : </td>
							<td class="h_kanan"> <?php echo number_format($row_pinjam->bunga_pinjaman); ?></td>
						</tr>
						<tr>
							<td> Simpanan Wajib </td>
							<td> : </td>
							<td class="h_kanan"> <?php echo number_format($s_wajib); ?></td>
						</tr>
						<tr>
							<td> Jumlah Angsuran </td> 
							<td> : </td>
							<td class="h_kanan"><?php echo number_format(nsi_round($row_pinjam->pokok_angsuran + $row_pinjam->bunga_pinjaman + $s_wajib)); ?></td>
						</tr>
					</table>
				</td>			
			</tr>
		</table>
	</div>

	<div class="box box-solid bg-light-blue">
		<table width="100%" style="font-size: 12px;">
			<tr>
				<td><strong> Detail Pembayaran </strong> &raquo; </td>
				<td> Sisa Angsuran : <span id="det_sisa_ags"> <?php echo $row_pinjam->lama_angsuran; ?> </span> Bulan </td>
				<td> Dibayar : Rp. <span id="det_sudah_bayar"> <?php echo number_format(nsi_round(0)); ?></span> </td>
				<td> Denda : Rp. <span id="det_jml_denda"> <?php echo  number_format(nsi_round(0)); ?> </span> </td>
				<td> Sisa Tagihan Rp. <span id="total_bayar"> <?php echo  number_format(nsi_round(0)); ?> </span> </td>
				<td> Status Pelunasan : <span id="ket_lunas"> <?php echo $row_pinjam->lunas; ?> </span> </td>
			</code>
		</tr>
	</table>
</div>
</div>

<label class="text-green"> Simulasi Tagihan :</label>
<table  class="table table-bordered">
	<tr class="header_kolom">
		<th style="width:10%; vertical-align: middle"> Bln ke</th>
		<th style="width:15%; vertical-align: middle"> Angsuran Pokok</th>
		<th style="width:15%; vertical-align: middle"> Angsuran Bunga</th>
		<th style="width:15%; vertical-align: middle"> Simpanan Wajib</th>
		<th style="width:30%; vertical-align: middle"> Jumlah Angsuran</th>
		<th style="width:20%; vertical-align: middle"> Tanggal Tempo</th>
	</tr>


<?php //var_dump($simulasi_tagihan); 

$vtotalags =0;
if(!empty($simulasi_tagihan)) {
	$no = 1;
	$row = array();
	$jml_pokok = 0;
	$jml_bunga = 0;
	$jml_ags = 0;
	$jml_adm = 0;
	$provisi_pinjaman = 0;
	$ags_per_bulan=0;
	foreach ($simulasi_tagihan as $row) {
		if(($no % 2) == 0) {
			$warna="#FAFAD2";
		} else {
			$warna="#FFFFFF";
		}

		$txt_tanggal = jin_date_ina($row['tgl_tempo']);
		$jml_pokok += $row['angsuran_pokok'];
		$jml_bunga += $row['bunga_pinjaman'];
		$jml_swajib += $s_wajib;
		//$jml_ags += $row['jumlah_ags'];
        $ags_per_bulan = $row['angsuran_pokok'] + $row['bunga_pinjaman'] + $s_wajib;
        $jml_ags += round($ags_per_bulan);
		echo '
			<tr bgcolor='.$warna.'>
				<td class="h_tengah">'.$no.'</td>
				<td class="h_kanan">'.number_format(nsi_round($row['angsuran_pokok'])).'</td>
				<td class="h_kanan">'.number_format(nsi_round($row['bunga_pinjaman'])).'</td>
				<td class="h_kanan">'.number_format(nsi_round($s_wajib)).'</td>
				<td class="h_kanan">'.number_format(nsi_round($ags_per_bulan)).'</td>
				<td class="h_kanan">'.$txt_tanggal.'</td>
			</tr>';
		$no++;
	}
	echo '<tr bgcolor="#eee">
				<td class="h_tengah"><strong>Jumlah</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_pokok)).'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_bunga)).'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_swajib)).'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_ags)).'</strong></td>
				<td></td>
			</tr>
		</table>';
}
?>
