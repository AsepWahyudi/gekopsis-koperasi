<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Guest extends MY_Controller {

	public function __construct() {
		parent::__construct();
		 
	}	
	
	public function index() {
		
		$this->load->view('front_themes/home', '');
	}


}
