<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Angsuran_simpanan extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('simpanan_m');
		$this->load->model('general_m');
		$this->load->model('bunga_m');
	}	

	public function index($master_id = NULL) {
		if($master_id == NULL) {
			redirect('bayar');
			exit();
		}

		$this->data['judul_browser'] = 'Bayar Angsuran';
		$this->data['judul_utama'] = 'Bayar Angsuran';
		$this->data['judul_sub'] = 'Kode Pinjam  TPJ' . sprintf('%05d', $master_id) . '';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		//include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';
		
		//include serch tanggal
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		$this->data['master_id'] = $master_id;
		$row_pinjam = $this->general_m->get_data_simpanan ($master_id);
		$this->data['row_pinjam'] = $row_pinjam; 
		$this->data['data_anggota'] = $this->general_m->get_data_anggota ($row_pinjam->anggota_id);
		
		$this->data['hitung_dibayar'] = $this->general_m->get_jml_bayar_simpanan($master_id);
		$this->data['sisa_ags'] = $this->general_m->get_record_bayar_simpanan($master_id);

		$this->data['isi'] = $this->load->view('angsuran_simpanan_list_v', $this->data, TRUE);

		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function ajax_list($id = NULL) {
		if($id == NULL) {
			redirect('bayar');
			exit();
		}
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl_bayar';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 'tgl_dari' => $tgl_dari, 'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->simpanan_m->get_data_transaksi_ajax_detail($offset,$limit,$search,$sort,$order,$id);
		$i	= 0;
		$rows   = array(); 

		foreach ($data['data'] as $r) {
			$tgl_bayar1 = explode(' ', $r->tgl_bayar);
			$txt_tanggal = jin_date_ina($tgl_bayar1[0]);
			$txt_tanggal .= ' - ' . substr($tgl_bayar1[1], 0, 5);	

			$pinjam = $this->general_m->get_data_simpanan($r->simpan_id);
			$anggota = $this->general_m->get_data_anggota($pinjam->anggota_id); 

			// HARI TELAT
			$hari_telat = 0;
			
		
			$tgl_tempo_var = substr($pinjam->tgl_transaksi, 0, 7) . '-01';
			$tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." month"));
			$tgl = substr($pinjam->tgl_transaksi,-11,-9);
			$tgl_tempo = substr($tgl_tempo, 0, 7) . '-' . $tgl;
			
			$tgl_bayar  = substr($r->tgl_bayar, 0, 10);
			
			$txt_tgl_tempo_max = jin_date_ina($tgl_tempo);

			//array keys ini = attribute 'field' di view nya     
			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] ='TBY' . sprintf('%05d', $r->id) . '';
			$rows[$i]['tgl_tempo'] = $txt_tgl_tempo_max;
			$rows[$i]['tgl_bayar'] = $r->tgl_bayar;
			$rows[$i]['tgl_bayar_txt'] = $txt_tanggal;
			$rows[$i]['pinjam_id'] = $r->simpan_id;
			$rows[$i]['angsuran_ke'] = $r->angsuran_ke;
			$rows[$i]['jumlah_bayar'] = number_format(nsi_round($r->jumlah_bayar));
			$rows[$i]['ket'] = $r->keterangan;
			$rows[$i]['user'] = $r->username;
			$rows[$i]['nota'] = '<p></p><p>
			<a href="'.site_url('cetak_angsuran').'/cetak/' . $r->id . '"  title="Cetak Bukti Transaksi" target="_blank"> <i class="glyphicon glyphicon-print"></i> Nota </a></p>';
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	public function create(){
		if(!isset($_POST)) {
			show_404();
		}
		if($this->simpanan_m->create_angsuran()){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data tidak dapat disimpan </div>'));
		}
		exit();
	}


	public function update($id=null) {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->simpanan_m->update_angsuran($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil diubah </div>'));
		}	else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>Maaf, Data gagal diubah </div>'));
		}
	}

	public function delete() {
		if(!isset($_POST)) {
			show_404();
		}
		$id = $this->input->post('id');
		$master_id = $this->input->post('master_id');
		if($this->simpanan_m->delete_angsuran($id, $master_id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Anda harus hapus data sebelumnya </div>'));
		}
	}
	
	function get_ags_ke($master_id) {
		$id_bayar = $this->input->post('id_bayar');
		if($id_bayar > 0) {
			$data_bayar = $this->simpanan_m->get_data_pembayaran_by_id($id_bayar);
			if($data_bayar) {
				$ags_ke = $data_bayar->angsuran_ke;
			} else {
				$ags_ke = 1;
			}
		} else {
			$ags_ke = $this->general_m->get_record_bayar_simpanan($master_id) + 1;
		}

		// -- bayar angsuran --
		$row_pinjam = $this->general_m->get_data_simpanan($master_id); #data pinjam
		$lama_ags = $row_pinjam->tenor; # lama angsuran
		$status_lunas = $row_pinjam->lunas; # status lunas
		$sisa_ags = $lama_ags  - $ags_ke; #sisa angsuran 
		$jml_pinjaman = $row_pinjam->tenor  * $row_pinjam->pokok_angsuran; #jml pinjaman

		//hitung sudah dibayar
		$dibayar=$this->general_m->get_jml_bayar_simpanan($master_id);
		$sudah_bayar= $dibayar->total * 1;

		//total harus bayar 
		$total_bayar = $jml_pinjaman;

		$sisa_tagihan = number_format(nsi_round($row_pinjam->pokok_angsuran * $sisa_ags)); #sisa tagihan 
		$sisa= $row_pinjam->pokok_angsuran * $sisa_ags; #sisa tagihan 

		//sisa pembayaran
		$sisa_pembayaran = $sisa;

		//--- update angsuran --
		$sisa_ags_det = $row_pinjam->tenor - ($ags_ke - 1) ;
		$sudah_bayar_det = number_format(nsi_round($dibayar ->total));

		// validasi lunas
		$sisa_tagihan_num = ($jml_pinjaman - $sudah_bayar);
		if($sisa_tagihan_num <= 0){
			$sisa_tagihan_num=0;
		}else{
			$sisa_tagihan_num=$sisa_tagihan_num;
		}


		$sisa_tagihan_det = number_format(nsi_round($sisa_tagihan_num));
		$total_bayar_det = number_format(nsi_round($sisa_tagihan_num));
		$total_tagihan = number_format(nsi_round($sisa_tagihan_num));

		
		if($ags_ke > $lama_ags) {
			$data = array(
				'ags_ke' 				=> 0,
				'sisa_ags' 				=> $sisa_ags,
				'sisa_tagihan'			=> $sisa_tagihan,
				'sisa_pembayaran' 	=> $sisa_pembayaran,

				'sisa_ags_det' 		=> $sisa_ags_det,
				'sudah_bayar_det' 	=> $sudah_bayar_det,
				'sisa_tagihan_det'	=> $sisa_tagihan_det,
				'total_bayar_det' 	=> $total_bayar_det,

				'status_lunas' 		=> $status_lunas,
				'total_tagihan' 		=> $total_tagihan
			);
			echo json_encode($data);		
		} else {
			$data = array(
				'ags_ke' 				=> $ags_ke,
				'sisa_ags' 				=> $sisa_ags,
				'sisa_tagihan'			=> $sisa_tagihan,
				'sisa_pembayaran' 	=> $sisa_pembayaran,

				'sisa_ags_det' 		=> $sisa_ags_det,
				'sudah_bayar_det' 	=> $sudah_bayar_det,
				'sisa_tagihan_det'	=> $sisa_tagihan_det,
				'total_bayar_det' 	=> $total_bayar_det,

				'status_lunas' 		=> $status_lunas,
				'total_tagihan' 		=> $total_tagihan
				);
			echo json_encode($data);
		}
		exit();
	}
}