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
title="Jurnal Transaksi" 
style="width:auto; height: 100%;"  >
</table>

<!-- Toolbar -->

<div id="tb" style="height: 35px;">
	<div style="vertical-align: middle; display: inline; padding-top: 15px;">
		<a href="javascript:void(0)" class="easyui-linkbutton"  iconCls="icon-add" plain="true" onclick="add()">Tambah</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-edit" plain="true" onclick="edit()">Edit</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-cancel" plain="true" onclick="purge()">Hapus</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="true" onclick="cetak_jv()">Cetak Journal</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-large-smartart" plain="true" onclick="validasi()">Validasi</a>
	</div>
	<div class="pull-right" style="vertical-align: middle;">
		<span>Cari :</span>
		<input class="easyui-datebox" name="tgl_dari" id="tgl_dari" data-options='formatter:dateformatter,required:true,parser:dateparser' placeholder="Tgl">-<input class="easyui-datebox" name="tgl_sampai" id="tgl_sampai" data-options='formatter:dateformatter,required:true,parser:dateparser' placeholder="No Journal">
		<input name="journal_voucherno" id="journal_voucherno" placeholder="No Journal" size="15" style="line-height:25px;border:1px solid #ccc;">
		
		<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Cari</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>
		<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
		<a href="<?=base_url()?>journal_voucher/export_excel" class="easyui-linkbutton" iconCls="icon-excel" plain="false">Ekspor</a>
	</div>
</div>

<!-- Dialog Form -->
<div id="dialog-form" class="easyui-dialog" data-options="modal:true, resizable: true, 
closed:true,
height:'550px',
width:'850px',
toolbar: [{
            text:'Simpan',
            iconCls:'icon-save',
            handler:function(){
            	submitform();
            }
        }],
">
<form class="easyui-form" id="form" name="form" method="post" novalidate>
		<input type='hidden' name='journal_voucherid' id='journal_voucherid' data-options='hidden:true'></input>
		<input type='hidden' name='validasi_status' id='validasi_status' data-options='hidden:true'></input>
			<table cellpadding='5'>
				<tr>
					<td>No Journal</td>
					<td><input class='easyui-textbox' id='journal_no' name='journal_no' data-options="width:'250px'"></input></td>
				</tr>
				<tr>
					<td>Tgl Jurnal</td>
					<td><input class='easyui-datebox' id='journal_date' name='journal_date' style='width:250px' data-options='formatter:dateformatter,required:true,parser:dateparser'></input></td>
				</tr>
				<tr>
					<td>Jenis Transaksi</td>
					<td><select class="easyui-combobox" name="jns_transaksi" id="jns_transaksi" data-options="required:true" label="" labelPosition="top" style="width:250px;">
						<option value="Pengeluaran Kas">Pengeluaran Kas</option>
						<option value="Pemasukan Kas">Pemasukan Kas</option>
						<option value="Jurnal Umum">Jurnal Umum</option>
						<option value="Pemindahbukuan">Pemindahbukuan</option>
					</select></td>
				</tr>
				<tr>
					<td>Keterangan</td>
					<td><input class="easyui-textbox" name="headernote" data-options="required:true, multiline:true,width:'250px',height:'100px'"></td>
				</tr>
			</table>
		<div id="tbdetail">
			<a id="adddetail" href= "#" title='' class="easyui-linkbutton" iconCls="icon-add" plain="true" onclick="javascript:$('#dgdetail').edatagrid('addRow')"></a>
			<a id="savedetail" href= "#" title='' class="easyui-linkbutton" iconCls="icon-save" plain="true" onclick="javascript:$('#dgdetail').edatagrid('saveRow')"></a>
			<a id="purgedetail" href= "#" title='' class="easyui-linkbutton" iconCls="icon-cut" plain="true" onclick="purgedetail()"></a>
			<a id="canceldetail" href= "#" title='' class="easyui-linkbutton" iconCls="icon-cancel" plain="true" onclick="javascript:$('#dgdetail').edatagrid('cancelRow')"></a>
			<a id="reloaddetail" href= "#" title='' class="easyui-linkbutton" iconCls="icon-reload" plain="true" onclick="javascript:$('#dgdetail').edatagrid('reload')"></a>
		</div>
		<table   id="dgdetail" 
			class="easyui-edatagrid"
			title="Detail Transaksi" 
			url="<?php echo site_url('journal_voucher/listdetail'); ?>" 
			pagination="true" rownumbers="true" 
			fitColumns="true" singleSelect="true" collapsible="true"
			sortName="journal_date" sortOrder="desc" style="width:98%;height:280px"
			striped="true">
		</table>
</div>
</form>

<script type="text/javascript">

$( document ).ready(function(){

});
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
	if (row) { 
		if (row.validasi_status === null){ 
				$('#dialog-form').dialog('open').dialog('setTitle','Edit Data');
				$('#form').form('load',row);
				$('#journal_voucherid').val(row.journal_voucherid);
				$('#journal_no').val(row.journal_no);
				$('#dgdetail').datagrid({
					queryParams: {
						id: row.journal_voucherid
					}
				});
		} else {
			$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Data sudah tervalidasi</div>',
			timeout:2000,
			showType:'slide'
			});
		}
	} else {
		$.messager.show({
				title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
				msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
				timeout:2000,
				showType:'slide'
		});	
	}
}
function validasi() {
	var row = $('#dg').datagrid('getSelected');
	if (row) { 
		if (row.validasi_status === null){ 
			$.messager.confirm('Konfirmasi','Apakah anda ingin validasi data journal <code>' + row.journal_no + '</code>  ?',function(r){  
					if (r){  
						jQuery.ajax({
							type	: "POST",
							url		: "<?php echo site_url('journal_voucher/validasi'); ?>",
							data	: 'id='+row.journal_voucherid,
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
		} else {
			$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Data sudah tervalidasi, tidak perlu di validasi kembali </div>',
			timeout:2000,
			showType:'slide'
			});
		}
	} else {
		$.messager.show({
				title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
				msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
				timeout:2000,
				showType:'slide'
			});	
	}
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
	url:'<?php echo site_url('journal_voucher/list'); ?>',
	pagination:true, 
	rownumbers:true,
	fitColumns:true,
	singleSelect:true,
	collapsible:true,
	pagePosition:'top',
	onDblClickRow:function (index,row) {
		edit();
	},
	sortName:'journal_date' ,
	sortOrder:'asc',
	toolbar:'#tb',
	striped:true,
	view: detailview,
	height:'500px',
	detailFormatter:function(index,row){
		return '<div style="padding:2px">'+
			'<table class="ddv-jurnaldetail"></table>'+
			'</div>';
	},
	onExpandRow: function(index,row){
		var ddvjurnaldetail = $(this).datagrid('getRowDetail',index).find('table.ddv-jurnaldetail');
		ddvjurnaldetail.datagrid({
			url:'<?php echo site_url('journal_voucher/listdetail'); ?>?id='+row.journal_voucherid,
			fitColumns:true,
			singleSelect:true,
			rownumbers:true,
			loadMsg:'Silahkan tunggu ....',
			height:'auto',
			showFooter:true,
			pagination:true, 
			pagePosition:'top',
			columns:[[ 
				{
			field:'journal_voucher_detid',
			hidden:true,
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'journal_voucher_id',
			hidden:true,
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'no_akun',
			title:'No Akun',
			width:'120px',
			sortable: true,
			formatter: function(value,row,index){
				return row.no_akun;
		}},
		{
			field:'nama_akun',
			title:'Nama Akun',
			width:'300px',
			sortable: true,
			formatter: function(value,row,index){
				return row.nama_akun;
		}},
		{
			field:'debit',
			title:'Debet',
			width:'120px',
		},
		{
			field:'credit',
			title:'Kredit',
			width:'120px',
		},
		{
			field:'jns_cabangid',
			title:'Cabang',
			width:'200px',
			sortable: true,
			formatter: function(value,row,index){
				return row.kode_cabang;
		}},
		{
			field:'itemnote',
			title:'Keterangan',
			width:'250px',
		},
			]],
			onResize:function(){
				$('#dg').datagrid('fixDetailRowHeight',index);
			},
			onLoadSuccess:function(){
				setTimeout(function(){
					$('#dg').datagrid('fixDetailRowHeight',index);
				},0);
			}
		});
		$('#dg').datagrid('fixDetailRowHeight',index);
	},
	columns:[[ 
		{
			field:'journal_voucherid',
			hidden:true,
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'journal_no',
			title:'No Jurnal',
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'journal_date',
			title:'Tgl Jurnal',
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'jns_transaksi',
			title:'Jenis Transaksi',
			width:'250px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'headernote',
			title:'Keterangan',
			width:'420px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'validasi_status',
			title:'Validasi',
			width:'80px',
			formatter: function(value,row,index){
				return value;
			}
		},
	]]
});

$('#dgdetail').edatagrid({
	iconCls: 'icon-edit',	
	singleSelect: true,
	toolbar:'#tbdetail',
	pagination: false, 
	pagePosition:'top',
	fitColumns:true,
	editing:true,
	showFooter:true,
	url: '<?php echo site_url('journal_voucher/listdetail'); ?>',
	saveUrl: '<?php echo site_url('journal_voucher/savedetail'); ?>',
	updateUrl: '<?php echo site_url('journal_voucher/savedetail'); ?>',
	destroyUrl: '<?php echo site_url('journal_voucher/purgedetail'); ?>',
	onSuccess: function(index,row){
		$('#dgdetail').edatagrid('reload');
	},
	onError: function(index,row){
		alert(row.msg);
	},
	onBeginEdit:function(index,row) {
		row.journal_voucher_id = $('#journal_voucherid').val();
		var edDebit = $(this).datagrid('getEditor',{index:index,field:'debit'})
		$(edDebit.target).textbox('textbox').bind('keydown',function(e){
			if (e.keyCode == 13){
				var vdebit = $(this).val();
				vdebit = number_format(vdebit,2,',','.'); //ubah grouping thousand memakai point
				$(edDebit.target).textbox('setValue', vdebit)
			}
		});
		var edCredit = $(this).datagrid('getEditor',{index:index,field:'credit'})
		$(edCredit.target).textbox('textbox').bind('keydown',function(e){
			if (e.keyCode == 13){
				var vcredit = $(this).val();
				vcredit = number_format(vcredit,2,',','.'); //ubah grouping thousand memakai point
				$(edCredit.target).textbox('setValue', vcredit)
			}
		});
	}, 
	onEndEdit:function(index,row,changes) {
		row.journal_voucher_id = $('#journal_voucherid').val();
	},
	onBeforeSave:function(index){
		var row = $('#dgdetail').edatagrid('getSelected');
		if (row) {
			row.journal_voucher_id = $('#journal_voucherid').val();
		}
	},
	onDestroy: function(index,row) {
		$('#dgdetail').edatagrid('reload');
	},
	columns:[[ 
		{
			field:'journal_voucher_detid',
			hidden:true,
			editor: {
				type:'textbox'
			},
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'journal_voucher_id',
			hidden:true,
			editor: {
				type:'textbox'
			},
			width:'150px',
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'jns_akun_id',
			title:'No Akun',
			editor:{
				type:'combogrid',
				options:{
					panelWidth:'600px',
					mode : 'remote',
					method:'get',
					idField:'jns_akun_id',
					textField:'no_akun',
					url:'<?php echo site_url('jenis_akun/get_list')?>',
					fitColumns:true,
					required:true,
					loadMsg: 'Tunggu sebentar ...',
					columns:[[
						{field:'jns_akun_id',title:'ID',width:'50px'},
						{field:'no_akun',title:'No Akun',width:'150px'},
						{field:'nama_akun',title:'Nama Akun',width:'350px'},
					]]
				}	
			},
			width:'120px',
			sortable: true,
			formatter: function(value,row,index){
				return row.no_akun;
		}},
		{
			field:'nama_akun',
			title:'Nama Akun',
			width:'300px',
			readonly:true,
			sortable: true,
			formatter: function(value,row,index){
				return row.nama_akun;
		}},
		{
			field:'debit',
			title:'Debet',
			width:'120px',
			editor: {
				type: 'textbox',
				options:{
					required:true,
				}
			},
			sortable: true,
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'credit',
			title:'Kredit',
			width:'120px',
			editor: {
				type: 'textbox',
				options:{
					required:true,
				}
			},
			sortable: true,
			formatter: function(value,row,index){
				return value;
			}
		},
		{
			field:'jns_cabangid',
			title:'Cabang',
			editor:{
				type:'combogrid',
				options:{
					panelWidth:'600px',
					mode : 'remote',
					method:'get',
					idField:'jns_cabangid',
					textField:'kode_cabang',
					url:'<?php echo site_url('jenis_cabang/get_list')?>',
					fitColumns:true,
					loadMsg: 'Tunggu sebentar ...',
					columns:[[
						{field:'jns_cabangid',title:'ID',width:'50px'},
						{field:'kode_cabang',title:'Kode Cabang',width:'150px'},
						{field:'nama_cabang',title:'Nama Cabang',width:'350px'},
					]]
				}	
			},
			width:'200px',
			sortable: true,
			formatter: function(value,row,index){
				return row.kode_cabang;
		}},
		{
			field:'itemnote',
			title:'Keterangan',
			width:'250px',
			editor: {
				type: 'textbox',
				options:{
				}
			}
		},
	]],
	
});



function cetak() {
		var cari_journalno	 = $('#journal_voucherno').val();
		var tgl_dari		= $('input[name=tgl_dari]').val();
		var tgl_sampai		= $('input[name=tgl_sampai]').val();
		

		var win = window.open('<?php echo site_url("lap_journal_voucher/cetak_laporan/?cari_journalno=' + cari_journalno + '&tgl_dari=' + tgl_dari + '&tgl_sampai=' + tgl_sampai + '"); ?>');
		if (win) {
			win.focus();
		} else {
			alert('Popup jangan di block');
		}
	}

	function cetak_jv() {
		var row = $('#dg').datagrid('getSelected');
		if (row) { 
			var vjournalno = row.journal_no;
				$.messager.confirm('Konfirmasi','Cetak data journal <code>' + row.journal_no + '</code>  ?',function(r){  
					var win = window.open('<?php echo site_url("lap_journal_voucher/cetak_jv/?cari_journalno=' + vjournalno + '"); ?>');
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

	function purge() {
	var row = $('#dg').datagrid('getSelected');
	if (row) { 
			$.messager.confirm('Konfirmasi','Apakah anda ingin hapus data journal <code>' + row.journal_no + '</code>  ?',function(r){  
					if (r){  
						jQuery.ajax({
							type	: "POST",
							url		: "<?php echo site_url('journal_voucher/purge'); ?>",
							data	: 'id='+row.journal_voucherid,
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
		
	} else {
		$.messager.show({
				title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
				msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
				timeout:2000,
				showType:'slide'
			});	
	}
}

function purgedetail() {
	var row = $('#dgdetail').datagrid('getSelected');
	if (row) { 
			$.messager.confirm('Konfirmasi','Apakah anda ingin hapus data akun ?',function(r){  
					if (r){  
						jQuery.ajax({
							type	: "POST",
							url		: "<?php echo site_url('journal_voucher/purgedetail'); ?>",
							data	: 'id='+row.journal_voucher_id+'&jvdid='+row.journal_voucher_detid,
							success	: function(result){
								var result = eval('('+result+')');
								
								$.messager.show({
									title:'<div><i class="fa fa-info"></i> Informasi</div>',
									msg: result.msg,
									timeout:2000,
									showType:'slide'
								});
								if(result.isError == 0) {
									$('#dgdetail').datagrid('reload');
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
		
	} else {
		$.messager.show({
				title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
				msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
				timeout:2000,
				showType:'slide'
			});	
	}
}

function formatnumber(symbol,value,othertext='') {
        if (value != undefined) {
          var ardata = value.split(",");
          if (ardata == undefined) {
            ardata = value.split(".");
          }
          s = '<div align=\"right\" style=\"float:right;display:flex\">'+symbol+' '+ardata[0]+'<div style=\"color:red;\">,'+ardata[1]+' '+othertext+'</div></div>';
        } else {
          s = '<div align=\"right\" style=\"float:right;display:flex\">0<div style=\"color:red;\">,0000 '+ othertext+ '</div></div>';
        }
        return s;
		
      }
</script>

