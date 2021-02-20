<?php if (!defined('BASEPATH')) exit('No direct script access allowed');

class OperatorController extends MY_Controller
{

	public function __construct() {
		parent::__construct();
		// cek status level admin
		if ($this->session->userdata('level') == 'Admin' || $this->session->userdata('level') == 'Operator') {
			//oke
			$this->data['akses'] = TRUE;
		} else {
			// no
			$this->data['akses'] = FALSE;
			redirect('home/no_akses');
		}
	}   

}