<!DOCTYPE html>
<html>
<style type="text/css">
	.first{
		display: block;
	    height: 0.3px;
	    border: 0;
	    border-top: 3px solid #bbdaec;
	    border-bottom: 2px solid #b1e2fa;
	    padding: 0; 
	}
	#content{
		background-image: url("<?= base_url('assets/asset/images/bg1.jpg');?>");
		background-repeat: no-repeat;
  		display: inline-block;f
  		font-family: 'Arial, Helvetica, sans-serif'; 
  		border-radius: 10px;"
	}
</style>
<body>
<div id="content">
<table style=" border: 1px;" width="500px"> 
  <tr>
   	<td colspan="4">
   		<div style="margin-top:10px; margin-left:10px; ">
   			<div style="display: inline-block;"><img src="<?= base_url('assets/asset/images/kop.png')?>" style="width: 90px; height: 90px" cellpadding="0" cellspacing="0"></div>
    		<div style="margin-left: 70px; margin-top: -70px; padding: 3px; margin-bottom: 18px; font-weight: bold; color: white; font-size: 18px"><center>KOPERASI SIMPAN PINJAM<br>Jl. asdfasdf asdfasdf asdfad</center></div>
    	</div>
    </td>
  </tr>
  <tr>
  	<td colspan="4"><hr class="first"></td>
  </tr>
  <tr>
    <td colspan="4"><div style="font-size: 15px; font-style: bold; margin-top: -5px; margin-bottom: 5px; text-align: center;"><b>KARTU TANDA ANGGOTA</b></div></td>
  </tr>
  <tr>
  	<td rowspan="5" valign="top"><div style="margin-left: 10px; margin-right: 10px"><img src="<?= $picture;?>" style="width: 80px; height: 85px"></div></td>
  	<td width="25%"><div style="font-family: Arial, Helvetica, sans-serif">Nama Anggota</div></td>
  	<td>:</td>
  	<td><div style="margin-right:15px"><?= $nama_anggota;?></div></td>
  </tr>
  <tr>
  	<td>TTL</td>
  	<td>:</td>
  	<td><div style="margin-right:15px"><?= $ttl; ?></div></td>
  </tr>
  <tr>
  	<td valign="top">Alamat</td>
  	<td valign="top">:</td>
  	<td><div style="margin-right:15px"><?= $alamat;?></div>	</td>
  </tr>
  <tr>
  	<td>Jabatan</td>
  	<td>:</td>
  	<td><?= $pengurus==1?'Pengurus':'Anggota';?></td>
  </tr>
  <tr>
  	<td colspan="4"><div style="text-align: right;">&nbsp;&nbsp;&nbsp;&nbsp;</div></td>
  </tr>
</table>
</div>
&nbsp;&nbsp;&nbsp;<br>
<a href="<?= base_url('anggota/cetak/'.$id_user);?>" target="_blank">Download</a>

<!-- <div style="background-image: url('bg1.jpg'); background-repeat: no-repeat;
  display: inline-block;font-family: 'Arial, Helvetica, sans-serif'; border-radius: 10px;">
<table style=" border: 1px;"> 
  <tr>
   	<td colspan="4">
   		<div style="margin-top:10px; margin-left:10px; ">
   			<div style="display: inline-block;"><img src="logo.png" style="width: 90px; height: 90px" cellpadding="0" cellspacing="0"></div>
    		<div style="margin-left: 70px; margin-top: -70px; padding: 3px; margin-bottom: 18px; font-weight: bold; color: white; font-size: 18px"><center>KOPERASI SIMPAN PINJAM<br>Jl. asdfasdf asdfasdf asdfad</center></div>
    	</div>
    </td>
  </tr>
  <tr>
  	<td colspan="4"><hr class="first"></td>
  </tr>
  <tr>
    <td colspan="4"><div style="font-size: 15px; font-style: bold; margin-top: -5px; margin-bottom: 5px"><center><b>KARTU TANDA ANGGOTA</b></center></div></td>
  </tr>
  <tr>
  	<td rowspan="5" valign="top"><div style="margin-left: 10px; margin-right: 10px"><img src="1.png" style="width: 80px; height: 85px"></div></td>
  	<td><div style="font-family: Arial, Helvetica, sans-serif">Nama Anggota</div></td>
  	<td>:</td>
  	<td>Faizal Dinar Alfaqih</td>
  </tr>
  <tr>
  	<td>TTL</td>
  	<td>:</td>
  	<td>Jakarta, 19-Januari-2019</td>
  </tr>
  <tr>
  	<td valign="top">Alamat</td>
  	<td valign="top">:</td>
  	<td><div style="margin-right:15px">asdfasd fasf asdfasd faasd fas<br>sadfasdfsdfasd asdfasdfasdf</div>	</td>
  </tr>
  <tr>
  	<td>Jabatan</td>
  	<td>:</td>
  	<td>Pengurus</td>
  </tr>
  <tr>
  	<td colspan="4"><div style="text-align: right;">&nbsp;&nbsp;&nbsp;&nbsp;</div></td>
  </tr>
</table>
</div> -->

</body>
</html>
