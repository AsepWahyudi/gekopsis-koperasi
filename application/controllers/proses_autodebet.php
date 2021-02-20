<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Proses_autodebet extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('autodebet_m');
		$this->load->model('general_m');
		
		//======================= Date & Time =======================//
		date_default_timezone_set("Asia/Jakarta");
        $time = time();
        // Initialize
        $datestring = "%Y-%m-%d";
        $timestring = "%H:%i";
        $datetimestring = "%Y-%m-%d %H:%i:%s";
		$year = "%Y";
		$month = "%m";
		$day = "%d";
        // DateOnly
        $this->current_date = mdate($datestring, $time);
        // YearOnly
		$this->current_year = mdate($year, $time);
        // MonthOnly
		$this->current_month = mdate($month, $time);
        // DayOnly
		$this->current_day = mdate($day, $time);
        // TimeOnly
        $this->current_time = mdate($timestring, $time);
        // DateTime
        $this->current_datetime = mdate($datetimestring, $time);
	}	

	public function index() {
		$this->data['judul_browser'] = 'Autodebet';
		$this->data['judul_utama'] = 'Autodebet';
		$this->data['judul_sub'] = 'Proses Autodebet';
		$this->data['get_auto_debet_setting'] = $this->autodebet_m->get_auto_debet_setting();
		$this->data['last_autodebet_anggota'] = $this->autodebet_m->last_autodebet_anggota();
		$this->data['last_autodebet_anggota_luarbiasa'] = $this->autodebet_m->last_autodebet_anggota_luarbiasa();
		$this->data['current_date'] = $this->current_date;
		$this->data['isi'] = $this->load->view('proses_autodebet_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function proses(){
		$status_anggota = $this->uri->segment(3);
		// $status_anggota = 1;
		// echo $status_anggota;
		// exit();
		// Proses Autodebet Pinjaman
			$get_data_pinjam = $this->autodebet_m->get_data_pinjam($status_anggota);
			$get_auto_debet_setting = $this->autodebet_m->get_auto_debet_setting()->row();
			foreach($get_data_pinjam->result() as $row_pinjam){
				$ags_ke = $this->general_m->get_record_bayar($row_pinjam->id) + 1;
				
				$lama_ags = $row_pinjam->lama_angsuran; # lama angsuran
				$status_lunas = $row_pinjam->lunas; # status lunas
				$sisa_ags = $lama_ags  - $ags_ke; #sisa angsuran 
				$jml_pinjaman = $row_pinjam->lama_angsuran  * $row_pinjam->ags_per_bulan; #jml pinjaman

				//hitung denda
				$denda = $this->general_m->get_jml_denda($row_pinjam->id);
				$jml_denda_num = $denda->total_denda * 1;
				
				//hitung sudah dibayar
				$dibayar=$this->general_m->get_jml_bayar($row_pinjam->id);
				$sudah_bayar= $dibayar->total * 1;

				//total harus bayar 
				$total_bayar = $jml_pinjaman + $jml_denda_num;

				$sisa_tagihan = number_format(nsi_round($row_pinjam->ags_per_bulan * $sisa_ags)); #sisa tagihan 
				$sisa= $row_pinjam->ags_per_bulan * $sisa_ags; #sisa tagihan 

				//sisa pembayaran
				$sisa_pembayaran = $sisa + $jml_denda_num ;
				
				
				// DENDA
				$denda = 0;
				$denda_semua = 0;
				$denda_semua_num = 0;
				$tgl_pinjam = substr($row_pinjam->tgl_pinjam, 0, 7) . '-01';
				$tgl_tempo = date('Y-m-d', strtotime("+".$ags_ke." months", strtotime($tgl_pinjam)));
				$tgl_bayar  = isset($_POST['tgl_bayar']) ? $_POST['tgl_bayar'] : '';
				if($tgl_bayar != '') {
					$data_bunga_arr = $this->bunga_m->get_key_val();
					$denda_hari = $data_bunga_arr['denda_hari'];
					$tgl_tempo = str_replace('-', '', $tgl_tempo);
					$tgl_bayar = str_replace('-', '', $tgl_bayar);
					$tgl_toleransi = $tgl_bayar - ($tgl_tempo - 1);
					if ( $tgl_toleransi > $denda_hari ) { 
						$denda = '' . number_format($data_bunga_arr['denda']);
					}
				}
				
				$jumlah = str_replace(',', '', $sisa_pembayaran) * 1;
				$denda= str_replace(',', '', $denda)*1;
				$jumlah_bayar = $jumlah + $denda;
				echo "tgl_bayar : $this->current_datetime| pinjam_id : $row_pinjam->id| angsuran_ke : $ags_ke | jumlah_bayar: $row_pinjam->ags_per_bulan | denda_rp: $denda| ket_bayar: Angsuran| kas_id: $get_auto_debet_setting->kas_id| jns_trans: 48| keterangan: auto_debet_system| user_name : ".$this->data['u_name']."  - $jumlah_bayar<br>";
				
				$data = array(			
								'tgl_bayar'		=>	$this->current_datetime,
								'pinjam_id'		=>	$row_pinjam->id,
								'angsuran_ke'	=>	$ags_ke,
								'jumlah_bayar'	=>	$row_pinjam->ags_per_bulan,
								'denda_rp'		=>	$denda,
								'ket_bayar'		=>	'Angsuran',
								'kas_id'			=>	$get_auto_debet_setting->kas_id,
								'jns_trans'		=>	'48',
								'keterangan'	=>	'auto_debet_system',
								'user_name'		=> $this->data['u_name']
								);
				
				$this->db->insert('tbl_pinjaman_d', $data);

				if($jumlah_bayar == 0) {
					$status = 'Lunas';} 
					else {
					$status = 'Belum';}
				$data = array('lunas' => $status);
				$this->db->where('id', $row_pinjam->id);
				$this->db->update('tbl_pinjaman_h', $data);
			}
		
		// Proses Autodebet Simpanan
		$get_data_simpan = $this->autodebet_m->get_data_simpan($status_anggota);
		foreach($get_data_simpan->result() as $row_simpan){
			echo "<br> tgl_bayar : $this->current_datetime| simpan_id : $row_simpan->id | angsuran_ke :  $row_simpan->angsuran_ke| jumlah_bayar : $row_simpan->angsuran_per_bulan";
			
			$data = array(			
							'tgl_bayar'		=>	$this->current_datetime,
							'simpan_id'		=>	$row_simpan->id,
							'angsuran_ke'	=>	$row_simpan->angsuran_ke,
							'jumlah_bayar'	=>	$row_simpan->angsuran_per_bulan,
							'keterangan'	=>	'auto_debet_system',
							'username'		=> $this->data['u_name']
							);
			
			$this->db->insert('tbl_trans_sp_d', $data);

			if($row_simpan->angsuran_ke == $row_simpan->tenor){
				$status = 'Lunas';
				$data = array(			
								'tgl_transaksi'		=>	$this->current_datetime,
								'anggota_id'		=>	$row_simpan->anggota_id,
								'anggota_nama'	=>	$row_simpan->anggota_nama,
								'jenis_id'	=>	$row_simpan->jenis_id,
								'tenor'	=>	$row_simpan->tenor,
								'jumlah'	=>	$row_simpan->jumlah,
								'bunga'	=>	$row_simpan->bunga,
								'keterangan'	=>	$row_simpan->keterangan,
								'lunas'	=>	'Belum',
								'akun'	=>	$row_simpan->akun,
								'dk'	=>	$row_simpan->dk,
								'kas_id'	=>	$row_simpan->kas_id,
								'update_data'	=>	$row_simpan->update_data,
								'user_name'	=>	$this->data['u_name'],
								'nama_penyetor'	=>	$row_simpan->nama_penyetor,
								'no_identitas'	=>	$row_simpan->no_identitas,
								'alamat'	=>	$row_simpan->alamat,
								'buat_ulang'	=>	'Y'
								);
				
				$this->db->insert('tbl_trans_sp', $data);
				$buat_ulang = 'N';
			} 
			else {
				$status = 'Belum';
				$buat_ulang = 'Y';
			}
			$data = array('lunas' => $status, 'buat_ulang' => $buat_ulang);
			$this->db->where('id', $row_simpan->id);
			$this->db->update('tbl_trans_sp', $data);
		}
		
		// echo $get_data_simpan->num_rows();
		// echo $get_data_pinjam->num_rows();
		// if()
		$data = array(			
					'tgl_autodebet'		=>	$this->current_datetime,
					'status_anggota'		=>	$status_anggota,
					'username'		=> $this->data['u_name']
					);
		
		$this->db->insert('history_autodebet', $data);
		
		redirect('proses_autodebet');
	}
}
