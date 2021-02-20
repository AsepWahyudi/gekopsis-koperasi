<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Penarikan extends OperatorController {
	
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('penarikan_m');
		$this->load->model('general_m');
	}	

	public function index() {
		$this->data['judul_browser'] = 'Transaksi';
		$this->data['judul_utama'] = 'Transaksi';
		$this->data['judul_sub'] = 'Penarikan Tunai <a href="'.site_url('penarikan/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		//include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

		//include datarange
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';

		//number_format
		$this->data['js_files'][] = base_url() . 'assets/extra/fungsi/number_format.js';
		
		//panggil data
		$this->data['kas_id'] = $this->penarikan_m->get_data_kas();
		$this->data['jenis_id'] = $this->general_m->get_id_simpanan();
		
		$this->data['jns_anggota'] = $this->general_m->get_jenis_anggota();
		$this->data['level_user'] = $this->general_m->get_level_by_id($this->data['u_name']);

		$this->data['isi'] = $this->load->view('penarikan_list_v', $this->data, TRUE);
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
			$rows[$i]['kode_anggota'] = 'AG'.sprintf('%04d', $r->id) . '<br>' . $r->ktp;
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

	function get_jml_tabungan() {
		$id = isset($_POST['anggota_id']) ? $_POST['anggota_id'] : '';
		$jml= $this->penarikan_m->get_jml_simpanan($id);
		$jml_tabungan = $jml->total;
	}

	function ajax_list() {
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl_transaksi';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$cari_simpanan = isset($_POST['cari_simpanan']) ? $_POST['cari_simpanan'] : '';
		$cari_anggota = isset($_POST['cari_anggota']) ? $_POST['cari_anggota'] : '';
		$cari_nama = isset($_POST['cari_nama']) ? $_POST['cari_nama'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 
			'cari_simpanan' => $cari_simpanan,
			'cari_anggota' => $cari_anggota,
			'cari_nama' => $cari_nama,
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->penarikan_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$i	= 0;
		$rows   = array(); 
		foreach ($data['data'] as $r) {
			$tgl_bayar = explode(' ', $r->tgl_transaksi);
			$txt_tanggal = jin_date_ina($tgl_bayar[0]);
			$txt_tanggal .= ' - ' . substr($tgl_bayar[1], 0, 5);		

			//array keys ini = attribute 'field' di view nya
			$anggota = $this->general_m->get_data_anggota($r->anggota_id);  
			$nama_simpanan = $this->general_m->get_jns_simpanan($r->jenis_id);  

			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] ='TRK' . sprintf('%05d', $r->id) . '';
			$rows[$i]['tgl_transaksi'] = $r->tgl_transaksi;
			$rows[$i]['tgl_transaksi_txt'] = $txt_tanggal;
			$rows[$i]['anggota_id'] = $r->anggota_id;
			//$rows[$i]['anggota_id_txt'] = 'AG' . sprintf('%04d', $r->anggota_id) . '';
			$rows[$i]['anggota_id_txt'] = $anggota->ktp;
			$rows[$i]['nama'] = $anggota->nama;
			$rows[$i]['departement'] = $anggota->departement;
			$rows[$i]['jenis_id'] = $r->jenis_id;
			$rows[$i]['jenis_id_txt'] =$nama_simpanan->jns_simpan;
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
			$rows[$i]['nota'] = '<p></p><p>
			<a href="'.site_url('cetak_penarikan').'/cetak/' . $r->id . '"  title="Cetak Bukti Transaksi" target="_blank"> <i class="glyphicon glyphicon-print"></i> Nota </a></p>';
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	function get_jenis_simpanan() {
		$this->load->model('lap_kas_anggota_m');
		$jenis_id = $this->input->post('jenis_id');
		$anggota_id = $this->input->post('anggota_id');
		$tot_simpn = $this->lap_kas_anggota_m->get_jml_simpanan($jenis_id, $anggota_id);
		$tot_tarik = $this->lap_kas_anggota_m->get_jml_penarikan($jenis_id, $anggota_id);
		echo number_format($tot_simpn->jml_total - $tot_tarik->jml_total);
		exit();
	}

	public function create() {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->penarikan_m->create()){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Gagal menyimpan data, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}
	}

	public function update($id=null) {
		if(!isset($_POST)) {
			show_404();
		}

		if($this->penarikan_m->update($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil diubah </div>'));
		}	else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Data Gagal Diubah, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}
	}

	public function delete() {
		if(!isset($_POST)) {
			show_404();
		}

		$id = intval(addslashes($_POST['id']));
		if($this->penarikan_m->delete($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data gagal dihapus </div>'));
		}
	}

	public function approve() {
		if(!isset($_POST)) {
			show_404();
		}
		$id = intval(addslashes($_POST['id']));
		if($this->penarikan_m->approve($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Approve data berhasil </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Approve data gagal </div>'));
		}	
	}

	function cetak_laporan() {
		$penarikan = $this->penarikan_m->lap_data_penarikan();
		if($penarikan == FALSE) {
			//redirect('penarikan');
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
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Data Penarikan Simpanan <br></span>
			<span> Periode '.jin_date_ina($tgl_dari).' - '.jin_date_ina($tgl_sampai).'</span> 
			', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
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
			$jml_penarikan = 0;
			foreach ($penarikan as $row) {
				$anggota= $this->penarikan_m->get_data_anggota($row->anggota_id);
				$jns_simpan= $this->penarikan_m->get_jenis_simpan($row->jenis_id);

				$tgl_bayar = explode(' ', $row->tgl_transaksi);
				$txt_tanggal = jin_date_ina($tgl_bayar[0],'p');
				$jml_penarikan += $row->jumlah;

				// AG'.sprintf('%04d', $row->anggota_id).'
				$html .= '
				<tr>
					<td class="h_tengah" >'.$no++.'</td>
					<td class="h_tengah"> '.'TRK'.sprintf('%05d', $row->id).'</td>
					<td class="h_tengah"> '.$txt_tanggal.'</td>
					<td class="h_kiri"> '.$anggota->identitas.' - '.$anggota->nama.'</td>
					<td> '.$anggota->departement.'</td>
					<td> '.$jns_simpan->jns_simpan.'</td>
					<td class="h_kanan"> '.number_format($row->jumlah).'</td>
					<td> '.$row->user_name.'</td>
				</tr>';
			}
			$html .= '
			<tr>
				<td colspan="6" class="h_tengah"><strong> Jumlah Total </strong></td>
				<td class="h_kanan"> '.number_format($jml_penarikan).'</td>
				<td></td>
			</tr>
		</table>';
		$pdf->nsi_html($html);
		$pdf->Output('trans_sk'.date('Ymd_His') . '.pdf', 'I');
	}

	// Baru
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Penarikan Tunai <a href="'.site_url('penarikan').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = 'xls|xlsx';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_penarikan')) {
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


		$this->data['isi'] = $this->load->view('penarikan_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');
			if($this->penarikan_m->import_db($data_import)) {
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
			redirect('penarikan/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('penarikan/import');
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
		redirect('penarikan/import');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->penarikan_m->get_data_excel();
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
				<th>Jenis Penarikan</th>
				<th>Jumlah</th>
				<th>User</th>
			  </tr>
  		";
		foreach ($data['data'] as $r) {
			echo "
			<tr>
				<td>TRK".sprintf('%05d', $r->id)."</td>
				<td>$r->tgl_transaksi</td>
				<td>$r->identitas</td>
				<td>$r->anggota_nama</td>
				<td>$r->departement</td>
				<td>$r->jns_simpan</td>
				<td>$r->jumlah</td>
				<td>$r->user_name</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
	}
}