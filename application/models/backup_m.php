<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Backup_m extends CI_Model {
		public function __construct(){
		parent::__construct();
	}

	function truncate_session() {
		$this->db->truncate('ci_sessions'); 
	}
	
	// function empty_table($table_name) {
		// $query = $this->db->query("SET FOREIGN_KEY_CHECKS = 0;");
		// return $query;
	// }
	
	function delete_constraint() {
		$query = $this->db->query("SET FOREIGN_KEY_CHECKS = 0;");
		return $query;
	}
	
	function select_views() {
		$query = $this->db->query("SHOW FULL TABLES WHERE TABLE_TYPE LIKE 'VIEW';");
		return $query;
	}
	
}