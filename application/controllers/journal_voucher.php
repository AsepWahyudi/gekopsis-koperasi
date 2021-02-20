<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class journal_voucher extends AdminController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('journal_voucher_m');
		$this->load->model('journal_voucher_det_m');
		$this->load->library('terbilang');
	}	
	
	public function index() {
		$this->data['judul_browser'] = 'Jurnal Transaksi';
		$this->data['judul_utama'] = 'Transaksi Keuangan';
		$this->data['judul_sub'] = 'Jurnal Transaksi <a href="'.site_url('journal_voucher/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';
		$this->data['js_files'][] = base_url() . 'assets/easyui/plugins/jquery.edatagrid.min.js';
		$this->data['js_files'][] = base_url() . 'assets/easyui/plugins/datagrid-detailview.min.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

		#include daterange
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		//number_format
		$this->data['js_files'][] = base_url() . 'assets/extra/fungsi/number_format.js';

		$this->data['isi'] = $this->load->view('journal_voucher_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function list() {
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'journal_date';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'asc';
		$journal_no = isset($_POST['journal_no']) ? $_POST['journal_no'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('journal_no' => $journal_no, 
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->journal_voucher_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$i	= 0;
		$rows   = array(); 
		
		foreach ($data['data'] as $r) {
			$rows[$i]['journal_voucherid'] = $r->journal_voucherid;
			$rows[$i]['journal_no'] = $r->journal_no;
			$rows[$i]['journal_date'] = date('d-m-Y',strtotime($r->journal_date));
			$rows[$i]['headernote'] = $r->headernote;
			$rows[$i]['jns_transaksi'] = $r->jns_transaksi;
			$rows[$i]['validasi_status'] = $r->validasi_status;
			$rows[$i]['aksi'] = '<p></p><p><a href="'.site_url('journal_voucher/detail').'/' . $r->journal_voucherid . '" title="Detail"> <i class="fa fa-search"></i> Detail </a>
				&nbsp;
			<a href="'.site_url('cetak_journal_voucher').'/cetak/' . $r->journal_voucherid . '"  title="Cetak Jurnal Transaksi" target="_blank"> <i class="glyphicon glyphicon-print"></i>Cetak</a></p>';
			$i++;
		}
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); 
	}

	function listdetail(){
		header('Content-Type: application/json');
    $id = 0;
    if (isset($_POST['id'])) {
      $id = $_POST['id'];
    } else if (isset($_GET['id'])) {
      $id = $_GET['id'];
		}
		$data   = $this->journal_voucher_det_m->get_data_list($id);
		$i	= 0;
		$rows   = array(); 

		foreach ($data['data'] as $r) {
			$rows[$i]['journal_voucher_id'] = $r->journal_voucher_id;
			$rows[$i]['debit'] = number_format($r->debit,2,',','.');
			$rows[$i]['credit'] = number_format($r->credit,2,',','.');
			$rows[$i]['journal_voucher_detid'] = $r->journal_voucher_detid;
			$rows[$i]['jns_cabangid'] = $r->jns_cabangid;
			$rows[$i]['jns_akun_id'] = $r->jns_akun_id;
			$rows[$i]['no_akun'] = $r->no_akun;
			$rows[$i]['nama_akun'] = $r->nama_akun;
			$rows[$i]['itemnote'] = $r->itemnote;
			$rows[$i]['kode_cabang'] = $r->kode_cabang;
			$i++;
		}
    $result = array('total'=>$data['count'],'rows' => $rows);
		$sql = "select ifnull(sum(debit),0) as debit, ifnull(sum(credit),0) as credit from journal_voucher_det t where journal_voucher_id = ".$id;
		$cmd = $this->db->query($sql)->row_array();
		$footer[] = array(
      'nama_akun' => 'Total',
      'debit' => number_format($cmd['debit'],2),
      'credit' => number_format($cmd['credit'],2),
    );
    $result = array_merge($result, array(
      'footer' => $footer
    ));
    echo json_encode($result);
	}

	public function create() {
		//$id = rand(-1, -1000000000);
		$id = 0;
		echo json_encode(array(
			'journal_voucherid' => $id,
		));
	}

	public function save(){
		$journal_voucherid = isset($_POST['journal_voucherid']) ? $_POST['journal_voucherid']:'';
		$journal_no = isset($_POST['journal_no']) ? $_POST['journal_no']:'';
		$journal_date = isset($_POST['journal_date']) ? $_POST['journal_date']:'';
		$headernote = isset($_POST['headernote']) ? $_POST['headernote']:'';
		$jns_transaksi = isset($_POST['jns_transaksi']) ? $_POST['jns_transaksi']:'';
		$this->db->trans_start();
		if ($journal_voucherid == 0) {
			if ($journal_no != '') {
				$journal_no = $journal_no;
			} else {
				$query = $this->db->query("select max(journal_no) as nojurnal from journal_voucher where left(journal_no,1) = '0'");
				$data = $query->row();
				if ($query->num_rows() > 0) {
					if ($data->nojurnal != '') {
						$journal_no = $data->nojurnal + 0000001;
						$journal_no = str_pad($journal_no,7,"0",STR_PAD_LEFT);
					} else {
						$val = 1;
						$journal_no = str_pad($val,7,"0",STR_PAD_LEFT);
					}
				} else {
					$val = 1;
					$journal_no = str_pad($val,7,"0",STR_PAD_LEFT);
				}
			}
			
			$data = array (
				'journal_no'=>$journal_no,
				'journal_date'=>date('Y-m-d', strtotime($journal_date)),
				'headernote'=>$headernote,
				'jns_transaksi'=>$jns_transaksi,
			);
			$this->db->insert('journal_voucher',$data);
		} else {
			$data = array (
				'journal_voucherid'=>$journal_voucherid,
				'journal_no'=>$journal_no,
				'journal_date'=>date('Y-m-d', strtotime($journal_date)),
				'headernote'=>$headernote,
				'jns_transaksi'=>$jns_transaksi,
			);
			$this->db->replace('journal_voucher',$data);
		}
		$insert_id = $this->db->insert_id();

		$sql = "update journal_voucher_det set journal_voucher_id = ? where journal_voucher_id = ? ";
		$this->db->query($sql,array($insert_id,$journal_voucherid));

		$this->db->trans_complete();
		echo json_encode(array(
			'isError'=>0,
			'msg'=>'Simpan Berhasil'
		));
		if ($this->db->trans_status() === FALSE) {
			echo json_encode(array(
				'isError'=>1,
				'msg'=>$e->errorInfo
			));
		}
	}

	public function savedetail(){
		$journal_voucher_detid = isset($_POST['journal_voucher_detid']) ? $_POST['journal_voucher_detid']:'';
		$journal_voucher_id = isset($_POST['journal_voucher_id']) ? $_POST['journal_voucher_id']:'';
		$jns_akunid = isset($_POST['jns_akun_id']) ? $_POST['jns_akun_id']:'';
		$debit = isset($_POST['debit']) ? $_POST['debit']:'';
		$debit = str_replace(".", "", $debit);
		$debit = str_replace(",", ".", $debit);
		$credit = isset($_POST['credit']) ? $_POST['credit']:'';
		$credit = str_replace(".", "", $credit);
		$credit = str_replace(",", ".", $credit);
		$jns_cabangid = isset($_POST['jns_cabangid']) ? $_POST['jns_cabangid']:'';
		$itemnote = isset($_POST['itemnote']) ? $_POST['itemnote']:'';
		$this->db->trans_start();
		$data = array (
			'journal_voucher_detid'=>$journal_voucher_detid,
			'journal_voucher_id'=>$journal_voucher_id,
			'jns_akun_id'=>$jns_akunid,
			'debit'=>$debit,
			'credit'=>$credit,
			'jns_cabangid'=>$jns_cabangid,
			'itemnote'=>$itemnote,
		);
		$this->db->replace('journal_voucher_det',$data);
		$this->db->trans_complete();
		echo json_encode(array(
			'isError'=>0,
			'msg'=>'Simpan Berhasil'
		));
		if ($this->db->trans_status() === FALSE) {
			echo json_encode(array(
				'isError'=>1,
				'msg'=>$e->errorInfo
			));
		}
	}

	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Journal Transaksi <a href="'.site_url('journal_voucher').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_journal_voucher')) {
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
				$this->data['header'] = $header;
				$this->data['values'] = $data_list;

			}
		}


		$this->data['isi'] = $this->load->view('journal_voucher_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function import_db() {
		if($this->input->post('submit')) {
			$this->load->model('journal_voucher_m','journal_voucher', TRUE);
			$data_import = $this->input->post('val_arr');
			if($this->journal_voucher->import_journal_db($data_import)) {
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
			redirect('journal_voucher/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('journal_voucher/import');
		}
	}

	public function validasi() {
		if(!isset($_POST)) {
			show_404();
		}
		$id = intval(addslashes($_POST['id']));
		if($this->journal_voucher_m->validasi($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Validasi data berhasil </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Validasi data gagal </div>'));
		}	
	}

	public function purge() {
		if(!isset($_POST))	{
			show_404();
		}

		$id = intval(addslashes($_POST['id']));
		if($this->journal_voucher_m->purge($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data gagal dihapus </div>'));
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
		redirect('journal_voucher/import');
	}


	public function purgedetail(){
		$journal_voucher_detid = isset($_POST['jvdid']) ? $_POST['jvdid']:'';
		$journal_voucher_id = isset($_POST['id']) ? $_POST['id']:'';

		$this->db->trans_start();
		$this->db->where('journal_voucher_id', $journal_voucher_id);
		$this->db->where('journal_voucher_detid', $journal_voucher_detid);
		$this->db->delete('journal_voucher_det');
		
		$this->db->trans_complete();
		echo json_encode(array(
			'isError'=>0,
			'msg'=>'Delete Berhasil'
		));
		if ($this->db->trans_status() === FALSE) {
			echo json_encode(array(
				'isError'=>1,
				'msg'=>$e->errorInfo
			));
		}
	}
}