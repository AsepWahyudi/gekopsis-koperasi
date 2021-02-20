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

# ambil suku bunga
foreach ($suku_bunga as $row) {
	$bunga = $row->opsi_val;
}
# ambil biaya admin
foreach ($biaya as $row) {
	$biaya_adm = $row->opsi_val;
}

?>

<table   id="dg" 
class="easyui-datagrid"
title="Data Pinjaman Anggota" 
style="width:auto; height: auto;" 
url="<?php echo site_url('pinjaman/ajax_list'); ?>" 
pagination="true" rownumbers="true" 
fitColumns="true" singleSelect="true" collapsible="true"
sortName="tgl_pinjam" sortOrder="DESC"
toolbar="#tb"
striped="true">
<thead>
	<tr>
    <th data-options="field:'validasi_status',halign:'center', align:'center'">Validasi</th>
		<th data-options="field:'id',halign:'center', align:'center'" hidden="true">ID</th>
		<th data-options="field:'id_txt', width:'17', halign:'center', align:'center'">Kode </th>
		<th data-options="field:'tgl_pinjam', halign:'center', align:'center'" hidden="true">Tanggal</th>
		<th data-options="field:'tgl_pinjam_txt', width:'25', halign:'center', align:'center'">Tanggal Pinjam</th>
		<th data-options="field:'anggota_id',halign:'center', align:'center'" hidden="true">ID</th>
		<th data-options="field:'anggota_id_txt', width:'35', halign:'center', align:'left'">Nama Anggota</th>
		<th data-options="field:'namaanggota', width:'35', halign:'center', align:'left'"  hidden="true">Nama Anggota</th>
		<th data-options="field:'barang_id', width:'35', halign:'center', align:'left'" hidden="true">Nama barang</th>
		<th data-options="field:'lama_angsuran',halign:'center', align:'center'" hidden="true">Lama</th>
		<th data-options="field:'bunga', halign:'center', align:'right'" hidden="true"> Bunga</th>
		<th data-options="field:'biaya_adm', halign:'center', align:'right'" hidden="true"> Biaya</th>
		<th data-options="field:'jumlah', width:'15', halign:'center', align:'right'" hidden="true" >Pokok <br> Pinjaman</th>
		<th data-options="field:'lama_angsuran_txt', width:'13', halign:'center', align:'center'" hidden="true">Lama</th> 
		<th data-options="field:'hitungan', width:'60', halign:'center', align:'center'">Hitungan</th>
		<th data-options="field:'tagihan', width:'40', halign:'center', align:'right'">Total <br> Tagihan</th>
		<th data-options="field:'lunas', width:'12', halign:'center', align:'center'">Lunas</th>
		<th data-options="field:'user', width:'15', halign:'center', align:'center'">User </th>
		<th data-options="field:'ket', width:'15', halign:'center', align:'left'" hidden="true">Keterangan</th>
		<th data-options="field:'kas_id', halign:'center', align:'right'" hidden="true"> Kas</th>
		<th data-options="field:'detail', halign:'center', align:'right'">Aksi</th>
		<th data-options="field:'nomor_pinjaman',halign:'center', align:'center'" hidden="true">Nomor Pinjaman</th>
		<th data-options="field:'jenis_id', halign:'center', width:'100%', align:'right'" hidden="true"> Jenis Pinjaman</th>
		<th data-options="field:'plafond_pinjaman', halign:'center', align:'right'" hidden="true"> Plafond Pinjaman</th>
		<th data-options="field:'plafond_pinjaman_akun', halign:'center', align:'right'" hidden="true"> Plafond Pinjaman Akun</th>
		<th data-options="field:'angsuran_bulanan', halign:'center', align:'right'" hidden="true"> Angsuran per Bulan</th>
		<th data-options="field:'nomor_pk', halign:'center', align:'right'" hidden="true"> Nomor Perjanjian Kredit</th>
		<th data-options="field:'rekening_tabungan', halign:'center', align:'right'" hidden="true"> Rekening Tabungan</th>
		<th data-options="field:'nomor_pensiunan', halign:'center', align:'right'" hidden="true"> Nomor Pensiunan</th>
		<th data-options="field:'nama_vendor', halign:'center', align:'right'" hidden="true"> Nama Vendor</th>
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
		<th data-options="field:'validasi_status', halign:'center', align:'right'" hidden="true">Validasi Status</th>
	</tr>
</thead>
</table>

<!-- Toolbar -->
<div id="tb" style="height: 35px;">
	<div style="vertical-align: middle; display: inline; padding-top: 15px;">
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-add" plain="true" onclick="create()">Tambah </a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-edit" plain="true" onclick="update()">Edit</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-cancel" plain="true" onclick="hapus()">Hapus</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="true" onclick="cetak_pj()">Cetak Pinjaman</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-large-smartart" plain="true" onclick="validasi()">Validasi</a>
		
	</div>
	<div class="pull-right" style="vertical-align: middle;">
		<div id="filter_tgl" class="input-group" style="display: inline;">
			<button class="btn btn-default" id="daterange-btn">
				<i class="fa fa-calendar"></i> <span id="reportrange"><span>Tanggal</span></span>
				<i class="fa fa-caret-down"></i>
			</button>
		</div>
		<select id="cari_status" name="cari_status" style="width:125px; height:27px" >
			<option value=""> -- Status Pinjaman --</option>	
			<option value="Belum">Belum Lunas</option>	
			<option value="Lunas">Sudah Lunas</option>			
		</select>
		<select id="cari_anggota" name="cari_anggota" style="width:150px; height:27px" >
			<option value=""> -- Jenis Anggota --</option>	
			<?php
				foreach ($jns_anggota as $row) {
					echo '<option value="'.$row->id.'">'.$row->nama.'</option>';
				}
			?>
		</select>
		<span>Cari :</span>
		<input name="kode_transaksi" id="kode_transaksi" size="15" placeholder="Kode Transaksi" style="line-height:22px;border:1px solid #ccc">
		<input name="cari_nama" id="cari_nama" size="15" placeholder="Nama Anggota" style="line-height:22px;border:1px solid #ccc">

		<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Cari</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak_laporan()">Cetak Laporan</a>
		<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-xls" plain="false" onclick="eksportExcel()">Ekspor</a>
	</div>
</div>

<!-- Dialog Form -->
<div id="dialog-form" class="easyui-dialog" show= "blind" hide= "blind" modal="true" resizable="false" style="width:500px; height:450px; padding-left: 15px; padding-top:20px" closed="true" buttons="#dialog-buttons" style="display: none;">
	<form id="form" method="post" enctype="multipart/form-data" novalidate>
		<table>
			<tr>
				<td>
					<table>
						<tr style="height:35px">
							<td>Tanggal Pinjam</td>
							<td>:</td>
							<td>
								<div class="input-group date dtpicker col-md-5" style="z-index: 9999 !important;">
									<input type="text" name="tgl_pinjam_txt" id="tgl_pinjam_txt"  style=" background:#eee; width:155px; height:23px" required="true" readonly="readonly" />
									<input type="hidden" name="tgl_pinjam" id="tgl_pinjam" />
									<div class="input-group-addon"><i class="fa fa-calendar"></i></div>
								</div>
							</td>	
						</tr>
							<tr style="height:35px">
							<td>Nama Peminjam</td>
							<td>:</td>
							<td>
								<input id="anggota_id" name="anggota_id" style="width:195px; height:25px" class="easyui-validatebox" required="true" >
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Nama Barang</td>
							<td>:</td>
							<td>
								<select id="barang_id" name="barang_id" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Barang --</option>
									<?php	
									foreach ($barang_id as $row) {
										echo '<option value="'.$row->id.'">'.$row->nm_barang.' Rp '.number_format($row->harga,2,',','.').'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Harga Barang</td>
							<td>:</td>
							<td>
								<input class="" id="jumlah" name="jumlah" style="width:195px; height:25px; background-color:#eee;" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Nomor Pinjaman</td>
							<td>:</td>
							<td>
								<input class="easyui-textbox" id="nomor_pinjaman" name="nomor_pinjaman" style="width:195px; height:25px;" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Jenis Pinjaman</td>
							<td>:</td>
							<td>
								<select id="jenis_id" name="jenis_id" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Pinjaman --</option>
									<?php	
									foreach ($jenis_id as $row) {
										echo '<option value="'.$row->id.'">'.$row->jns_pinjaman.'</option>';
									}
									?>
								</select>
								<input type="hidden" id="fixed_jenis">
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Plafond Pinjaman</td>
							<td>:</td>
							<td>
								<input id="plafond_pinjaman" name="plafond_pinjaman" style="width:195px; height:25px;" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Plafond Pinjaman Akun</td>
							<td>:</td>
							<td>
								<select id="plafond_pinjaman_akun" name="plafond_pinjaman_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Plafond Pinjaman Akun --</option>
									<?php	
									foreach ($plafond_pinjaman_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Jangka Waktu</td>
							<td>:</td>
							<td>
								<select id="lama_angsuran" name="lama_angsuran" style="width:200px; height:23px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Angsuran --</option>			
									<?php	
									foreach ($jenis_ags as $row) {
										echo '<option value="'.$row->ket.'">'.$row->ket.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Suku Bunga (%)</td>
							<td>:</td>
							<td>
								<input type="text" id="bunga" name="bunga" style="background:#eee; border-width:1; width:195px; height:23px" readonly="true" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Angsuran per bulan</td>
							<td>:</td>
							<td>
								<input id="angsuran_bulanan" name="angsuran_bulanan" style="width:195px; height:25px; " class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>No. Perjanjian Kredit</td>
							<td>:</td>
							<td>
								<input class="easyui-textbox" id="nomor_pk" name="nomor_pk" style="width:195px; height:25px; " />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Rekening Tabungan</td>
							<td>:</td>
							<td>
								<input class="easyui-textbox" id="rekening_tabungan" name="rekening_tabungan" style="width:195px; height:25px; " />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Nomor Pensiunan</td>
							<td>:</td>
							<td>
								<input class="easyui-textbox" id="nomor_pensiunan" name="nomor_pensiunan" style="width:195px; height:25px; " />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Nama Vendor</td>
							<td>:</td>
							<td>
								<input class="easyui-textbox" id="nama_vendor" name="nama_vendor" style="width:195px; height:25px; " />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Cabang</td>
							<td>:</td>
							<td>
								<select id="jenis_cabang" name="jenis_cabang" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Cabang --</option>
									<?php	
									foreach ($jenis_cabang as $row) {
										echo '<option value="'.$row->jns_cabangid.'">'.$row->nama_cabang.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Biaya Asuransi</td>
							<td>:</td>
							<td>
								<input type="text" id="biaya_asuransi" name="biaya_asuransi" style=" border-width:1; width:195px; height:23px" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Biaya Asuransi Akun</td>
							<td>:</td>
							<td>
								<select id="biaya_asuransi_akun" name="biaya_asuransi_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Biaya Asuransi Akun --</option>
									<?php	
									foreach ($biaya_asuransi_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Biaya Administrasi</td>
							<td>:</td>
							<td>
								<input type="text" id="biaya_adm" name="biaya_adm" style=" border-width:1; width:195px; height:23px" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Biaya Administrasi Akun</td>
							<td>:</td>
							<td>
								<select id="biaya_adm_akun" name="biaya_adm_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Biaya Administrasi Akun --</option>
									<?php	
									foreach ($biaya_adm_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Biaya Materai</td>
							<td>:</td>
							<td>
								<input type="text" id="biaya_materai" name="biaya_materai" style="  border-width:1; width:195px; height:23px" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0"  />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Biaya Materai Akun</td>
							<td>:</td>
							<td>
								<select id="biaya_materai_akun" name="biaya_materai_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Biaya Materai Akun --</option>
									<?php	
									foreach ($biaya_materai_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Simpanan Pokok</td>
							<td>:</td>
							<td>
								<input type="text" id="simpanan_pokok" name="simpanan_pokok" style=" border-width:1; width:195px; height:23px" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Simpanan Pokok Akun</td>
							<td>:</td>
							<td>
								<select id="simpanan_pokok_akun" name="simpanan_pokok_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Simpanan Pokok Akun --</option>
									<?php	
									foreach ($simpanan_pokok_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Simpanan Wajib </td>
							<td>:</td>
							<td>
								<input  id="simpanan_wajib" name="simpanan_wajib" style="width:195px; height:25px; " class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Simpanan Wajib Akun</td>
							<td>:</td>
							<td>
								<select id="simpanan_wajib_akun" name="simpanan_wajib_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Simpanan Wajib Akun --</option>
									<?php	
									foreach ($simpanan_wajib_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Pokok Bulan 1</td>
							<td>:</td>
							<td>
								<input id="pokok_bulan_satu" name="pokok_bulan_satu" style="width:195px; height:25px;" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Pokok Bulan 1 Akun</td>
							<td>:</td>
							<td>
								<select id="pokok_bulan_satu_akun" name="pokok_bulan_satu_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Pokok Bulan 1 Akun --</option>
									<?php	
									foreach ($pokok_bulan_satu_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Bunga Bulan 1 </td>
							<td>:</td>
							<td>
								<input  id="bunga_bulan_satu" name="bunga_bulan_satu" style="width:195px; height:25px; " class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Bunga Bulan 1 Akun</td>
							<td>:</td>
							<td>
								<select id="bunga_bulan_satu_akun" name="bunga_bulan_satu_akun" style="width:195px; height:25px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Bunga Bulan 1 Akun --</option>
									<?php	
									foreach ($bunga_bulan_satu_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Pokok Bulan 2</td>
							<td>:</td>
							<td>
								<input id="pokok_bulan_dua" name="pokok_bulan_dua" style="width:195px; height:25px;" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Pokok Bulan 2 Akun</td>
							<td>:</td>
							<td>
								<select id="pokok_bulan_dua_akun" name="pokok_bulan_dua_akun" style="width:195px; height:25px" class="easyui-validatebox">
									<option value="0"> -- Pilih Pokok Bulan 2 Akun --</option>
									<?php	
									foreach ($pokok_bulan_dua_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Bunga Bulan 2 </td>
							<td>:</td>
							<td>
								<input  id="bunga_bulan_dua" name="bunga_bulan_dua" style="width:195px; height:25px; " class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Bunga Bulan 2 Akun</td>
							<td>:</td>
							<td>
								<select id="bunga_bulan_dua_akun" name="bunga_bulan_dua_akun" style="width:195px; height:25px" class="easyui-validatebox">
									<option value="0"> -- Pilih Bunga Bulan 2 Akun --</option>
									<?php	
									foreach ($bunga_bulan_dua_akun as $row) {
										echo '<option value="'.$row->jns_akun_id.'">'.$row->no_akun.' - '.$row->nama_akun.'</option>';
									}
									?>
								</select>
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Pencairan Bersih</td>
							<td>:</td>
							<td>
								<input id="pencairan_bersih" name="pencairan_bersih" style="width:195px; height:25px;" class = "easyui-numberbox" data-options="min:0,precision:2,decimalSeparator:'.',groupSeparator:',',value:0" />
							</td>	
						</tr>
						<tr style="height:35px">
							<td>Ambil Dari Kas</td>
							<td>:</td>
							<td>
								<select id="kas" name="kas_id" style="width:200px; height:23px" class="easyui-validatebox" required="true">
									<option value="0"> -- Pilih Kas --</option>			
									<?php	
									foreach ($kas_id as $row) {
										echo '<option value="'.$row->id.'">'.$row->nama.'</option>';
									}
									?>
								</select>
							</td>
						</tr>
						<tr style="height:35px">
							<td>Keterangan</td>
							<td>:</td>
							<td>
								<input class="easyui-textbox" id="ket" name="ket" style="width:190px; height:20px" >
							</td>	
						</tr>
						<tr style="height:35px">
							<td>File</td>
							<td>:</td>
							<td>
								<input type="file" id="file" name="file" style="width:190px; height:20px" >
							</td>	
						</tr>
					</table>
				</td>
				<td width="10px"></td><td valign="top"> Photo : <br> <div id="anggota_poto" style="height:120px; width:90px; border:1px solid #ccc"> </div></td>
			</tr>
		</table>
	</form>
</div>

<!-- Dialog Button -->
<div id="dialog-buttons">
	<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-ok" onclick="save()">Simpan</a>
	<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-cancel" onclick="javascript:jQuery('#dialog-form').dialog('close')">Batal</a>
</div>


<script type="text/javascript">
$(document).ready(function() {
	$('#jenis_id').change(function(){
		val_jenis_id = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_pinjaman',
			type: 'POST',
			dataType: 'html',
			data: {jenis_id: val_jenis_id},
		})
		.done(function(result) {
			var data=$.parseJSON(result);
			$('#biaya_adm').numberbox('setValue', data.biaya_adm);
			$('#bunga').val(data.bunga);
			$('#simpanan_pokok').numberbox('setValue', data.simpanan_pokok);
			$('#biaya_materai').numberbox('setValue', data.biaya_materai);
			$('#biaya_asuransi').numberbox('setValue',data.biaya_asuransi);
			$('#fixed_jenis').val(data.fixed);
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});		
	});

	$('#lama_angsuran').change(function(){

		var lama = $('#lama_angsuran').val();

		var fixed = $('#fixed_jenis').val();

		var bunga = $('#bunga').val();

		if(fixed == 'Y' && lama=='24'){

			var jml = bunga * 2;

			$('#bunga').val(jml);

		}

	});

	$('#barang_id').change(function(){
		val_barang_id = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_barang',
			type: 'POST',
			dataType: 'html',
			data: {barang_id: val_barang_id},
		})
		.done(function(result) {
			$('#jumlah').val(result);
			if(result == '0') {
				$('#jumlah').removeAttr('readonly');
				$('#jumlah').css('background-color', '');
				$('#jumlah').focus().select();
			} else {
				$('#jumlah').attr('readonly', 'true');
				$('#jumlah').css('background-color', '#eee');
			}
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#simpanan_wajib_akun').change(function(){
		val_simpanan_wajib_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {simpanan_wajib_akun: val_simpanan_wajib_akun},
		})
		.done(function(result) {

		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#plafond_pinjaman_akun').change(function(){
		val_plafond_pinjaman_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {plafond_pinjaman_akun: val_plafond_pinjaman_akun},
		})
		.done(function(result) {

		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#biaya_asuransi_akun').change(function(){
		val_biaya_asuransi_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {biaya_asuransi_akun: val_biaya_asuransi_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#jenis_cabang').change(function(){
		val_jenis_cabang = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_cabang',
			type: 'POST',
			dataType: 'html',
			data: {jenis_cabang: val_jenis_cabang},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#biaya_adm_akun').change(function(){
		val_biaya_adm_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {biaya_adm_akun: val_biaya_adm_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#biaya_materai_akun').change(function(){
		val_biaya_materai_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {biaya_materai_akun: val_biaya_materai_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#simpanan_pokok_akun').change(function(){
		val_simpanan_pokok_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {simpanan_pokok_akun: val_simpanan_pokok_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#pokok_bulan_satu_akun').change(function(){
		val_pokok_bulan_satu_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {pokok_bulan_satu_akun: val_pokok_bulan_satu_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#pokok_bulan_dua_akun').change(function(){
		val_pokok_bulan_dua_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {pokok_bulan_dua_akun: val_pokok_bulan_dua_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#bunga_bulan_satu_akun').change(function(){
		val_bunga_bulan_satu_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {bunga_bulan_satu_akun: val_bunga_bulan_satu_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#bunga_bulan_dua_akun').change(function(){
		val_bunga_bulan_dua_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {bunga_bulan_dua_akun: val_bunga_bulan_dua_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

	$('#pencairain_bersih_akun').change(function(){
		val_pencairain_bersih_akun = $(this).val();
		$.ajax({
			url: '<?php echo site_url()?>pinjaman/get_jenis_akun',
			type: 'POST',
			dataType: 'html',
			data: {pencairain_bersih_akun: val_pencairain_bersih_akun},
		})
		.done(function(result) {
			
		})
		.fail(function() {
			alert('Kesalahan Konekasi, silahkan ulangi beberapa saat lagi.');
		});
		
	});

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
		url: '<?php echo site_url('pinjaman/list_anggota'); ?>',
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
</script>

<script type="text/javascript">
var url;
function create(){
	jQuery('#dialog-form').dialog('open').dialog('setTitle','Form Tambah Pinjaman');
	jQuery('#form').form('clear');
	$('#anggota_id ~ span span a').show();
	$('#anggota_id ~ span input').removeAttr('disabled');
	$('#anggota_id ~ span input').focus();

	$('#barang_id').attr('enable', true);
	$('#barang_id').removeAttr('disabled');
	$('#barang_id').css('background-color', '#fff');

	jQuery('#tgl_pinjam_txt').val('<?php echo $txt_tanggal;?>');
	jQuery('#tgl_pinjam').val('<?php echo $tanggal;?>');
	jQuery('#barang_id option[value="0"]').prop('selected', true);
	jQuery('#bunga').val('<?php echo $bunga;?>');
	jQuery('#biaya_adm').val('<?php echo $biaya_adm;?>');
	jQuery('#kas option[value="0"]').prop('selected', true);
	jQuery('#lama_angsuran option[value="0"]').prop('selected', true);
	jQuery('#jenis_id option[value="0"]').prop('selected', true);
	jQuery('#plafond_pinjaman_akun option[value="0"]').prop('selected', true);
	jQuery('#biaya_asuransi_akun option[value="0"]').prop('selected', true);
	jQuery('#biaya_adm_akun option[value="0"]').prop('selected', true);
	jQuery('#biaya_materai_akun option[value="0"]').prop('selected', true);
	jQuery('#simpanan_wajib_akun option[value="0"]').prop('selected', true);
	jQuery('#simpanan_pokok_akun option[value="0"]').prop('selected', true);
	jQuery('#pokok_bulan_satu_akun option[value="0"]').prop('selected', true);
	jQuery('#bunga_bulan_satu_akun option[value="0"]').prop('selected', true);
	jQuery('#pokok_bulan_dua_akun option[value="0"]').prop('selected', true);
	jQuery('#bunga_bulan_dua_akun option[value="0"]').prop('selected', true);
	jQuery('#jenis_cabang option[value="0"]').prop('selected', true);
	$("#anggota_poto").html('');

	$('#jumlah').keyup(function(){
		var val_jumlah = $(this).val();
		//$('#jumlah').numberbox('setValue', number_format(val_jumlah));
		$('#jumlah').val(number_format(val_jumlah),2,',','.');
	});

	$('#plafond_pinjaman').keyup(function(){
		var val_plafond_pinjaman = $(this).val();
		$('#plafond_pinjaman').val(number_format(val_plafond_pinjaman),2,',','.');
		
	});

	$('#plafond_pinjaman  ~ span input').blur(function(){
		var val_plafond_pinjaman = $(this).val();
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		$('#pencairan_bersih').numberbox('setValue',val_plafond_pinjaman);
	});

	$('#angsuran_bulanan').keyup(function(){
		var val_angsuran_bulanan = $(this).val();
		$('#angsuran_bulanan').val(number_format(val_angsuran_bulanan),2,',','.');
	});

	$('#biaya_asuransi').keyup(function(){
		var val_biaya_asuransi = $(this).val();
		$('#biaya_asuransi').val(number_format(val_biaya_asuransi),2,',','.');
	});

	$('#biaya_asuransi ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_biaya_asuransi = $(this).val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#biaya_adm').keyup(function(){
		var val_biaya_asuransi = $(this).val();
		$('#biaya_asuransi').val(number_format(val_biaya_asuransi),2,',','.');
	});

	$('#biaya_adm ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_biaya_adm = $(this).val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#biaya_asuransi_akun_txt').keyup(function(){
		var val_biaya_asuransi_akun = $(this).val();
		$('#biaya_asuransi_akun_txt').val(number_format(val_biaya_asuransi_akun),2,',','.');
	});

	$('#biaya_materai').keyup(function(){
		var val_biaya_materai = $(this).val();
		$('#biaya_materai').val(number_format(val_biaya_materai),2,',','.');
	});

	$('#biaya_materai ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_biaya_materai =  $(this).val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#simpanan_pokok').keyup(function(){
		var val_simpanan_pokok = $(this).val();
		$('#simpanan_pokok').val(number_format(val_simpanan_pokok),2,',','.');
	});

	$('#simpanan_pokok ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_simpanan_pokok =  $(this).val();
		var val_biaya_materai =  $('#biaya_materai').val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_simpanan_pokok = parseFloat(val_simpanan_pokok.replace(/,/g,''));
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai) - parseFloat(val_simpanan_pokok);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#simpanan_wajib').keyup(function(){
		var val_simpanan_wajib = $(this).val();
		$('#simpanan_wajib').val(number_format(val_simpanan_wajib),2,',','.');
	});

	$('#simpanan_wajib ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_simpanan_wajib =  $(this).val();
		var val_simpanan_pokok =  $('#simpanan_pokok').val();
		var val_biaya_materai =  $('#biaya_materai').val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_simpanan_wajib = parseFloat(val_simpanan_wajib.replace(/,/g,''));
		val_simpanan_pokok = parseFloat(val_simpanan_pokok.replace(/,/g,''));
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai) - parseFloat(val_simpanan_pokok) - parseFloat(val_simpanan_wajib);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#pokok_bulan_satu').keyup(function(){
		var val_pokok_bulan_satu = $(this).val();
		$('#pokok_bulan_satu').val(number_format(val_pokok_bulan_satu),2,',','.');
	});

	$('#pokok_bulan_satu ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_pokok_bulan_satu =  $(this).val();
		var val_simpanan_wajib =  $('#simpanan_wajib').val();
		var val_simpanan_pokok =  $('#simpanan_pokok').val();
		var val_biaya_materai =  $('#biaya_materai').val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_pokok_bulan_satu = parseFloat(val_pokok_bulan_satu.replace(/,/g,''));
		val_simpanan_wajib = parseFloat(val_simpanan_wajib.replace(/,/g,''));
		val_simpanan_pokok = parseFloat(val_simpanan_pokok.replace(/,/g,''));
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai) - parseFloat(val_simpanan_pokok) - parseFloat(val_simpanan_wajib) - parseFloat(val_pokok_bulan_satu);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#bunga_bulan_satu').keyup(function(){
		var val_bunga_bulan_satu = $(this).val();
		$('#bunga_bulan_satu').val(number_format(val_bunga_bulan_satu),2,',','.');
	});

	$('#bunga_bulan_satu ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_bunga_bulan_satu =  $(this).val();
		var val_pokok_bulan_satu =  $('#pokok_bulan_satu').val();
		var val_simpanan_wajib =  $('#simpanan_wajib').val();
		var val_simpanan_pokok =  $('#simpanan_pokok').val();
		var val_biaya_materai =  $('#biaya_materai').val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_bunga_bulan_satu = parseFloat(val_bunga_bulan_satu.replace(/,/g,''));
		val_pokok_bulan_satu = parseFloat(val_pokok_bulan_satu.replace(/,/g,''));
		val_simpanan_wajib = parseFloat(val_simpanan_wajib.replace(/,/g,''));
		val_simpanan_pokok = parseFloat(val_simpanan_pokok.replace(/,/g,''));
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai) - parseFloat(val_simpanan_pokok) - parseFloat(val_simpanan_wajib) - parseFloat(val_pokok_bulan_satu) - parseFloat(val_bunga_bulan_satu);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#pokok_bulan_dua').keyup(function(){
		var val_pokok_bulan_dua = $(this).val();
		$('#pokok_bulan_dua').val(number_format(val_pokok_bulan_dua),2,',','.');
	});

	$('#pokok_bulan_dua ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_pokok_bulan_dua =  $(this).val();
		var val_bunga_bulan_satu =  $('#bunga_bulan_satu').val();
		var val_pokok_bulan_satu =  $('#pokok_bulan_satu').val();
		var val_simpanan_wajib =  $('#simpanan_wajib').val();
		var val_simpanan_pokok =  $('#simpanan_pokok').val();
		var val_biaya_materai =  $('#biaya_materai').val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_pokok_bulan_dua = parseFloat(val_pokok_bulan_dua.replace(/,/g,''));
		val_bunga_bulan_satu = parseFloat(val_bunga_bulan_satu.replace(/,/g,''));
		val_pokok_bulan_satu = parseFloat(val_pokok_bulan_satu.replace(/,/g,''));
		val_simpanan_wajib = parseFloat(val_simpanan_wajib.replace(/,/g,''));
		val_simpanan_pokok = parseFloat(val_simpanan_pokok.replace(/,/g,''));
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai) - parseFloat(val_simpanan_pokok) - parseFloat(val_simpanan_wajib) - parseFloat(val_pokok_bulan_satu) - parseFloat(val_bunga_bulan_satu) - parseFloat(val_pokok_bulan_dua);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#bunga_bulan_dua').keyup(function(){
		var val_bunga_bulan_dua = $(this).val();
		$('#bunga_bulan_dua').val(number_format(val_bunga_bulan_dua),2,',','.');
	});

	$('#bunga_bulan_dua ~ span input').blur(function(){
		var val_pencairan_bersih = 0;
		var val_bunga_bulan_dua =  $(this).val();
		var val_pokok_bulan_dua =  $('#pokok_bulan_dua').val();
		var val_bunga_bulan_satu =  $('#bunga_bulan_satu').val();
		var val_pokok_bulan_satu =  $('#pokok_bulan_satu').val();
		var val_simpanan_wajib =  $('#simpanan_wajib').val();
		var val_simpanan_pokok =  $('#simpanan_pokok').val();
		var val_biaya_materai =  $('#biaya_materai').val();
		var val_biaya_adm = $('#biaya_adm').val();
		var val_plafond_pinjaman = $('#plafond_pinjaman').val();
		var val_biaya_asuransi = $('#biaya_asuransi').val();
		val_bunga_bulan_dua = parseFloat(val_bunga_bulan_dua.replace(/,/g,''));
		val_pokok_bulan_dua = parseFloat(val_pokok_bulan_dua.replace(/,/g,''));
		val_bunga_bulan_satu = parseFloat(val_bunga_bulan_satu.replace(/,/g,''));
		val_pokok_bulan_satu = parseFloat(val_pokok_bulan_satu.replace(/,/g,''));
		val_simpanan_wajib = parseFloat(val_simpanan_wajib.replace(/,/g,''));
		val_simpanan_pokok = parseFloat(val_simpanan_pokok.replace(/,/g,''));
		val_biaya_materai = parseFloat(val_biaya_materai.replace(/,/g,''));
		val_biaya_adm = parseFloat(val_biaya_adm.replace(/,/g,''));
		val_biaya_asuransi = parseFloat(val_biaya_asuransi.replace(/,/g,''));
		val_plafond_pinjaman = parseFloat(val_plafond_pinjaman.replace(/,/g,''));
		val_pencairan_bersih = parseFloat(val_plafond_pinjaman) - parseFloat(val_biaya_asuransi) - parseFloat(val_biaya_adm) - parseFloat(val_biaya_materai) - parseFloat(val_simpanan_pokok) - parseFloat(val_simpanan_wajib) - parseFloat(val_pokok_bulan_satu) - parseFloat(val_bunga_bulan_satu) - parseFloat(val_pokok_bulan_dua) - parseFloat(val_bunga_bulan_dua);
		$('#pencairan_bersih').numberbox('setValue',val_pencairan_bersih);
	});

	$('#pencairan_bersih').keyup(function(){
		var val_pencairan_bersih = $(this).val();
		$('#pencairan_bersih').val(number_format(val_pencairan_bersih),2,',','.');
	});

	url = '<?php echo site_url('pinjaman/create'); ?>';
}

function save() {
	var string = $("#form").serialize();
	//validasi teks kosong
	var anggota_id = $("input[name=anggota_id]").val();
	if(anggota_id == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Nama Peminjam belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#anggota_id").focus();
		return false;
	}

	var plafond_pinjaman_akun = $("#plafond_pinjaman_akun option:selected").val();
	if(plafond_pinjaman_akun == "0" || plafond_pinjaman_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Plafond Pinjaman Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#plafond_pinjaman_akun").focus();
		return false;
	}

	var biaya_asuransi_akun = $("#biaya_asuransi_akun option:selected").val();
	if(biaya_asuransi_akun == "0" || biaya_asuransi_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Biaya Asuransi Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#biaya_asuransi_akun").focus();
		return false;
	}

	var jenis_cabang = $("#jenis_cabang option:selected").val();
	if(jenis_cabang == "0" || jenis_cabang == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Cabang Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#jenis_cabang").focus();
		return false;
	}

	var biaya_adm_akun = $("#biaya_adm_akun option:selected").val();
	if(biaya_adm_akun == "0" || biaya_adm_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Biaya Administrasi Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#biaya_adm_akun").focus();
		return false;
	}

	var biaya_materai_akun = $("#biaya_materai_akun option:selected").val();
	if(biaya_materai_akun == "0" || biaya_materai_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Biaya Materai Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#biaya_materai_akun").focus();
		return false;
	}

	var simpanan_pokok_akun = $("#simpanan_pokok_akun option:selected").val();
	if(simpanan_pokok_akun == "0" || simpanan_pokok_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Simpanan Pokok Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#simpanan_pokok_akun").focus();
		return false;
	}

	var pokok_bulan_satu_akun = $("#pokok_bulan_satu_akun option:selected").val();
	if(pokok_bulan_satu_akun == "0" || pokok_bulan_satu_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Pokok Bulan Satu Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#pokok_bulan_satu_akun").focus();
		return false;
	}

	var bunga_bulan_satu_akun = $("#bunga_bulan_satu_akun option:selected").val();
	if(bunga_bulan_satu_akun == "0" || bunga_bulan_satu_akun == "") {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Bunga Bulan Satu Akun belum dipilih. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#bunga_bulan_satu_akun").focus();
		return false;
	}

	var lama_angsuran = $("#lama_angsuran").val();
	if(lama_angsuran == 0) {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Jangka Waktu Lama Angsuran belum dipilih </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#lama_angsuran").focus();
		return false;
	}

	var kas = $("#kas").val();
	if(kas == 0) {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Ambil dari Kas harus diisi.</div>',
			timeout:2000,
			showType:'slide'
		});
		$("#kas").focus();
		return false;
	}

	var nomor_pinjaman = $("input[name=nomor_pinjaman]").val();
	if(nomor_pinjaman == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Nomor Pinjaman Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#nomor_pinjaman").focus();
		return false;
	}

	var plafond_pinjaman = $("input[name=plafond_pinjaman]").val();
	if(plafond_pinjaman == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Plafond Pinjaman Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#plafond_pinjaman").focus();
		return false;
	}

	var plafond_pinjaman_akun = $("input[name=plafond_pinjaman_akun]").val();
	if(plafond_pinjaman_akun == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Plafond Pinjaman Akun Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#plafond_pinjaman_akun").focus();
		return false;
	}

	var simpanan_wajib = $("input[name=simpanan_wajib]").val();
	if(simpanan_wajib == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Simpanan Wajib Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#simpanan_wajib").focus();
		return false;
	}

	var simpanan_wajib_akun = $("input[name=simpanan_wajib_akun]").val();
	if(simpanan_wajib_akun == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Simpanan Wajib Akun Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#simpanan_wajib").focus();
		return false;
	}

	var angsuran_bulanan = $("input[name=angsuran_bulanan]").val();
	if(angsuran_bulanan == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Angsuran per bulan Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#angsuran_bulanan").focus();
		return false;
	}

	var nomor_pk = $("input[name=nomor_pk]").val();
	if(nomor_pk == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Nomor PK Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#nomor_pk").focus();
		return false;
	}

	var rekening_tabungan = $("input[name=rekening_tabungan]").val();
	if(rekening_tabungan == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Rekening Tabungan Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#rekening_tabungan").focus();
		return false;
	}

	var nomor_pensiunan = $("input[name=nomor_pensiunan]").val();
	if(nomor_pensiunan == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Nomor Pensiunan Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#nomor_pensiunan").focus();
		return false;
	}

	var bunga_bulan_satu_akun = $("input[name=bunga_bulan_satu_akun]").val();
	if(bunga_bulan_satu_akun == '') {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan ! </div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Bunga Bulan satu akun Belum di isi. </div>',
			timeout:2000,
			showType:'slide'
		});
		$("#bunga_bulan_satu_akun").focus();
		return false;
	}

	var fd = new FormData($("#form")[0]);
    var files = $('#file')[0].files[0];
    fd.append('file',files);

    $.ajax({
        url: url,
        type: 'post',
        data: fd,
        contentType: false,
        processData: false,
		error: function(XMLHttpRequest, textStatus, errorThrown){
        alert('status:' + XMLHttpRequest.status + ', status text: ' + XMLHttpRequest.statusText);
    	},
        success: function(result){
            var result = eval('('+result+')');
			$.messager.show({
				title:'<div><i class="fa fa-info"></i> Informasi</div>',
				msg: result.msg,
				timeout:2000,
				showType:'slide'
			});
			if(result.ok) {
				jQuery('#dialog-form').dialog('close');
				$('#dg').datagrid('reload');
			}
        },
    });
}

function update(){
	var row = jQuery('#dg').datagrid('getSelected');
	if(row){

		if (row.validasi_status !== 'X') {
			jQuery('#dialog-form').dialog('open').dialog('setTitle','Edit Data Pinjaman');
			jQuery('#form').form('load',row);

			$('#anggota_id ~ span input').attr('disabled', true);
			$('#anggota_id ~ span input').css('background-color', '#fff');
			$('#anggota_id ~ span span a').hide();

			$('#barang_id').attr('disabled', true);
			$('#barang_id').css('background-color', '#fff');
			
				url = '<?php echo site_url('pinjaman/update'); ?>/' + row.id;
		} else {
			$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data tidak bisa diubah, karena sudah di validasi </div>',
			timeout:2000,
			showType:'slide'
			});
		}

	}else {
		$.messager.show({
			title:'<div><i class="fa fa-warning"></i> Peringatan !</div>',
			msg: '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data harus dipilih terlebih dahulu </div>',
			timeout:2000,
			showType:'slide'
		});		}
	}

	function hapus(){  
		var row = $('#dg').datagrid('getSelected');  
		if (row){ 
			$.messager.confirm('Konfirmasi','Apakah anda yakin akan menghapus data pinjaman <code>' + row.id_txt + '</code>  dan Seluruh data angsurannya?',function(r){  
				if (r){  
					$.ajax({
						type	: "POST",
						url		: "<?php echo site_url('pinjaman/delete'); ?>",
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

	function validasi(){  
		var row = $('#dg').datagrid('getSelected'); 

			if (row){ 
				if (row.validasi_status !== 'X') { 
				$.messager.confirm('Konfirmasi','Apakah anda ingin validasi data pinjaman <code>' + row.id_txt + '</code>  ?',function(r){  
					if (r){  
						$.ajax({
							type	: "POST",
							url		: "<?php echo site_url('pinjaman/validasi'); ?>",
							data	: 'id='+row.id+'&namaanggota='+row.namaanggota,
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