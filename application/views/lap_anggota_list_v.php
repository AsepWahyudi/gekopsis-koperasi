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

<div class="row">
	<div class="col-md-12">
		<div class="box box-solid box-primary">
			<div class="box-header">
				<h3 class="box-title"> Cetak Laporan Data Anggota</h3>
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
						<td> Pilih Jenis Anggota </td>
						<td>
						 <input id="jenis_anggota_id" name="jenis_anggota_id" value="" style="width:200px; height:25px" class="">
						</td>
					</tr>
					<tr>
						<td> Pilih ID Anggota </td>
						<td>
							<input id="anggota_id" name="anggota_id" value="" style="width:200px; height:25px" class="">
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
			<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Data Anggota </p>
			<table  class="table table-bordered">
			<tr class="header_kolom">
				<th style="width:4%; vertical-align: middle; text-align:center" > No. </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> ID Anggota </th>
				<th style="width:25%; vertical-align: middle; text-align:center"> Nama Anggota </th>
				<th style="width:3%; vertical-align: middle; text-align:center"> L/P  </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Jabatan  </th>
				<th style="width:20%; vertical-align: middle; text-align:center"> Alamat </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Status </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Tgl Registrasi </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Category </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Nomor Rekening </th>
				<th style="width:10%; vertical-align: middle; text-align:center"> Nama Rekening </th>
				<th style="width:10%; vertical-align: middle; text-align:center">Photo</th>
			</tr>

			<?php
				$no = $offset + 1;
				$mulai=1;
				if (!empty($data_anggota)) {

					foreach ($data_anggota as $row) {

						if(($no % 2) == 0) {
							$warna="#EEEEEE";
						} else {
							$warna="#FFFFFF";
						}

						//photo
						$photo_w = 3 * 15;
						$photo_h = 4 * 15;
						if($row->file_pic == '') {
							$photo ='<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="'.$photo_w.'" height="'.$photo_h.'" />';
						} else {
							$photo= '<img src="'.base_url().'uploads/anggota/' . $row->file_pic . '" alt="Foto" width="'.$photo_w.'" height="'.$photo_h.'" />';
						}

						//jabatan
						if ($row->jabatan_id == "1"){
							$jabatan="Pengurus"; 
						} else {
							$jabatan="Anggota";
						}

						//status
						if ($row->aktif == "Y"){
							$status="Aktif";
						} else {
							$status="Non-Aktif";
						}

						$tgl_reg  = explode(' ', $row->tgl_daftar);
						$txt_tanggal = jin_date_ina($tgl_reg[0],'p');

						$tgl_lahir = explode(' ', $row->tgl_lahir);
						$txt_lahir = jin_date_ina($tgl_lahir[0],'full');

						$category=$this->lap_anggota_m->get_data_category($row->jns_anggotaid);
						// AG'.sprintf('%04d', $row->id).'
						echo '
						<tr bgcolor='.$warna.' >
						<td class="h_tengah" style="vertical-align: middle "> '.$no++.' </td>
						<td class="h_tengah" style="vertical-align: middle "> '.$row->ktp.'</td>
						<td class="h_kiri" style="vertical-align: middle "><b> '.$row->no_anggota.'-'.strtoupper($row->nama).'</b> <br> '.$row->tmp_lahir.', '.$txt_lahir.'</td>
						<td class="h_tengah" style="vertical-align: middle "> '.$row->jk.'</td>
						<td class="h_tengah" style="vertical-align: middle" > '.$jabatan.'<br>'.$row->departement.'</td>
						<td style="vertical-align: middle"> '.$row->alamat.' <br> Telp. '. $row->notelp.'  </td>
						<td class="h_tengah" style="vertical-align: middle "> '.$status.'</td>
						<td class="h_tengah" style="vertical-align: middle "> '.$txt_tanggal.'</td>
						<td class="h_tengah" style="vertical-align: middle "> '.$category->nama.'</td>
						<td class="h_tengah" style="vertical-align: middle "> '.$row->nomor_rekening.'</td>
						<td class="h_tengah" style="vertical-align: middle "> '.$row->nama_bank.'</td>
						<td class="h_tengah" style="vertical-align: middle "> '.$photo.'</td>
						</tr>';
					}
					echo '</table>
					<div class="box-footer">'.$halaman.'</div>';
				} else {
					echo '<tr>
						<td colspan="9" >
							<code> Tidak Ada Data <br> </code>
						</td>
					</tr>';
				}
			?>
			</div>
		</div>


<script type="text/javascript">
function cetak () {
	
	<?php 
		if(isset($_REQUEST['anggota_id'])) {
			echo 'var anggota_id = "'.$_REQUEST['anggota_id'].'";';
		} else {
			echo 'var anggota_id = $("#anggota_id").val();';
		}
		
		if(isset($_REQUEST['jenis_anggota_id'])) {
			echo 'var jenis_anggota_id = "'.$_REQUEST['jenis_anggota_id'].'";';
		} else {
			echo 'var jenis_anggota_id = $("#jenis_anggota_id").val();';
		}
	?>
	var win = window.open('<?php echo site_url("lap_anggota/cetak/?jenis_anggota_id=' + jenis_anggota_id +'&anggota_id=' + anggota_id +'"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}

function eksportExcel () {
	
	<?php 
		if(isset($_REQUEST['anggota_id'])) {
			echo 'var anggota_id = "'.$_REQUEST['anggota_id'].'";';
		} else {
			echo 'var anggota_id = $("#anggota_id").val();';
		}
		
		if(isset($_REQUEST['jenis_anggota_id'])) {
			echo 'var jenis_anggota_id = "'.$_REQUEST['jenis_anggota_id'].'";';
		} else {
			echo 'var jenis_anggota_id = $("#jenis_anggota_id").val();';
		}
	?>
	var win = window.open('<?php echo site_url("lap_anggota/export_excel/?jenis_anggota_id=' + jenis_anggota_id +'&anggota_id=' + anggota_id +'"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}

$(document).ready(function() {
	<?php 
		if(isset($_REQUEST['anggota_id'])) {
			echo 'var anggota_id = "'.$_REQUEST['anggota_id'].'";';
		} else {
			echo 'var anggota_id = "";';
		}
		echo '$("#anggota_id").val(anggota_id);';
		
		if(isset($_REQUEST['jenis_anggota_id'])) {
			echo 'var jenis_anggota_id = "'.$_REQUEST['jenis_anggota_id'].'";';
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
		]],
		onSelect:function(record){
			show_anggota($('input[name=jenis_anggota_id]').val())
			$('input[name=anggota_id]').val('')
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
		]]
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
		]]
	});
}

function doSearch() {
	$('#fmCari').submit();
}

function clearSearch(){
	window.location.href = '<?php echo site_url("lap_anggota"); ?>';
}
</script>