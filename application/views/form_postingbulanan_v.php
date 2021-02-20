
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

<?php
	if(isset($_GET['periode']) && $_GET['periode'] != "") {
		$tanggal = $_GET['periode']; 
	} else {
		$tanggal = "";
	}
		
		//if(is_array($txt_periode_arr)) {
		if(isset($tanggal) && $tanggal != "") {
			$txt_periode_arr = explode('-', $tanggal);
			$txt_periode = jin_nama_bulan($txt_periode_arr[1]) . ' ' . $txt_periode_arr[0];

			$temp_month = date("F", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
			$temp_year =date("Y", strtotime($txt_periode_arr[0].'-'.$txt_periode_arr[1].'-'.'01'));
		} else {
			$txt_periode =" ";
		}

?>
<div class="row">
	<div class="col-md-12">
		<div class="box box-solid box-primary">
			<div class="box-header">
				<h3 class="box-title">Posting Bulanan</h3>
				<div class="box-tools pull-right">
					<button class="btn btn-primary btn-sm" data-widget="collapse"><i class="fa fa-minus"></i></button>
				</div>
			</div>
			<div class="box-body">
					
				<?php if($tersimpan == 'Y') { ?>
					<div class="box-body">
						<div class="alert alert-success alert-dismissable">
		                    <i class="fa fa-check"></i>
		                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
                            Posting berhasil disimpan. <br>
                            <?php echo $this->session->flashdata('success'); ?>      
		                </div>
					</div>
				<?php } ?>

				<?php if($tersimpan == 'N') { ?>
					<div class="box-body">
						<div class="alert alert-danger alert-dismissable">
		                    <i class="fa fa-warning"></i>
		                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
                           <?php echo $this->session->flashdata('error'); ?>  
                           <br>Posting tidak berhasil disimpan. <br>
		                </div>
					</div>
				<?php } ?>

				<div class="form-group">
					<?php 
					echo form_open('');
					echo '<br>';
					?>
					<table>
						<tr>
							<td>
								<div class="input-group date dtpicker col-md-5" data-date="<?php echo $tanggal; ?>">
									<input id="txt_periode" style="width: 125px; text-align: center;" class="form-control" type="text" value="<?php echo $txt_periode;?>" />
									<div class="input-group-addon"><i class="fa fa-calendar"></i></div>
								</div>
								<input type="hidden" name="periode" id="periode" value="<?php echo $tanggal; ?>" />
							</td>
						</tr>
						<tr>
							<td><input name="submit" type="submit" class="btn btn-primary" value="Posting" /></td>
						</tr>
					</table>
					<?php echo form_close(); ?>
				</div>
			</div><!-- /.box-body -->
		</div>
	</div>
</div>

<script type="text/javascript">
$(document).ready(function() {
	
	$(".dtpicker").datetimepicker({
		language:  'id',
		weekStart: 1,
		autoclose: true,
		todayBtn: true,
		todayHighlight: true,
		pickerPosition: 'bottom-right',
		format: "MM yyyy",
		linkField: "periode",
		linkFormat: "yyyy-mm",
		startView: 3,
		minView: 3
	}).on('changeDate', function(ev){
		//doSearch();
	});

	<?php 
		if(isset($_GET['periode']) && $_GET['periode'] != "") {
			echo 'var periode = "'.$_GET['periode'].'";';
		} else {
			echo 'var periode = "";';
		}
		echo '$("#periode").val(periode);';
	?>

}); // ready

</script>