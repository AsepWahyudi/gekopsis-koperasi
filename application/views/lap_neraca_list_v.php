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
.faArrowIcon:before {
        font-family: FontAwesome;
        top:0;
        left:-5px;
        padding-right:10px;
        content: "\f0a9"; 
    }
</style>

<?php 
$jenis_laporan = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
/*
$blnthn_dari = isset($_GET['tgl_dari'])?$_GET['tgl_dari']:date("Y-m");
$blnthn_samp = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date("Y-m");

// buaat tanggal sekarang
if(isset($_REQUEST['tgl_dari']) && isset($_REQUEST['tgl_samp'])) {
	$tgl_dari = $_REQUEST['tgl_dari'];
	$tgl_samp = $_REQUEST['tgl_samp'];
} else {
	$tgl_dari = date('Y') . '-01-01';
	$tgl_samp = date('Y') . '-12-31';
}
$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
$tgl_samp_txt = jin_date_ina($tgl_samp, 'p');
$tgl_periode_txt = $tgl_dari_txt . ' - ' . $tgl_samp_txt;
*/
?>

<div class="box box-solid box-primary">
	<div class="box-header">
		<h3 class="box-title">Laporan Neraca Saldo</h3>
		<div class="box-tools pull-right">
			<button class="btn btn-primary btn-sm" data-widget="collapse">
				<i class="fa fa-minus"></i>
			</button>
		</div>
	</div>
	<div class="box-body">
		<div>
			<form id="fmCari" method="GET">
				<input type="hidden" name="tgl_dari" id="tgl_dari">
				<input type="hidden" name="tgl_samp" id="tgl_samp">
					<table>
						<tr>
							<td>
								<div id="filter_tgl" class="input-group" style="display: inline;">
									<button class="btn btn-default" id="daterange-btn">
										<i class="fa fa-calendar"></i> <span id="reportrange"><span><?php echo $tgl_periode_txt; ?>
										</span></span>
										<i class="fa fa-caret-down"></i>
									</button>
								</div>
							</td>
							<td>
								<select id="jenis_laporan" name="jenis_laporan">
									<option value="1">Staffel</option>
									<option value="2">Skonto</option>
									<option value="3">Perbandingan Antar Bulan</option>
								</select>
								<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-search" plain="false" onclick="cari()">Cari Laporan</a>
								<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" plain="false" onclick="cetak()">Cetak Laporan</a>
								<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-clear" plain="false" onclick="clearSearch()">Hapus Filter</a>
								<a href="javascript:void(0);" class="easyui-linkbutton" iconCls="icon-excel" plain="false" onclick="export_excel()">Ekspor</a>
							</td>
						</tr>
					</table>
					</form>
			</div>
	</div>
</div>
<div class="box box-solid box-primary">
<div class="box-body">
<p></p>
<?php if ($jenis_laporan == 3) {  ?>
	<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Neraca Saldo Periode <?php echo $tgl_periode_txt_c; ?></p>
<?php } else { ?>
	<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Laporan Neraca Saldo Periode <?php echo $tgl_periode_txt; ?></p>
<?php } ?>
<?php if ($jenis_laporan == 1) {?>
	<table class="table table-bordered">
		<tr class="header_kolom">
			<th style="text-align:center; width:5%"> </th>
			<th style="text-align:center; width:60%"> Nama Akun</th>
			<th style="text-align:center; width:15%"> Debet </th>
			<th style="text-align:center; width:15%"> Kredit </th>
		</tr>
    <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>AKTIVA</strong></td>
      <td></td>
      <td></td>
    </tr>	
    <?php $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunaktiva as $kelompok) {  
    $kel1=$kelompok['nama_kelompok'];?>
      <tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
				<td></td>
				<td></td>
			</tr>	
      <?php foreach($indukakunaktiva as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {?>
          <tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
            <td></td>
            <td></td>
          </tr>	
					<?php foreach($jns_akun_aktiva as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{?>
							<tr>
								<td> &nbsp;</td>
								<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
								<td align="right"><?php echo number_format($akun['debet'],2,',','.')?></td>
								<td align="right"><?php echo number_format($akun['credit'],2,',','.')?></td>
							</tr>	
							<?php $subtotald += $akun['debet'];$subtotalc += $akun['credit'];
								  $vsubtotald += $akun['debet'];$vsubtotalc += $akun['credit'];
						} 
					}
				}
			}	?>
      <?php if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) { ?>
						<tr>
							<td colspan="2" class="h_kanan"><strong>Total <?php echo $kelompok['nama_kelompok']?></strong></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotald),2,',','.');?></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotalc),2,',','.');?></td>
						</tr> 
						<?php $data=0;$subtotald=0;$subtotalc=0;
					} 
			
			?>
    <?php } ?>
    <tr>
      <td colspan="2" class="h_kanan"><strong>Total AKTIVA</strong></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalaktiva['debet']),2,',','.');?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalaktiva['credit']),2,',','.');?></td>
    </tr> 
    <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>PASIVA</strong></td>
      <td></td>
      <td></td>
    </tr>	
    <?php $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunpasiva as $kelompok) {  
    $kel1=$kelompok['nama_kelompok'];?>
      <tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
				<td></td>
				<td></td>
			</tr>	
      <?php foreach($indukakunpasiva as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {?>
          <tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
            <td></td>
            <td></td>
          </tr>	
					<?php foreach($jns_akun_pasiva as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{?>
							<tr>
								<td> &nbsp;</td>
								<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
								<td align="right"><?php echo number_format($akun['debet'],2,',','.')?></td>
								<td align="right"><?php echo number_format($akun['credit'],2,',','.')?></td>
							</tr>	
							<?php $subtotald += $akun['debet'];$subtotalc += $akun['credit'];
								  $vsubtotald += $akun['debet'];$vsubtotalc += $akun['credit'];
						} 
					}
				}
			}	?>
      <?php if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) { ?>
						<tr>
							<td colspan="2" class="h_kanan"><strong>Total <?php echo $kelompok['nama_kelompok']?></strong></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotald),2,',','.');?></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotalc),2,',','.');?></td>
						</tr> 
						<?php $data=0;$subtotald=0;$subtotalc=0;
					} 
        }
			?>
    <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>MODAL</strong></td>
      <td></td>
      <td></td>
    </tr>	
    <?php $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunmodal as $kelompok) {  
    $kel1=$kelompok['nama_kelompok'];?>
      <?php foreach($indukakunmodal as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {?>
          <tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
            <td></td>
            <td></td>
          </tr>	
					<?php foreach($jns_akun_modal as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{?>
							<tr>
								<td> &nbsp;</td>
								<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
								<td align="right"><?php echo number_format($akun['debet'],2,',','.')?></td>
								<td align="right"><?php echo number_format($akun['credit'],2,',','.')?></td>
							</tr>	
							<?php $subtotald += $akun['debet'];$subtotalc += $akun['credit'];
								  $vsubtotald += $akun['debet'];$vsubtotalc += $akun['credit'];
						} 
					}
				}
			}	?>
      <?php if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) { ?>
						<tr>
							<td colspan="2" class="h_kanan"><strong>Total <?php echo $kelompok['nama_kelompok']?></strong></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotald),2,',','.');?></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotalc),2,',','.');?></td>
						</tr> 
						<?php $data=0;$subtotald=0;$subtotalc=0;
					} 
        }
			?>
    <tr>
      <td colspan="2" class="h_kanan"><strong>Total MODAL</strong></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalmodal['debet']),2,',','.');?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalmodal['credit']),2,',','.');?></td>
    </tr> 
    <tr>
      <td colspan="2" class="h_kanan"><strong>Total PASIVA</strong></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalpasiva['debet']+$totalmodal['debet']),2,',','.');?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalpasiva['credit']+$totalmodal['credit']),2,',','.');?></td>
    </tr> 
  </table>
  <br>
	<table class="table table-bordered">
		<tr class="header_kolom">
			<th style="text-align:center; width:5%"> </th>
			<th style="text-align:center; width:60%"> Nama Akun</th>
			<th style="text-align:center; width:15%"> Debet </th>
			<th style="text-align:center; width:15%"> Credit</th>
			
		</tr>
		<?php
			foreach($kelchan as $kelompok) {?>
					<tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
						<td></td>
						<td></td>
					</tr>
					<?php foreach($indukchan as $induk) {
						if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) 
						{?>
							<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
								<td></td>
								<td></td>
							</tr>	
							<?php foreach($chan as $akun) { 
								if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
								{?>	
									<tr>
										<td> &nbsp;</td>
										<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
										<td align="right">0</td>
										<td align="right">0</td>
									</tr>	
							<?php }
							}
						}
					}?>
			<?php }?>
        </table>
<?php } else ?>
<?php if ($jenis_laporan == 2) { ?>
	<table class="table table-bordered">
	<tr class="header_kolom">
			<th style="text-align:center; width:10%"> </th>
			<th style="text-align:center; width:30%"> Keterangan</th>
			<th style="text-align:center; width:10%"> Jumlah</th>
			<th style="text-align:center; width:10%"> </th>
			<th style="text-align:center; width:30%"> Keterangan</th>
			<th style="text-align:center; width:15%"> Jumlah</th>
		</tr>
		<?php foreach($datas as $row) { $keldebet1=$row['kelompok_debet'];
				if (($row['kelompok_debet'] == '') && ($row['akun_debet'] == '') && ($row['kelompok_kredit'] == '') && ($row['akun_kredit'] == '')) {?>
					<tr>
						<td>&nbsp;</td>
						<td>&nbsp;</td>
						<td>&nbsp;</td>
						<td>&nbsp;</td>
						<td>&nbsp;</td>
						<td>&nbsp;</td>
					</tr> 
				<?php } else {?>	
							<tr>
								<?php if ($row['kelompok_debet'] != '') { ?>
									<?php if ($row['is_total_debet'] == 0) { ?>
											<td><strong><?php echo $row['kelompok_debet'] ?></strong></td>
									<?php } else { ?>
										<td><strong><?php echo 'TOTAL '.$row['kelompok_debet'] ?></strong></td>
									<?php } ?>
								<?php } else { ?>
									<td><br></td>
								<?php } ?>

								<?php if ($row['akun_debet'] != '') { ?>
									<?php if ($row['induk_akun_debet'] != '') { ?>
											<td><?php echo $row['akun_debet'] ?></td>
											<td class="h_kanan"><?php echo number_format($row['value_debet'],2,',','.') ?></td>
									<?php } else 
									if ($row['induk_akun_debet'] == '') { ?>
											<td><strong><?php echo $row['akun_debet'] ?></strong></td>
											<td></td>
									<?php }
								} else
								if (($row['kelompok_debet'] != '') && ($row['is_total_debet'])) { ?>
										<td></td>
										<td class="h_kanan"><strong><?php echo number_format($row['total_kelompok_debet'],2,',','.')?></strong></td>
								<?php } else {?>
										<td></td>
										<td></td>
								<?php }?>
								<?php if ($row['kelompok_kredit'] != '') { ?>
										<?php if ($row['is_total_kredit'] == 0) { ?>
											<td><strong><?php echo $row['kelompok_kredit'] ?></strong></td>
										<?php } else { ?>
											<td><strong><?php echo 'TOTAL '.$row['kelompok_kredit'] ?></strong></td>
										<?php } ?>
								<?php } else { ?>
										<td><br></td>
								<?php } ?>

								<?php if ($row['akun_kredit'] != '') { ?>
									<?php if ($row['induk_akun_kredit'] != '') { ?>
										<td><?php echo $row['akun_kredit'] ?></td>
										<td class="h_kanan"><?php echo number_format($row['value_kredit'],2,',','.') ?></td>
									<?php } else 
										if ($row['induk_akun_kredit'] == '') { ?>
											<td><strong><?php echo $row['akun_kredit'] ?></strong></td>
											<td></td>
										<?php }
								} else
									if (($row['kelompok_kredit'] != '') && ($row['is_total_kredit'])) { ?>
										<td></td>
										<td class="h_kanan"><strong><?php echo number_format($row['total_kelompok_kredit'],2,',','.')?></strong></td>
									<?php } else {?>
										<td></td>
										<td></td>
									<?php }	?>
							</tr>	
			<?php }
		}?>
		<tr>
				<td colspan="2"><strong>JUMLAH AKTIVA</strong></td>
				<td class="h_kanan"><strong><?php echo number_format($total['debet'],2,',','.')?></strong></td>
				<td colspan="2"><strong>JUMLAH PASIVA</strong></td>
				<td class="h_kanan"><strong><?php echo number_format($total['credit'],2,',','.')?></strong></td>
			</tr> 	
	</table>
	<br>
	<table class="table table-bordered">
	<tr class="header_kolom">
			<th style="text-align:center; width:10%"> </th>
			<th style="text-align:center; width:30%"> Keterangan</th>
			<th style="text-align:center; width:10%"> Jumlah</th>
			<th style="text-align:center; width:10%"> </th>
			<th style="text-align:center; width:30%"> Keterangan</th>
			<th style="text-align:center; width:10%"> Jumlah</th>
		</tr>
		<?php $offbalancesheet = ""; foreach($datachan as $row) { 
				$offbalancesheet = $row['kelompok_debet'];
			 } ?>
			<tr>
				<td><b><?php echo $offbalancesheet; ?></b></td>
				<td></td>
				<td></td>
				<td></td>
				<td></td>
				<td></td>
			</tr> 		
				<?php foreach($datachan as $row1) { ?>
					<tr>
					<td></td>
					<td><?php if (strpos($row1['akun_debet'], '801.00.00') !== false || strpos($row1['akun_debet'], '901.00.00') !== false) { echo '<b>'.$row1['akun_debet'].'</b>'; } else { echo $row1['akun_debet'];}?></td>
					<td>0</td>
					<td></td>
					<td></td>
					<td></td>
					</tr>
				<?php }  ?>
		</table>

<?php } else ?>
<?php if ($jenis_laporan == 3) { ?>
	<table class="table table-bordered">
		<tr class="header_kolom">
			<th style="text-align:center; width:5%"> </th>
			<th style="text-align:center; width:60%"> Nama Akun</th>
			<th style="text-align:center; width:15%"> Bulan <?php echo date("F Y",strtotime($tgl_dari))?></th>
			<th style="text-align:center; width:15%"> Bulan <?php echo date("F Y",strtotime($tgl_samp))?></th>
		</tr>
    <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>AKTIVA</strong></td>
      <td></td>
      <td></td>
    </tr>	
    <?php $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunaktiva as $kelompok) {  
      $kel1=$kelompok['nama_kelompok'];?>
      <tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
				<td></td>
				<td></td>
			</tr>	
      <?php foreach($indukakunaktiva as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {?>
          <tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
            <td></td>
            <td></td>
          </tr>	
					<?php foreach($jns_akun_aktiva as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{?>
							<tr>
								<td> &nbsp;</td>
								<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
								<td align="right"><?php echo number_format($akun['debet'],2,',','.')?></td>
								<td align="right"><?php echo number_format($akun['credit'],2,',','.')?></td>
							</tr>	
							<?php $subtotald += $akun['debet'];$subtotalc += $akun['credit'];
								  $vsubtotald += $akun['debet'];$vsubtotalc += $akun['credit'];
						} 
					}
				}
			}	?>
      <?php if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) { ?>
						<tr>
							<td colspan="2" class="h_kanan"><strong>Total <?php echo $kelompok['nama_kelompok']?></strong></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotald),2,',','.');?></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotalc),2,',','.');?></td>
						</tr> 
						<?php $data=0;$subtotald=0;$subtotalc=0;
					} 
			?>
    <?php } ?>
    <tr>
      <td colspan="2" class="h_kanan"><strong>Total AKTIVA</strong></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalaktiva['debet']),2,',','.');?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalaktiva['credit']),2,',','.');?></td>
    </tr> 
    <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>PASIVA</strong></td>
      <td></td>
      <td></td>
    </tr>	
    <?php $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunpasiva as $kelompok) {  
      $kel1=$kelompok['nama_kelompok'];?>
      <tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
				<td></td>
				<td></td>
			</tr>	
      <?php foreach($indukakunpasiva as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {?>
          <tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
            <td></td>
            <td></td>
          </tr>	
					<?php foreach($jns_akun_pasiva as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{?>
							<tr>
								<td> &nbsp;</td>
								<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
								<td align="right"><?php echo number_format($akun['debet'],2,',','.')?></td>
								<td align="right"><?php echo number_format($akun['credit'],2,',','.')?></td>
							</tr>	
							<?php $subtotald += $akun['debet'];$subtotalc += $akun['credit'];
								  $vsubtotald += $akun['debet'];$vsubtotalc += $akun['credit'];
						} 
					}
				}
			}	?>
      <?php if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) { ?>
						<tr>
							<td colspan="2" class="h_kanan"><strong>Total <?php echo $kelompok['nama_kelompok']?></strong></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotald),2,',','.');?></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotalc),2,',','.');?></td>
						</tr> 
						<?php $data=0;$subtotald=0;$subtotalc=0;
					} 
			?>
    <?php } ?>
    <?php $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunmodal as $kelompok) {  
      $kel1=$kelompok['nama_kelompok'];?>
      <tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
				<td></td>
				<td></td>
			</tr>	
      <?php foreach($indukakunmodal as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {?>
          <tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
            <td></td>
            <td></td>
          </tr>	
					<?php foreach($jns_akun_modal as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{?>
							<tr>
								<td> &nbsp;</td>
								<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
								<td align="right"><?php echo number_format($akun['debet'],2,',','.')?></td>
								<td align="right"><?php echo number_format($akun['credit'],2,',','.')?></td>
							</tr>	
							<?php $subtotald += $akun['debet'];$subtotalc += $akun['credit'];
								  $vsubtotald += $akun['debet'];$vsubtotalc += $akun['credit'];
						} 
					}
				}
			}	?>
      <?php if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) { ?>
						<tr>
							<td colspan="2" class="h_kanan"><strong>Total <?php echo $kelompok['nama_kelompok']?></strong></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotald),2,',','.');?></td>
							<td class="h_kanan"><?php echo number_format(nsi_round($subtotalc),2,',','.');?></td>
						</tr> 
						<?php $data=0;$subtotald=0;$subtotalc=0;
					} 
			?>
    <?php } ?>
    <tr>
      <td colspan="2" class="h_kanan"><strong>Total MODAL</strong></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalmodal['debet']),2,',','.');?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalmodal['credit']),2,',','.');?></td>
    </tr> 
    <tr>
      <td colspan="2" class="h_kanan"><strong>Total PASIVA</strong></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalpasiva['debet']+$totalmodal['debet']),2,',','.');?></td>
      <td class="h_kanan"><?php echo number_format(nsi_round($totalpasiva['credit']+$totalmodal['credit']),2,',','.');?></td>
    </tr> 
	</table>
	<br>
	<table class="table table-bordered">
		<tr class="header_kolom">
			<th style="text-align:center; width:5%"> </th>
			<th style="text-align:center; width:60%"> Nama Akun</th>
			<th style="text-align:center; width:15%"> Bulan <?php echo date("F Y",strtotime($tgl_dari))?></th>
			<th style="text-align:center; width:15%"> Bulan <?php echo date("F Y",strtotime($tgl_samp))?></th>
			
		</tr>
		<?php
			foreach($kelchan as $kelompok) {?>
					<tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong><?php echo $kelompok['nama_kelompok'] ?></strong></td>
						<td></td>
						<td></td>
					</tr>
					<?php foreach($indukchan as $induk) {
						if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) 
						{?>
							<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong><?php echo $induk['no_akun'].' - '.$induk['nama_akun'] ?></strong></td>
								<td></td>
								<td></td>
							</tr>	
							<?php foreach($chan as $akun) { 
								if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
								{?>	
									<tr>
										<td> &nbsp;</td>
										<td><?php echo $akun['no_akun'].' - '.$akun['nama_akun'] ?></td>
										<td align="right">0</td>
										<td align="right">0</td>
									</tr>	
							<?php }
							}
						}
					}?>
			<?php }?>

<?php } ?>
        </table>
</div>
</div>
	
<script type="text/javascript">
$(document).ready(function() {
	fm_filter_tgl();
	$('#jenis_laporan').val(<?php echo isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1?>);
}); // ready

function fm_filter_tgl() {
	$('#daterange-btn').daterangepicker({
		ranges: {
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
	window.location.href = '<?php echo site_url("lap_neraca"); ?>';
}

function cari() {
	doSearch();
}

function doSearch() {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	$('input[name=tgl_dari]').val(tgl_dari);
	$('input[name=tgl_samp]').val(tgl_samp);
	$('#fmCari').attr('action', '<?php echo site_url('lap_neraca'); ?>');
	$('#fmCari').submit();	
}

function cetak () {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	var jenis_laporan = $('#jenis_laporan').val();

	var win = window.open('<?php echo site_url("lap_neraca/cetak/?tgl_dari=' + tgl_dari + '&tgl_samp=' + tgl_samp + '&jenis_laporan=' + jenis_laporan + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}	
}

function export_excel() {
	var tgl_dari = $('input[name=daterangepicker_start]').val();
	var tgl_samp = $('input[name=daterangepicker_end]').val();
	var jenis_laporan = $('#jenis_laporan').val();

	var win = window.open('<?php echo site_url("lap_neraca/export_excel/?tgl_dari=' + tgl_dari + '&tgl_samp=' + tgl_samp + '&jenis_laporan=' + jenis_laporan + '"); ?>');
	if (win) {
		win.focus();
	} else {
		alert('Popup jangan di block');
	}	
}

</script>