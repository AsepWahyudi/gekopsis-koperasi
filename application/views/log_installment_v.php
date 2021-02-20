<!-- Styler -->
<style type="text/css">
td, div {
	font-family: "Arial","​Helvetica","​sans-serif";
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
</style>

<?php 
	// buaat tanggal sekarang
	$tanggal = date('Y-m-d H:i');
	$tanggal_arr = explode(' ', $tanggal);
	$txt_tanggal = jin_date_ina($tanggal_arr[0]);
	$txt_tanggal .= ' - ' . $tanggal_arr[1];
?>

<!-- Data Grid -->
<table   id="dg" 
class="easyui-datagrid"
title="Notifikasi Angsuran" 
style="width:auto; height: auto;" 
url="<?php echo site_url('log_installment/ajax_list'); ?>" 
pagination="true" rownumbers="true" 
fitColumns="true" singleSelect="true" collapsible="true"
sortName="tgl_transaksi" sortOrder="desc"
toolbar="#tb"
striped="true">
<thead>
	<tr>
		<th data-options="field:'id', sortable:'true',halign:'center', align:'center'" hidden="true">ID</th>
		<th data-options="field:'nomor_pinjaman', width:'17', halign:'center', align:'center'">Kode <br> Transaksi</th>
        <th data-options="field:'tgl_pinjam', width:'17', halign:'center', align:'center'">Tanggal <br> Pinjam</th>
		<th data-options="field:'identitas',halign:'center', align:'center'" >Identitas</th>
		<th data-options="field:'nama', width:'35',halign:'center', align:'left'">Nama Anggota</th>
        <th data-options="field:'tenor', width:'15', halign:'center', align:'center'">Tenor</th>
        <th data-options="field:'angsuran', width:'15', halign:'center', align:'center'">Angsuran  </th>
        <th data-options="field:'total_tagihan', width:'15', halign:'center', align:'right'">Total <br> Tagihan</th>
        <th data-options="field:'sudah_bayar', width:'15', halign:'center', align:'right'" >Sudah <br> di Bayar</th>
		<th data-options="field:'kurang_bayar',halign:'center', align:'right'" >Kurang Bayar</th>
		<th data-options="field:'lebih_bayar', width:'20',halign:'center', align:'right'">Lebih Bayar</th>

	
		<th data-options="field:'no_identitas',halign:'center', align:'center'" hidden="true">No. Identitas</th>
	</tr>
</thead>
</table>

<!-- Toolbar -->
<div id="tb" style="height: 35px;">
	<div style="vertical-align: middle; display: inline; padding-top: 15px;">
	</div>
	<div class="pull-right" style="vertical-align: middle;">
		<div id="filter_tgl" class="input-group" style="display: inline;">
		</div>
		<select id="cari_anggota" name="cari_anggota" style="width:150px; height:27px" >
			<option value=""> -- Jenis Anggota --</option>	
			<?php
				foreach ($jns_anggota as $row) {
					echo '<option value="'.$row->id.'">'.$row->nama.'</option>';
				}
			?>
		</select>
		<span>Cari :</span>
		<input name="kode_transaksi" id="kode_transaksi" placeholder="Kode Transaksi" size="15" style="line-height:25px;border:1px solid #ccc;">
		<input name="cari_nama" id="cari_nama" size="15" placeholder="Nama Anggota" style="line-height:22px;border:1px solid #ccc">
		
		<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Cari</a>
		<!--<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Log</a>
		<a href="<?=base_url()?>log_installment/export_excel" class="easyui-linkbutton" iconCls="icon-excel" plain="false">Ekspor</a>
		-->
		<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
		
	</div>
</div>

<script type="text/javascript">
$(document).ready(function() {
	
	$('#anggota_id').combogrid({
		panelWidth:400,
		url: '<?php echo site_url('simpanan/list_anggota'); ?>',
		idField:'id',
		valueField:'id',
		textField:'nama',
		mode:'remote',
		fitColumns:true,
		columns:[[
		{field:'photo',title:'Photo',align:'center',width:5},
		{field:'id',title:'ID', hidden: true},
		{field:'kode_anggota', title:'ID', align:'center', width:15},
		{field:'nama',title:'Nama Anggota',align:'left',width:15},
		{field:'kota',title:'Kota',align:'left',width:10}
		]],
		onSelect: function(record){
			$("#anggota_poto").html('<img src="<?php echo base_url();?>assets/theme_admin/img/loading.gif" />');
			var val_anggota_id = $('input[name=anggota_id]').val();
			$.ajax({
				url: '<?php echo site_url(); ?>simpanan/get_anggota_by_id/' + val_anggota_id,
				type: 'POST',
				dataType: 'html',
				data: {anggota_id: val_anggota_id},
			})
			.done(function(result) {
				var datain = JSON.parse(result);
				$('#anggota_nama').val(datain[0]);
				$('#anggota_poto').html(datain[1]);
			})
			.fail(function() {
				alert('Koneksi error, silahkan ulangi.')
			});
		}
	});

	$("#cari_anggota,#cari_simpanan").change(function(){
		$("#kode_transaksi,#cari_nama").val('');
		$('#dg').datagrid('load',{
			cari_anggota: $('#cari_anggota').val(),
			cari_simpanan: $('#cari_simpanan').val()
		});
	});
	
	$("#kode_transaksi").keyup(function(event){
		if(event.keyCode == 13){
			$("#btn_filter").click();
		}
	});
	
	$("#cari_nama").keyup(function(event){
		if(event.keyCode == 13){
			$("#btn_filter").click();
		}
	});
	
	$("#kode_transaksi").keyup(function(e){
		var isi = $(e.target).val();
		$(e.target).val(isi.toUpperCase());
	});

}); // ready


</script>

<script type="text/javascript">
var url;

function form_select_clear() {
	$('select option')
	.filter(function() {
		return !this.value || $.trim(this.value).length == 0;
	})
	.remove();
	$('select option')
	.first()
	.prop('selected', true);	
}

function doSearch(){
$('#dg').datagrid('load',{
	kode_transaksi: $('#kode_transaksi').val(),
	cari_nama: $('#cari_nama').val(),
});
}

function clearSearch(){
	location.reload();
}

function cetak () {
	var cari_nama 	= $('#cari_nama').val();
	var kode_transaksi 	= $('#kode_transaksi').val();
	var cari_anggota 	= $('#cari_anggota').val();
	
	var win = window.open('<?php echo site_url("log_installment/cetak_laporan/?kode_transaksi=' + kode_transaksi + '&cari_nama=' + cari_nama + '&cari_anggota=' + cari_anggota + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
}
</script>

