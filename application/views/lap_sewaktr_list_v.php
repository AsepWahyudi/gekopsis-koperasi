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
	$vtgl_periode_txt = "";
?>

<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Sewa Kantor</h3>
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-sm" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
		<div>
			<form id="fmCari">
				<table>
					<tr>
						<td> Pilih Cabang </td>
						<td>
							<input id="cabang_id" name="cabang_id" value="" style="width:200px; height:25px" class="">
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Lihat Laporan</a>
							<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>
							<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
							<a href="<?=base_url()?>lap_kas_anggota/export_excel" class="easyui-linkbutton" iconCls="icon-excel" plain="false">Ekspor</a>
						</td>
					</tr>
				</table>
			</form>
		</div>
	</div>
</div>

<div class="box box-primary">
<div class="box-body">
<p></p>
	<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Biaya Bayar di Muka </p>
	<table  class="table table-bordered">
		<tr class="header_kolom">
			<th class="h_tengah" style="width:3%; vertical-align: middle" > No. </th>
			<th class="h_tengah" style="width:3%; vertical-align: middle" > Cabang </th>
			<th class="h_tengah" style="width:3%; vertical-align: middle" > Saldo </th>
			<th class="h_tengah" style="width:5%; vertical-align: middle" colspan="13"> Bulan Sewa </th>
		</tr>
	<?php 
$no = 1;
$temp_tgl_tempo_var = "";
$temp_tgl_tempo ="";
$tgl_awalsewa = "";
$jml_saldo = 0;
$jml_sewa = 0;

foreach ($data_sewakantor as $rows) {
	$jml_sewa=0;
	if(($no % 2) == 0) {
		$warna="#eeeeee"; 
	} else {
		$warna="#FFFFFF"; 
	}
	$cabang = $this->general_m->get_jns_cabang($rows->cabang_id);
	$tgl_awalsewa = explode(' ', $rows->awal_sewa);
	$tgl_awalsewa = jin_date_ina($tgl_awalsewa[0],'p');
	$saldo = $rows->saldo;
	$jml_saldo += $saldo;
	$biayasewa = $rows->saldo / $rows->jangka_waktu;
	echo '<tr>
				<td class="h_tengah" rowspan="4">'.$no++.'</td>
				<td class="h_tengah" rowspan="4">'.$cabang[0]->nama_cabang.'</td>
				<td class="h_tengah" rowspan="4">'.number_format(nsi_round($rows->saldo),2,',','.').'</td>
				<tr><tr class="header_kolom">';
				for ($i=1; $i <= $rows->jangka_waktu; $i++) { 
					$temp_tgl_tempo_var = $rows->awal_sewa; //$tgl_awalsewa;
					$temp_tgl_tempo = date("M Y", strtotime($temp_tgl_tempo_var . " +".($i-1)." month"));
					echo '<td class="h_tengah">'.$temp_tgl_tempo.' </td>';
					
				}
				echo '<td>Total</td>
				</tr><tr>';
				for ($i=1; $i <= $rows->jangka_waktu; $i++) { 
					echo '<td class="h_kanan">'.number_format(nsi_round($biayasewa),2,',','.').' </td>';
					$jml_sewa += $biayasewa;
				}
				echo '<td class="h_kanan">'.number_format(nsi_round($jml_sewa),2,',','.').'</td>
			</tr>';
	
}
	echo '</table>
	<div class="box-footer">'.$halaman.'</div>';
?>
</div>
</div>


<script type="text/javascript">
$(document).ready(function() {
	fm_filter_tgl();
	<?php 
		if(isset($_REQUEST['cabang_id'])) {
			echo 'var cabang_id = "'.$_REQUEST['cabang_id'].'";';
		} else {
			echo 'var cabang_id = "";';
		}
		echo '$("#cabang_id").val(cabang_id);';
	?>

	$('#cabang_id').combogrid({
			panelWidth:300,
			url: '<?php echo site_url('lap_sewa_kantor/list_cabang'); ?>'+'/'+cabang_id ,
			idField:'id',
			valueField:'id',
			textField:'nama',
			mode:'remote',
			fitColumns:true,
			columns:[[
				{field:'id',title:'ID', hidden: true},
				{field:'nama',title:'Nama Cabang',align:'left',width:20}
			]]
		});

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
	window.location.href = '<?php echo site_url("lap_sewa_kantor"); ?>';
}

function doSearch() {
	$('#fmCari').attr('action', '<?php echo site_url('lap_sewa_kantor'); ?>');
	$('#fmCari').submit();	
}

function cetak () {
	var cabang = $('#cabang_id').val();
	var win = window.open('<?php echo site_url("lap_sewa_kantor/cetak/?cabang=' + cabang + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}
</script>