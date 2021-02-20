<?php
if(!isset($_SESSION)) { session_start(); } ob_start();
$this->load->helper('cookie');
function destroyCookies($prefix){
  if(isset($_COOKIE)){
    foreach($_COOKIE as $i => $v){
      if(preg_match("/^$prefix/", $i)){
        //setcookie($i, '', time()-(1*24*60*60*1000)); unset($_COOKIE[$i]);
        //echo $i.'<br>';
      	delete_cookie($i);
      }
    }

  }
}
destroyCookies('hidden_sorting_');
ob_end_flush();
?><!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title><?php echo $this->load->get_section('judul_browser');?> - SIFOR KOPJAM</title>
	<link rel="shortcut icon" href="<?php echo base_url(); ?>icon.ico" type="image/x-icon" />
	<meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>

	<?php 
	foreach($css_files as $file): ?>
		<link type="text/css" rel="stylesheet" href="<?php echo $file; ?>" />
	<?php endforeach; ?>

	<!-- bootstrap 3.0.2 -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/bootstrap.min.css" rel="stylesheet" type="text/css" />
	<!-- font Awesome -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/font-awesome.min.css" rel="stylesheet" type="text/css" />
	<!-- Ionicons -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/ionicons.min.css" rel="stylesheet" type="text/css" />

	<!-- Theme style -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/AdminLTE.css" rel="stylesheet" type="text/css" />
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/custome.css" rel="stylesheet" type="text/css" />

	<!-- jQuery 2.0.2 -->
	<script src="<?php echo base_url(); ?>assets/theme_admin/js/jquery.min.js"></script>
	<?php foreach($js_files as $file): ?>
		<script src="<?php echo $file; ?>"></script>
	<?php endforeach; ?>


	<!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
	<!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
	<!--[if lt IE 9]>
	 <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
	 <script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>
	 <![endif]-->
</head>
<body class="skin-blue">
	<!-- header logo: style can be found in header.less -->
	<header class="header">
		<a href="<?php echo site_url();?>" class="logo">
			<!-- Add the class icon to your logo image or logo icon to add the margining -->
			 <div style="text-align:center;"><img height="50" src="<?php echo base_url().'assets/theme_admin/img/tulisan.png'; ?>"></div>
		</a>
		<!-- Header Navbar: style can be found in header.less -->
		<nav class="navbar navbar-static-top" role="navigation">
			<!-- Sidebar toggle button-->
			<a href="#" class="navbar-btn sidebar-toggle" data-toggle="offcanvas" role="button">
				<span class="sr-only">Toggle navigation</span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
			</a>
			<div class="navbar-right">
				<ul class="nav navbar-nav">
					<?php $this->load->view('notifikasi_v'); ?>
					<!-- User Account: style can be found in dropdown.less -->
					<li class="dropdown">
						<a href="#" class="dropdown-toggle" data-toggle="dropdown">
							<i class="glyphicon glyphicon-user"></i>
							<span><?php echo $this->load->get_section('u_name');?> <i class="caret"></i></span>
						</a>
						<ul class="dropdown-menu">
							<li><a href="<?php echo base_url();?>ubah_password"> <i class="fa fa-key"></i>Ubah Password</a></li>
							<li><a href="<?php echo base_url();?>login/logout"> <i class="fa fa-sign-out"></i>Logout</a></li>
						</ul>
					</li>
				</ul>
			</div>
		</nav>
	</header>
	<div class="wrapper row-offcanvas row-offcanvas-left">
		<!-- Left side column. contains the logo and sidebar -->
		<aside class="left-side sidebar-offcanvas">                
			<!-- sidebar: style can be found in sidebar.less -->
			<section class="sidebar">
				<!-- Sidebar user panel -->
				<!-- sidebar menu: : style can be found in sidebar.less -->
				<?php $sub_view['level'] = $this->session->userdata('level'); ?>
				<?php $this->load->view('menu_v', $sub_view); ?>
			</section>
			<!-- /.sidebar -->
		</aside>

		<!-- Right side column. Contains the navbar and content of the page -->
		<aside class="right-side">                
			<!-- Content Header (Page header) -->
			<section class="content-header">
				<h1>
					<?php echo $this->load->get_section('judul_utama');?> 
					<small> <?php echo $this->load->get_section('judul_sub');?> </small>
				</h1>
				<ol class="breadcrumb">
					<li> 
						<i class="fa fa-calendar"></i> <?php echo date('d M Y'); ?> &nbsp; 
						<i class="fa fa-clock-o"></i> <?php echo date('H:i'); ?>
					</li>
				</ol>
			</section>

			<!-- Main content -->
			<section class="content">
				<?php echo $this->load->get_section('sebelum_gc_list');?> 
				<?php echo $output; ?>
				<?php echo $this->load->get_section('setelah_gc_list');?> 
			</section><!-- /.content -->
		</aside><!-- /.right-side -->
	</div><!-- ./wrapper -->



	<!-- Bootstrap -->
	<script src="<?php echo base_url(); ?>assets/theme_admin/js/bootstrap.min.js" type="text/javascript"></script>
	<!-- AdminLTE App -->
	<script src="<?php echo base_url(); ?>assets/theme_admin/js/AdminLTE/app.js" type="text/javascript"></script>

</body>
</html>