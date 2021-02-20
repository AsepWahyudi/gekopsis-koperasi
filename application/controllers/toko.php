<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Toko extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('transfer_m');
		$this->load->model('toko_m');
		$this->load->model('pinjaman_m');
	}	

	public function index() {
		$this->data['judul_browser'] = 'Transaksi';
		$this->data['judul_utama'] = 'Transaksi';
		$this->data['judul_sub'] = 'Transaksi Toko <a href="'.site_url('toko/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

		#include daterange
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		//number_format
		$this->data['js_files'][] = base_url() . 'assets/extra/fungsi/number_format.js';


		$this->data['barang_id'] = $this->pinjaman_m->get_id_barang();

		$this->data['kas_id'] = $this->toko_m->get_data_kas();

		$this->data['isi'] = $this->load->view('toko_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}


	function ajax_list() {
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->toko_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$i	= 0;
		$rows   = array(); 

		foreach ($data['data'] as $r) {
			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] ='TRT' . sprintf('%05d', $r->id) . '';
			$rows[$i]['tgl'] = $r->tgl;
			$rows[$i]['tgl_txt'] = $r->tgl;	
			$rows[$i]['keterangan'] = $r->keterangan;
			$rows[$i]['jumlah'] = number_format($r->jumlah);
			$rows[$i]['harga'] = $r->harga;
			$rows[$i]['barang'] = $r->nm_barang;
			$rows[$i]['nama'] = $r->nama;
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	public function create() {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->toko_m->create()){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		}else{
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Gagal menyimpan data, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}
	}

	public function update($id=null) {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->toko_m->update($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil diubah </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Data gagal diubah, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}

	}
	
	public function delete() {
		if(!isset($_POST))	 {
			show_404();
		}
		$id = intval(addslashes($_POST['id']));
		if($this->toko_m->delete($id))
		{
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data gagal dihapus </div>'));
		}
	}


	function cetak_laporan() {
		$transfer = $this->transfer_m->lap_data_transfer();
		if($transfer == FALSE) {
			redirect('transfer_kas');
			exit();
		}

		$tgl_dari = $_REQUEST['tgl_dari']; 
		$tgl_sampai = $_REQUEST['tgl_sampai']; 

		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('L');
		$html = '';
		$html .= '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 12px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			.txt_content {font-size: 10pt; font-style: arial;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Data Transfer Antar Kas<br></span>

			<span> Periode '.jin_date_ina($tgl_dari).' - '.jin_date_ina($tgl_sampai).'</span>

			', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
		<table width="100%" cellspacing="0" cellpadding="3" border="1" border-collapse= "collapse">
			<tr class="header_kolom">
				<th class="h_tengah" style="width:5%;" > No. </th>
				<th class="h_tengah" style="width:10%;"> No Transaksi</th>
				<th class="h_tengah" style="width:15%;"> Tanggal </th>
				<th class="h_tengah" style="width:25%;"> Uraian  </th>
				<th class="h_tengah" style="width:10%;"> Dari Kas </th>
				<th class="h_tengah" style="width:10%;"> Untuk Kas  </th>
				<th class="h_tengah" style="width:15%;"> Jumlah  </th>
				<th class="h_tengah" style="width:10%;"> User </th>
			</tr>';

			$no =1;
			$jml_transfer = 0;
			foreach ($transfer as $row) {
				$tgl_bayar = explode(' ', $row->tgl_catat);
				$txt_tanggal = jin_date_ina($tgl_bayar[0],'p');

				$dari_kas = $this->transfer_m->get_nama_kas_id($row->dari_kas_id);  
				$untuk_kas = $this->transfer_m->get_nama_kas_id($row->untuk_kas_id); 

				$jml_transfer += $row->jumlah;

				$html .= '
				<tr>
					<td class="h_tengah" >'.$no++.'</td>
					<td class="h_tengah"> '.'TRF'.sprintf('%05d', $row->id).'</td>
					<td class="h_tengah"> '.$txt_tanggal.'</td>
					<td class="h_kiri"> '.$row->keterangan.'</td>
					<td class="h_kiri"> '.$dari_kas->nama.'</td>
					<td class="h_kiri"> '.$untuk_kas->nama.'</td>
					<td class="h_kanan"> '.number_format($row->jumlah).'</td>
					<td> '.$row->user_name.'</td>
				</tr>';
			}
			$html .= '
			<tr>
				<td colspan="6" class="h_tengah"><strong> Jumlah Total </strong></td>
				<td class="h_kanan"> <strong>'.number_format($jml_transfer).'</strong></td>
			</tr>
		</table>';
		$pdf->nsi_html($html);
		$pdf->Output('trans'.date('Ymd_His') . '.pdf', 'I');
	} 

	//Added
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Transaksi Toko <a href="'.site_url('toko').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = 'xls|xlsx';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_toko')) {
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
									if($kolom == 'A') {
										$header[$kolom] = 'Tanggal';
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


		$this->data['isi'] = $this->load->view('toko_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			$this->load->model('toko_m','toko', TRUE);
			$data_import = $this->input->post('val_arr');
			if($this->toko->import_db($data_import)) {
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
			redirect('toko/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('toko/import');
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
		redirect('toko/import');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->toko_m->get_data_excel();
		$i	= 0;
		$rows   = array(); 
		
		
		echo "
			<table border='1' cellpadding='5'>
			  <tr>
				<th>Kode Transaksi</th>
				<th>Tanggal</th>
				<th>Barang</th>
				<th>Harga</th>
				<th>Jumlah</th>
				<th>Keterangan</th>
				<th>Tipe</th>
			  </tr>
  		";
		foreach ($data['data'] as $r) {
			echo "
			<tr>
				<td>TRT".sprintf('%05d', $r->id)."</td>
				<td>$r->tgl</td>
				<td>$r->nm_barang</td>
				<td>$r->harga</td>
				<td>$r->jumlah</td>
				<td>$r->keterangan</td>
				<td>$r->tipe</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
	}
}