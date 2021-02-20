<a href="<?php echo site_url();?>" class="logo">
	<div style="text-align:center;"><img height="50" src="<?php echo base_url().'assets/theme_admin/img/logo2.png'; ?>"></div>
</a>

<ul class="sidebar-menu">
<li class="<?php 
	 $menu_home_arr= array('home', '');
	 if(in_array($this->uri->segment(1), $menu_home_arr)) {echo "active";}?>">
		<a href="<?php echo base_url(); ?>home">
			<img height="20" src="<?php echo base_url().'assets/theme_admin/img/home.png'; ?>"> <span>Beranda</span>
		</a>
</li>

<!-- Menu Transaksi -->

<?php if (($level == 'Admin') || ($level == 'Operator') || ($level == 'Manajer') || ($level == 'Pengurus')) { ?>
<li  class="treeview <?php 
	 $menu_trans_arr= array('journal_voucher','fixed_asset', 'sewa_kantor','toko','postingbulanan');
	 if(in_array($this->uri->segment(1), $menu_trans_arr)) {echo "active";}?>">

	<a href="#">
		<img height="20" src="<?php echo base_url().'assets/theme_admin/img/transaksi.png'; ?>">
		<span>Transaksi Keuangan</span>
		<i class="fa fa-angle-left pull-right"></i>
	</a>
	<ul class="treeview-menu">
		<li class="<?php if ($this->uri->segment(1) == 'sewa_kantor') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>sewa_kantor"> <i class="fa fa-folder-open-o"></i> Biaya Dibayar Dimuka </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'journal_voucher') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>journal_voucher"> <i class="fa fa-folder-open-o"></i> Jurnal Transaksi </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'fixed_asset') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>fixed_asset"> <i class="fa fa-folder-open-o"></i> Fixed Asset </a></li>		
		<li class="<?php if ($this->uri->segment(1) == 'toko') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>toko"> <i class="fa fa-folder-open-o"></i> Toko </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'postingbulanan') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>postingbulanan"> <i class="fa fa-folder-open-o"></i> Posting Bulanan </a></li>
	</ul>
</li>
<?php } ?>


<?php if (($level == 'Operator') || ($level == 'Admin')) { ?>
<!-- Menu Simpanan -->
<li  class="treeview <?php 
	 $menu_trans_arr= array('deposito','tarik_deposito');
	 if(in_array($this->uri->segment(1), $menu_trans_arr)) {echo "active";}?>">

	<a href="#">
		<img height="20" src="<?php echo base_url().'assets/theme_admin/img/uang.png'; ?>">
		<span>Deposito</span>
		<i class="fa fa-angle-left pull-right"></i>
	</a>
	<ul class="treeview-menu">
		<li class="<?php if ($this->uri->segment(1) == 'deposito') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>deposito"> <i class="fa fa-folder-open-o"></i> Setoran Deposito </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'tarik_deposito') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>tarik_deposito"> <i class="fa fa-folder-open-o"></i> Penarikan Deposito</a></li>
	</ul>
</li>
<?php } ?>


<?php if (($level == 'Operator') || ($level == 'Admin')) { ?>
<!-- Menu Simpanan -->
<li  class="treeview <?php 
	 $menu_trans_arr= array('simpanan','penarikan');
	 if(in_array($this->uri->segment(1), $menu_trans_arr)) {echo "active";}?>">

	<a href="#">
		<img height="20" src="<?php echo base_url().'assets/theme_admin/img/uang.png'; ?>">
		<span>Simpanan</span>
		<i class="fa fa-angle-left pull-right"></i>
	</a>
	<ul class="treeview-menu">
		<li class="<?php if ($this->uri->segment(1) == 'simpanan') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>simpanan"> <i class="fa fa-folder-open-o"></i> Setoran Tunai </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'penarikan') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>penarikan"> <i class="fa fa-folder-open-o"></i> Penarikan Tunai</a></li>
	</ul>
</li>
<?php } ?>

<?php if (($level == 'Operator') || ($level == 'Admin')) { ?>
<!-- menu pinjaman -->
<li  class="treeview <?php 
$menu_pinjam_arr= array('pengajuan','pinjaman','bayar','pelunasan', 'angsuran','angsuran_detail','angsuran_lunas','repayment_schedule');
if(in_array($this->uri->segment(1), $menu_pinjam_arr)) {echo "active";}?>">

<a href="#">
	<img height="20" src="<?php echo base_url().'assets/theme_admin/img/pinjam.png'; ?>">
	<span>Pinjaman</span>
	<i class="fa fa-angle-left pull-right"></i>
</a>
<ul class="treeview-menu">
	<li class="<?php if ($this->uri->segment(1) == 'pengajuan' || $this->uri->segment(1) == 'pengajuan'){ echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>pengajuan"> <i class="fa fa-folder-open-o"></i> Data Pengajuan </a></li>
	<?php if($level != 'pinjaman') { ?>
	<li class="<?php if ($this->uri->segment(1) == 'pinjaman' || $this->uri->segment(1) == 'angsuran_detail'){ echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>pinjaman"> <i class="fa fa-folder-open-o"></i> Data Pinjaman </a></li>  
	<li class="<?php if ($this->uri->segment(1) == 'bayar' || $this->uri->segment(1) == 'angsuran') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>bayar"> <i class="fa fa-folder-open-o"></i> Bayar Angsuran</a></li> 
	<li class="<?php if ($this->uri->segment(1) == 'pelunasan' || $this->uri->segment(1) == 'angsuran_lunas') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>pelunasan"> <i class="fa fa-folder-open-o"></i> Pinjaman Lunas </a></li>
	<li class="<?php if ($this->uri->segment(1) == 'repayment_schedule' || $this->uri->segment(1) == 'repayment_schedule') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>repayment_schedule"> <i class="fa fa-folder-open-o"></i> Repayment Schedule </a></li>
	<?php } ?>
</ul>
</li>
<?php } ?>

<!-- laporan -->
<li  class="treeview <?php 
	 $menu_lap_arr= array('lap_anggota','lap_kas_anggota','lap_simpanan','lap_kas_pinjaman','lap_tempo','lap_macet','lap_trans_kas','lap_buku_besar','lap_neraca','lap_saldo','lap_laba','lap_shu','lap_auto_debet','lap_toko','lap_trans_toko','lap_pinjaman_toko','log_installment','lap_sewa_kantor','lap_deposito','lap_fixedasset');
	 if(in_array($this->uri->segment(1), $menu_lap_arr)) {echo "active";}?>">
	<a href="#">
		<img height="20" src="<?php echo base_url().'assets/theme_admin/img/laporan.png'; ?>">
		<span>Laporan</span>
		<i class="fa fa-angle-left pull-right"></i>
	</a>
	<ul class="treeview-menu">
	<?php if($level != 'pinjaman') { ?>
		<li class="<?php if ($this->uri->segment(1) == 'lap_anggota') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_anggota"><i class="fa fa-folder-open-o"></i> Data Anggota </a></li>
	<?php } ?>
		<li class="<?php if ($this->uri->segment(1) == 'lap_kas_anggota') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>lap_kas_anggota"> <i class="fa fa-folder-open-o"></i> Kas Anggota </a></li>
	<?php if($level != 'pinjaman') { ?>
		<li class="<?php if ($this->uri->segment(1) == 'lap_tempo') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_tempo"><i class="fa fa-folder-open-o"></i> Tagihan Angsuran Pinjaman</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_macet') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_macet"><i class="fa fa-folder-open-o"></i> Kredit Macet</a></li> 
		<li class="<?php if ($this->uri->segment(1) == 'lap_deposito') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_deposito"><i class="fa fa-folder-open-o"></i> Transaksi Deposito</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_trans_kas') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_trans_kas"><i class="fa fa-folder-open-o"></i> Transaksi Kas</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_simpanan') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>lap_simpanan"> <i class="fa fa-folder-open-o"></i> Kas Simpanan </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_kas_pinjaman') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>lap_kas_pinjaman"> <i class="fa fa-folder-open-o"></i> Kas Pinjaman </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_saldo') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_saldo"><i class="fa fa-folder-open-o"></i> Saldo Kas </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_pinjaman_toko') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_pinjaman_toko"><i class="fa fa-folder-open-o"></i> Pinjaman Toko </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_shu') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_shu"><i class="fa fa-folder-open-o"></i> SHU </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_fixedasset') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_fixedasset"><i class="fa fa-folder-open-o"></i>Fixed Asset</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_laba') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_laba"><i class="fa fa-folder-open-o"></i> Laba Rugi </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_buku_besar') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_buku_besar"><i class="fa fa-folder-open-o"></i> Buku Besar</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_neraca') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_neraca"><i class="fa fa-folder-open-o"></i> Neraca Saldo</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'log_installment') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>log_installment"><i class="fa fa-folder-open-o"></i> Log Angsuran</a></li>
		<li class="<?php if ($this->uri->segment(1) == 'lap_sewa_kantor') { echo 'active'; } ?>"> <a href="<?php echo base_url(); ?>lap_sewa_kantor"><i class="fa fa-folder-open-o"></i> Biaya Dibayar Dimuka</a></li>
		<?php } ?>
	</ul>
</li>

<?php if (($level == 'Admin') || ($level == 'Operator')) { ?>
<!-- Master data -->
<li  class="treeview <?php 
$menu_data_arr= array('jenis_cabang','jenis_simpanan','jenis_akun','jenis_kas','jenis_angsuran','data_barang','anggota','user','jenis_pinjaman','jenis_anggota','jenis_pengajuan','jenis_deposito','kelompok_akun','kategori_asset','neraca_skonto');
if(in_array($this->uri->segment(1), $menu_data_arr)) {echo "active";}?>">

<a href="#">
	<img height="20" src="<?php echo base_url().'assets/theme_admin/img/data.png'; ?>">
	<span>Master Data</span>
	<i class="fa fa-angle-left pull-right"></i>
</a>
<ul class="treeview-menu">
	<?php if($level == 'Admin') { ?>
		<li class="<?php if ($this->uri->segment(1) == 'jenis_deposito') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_deposito"> <i class="fa fa-folder-open-o"></i> Jenis Deposito </a></li>	
		<li class="<?php if ($this->uri->segment(1) == 'jenis_simpanan') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_simpanan"> <i class="fa fa-folder-open-o"></i> Jenis Simpanan </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'jenis_pinjaman') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_pinjaman"> <i class="fa fa-folder-open-o"></i> Jenis Pinjaman </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'kelompok_akun') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>kelompok_akun"> <i class="fa fa-folder-open-o"></i> Kelompok Akun </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'jenis_akun') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_akun"> <i class="fa fa-folder-open-o"></i> Jenis Akun </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'neraca_skonto') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>neraca_skonto"> <i class="fa fa-folder-open-o"></i> Layout Neraca Skonto </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'jenis_anggota') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_anggota"> <i class="fa fa-folder-open-o"></i> Jenis Anggota </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'jenis_pengajuan') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_pengajuan"> <i class="fa fa-folder-open-o"></i> Jenis Pengajuan </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'jenis_kas') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_kas"> <i class="fa fa-folder-open-o"></i> Data Kas </a></li>   
		<li class="<?php if ($this->uri->segment(1) == 'jenis_angsuran') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_angsuran"> <i class="fa fa-folder-open-o"></i> Lama Angsuran </a></li>
		<li class="<?php if ($this->uri->segment(1) == 'kategori_asset') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>kategori_asset"> <i class="fa fa-folder-open-o"></i> Kategori Asset </a></li>
	<?php } ?>
	<li class="<?php if ($this->uri->segment(1) == 'data_barang') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>data_barang"> <i class="fa fa-folder-open-o"></i> Data Barang </a></li>
	<li class="<?php if ($this->uri->segment(1) == 'anggota') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>anggota"> <i class="fa fa-folder-open-o"></i> Data Anggota</a></li>
</ul>
</li>
<?php } ?>

<!-- MENU Setting -->
<?php if($level == 'Admin') { ?>
<li  class="treeview <?php 
$menu_sett_arr= array('profil','suku_bunga', 'restore');
if(in_array($this->uri->segment(1), $menu_sett_arr)) {echo "active";}?>">

<a href="#">
	<img height="20" src="<?php echo base_url().'assets/theme_admin/img/settings.png'; ?>">
	<span>Setting</span>
	<i class="fa fa-angle-left pull-right"></i>
</a>

<ul class="treeview-menu">          
	<li class="<?php if ($this->uri->segment(1) == 'profil') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>profil"> <i class="fa fa-folder-open-o"></i> Identitas Koperasi </a></li>
	<li class="<?php if ($this->uri->segment(1) == 'suku_bunga') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>suku_bunga"> <i class="fa fa-folder-open-o"></i> Suku Bunga </a></li>
	<li class="<?php if ($this->uri->segment(1) == 'jenis_cabang') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>jenis_cabang"> <i class="fa fa-folder-open-o"></i> Kantor Cabang </a></li>	
	<li class="<?php if ($this->uri->segment(1) == 'user') { echo 'active'; } ?>"><a href="<?php echo base_url(); ?>user"> <i class="fa fa-folder-open-o"></i> Data Pengguna </a></li> 
	<li class="">  <a href="<?php echo base_url(); ?>backup/db"> <i class="fa fa-folder-open-o"></i> Backup Database </a></li>	
	<li class="<?php if ($this->uri->segment(1) == 'restore') { echo 'active'; } ?>">  <a href="<?php echo base_url(); ?>restore"> <i class="fa fa-folder-open-o"></i> Restore Database </a></li>
</ul>
</li>
<?php } ?>

</ul>