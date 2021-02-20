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

<!-- Data Grid -->
<?php 
# buaat tanggal sekarang
$tanggal = date('Y-m-d H:i');
$tanggal_arr = explode(' ', $tanggal);
$txt_tanggal = jin_date_ina($tanggal_arr[0]);
$txt_tanggal .= ' - ' . $tanggal_arr[1];

?>

<table   id="dg" 
class="easyui-datagrid"
title="Repayment Schedule" 
style="width:auto; height: auto;" 
url="<?php echo site_url('repayment_schedule/ajax_list'); ?>" 
pagination="true" rownumbers="true" 
fitColumns="true" singleSelect="true" collapsible="true"
sortName="tgl_pinjam" sortOrder="DESC"
toolbar="#tb"
striped="true">
<thead>
	<tr>
		<th data-options="field:'id',halign:'center', align:'center'" hidden="true">ID</th>
		<th data-options="field:'id_txt', width:'17', halign:'center', align:'center'">Kode </th>
		<th data-options="field:'tgl_pinjam', halign:'center', align:'center'" hidden="true">Tanggal</th>
		<th data-options="field:'tgl_pinjam_txt', width:'25', halign:'center', align:'center'">Tanggal Pinjam</th>
        <th data-options="field:'anggota_id',halign:'center', align:'center'" hidden="true">ID</th>
		<th data-options="field:'anggota_id_txt', width:'35', halign:'center', align:'left'">Nama Anggota</th>
		<th data-options="field:'namaanggota', width:'35', halign:'center', align:'left'"  hidden="true">Nama Anggota</th>
		<th data-options="field:'lama_angsuran',halign:'center', align:'center'" hidden="true">Lama</th>
		<th data-options="field:'bunga', halign:'center', align:'right'" hidden="true"> Bunga</th>
		<th data-options="field:'biaya_adm', halign:'center', align:'right'" hidden="true"> Biaya</th>
		<th data-options="field:'jumlah', width:'15', halign:'center', align:'right'" hidden="true" >Pokok <br> Pinjaman</th>
		<th data-options="field:'lama_angsuran_txt', width:'13', halign:'center', align:'center'" hidden="true">Lama</th> 
		<th data-options="field:'hitungan', width:'60', halign:'center', align:'center'">Hitungan</th>
		<th data-options="field:'tagihan', width:'40', halign:'center', align:'right'">Total <br> Tagihan</th>
		<th data-options="field:'user', width:'15', halign:'center', align:'center'">User </th>
		<th data-options="field:'ket', width:'15', halign:'center', align:'left'" hidden="true">Keterangan</th>
		<th data-options="field:'kas_id', halign:'center', align:'right'" hidden="true"> Kas</th>
		<th data-options="field:'detail', halign:'center', align:'right'">Aksi</th>
		<th data-options="field:'nomor_pinjaman',halign:'center', align:'center'" hidden="true">Nomor Pinjaman</th>
		<th data-options="field:'jenis_id', halign:'center', align:'right'" hidden="true"> Jenis Pinjaman</th>
		<th data-options="field:'plafond_pinjaman', halign:'center', align:'right'" hidden="true"> Plafond Pinjaman</th>
		<th data-options="field:'plafond_pinjaman_akun', halign:'center', align:'right'" hidden="true"> Plafond Pinjaman Akun</th>
		<th data-options="field:'angsuran_bulanan', halign:'center', align:'right'" hidden="true"> Angsuran per Bulan</th>
		<th data-options="field:'nomor_pk', halign:'center', align:'right'" hidden="true"> Nomor Perjanjian Kredit</th>
		<th data-options="field:'rekening_tabungan', halign:'center', align:'right'" hidden="true"> Rekening Tabungan</th>
		<th data-options="field:'nomor_pensiunan', halign:'center', align:'right'" hidden="true"> Nomor Pensiunan</th>
		<th data-options="field:'biaya_asuransi', halign:'center', align:'right'" hidden="true"> Biaya Asuransi</th>
		<th data-options="field:'biaya_asuransi_akun', halign:'center', align:'right'" hidden="true"> Biaya Asuransi Akun</th>
		<th data-options="field:'jenis_cabang', halign:'center', align:'right'" hidden="true"> Jenis Cabang</th>
		<th data-options="field:'biaya_adm_akun', halign:'center', align:'right'" hidden="true"> Biaya Administrasi Akun</th>
		<th data-options="field:'biaya_materai', halign:'center', align:'right'" hidden="true"> Biaya Materai</th>
		<th data-options="field:'biaya_materai_akun', halign:'center', align:'right'" hidden="true"> Biaya Materai Akun</th>
		<th data-options="field:'simpanan_pokok', halign:'center', align:'right'" hidden="true"> Simpanan Pokok</th>
		<th data-options="field:'simpanan_pokok_akun', halign:'center', align:'right'" hidden="true"> Simpanan Pokok Akun</th>
		<th data-options="field:'simpanan_wajib', halign:'center', align:'right'" hidden="true"> Simpanan Wajib</th>
		<th data-options="field:'simpanan_wajib_akun', halign:'center', align:'right'" hidden="true"> Simpanan Wajib Akun</th>
		<th data-options="field:'pokok_bulan_satu', halign:'center', align:'right'" hidden="true"> Pokok Bulan satu</th>
		<th data-options="field:'pokok_bulan_satu_akun', halign:'center', align:'right'" hidden="true"> Pokok Bulan satu Akun</th>
		<th data-options="field:'bunga_bulan_satu', halign:'center', align:'right'" hidden="true"> Bunga Bulan satu</th>
		<th data-options="field:'bunga_bulan_satu_akun', halign:'center', align:'right'" hidden="true"> Bunga Bulan satu Akun</th>
		<th data-options="field:'pokok_bulan_dua', halign:'center', align:'right'" hidden="true"> Pokok Bulan dua</th>
		<th data-options="field:'pokok_bulan_dua_akun', halign:'center', align:'right'" hidden="true"> Pokok Bulan dua Akun</th>
		<th data-options="field:'bunga_bulan_dua', halign:'center', align:'right'" hidden="true"> Bunga Bulan dua</th>
		<th data-options="field:'bunga_bulan_dua_akun', halign:'center', align:'right'" hidden="true"> Bunga Bulan dua Akun</th>
		<th data-options="field:'pencairan_bersih', halign:'center', align:'right'" hidden="true"> Pencairan Bersih</th>
		
	</tr>
</thead>
</table>

<!-- Toolbar -->
<div id="tb" style="height: 35px;">
	<div style="vertical-align: middle; display: inline; padding-top: 15px;">
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-cancel" plain="true" onclick="hapus()">Hapus</a>		
	</div>
	<div class="pull-right" style="vertical-align: middle;">
		<div id="filter_tgl" class="input-group" style="display: inline;">
			<button class="btn btn-default" id="daterange-btn">
				<i class="fa fa-calendar"></i> <span id="reportrange"><span>Tanggal</span></span>
				<i class="fa fa-caret-down"></i>
			</button>
		</div>
		<span>Cari :</span>
		<input name="kode_transaksi" id="kode_transaksi" size="15" placeholder="Kode Transaksi" style="line-height:22px;border:1px solid #ccc">
		<input name="cari_nama" id="cari_nama" size="15" placeholder="Nama Anggota" style="line-height:22px;border:1px solid #ccc">

		<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Cari</a>
		<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
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
		format: "dd MM yyyy - hh:ii",
		linkField: "tgl_pinjam",
		linkFormat: "yyyy-mm-dd hh:ii"
	});

	$('#anggota_id').combogrid({
		panelWidth:400,
		url: '<?php echo site_url('repayment_schedule/list_anggota'); ?>',
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
				var result = $.parseJSON(result);
				$('#anggota_poto').html(result[1]);
			})
			.fail(function() {
				alert('Koneksi error, silahkan ulangi.')
			});
		}
	});

	
	$("#cari_anggota,#cari_status").change(function(){
		$("#kode_transaksi,#cari_nama").val('');
		$('#dg').datagrid('load',{
			cari_anggota: $('#cari_anggota').val(),
			cari_status: $('#cari_status').val()
		});
	});
	
	$("#kode_transaksi,#cari_nama").keyup(function(event){
		if(event.keyCode == 13){
			$("#btn_filter").click();
		}
	});

	$("#kode_transaksi").keyup(function(e){
		var isi = $(e.target).val();
		$(e.target).val(isi.toUpperCase());
	});

fm_filter_tgl();
}); //ready


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
		showDropdowns: true,
		format: 'YYYY-MM-DD',
		startDate: moment().startOf('year').startOf('month'),
		endDate: moment().endOf('year').endOf('month')
	},
	function(start, end) {
		$('#reportrange span').html(start.format('D MMM YYYY') + ' - ' + end.format('D MMM YYYY'));
		doSearch();
	});
}
	function hapus(){  
		var row = $('#dg').datagrid('getSelected');  
		if (row){ 
			$.messager.confirm('Konfirmasi','Apakah anda yakin akan menghapus data repayment <code>' + row.id_txt + '</code>  dan Seluruh data angsurannya?',function(r){  
				if (r){  
					$.ajax({
						type	: "POST",
						url		: "<?php echo site_url('repayment_schedule/delete'); ?>",
						data	: 'id='+row.id,
						success	: function(result){
							var result = eval('('+result+')');
							$.messager.show({
								title:'<div><i class="fa fa-info"></i> Informasi</div>',
								msg: result.msg,
								timeout:2000,
								showType:'slide'
							});
							if(result.ok) {
								$('#dg').datagrid('reload');
							}

						},
						error : function (){
							$.messager.show({
								title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
								msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Terjadi kesalahan koneksi, silahkan muat ulang !!</div>',
								timeout:2000,
								showType:'slide'
							});
						}
					});  
				}  
			});  
		}  else {
			$.messager.show({
				title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
				msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
				timeout:2000,
				showType:'slide'
			});	
		}
		$('.messager-button a:last').focus();
	} 

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
			cari_status : $('#cari_status').val(),
			kode_transaksi: $('#kode_transaksi').val(),
			cari_nama: $('#cari_nama').val(),
			tgl_dari: 	$('input[name=daterangepicker_start]').val(),
			tgl_sampai: $('input[name=daterangepicker_end]').val()
		});
	}

	function clearSearch(){
		location.reload();
	}

	function cetak_laporan () {
		var cari_status	 	= $('#cari_status').val();
		var cari_anggota	 	= $('#cari_anggota').val();
		var cari_nama	 	= $('#cari_nama').val();
		var kode_transaksi 	= $('#kode_transaksi').val();
		var tgl_dari			= $('input[name=daterangepicker_start]').val();
		var tgl_sampai			= $('input[name=daterangepicker_end]').val();
		

		var win = window.open('<?php echo site_url("lap_pinjaman/cetak_laporan/?cari_status=' + cari_status + '&kode_transaksi=' + kode_transaksi + '&tgl_dari=' + tgl_dari + '&tgl_sampai=' + tgl_sampai + '&cari_anggota=' + cari_anggota + '&cari_nama=' + cari_nama + '"); ?>');
		if (win) {
			win.focus();
		} else {
			alert('Popup jangan di block');
		}
	}

	function eksportExcel () {
		var cari_status	 	= $('#cari_status').val();
		var cari_anggota	 	= $('#cari_anggota').val();
		var cari_nama	 	= $('#cari_nama').val();
		var kode_transaksi 	= $('#kode_transaksi').val();
		var tgl_dari			= $('input[name=daterangepicker_start]').val();
		var tgl_sampai			= $('input[name=daterangepicker_end]').val();
		

		var win = window.open('<?php echo site_url("lap_pinjaman/eksport_Excel/?cari_status=' + cari_status + '&kode_transaksi=' + kode_transaksi + '&tgl_dari=' + tgl_dari + '&tgl_sampai=' + tgl_sampai + '&cari_anggota=' + cari_anggota + '&cari_nama=' + cari_nama + '"); ?>');
		if (win) {
			win.focus();
		} else {
			alert('Popup jangan di block');
		}
	}

	function cetak_pj() {
		var row = $('#dg').datagrid('getSelected');
		if (row) { 
			var vpinjamid = row.id;
				$.messager.confirm('Konfirmasi','Cetak data pinjaman <code>' + row.nomor_pinjaman + '</code>  ?',function(r){  
					var win = window.open('<?php echo site_url("lap_pinjaman/cetak_pj/?cari_pinjamid=' + vpinjamid + '"); ?>');
					if (win) {
						win.focus();
					} else {
						alert('Popup jangan di block');
					}
				});  
			
		} else {
			$.messager.show({
					title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
					msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
					timeout:2000,
					showType:'slide'
				});	
		}
	}
</script>