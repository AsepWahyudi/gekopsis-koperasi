
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
<table id="dg" 
class="easyui-datagrid"
title="Fixed Asset" 
style="width:auto; height: 100%;"  >
</table>

<!-- Toolbar -->
<div id="tb" style="height: 35px;">
	<div style="vertical-align: middle; display: inline; padding-top: 15px;">
		<a href="javascript:void(0)" class="easyui-linkbutton"  iconCls="icon-add" plain="true" onclick="add()">Tambah</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-edit" plain="true" onclick="edit()">Edit</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-cancel" plain="true" onclick="purge()">Hapus</a>
	</div>
	<div class="pull-right" style="vertical-align: middle;">
		<span>Cari :</span>
		<input class="easyui-datebox" name="tanggal_efektif" id="tanggal_efektif" placeholder="Tgl">-<input class="easyui-datebox" name="tgl_sampai" id="tgl_sampai" placeholder="No Journal">
		<input name="kode_asset" id="kode_asset" placeholder="Kode Asset" size="15" style="line-height:25px;border:1px solid #ccc;">
		
		<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Cari</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>
		<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
		<a href="<?=base_url()?>fixed_asset/export_excel" class="easyui-linkbutton" iconCls="icon-excel" plain="false">Ekspor</a>
	</div>
</div>

<script type="text/javascript">
function add(){
	jQuery.ajax({'url':'<?php echo site_url('journal_voucher/create'); ?>',
		'type':'post','dataType':'json',
		'error': function(xhr,status,error) {
			show('Pesan','An Error Occured: '+xhr.status+ ' ' +xhr.responseText,'1');
		},
		'success':function(data) {
			$('#dialog-form').dialog('open').dialog('setTitle','Tambah Data');
			$('#form').form('clear');	
			$('#journal_voucherid').val(data.journal_voucherid);
			$('#dgdetail').datagrid({
				queryParams: {
					id: data.journal_voucherid
				}
			});
		}
	});
}
function edit() {
	var row = $('#dg').datagrid('getSelected');
	$('#dialog-form').dialog('open').dialog('setTitle','Tambah Data');
	$('#form').form('load',row);
	$('#journal_voucherid').val(row.journal_voucherid);
	$('#dgdetail').datagrid({
		queryParams: {
			id: row.journal_voucherid
		}
	});
}
function submitform(){
	$('#dgdetail').edatagrid('saveRow');
	$('#form').form('submit',{
		iframe:false,
		url:'<?php echo site_url('journal_voucher/save'); ?>',
		onSubmit:function(){
				return $(this).form('enableValidation').form('validate');
		},
		success:function(data){
			var datax = eval('(' + data + ')'); 
			if (datax.isError == 1){
				alert(datax.msg);
			} else {
				alert(datax.msg)
				$('#dg').datagrid('reload');
				$('#dialog-form').dialog('close');
			}
    },
	});	
};
function dateformatter(date){
	var y = date.getFullYear();
	var m = date.getMonth()+1;
	var d = date.getDate();
	return (d<10?('0'+d):d)+'-'+(m<10?('0'+m):m)+'-'+y;
}
function dateparser(s){
	if (!s) return new Date();
		var ss = (s.split('-'));
		var y = parseInt(ss[2],10);
		var m = parseInt(ss[1],10);
		var d = parseInt(ss[0],10);
		if (!isNaN(y) && !isNaN(m) && !isNaN(d)){
				return new Date(y,m-1,d);
		} else {
				return new Date();
		}
}
function doSearch(){
$('#dg').datagrid('load',{
	journal_no: $('#journal_no').val(),
	tgl_dari: 	$('#tgl_dari').val(),
	tgl_sampai: $('#tgl_sampai').val()
});
}
$('#dg').edatagrid({
	url:'<?php echo site_url('fixed_asset/list'); ?>',
	pagination:true, 
	rownumbers:true,
	fitColumns:true,
	singleSelect:true,
	collapsible:true,
	pagePosition:'top',
	onDblClickRow:function (index,row) {
		edit();
	},
	sortName:'harga_perolehan' ,
	sortOrder:'desc',
	toolbar:'#tb',
	striped:true,
	view: detailview,
	height:'500px',
	detailFormatter:function(index,row){
		return '<div style="padding:2px">'+
			'<table class="ddv-jurnaldetail"></table>'+
			'</div>';
	},
	columns:[[ 
		{
			field:'kode_asset_id',
			hidden:true,
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'kode_asset',
			title:'Kode Asset1',
			width:'100px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'nama_asset',
			title:'Nama Asset',
			width:'250px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'kategori_asset',
			title:'Kategori Asset',
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'status',
			title:'Status',
			width:'100px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'tanggal_efektif',
			title:'Tanggal Efektif',
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'harga_perolehan',
			title:'Harga Perolehan',
			width:'250px',
			formatter: function(value,row,index){
				return value;
			}
		},
	]]
});

</script>

