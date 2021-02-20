<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Restore extends MY_Controller {
	
	function index(){
		$this->data['judul_browser'] = 'Restore Database';
		$this->data['judul_utama'] = 'Setting';
		$this->data['judul_sub'] = 'Restore Database';

		$this->load->helper(array('form'));
		
		if($this->input->post('submit')) {
			$this->load->model('Backup_m','backup', TRUE);	
			
			$this->backup->delete_constraint();
			
			$tables=$this->backup->select_views()->result_array();    
			foreach($tables as $key => $val) {
				$this->backup->drop_views($val['Tables_in_nsi_koperasi']);
			}
			
			$this->load->helper('file');
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types']="jpg|png|gif|jpeg|bmp|sql|x-sql";
			$this->load->library('upload',$config);
			$this->upload->initialize($config);

			if(!$this->upload->do_upload("datafile")){
				$error = array('error' => $this->upload->display_errors());
				echo "GAGAL UPLOAD";
				var_dump($error);
				exit();
			}

			$file = $this->upload->data();  //DIUPLOAD DULU KE DIREKTORI assets/database/
			$fotoupload=$file['file_name'];
						
			$isi_file = file_get_contents(FCPATH . 'uploads/temp/' . $fotoupload); //PANGGIL FILE YANG TERUPLOAD
			$string_query = rtrim( $isi_file, "\n;" );
			$array_query = explode(";", $string_query);   //JALANKAN QUERY MERESTORE KEDATABASE
			foreach($array_query as $query)
			{
				$this->db->query($query);
			}

			$path_to_file = FCPATH . 'uploads/temp/' . $fotoupload;
			if(unlink($path_to_file)) {   // HAPUS FILE YANG TERUPLOAD
				 redirect('home');
			}
			else {
				 echo 'errors occured';
			}
		}

		$this->data['isi'] = $this->load->view('restore_dabatabase_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
}
