<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class jenis_cabang extends AdminController {
	public function __construct() {
		parent::__construct();	
	}		
	public function index() {
		$this->data['judul_browser'] = 'Cabang';
		$this->data['judul_utama'] = 'Cabang';
		$this->data['judul_sub'] = 'Cabang <a href="'.site_url('jenis_cabang/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->output->set_template('gc');

		$this->load->library('grocery_CRUD');
		$crud = new grocery_CRUD();
		$crud->set_table('jns_cabang');
		$crud->set_subject('Cabang');
	
		$crud->fields('kode_cabang','nama_cabang', 'alamat_cabang');		
		$crud->required_fields('kode_cabang','nama_cabang', 'alamat_cabang');
		
		$this->db->_protect_identifiers = FALSE;
		$crud->unset_read();
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
		$this->data['judul_sub'] = 'Cabang <a href="'.site_url('jenis_cabang').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_data_cabang')) {
				$this->data['error'] = $this->upload->display_errors();
			} else {
				// ok uploaded
				$file = $this->upload->data();
				$this->data['file'] = $file;
				$this->data['lokasi_file'] = $file['full_path'];
				$this->load->library('excel');

				// baca excel
				$objPHPExcel = PHPExcel_IOFactory::load($file['full_path']);
				//$objPHPExcel = PHPExcel_IOFactory::createWriter($objPHPExcel, 'Excel2007');
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
						//var_dump($highestColumn);die();
						$data_jml_arr = array();
						for ($row = 1; $row <= $highestRow; ++$row) {
							for ($col = 0; $col < $highestColumnIndex; ++$col) {
								$cell = $worksheet->getCellByColumnAndRow($col, $row);
								$val = $cell->getValue();
								$kolom = PHPExcel_Cell::stringFromColumnIndex($col);
								if($row === 1) {
									if($kolom == 'A') {
										$header[$kolom] = 'Nama';
									} else {
										$header[$kolom] = $val;
									}
								} else {
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
				/*
				$data_import = array(
					'import_anggota_header'		=> $header,
					'import_anggota_values' 	=> $data_list
					);
				$this->session->set_userdata($data_import);
				*/
			}
		}


		$this->data['isi'] = $this->load->view('jenis_cabang_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			$this->load->model('jenis_cabang_m','jenis_cabang', TRUE);
			$data_import = $this->input->post('val_arr');
			if($this->jenis_cabang->import_db($data_import)) {
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
			redirect('jenis_cabang/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('jenis_cabang/import');
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
		redirect('jenis_cabang/import');
	}

	function get_list() {
		header('Content-Type: application/json');
		$kode_cabang = isset($_GET['q']) ? $_GET['q'] : '';
		$nama_cabang = isset($_GET['q']) ? $_GET['q'] : '';
		$row = array();
		$selectcount = ' select count(1) as total ';
		$select = ' select jns_cabangid,kode_cabang,nama_cabang ';
		$from = ' from jns_cabang t ';
		$where = ' where ';
		$where .= " ((coalesce(kode_cabang,'') like '%".$kode_cabang."%') 
			or (coalesce(nama_cabang,'') like '%".$nama_cabang."%'))";
		$sql = $selectcount . $from . $where;
		$query = $this->db->query($sql);
		if ($query->num_rows() > 0) {
			$result['total'] = $query->row()->total;
		} else {
			$result['total'] = 0;
		}
		$sql = $select . $from . $where;
		$query = $this->db->query($sql);
		if ($query->num_rows() > 0) {
			$cmd = $query->result_array();
			foreach($cmd as $data) {	
				$row[] = array(
					'jns_cabangid'=>$data['jns_cabangid'],
					'kode_cabang'=>$data['kode_cabang'],
					'nama_cabang'=>$data['nama_cabang'],
				);
			}
		} else {
			$cmd = array();
		}
		$result=array_merge($result,array('rows'=>$row));
		echo json_encode($result);
	}
}
