<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Admin extends CI_Controller {

	public $data = array ('pesan' => '');
	
	public function __construct () {
		parent::__construct();
		$this->load->helper('form');
		$this->load->library('form_validation');
		$this->load->model('Login_m','login', TRUE);
	}
	
	public function index() {
		// status user login = BENAR, pindah ke halaman home
		if ($this->session->userdata('login') == TRUE && $this->session->userdata('level') == 'admin') {
			redirect('home');
		} else {
			// status login salah, tampilkan form login
			// validasi sukses
			if($this->login->validasi()) {
				// cek di database sukses
				if($this->login->cek_user()) {
					redirect('home');
					
				} else {
					// cek database gagal
					$this->data['pesan'] = 'Username atau Password salah.';
				}
			} else {
				// validasi gagal
         }
         $this->data['jenis'] = 'admin';
         $this->load->view('themes/login_form_admin', $this->data);
		 
		}
	}

	public function logout() {
		$this->login->logout();
		redirect('admin');
	}
}