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
    background-image: url(assets/asset/images/bg1.jpg);
    background-repeat: no-repeat;
      display: inline-block;f
      font-family: Arial, Helvetica, sans-serif; 
      border-radius: 10px;
      width:420px;
  }
  
</style>
<div id="content">
  <table style="" width="300px"> 
      <tr>
        <td colspan="4">
          <div style="margin-top:10px; margin-left:10px; ">
            <div style="display: inline-block;"><img src="assets/asset/images/kop.png" style="width: 90px; height: 90px" cellpadding="0" cellspacing="0"></div>
            <div style="margin-left: 70px; margin-top: -30px; padding: 3px; margin-bottom: 18px; font-weight: bold; color: white; font-size: 18px; text-align:center">KOPERASI SIMPAN PINJAM<br>Jl. asdfasdf asdfasdf asdfad</div>
          </div>
        </td>
      </tr>
      <tr>
        <td colspan="4"><hr class="first"></td>
      </tr>
      <tr>
        <td colspan="4"><div style="font-size: 15px; font-style: bold; margin-top: -5px; text-align:center"><b>KARTU TANDA ANGGOTA</b></div></td>
      </tr>
      <tr>
        <td rowspan="5" valign="top"><div style="margin-left: 10px; margin-right: 10px; margin-top:-30px"><img src="<?=$picture;?>" style="width: 80px; height: 85px"></div></td>
        <td style="width:110px"><div style="font-family: Arial, Helvetica, sans-serif; margin-top:-30px">Nama Anggota</div></td>
        <td><div style=margin-top:-30px;>:</div></td>
        <td><div style="margin-right:15px; margin-top:-30px"><?=$nama_anggota;?></div></td>
      </tr>
      <tr>
        <td> <div style="margin-top:-20px">TTL</div></td>
        <td><div style="margin-top:-20px">:</div></td>
        <td><div style="margin-right:15px; margin-top:-20px"><?=$ttl;?></div></td>
      </tr>
      <tr>
        <td valign="top"><div style="margin-top:-10px">Alamat</div></td>
        <td valign="top"><div style="margin-top:-10px">:</div></td>
        <td style="width:150px"><div style="margin-right:15px; margin-top:-10px;"><?=$alamat;?></div> </td>
    </tr>
    <tr>
        <td><div style="margin-top:-1px;">Jabatan</div></td>
        <td>:</td>
        <td><?=$jabatan;?></td>
      </tr>
    
   </table><br><br>
</div>'