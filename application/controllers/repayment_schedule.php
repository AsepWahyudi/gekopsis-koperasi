<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class repayment_schedule extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('repayment_schedule_m');
		$this->load->model('general_m');
        $this->load->model('angsuran_m');
        $this->load->model('bunga_m');
	}	

	public function index() {
		$this->data['judul_browser'] = 'Repayment Schedule';
		$this->data['judul_utama'] = 'Pinjaman';
		$this->data['judul_sub'] = 'Repayment Schedule <a href="'.site_url('repayment_schedule/import').'" class="btn btn-sm btn-success">Import Data</a>';
		
		$this->load->library('grocery_CRUD');

		$crud = new grocery_CRUD();
		$crud->set_table('repayment_schedule_h');
		$crud->set_subject('Repayment Schedule');
	
		$crud->fields('nomor_pinjaman','anggota_id');		
		$crud->required_fields('nomor_pinjaman','anggota_id');
		
		$this->db->_protect_identifiers = FALSE;
		
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

		$this->data['kas_id'] = $this->repayment_schedule_m->get_data_kas();
		$this->data['jenis_ags'] = $this->repayment_schedule_m->get_data_angsuran();
		$this->data['suku_bunga'] = $this->repayment_schedule_m->get_data_bunga();
		$this->data['jenis_id'] = $this->general_m->get_id_pinjaman();
		$this->data['biaya'] = $this->repayment_schedule_m->get_biaya_adm();
		$this->data['plafond_pinjaman_akun'] = $this->general_m->get_id_akun();
		$this->data['biaya_asuransi_akun'] = $this->general_m->get_id_akun();
		$this->data['biaya_adm_akun'] = $this->general_m->get_id_akun();
		$this->data['biaya_materai_akun'] = $this->general_m->get_id_akun();
		$this->data['simpanan_pokok_akun'] = $this->general_m->get_id_akun();
		$this->data['pokok_bulan_satu_akun'] = $this->general_m->get_id_akun();
		$this->data['bunga_bulan_satu_akun'] = $this->general_m->get_id_akun();
		$this->data['pokok_bulan_dua_akun'] = $this->general_m->get_id_akun();
		$this->data['bunga_bulan_dua_akun'] = $this->general_m->get_id_akun();
		$this->data['simpanan_wajib_akun'] = $this->general_m->get_id_akun();
		$this->data['pencairan_bersih_akun'] = $this->general_m->get_id_akun();
		$this->data['jenis_cabang'] = $this->general_m->get_data_cabang();
		$this->data['jns_anggota'] = $this->general_m->get_jenis_anggota();
		
		$this->data['isi'] = $this->load->view('repayment_schedule_v', $this->data, TRUE);
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

	function get_jenis_pinjaman() {
		$id = $this->input->post('jenis_id');
		$jenis_simpanan = $this->general_m->get_id_pinjaman();
		foreach ($jenis_simpanan as $row) {
			if($row->id == $id) {
				echo json_encode($row);
			}
		}
		exit();
	}

	function get_jenis_akun() {
		$id = $this->input->post('plafond_pinjaman_akun');
		$jenis_akun = $this->general_m->get_id_akun();
		foreach ($jenis_akun as $row) {
			if($row->jns_akun_id == $id) {
				echo json_encode($row);
			}
		}
		exit();
	}

	function get_jenis_cabang() {
		$id = $this->input->post('jenis_cabang');
		$jenis_cabang = $this->general_m->get_data_cabang();
		foreach ($jenis_cabang as $row) {
			if($row->jns_cabangid == $id) {
				echo json_encode($row);
			}
		}
		exit();
	}

	function get_anggota_by_id() {
		$id = isset($_POST['anggota_id']) ? $_POST['anggota_id'] : '';
		$r   = $this->general_m->get_data_anggota($id);
		$out = '';
		$photo_w = 3 * 30;
		$photo_h = 4 * 30;
		if($r->file_pic == '') {
			$out ='<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="'.$photo_w.'" height="'.$photo_h.'" />'
			.'<br> ID : '.'AG' . sprintf('%04d', $r->id) . '';
		} else {
			$out = '<img src="'.base_url().'uploads/anggota/' . $r->file_pic . '" alt="Foto" width="'.$photo_w.'" height="'.$photo_h.'" />'
			.'<br> ID : '.'AG' . sprintf('%04d', $r->id) . '';
		}
		echo $out;
		exit();
	}

	function ajax_list() {
		/*Default request pager params dari jeasyUI*/
		$offset = isset($_POST['page']) ? intval($_POST['page']) : 1;
		$limit  = isset($_POST['rows']) ? intval($_POST['rows']) : 10;
		$sort  = isset($_POST['sort']) ? $_POST['sort'] : 'tgl_pinjam';
		$order  = isset($_POST['order']) ? $_POST['order'] : 'desc';
		$kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$cari_status = isset($_POST['cari_status']) ? $_POST['cari_status'] : '';
		$cari_anggota = isset($_POST['cari_anggota']) ? $_POST['cari_anggota'] : '';
		$cari_nama = isset($_POST['cari_nama']) ? $_POST['cari_nama'] : '';
		$tgl_dari = isset($_POST['tgl_dari']) ? $_POST['tgl_dari'] : '';
		$tgl_sampai = isset($_POST['tgl_sampai']) ? $_POST['tgl_sampai'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 
			'cari_status' => $cari_status,
			'cari_anggota' => $cari_anggota,
			'cari_nama' => $cari_nama,
			'tgl_dari' => $tgl_dari, 
			'tgl_sampai' => $tgl_sampai);
		$offset = ($offset-1)*$limit;
		$data   = $this->repayment_schedule_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		$i	= 0;
		$rows   = array(); 
		$nama_barang ="";
		$jenis_pinjaman = "";
		$conf_bunga = $this->bunga_m->get_key_val();
		foreach ($data['data'] as $r) {
			$tgl_bayar = explode(' ', $r->tgl_pinjam);
			$txt_tanggal = jin_date_ina($tgl_bayar[0],'p');
			$txt_tanggal .= ' - ' . substr($tgl_bayar[1], 0, 5);		
			$jpinjaman = $this->repayment_schedule_m->get_jenis_pinjaman($r->jenis_pinjaman);   
			if (empty($jpinjaman)) {
				$jenis_pinjaman = "";
			} else {
				$jenis_pinjaman = $jpinjaman->jns_pinjaman;
			}

			$anggota = $this->general_m->get_data_anggota($r->anggota_id);   
			$jml_bayar = $this->repayment_schedule_m->get_jml_bayar($r->id); 
			$jml_denda = $this->general_m->get_jml_denda($r->id); 
            $total_tagihan = (round($r->pokok_angsuran) + $r->bunga_pinjaman + $r->simpanan_wajib ) * $r->lama_angsuran; 
			$sisa_tagihan = $total_tagihan - $jml_bayar;

			$sisa_angsur = 0;
			if($r->lunas == 'Belum') {
				$sisa_angsur = $r->lama_angsuran - $r->bln_sudah_angsur;
            }
            
			$denda_hari = $conf_bunga['denda_hari'];
            for ($z=1; $z <= $r->lama_angsuran; $z++) { 
                $tgl = date("d", strtotime($r->tgl_pinjam));
                $bln = date("m", strtotime($r->tgl_pinjam));
                $thn = date("Y", strtotime($r->tgl_pinjam));
                $tglpinjam = $thn.'-'.$bln.'-'.$denda_hari;
                $tgl_tempo_var = $tglpinjam;
                $tgl_tempo = date("Y-m-d", strtotime($tgl_tempo_var . " +".$z." month"));
                $date_now = date("Y-m-d");
                if(date("m",strtotime($tgl_tempo)) == date("m",strtotime($date_now))){
                    if($date_now > $tgl_tempo){
                        $jmlangscurrent = $z;
                    } else {
                        $jmlangscurrent = $z -1;
                    } 
                    break;
                } 
            }
           
			$total_tunggakan = 0;
			$tunggakan = 0;
			if ($r->bln_sudah_angsur != 0) {
                if ($jmlangscurrent > $r->bln_sudah_angsur){
                    $jmlangscurrent = $jmlangscurrent - $r->bln_sudah_angsur;
                    $tunggakan = ($r->ags_per_bulan + $s_wajib->jumlah) * $jmlangscurrent;
                } else {
                    $tunggakan = ($r->ags_per_bulan + $s_wajib->jumlah) * $r->bln_sudah_angsur;
                }
				
				if ($tunggakan > $jml_bayar){
					$total_tunggakan = $tunggakan - $jml_bayar;
				} else {
					$total_tunggakan = 0;
				}
			} else {
				$tunggakan = ($r->ags_per_bulan + $s_wajib->jumlah) * $jmlangscurrent;
				if ($tunggakan > $jml_bayar){
					$total_tunggakan = $tunggakan - $jml_bayar;
				} else {
					$total_tunggakan = 0;
				}
			}

			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] = $r->nomor_pinjaman;
			$rows[$i]['tgl_pinjam'] = date('d-m-Y',strtotime($r->tgl_pinjam));
			$rows[$i]['tgl_pinjam_txt'] = $txt_tanggal;
			$rows[$i]['anggota_id'] = $r->anggota_id;
			$rows[$i]['anggota_id_txt'] = $anggota->ktp.' <br>'.$anggota->nama.' <br>'.$anggota->departement;
			$rows[$i]['namaanggota'] = $anggota->nama;
			$rows[$i]['lama_angsuran'] = $r->lama_angsuran;
			$rows[$i]['lama_angsuran_txt'] = $r->lama_angsuran.' Bulan';
			$rows[$i]['bunga'] = $r->bunga;
			$rows[$i]['bunga_txt'] = $r->bunga;
			$rows[$i]['nomor_pinjaman'] = $r->nomor_pinjaman;
			$rows[$i]['jenis_id'] = $r->jenis_pinjaman;
			$rows[$i]['plafond_pinjaman'] = $r->plafond_pinjaman;
			$rows[$i]['plafond_pinjaman_akun'] = $r->plafond_pinjaman_akun;
			$rows[$i]['angsuran_bulanan'] = $r->angsuran_per_bulan;
			$rows[$i]['nomor_pk'] = $r->no_perjanjian_kredit;
			$rows[$i]['rekening_tabungan'] = $r->nomor_rekening;
			$rows[$i]['nomor_pensiunan'] = $r->nomor_pensiunan;
			$rows[$i]['biaya_asuransi'] = $r->biaya_asuransi;
			$rows[$i]['biaya_asuransi_akun'] = $r->biaya_asuransi_akun;
			$rows[$i]['biaya_adm_akun'] = $r->biaya_administrasi_akun;
			$rows[$i]['biaya_materai'] = $r->biaya_materai;
			$rows[$i]['biaya_materai_akun'] = $r->biaya_materai_akun;
			$rows[$i]['simpanan_pokok'] = $r->simpanan_pokok;
			$rows[$i]['simpanan_pokok_akun'] = $r->simpanan_pokok_akun;
			$rows[$i]['pokok_bulan_satu'] = $r->pokok_bulan_satu;
			$rows[$i]['pokok_bulan_satu_akun'] = $r->pokok_bulan_satu_akun;
			$rows[$i]['bunga_bulan_satu'] = $r->bunga_bulan_satu;
			$rows[$i]['bunga_bulan_satu_akun'] = $r->bunga_bulan_satu_akun;
			$rows[$i]['pokok_bulan_dua'] = $r->pokok_bulan_dua;
			$rows[$i]['pokok_bulan_dua_akun'] = $r->pokok_bulan_dua_akun;
			$rows[$i]['bunga_bulan_dua'] = $r->bunga_bulan_dua;
			$rows[$i]['bunga_bulan_dua_akun'] = $r->bunga_bulan_dua_akun;
			$rows[$i]['pencairan_bersih'] = $r->pencairan_bersih;
			$rows[$i]['simpanan_wajib'] = $r->simpanan_wajib;
			$rows[$i]['simpanan_wajib_akun'] = $r->simpanan_wajib_akun;
			$rows[$i]['jenis_cabang'] = $r->jns_cabangid;
			$rows[$i]['jumlah'] = number_format(nsi_round($r->jumlah));
			$rows[$i]['hitungan'] = '<table>
						<tr>
							<td width="75px" align="left">Jenis Pinjaman</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.$jenis_pinjaman.'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Harga Plafond</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format($r->jumlah) .'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Lama Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.$r->lama_angsuran.' Bulan</td>
						</tr>
						<tr>
							<td width="75px" align="left">Pokok Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format($r->pokok_angsuran) .'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Bunga Pinjaman</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($r->bunga_pinjaman)).'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Simpanan Wajib</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format($s_wajib->jumlah) .'</td>
						</tr>
						<tr>
							<td width="75px" align="left">File</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right"><a href="'.base_url('uploads/pinjaman/'.$r->file).'">Files Embed</a></td>
						</tr>
						</table>';
			$rows[$i]['tagihan'] = '<table>
						<tr>
							<td width="100px" align="left">Jumlah Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($r->pokok_angsuran + $r->bunga_pinjaman + $r->simpanan_wajib)).
							'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Jumlah Denda</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($jml_denda->total_denda)).'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Total Tagihan</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($total_tagihan)).'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Sudah Dibayar</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round(0)).'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Sisa Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.$sisa_angsur.
							'</td>
						</tr>						
						<tr>
							<td width="100px" align="left">Sisa Tagihan</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($sisa_tagihan)).'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Total Tunggakan</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round(0)).'</td>
						</tr>
						</table>';
			$rows[$i]['lunas'] = $r->lunas;
			$rows[$i]['user'] = $r->user_name;
			$rows[$i]['ket'] = $r->keterangan;
			$rows[$i]['kas_id'] = $r->kas_id;
			$rows[$i]['detail'] ='<a href="'.site_url('repayment_detail').'/index/' . $r->id . '" title="Detail"> <i class="fa fa-search"></i> Detail </a>
                &nbsp;
				';
				
			$i++;
		}
        $result = array('total'=>$data['count'],'rows'=>$rows);
        echo json_encode($result); //return nya json
	}

	function get_jenis_barang() {
		$id = $this->input->post('barang_id');
		$jenis_barang = $this->repayment_schedule_m->get_id_barang();
		foreach ($jenis_barang as $row) {
			if($row->id == $id) {
				echo number_format($row->harga);
			}
		}
		exit();
	}

	

	public function create(){

		if(!isset($_POST)) {
			show_404();
		}

		/* Getting file name */
		$filename = $_FILES['file']['name'];
		$filename = md5(date("Y-m-d H:i:s")).$filename;
		/* Location */
		$location = "uploads/pinjaman/".$filename;
		$uploadOk = 1;
		$imageFileType = pathinfo($location,PATHINFO_EXTENSION);
		if($uploadOk == 0){
		   echo 0;
		}else{
		   /* Upload file */
		   if(move_uploaded_file($_FILES['file']['tmp_name'],$location)){
		      
		   }else{
		      
		   }
		}

		if($this->repayment_schedule_m->create($filename)){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Gagal menyimpan data, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}
	}

	public function update($id=null) {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->repayment_schedule_m->update($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil diubah </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Data gagal diubah </div>'));
		}	
	}

	public function delete() {
		if(!isset($_POST))	{
			show_404();
		}

		$id = intval(addslashes($_POST['id']));
		if($this->repayment_schedule_m->delete($id)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil dihapus </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Maaf, Data gagal dihapus </div>'));
		}
	}

	public function validasi() {
		if(!isset($_POST)) {
			show_404();
		}
		$id = intval(addslashes($_POST['id']));
		$namaanggota = $_POST['namaanggota'];
		if($this->repayment_schedule_m->validasi($id,$namaanggota)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Validasi data berhasil </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Validasi data gagal </div>'));
		}	
	}
	
	// Added by Gani
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Repayment Schedule <a href="'.site_url('repayment_schedule').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_repayment')) {
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
										$header[$kolom] = 'Tanggal Pinjam';
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

		
		$this->data['isi'] = $this->load->view('repayment_schedule_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');
			
			if($this->repayment_schedule_m->import_db($data_import)) {
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
			redirect('repayment_schedule/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('repayment_schedule/import');
		}
	}
	
	function import_db_nasabah() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');

			if($this->repayment_schedule_m->import_db_nasabah($data_import)) {
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
			redirect('repayment_schedule/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('repayment_schedule/import');
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
		redirect('repayment_schedule/import');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->repayment_schedule_m->get_data_excel();
		$i	= 0;
		$rows   = array(); 
		
		
		echo "
			<table border='1' cellpadding='5'>
			  <tr>
				<th>Kode</th>
				<th>Tanggal Pinjam</th>
				<th>Nama Anggota</th>
				<th>Jumlah</th>
				<th>Lama Angsuran</th>
				<th>Bunga</th>
				<th>Biaya Adm</th>
				<th>Lunas</th>
			  </tr>
  		";
		foreach ($data['data'] as $r) {
			echo "
			<tr>
				<td>PJ".sprintf('%05d', $r->id)."</td>
				<td>$r->tgl_pinjam</td>
				<td>$r->nama</td>
				<td>$r->jumlah</td>
				<td>$r->lama_angsuran</td>
				<td>$r->bunga</td>
				<td>$r->biaya_adm</td>
				<td>$r->lunas</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
    }
    
    function cetak($id) {
		$row = $this->pinjaman_m->get_data_pinjam($id);
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		$opsi_val_arr = $this->setting_m->get_key_val();

		foreach ($opsi_val_arr as $key => $value){
			$out[$key] = $value;
		}

		$this->load->library('Struk');
		$pdf = new Struk('P', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(false);
		$resolution = array(210, 140);
		$pdf->AddPage('L', $resolution);

		$html = '
		<style>
			.h_tengah {text-align: center;}
			.h_kiri {text-align: left;}
			.h_kanan {text-align: right;}
			.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 12px;}
			.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			.txt_content {font-size: 7pt; text-align: center;}
		</style>';
		$html .= ''.$pdf->nsi_box($text ='
			<table width="100%">
				<tr>
					<td colspan="2" class="h_kiri" class="txt_judul"><strong>'.$out['nama_lembaga'].'</strong>
					</td>
				</tr>
				<tr>
					<td class="h_kiri" width="100%">'.$out['alamat'].' Tel. '.$out['telepon'].'
						<hr width="100%"></td>
					</tr>
				</table>
				', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'left').'';

		$anggota= $this->general_m->get_data_anggota($row->anggota_id);

		$tgl_bayar = explode(' ', $row->tgl_pinjam);
		$txt_tanggal = jin_date_ina($tgl_bayar[0]);

		$tgl_tempo = explode(' ', $row->tempo);
		$tgl_tempo = jin_date_ina($tgl_tempo[0]); 

        // '.'AG'.sprintf('%05d', $row->anggota_id).'

		$html .='<div class="h_tengah"><strong>BUKTI PENCAIRAN DANA KREDIT </strong> <br> Ref. '.date('Ymd_His').'</div>
		<br> Telah terima dari <strong>'.$out['nama_lembaga'].'</strong>
		<br> Pada Tanggal '.jin_date_ina(date('Y-m-d')).' untuk realisasi kredit sebessar Rp. '.number_format($row->jumlah).' ('.$this->terbilang->eja(nsi_round($row->jumlah)).' RUPIAH) dengan rincian :
		<br>
		<table width="100%">   
			<tr>
				<td width="18%"> Nomor Pinjaman </td>
				<td width="2%">:</td>
				<td width="45%">'.$row->nomor_pinjaman.'</td>
			</tr>
			<tr>
				<td> Id Anggota </td>
				<td>:</td>
				<td>'.$anggota->ktp.'</td>
			</tr>
			<tr>
				<td> Nama Anggota </td>
				<td>:</td>
				<td>'.strtoupper($anggota->nama).'</td>
			</tr>
			<tr>
				<td> Dept </td>
				<td>:</td>
				<td>'.$anggota->departement.'</td>
			</tr>
			<tr>
				<td> Alamat </td>
				<td>:</td>
				<td>'.$anggota->alamat.'</td>
			</tr>
			<tr>
				<td> Tanggal Pinjam </td>
				<td>:</td>
				<td>'.$txt_tanggal.'</td>
			</tr>
			<tr>
				<td> Tanggal Tempo </td>
				<td>:</td>
				<td>'.$tgl_tempo.'</td>
			</tr>
			<tr>
				<td> Lama Pinjam </td>
				<td>:</td>
				<td>'.$row->lama_angsuran.' Bulan</td>
			</tr>
		</table>

		<br><br>
		<table width="100%">
			<tr>
				<td width="20%"> Total Pinjaman </td>
				<td width="7%">: Rp. </td>
				<td width="20%" class="h_kanan">'.number_format(nsi_round(($row->ags_per_bulan + $s_wajib->jumlah) * $row->lama_angsuran)).'</td>
			</tr>
			<tr>
				<td width="20%"> Pokok Pinjaman </td>
				<td width="7%">: Rp. </td>
				<td width="20%" class="h_kanan">'.number_format(nsi_round($row->jumlah)).'</td>
			</tr>
			<tr>
				<td> Angsuran Pokok </td>
				<td>: Rp. </td>
				<td class="h_kanan">'.number_format($row->pokok_angsuran).'</td>
			</tr>
			<tr>
				<td> Simpanan Wajib </td>
				<td>: Rp. </td>
				<td class="h_kanan">'.number_format($s_wajib->jumlah).'</td>
			</tr>
			<tr>
				<td> Biaya Admin </td>
				<td>: Rp. </td>
				<td class="h_kanan">'.number_format($row->biaya_adm).'</td>
			</tr>
			<tr>
				<td> Angsuran Bunga </td>
				<td>: Rp. </td>
				<td class="h_kanan">'.number_format($row->bunga_pinjaman).'</td>
			</tr>
			<tr>
				<td> <strong>Jumlah Angsuran </strong></td>
				<td><strong>: Rp. </strong></td>
				<td class="h_kanan"><strong>'.number_format(nsi_round($row->ags_per_bulan + $s_wajib->jumlah)).'</strong></td>
			</tr>
		</table> 
		<p>TERBILANG : '.$this->terbilang->eja(nsi_round($row->ags_per_bulan + $s_wajib->jumlah)).' RUPIAH</p>
		<table width="90%">
			<tr>
				<td height="50px"></td>
				<td class="h_tengah">'.$out['kota'].', '.jin_date_ina(date('Y-m-d')).'</td>
			</tr>
			<tr>
				<td class="h_tengah"> '.strtoupper($row->user_name).'</td>
				<td class="h_tengah">'.strtoupper($anggota->nama).'</td>
			</tr>
		</table>';
		$pdf->nsi_html($html);
		$pdf->Output(date('Ymd_His') . '.pdf', 'I');
	} 
}
