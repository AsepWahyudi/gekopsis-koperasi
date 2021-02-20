<style type="text/css">
	.modal-body { background-color: #fff;}
	.img-rounded { border: 1px solid #ccc !important;}
	.center-block { float: none; }
	td.bs-checkbox {vertical-align: middle !important;}
	.btn {margin-top: 2px; margin-bottom: 2px;}
	.select2-choices {
		min-height: 150px;
		max-height: 150px;
		overflow-y: auto;
	}
</style>

	<div class="row">
		<div class="col-md-12">
			<div class="box box-solid box-primary">
				<div class="box-header">
					<h3 class="box-title">Formulir Pengajuan Pinjaman</h3>
				</div>
				<?php echo form_open(''); ?>
				<div class="box-body">

					<?php if($tersimpan == 'N') { ?>
					<div class="box-body">
						<div class="alert alert-danger alert-dismissable">
							<i class="fa fa-warning"></i>
							<button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
							Pengajuan gagal terkirim, silahkan periksa kembali dan ulangi.
						</div>
					</div>
					<?php } ?>

					<div class="form-group">
						<label for="anggota">Anggota</label>
						<div>
							<select name="anggota" id="anggota" class="form-control" style="width: 250px;">
								<option value="">-- Pilih --</option>
								<?php foreach($list_agt as $agt){ echo "<option value='".$agt->id."'>".$agt->nama."</option>"; } ?>
							</select>
						</div>					
					</div>

					<div class="form-group">
						<label for="anggota">Jenis</label>
						<div>
							<select name="jenis" id="jenis" class="form-control" style="width: 250px;">
								<option value="">-- Pilih --</option>
								<?php foreach($list_pengajuan as $pengajuan){ echo "<option value='".$pengajuan->jenis_pengajuan."|".$pengajuan->fix_angsuran."|".$pengajuan->lama_angsuran."|".$pengajuan->inisial_id."'>".$pengajuan->jenis_pengajuan."</option>"; } ?>
							</select>
						</div>	
					</div>

					<div class="form-group">
						<?php
						$data = array(
							'name'       => 'nominal',
							'id'			=> 'nominal',
							'class'		=> 'form-control',
							'value'      => '',
							'maxlength'  => '255',
							'style'      => 'width: 250px'
							);
						echo form_label('Nominal', 'nominal');
						echo form_input($data);
						echo form_error('nominal', '<p style="color: red;">', '</p>');
						?>
					</div>


					<div class="form-group">
						<?php
						$attr_form = 'lama_ags';
						$attr_form_label = 'Lama Angsuran';
						echo '<label for="'.$attr_form.'">'.$attr_form_label.'</label>
								<div>';
						echo form_dropdown($attr_form, $lama_ags, set_value($attr_form, ''), 'id="'.$attr_form.'" class="form-control" style="width: 100px;" ');
						echo '</div><div id="div_lama_ags"></div>';
						?>
					</div>

					<div class="form-group">
						<?php
						$data = array(
							'name'       => 'keterangan',
							'id'			=> 'keterangan',
							'class'		=> 'form-control',
							'value'      => '',
							'maxlength'  => '255',
							'style'      => 'width: 350px'
							);
						echo form_label('Keterangan', 'keterangan');
						echo form_input($data);
						echo form_error('keterangan', '<p style="color: red;">', '</p>');
						echo '<br>'; ?>
					</div>
					<div class="form-group">
						<div id="div_simulasi"></div>
					</div>

				</div><!-- /.box-body -->
				<div class="box-footer">
					<?php
					// submit
					$data = array(
						'name' 		=> 'submit',
						'id' 		=> 'submit',
						'class' 	=> 'btn btn-primary',
						'value'		=> 'true',
						'type'	 	=> 'submit',
						'content' 	=> 'Kirim Pengajuan'
						);
					echo form_button($data);

					echo form_close();
					?>	
				</div>
				<?php echo form_close(); ?>
			</div><!-- box-primary -->
		</div><!-- col -->
	</div><!-- row -->


<!-- Modal -->
<div id="modal_aksi" class="modal fade" role="dialog">
	<form>
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
		<h4 class="modal-title">Konfirmasi</h4>
	</div>
	<div class="modal-body">
		<p class="modal_hasil">
			
		</p>
		<div id="div_alasan">
			
		</div>
	</div>
	<div class="modal-footer">
		<button type="button" class="btn btn-default" id="link_konfirmasi_batal" data-dismiss="modal">Batal</button>
		<a href="javascript:void(0)" class="btn btn-primary" id="link_konfirmasi">OK</a>
	</div>
	</form>
</div>

<script type="text/javascript">
	$(function() {
		// $('#nominal').on('change keyup paste', function() {
			// var n = parseInt($(this).val().replace(/\D/g, ''), 10);
			// $(this).val(number_format(n, 0, '', '.'));
		// });
		$('#jenis').on('change', function() {
			oc_lama_ags();
		});
		oc_lama_ags();

		$('#jenis, #nominal, #lama_ags').on('change', function() {
			simulasikan();
		});


	});

	function simulasikan() {
		var jenis = $('#jenis').val();
		var splitted = jenis.split("|");
		var jenis_pengajuan = splitted[0];
		var fix_angsuran = splitted[1];
		var lama_angsuran = splitted[2];
		var var_nominal = $('#nominal').val();
		var var_lama_ags = $('#lama_ags').val();
		$.ajax({
			url: '<?php echo site_url('member/simulasi')?>',
			type: 'POST',
			dataType: 'html',
			data: {'nominal': var_nominal, 'lama_ags': var_lama_ags, 'jenis': jenis_pengajuan, 'fix_angsuran': fix_angsuran, 'lama_angsuran': lama_angsuran}
		})
		.done(function(result) {
			$('#div_simulasi').html(result);
			console.log("success");
		})
		.fail(function() {
			console.log("error");
		})
		.always(function() {
			console.log("complete");
		});
	}

	function oc_lama_ags() {
		var jenis = $('#jenis').val();
		var splitted = jenis.split("|");
		var jenis_pengajuan = splitted[0];
		var fix_angsuran = splitted[1];
		var lama_angsuran = splitted[2];

		if(fix_angsuran == 'Y') {
			$('#lama_ags').hide();
			$('#div_lama_ags').html('<input value="'+lama_angsuran+' bln" disabled="disabled" class="form-control" style="width: 35px;">');
			$('#div_lama_ags').show();
		} else {
			$('#div_lama_ags').html('');
			$('#div_lama_ags').hide;
			$('#lama_ags').show();
		}		
	}



</script>