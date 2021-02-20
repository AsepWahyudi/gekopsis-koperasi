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

<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Tagihan Angsuran Pinjaman </h3>
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
				
					<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-excel" plain="false" onclick="eksportExcel()">Ekspor</a>
				</td>
			</tr>
		</table>
		</form>
</div>
</div>
</div>

<div class="box box-primary">
<div class="box-body">
<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Tagihan Angsuran Pinjaman<br> <?php echo $txt_periode; ?> </p>
	<table  class="table table-bordered">
		<tr class="header_kolom">
			<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
			<th style="width:10%; vertical-align: middle; text-align:center">No Pinjaman</th>
			<th style="width:15%; vertical-align: middle; text-align:center">Nama Anggota</th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Rekening  </th>
			<th style="width:15%; vertical-align: middle; text-align:center"> Tanggal Pinjam  </th>
			<th style="width:15%; vertical-align: middle; text-align:center"> Tanggal Tempo  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Lama Pinjam  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Simpanan Wajib  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Angsuran Pokok </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Angsuran Bunga </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Administrasi Angsuran </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Jumlah Tagihan  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Tunggakan  </th>
			<th style="width:10%; vertical-align: middle; text-align:center"> Sisa Tagihan  </th>
		</tr>
	<?php

	$no = $offset + 1;
	$jml_tagihan = 0;
	$jml_dibayar = 0;
	$jml_sisa = 0;
	$jml_tunggakan = 0;
  $ketemu = '';
	foreach ($data_tempo as $rows) {
		if(($no % 2) == 0) {
			$warna="#eeeeee"; 
		} else {
			$warna="#FFFFFF"; 
		}

		if ($tanggal != "") {
      for ($i=1; $i <= $rows->lama_angsuran; $i++) { 
        if($rows->tenor == 'Bulan'){
          $temp_tgl_tempo_var = substr($rows->tgl_pinjam, 0, 10);
          $temp_tgl_tempo = date("Y-m-d", strtotime($temp_tgl_tempo_var . " +".$i." month"));
        }
        else if($rows->tenor == 'Minggu'){
          $temp_tgl_tempo_var = $rows->tgl_pinjam;
          $temp_tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." week"));
        }
        else{
          $tgl_tempo_var = $rows->tgl_pinjam;
          $temp_tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." day"));
        }
        $month=date("F",strtotime($temp_tgl_tempo));
        $year=date("Y",strtotime($temp_tgl_tempo));
        if ($temp_month === $month && $temp_year === $year) {
          $ketemu = 'Y';
          break;
        } else {
          $ketemu = 'N';
        }
      }
    }
    $total_tagihan = 0;
    $sisa_tagihan = 0;
    $total_tunggakan = 0;
	if ($ketemu == 'Y' || $ketemu == "") {
		
		$tgl_pinjam = explode(' ', $rows->tgl_pinjam);
		$tgl_pinjam = jin_date_ina($tgl_pinjam[0],'p');

		$tgl_tempo = explode(' ', $rows->tempo);
		$tgl_tempo = jin_date_ina($tgl_tempo[0],'p');

		$jml_bayar = $this->general_m->get_jml_bayar($rows->id); 
    $jml_denda = $this->general_m->get_jml_denda($rows->id); 
    
    $tunggakan = 0;
    if ($rows->jenis_pinjaman == 9) {
      $total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $rows->adminangsuran;
      $sisa_tagihan = ($total_tagihan * $rows->lama_angsuran) - $jml_bayar->total;
    } else {
      $total_tagihan = $rows->pokok_angsuran + $rows->bunga_pinjaman + $s_wajib->jumlah;
      $sisa_tagihan = ($rows->pokok_angsuran * $rows->lama_angsuran) - $jml_bayar->total;
    }

    if ($rows->bln_sudah_angsur != 0) {
      $tunggakan = ($rows->ags_per_bulan + $s_wajib->jumlah) * $rows->bln_sudah_angsur;
      if ($tunggakan > $jml_bayar->total){
        $total_tunggakan = $tunggakan - $jml_bayar->total;
      } else {
        $total_tunggakan = 0;
      }
    } else {
      $tunggakan = ($rows->ags_per_bulan + $s_wajib->jumlah) * $rows->selisih_bulan;
      if ($tunggakan > $jml_bayar->total){
        $total_tunggakan = $tunggakan - $jml_bayar->total;
      } else {
        $total_tunggakan = 0;
      }
    }

		$jml_tagihan += $total_tagihan;
		$jml_dibayar += $jml_bayar->total;
		$jml_sisa += $sisa_tagihan;
    $jml_tunggakan += $total_tunggakan;
    
    if ($rows->jenis_pinjaman == 9) {
      echo '<tr bgcolor='.$warna.'>
					<td class="h_tengah">'.$no++.'</td>
					<td class="h_tengah">'.$rows->nomor_pinjaman.'</td>
					<td class="h_kiri">'.$rows->ktp.' - '.$rows->nama.'</td>
					<td class="h_kanan">'.$rows->rekening.'</td>
					<td class="h_tengah">'.$tgl_pinjam.'</td>
					<td class="h_tengah">'.$tgl_tempo.'</td>
					<td class="h_tengah">'.$rows->lama_angsuran.' Bulan</td>
					<td class="h_tengah">'.number_format(nsi_round(0),2,',','.').'</td>
					<td class="h_tengah">'.number_format(nsi_round($rows->pokok_angsuran),2,',','.').'</td>
					<td class="h_tengah">'.number_format(nsi_round($rows->bunga_pinjaman),2,',','.').'</td>
					<td class="h_tengah">'.number_format(nsi_round($rows->adminangsuran),2,',','.').'</td>
					<td class="h_kanan">'.number_format(nsi_round($total_tagihan),2,'.',',').'</td>
					<td class="h_kanan">'.number_format(nsi_round($total_tunggakan),2,',','.').'</td>
					<td class="h_kanan">'.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
        </tr>';
    } else {
      echo '<tr bgcolor='.$warna.'>
          <td class="h_tengah">'.$no++.'</td>
          <td class="h_tengah">'.$rows->nomor_pinjaman.'</td>
          <td class="h_kiri">'.$rows->ktp.' - '.$rows->nama.'</td>
          <td class="h_kanan">'.$rows->rekening.'</td>
          <td class="h_tengah">'.$tgl_pinjam.'</td>
          <td class="h_tengah">'.$tgl_tempo.'</td>
          <td class="h_tengah">'.$rows->lama_angsuran.' Bulan</td>
          <td class="h_tengah">'.number_format(nsi_round($s_wajib->jumlah),2,',','.').'</td>
          <td class="h_tengah">'.number_format(nsi_round($rows->pokok_angsuran),2,',','.').'</td>
          <td class="h_tengah">'.number_format(nsi_round($rows->bunga_pinjaman),2,',','.').'</td>
          <td class="h_tengah">'.number_format(nsi_round(0),2,',','.').'</td>
          <td class="h_kanan">'.number_format(nsi_round($total_tagihan),2,'.',',').'</td>
          <td class="h_kanan">'.number_format(nsi_round($total_tunggakan),2,',','.').'</td>
          <td class="h_kanan">'.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
        </tr>';
      }
		}
	}
	echo '<tr class="header_kolom">
				<td colspan="11" class="h_tengah"><strong>Jumlah Total</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tagihan),2,',','.').'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_tunggakan),2,',','.').'</strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($jml_sisa),2,',','.').'</strong></td>
			</tr>';
	echo '</table>
	<div class="box-footer">'.$halaman.'</div>';

	?>
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

		if(isset($_GET['anggota_id']) && $_GET['anggota_id'] != "" ) {
			echo 'var anggota_id = "'.$_GET['anggota_id'].'";';
		} else {
			echo 'var anggota_id = "";';
		}
		echo '$("#anggota_id").val(anggota_id);';
		
		if(isset($_GET['jenis_anggota_id']) && $_GET['jenis_anggota_id'] != "") {
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
			{field:'id', title:'ID', align:'left', width:10},
			{field:'nama',title:'Jenis Anggota',align:'left',width:25}
		]],
		onSelect:function(record){
			//show_anggota($('input[name=jenis_anggota_id]').val())
			//$('input[name=anggota_id]').val('')
			//doSearch();
		}
		
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
		]],
		onSelect:function(record){
			//doSearch()
		}
		
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
	$('#fmCari').attr('action', '<?php echo site_url('lap_tempo'); ?>');
	$('#fmCari').submit();
}

function clearSearch(){
	window.location.href = '<?php echo site_url("lap_tempo"); ?>';
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

	var periode = $('#periode').val();
	var win = window.open('<?php echo site_url("lap_tempo/cetak/?periode=' + periode +'&jenis_anggota_id=' + jenis_anggota_id + '&anggota_id=' + anggota_id + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}

}



function eksportExcel () {
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

	var periode = $('#periode').val();
	var win = window.open('<?php echo site_url("lap_tempo/export_excel/?periode=' + periode +'&jenis_anggota_id=' + jenis_anggota_id + '&anggota_id=' + anggota_id + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}

}

</script>