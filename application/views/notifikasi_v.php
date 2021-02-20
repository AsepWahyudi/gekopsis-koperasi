<?php 
// Pengajuan
$jml_ajuan = count($notif_pengajuan);
$link_pengajuan = site_url('pengajuan');
if($jml_ajuan > 0) {
	?>
	<li class="dropdown messages-menu" title="Pengajuan Pinjaman">
		<a href="<?php echo $link_pengajuan; ?>">
			<i class="fa fa-envelope"></i>
			<span class="badge bg-purple" style="font-size: 14px;"><?php echo $jml_ajuan; ?></span>
		</a>
	</li> <?php
} else { ?>
	<li class="dropdown messages-menu" title="Pengajuan Pinjaman">
		<a href="<?php echo $link_pengajuan; ?>">
			<i class="fa fa-envelope"></i>
			<span class="badge bg-green" style="font-size: 14px;"><i class="fa fa-check-circle"></i></span>
		</a>
	</li>
	<?php
} ?>

<?php 
// Jatuh tempo
$jml = count($notif_tempo);
$txt_sis = array();
foreach ($notif_tempo as $row) {
	if($row->tempo != 0) {
		//$jml++;
		$tgl_tempo = explode(' ', $row->tempo);
		$tgl_tempo = jin_date_ina($tgl_tempo[0], 'p');
		$txt_sis[] = '
			<h4><strong>'.$row->nama.'</strong> <i><span style="font-size: 14px;"></span></i></h4>
			<p>
			Jatuh tempo pada tgl <span class="badge bg-blue">'.
			$tgl_tempo.'</span><br /> 
			Sisa Senilai <span class="badge bg-purple">'.number_format(nsi_round(($row->tagihan + $row->jum_denda) - $row->jum_bayar)).'</span>
			</p>';
	}
}

?>


<li class="dropdown notifications-menu" title="Jatuh Tempo">
		<?php
		if($jml > 0) {
			echo '
	<a href="#" class="dropdown-toggle" data-toggle="dropdown">
		<i class="fa fa-warning"></i>
		<span class="badge bg-red" style="font-size: 14px;">'.$jml.'</span>
	</a>
	';
		?>
	<ul class="dropdown-menu">
		<li class="header">Anda Mendapat <span class="badge bg-red"><?php echo $jml; ?></span> Notifikasi</li>
		<li>
			<!-- inner menu: contains the actual data -->
			<ul class="menu">
				<?php
				foreach ($txt_sis as $row) {
					echo '
				<li>
					<a href="'.site_url().'bayar">
					<div class="pull-left" style="font-size: 35px; padding: 0 15px; width: 27px;">
						<i class="fa fa-smile-o"></i>
					</div>
					<div style="padding: 0 5px;">
					 '.$row.'
					 </div>
					</a>
				</li>
					';
				}
				?>
								
			</ul>
		</li>
	</ul>

	<?php } else {
			echo '
	<a href="#" class="dropdown-toggle" data-toggle="dropdown">
		<i class="fa fa-warning"></i>
		<span class="badge bg-green" style="font-size: 14px;"><i class="fa fa-check-circle"></i></span>
	</a>
			';
	?>
	<ul class="dropdown-menu">
		<li class="header bg-light-blue h_tengah">Notifikasi</li>
		<li>
			<!-- inner menu: contains the actual data -->
			<ul class="menu">
				<li>
					<a>
					<div class="pull-left" style="font-size: 35px; padding: 0 15px; width: 27px;">
						<i class="fa fa-check-circle" style="color: green;"></i>
					</div>
					<div style="padding: 20px 5px 0 5px; height: 35px;">
						<p>Saat ini tidak ada Notifikasi</p>
					 </div>
					</a>
				</li>
			</ul>
		</li>
		<!-- <li class="footer"><a href="#">View all</a></li> -->
	</ul>

<script type="text/javascript">
	$(document).ready(function() {
		$(".slimScrollDiv").height(100);
	});

</script>

	<?php
		}
		?>
</li>