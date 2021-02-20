<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Setting_autodebet extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('autodebet_m');
		
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
		$this->data['tersimpan'] = '';
		$this->load->model('setting_m');
		if ($this->input->post('submit')) {
			$tgl_tempo_anggota = $this->input->post('tgl_tempo_anggota');
			$tgl_tempo_anggota_luarbiasa = $this->input->post('tgl_tempo_anggota_luarbiasa');
			$kas_id = $this->input->post('kas_id');
			
			$data = array('tgl_tempo_anggota' => $tgl_tempo_anggota, 'tgl_tempo_anggota_luarbiasa' => $tgl_tempo_anggota_luarbiasa, 'kas_id' => $kas_id);
			$this->db->where('id', 1);
			
			if($this->db->update('setting_autodebet', $data)) {
				$this->data['tersimpan'] = 'Y';
			} else {
				$this->data['tersimpan'] = 'N';
			}
		}
		$this->data['judul_browser'] = 'Autodebet';
		$this->data['judul_utama'] = 'Autodebet';
		$this->data['judul_sub'] = 'Setting Autodebet';
		$this->data['get_auto_debet_setting'] = $this->autodebet_m->get_auto_debet_setting();
		$this->data['get_nama_kas'] = $this->autodebet_m->get_nama_kas();
		
		$this->data['isi'] = $this->load->view('setting_autodebet_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
}