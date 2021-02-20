<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Pinjaman extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('pinjaman_m');
		$this->load->model('general_m');
		$this->load->model('angsuran_m');
		$this->load->model('bunga_m');
	}	

	public function index() {
		$this->data['judul_browser'] = 'Pinjaman';
		$this->data['judul_utama'] = 'Pinjaman';
		$this->data['judul_sub'] = 'Pinjaman <a href="'.site_url('pinjaman/import').'" class="btn btn-sm btn-success">Import Data</a>';
		
		$this->load->library('grocery_CRUD');

		$crud = new grocery_CRUD();
		$crud->set_table('tbl_pinjaman_h');
		$crud->set_subject('Data Pinjaman');
	
		$crud->fields('nomor_pinjaman','anggota_id', 'barang_id');		
		$crud->required_fields('nomor_pinjaman','anggota_id', 'barang_id');
		
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

		$this->data['kas_id'] = $this->pinjaman_m->get_data_kas();
		$this->data['jenis_ags'] = $this->pinjaman_m->get_data_angsuran();
		$this->data['suku_bunga'] = $this->pinjaman_m->get_data_bunga();
		$this->data['jenis_id'] = $this->general_m->get_id_pinjaman();
		$this->data['biaya'] = $this->pinjaman_m->get_biaya_adm();
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

		$this->data['barang_id'] = $this->pinjaman_m->get_id_barang();
		$this->data['jns_anggota'] = $this->general_m->get_jenis_anggota();
		
		$this->data['isi'] = $this->load->view('pinjaman_list_v', $this->data, TRUE);
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
		$data   = $this->pinjaman_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		$conf_bunga = $this->bunga_m->get_key_val();
		$i	= 0;
		$rows   = array(); 
		$nama_barang ="";
		$jenis_pinjaman = "";
		$jmlblntunggak = 0;
		foreach ($data['data'] as $r) {
			
			$tgl_bayar = explode(' ', $r->tgl_pinjam);
			$txt_tanggal = jin_date_ina($tgl_bayar[0],'p');
			$txt_tanggal .= ' - ' . substr($tgl_bayar[1], 0, 5);		
			//array keys ini = attribute 'field' di view nya
			$barang = $this->pinjaman_m->get_data_barang($r->barang_id);   
			if (empty($barang)) {
				$nama_barang = "";
			} else {
				$nama_barang = $barang->nm_barang;
			}

			$jpinjaman = $this->pinjaman_m->get_jenis_pinjaman($r->jenis_pinjaman);   
			if (empty($jpinjaman)) {
				$jenis_pinjaman = "";
			} else {
				$jenis_pinjaman = $jpinjaman->jns_pinjaman;
			}

			$anggota = $this->general_m->get_data_anggota($r->anggota_id);   
			$jml_bayar = $this->general_m->get_jml_bayar($r->id); 
			$jml_denda = $this->general_m->get_jml_denda($r->id); 

			//$total_tagihan = $r->tagihan + $jml_denda->total_denda; //total angsuran perbulan * jumlah bulan, by debaluk
			$total_tagihan = ($r->ags_per_bulan + $s_wajib->jumlah + $jml_denda->total_denda) * $r->lama_angsuran; 
			$sisa_tagihan = $total_tagihan - $jml_bayar->total;

			$sisa_angsur = 0;
			if($r->lunas == 'Belum') {
				$sisa_angsur = $r->lama_angsuran - $r->bln_sudah_angsur;
			}

			$total_tunggakan = 0;
			$tunggakan = 0;
			$denda_hari = $conf_bunga['denda_hari'];
			$jmlangscurrent = 0;
			if ($r->bln_sudah_angsur > 0) {
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
					
						//if ($jmlangscurrent > $r->bln_sudah_angsur) {
						//	$jmlblntunggak = $jmlangscurrent - $r->bln_sudah_angsur;
						//} 	
						$jmlblntunggak = $jmlangscurrent;
						break;
					} 
				}

				$tunggakan = ($r->ags_per_bulan + $s_wajib->jumlah) * $jmlblntunggak;
				if ($tunggakan > $jml_bayar->total){
					$total_tunggakan = $tunggakan - $jml_bayar->total;
				} else {
					$total_tunggakan = 0;
				}
				
			} else {
				$tunggakan = ($r->ags_per_bulan + $s_wajib->jumlah) * $r->selisih_bulan;
				if ($tunggakan > $jml_bayar->total){
					$total_tunggakan = $tunggakan - $jml_bayar->total;
				} else {
					$total_tunggakan = 0;
				}
			}
			

			$rows[$i]['id'] = $r->id;
			$rows[$i]['id_txt'] = $r->nomor_pinjaman;
			$rows[$i]['tgl_pinjam'] = $r->tgl_pinjam;
			$rows[$i]['tgl_pinjam_txt'] = $txt_tanggal;
			$rows[$i]['anggota_id'] = $r->anggota_id;
			$rows[$i]['anggota_id_txt'] = $anggota->ktp.' <br>'.$anggota->nama.' <br>'.$anggota->departement;
			$rows[$i]['namaanggota'] = $anggota->nama;
			$rows[$i]['barang_id'] = $r->barang_id;
			$rows[$i]['lama_angsuran'] = $r->lama_angsuran;
			$rows[$i]['lama_angsuran_txt'] = $r->lama_angsuran.' Bulan';
			$rows[$i]['bunga'] = $r->bunga;
			$rows[$i]['bunga_txt'] = $r->bunga;
			$rows[$i]['biaya_adm'] = $r->biaya_adm;
			$rows[$i]['nomor_pinjaman'] = $r->nomor_pinjaman;
			$rows[$i]['jenis_id'] = $r->jenis_pinjaman;
			$rows[$i]['plafond_pinjaman'] = $r->plafond_pinjaman;
			$rows[$i]['plafond_pinjaman_akun'] = $r->plafond_pinjaman_akun;
			$rows[$i]['angsuran_bulanan'] = $r->angsuran_per_bulan;
			$rows[$i]['nomor_pk'] = $r->no_perjanjian_kredit;
			$rows[$i]['rekening_tabungan'] = $r->nomor_rekening;
			$rows[$i]['nomor_pensiunan'] = $r->nomor_pensiunan;
			$rows[$i]['nama_vendor'] = $r->nama_vendor;
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
			$rows[$i]['jumlah'] = number_format(nsi_round($r->jumlah),2,',','.');
			$rows[$i]['hitungan'] = '<table>
						<tr>
							<td width="75px" align="left">Jenis Pinjaman</td> 
							<td width="10px" align="center"> : </td>
							<td width="100%" align="left">'.$jenis_pinjaman.'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Harga Plafond</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format($r->jumlah,2,',','.') .'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Lama Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.$r->lama_angsuran.' Bulan</td>
						</tr>
						<tr>
							<td width="75px" align="left">Pokok Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format($r->pokok_angsuran,2,',','.') .'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Bunga Pinjaman</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($r->bunga_pinjaman),2,',','.').'</td>
						</tr>
						<tr>
							<td width="75px" align="left">Simpanan Wajib</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format($s_wajib->jumlah,2,',','.') .'</td>
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
							<td width="75px" align="right">'.number_format(nsi_round($r->ags_per_bulan + $s_wajib->jumlah),2,',','.').
							'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Jumlah Denda</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($jml_denda->total_denda),2,',','.').'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Total Tagihan</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($total_tagihan),2,',','.').'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Sudah Dibayar</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($jml_bayar->total),2,',','.').'</td>
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
							<td width="75px" align="right">'.number_format(nsi_round($sisa_tagihan),2,',','.').'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Total Tunggakan</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="right">'.number_format(nsi_round($total_tunggakan),2,',','.').'</td>
						</tr>
						</table>';
			$rows[$i]['lunas'] = $r->lunas;
			$rows[$i]['user'] = $r->user_name;
			$rows[$i]['ket'] = $r->keterangan;
			$rows[$i]['kas_id'] = $r->kas_id;
			$rows[$i]['validasi_status'] = $r->validasi_status;
			$rows[$i]['detail'] ='<a href="'.site_url('angsuran_detail').'/index/' . $r->id . '" title="Detail"> <i class="fa fa-search"></i> Detail </a>
				&nbsp;
				<a href="'.site_url('cetak_pinjaman').'/cetak/' . $r->id . '"  title="Cetak Bukti Transaksi" target="_blank"> <i class="glyphicon glyphicon-print"></i> Nota </a>
				&nbsp;';
				
			$i++;
		}
	//keys total & rows wajib bagi jEasyUI
	$result = array('total'=>$data['count'],'rows'=>$rows);
	echo json_encode($result); //return nya json
	}

	function get_jenis_barang() {
		$id = $this->input->post('barang_id');
		$jenis_barang = $this->pinjaman_m->get_id_barang();
		foreach ($jenis_barang as $row) {
			if($row->id == $id) {
				echo number_format($row->harga,2,',','.');
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

		if($this->pinjaman_m->create($filename)){
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Data berhasil disimpan </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i> Gagal menyimpan data, pastikan nilai lebih dari <strong>0 (NOL)</strong>. </div>'));
		}
	}

	public function update($id=null) {
		if(!isset($_POST)) {
			show_404();
		}
		if($this->pinjaman_m->update($id)) {
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
		if($this->pinjaman_m->delete($id)) {
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
		if($this->pinjaman_m->validasi($id,$namaanggota)) {
			echo json_encode(array('ok' => true, 'msg' => '<div class="text-green"><i class="fa fa-check"></i> Validasi data berhasil </div>'));
		} else {
			echo json_encode(array('ok' => false, 'msg' => '<div class="text-red"><i class="fa fa-ban"></i>  Maaf, Validasi data gagal </div>'));
		}	
	}
	
	// Added by Gani
	function import() {
		$this->data['judul_browser'] = 'Import Data';
		$this->data['judul_utama'] = 'Import Data';
		$this->data['judul_sub'] = 'Pinjaman <a href="'.site_url('pinjaman').'" class="btn btn-sm btn-success">Kembali</a>';

		$this->load->helper(array('form'));

		if($this->input->post('submit')) {
			$config['upload_path']   = FCPATH . 'uploads/temp/';
			$config['allowed_types'] = '*';
			$this->load->library('upload', $config);

			if ( ! $this->upload->do_upload('import_pinjaman')) {
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

		
		$this->data['isi'] = $this->load->view('pinjaman_import_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}
	
	function import_db() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');
			
			if($this->pinjaman_m->import_db($data_import)) {
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
			redirect('pinjaman/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('pinjaman/import');
		}
	}
	
	function import_db_nasabah() {
		if($this->input->post('submit')) {
			
			$data_import = $this->input->post('val_arr');

			if($this->pinjaman_m->import_db_nasabah($data_import)) {
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
			redirect('pinjaman/import');
		} else {
			$this->session->set_flashdata('import', 'NO');
			redirect('pinjaman/import');
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
		redirect('pinjaman/import');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data   = $this->pinjaman_m->get_data_excel();
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
				<td>".number_format($r->jumlah,2,',','.')."</td>
				<td>$r->lama_angsuran</td>
				<td>".number_format($r->bunga,2,',','.')."</td>
				<td>".number_format($r->biaya_adm,2,',','.')."</td>
				<td>$r->lunas</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
	}
}
