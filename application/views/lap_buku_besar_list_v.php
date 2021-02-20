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

<?php 
	if(isset($_GET['tgl_dari']) && isset($_GET['tgl_samp'])) {
		$tgl_dari = $_GET['tgl_dari'];
		$tgl_samp = $_GET['tgl_samp'];
	} else {
		$tgl_dari = date('Y') . '-01-01';
		$tgl_samp = date('Y') . '-12-31';
	}
	$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
	$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
	$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;
?>

<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Cetak Laporan Buku Besar</h3>
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
							<i class="fa fa-calendar"></i> <span id="reportrange"><span><?php echo $tgl_periode_txt; ?>
							</span></span>
							<i class="fa fa-caret-down"></i>
						</button>
					</div>
				</td>
				<td>
					<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Cari Laporan</a>

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
<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Buku Besar Periode <?php echo $tgl_periode_txt; ?></p>

<?php

$total_saldo = 0;
$jmlD = 0;
$jmlk = 0;
foreach ($jenis_akun as $data=> $key) {
	//var_dump('akun', $key->jns_akun_id);die();
	$transJ = $this->lap_buku_besar_m->get_data_journal_id($key->jns_akun_id);
	?>
	<h3><strong><?php echo $key->no_akun.' '.$key->nama_akun?></strong></h3>
	<table  class="table table-bordered">
				<tr class="header_kolom">
					<th class="h_tengah" style="width:5%; vertical-align: middle "> No</th>
					<th class="h_tengah" style="width:10%; vertical-align: middle "> No Jurnal</th>
					<th class="h_tengah" style="width:10%; vertical-align: middle "> Tanggal </th>
					<th class="h_tengah" style="width:30%; vertical-align: middle "> Keterangan </th>
					<th class="h_tengah" style="width:20%; vertical-align: middle "> Cabang </th>
					<th class="h_tengah" style="width:10%; vertical-align: middle "> Debet </th>
					<th class="h_tengah" style="width:10%; vertical-align: middle "> Kredit </th>
					<th class="h_tengah" style="width:10%; vertical-align: middle "> Saldo </th>
	</tr>
	<?php
	$no = 1;
	$saldo = 0;
	$namaakun="";
	$keterangan="";
	$nomorakun="";
	//$jmlD = $jmlD;
	//$jmlk = $jmlk;
	$jmlD = 0;
	$jmlk = 0;
	foreach ($transJ as $dataJ=> $rows) {
    //$nm_akun = $this->lap_buku_besar_m->get_nama_akun_id($rows->transaksi);
		$tglD = explode(' ', $rows->journal_date);
		$txt_tanggalD = jin_date_ina($tglD[0],'p');

		if($key->no_akun !=""){
			$nomorakun = $key->no_akun;
		} else {
			$nomorakun = "-";
		}

		if($key->nama_akun !=""){
			$namaakun = $key->nama_akun;
		} else {
			$namaakun = "-";
		}

		if($rows->itemnote != ""){
			$keterangan = $rows->itemnote;
		} else {
			$keterangan = "-";
		}

		if($rows->credit != 0) {
			$jmlk += $rows->credit;
			$rows->debit = 0;
		}
		if($rows->debit != 0) {
			$jmlD += $rows->debit;
			$rows->credit = 0;
		}
				
		$saldo = $jmlD - $jmlk;?>
		<tr>
      <td class="h_tengah"><?php echo $no++?></td>
      <td><?php echo $rows->journal_no?></td>
      <td class="h_tengah"><?php echo $txt_tanggalD?></td>
      <td><?php echo $keterangan?></td>
      <td><?php echo $rows->kode_cabang?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($rows->debit),2,',','.')?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($rows->credit),2,',','.')?></td>
	  <?php if ($rows->debit != 0) {?>
      	<td class="h_kanan"><?php echo number_format(nsi_round($rows->debit),2,',','.')?></td>
	 <?php } else if ( $rows->credit != 0) { ?>
		<td class="h_kanan"><?php echo number_format(nsi_round($rows->credit),2,',','.')?></td>
	 <?php } else {?>	
		<td class="h_kanan"><?php echo number_format(nsi_round(0),2,',','.')?></td>
	 <?php } ?>  
    </tr>
  <?php } ?>
  </table>
	<br><table  class="table table-bordered">
				<tr class="header_kolom">
					<td class="h_kanan">TOTAL SALDO <?php echo $key->no_akun . ' ' .$key->nama_akun?></td>
					<td class="h_kanan"><?php echo number_format(nsi_round($saldo),2,',','.')?></td>
					
				</tr>
			</table>
	<?php 
	//$total_saldo += $saldo;
	}
	
?>
</div>
</div>

<script type="text/javascript">
$(document).ready(function() {
	fm_filter_tgl();
}); // ready

function fm_filter_tgl() {
	$('#daterange-btn').daterangepicker({
		ranges: {
			'Hari ini': [moment(), moment()],
			'Kemarin': [moment().subtract('days', 1), moment().subtract('days', 1)],
			'7 Hari yang lalu': [moment().subtract('days', 6), moment()],
			'30 Hari yang lalu': [moment().subtract('days', 29), moment()],
			'Bulan ini': [moment().startOf('month'), moment().endOf('month')],
			'Bulan kemarin': [moment().subtract('month', 1).startOf('month'), moment().subtract('month', 1).endOf('month')],
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

function doSearch() {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	$('input[name=tgl_dari]').val(tgl_dari);
	$('input[name=tgl_samp]').val(tgl_samp);
	$('#fmCari').attr('action', '<?php echo site_url('lap_buku_besar'); ?>');
	$('#fmCari').submit();	
}
function clearSearch(){
	window.location.href = '<?php echo site_url("lap_buku_besar"); ?>';
}

function cetak () {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();

	var win = window.open('<?php echo site_url("lap_buku_besar/cetak?tgl_dari=' + tgl_dari + '&tgl_samp=' + tgl_samp + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}

function export_excel() {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	<?php echo site_url('lap_buku_besar/export_excel'); ?>');

	var win = window.open('<?php echo site_url("lap_buku_besar/export_excel/?tgl_dari=' + tgl_dari + '&tgl_samp=' + tgl_samp + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}
</script>