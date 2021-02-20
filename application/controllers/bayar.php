<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Bayar extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('bayar_m');
		$this->load->model('general_m');
		$this->load->model('angsuran_m');
	}	

	public function index() {
		$this->data['judul_browser'] = 'Pinjaman';
		$this->data['judul_utama'] = 'Transaksi';
		$this->data['judul_sub'] = 'Pembayaran Angsuran <a href="'.site_url('bayar/import').'" class="btn btn-sm btn-success">Import Data</a>';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';
		//$this->data['js_files'][] = base_url() . 'assets/easyui/datagrid-detailview.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';
		#include seach
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';
		
		$this->data['jns_anggota'] = $this->general_m->get_jenis_anggota();

		$this->data['isi'] = $this->load->view('bayar_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}


	function ajax_list() {
		$this->load->model('bunga_m');
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl_pinjam';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$cari_anggota = isset($_POST['cari_anggota']) ? $_POST['cari_anggota'] : '';
		$cari_nama = isset($_POST['cari_nama']) ? $_POST['cari_nama'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array(
			'kode_transaksi' => $kode_transaksi, 
			'cari_anggota' => $cari_anggota, 
			'cari_nama' => $cari_nama, 
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai
			);
		$offset = ($offset-1)*$limit;
		$data   = $this->bayar_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$i	= 0;
		$rows   = array(); 
		$data_bunga_arr = $this->bunga_m->get_key_val();
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();

		foreach ($data['data'] as $r) {
			$tgl_pinjam = explode(' ', $r->tgl_pinjam);
			$txt_tanggal = jin_date_ina($tgl_pinjam[0],'p');		

			//array keys ini = attribute 'field' di view nya
			$anggota = $this->general_m->get_data_anggota($r->anggota_id);   

			$rows[$i]['id'] = $r->id;
			//$rows[$i]['id_txt'] ='TPJ' . sprintf('%05d', $r->id) . '';
			$rows[$i]['id_txt'] = $r->nomor_pinjaman;
			$rows[$i]['tgl_pinjam_txt'] = $txt_tanggal;
			//$rows[$i]['anggota_id'] ='AG' . sprintf('%04d', $r->anggota_id) . '';
			$rows[$i]['anggota_id'] = $anggota->ktp;
			$rows[$i]['anggota_id_txt'] = $anggota->nama;
			$rows[$i]['lama_angsuran_txt'] = $r->lama_angsuran.' Bulan';
			$rows[$i]['jumlah'] = number_format($r->jumlah,2,',','.');
			$rows[$i]['ags_pokok'] = number_format($r->pokok_angsuran,2,',','.');
			$rows[$i]['bunga'] = number_format($r->bunga_pinjaman,2,',','.');
			$rows[$i]['s_wajib'] = number_format($s_wajib->jumlah,2,',','.');
			$rows[$i]['angsuran_bln'] = number_format(nsi_round($r->pokok_angsuran + $r->bunga_pinjaman + $s_wajib->jumlah),2,',','.');
			// Jatuh Tempo
			$sdh_ags_ke = $r->bln_sudah_angsur;
			$ags_ke = $r->bln_sudah_angsur + 1;

			$denda_hari = $data_bunga_arr['denda_hari'];
			$tgl_pinjam = substr($r->tgl_pinjam, 0, 7) . '-01';
			$tgl_tempo = date('Y-m-d', strtotime("+".$ags_ke." months", strtotime($tgl_pinjam)));
			$tgl_tempo = substr($tgl_tempo, 0, 7) . '-' . sprintf("%02d", $denda_hari);
			$txt_status = '';
			$txt_status_tip = 'Ags Ke: ' . $ags_ke . ' Tempo: ' . $tgl_tempo;
			if($tgl_tempo < date('Y-m-d')) {
				$rows[$i]['merah'] = 1;
				$txt_status .= '<span title="'.$txt_status_tip.'" class="text-red"><i class="fa fa-warning"></i></span>';
			} else {
				$rows[$i]['merah'] = 0;
				$txt_status .= '<span title="'.$txt_status_tip.'" class="text-green"><i class="fa fa-check-circle" title="'.$txt_status_tip.'"></i></span>';
			}
			//$rows[$i]['status'] = $txt_status;

			$rows[$i]['bayar'] = '<br><p>'.$txt_status.' 
			<a href="'.site_url('angsuran').'/index/' . $r->id . '" title="Bayar Angsuran"> <i class="fa fa-money"></i> Bayar </a></p>';
			$i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}
	
	// Added by Gani
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Pembayaran Angsuran <a href="'.site_url('bayar').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_bayar')) {
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
										$header[$kolom] = 'Nomor Pinjaman';
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
				$ket="";
				foreach ($data_list_x as $data_kolom) {
					if((@$data_kolom['A'] == NULL || trim(@$data_kolom['A'] == '')) || (@$data_kolom['B'] == NULL || trim(@$data_kolom['B'] == '')) || (@$data_kolom['C'] == NULL || trim(@$data_kolom['C'] == '')) ) { continue; }
					foreach ($data_kolom as $kolom => $val) {
						if(in_array($kolom, array('A', 'B', 'C')) ) {
							$val = ltrim($val, "'");
						}
						if ($kolom == A) {
							$pinjamid = $this->bayar_m->get_data_by_nomor_pinjam($val);
							if (isset($pinjamid->id)) {
								$val = $val;
							} else {
								$ket = '<font color="red">Pinjaman '.$val.' tidak di temukan dan tidak akan di masukan ke dalam database</font>';
							}
						}
						if ($kolom == B) {
							$val = date('Y-m-d', strtotime($val));
						}
						if ($kolom == F) {
							if ($ket != "") {
								$val = $ket;
								$ket ="";
							} 
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


		$this->data['isi'] = $this->load->view('bayar_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');
			if($this->bayar_m->import_db($data_import)) {
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
			redirect('bayar/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('bayar/import');
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
		redirect('bayar/import');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->bayar_m->get_data_excel();
		$i	= 0;
		$rows   = array(); 
		
		
		echo "
			<table border='1' cellpadding='5'>
			  <tr>
				<th>Kode</th>
				<th>Tanggal Pinjam</th>
				<th>ID Anggota</th>
				<th>Nama Anggota</th>
				<th>Pokok Pinjaman</th>
				<th>Lama Pinjam</th>
				<th>Angsuran Pokok</th>
				<th>Bunga Angsuran</th>
				<th>Biaya Admin</th>
				<th>Angsuran Per Bulan</th>
			  </tr>
  		";
		foreach ($data['data'] as $r) {
			echo "
			<tr>
				<td>TPJ".sprintf('%05d', $r->id)."</td>
				<td>$r->tgl_pinjam</td>
				<td>$r->identitas</td>
				<td>$r->nama</td>
				<td>$r->jumlah</td>
				<td>$r->lama_angsuran</td>
				<td>$r->pokok_angsuran</td>
				<td>$r->bunga</td>
				<td>$r->biaya_adm</td>
				<td>$r->ags_per_bulan</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
	}
}
