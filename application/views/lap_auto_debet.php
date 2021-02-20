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

<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Cetak Data Auto Debet</h3>
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-sm" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
		<table>
			<tr>
				<td> Pilih ID Anggota </td>
				<td>
					<form id="fmCari">
					 <input id="anggota_id" name="anggota_id" value="" style="width:200px; height:25px" class="">
					 </form>
				</td>	
				<td>
					<a href="javascript:void(0);" id="btn_filter" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="doSearch()">Lihat Laporan</a>
					<!--<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>-->
					<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
					<a href="<?=base_url()?>lap_auto_debet/export_excel" class="easyui-linkbutton" iconCls="icon-excel" plain="false">Ekspor</a>
				</tr>
			</table>
		</div>
</div>

<div class="box box-primary">
	<div class="box-body">
	<?php
		$first_day_this_month = date('Y-m-01'); // hard-coded '01' for first day
		$last_day_this_month  = date('Y-m-t');
	?>
	<p></p>
	<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Data Auto Debet (<?=$first_day_this_month.' - '.$last_day_this_month?>)</p>
	<table  class="table table-bordered">
		<tr class="header_kolom">
			<th style="width:5%; vertical-align: middle; text-align:center" > No. </th>
			<th style="width:5%; vertical-align: middle; text-align:center">Photo</th>
			<th style="width:25%; vertical-align: middle; text-align:center"> Identitas  </th>
			<th style="width:20%; vertical-align: middle; text-align:center">Auto Debet Simpanan</th>
			<th style="width:20%; vertical-align: middle; text-align:center"> Auto Debet Pinjaman </th>
			<th style="width:23%; vertical-align: middle; text-align:center"> Keterangan </th>
		</tr>
	<?php
	
	$no = $offset + 1;
	$mulai=1;
	if (!empty($data_anggota)) {
		
		$query = $this->db->query("select * from auto_debet_tempo");
		
		foreach ($data_anggota as $row) {
			
			$status_anggota_array=array('anggota'=>'1','anggota luarbiasa'=>'2');

			//echo var_dump($status_anggota_array[$row->status_anggota]);
			
			foreach ($query->result() as $key) {
				//var_dump($status_anggota_array);die();
				if($status_anggota_array[$row->jns_anggotaid] == $key->status_anggota){
					
					//if($key->tanggal_tempo == 6){
					
						if(($no % 2) == 0) {
							$warna="#EEEEEE"; } 
						else {
							$warna="#FFFFFF";}

						//pinjaman
						$pinjaman = $this->lap_kas_anggota_m->get_data_pinjam($row->id);
						$pinjam_id = @$pinjaman->id;
						$anggota_id = @$pinjaman->anggota_id;

						$jml_pj = $this->lap_kas_anggota_m->get_jml_pinjaman($anggota_id);
						$pj_anggota= @$jml_pj->total;

						//denda
						$denda = $this->lap_kas_anggota_m->get_jml_denda($pinjam_id);
						$tagihan= @$pinjaman->tagihan + $denda->total_denda;
						//dibayar
						$dibayar = $this->lap_kas_anggota_m->get_jml_bayar($pinjam_id);
						$sisa_tagihan = $tagihan - $dibayar->total;

						$peminjam_tot = $this->lap_kas_anggota_m->get_peminjam_tot($row->id);
						$peminjam_lunas = $this->lap_kas_anggota_m->get_peminjam_lunas($row->id);

						$tgl_tempo = explode(' ', @$pinjaman->tempo);
						$tgl_tempo_txt = jin_date_ina($tgl_tempo[0],'p');
						$tgl_tempo_r = $tgl_tempo[0];

						$tgl_tempo_rr = explode('-', $tgl_tempo_r);
						$thn = $tgl_tempo_rr[0];
						$bln = @$tgl_tempo_rr[1];

						if ((@$pinjaman->lunas == 'Belum') && (date('m') > $bln ) && (date('y') > $thn )) {
							$data = 'Macet';
						} else {
							$data = 'Lancar';
						}

						//photo
						$photo_w = 3 * 20;
						$photo_h = 4 * 20;
						if($row->file_pic == '') {
							$photo ='<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="'.$photo_w.'" height="'.$photo_h.'" />';
						} else {
							$photo= '<img src="'.base_url().'uploads/anggota/' . $row->file_pic . '" alt="Foto" width="'.$photo_w.'" height="'.$photo_h.'" />';
						}

						//jk
						if ($row->jk == "L") {
							$jk="Laki-Laki";
						} else {
							$jk="Perempuan"; 
						}

						//jabatan
						if ($row->jabatan_id == "1") {
							$jabatan="Pengurus";
						} else {
							$jabatan="Anggota"; 
						}
						// AG'.sprintf('%04d', $row->id).'
						
						echo '
							<tr bgcolor='.$warna.' >
								<td class="h_tengah" style="vertical-align: middle "> '.$no++.' </td>
								<td class="h_tengah" style="vertical-align: top "> '.$photo.'</td>
								<td> 
									<table>
										<tr><td> ID Anggota : '.$row->identitas.'</td></tr>
										<tr><td> Nama : <b>'.strtoupper($row->nama).'</b> </td></tr>
										<tr><td> Jenis Kelamin : '.$jk.' </td></tr>
										<tr><td> Jabatan : '.$jabatan.' - '.$row->departement.'</td></tr>
										<tr><td> Alamat  : '.$row->alamat.' Telp.'.$row->notelp.' </td></tr>
									</table>
								</td>
								<td>';
								$simpanan_arr = array();
								$simpanan_row_total = 0; 
								$simpanan_total = 0; 
								foreach ($data_jns_simpanan as $jenis) {
									$simpanan_arr[$jenis->id] = $jenis->jns_simpan;
									$nilai_s = $this->lap_kas_anggota_m->get_jml_simpanan($jenis->id, $row->id);
									$nilai_p = $this->lap_kas_anggota_m->get_jml_penarikan($jenis->id, $row->id);
									
									//$simpanan_row=$nilai_s->jml_total - $nilai_p->jml_total;
									if($jenis->jns_simpan=="Simpanan Sukarela"){
										$lap_autodebet_per_simpanan = $this->autodebet_m->lap_autodebet_per_simpanan($first_day_this_month,$last_day_this_month,$jenis->id,$row->id);
										if($lap_autodebet_per_simpanan->num_rows() == 0){
											$simpanan_row = 0;	
										}
										else{
											$simpanan_row = $lap_autodebet_per_simpanan->row()->total;
										}
									}else if($jenis->jns_simpan=="Simpanan Pokok"){
										$lap_autodebet_per_simpanan = $this->autodebet_m->lap_autodebet_per_simpanan($first_day_this_month,$last_day_this_month,$jenis->id,$row->id);
										if($lap_autodebet_per_simpanan->num_rows() == 0){
											$simpanan_row = 0;	
										}
										else{
											$simpanan_row = $lap_autodebet_per_simpanan->row()->total;
										}
									}else if($jenis->jns_simpan=="Simpanan Wajib"){
									 	$lap_autodebet_per_simpanan = $this->autodebet_m->lap_autodebet_per_simpanan($first_day_this_month,$last_day_this_month,$jenis->id,$row->id);
										if($lap_autodebet_per_simpanan->num_rows() == 0){
											$simpanan_row = 0;	
										}
										else{
											$simpanan_row = $lap_autodebet_per_simpanan->row()->total;
										}
									}else if($jenis->jns_simpan=="Simpanan Khusus"){
										$lap_autodebet_per_simpanan = $this->autodebet_m->lap_autodebet_per_simpanan($first_day_this_month,$last_day_this_month,$jenis->id,$row->id);
										if($lap_autodebet_per_simpanan->num_rows() == 0){
											$simpanan_row = 0;	
										}
										else{
											$simpanan_row = $lap_autodebet_per_simpanan->row()->total;
										}
									}else if($jenis->jns_simpan=="Simpanan Harian"){
										$lap_autodebet_per_simpanan = $this->autodebet_m->lap_autodebet_per_simpanan($first_day_this_month,$last_day_this_month,$jenis->id,$row->id);
										if($lap_autodebet_per_simpanan->num_rows() == 0){
											$simpanan_row = 0;	
										}
										else{
											$simpanan_row = $lap_autodebet_per_simpanan->row()->total;
										}
									}

									$simpanan_row_total += $simpanan_row;
									$simpanan_total += $simpanan_row_total;

									echo'<table style="width:100%;">
											<tr>
												<td>'.$jenis->jns_simpan.'</td>
												<td class="h_kanan">'. number_format($simpanan_row).'</td>
											</tr>';
									}
									echo '<tr>
												<td><strong> Tagihan Simpanan </strong></td>
												<td class="h_kanan"><strong> '.number_format($simpanan_row_total).'</strong></td>
											</tr>
											</table>';
									
									$lap_autodebet_per_pinjaman = $this->autodebet_m->lap_autodebet_per_pinjaman($first_day_this_month,$last_day_this_month,$row->id);
									echo '		
									<td>
										<table style="width:100%;" border="0"> ';
									$total_tagihan_pinjaman_arr = array();	
									foreach($lap_autodebet_per_pinjaman->result() as $row_tagihan_pinjaman){
									echo '		
											<tr>
												<td> '.$row_tagihan_pinjaman->jns_pinjaman.'</td>
												<td class="h_kanan">'.number_format($row_tagihan_pinjaman->total).'</td>
											</tr>';
										array_push($total_tagihan_pinjaman_arr,$row_tagihan_pinjaman->total);	
									}
									
									$tgl_tempo_txt = '';
									if(array_sum($total_tagihan_pinjaman_arr) != 0 || $simpanan_row_total != 0){
										if($row->status_anggota == '1'){
											$tgl_tempo_txt = $setting_autodebet->tgl_tempo_anggota;
										}else{
											$tgl_tempo_txt = $setting_autodebet->tgl_tempo_anggota_luarbiasa;
										}
									}
									
									echo '
											<tr>
												<td><strong> Tagihan Pinjaman</strong></td>
												<td class="h_kanan"> <strong>'.number_format(array_sum($total_tagihan_pinjaman_arr)).'</strong></td>
											</tr>
										</table>
									</td>
									<td> 
										<table style="width:100%;" > 
											<tr>
												<td> Jumlah Pinjaman </td>
												<td class="h_kanan">'.$peminjam_tot.'</td>
											</tr>
											<tr>
												<td> Pinjaman Lunas </td>
												<td class="h_kanan">'.$peminjam_lunas.'</td>
											</tr>
											<tr>
												<td> Pembayaran</td>
												<td class="h_kanan"> <code>'.$data.'</code></td>
											</tr>
											<tr>
												<td> Tanggal Tempo</td>
												<td class="h_kanan"> <code>'.$tgl_tempo_txt.'-'.$current_month.'-'.$current_year.'</code></td>
											</tr>
										</table><br>';
									
									
									$detail_pinjaman = $this->lap_kas_anggota_m->get_pinjaman_anggota($row->id);
									if(count($detail_pinjaman)>0){
										echo "<h4>Informasi Pinjaman</h4><hr>";
									}
									foreach ($detail_pinjaman as $dp) {
										echo 
											'<table style="text-align:left">
												<tr>
													<td width="100px" align="left">Nama Barang</td> 
													<td width="10px" align="center"> : </td>
													<td width="100px" align="left">'.$dp->nm_barang.'</td>
												</tr>
												<tr>
													<td width="100px" align="left">Harga Barang</td> 
													<td width="10px" align="center"> : </td>
													<td width="100px">Rp. '.number_format($dp->jumlah) .'</td>
												</tr>
												<tr>
													<td width="100px" align="left">Lama Angsuran</td> 
													<td width="10px" align="center"> : </td>
													<td width="100px">'.$dp->lama_angsuran.' Bulan</td>
												</tr>
												<tr>
													<td width="100px" align="left">Pokok Angsuran</td> 
													<td width="10px" align="center"> : </td>
													<td width="100px">Rp. '.number_format($dp->pokok_angsuran) .'</td>
												</tr>
												<tr>
													<td width="100px" align="left">Bunga Pinjaman</td> 
													<td width="10px" align="center"> : </td>
													<td width="100px">Rp. '.number_format(nsi_round($dp->bunga_pinjaman)).'</td>
												</tr>
												<tr>
													<td width="100px" align="left">Biaya Admin</td> 
													<td width="10px" align="center"> : </td>
													<td width="100px">Rp. '.number_format($dp->biaya_adm) .'</td>
												</tr>
											</table>=============================';
									}

								echo'		
									</td>
								</tr>';
							}
						}
					//}
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
	$(document).ready(function() {

	<?php 
		if(isset($_REQUEST['anggota_id'])) {
			echo 'var anggota_id = "'.$_REQUEST['anggota_id'].'";';
		} else {
			echo 'var anggota_id = "";';
		}
		echo '$("#anggota_id").val(anggota_id);';
	?>

		$('#anggota_id').combogrid({
			panelWidth:300,
			url: '<?php echo site_url('lap_shu_anggota/list_anggota'); ?>' ,
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

function clearSearch(){
	window.location.href = '<?php echo site_url("lap_kas_anggota"); ?>';
}

function cetak () {
	<?php 
		if(isset($_REQUEST['anggota_id'])) {
			echo 'var anggota_id = "'.$_REQUEST['anggota_id'].'";';
		} else {
			echo 'var anggota_id = $("#anggota_id").val();';
		}
	?>
	var win = window.open('<?php echo site_url("lap_auto_debet/cetak_laporan/?anggota_id=' + anggota_id +'"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}
	//$('#fmCari').attr('action', '<?php echo site_url('lap_kas_anggota/cetak_laporan'); ?>');
	//$('#fmCari').submit();
}

function doSearch() {
	$('#fmCari').submit();
}
</script>