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
		<div class="box box-primary">
			<div class="box-body" style="min-height: 500px;">
				<div>
					<p style="text-align:center; font-size: 15pt; font-weight: bold;"> Autodebet </p>
				</div>

				<div id="tb" style="text-align:center;">
					<?php
						$tgl_tempo_anggota = $get_auto_debet_setting->row()->tgl_tempo_anggota;
						$tgl_tempo_anggota_luarbiasa = $get_auto_debet_setting->row()->tgl_tempo_anggota_luarbiasa;
						$date_only_str = substr($current_date,8);
						$date_only = (int)$date_only_str;
					?>
					<div style="vertical-align: middle; display: inline; padding-top: 15px;">
						<a onclick="proses_autodebet()" href="#" class="easyui-linkbutton" iconCls="icon-add" plain="true" style="background: #3c8dbc; padding: 7px 15px; color: #fff;"> Proses Autodebet</a>
					</div>
					<!--
					<div style="vertical-align: middle; display: inline; padding-top: 15px;">
						<?php
							if($date_only == $tgl_tempo_anggota_luarbiasa){
						?>
						<a href="<?=base_url()?>proses_autodebet/proses/2" class="easyui-linkbutton" iconCls="icon-add" plain="true" style="background: #3c8dbc; padding: 7px 15px; color: #fff;"> Autodebet Anggota Luar Biasa</a>
						<?php
							}else{
						?>
							<a href="#" class="easyui-linkbutton" iconCls="icon-add" plain="true" onclick="bukanWaktu('<?=$tgl_tempo_anggota_luarbiasa?>')" style="background: #717475; padding: 7px 15px; color: #fff;"> Autodebet Anggota Luar Biasa</a>
						<?php
							}
						?>
					</div>
					-->
					<div class="box-body">
						<div class="alert alert-success alert-dismissable">
							<?php
								if($last_autodebet_anggota->num_rows() == 0){
									$tgl_last_autodebet_anggota = '-';
									$username_anggota = '-';
								}
								else{
									$tgl_last_autodebet_anggota = $last_autodebet_anggota->row()->tgl_autodebet;
									$username_anggota = $last_autodebet_anggota->row()->username;
								}
								
								if($last_autodebet_anggota_luarbiasa->num_rows() == 0){
									$tgl_last_autodebet_anggota_luarbiasa = '-';
									$username_anggota_lb = '-';
								}
								else{
									$tgl_last_autodebet_anggota_luarbiasa = $last_autodebet_anggota_luarbiasa->row()->tgl_autodebet;
									$username_anggota_lb = $last_autodebet_anggota_luarbiasa->row()->username;
								}
							?>
		                    <i class="fa fa-check"></i>
		                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
		                    Riwayat Auto Debet <strong><?=$tgl_last_autodebet_anggota?></strong> tanggal oleh <strong><?=$username_anggota?></strong> <br>
							<!--Anggota pada tanggal pada <strong><?=$tgl_last_autodebet_anggota?></strong> tanggal oleh  <strong><?=$username_anggota?></strong> <br>-->
							<!--Anggota Luar Biasa  pada <strong><?=$tgl_last_autodebet_anggota_luarbiasa?></strong> tanggal oleh <strong><?=$username_anggota_lb?></strong>-->
		                </div>
					</div>
				</div>
			</div>
		</div>
	</div>
	
<script>
	function bukanWaktu(tgl){
		var pesan = 'Tidak dapat melakukan auto debet, tanggal autodebet jatuh pada tanggal '+tgl+'!';
		alert(pesan);
	}
	
	function proses_autodebet(){
		var check=confirm("Proses autodebet tidak dapat dicancel. Apakah Anda yakin untuk memproses autodebet?");
		if(check){
			window.location.href = "<?=base_url()?>proses_autodebet/proses/";
		}
	}
</script>