<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class sewa_kantor extends AdminController {
	public function __construct() {
		parent::__construct();	
	}		
	public function index() {
		$this->data['judul_browser'] = 'Master Data';
		$this->data['judul_utama'] = 'Master Data';
		$this->data['judul_sub'] = 'Sewa Kantor <a href="'.site_url('sewa_kantor/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->output->set_template('gc');

		$this->load->library('grocery_CRUD');
		$crud = new grocery_CRUD();
		$crud->set_table('sewa_kantor');
		$crud->set_subject('Sewa Kantor');
	
		$crud->fields('cabang_id','awal_sewa','akhir_sewa','saldo','jangka_waktu');		
		$crud->required_fields('cabang_id','awal_sewa','akhir_sewa','saldo','jangka_waktu');
        
		$crud->display_as('cabang_id','Cabang');
		$crud->display_as('saldo','Saldo Bayar DiMuka');
		$this->db->_protect_identifiers = FALSE;
        
        $this->db->select('*');
		$this->db->from('jns_cabang');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$result = $query->result();
			foreach ($result as $val) {
				$vcabang[$val->jns_cabangid] = $val->nama_cabang;
			}
		} else {
			$vcabang = array('' => '-');
		}
		$crud->field_type('cabang_id','dropdown',$vcabang);

		$output = $crud->render();

		$out['output'] = $this->data['judul_browser'];
		$this->load->section('judul_browser', 'default_v', $out);
		$out['output'] = $this->data['judul_utama'];
		$this->load->section('judul_utama', 'default_v', $out);
		$out['output'] = $this->data['judul_sub'];
		$this->load->section('judul_sub', 'default_v', $out);
		$out['output'] = $this->data['u_name'];
		$this->load->section('u_name', 'default_v', $out);

		$this->load->view('default_v', $output);
		

	}
	
	//Added
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Sewa Kantor <a href="'.site_url('sewa_kantor').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_sewa_kantor')) {
				$this->data['error'] = $this->upload->display_errors();
			} else {
				// ok uploaded
				$file = $this->upload->data();
				$this->data['file'] = $file;

				$this->data['lokasi_file'] = $file['full_path'];

				$this->load->library('excel');

				// baca excel
				$objPHPExcel = PHPExcel_IOFactory::load($file['full_path']);
				$no_sheet = 1;
				$header = array();
				$data_list_x = array();
				$data_list = array();
				foreach ($objPHPExcel->getWorksheetIterator() as $worksheet) {
					if($no_sheet == 1) { // ambil sheet 1 saja
						$no_sheet++;
						$worksheetTitle = $worksheet->getTitle();
						$highestRow = $worksheet->getHighestRow(); // e.g. 10
						$highestColumn = $worksheet->getHighestColumn(); // e.g 'F'
						$highestColumnIndex = PHPExcel_Cell::columnIndexFromString($highestColumn);

						$nrColumns = ord($highestColumn) - 64;
						//echo "File ".$worksheetTitle." has ";
						//echo $nrColumns . ' columns';
						//echo ' y ' . $highestRow . ' rows.<br />';

						$data_jml_arr = array();
						//echo 'Data: <table width="100%" cellpadding="3" cellspacing="0"><tr>';
						for ($row = 1; $row <= $highestRow; ++$row) {
						   //echo '<tr>';
							for ($col = 0; $col < $highestColumnIndex; ++$col) {
								$cell = $worksheet->getCellByColumnAndRow($col, $row);
								$val = $cell->getValue();
								$kolom = PHPExcel_Cell::stringFromColumnIndex($col);
								if($row === 1) {
									$header[$kolom] = $val;
								} else {
                                    if($kolom == 'B' || $kolom == 'C') {
                                        $val = date('Y-m-d',strtotime($val));
                                    }
									$data_list_x[$row][$kolom] = $val;
								}
							}
						}
					}
				}

				$no = 1;
				foreach ($data_list_x as $data_kolom) {
					if((@$data_kolom['A'] == NULL || trim(@$data_kolom['A'] == '')) ) { continue; }
						foreach ($data_kolom as $kolom => $val) {
							if(in_array($kolom, array('E', 'K', 'L')) ) {
								$val = ltrim($val, "'");
							}
							$data_list[$no][$kolom] = $val;
						}
					
					$no++;
				}

				//$arr_data = array();
				$this->data['header'] = $header;
				$this->data['values'] = $data_list;
			}
		}


		$this->data['isi'] = $this->load->view('sewa_kantor_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			$this->load->model('sewa_kantor_m','sewa_kantor', TRUE);
			$data_import = $this->input->post('val_arr');
			if($this->sewa_kantor->import_db($data_import)) {
				$this->session->set_flashdata('import', 'OK');
			} else {
				$this->session->set_flashdata('import', 'NO');
			}
			//hapus semua file di temp
			$files = glob('uploads/temp/*');
			foreach($files as $file){ 
				if(is_file($file)) {
					@unlink($file);
				}
			}
			redirect('sewa_kantor/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('sewa_kantor/import');
		}
	}

	function import_batal() {
		//hapus semua file di temp
		$files = glob('uploads/temp/*');
		foreach($files as $file){ 
			if(is_file($file)) {
				@unlink($file);
			}
		}
		$this->session->set_flashdata('import', 'BATAL');
		redirect('sewa_kantor/import');
	}
}
