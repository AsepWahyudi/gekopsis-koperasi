<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Login-SIFOR KOPJAM</title>
	<link rel="shortcut icon" href="<?php echo base_url(); ?>icon.ico" type="image/x-icon" />
	<meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
	<!-- bootstrap 3.0.2 -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/bootstrap.min.css" rel="stylesheet" type="text/css" />
	<!-- font Awesome -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/font-awesome.min.css" rel="stylesheet" type="text/css" />
	<!-- Theme style -->
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/AdminLTE.css" rel="stylesheet" type="text/css" />
	<link href="<?php echo base_url(); ?>assets/theme_admin/css/custome.css" rel="stylesheet" type="text/css" />

	<!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
	<!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
	<!--[if lt IE 9]>
	<script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
	<script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>
	<![endif]-->
</head>
<body>
	<br><br>
	
	<p align="center">
		
	</p>
	<div class="form-box" id="login-box">
		<div class="header"><img height='60' src="<?php echo base_url().'assets/theme_admin/img/tulisan.png'; ?>"></div>
		 
			<div class="body bg-gray" style="text-align: center;">
				<h4>Selahkan pilih jenis login</h4>
			</p>
		</p>
				<div style="margin-top: 20px"></div>
				<a href="<?php echo site_url('admin'); ?>"
					<button type="submit" class="btn btn-primary btn-block">Admin</button>
				</a>
				<a href="<?php echo site_url('member'); ?>"
					<button type="submit" class="btn btn-primary btn-block">Member</button>
				</a>
				
			</div>
			<div class="footer"> 
				&copy; Copyright <?php echo date('Y'); ?> | Developed by NSI. 
			</div>
		 
	</div>

	<!-- jQuery 2.0.2 -->
	<script src="<?php echo base_url(); ?>assets/theme_admin/js/jquery.min.js"></script>
	<!-- Bootstrap -->
	<script src="<?php echo base_url(); ?>assets/theme_admin/js/bootstrap.min.js" type="text/javascript"></script>


<script type="text/javascript">
	$(document).ready(function() {
		$('#u_name').focus();
	});
</script>

</body>
</html>