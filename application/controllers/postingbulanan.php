<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Postingbulanan extends AdminController {

	public function __construct() {
		parent::__construct();	
	}	
	
	public function index() {
		$this->data['judul_browser'] = 'Posting Bulanan';
		$this->data['judul_utama'] = 'Transaksi Keuangan';
		$this->data['judul_sub'] = 'Posting Bulanan';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

			#include seach
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		$this->load->helper('form');
    $out = array ();
    $out['tersimpan'] = '';
      
		$this->load->model('postingbulanan_m');
		if ($this->input->post('submit')) {
			if($this->postingbulanan_m->posting()) {
				$out['tersimpan'] = 'Y';
			} else {
        $out['tersimpan'] = 'N';
			}
		}

		$this->data['isi'] = $this->load->view('form_postingbulanan_v', $out, TRUE);

		$this->load->view('themes/layout_utama_v', $this->data);
	}
}
