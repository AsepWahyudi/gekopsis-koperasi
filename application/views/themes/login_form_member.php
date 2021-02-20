<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Kasbon</title>
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
        <a href="<?php echo base_url(); ?>" class="scrollto"><img src="<?php echo base_url(); ?>assets/front_end/img/kasbon_menu1.png" alt="" class="img-fluid"></a>
      </div>

      <nav class="main-nav float-right d-none d-lg-block">
        <ul>
		  <li><a href="<?php echo base_url(); ?>admin">Admin</a></li>
		  <li><a href="<?php echo base_url(); ?>member">Member</a></li>
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
        <h2>Member Login</h2>
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

  <!--==========================
    Footer
  ============================-->
  <footer id="footer">
    <div class="footer-top">
      <div class="container">
        <div class="row">

          <div class="col-lg-4 col-md-6 footer-info">
            <h3>KASBON.CO.ID</h3>
            <p>Kasbon.co.id adalah merek dagang dari Koperasi Insan Sejahtera SIMGROUP (KISS).</p>
            <p>Kasbon.co.id dibentuk untuk membantu karyawan menghadapi masalah keuangan mendesak dengan cara mudah dan cepat. kami berusaha memberikan solusi kepada karyawan mendapatkan pinjaman yang murah dan mudah, tanpa berbagai syarat yang memberatkan.</p>
          </div>

          <div class="col-lg-2 col-md-6 footer-links">
            <h4>Useful Links</h4>
            <ul>
              <li><a href="#">Home</a></li>
              <li><a href="#">About us</a></li>
              <li><a href="#">Services</a></li>
              <li><a href="#">Terms of service</a></li>
              <li><a href="#">Privacy policy</a></li>
            </ul>
          </div>

          <div class="col-lg-3 col-md-6 footer-contact">
            <h4>Contact Us</h4>
            <p>
              Wisma SIM <br>
              Jl. Kebagusan Raya No 18<br>
              Pasar Minggu,Jakarta Selatan <br>
              <strong>Phone:</strong> ++62 8131 0000 638<br>
              <strong>Email:</strong> cs@kasbon.co.id<br>
            </p>

            <div class="social-links">
              <a href="#" class="twitter"><i class="fa fa-twitter"></i></a>
              <a href="#" class="facebook"><i class="fa fa-facebook"></i></a>
              <a href="#" class="instagram"><i class="fa fa-instagram"></i></a>
              <a href="#" class="google-plus"><i class="fa fa-google-plus"></i></a>
              <a href="#" class="linkedin"><i class="fa fa-linkedin"></i></a>
            </div>

          </div>

          <div class="col-lg-3 col-md-6 footer-newsletter">
            <h4>Info Terkini</h4>
            <p>Dapatkan informasi dan promo menarik dengan mendaftarkan email kamu untuk berlangganan.</p>
            <form action="" method="post">
              <input type="email" name="email"><input type="submit"  value="Subscribe">
            </form>
          </div>

        </div>
      </div>
    </div>

    <div class="container">
      <div class="copyright">
        &copy; Copyright <strong>Kasbon.co.id</strong>. All Rights Reserved
      </div>
      <div class="credits">
        <!--
          All the links in the footer should remain intact.
          You can delete the links only if you purchased the pro version.
          Licensing information: https://bootstrapmade.com/license/
          Purchase the pro version with working PHP/AJAX contact form: https://bootstrapmade.com/buy/?theme=NewBiz
        -->
        Designed by <a href="https://bootstrapmade.com/">KISS</a>
      </div>
    </div>
  </footer><!-- #footer -->

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
