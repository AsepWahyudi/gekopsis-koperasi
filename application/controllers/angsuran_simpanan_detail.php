<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Angsuran_simpanan_detail extends OperatorController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('simpanan_m');
		$this->load->model('general_m');
	}	

	public function index($master_id = NULL) {
		if($master_id == NULL) {
			redirect('pinjaman');
			exit();
		}

		$this->data['judul_browser'] = 'Detail Simpanan';
		$this->data['judul_utama'] = 'Detail Simpanan';
		$this->data['judul_sub'] = 'Kode Simpan  TRD' . sprintf('%05d', $master_id) . '';

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
		$this->data['sisa_ags'] = $this->general_m->get_record_bayar_simpanan($master_id);
		$this->data['data_anggota'] = $this->general_m->get_data_anggota ($row_pinjam->anggota_id);
		$this->data['hitung_dibayar'] = $this->general_m->get_jml_bayar_simpanan($master_id);
		$this->data['simulasi_tagihan'] = $this->simpanan_m->get_simulasi_simpanan($master_id);
		$this->data['angsuran'] = $this->simpanan_m->get_data_angsuran($master_id);

		$this->data['isi'] = $this->load->view('angsuran_simpanan_detail_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
}