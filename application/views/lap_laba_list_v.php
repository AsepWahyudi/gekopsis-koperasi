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
</style>
<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Laporan Laba Rugi </h3>
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-sm" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
	<form id="fmCari" method="GET">
	<input type="hidden" name="tgl_dari" id="tgl_dari">
	<input type="hidden" name="tgl_samp" id="tgl_samp">
	<table>
		<tr>
			<td>
				<div id="filter_tgl" class="input-group" style="display: inline;">
					<button class="btn btn-default" id="daterange-btn">
					<?php if ($jenis_laporan == 1) { ?>
						<i class="fa fa-calendar"></i> <span id="reportrange"><span><?php echo $tgl_periode_txt; ?>
					<?php } else {?>	
						<i class="fa fa-calendar"></i> <span id="reportrange"><span><?php echo $tgl_periode_txt_c; ?>
					<?php } ?>
						</span></span>
						<i class="fa fa-caret-down"></i>
					</button>
				</div>
			</td>
			<td>
			<select id="jenis_laporan" name="jenis_laporan">
				<option value="1">Staffel</option>
				<option value="2">Perbandingan Antar Bulan</option>
			</select>
			<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="cari()">Cari Laporan</a>
			<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>
			<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
			<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-excel" plain="false" onclick="export_excel()">Ekspor</a>
			</td>
		</tr>
	</table>
	</form>
</div>
</div>

<div class="box box-primary">
<div class="box-body">
<p></p>
<?php if ($jenis_laporan == 1) { ?>
	<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Laba Rugi <?php echo $tgl_periode_txt; ?></p>
<?php } else {?>
	<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Laba Rugi <br>Perbandingan Bulan <?php echo $tgl_periode_txt_c; ?></p>
<?php } ?>
<p></p>
<h3> Estimasi Data Pinjaman </h3>
<table  class="table table-bordered">
<?php if ($jenis_laporan == 1) { ?>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
	</tr>
	<tr>
		<td class="h_tengah"> 1 </td>
		<td> Jumlah Pinjaman</td>
		<td class="h_kanan">
			<?php
				$pinjaman = $jml_pinjaman->jml_total; 
				echo ''.number_format(nsi_round($pinjaman),2,',','.').'<br>';
			?>
		</td>
	</tr>	
	<tr>
		<td class="h_tengah"> 2 </td>
		<td> Pendapatan Biaya Administrasi</td>
		<td class="h_kanan">
			<?php
				$biaya_adm = $jml_biaya_adm->jml_total; 
				echo ''.number_format(nsi_round($biaya_adm),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td class="h_tengah"> 3 </td>
		<td> Pendapatan Biaya Bunga</td>
		<td class="h_kanan">
			<?php
				$bunga = $jml_bunga->jml_total; 
				echo ''.number_format(nsi_round($bunga),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td class="h_tengah"> 4 </td>
		<td> Jumlah Provisi</td>
		<td class="h_kanan">
			<?php
				$provisi = $jml_pinjaman->jml_prv; 
				echo ''.number_format(nsi_round($provisi),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td class="h_tengah"> 5 </td>
		<td> Pendapatan Biaya Pembulatan</td>
		<td class="h_kanan">
			<?php
				$bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv); 
				echo ''.number_format(nsi_round($bulatan),2,',','.').'<br>';
			?>
		</td>
	</tr>		
	<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Tagihan</td>
		<td class="h_kanan">
			<?php
				$tagihan = $jml_tagihan->jml_total; 
				echo ''.number_format(nsi_round($tagihan),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td colspan="2" class="h_kanan"> <strong>Estimasi Pendapatan Pinjaman</strong></td>
		<td class="h_kanan">
			<?php
				$estimasi = $tagihan - $pinjaman; 
				echo '<strong>'.number_format(nsi_round($estimasi),2,',','.').'</strong>';
			?>
		</td>
	</tr>
<?php } else {?>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan <?php echo date("F Y",strtotime($blnthn_dari))?>  </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan <?php echo date("F Y",strtotime($blnthn_samp))?>  </th>
	</tr>
	<tr>
		<td class="h_tengah"> 1 </td>
		<td> Jumlah Pinjaman</td>
		<td class="h_kanan">
			<?php
				$pinjaman_old = $jml_pinjaman_old->jml_total; 
				echo ''.number_format(nsi_round($pinjaman_old),2,',','.').'<br>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$pinjaman = $jml_pinjaman->jml_total; 
				echo ''.number_format(nsi_round($pinjaman),2,',','.').'<br>';
			?>
		</td>
	</tr>	
	<tr>
		<td class="h_tengah"> 2 </td>
		<td> Pendapatan Biaya Administrasi</td>
		<td class="h_kanan">
			<?php
				$biaya_adm = $jml_biaya_adm_old->jml_total; 
				echo ''.number_format(nsi_round($biaya_adm),2,',','.').'<br>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$biaya_adm = $jml_biaya_adm->jml_total; 
				echo ''.number_format(nsi_round($biaya_adm),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td class="h_tengah"> 3 </td>
		<td> Pendapatan Biaya Bunga</td>
		<td class="h_kanan">
			<?php
				$bunga = $jml_bunga_old->jml_total; 
				echo ''.number_format(nsi_round($bunga),2,',','.').'<br>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$bunga = $jml_bunga->jml_total; 
				echo ''.number_format(nsi_round($bunga),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td class="h_tengah"> 4 </td>
		<td> Jumlah Provisi</td>
		<td class="h_kanan">
			<?php
				$provisi = $jml_pinjaman_old->jml_prv; 
				echo ''.number_format(nsi_round($provisi),2,',','.').'<br>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$provisi = $jml_pinjaman->jml_prv; 
				echo ''.number_format(nsi_round($provisi),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td class="h_tengah"> 5 </td>
		<td> Pendapatan Biaya Pembulatan</td>
		<td class="h_kanan">
			<?php
				//var_dump($jml_tagihan, ' ',$jml_pinjaman->jml_total ,' ', $jml_bunga->jml_total,' ', $jml_biaya_adm->jml_total,' ', $jml_pinjaman->jml_prv);die();
				$bulatan_old = $jml_tagihan_old->jml_total - ($jml_pinjaman_old->jml_total + $jml_bunga_old->jml_total + $jml_biaya_adm_old->jml_total + $jml_pinjaman_old->jml_prv); 
				echo ''.number_format(nsi_round($bulatan_old),2,',','.').'<br>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$bulatan = $jml_tagihan->jml_total - ($jml_pinjaman->jml_total + $jml_bunga->jml_total + $jml_biaya_adm->jml_total + $jml_pinjaman->jml_prv); 
				echo ''.number_format(nsi_round($bulatan),2,',','.').'<br>';
			?>
		</td>
	</tr>		
	<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Tagihan</td>
		<td class="h_kanan">
			<?php
				$tagihan_old = $jml_tagihan_old->jml_total; 
				echo ''.number_format(nsi_round($tagihan_old),2,',','.').'<br>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$tagihan = $jml_tagihan->jml_total; 
				echo ''.number_format(nsi_round($tagihan),2,',','.').'<br>';
			?>
		</td>
	</tr>
	<tr>
		<td colspan="2" class="h_kanan"> <strong>Estimasi Pendapatan Pinjaman</strong></td>
		<td class="h_kanan">
			<?php
				$estimasi = $tagihan_old - $pinjaman_old; 
				echo '<strong>'.number_format(nsi_round($estimasi),2,',','.').'</strong>';
			?>
		</td>
		<td class="h_kanan">
			<?php
				$estimasi = $tagihan - $pinjaman; 
				echo '<strong>'.number_format(nsi_round($estimasi),2,',','.').'</strong>';
			?>
		</td>
	</tr>
<?php }?>

</table>

<h3> Pendapatan </h3>
<table  class="table table-bordered">
<?php if ($jenis_laporan == 1) {?>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
	</tr>
	<?php $grandtotal=0; $subtotal=0; $i=0; foreach($data_dapat as $data => $row) { ?>	
				<?php if ($row->induk_akun != "") { ?>
						<tr>
						<td class="h_tengah"><?php echo $i ?>  </td>
						<td><?php echo $row->no_akun.' - '.$row->nama_akun; ?></td>
						<td class="h_kanan"><?php echo number_format(nsi_round($row->value),2,',','.')?></td>
						</tr>
				<?php $subtotal += $row->value;} else { $i=0;?>
					<tr>
					<td class="h_tengah fa fa-h-square"></td>
					<td><strong><?php echo $row->no_akun.' - '.$row->nama_akun; ?></strong></td>
					<td class="h_kanan"></td>
					</tr>
				<?php }?>
				
				 <?php if ($row->induk_akun != "" && @$data_dapat[$data+1]->induk_akun != $row->induk_akun) { ?>
						<tr><td colspan="2" class="h_kanan">Total</td><td class="h_kanan"><?php echo number_format(nsi_round($subtotal),2,',','.');?></td></tr> 
				<?php   $data=0;$subtotal=0;} ?>
				<?php ?>
	<?php $i++; $grandtotal += $row->value;} ?>
	<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Pendapatan</td>
		<td class="h_kanan"><?php echo number_format($grandtotal,2,',','.')?></td>
	</tr>
	<?php } else {?>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan <?php echo date("F Y",strtotime($blnthn_dari))?>  </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan <?php echo date("F Y",strtotime($blnthn_samp))?>  </th>
	</tr>

	<?php $i=0; foreach($data_dapat as $data) {?>
	<tr>
	<?php if ($data->induk_akun != '') {$i++ ?>
		<td class="h_tengah"><?php echo $i?>  </td>
		<td><?php echo $data->no_akun.' - '.$data->nama_akun; ?></td>
		<td class="h_kanan"><?php echo number_format($data->valueold,2,',','.');?></td>
		<td class="h_kanan"><?php echo number_format($data->value,2,',','.');?></td>
	<?php } else {$i=0;?>
		<td class="h_tengah fa fa-h-square"></td>
		<td><strong><?php echo $data->no_akun.' - '.$data->nama_akun; ?></strong></td>
		<td class="h_kanan"></td>
		<td class="h_kanan"></td>
	<?php }?>
	</tr>
	<?php }?>

	<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Pendapatan</td>
		<td class="h_kanan"><?php echo number_format($total_dapat->valueold,2,',','.')?></td>
		<td class="h_kanan"><?php echo number_format($total_dapat->value,2,',','.')?></td>
	</tr>
	<?php }?>
</table>

<h3> Biaya </h3>
<table  class="table table-bordered">
<?php if ($jenis_laporan == 1) { ?>
	<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:75%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Jumlah  </th>
	</tr>
	
	<?php $subtotal=0; $i=0; foreach($data_biaya as $data => $row) { ?>	
				<?php if ($row->induk_akun != "") { ?>
						<tr>
						<td class="h_tengah"><?php echo $i ?>  </td>
						<td><?php echo $row->no_akun.' - '.$row->nama_akun; ?></td>
						<td class="h_kanan"><?php echo number_format(nsi_round($row->value),2,',','.')?></td>
						</tr>
				<?php $subtotal += $row->value;} else { $i=0;?>
					<tr>
					<td class="h_tengah fa fa-h-square"></td>
					<td><strong><?php echo $row->no_akun.' - '.$row->nama_akun; ?></strong></td>
					<td class="h_kanan"></td>
					</tr>
				<?php }?>
				
				 <?php if ($row->induk_akun != "" && @$data_biaya[$data+1]->induk_akun != $row->induk_akun) { ?>
						<tr><td colspan="2" class="h_kanan">Total</td><td class="h_kanan"><?php echo number_format(nsi_round($subtotal),2,',','.');?></td</tr> 
				<?php   $data=0;$subtotal=0;} ?>
				<?php ?>
	<?php $i++;} ?>
	<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Biaya</td>
		<td class="h_kanan"><?php echo number_format($total_biaya->value,2,',','.')?></td>
	</tr>
	<?php } else {?>
		<tr class="header_kolom">
		<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
		<th style="width:50%; vertical-align: middle; text-align:center">Keterangan </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan <?php echo date("F Y",strtotime($blnthn_dari))?>  </th>
		<th style="width:20%; vertical-align: middle; text-align:center"> Bulan <?php echo date("F Y",strtotime($blnthn_samp))?>  </th>
	</tr>
	
	<?php $i=0; foreach($data_biaya as $data) {$i++ ?>
	<tr>
	<?php if ($data->induk_akun != '') {$i++ ?>
		<td class="h_tengah"><?php echo $i?>  </td>
		<td><?php echo $data->no_akun.' - '.$data->nama_akun; ?></td>
		<td class="h_kanan"><?php echo number_format($data->valueold,2,',','.');?></td>
		<td class="h_kanan"><?php echo number_format($data->value,2,',','.');?></td>
	
	<?php } else {$i=0;?>
		<td class="h_tengah fa fa-h-square"></td>
		<td><strong><?php echo $data->no_akun.' - '.$data->nama_akun; ?></strong></td>
		<td class="h_kanan"></td>
		<td class="h_kanan"></td>
	<?php }?>
	</tr>
	<?php }?>
	<tr class="header_kolom">
		<td colspan="2" class="h_kanan"> Jumlah Biaya</td>
		<td class="h_kanan"><?php echo number_format($total_biaya->valueold,2,',','.')?></td>
		<td class="h_kanan"><?php echo number_format($total_biaya->value,2,',','.')?></td>
	</tr>

	<?php }?>
</table>
<table width="100%">
<?php if ($jenis_laporan == 1) { ?>
	<tr class="header_kolom" style="background-color: #98FB98;">
		<td colspan="2" class="h_kanan"> Laba Rugi </td>
		<td class="h_kanan"><?php echo number_format($grandtotal - $total_biaya->value,2,',','.')?></td>
	</tr>
<?php } else {?>
	<tr class="header_kolom" style="background-color: #98FB98;">
		<td style="width:5%; vertical-align: middle; text-align:center" >  </th>
		<td style="width:50%; vertical-align: middle; text-align:right">Laba Rugi </th>
		<td style="width:20%; vertical-align: middle; text-align:right"> <?php echo number_format($total_dapat->valueold - $total_biaya->valueold,2,',','.')?>  </th>
		<td style="width:20%; vertical-align: middle; text-align:right"><?php echo number_format($total_dapat->value - $total_biaya->value,2,',','.')?> </th>
	</tr>
	<?php }?>
</table>
</div>
</div>

<script type="text/javascript">
$(document).ready(function() {
	fm_filter_tgl();
	$('#jenis_laporan').val(<?php echo isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1?>);

}); // ready

function fm_filter_tgl() {
	$('#daterange-btn').daterangepicker({
		ranges: {
			'Tahun ini': [moment().startOf('year').startOf('month'), moment().endOf('year').endOf('month')],
			'Tahun kemarin': [moment().subtract('year', 1).startOf('year').startOf('month'), moment().subtract('year', 1).endOf('year').endOf('month')]
		},
		locale: 'id',
		showDropdowns: true,
		format: 'YYYY-MM-DD',
		<?php 
			if(isset($tgl_dari) && isset($tgl_samp)) {
				echo "
					startDate: '".$tgl_dari."',
					endDate: '".$tgl_samp."'
				";
			} else {
				echo "
					startDate: moment().startOf('year').startOf('month'),
					endDate: moment().endOf('year').endOf('month')
				";
			}
		?>
	},

	function (start, end) {
		doSearch();
	});
}

function clearSearch(){
	window.location.href = '<?php echo site_url("lap_laba"); ?>';
}

function cari() {
	doSearch();
}

function doSearch() {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	var jenis_laporan = $('#jenis_laporan').val();
	$('input[name=tgl_dari]').val(tgl_dari);
	$('input[name=tgl_samp]').val(tgl_samp);
	$('#fmCari').attr('action', '<?php echo site_url('lap_laba'); ?>');
	$('#fmCari').submit();	
}

function cetak () {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	var jenis_laporan = $('#jenis_laporan').val();
	var win = window.open('<?php echo site_url("lap_laba/cetak/?tgl_dari=' + tgl_dari + '&tgl_samp=' + tgl_samp + '&jenis_laporan='+ jenis_laporan"); ?>);
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
	
}

function export_excel() {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	var jenis_laporan = $('#jenis_laporan').val();

	<?php echo site_url('lap_laba/export_excel'); ?>');

	var win = window.open('<?php echo site_url("lap_laba/export_excel/?tgl_dari=' + tgl_dari + '&tgl_samp=' + tgl_samp + '&jenis_laporan='+ jenis_laporan"); ?>);
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
	
}


</script>