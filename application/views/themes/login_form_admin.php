<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Koperasi Gilang Gemilang</title>
  <meta content="width=device-width, initial-scale=1.0" name="viewport">
  <meta content="" name="keywords">
  <meta content="" name="description">

  <!-- Favicons -->
  <link href="img/favicon.png" rel="icon">
  <link href="img/apple-touch-icon.png" rel="apple-touch-icon">

  <!-- Google Fonts -->
  <link href="https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,700,700i|Montserrat:300,400,500,700" rel="stylesheet">

  <!-- Bootstrap CSS File -->
  <link href="<?php echo base_url(); ?>assets/front_end/lib/bootstrap/css/bootstrap.min.css" rel="stylesheet">

  <!-- Libraries CSS Files -->
  <link href="<?php echo base_url(); ?>assets/front_end/lib/font-awesome/css/font-awesome.min.css" rel="stylesheet">
  <link href="<?php echo base_url(); ?>assets/front_end/lib/animate/animate.min.css" rel="stylesheet">
  <link href="<?php echo base_url(); ?>assets/front_end/lib/ionicons/css/ionicons.min.css" rel="stylesheet">
  <link href="<?php echo base_url(); ?>assets/front_end/lib/owlcarousel/assets/owl.carousel.min.css" rel="stylesheet">
  <link href="<?php echo base_url(); ?>assets/front_end/lib/lightbox/css/lightbox.min.css" rel="stylesheet">

  <!-- Main Stylesheet File -->
  <link href="<?php echo base_url(); ?>assets/front_end/css/style.css" rel="stylesheet">

  <!-- =======================================================
    Theme Name: NewBiz
    Theme URL: https://bootstrapmade.com/newbiz-bootstrap-business-template/
    Author: BootstrapMade.com
    License: https://bootstrapmade.com/license/
  ======================================================= -->
</head>

<body>

  <!--==========================
  Header
  ============================-->
  <header id="header" class="fixed-top">
    <div class="container">

      <div class="logo float-left">
        <!-- Uncomment below if you prefer to use an image logo -->
        <!-- <h1 class="text-light"><a href="#header"><span>NewBiz</span></a></h1> -->
      </div>

      <nav class="main-nav float-right d-none d-lg-block">
        <ul>
		  <li><a href="<?php echo base_url(); ?>admin">Admin</a></li>
        </ul>
      </nav><!-- .main-nav -->
    </div>
  </header><!-- #header -->

  <!--==========================
    Intro Section
  ============================-->
  <section id="intro" class="clearfix">
    <div class="container">

      <div class="intro-img">
        <img src="<?php echo base_url(); ?>assets/front_end/img/intro-img.svg" alt="" class="img-fluid">
      </div>

      <div class="intro-info">
        <h2>System Login</h2>
		<div class="form-box" id="login-box" style="width:300px;" align="center">
				
			<form action="" method="post">
				<div class="body bg-gray">
					
					<?php 
					if (!empty($pesan)) {
						echo '<div style="color: red;">' . $pesan . '</div>';
					}
					?>
					<div class="form-group">
						<input type="text" name="u_name" id="u_name" class="form-control" placeholder="Username" value="<?php echo set_value('u_name');?>" />
						<?php echo form_error('u_name', '<p style="color: red;">', '</p>');?>
					</div>
					<div class="form-group">
						<input type="password" name="pass_word" class="form-control" placeholder="Password" />
						<?php echo form_error('pass_word', '<p style="color: red;">', '</p>');?>
					</div> 
					<button type="submit" class="btn btn-primary btn-block">Login</button>
					
				</div>
				
			</form>
		</div>
			
       
      </div>

    </div>
  </section><!-- #intro -->

  <a href="#" class="back-to-top"><i class="fa fa-chevron-up"></i></a>
  <!-- Uncomment below i you want to use a preloader -->
  <!-- <div id="preloader"></div> -->

  <!-- JavaScript Libraries -->
  <script src="<?php echo base_url(); ?>assets/front_end/lib/jquery/jquery.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/jquery/jquery-migrate.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/bootstrap/js/bootstrap.bundle.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/easing/easing.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/mobile-nav/mobile-nav.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/wow/wow.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/waypoints/waypoints.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/counterup/counterup.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/owlcarousel/owl.carousel.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/isotope/isotope.pkgd.min.js"></script>
  <script src="<?php echo base_url(); ?>assets/front_end/lib/lightbox/js/lightbox.min.js"></script>
  <!-- Contact Form JavaScript File -->
  <script src="<?php echo base_url(); ?>assets/front_end/contactform/contactform.js"></script>

  <!-- Template Main Javascript File -->
  <script src="<?php echo base_url(); ?>assets/front_end/js/main.js"></script>

</body>
</html>
