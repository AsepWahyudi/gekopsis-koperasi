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
if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
	$tgl_dari = $_REQUEST['tgl_dari'];
	$tgl_samp = $_REQUEST['tgl_samp'];
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
		<h3 class="box-title">Cetak Laporan SHU</h3>
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-sm" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
		<form id="fmCari" method="POST">
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
					<!-- <a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a> -->

					<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
				</td>
			</tr>
		</table>

	</div>
</div>

<div class="box box-primary">
	<div class="box-body">
		<p></p>
		<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Toko <br> Periode 01 Jan 2019 - 31 Des 2019 </p>
		<table class="table table-bordered">
			<tbody>
			<tr class="header_kolom">
				<th style="width:5%; vertical-align: middle; text-align:center"> No. </th>
				<th style="width:15%; vertical-align: middle; text-align:center">Nama Barang </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Stok Awal </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Barang Masuk(Qty)</th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Barang Masuk(Rp)</th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Barang Keluar (Qty)</th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Barang Keluar (Rp)</th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Stok Akhir</th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Penghasilan (Rp)</th>
			</tr>
			<?php $n=0; foreach($all['data'] as $is){ $n++;?>
			<tr>
				<td class="h_tengah"><?php echo $n; ?></td>
				<td><?php echo ucwords($is->nm_barang); ?></td>
				<td class="h_kanan"><?php echo number_format($is->jumlah); ?></td>
				<td class="h_kanan"><?php echo number_format($is->jml_masuk); ?></td>
				<td class="h_kanan"><?php echo number_format($is->hrg_masuk); ?></td>
				<td class="h_kanan"><?php echo number_format($is->jml_keluar); ?></td>
				<td class="h_kanan"><?php echo number_format($is->hrg_keluar); ?></td>
				<td class="h_kanan"><?php echo number_format($is->jumlah-$is->jml_keluar); ?></td>
				<td class="h_kanan"><label style="color:">0</label></td>
			</tr>
			<?php } ?>
			</tbody>
		</table>
	</div>
</div>
</form>

<script type="text/javascript">
	$(document).ready(function() {
		$('#anggota_id').combogrid({
			panelWidth:300,
			url: '<?php echo site_url('lap_shu_anggota/list_anggota'); ?>' ,
			idField:'id',
			valueField:'id',
			textField:'id_nama',
			mode:'remote',
			fitColumns:true,
			columns:[[
			{field:'photo',title:'Photo',align:'center',width:5},
			{field:'id',title:'ID', hidden: true},
			{field:'id_nama', title:'IDNama', hidden: true},
			{field:'kode_anggota', title:'ID', align:'center', width:15},
			{field:'nama',title:'Nama Anggota',align:'left',width:20}
			]],
			onChange:function(value) {
			//doSearch();
		}
	});
		<?php if(isset($_POST['anggota_id'])) { ?>
			$('#anggota_id').combogrid('setValue', '<?php echo $_POST['anggota_id']; ?>');
			<?php } ?>

			fm_filter_tgl();

	//doSearch();
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

	function clearSearch(){
		window.location.href = '<?php echo site_url("lap_toko"); ?>';
	}

	function doSearch() {
		var tgl_dari = $('input[name=daterangepicker_start]').val();
		var tgl_samp = $('input[name=daterangepicker_end]').val();
		$('input[name=tgl_dari]').val(tgl_dari);
		$('input[name=tgl_samp]').val(tgl_samp);
		$('#fmCari').attr('action', '<?php echo site_url('lap_toko'); ?>');
		$('#fmCari').submit();
	}

	function cetak () {	

		var tgl_dari = $('input[name=daterangepicker_start]').val();
		var tgl_samp = $('input[name=daterangepicker_end]').val();
		var js_modal = $('#js_modal').val();
		var js_usaha = $('#js_usaha').val();
		var tot_pendpatan = $('#tot_pendpatan').val();
		var tot_simpanan = $('#tot_simpanan').val();

		$('input[name=tgl_dari]').val(tgl_dari);
		$('input[name=tgl_samp]').val(tgl_samp);

		var win = window.open('<?php echo site_url("lap_toko/cetak_laporan/?anggota_id=' + anggota_id + '&tgl_dari='+ tgl_dari +'&tgl_samp='+ tgl_samp +'&js_modal='+ js_modal +'&js_usaha='+ js_usaha +'&tot_pendpatan='+ tot_pendpatan +'&tot_simpanan='+ tot_simpanan +'"); ?>');
		if (win) {
			win.focus();
		} else {
			alert('Popup jangan di block');
		}

	//$('#fmCari').attr('action', '<?php echo site_url('lap_shu_anggota/cetak_laporan'); ?>');
	//$('#fmCari').submit();
}
</script>