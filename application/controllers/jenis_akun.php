<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Jenis_akun extends AdminController {

	public function __construct() {
		parent::__construct();	
	}	
	
	public function index() {
		$this->data['judul_browser'] = 'Master Data';
		$this->data['judul_utama'] = 'Master Data';
		$this->data['judul_sub'] = 'Jenis Akun <a href="'.site_url('jenis_akun/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->output->set_template('gc');

		$this->load->library('grocery_CRUD');
		$crud = new grocery_CRUD();
		$crud->set_table('jns_akun');
		$crud->set_subject('Jenis Akun Transaksi');
	
		$crud->fields('no_akun','nama_akun', 'induk_akun', 'kelompok_akunid', 'kelompok_laporan', 'jenis_akun','saldo_normal','aktif');
		$crud->columns('no_akun','nama_akun', 'induk_akun', 'kelompok_akunid', 'kelompok_laporan', 'jenis_akun','saldo_normal','aktif');
		$crud->set_relation('kelompok_akunid','kelompok_akun','nama_kelompok');
		//$crud->set_relation('induk_akun','jns_akun','{no_akun} - {nama_akun}');
		$crud->set_relation('induk_akun','jns_akun','{no_akun}');
		$crud->unique_fields(array('no_akun'));
		
		$crud->required_fields('no_akun','nama_akun','kelompok_laporan');
		$crud->display_as('kelompok_akunid','Kelompok Akun');
		$this->db->_protect_identifiers = FALSE;

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
		$this->data['judul_sub'] = 'Jenis Akun Transaksi <a href="'.site_url('jenis_akun').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_jenis_akun')) {
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

						$data_jml_arr = array();
						for ($row = 1; $row <= $highestRow; ++$row) {
							for ($col = 0; $col < $highestColumnIndex; ++$col) {
								$cell = $worksheet->getCellByColumnAndRow($col, $row);
								$val = $cell->getValue();
								$kolom = PHPExcel_Cell::stringFromColumnIndex($col);
								if($row === 1) {
									if($kolom == 'A') {
										$header[$kolom] = 'Kd Aktiva';
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
				
				$this->data['header'] = $header;
				$this->data['values'] = $data_list;
			}
		}


		$this->data['isi'] = $this->load->view('jenis_akun_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			$this->load->model('jenis_akun_m','jenis_akun', TRUE);
			$data_import = $this->input->post('val_arr');
			if($this->jenis_akun->import_db($data_import)) {
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
			redirect('jenis_akun/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('jenis_akun/import');
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
		redirect('jenis_akun/import');
	}

	function get_list() {
		header('Content-Type: application/json');
		$no_akun = isset($_GET['q']) ? $_GET['q'] : '';
		$nama_akun = isset($_GET['q']) ? $_GET['q'] : '';
		$row = array();
		$selectcount = ' select count(1) as total ';
		$select = ' select jns_akun_id, no_akun, nama_akun ';
		$from = ' from jns_akun t ';
		$where = ' where ';
		$where .= " ((coalesce(no_akun,'') like '%".$no_akun."%') 
			or (coalesce(nama_akun,'') like '%".$nama_akun."%')) 
			and aktif = 'Y' 
			and jenis_akun = 'SUB AKUN' ";
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
					'jns_akun_id'=>$data['jns_akun_id'],
					'no_akun'=>$data['no_akun'],
					'nama_akun'=>$data['nama_akun'],
				);
			}
		} else {
			$cmd = array();
		}
		
		$result=array_merge($result,array('rows'=>$row));
		echo json_encode($result);
	}

}
