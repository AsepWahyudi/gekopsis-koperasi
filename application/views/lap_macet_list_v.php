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

	if(isset($_GET['periode']) && $_GET['periode'] != "") {
		$tanggal = $_GET['periode']; 
	} else {
		$tanggal = "";
	}
	
	if(isset($tanggal) && $tanggal != "") {
		$txt_periode_arr = explode('-', $tanggal);
		$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];
		$vlabel="Periode ";
	} else {
		$txt_periode =" ";
		$vlabel= " ";
	}
?>

<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Cetak Laporan Kredit Macet</h3>
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-sm" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
	<div>
		<form id="fmCari" method="GET">
			<table>
				<tr>
					<td>
						<div class="input-group date dtpicker col-md-5" data-date="<?php echo $tanggal; ?>">
							<input id="txt_periode" style="width: 125px; text-align: center;" class="form-control" type="text" value="<?php echo $txt_periode;?>" />
							<div class="input-group-addon"><i class="fa fa-calendar"></i></div>
						</div>
						<input type="hidden" name="periode" id="periode" value="<?php echo $tanggal; ?>" />
					</td>
					<td>
						<input id="jenis_anggota_id" name="jenis_anggota_id" value="" style="width:200px; height:25px" class="">

						<input id="anggota_id" name="anggota_id" value="" style="width:200px; height:25px" class="">
					</td>
					<td>
						<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Lihat Laporan</a>

						<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>

						<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
					
						<a href="<?=base_url()?>lap_macet/export_excel" class="easyui-linkbutton" iconCls="icon-excel" plain="false">Ekspor</a>
					</td>
				</tr>
			</table>
		</form>
	</div>
</div>
</div>

<div class="box box-primary">
<div class="box-body">
<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Kredit Macet  <?php echo $vlabel . $txt_periode; ?> </p>
	<table  class="table table-bordered">
		<tr class="header_kolom">
			<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
			<th style="width:10%; vertical-align: middle; text-align:center">Kode Pinjam</th>
			<th style="width:15%; vertical-align: middle; text-align:center">Nama Anggota</th>
			<th style="width:15%; vertical-align: middle; text-align:center"> Tanggal Pinjam  </th>
			<th style="width:15%; vertical-align: middle; text-align:center"> Tanggal Tempo  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Lama Pinjam  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Mulai Bulan Tertunggak </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Total Bulan Tertunggak </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Jumlah Tagihan  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Dibayar  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Sisa Tagihan  </th>
		</tr>
	<?php
	$no = $offset + 1;
	$jml_tagihan = 0;
	$jml_dibayar = 0;
	$jml_sisa = 0;
	$jmlblntunggak = 0;
	//var_dump($data_tempo);die();
	$mulainunggak="-";
	foreach ($data_tempo as $rows) {
	if(($no % 2) == 0) {
		$warna="#eeeeee"; } 
	else {
		$warna="#FFFFFF"; }
		
		$tgl_pinjam = explode(' ', $rows->tgl_pinjam);
		$tgl_pinjam = jin_date_ina($tgl_pinjam[0],'p');

		$tgl_tempo = explode(' ', $rows->tempo);
		$tgl_tempo1 = jin_date_ina($tgl_tempo[0],'p');
		
		$jml_bayar = $this->general_m->get_jml_bayar($rows->id); 
		$jml_denda = $this->general_m->get_jml_denda($rows->id); 
		$total_tagihan = $rows->tagihan + $jml_denda->total_denda;
		$sisa_tagihan = $total_tagihan - $jml_bayar->total;

		$jml_tagihan += $total_tagihan;
		$jml_dibayar += $jml_bayar->total;
		$jml_sisa += $sisa_tagihan;

    $denda_hari = $conf_bunga['denda_hari'];
    $jmlangscurrent = 0;
			
    for ($z=1; $z <= $rows->lama_angsuran; $z++) { 
      $tgl = date("d", strtotime($rows->tgl_pinjam));
      $bln = date("m", strtotime($rows->tgl_pinjam));
      $thn = date("Y", strtotime($rows->tgl_pinjam));
      $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
      $tgl_tempo_var = $tglpinjam;
      $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$z." month"));
      $date_now = date("Y-m-d");
      if(date("m",strtotime($tgl_tempo)) == date("m",strtotime($date_now))){
        if($date_now > $tgl_tempo){
          $jmlangscurrent = $z;
        } else {
        $jmlangscurrent = $z -1;
      } 
				
        if ($jmlangscurrent > $rows->bulan_sdh_angsur) {
          $jmlblntunggak = $jmlangscurrent - $rows->bulan_sdh_angsur;
          if ($rows->bulan_sdh_angsur > 0) {
            $jmltgk = $rows->bulan_sdh_angsur + 1;
            $mulainunggak = date("m", strtotime($tglpinjam . " +".$jmltgk." month"));
            $mulainunggak = jin_nama_bulan($mulainunggak);
            
          } else {
            $mulainunggak = date("m", strtotime($rows->tgl_pinjam . " +1 month"));
            $mulainunggak = jin_nama_bulan($mulainunggak);
          }
        } 	
        break;
      } 
    }
	
if ($jmlblntunggak > 0) {
	echo '<tr bgcolor='.$warna.'>
				<td class="h_tengah">'.$no++.'</td>
				<td class="h_tengah">'.$rows->nomor_pinjaman.'</td>
				<td class="h_kiri">'.$rows->nama.'</td>
				<td class="h_tengah">'.$tgl_pinjam.'</td>
				<td class="h_tengah">'.$tgl_tempo1.'</td>
				<td class="h_tengah">'.$rows->lama_angsuran.' Bulan</td>
				<td class="h_tengah">'.$mulainunggak.'</td>
				<td class="h_tengah">'.$jmlblntunggak.' Bulan</td>
				<td class="h_kanan">'.number_format(nsi_round($total_tagihan),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($jml_bayar->total),2,',','.').'</td>
				<td class="h_kanan">'.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
      </tr>';
} else {
  $jml_tagihan = $jml_tagihan - $total_tagihan;
  $jml_dibayar = $jml_dibayar - $jml_bayar->total;
  $jml_sisa = $jml_sisa - $sisa_tagihan;
}
	}
	echo '<tr class="header_kolom">
				<td colspan="8" class="h_tengah"><strong>Jumlah Total</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tagihan),2,',','.').'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_dibayar),2,',','.').'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_sisa),2,',','.').'</strong></td>
			</tr>';
	echo '</table>
		<div class="box-footer">'.$halaman.'</div>';

		
	?>
</div>
</div>
	
<script type="text/javascript">
$(document).ready(function() {
	//fm_filter_tgl();
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
		echo '$("#periode").val(periode);$("#txt_periode").val(periode);';

		if(isset($_GET['anggota_id'])) {
			echo 'var anggota_id = "'.$_GET['anggota_id'].'";';
		} else {
			echo 'var anggota_id = "";';
		}
		echo '$("#anggota_id").val(anggota_id);';
		
		if(isset($_GET['jenis_anggota_id'])) {
			echo 'var jenis_anggota_id = "'.$_GET['jenis_anggota_id'].'";';
		} else {
			echo 'var jenis_anggota_id = "";';
		}
		echo '$("#jenis_anggota_id").val(jenis_anggota_id);';
	?>

		
	$('#jenis_anggota_id').combogrid({
		panelWidth:300,
		url: '<?php echo site_url('lap_anggota/list_anggota'); ?>',
		idField:'id',
		valueField:'id',
		textField:'nama',
		mode:'remote',
		fitColumns:true,
		columns:[[
			{field:'id', title:'ID', align:'center', width:15},
			{field:'nama',title:'Nama Anggota',align:'left',width:20}
		]]
		/*
		,onSelect:function(record){
			show_anggota($('input[name=jenis_anggota_id]').val())
			$('input[name=anggota_id]').val('')
			doSearch();
		}
		*/
	});
	
	$('#anggota_id').combogrid({
		panelWidth:300,
		url: '<?php echo site_url('lap_shu_anggota/list_anggota'); ?>'+'/'+jenis_anggota_id ,
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
		]]
		/*,
		onSelect:function(record){
			doSearch()
		}
		*/
	});	
}); // ready

function show_anggota(id){
	$('#anggota_id').combogrid({
		panelWidth:300,
		url: '<?php echo site_url('lap_shu_anggota/list_anggota'); ?>'+'/'+id ,
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
		onSelect:function(record){
			doSearch()
		}
	});
}

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
	window.location.href = '<?php echo site_url("lap_macet"); ?>';
}

function doSearch() {
	var jenis_anggota_id = $('#jenis_anggota_id').val();
	var anggota_id = $('#anggota_id').val();
	var txtperiode = $('#txt_periode').val();
	if (txtperiode !== 'undefined' && txtperiode != ""){
		var periode = $('#periode').val();
	} else {
		var periode = "";
		document.getElementById("periode").value = "";
		document.getElementById("txt_periode").value = "";
	}
	
	$('#fmCari').attr('action', '<?php echo site_url('lap_macet'); ?>');
	$('#fmCari').submit();	
}

function cetak () {
	var jenis_anggota_id = $('#jenis_anggota_id').val();
	var anggota_id = $('#anggota_id').val();
	var txtperiode = $('#txt_periode').val();
	if (txtperiode !== 'undefined' && txtperiode != ""){
		var periode = $('#periode').val();
	} else {
		var periode = "";
		document.getElementById("periode").value = "";
		document.getElementById("txt_periode").value = "";
	}

	var win = window.open('<?php echo site_url("lap_macet/cetak/?periode=' + periode +'&jenis_anggota_id=' + jenis_anggota_id + '&anggota_id=' + anggota_id + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}

}
</script>