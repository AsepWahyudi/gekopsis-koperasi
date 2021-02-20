<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Deposito extends OperatorController {
	
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('deposito_m');
		$this->load->model('general_m');
		$this->load->model('setting_m');
		$this->load->library('terbilang');
		
		$this->load->helper('fungsi');
		$this->load->model('angsuran_m');
		
	}	

	public function index() {
		$this->data['judul_browser'] = 'Transaksi';
		$this->data['judul_utama'] = 'Transaksi';
		$this->data['judul_sub'] = 'Setoran Deposito <a href="'.site_url('deposito/import').'" class="btn btn-sm btn-success">Import Data</a>';

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

		$this->data['kas_id'] = $this->deposito_m->get_data_kas();
		$this->data['jenis_id'] = $this->general_m->get_id_deposito();
		$this->data['jns_anggota'] = $this->general_m->get_jenis_anggota();
		$this->data['level_user'] = $this->deposito_m->get_level_by_id($this->data['u_name']);

		$this->data['isi'] = $this->load->view('deposito_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}

	function list_anggota() {
		$q = isset($_POST['q']) ? $_POST['q'] : '';
		$r = '';
		$data   = $this->general_m->get_data_anggota_ajax($q,$r);
		$i	= 0;
		$rows   = array(); 
		foreach ($data['data'] as $r) {
			if($r->file_pic == '') {
				$rows[$i]['photo'] = '<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="30" height="40" />';
			} else {
				$rows[$i]['photo'] = '<img src="'.base_url().'uploads/anggota/' . $r->file_pic . '" alt="Foto" width="30" height="40" />';
			}
			$rows[$i]['id'] = $r->id;
			$rows[$i]['kode_anggota'] = $r->no_anggota . '<br>' . $r->ktp;
			$rows[$i]['nama'] = $r->nama;
			$rows[$i]['kota'] = $r->kota. '<br>' . $r->departement;		
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	function get_anggota_by_id() {
		$id = isset($_POST['anggota_id']) ? $_POST['anggota_id'] : '';
		$r   = $this->general_m->get_data_anggota($id);
		$out = '';
		$photo_w = 3 * 30;
		$photo_h = 4 * 30;
		if($r->file_pic == '') {

			$out =array($r->nama,'<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="'.$photo_w.'" height="'.$photo_h.'" />'
			.'<br> ID : '.'AG' . sprintf('%04d', $r->id) . '');
		} else {
			$out = array($r->nama,'<img src="'.base_url().'uploads/anggota/' . $r->file_pic . '" alt="Foto" width="'.$photo_w.'" height="'.$photo_h.'" />'
			.'<br> ID : '.'AG' . sprintf('%04d', $r->id) . '');
		}
		echo json_encode($out);
		exit();
	}

	function ajax_list() {
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl_transaksi';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$cari_deposito = isset($_POST['cari_deposito']) ? $_POST['cari_deposito'] : '';
		$cari_nama = isset($_POST['cari_nama']) ? $_POST['cari_nama'] : '';
		$cari_anggota = isset($_POST['cari_anggota']) ? $_POST['cari_anggota'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 
			'cari_deposito' => $cari_deposito,
			'cari_nama' => $cari_nama,
			'cari_anggota' => $cari_anggota,
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->deposito_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$i	= 0;
		$rows   = array(); 

		foreach ($data['data'] as $r) {
			$tgl_bayar = explode(' ', $r->tgl_transaksi);
			$txt_tanggal = jin_date_ina($tgl_bayar[0]);
			$txt_tanggal .= ' - ' . substr($tgl_bayar[1], 0, 5);		

			//array keys ini = attribute 'field' di view nya
			$anggota = $this->general_m->get_data_anggota($r->anggota_id);  
			$nama_deposito = $this->deposito_m->get_jenis_deposito($r->jenis_id);  

			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] ='TRD' . sprintf('%05d', $r->id) . '';
			$rows[$i]['tgl_transaksi'] = $r->tgl_transaksi;
			$rows[$i]['tgl_transaksi_txt'] = $txt_tanggal;
			$rows[$i]['anggota_id'] = $r->anggota_id;
			//$rows[$i]['anggota_id_txt'] = 'AG' . sprintf('%04d', $r->anggota_id);
			$rows[$i]['anggota_id_txt'] = $anggota->ktp;
			$rows[$i]['nama'] = $anggota->nama;
			$rows[$i]['departement'] = $anggota->departement;
			$rows[$i]['jenis_id'] = $r->jenis_id;
			$rows[$i]['jenis_id_txt'] = $nama_deposito->jns_deposito;
			if($r->tenor == '0'){
				$tenor = '-';
			}
			else{
				$tenor = $r->tenor;
			}
			$rows[$i]['tenor'] =$tenor;
			$rows[$i]['bunga'] =$r->bunga;
			$rows[$i]['lunas'] = $r->lunas;
			$rows[$i]['jumlah_txt'] = number_format($r->jumlah);
			$rows[$i]['jumlah'] = $r->jumlah;
			$rows[$i]['ket'] = $r->keterangan;
			$rows[$i]['user'] = $r->user_name;
			$rows[$i]['kas_id'] = $r->kas_id;
			$rows[$i]['nama_penyetor'] = $r->nama_penyetor;
			$rows[$i]['no_identitas'] = $r->no_identitas;
			$rows[$i]['alamat'] = $r->alamat;
			$rows[$i]['is_approve'] = $r->is_approve;
			$rows[$i]['approve_by'] = $r->approve_by;
			$rows[$i]['aksi'] = '<p></p><p><a href="'.site_url('deposito/detail').'/' . $r->id . '" title="Detail"> <i class="fa fa-search"></i> Detail </a>
				&nbsp;
			<a href="'.site_url('cetak_deposito').'/cetak/' . $r->id . '"  title="Cetak Bukti Transaksi" target="_blank"> <i class="glyphicon glyphicon-print"></i> Nota </a></p>';
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	function get_jenis_deposito() {
		$id = $this->input->post('jenis_id');
		$jenis_deposito = $this->general_m->get_id_deposito();
		foreach ($jenis_deposito as $row) {
			if($row->id == $id) {
				echo json_encode($row);
			}
		}
		exit();
	}

	public function create() {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->deposito_m->create()){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		}else
		{
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Gagal menyimpan data, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}
	}

	public function update($id=null) {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->deposito_m->update($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil diubah </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Data gagal diubah, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}

	}

	public function approve() {
		if(!isset($_POST)) {
			show_404();
		}
		$id = intval(addslashes($_POST['id']));
		if($this->deposito_m->approve($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Approve data berhasil </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Approve data gagal </div>'));
		}	
	}

	public function delete() {
		if(!isset($_POST))	 {
			show_404();
		}
		$id = intval(addslashes($_POST['id']));
		if($this->deposito_m->delete($id))
		{
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data gagal dihapus </div>'));
		}
	}


	function cetak_laporan() {
		$simpanan = $this->deposito_m->lap_data_deposito();
		if($simpanan == FALSE) {
			//redirect('simpanan');
			echo 'DATA KOSONG<br>Pastikan Filter Tanggal dengan benar.';
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
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Data Simpanan Anggota <br></span>
			<span> Periode '.jin_date_ina($tgl_dari).' - '.jin_date_ina($tgl_sampai).'</span> ', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
		<table width="100%" cellspacing="0" cellpadding="3" border="1" border-collapse= "collapse">
		<tr class="header_kolom">
			<th class="h_tengah" style="width:5%;" > No. </th>
			<th class="h_tengah" style="width:8%;"> No Transaksi</th>
			<th class="h_tengah" style="width:7%;"> Tanggal </th>
			<th class="h_tengah" style="width:25%;"> Nama Anggota </th>
			<th class="h_tengah" style="width:13%;"> Dept </th>
			<th class="h_tengah" style="width:18%;"> Jenis Simpanan </th>
			<th class="h_tengah" style="width:13%;"> Jumlah  </th>
			<th class="h_tengah" style="width:10%;"> User </th>
		</tr>';

		$no =1;
		$jml_deposito = 0;
		foreach ($simpanan as $row) {
			$anggota= $this->deposito_m->get_data_anggota($row->anggota_id);
			$jns_deposito= $this->deposito_m->get_jenis_deposito($row->jenis_id);

			$tgl_bayar = explode(' ', $row->tgl_transaksi);
			$txt_tanggal = jin_date_ina($tgl_bayar[0],'p');

			$jml_deposito += $row->jumlah;

			// '.'AG'.sprintf('%04d', $row->anggota_id).'
			$html .= '
			<tr>
				<td class="h_tengah" >'.$no++.'</td>
				<td class="h_tengah"> '.'TRD'.sprintf('%05d', $row->id).'</td>
				<td class="h_tengah"> '.$txt_tanggal.'</td>
				<td class="h_kiri"> '.$anggota->identitas.' - '.$anggota->nama.'</td>
				<td> '.$anggota->departement.'</td>
				<td> '.$jns_deposito->jns_deposito.'</td>
				<td class="h_kanan"> '.number_format($row->jumlah).'</td>
				<td> '.$row->user_name.'</td>
			</tr>';
		}
		$html .= '
		<tr>
			<td colspan="5" class="h_tengah"><strong> Jumlah Total </strong></td>
			<td class="h_kanan"> <strong>'.number_format($jml_deposito).'</strong></td>
		</tr>
		</table>';
		$pdf->nsi_html($html);
		$pdf->Output('trans_sp'.date('Ymd_His') . '.pdf', 'I');
	} 

	// Baru
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Setoran Tunai <a href="'.site_url('simpanan').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = 'xls|xlsx';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_deposito')) {
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
										$header[$kolom] = 'Tanggal Transaksi';
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
						if(in_array($kolom, array('B', 'C', 'D')) ) {
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


		$this->data['isi'] = $this->load->view('simpanan_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');
			if($this->deposito_m->import_db($data_import)) {
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
			redirect('simpanan/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('simpanan/import');
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
		redirect('simpanan/import');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->deposito_m->get_data_excel();
		$i	= 0;
		$rows   = array(); 
		
		
		echo "
			<table border='1' cellpadding='5'>
			  <tr>
				<th>Kode Transaksi</th>
				<th>Tanggal Transaksi</th>
				<th>ID Anggota</th>
				<th>Nama Anggota</th>
				<th>Dept</th>
				<th>Jenis Simpanan</th>
				<th>Jumlah</th>
				<th>User</th>
			  </tr>
  		";
		foreach ($data['data'] as $r) {
			echo "
			<tr>
				<td>TRD".sprintf('%05d', $r->id)."</td>
				<td>$r->tgl_transaksi</td>
				<td>$r->identitas</td>
				<td>$r->anggota_nama</td>
				<td>$r->departement</td>
				<td>$r->jns_deposito</td>
				<td>$r->jumlah</td>
				<td>$r->user_name</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
	}
	
	//detail deposito, by debaluk
	public function detail($master_id)
	{
		if($master_id == NULL) {
			redirect('deposito');
			exit();
		}

		$this->data['judul_browser'] = 'Detail Deposito';
		$this->data['judul_utama'] = 'Detail Deposito';
		$this->data['judul_sub'] = 'Kode Depositor  TRD' . sprintf('%05d', $master_id) . '';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		//include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';
		
		//include serch tanggal
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		$this->data['master_id'] = $master_id;
		$row_deposito = $this->general_m->get_data_deposito ($master_id);
		$this->data['row_deposito'] = $row_deposito;
		$this->data['hitung_dibayar'] = $this->general_m->get_jml_bayar_deposito($master_id);
		$this->data['sisa_ags'] = $this->general_m->get_record_bayar_deposito($master_id);
		$this->data['data_anggota'] = $this->general_m->get_data_anggota ($row_deposito->anggota_id);
		//$this->data['hitung_dibayar'] = $this->general_m->get_jml_bayar_simpanan($master_id);
		$this->data['simulasi_tagihan'] = $this->deposito_m->get_simulasi_deposito($master_id);
		//$this->data['angsuran'] = $this->simpanan_m->get_data_angsuran($master_id);

		//$this->data['isi'] = $this->load->view('angsuran_deposito_detail_v', $this->data, TRUE);
		$this->data['isi'] = $this->load->view('deposito_detail_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	public function bayar($master_id)
	{
		if($master_id == NULL) {
			redirect('tarik_deposito');
			exit();
		}

		$this->data['judul_browser'] = 'Bayar Angsuran Deposito';
		$this->data['judul_utama'] = 'Bayar Angsuran Deposito';
		$this->data['judul_sub'] = 'Kode Deposito  TPJ' . sprintf('%05d', $master_id) . '';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		//include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';
		
		//include serch tanggal
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		$this->data['master_id'] = $master_id;
		$row_deposito = $this->general_m->get_data_deposito ($master_id);
		$this->data['row_pinjam'] = $row_deposito; 
		$this->data['data_anggota'] = $this->general_m->get_data_anggota ($row_deposito->anggota_id);
		
		$this->data['hitung_dibayar'] = $this->general_m->get_jml_bayar_simpanan($master_id);
		$this->data['sisa_ags'] = $this->general_m->get_record_bayar_simpanan($master_id);

		$this->data['isi'] = $this->load->view('deposito_bayar_angsuran', $this->data, TRUE);

		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function bayar_ajax_list($id = NULL) {
		if($id == NULL) {
			redirect('bayar');
			exit();
		}
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl_bayar';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 'tgl_dari' => $tgl_dari, 'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->deposito_m->get_data_transaksi_ajax_detail($offset,$limit,$search,$sort,$order,$id);
		$i	= 0;
		$rows   = array(); 

		foreach ($data['data'] as $r) {
			$tgl_bayar1 = explode(' ', $r->tgl_bayar);
			$txt_tanggal = jin_date_ina($tgl_bayar1[0]);
			$txt_tanggal .= ' - ' . substr($tgl_bayar1[1], 0, 5);	

			$pinjam = $this->general_m->get_data_deposito($r->deposito_id);
			$anggota = $this->general_m->get_data_anggota($pinjam->anggota_id); 

			// HARI TELAT
			$hari_telat = 0;
			
		
			$tgl_tempo_var = substr($pinjam->tgl_transaksi, 0, 7) . '-01';
			$tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$i." month"));
			$tgl = substr($pinjam->tgl_transaksi,-11,-9);
			$tgl_tempo = substr($tgl_tempo, 0, 7) . '-' . $tgl;
			
			$tgl_bayar  = substr($r->tgl_bayar, 0, 10);
			
			$txt_tgl_tempo_max = jin_date_ina($tgl_tempo);

			//array keys ini = attribute 'field' di view nya     
			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] ='TBY' . sprintf('%05d', $r->id) . '';
			$rows[$i]['tgl_tempo'] = $txt_tgl_tempo_max;
			$rows[$i]['tgl_bayar'] = $r->tgl_bayar;
			$rows[$i]['tgl_bayar_txt'] = $txt_tanggal;
			$rows[$i]['pinjam_id'] = $r->deposito_id;
			$rows[$i]['angsuran_ke'] = $r->angsuran_ke;
			$rows[$i]['jumlah_bayar'] = number_format(nsi_round($r->jumlah_bayar));
			$rows[$i]['ket'] = $r->keterangan;
			$rows[$i]['user'] = $r->username;
			$rows[$i]['nota'] = '<p></p><p>
			<a href="'.site_url('cetak_angsuran').'/cetak/' . $r->id . '"  title="Cetak Bukti Transaksi" target="_blank"> <i class="glyphicon glyphicon-print"></i> Nota </a></p>';
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}
	
	public function create_angsuran(){
		if(!isset($_POST)) {
			show_404();
		}
		if($this->deposito_m->create_angsuran()){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data tidak dapat disimpan </div>'));
		}
		exit();
	}
	
	public function update_angsuran($id=null) {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->deposito_m->update_angsuran($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil diubah </div>'));
		}	else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>Maaf, Data gagal diubah </div>'));
		}
	}
	
	function get_ags_ke($master_id) {
		$id_bayar = $this->input->post('id_bayar');
		if($id_bayar > 0) {
			$data_bayar = $this->deposito_m->get_data_pembayaran_by_id($id_bayar);
			if($data_bayar) {
				$ags_ke = $data_bayar->angsuran_ke;
			} else {
				$ags_ke = 1;
			}
		} else {
			$ags_ke = $this->general_m->get_record_bayar_deposito($master_id) + 1;
		}

		// -- bayar angsuran --
		$row_pinjam = $this->general_m->get_data_deposito($master_id); #data pinjam
		$lama_ags = $row_pinjam->tenor; # lama angsuran
		$status_lunas = $row_pinjam->lunas; # status lunas
		$sisa_ags = $lama_ags  - $ags_ke; #sisa angsuran 
		$jml_pinjaman = $row_pinjam->tenor  * $row_pinjam->pokok_angsuran; #jml pinjaman

		//hitung sudah dibayar
		$dibayar=$this->general_m->get_jml_bayar_deposito($master_id);
		$sudah_bayar= $dibayar->total * 1;

		//total harus bayar 
		$total_bayar = $jml_pinjaman;

		$sisa_tagihan = number_format(nsi_round($row_pinjam->pokok_angsuran * $sisa_ags)); #sisa tagihan 
		$sisa= $row_pinjam->pokok_angsuran * $sisa_ags; #sisa tagihan 

		//sisa pembayaran
		$sisa_pembayaran = $sisa;

		//--- update angsuran --
		$sisa_ags_det = $row_pinjam->tenor - ($ags_ke - 1) ;
		$sudah_bayar_det = number_format(nsi_round($dibayar ->total));

		// validasi lunas
		$sisa_tagihan_num = ($jml_pinjaman - $sudah_bayar);
		if($sisa_tagihan_num <= 0){
			$sisa_tagihan_num=0;
		}else{
			$sisa_tagihan_num=$sisa_tagihan_num;
		}


		$sisa_tagihan_det = number_format(nsi_round($sisa_tagihan_num));
		$total_bayar_det = number_format(nsi_round($sisa_tagihan_num));
		$total_tagihan = number_format(nsi_round($sisa_tagihan_num));

		
		if($ags_ke > $lama_ags) {
			$data = array(
				'ags_ke' 				=> 0,
				'sisa_ags' 				=> $sisa_ags,
				'sisa_tagihan'			=> $sisa_tagihan,
				'sisa_pembayaran' 	=> $sisa_pembayaran,

				'sisa_ags_det' 		=> $sisa_ags_det,
				'sudah_bayar_det' 	=> $sudah_bayar_det,
				'sisa_tagihan_det'	=> $sisa_tagihan_det,
				'total_bayar_det' 	=> $total_bayar_det,

				'status_lunas' 		=> $status_lunas,
				'total_tagihan' 		=> $total_tagihan
			);
			echo json_encode($data);		
		} else {
			$data = array(
				'ags_ke' 				=> $ags_ke,
				'sisa_ags' 				=> $sisa_ags,
				'sisa_tagihan'			=> $sisa_tagihan,
				'sisa_pembayaran' 	=> $sisa_pembayaran,

				'sisa_ags_det' 		=> $sisa_ags_det,
				'sudah_bayar_det' 	=> $sudah_bayar_det,
				'sisa_tagihan_det'	=> $sisa_tagihan_det,
				'total_bayar_det' 	=> $total_bayar_det,

				'status_lunas' 		=> $status_lunas,
				'total_tagihan' 		=> $total_tagihan
				);
			echo json_encode($data);
		}
		exit();
	}
	
	public function cetak_angsuran($id)
	{
		
		
		
		$angsuran = $this->angsuran_m->get_data_pembayaran_by_id($id);
		$opsi_val_arr = $this->setting_m->get_key_val();
		foreach ($opsi_val_arr as $key => $value){
			$out[$key] = $value;
		}

		$this->load->library('Struk');
		$pdf = new Struk('P', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(false);
		$resolution = array(210, 80);
		$pdf->AddPage('L', $resolution);
		$html = '<style>
		.h_tengah {text-align: center;}
		.h_kiri {text-align: left;}
		.h_kanan {text-align: right;}
		.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 12px;}
		.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		.txt_content {font-size: 7pt; text-align: center;}
	</style>';
	$html .= ''.$pdf->nsi_box($text =' <table width="100%">
		<tr>
			<td colspan="2" class="h_kanan"><strong>'.$out['nama_lembaga'].'</strong></td>
		</tr>
		<tr>
			<td width="30%"><strong>BUKTI SETORAN ANGSURAN KREDIT</strong>
				<hr width="100%">
			</td>
			<td class="h_kanan" width="70%">'.$out['alamat'].'</td>
		</tr>
	</table>', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'left').'';
	$no =1;
	foreach ($angsuran as $row) {
		$pinjaman= $this->general_m->get_data_pinjam($row->pinjam_id);

		$anggota_id = $pinjaman->anggota_id;
		$anggota= $this->general_m->get_data_anggota($anggota_id);

		$hitung_denda = $this->general_m->get_jml_denda($row->pinjam_id);
		$jml_denda=$hitung_denda->total_denda;

		$hitung_dibayar = $this->general_m->get_jml_bayar($row->pinjam_id);
		$dibayar = $hitung_dibayar->total;
		$tagihan = $pinjaman->ags_per_bulan * $pinjaman->lama_angsuran;
		$sisa_bayar = $tagihan - $dibayar ;

		$total_dibayar = $sisa_bayar + $jml_denda;

		$tgl_bayar = explode(' ', $row->tgl_bayar);
		$txt_tanggal = jin_date_ina($tgl_bayar[0]);
		$txt_tanggal .= ' / ' . substr($tgl_bayar[1], 0, 5);    

		//AG'.sprintf('%04d', $anggota_id).'
		$html .='<table width="100%">
		<tr>
			<td width="20%"> Tanggal Transaksi </td>
			<td width="2%">:</td>
			<td width="35%" class="h_kiri">'.$txt_tanggal.'</td>

			<td> Tanggal Cetak </td>
			<td colspan="2">: '.jin_date_ina(date('Y-m-d')).' / '.date('H:i').'</td>
		</tr>
		<tr>
			<td> Nomor Transaksi </td>
			<td>:</td>
			<td>'.'TRD'.sprintf('%05d', $row->id).'</td>

			<td> User Akun </td>
			<td colspan="2">: '.$row->user_name.' </td>           
		</tr>
		<tr>
			<td> ID Anggota </td>
			<td>:</td>
			<td>'.$anggota->identitas.' / '.strtoupper($anggota->nama).'</td>

			<td> Status </td>
			<td colspan="2">: SUKSES</td>
		</tr>
		<tr>
			<td> Dept </td>
			<td>:</td>
			<td class="h_kiri">'.$anggota->departement.'</td>
		</tr>
		<tr>
			<td> Nomor Kontrak </td>
			<td >:</td>
			<td class="h_kiri">'.'TPJ'.sprintf('%05d', $pinjaman->id).'</td>
		</tr>
		<tr>
			<td> Angsuran Ke </td>
			<td>: </td>
			<td class="h_kiri">'.$row->angsuran_ke.' / '.$pinjaman->lama_angsuran.'</td>
		</tr>
	</table>
	<table width="100%">
		<tr>
			<td width="20%"> Angsuran Pokok </td>
			<td width="5%">: Rp. </td>
			<td width="15%"  class="h_kanan">'.number_format($pinjaman->pokok_angsuran).'</td>

			<td width="17%"></td>
			<td width="16.5%">Total Denda </td>
			<td width="5%">: Rp. </td>
			<td width="20%" class="h_kanan">'.number_format(nsi_round($jml_denda)).'</td>
		</tr>
		<tr>
			<td> Bunga Angsuran</td>
			<td width="5%">: Rp. </td>
			<td class="h_kanan">'.number_format($pinjaman->bunga_pinjaman).'</td>

			<td width="17%"> </td>
			<td width="16.5%">Sisa Pinjman</td>
			<td width="5%">: Rp. </td>
			<td width="20%" class="h_kanan">'.number_format(nsi_round($sisa_bayar)).'</td>
		</tr>
		<tr>
			<td> Biaya Admin </td>
			<td>: Rp. </td>
			<td class="h_kanan">'.number_format(nsi_round($pinjaman->biaya_adm)).'</td>

			<td width="17%"></td>
			<td width="16.5%">Total Tagihan </td>
			<td width="5%">: Rp. </td>
			<td width="20%" class="h_kanan">'.number_format(nsi_round($total_dibayar)).'</td>
		</tr>
		<tr>
			<td> Jumlah Angsuran </td>
			<td>: Rp.</td>
			<td class="h_kanan"><strong>'.number_format(nsi_round($row->jumlah_bayar)).'</strong></td>
		</tr>
		<tr>
			<td> Terbilang </td>
			<td colspan="4">: '.$this->terbilang->eja(nsi_round($row->jumlah_bayar)).' RUPIAH</td>
		</tr>';
	}
	$html .= '</table>
	<p class="txt_content">Ref. '.date('Ymd_His').'<br> 
		Informasi Hubungi Call Center : '.$out['telepon'].'
		<br>
		atau dapat diakses melalui : '.$out['web'].'
	</p>';

	$pdf->nsi_html($html);
	$pdf->Output(date('Ymd_His') . '.pdf', 'I');


	}
	
	public function delete_angsuran() {
		if(!isset($_POST)) {
			show_404();
		}
		$id = $this->input->post('id');
		$master_id = $this->input->post('master_id');
		
		if($this->deposito_m->delete_angsuran($id, $master_id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Anda harus hapus data sebelumnya </div>'));
		}
	}
	
}