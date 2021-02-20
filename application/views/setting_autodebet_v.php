<div class="row">
	<div class="col-md-12">
		<div class="box box-solid box-primary">
			<div class="box-header">
				<h3 class="box-title">Setting Autodebet</h3>
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
		                    Data berhasil disimpan.
		                </div>
					</div>
				<?php } ?>

				<?php if($tersimpan == 'N') { ?>
					<div class="box-body">
						<div class="alert alert-danger alert-dismissable">
		                    <i class="fa fa-warning"></i>
		                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
		                    Data tidak berhasil disimpan, silahkan ulangi beberapa saat lagi.
		                </div>
					</div>
				<?php } ?>

				<div class="form-group">
					<form action="<?=base_url()?>setting_autodebet" method="post">
						<label for="tgl_tempo_anggota">Tanggal Tempo Anggota</label>
						<input type="text" name="tgl_tempo_anggota" value="<?=$get_auto_debet_setting->row()->tgl_tempo_anggota?>" id="tgl_tempo_anggota" class="form-control" maxlength="255" style="width: 95%">
						<br>
						<label for="tgl_tempo_anggota_luarbiasa">Tanggal Tempo Anggota Luar Biasa</label>
						<input type="text" name="tgl_tempo_anggota_luarbiasa" value="<?=$get_auto_debet_setting->row()->tgl_tempo_anggota_luarbiasa?>" id="tgl_tempo_anggota_luarbiasa" class="form-control" maxlength="255" style="width: 95%">
						<br>
						<label for="kas_id">Nama Kas</label>
						<select name="kas_id" id="kas_id" class="form-control" style="width: 95%">
							<?php
								foreach($get_nama_kas->result() as $row_kas){
									if($row_kas->id == $get_auto_debet_setting->row()->kas_id){
										$selected = 'selected';
									}
									else{
										$selected = '';
									}
							?>
							<option <?=$selected?> value="<?=$row_kas->id?>"><?=$row_kas->nama?></option>
							<?php
								}
							?>
						</select>
						<br>
						
						<button name="submit" type="submit" id="submit" class="btn btn-primary" value="true">Update</button>
					</form>
				</div>
			</div><!-- /.box-body -->
		</div>
	</div>
</div>