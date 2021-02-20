<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class fixed_asset extends AdminController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('fixed_asset_m');
		$this->load->library('terbilang');
	}	
	
	public function index() {
		$this->data['judul_browser'] = 'Fixed Asset';
		$this->data['judul_utama'] = 'Fixed Asset';
		$this->data['judul_sub'] = 'Fixed Asset <a href="'.site_url('fixed_asset/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->output->set_template('gc');

		$this->load->library('grocery_CRUD');
		$crud = new grocery_CRUD();
		$crud->set_table('fixed_asset');
		$crud->set_subject('Fixed Asset');
	
		$crud->fields('kode_asset','nama_asset','kategori_asset','status','tanggal_efektif','harga_perolehan','akumulasi_penyusutan','nilai_buku','depresia','usia_fiskal','barang_id','jns_cabangid');		
		$crud->required_fields('kode_asset','kode_asset','nama_asset','kategori_asset','status','tanggal_efektif','harga_perolehan','akumulasi_penyusutan','nilai_buku','depresia','usia_fiskal','jns_cabangid');
		
		//$crud->display_as('barang_id','Nama Barang');

		$this->db->_protect_identifiers = FALSE;

		$this->db->select('*');
		$this->db->from('kategori_asset');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$result = $query->result();
			foreach ($result as $val) {
				$kategori[$val->kategori_asset_id] = $val->kategori_asset;
			}
		} else {
			$kategori = array('' => '-');
		}
		$crud->field_type('kategori_asset','dropdown',$kategori);

		
		$this->db->select('id,nm_barang');
		$this->db->from('tbl_barang');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$result = $query->result();
			foreach ($result as $val) {
				$barang[$val->id] = $val->nm_barang;
			}
		} else {
			$barang = array('' => '-');
		}
		$crud->field_type('barang_id','dropdown',$barang);

		$this->db->select('jns_cabangid, nama_cabang');
		$this->db->from('jns_cabang');
		$query = $this->db->get();
		if($query->num_rows()>0){
			$result = $query->result();
			foreach ($result as $val) {
				$cabang[$val->jns_cabangid] = $val->nama_cabang;
			}
		} else {
			$cabang = array('' => '-');
		}
		$crud->field_type('jns_cabangid','dropdown',$cabang);

		$crud->display_as('jns_cabangid','Cabang');
		
		$crud->field_type('status','dropdown',
			array('ACTIVE' => 'ACTIVE','NOT ACTIVE' => 'NOT ACTIVE'));

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

	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Fixed Asset <a href="'.site_url('fixed_asset').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_fixed_asset')) {
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
									$header[$kolom] = $val;
								} else {
									if($kolom == 'F' ) {
										$val = date('Y-m-d',strtotime($val));
										//$val = PHPExcel_Style_NumberFormat::toFormattedString($val,'YYYY-MM-DD');
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
				$this->data['header'] = $header;
				$this->data['values'] = $data_list;

			}
		}


		$this->data['isi'] = $this->load->view('fixed_asset_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function import_db() {

		if($this->input->post('submit')) {
			$this->load->model('fixed_asset_m','fixed_asset', TRUE);
			$data_import = $this->input->post('val_arr');
			if($this->fixed_asset->import_fixed_asset($data_import)) {
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
			redirect('fixed_asset/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('fixed_asset/import');
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
		redirect('fixed_asset/import');
	}
}