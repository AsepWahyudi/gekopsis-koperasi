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
//var_dump($data_asset);die();
?>

<?php
	if(isset($_GET['periode']) && $_GET['periode'] != "") {
		$tanggal = $_GET['periode']; 
	} else {
		$tanggal = "";
	}
		
		//if(is_array($txt_periode_arr)) {
		if(isset($tanggal) && $tanggal != "") {
			$txt_periode_arr = explode('-', $tanggal);
			$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];

			$temp_month = date("F", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
			$temp_year =date("Y", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
		} else {
			$txt_periode =" ";
		}

?>
<div class="row">
	<div class="col-md-12">
		<div class="box box-solid box-primary">
			<div class="box-header">
				<h3 class="box-title"> Cetak Laporan Fixed Asset</h3>
				<div class="box-tools pull-right">
					<button class="btn btn-primary btn-sm" data-widget="collapse">
							<i class="fa fa-minus"></i>
					</button>
				</div>
			</div>
			<div class="box-body">
					<form id="fmCari">
						<table>
							<tr>
								<td> Kode Asset </td>
								<td>
								<input id="kode_asset" name="kode_asset" value="<?php echo $kode_asset?>" style="width:200px; height:25px" class="">
								</td>
							</tr>
							<tr>
								<td> Nama Asset </td>
								<td>
									<input id="nama_asset" name="nama_asset" value="<?php echo $nama_asset?>" style="width:200px; height:25px" class="">
								</td>
							</tr>
							<tr>
							<td> Kategori Asset </td>
							<td>
								<input id="kat_asset" name="kat_asset" value="<?php echo $kat_asset?>" style="width:200px; height:25px" class="">
							</td>
              </tr>
              <tr>
              <td> Period </td>
              <td>
					<div class="input-group date dtpicker col-md-5" data-date="<?php echo $tanggal; ?>">
						<input id="txt_periode" style="width: 125px; text-align: center;" class="form-control" type="text" value="<?php echo $txt_periode;?>" />
						<div class="input-group-addon"><i class="fa fa-calendar"></i></div>
					</div>
					<input type="hidden" name="periode" id="periode" value="<?php echo $tanggal; ?>" />
				</td>
						</tr>
							<tr>
								<td colspan="2">
									<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Lihat Laporan</a>
									<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>
									<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
									<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-xls" plain="false" onclick="eksportExcel()">Ekspor</a>
								</td>
							</tr>
						</table>
					</form>
					<p></p>
					<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Fixed Asset </p>
					<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Periode : <?php echo $periode?> </p>
					<table  class="table table-bordered">
					<tr class="header_kolom">
						<th style="width:13%; vertical-align: middle; text-align:center" > Kode Asset </th>
						<th style="width:25%; vertical-align: middle; text-align:center"> Nama Asset </th>
						<th style="width:8%; vertical-align: middle; text-align:center"> Lokasi Asset </th>
						<th style="width:8%; vertical-align: middle; text-align:center"> Kategori Asset  </th>
						<th style="width:5%; vertical-align: middle; text-align:center"> Status  </th>
						<th style="width:7%; vertical-align: middle; text-align:center"> Tanggal Efektif  </th>
						<th style="width:10%; vertical-align: middle; text-align:center"> Harga Perolehan </th>
						<th style="width:7%; vertical-align: middle; text-align:center"> Usia Fiskal </th>
						<th style="width:10%; vertical-align: middle; text-align:center"> Akumulasi <br> Penyusutan </th>
						<th style="width:15%; vertical-align: middle; text-align:center"> Nilai Buku </th>
						<th style="width:15%; vertical-align: middle; text-align:center"> Depresiasi Per Bulan</th>
					</tr>
					<?php
			
				if (!empty($data_asset)) {
					foreach ($data_asset as $row) {
						$kat_assets = $this->general_m->get_kategori_asset($row->kategori_asset);
						echo '
						<tr>
							<td class="h_kiri" style="vertical-align: middle "> '.$row->kode_asset.'</td>
							<td class="h_kiri" style="vertical-align: middle "><b> '.$row->nama_asset.'</td>
							<td class="h_tengah" style="vertical-align: middle "> '.$row->lokasi_asset.'</td>
							<td class="h_tengah" style="vertical-align: middle" > '.$kat_assets[0]->kategori_asset.'</td>
							<td class="h_tengah" style="vertical-align: middle"> '.$row->status.'  </td>
							<td class="h_tengah" style="vertical-align: middle "> '.jin_date_ina($row->tanggal_efektif,'p').'</td>
							<td class="h_kanan" style="vertical-align: middle "> '.$row->harga_perolehan.'</td>
							<td class="h_kanan" style="vertical-align: middle "> '.$row->usia_fiskal.'</td>
							<td class="h_kanan" style="vertical-align: middle "> '.$row->akumulasi_penyusutan.'</td>
							<td class="h_kanan" style="vertical-align: middle "> '.$row->nilai_buku.'</td>
							<td class="h_kanan" style="vertical-align: middle "> '.$row->depresia.'</td>
						</tr>';
					}
					echo '</table>';
				} else {
					echo '<tr>
						<td colspan="9" >
							<code> Tidak Ada Data <br> </code>
						</td>
					</tr>';
				}
			?>
				</table>
			</div>
		</div>
	</div>
</div>		


<script type="text/javascript">

$(document).ready(function() {
	$(".dtpicker").datetimepicker({
		language:  'id',
		weekStart: 1,
		autoclose: true,
		todayBtn: true,
		todayHighlight: true,
		pickerPosition: 'bottom-right',
		format: "MM yyyy",
		linkField: "periode",
		linkFormat: "yyyy-mm",
		startView: 3,
		minView: 3
	}).on('changeDate', function(ev){
		//doSearch();
	});
  
  <?php 
  if(isset($_GET['periode']) && $_GET['periode'] != "") {
    echo 'var periode = "'.$_GET['periode'].'";';
  } else {
    echo 'var periode = "";';
  }
  echo '$("#periode").val(periode);';
   ?>


	$('#kat_asset').combogrid({
			panelWidth:300,
			url: '<?php echo site_url('lap_fixedasset/list_kat_asset'); ?>',
			idField:'id',
			valueField:'id',
			textField:'nama',
			mode:'remote',
      value:'<?php echo $kat_asset?>',
			fitColumns:true,
			columns:[[
				{field:'id',title:'ID', hidden: true},
				{field:'nama',title:'Kategori Asset',align:'left',width:20}
			]]
		});    

}); // ready

function cetak () {
	var win = window.open('<?php echo site_url("lap_fixedasset/cetak/?")?>kode_asset=' + $('#kode_asset').val() + 
    '&nama_asset=' + $('#nama_asset').val() + '&kat_asset=' + $('#kat_asset').combogrid('getValue') + '&periode=' + $("#periode").val());
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}

function eksportExcel () {
	var win = window.open('<?php echo site_url("lap_fixedasset/export_excel/?")?>kode_asset=' + $('#kode_asset').val() + 
    '&nama_asset=' + $('#nama_asset').val() + '&kat_asset=' + $('#kat_asset').combogrid('getValue') + '&periode=' + $("#periode").val());
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}

function doSearch() {
  var txtperiode = $('#txt_periode').val();
	if (txtperiode !== 'undefined' && txtperiode != ""){
		var periode = $('#periode').val();
	} else {
		var periode = "";
		document.getElementById("periode").value = "";
		document.getElementById("txt_periode").value = "";
	}
	$('#fmCari').attr('action', '<?php echo site_url('lap_fixedasset'); ?>');
	$('#fmCari').submit();
}

function clearSearch(){
	window.location.href = '<?php echo site_url("lap_fixedasset"); ?>';
}
</script>