<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Log_installment extends OperatorController {
	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('log_installment_m');
        $this->load->model('general_m');
        $this->load->model('angsuran_m');
        $this->load->model('pinjaman_m');
	}	

	public function index() {
		$this->data['judul_browser'] = 'Notifikasi Angsuran';
		$this->data['judul_utama'] = 'Notifikasi Angsuran';
		//$this->data['judul_sub'] = 'Angsuran <a href="'.site_url('log_installment/import').'" class="btn btn-sm btn-success">Import Data</a>';

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

		$this->data['kas_id'] = $this->log_installment_m->get_data_kas();
		$this->data['jenis_id'] = $this->general_m->get_id_simpanan();
		$this->data['jns_anggota'] = $this->general_m->get_jenis_anggota();

		$this->data['isi'] = $this->load->view('log_installment_v', $this->data, TRUE);
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
			$rows[$i]['kode_anggota'] = $r->no_anggota . '<br>' . $r->identitas;
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
		$cari_nama = isset($_POST['cari_nama']) ? $_POST['cari_nama'] : '';
		$cari_anggota = isset($_POST['cari_anggota']) ? $_POST['cari_anggota'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 
			'cari_nama' => $cari_nama,
			'cari_anggota' => $cari_anggota);
		$offset = ($offset-1)*$limit;
		$data   = $this->log_installment_m->get_data_transaksi_ajax($offset,$limit,$search,$sort,$order);
        $i	= 0;
        $vlebih_bayar = 0;
		$rows   = array(); 
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		$vangsuran = 0;
		foreach ($data['data'] as $r) {
			$tgl_pinjam = explode(' ', $r->tgl_pinjam);
			$vangsuran = $r->angsuran + $s_wajib->jumlah;
			$total_tagihan = ($r->angsuran + $s_wajib->jumlah) * $r->lama_angsuran;
			$anggota = $this->general_m->get_data_anggota($r->anggota_id);  
            $sdh_bayar = $this->pinjaman_m->get_jml_bayar($r->id);
            $kurang_bayar = $total_tagihan - $sdh_bayar;
            if ($kurang_bayar < 0) {
                $kurang_bayar = 0;
            }
            $lebih_bayar = $sdh_bayar;
            if ($sdh_bayar!= NULL || $sdh_bayar != "") {
                if ($lebih_bayar > $total_tagihan) {
                    $vlebih_bayar = $sdh_bayar - $total_tagihan;   
                } else {
                    $vlebih_bayar = 0;
                }
            } else {
                $vlebih_bayar = 0;
            }
            $date=date_create($r->tgl_pinjam);
            $date = date_format($date,"d-m-Y");
			$rows[$i]['id'] = $r->id;
			$rows[$i]['nomor_pinjaman'] =$r->nomor_pinjaman;
            $rows[$i]['tgl_pinjam'] = $date;
            $rows[$i]['identitas'] = $r->ktp;
			$rows[$i]['nama'] = $anggota->nama;
			if($r->lama_angsuran == '0'){
				$tenor = '-';
			}
			else{
				$tenor = $r->lama_angsuran;
			}
			$rows[$i]['tenor'] =$r->lama_angsuran;
			$rows[$i]['angsuran'] = number_format($vangsuran);
			$rows[$i]['total_tagihan'] = number_format($total_tagihan);
			$rows[$i]['sudah_bayar'] = number_format($sdh_bayar);
			$rows[$i]['kurang_bayar'] = number_format($kurang_bayar);
			$rows[$i]['lebih_bayar'] = number_format($vlebih_bayar);
		    $i++;
		}
		//keys total & rows wajib bagi jEasyUI
		$result = array('total'=>$data['count'],'rows'=>$rows);
		echo json_encode($result); //return nya json
	}

	function get_jenis_simpanan() {
		$id = $this->input->post('jenis_id');
		$jenis_simpanan = $this->general_m->get_id_simpanan();
		foreach ($jenis_simpanan as $row) {
			if($row->id == $id) {
				echo json_encode($row);
			}
		}
		exit();
	}


	function cetak_laporan() {
		$log = $this->log_installment_m->lap_data_log();
		if($log == FALSE) {
			//redirect('simpanan');
			echo 'DATA KOSONG<br>Pastikan Filter Tanggal dengan benar.';
			exit();
		}

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
		'.$pdf->nsi_box($text = '<span class="txt_judul">Log Notifikasi Angsuran <br></span>
			<span> </span> ', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
		<table width="100%" cellspacing="0" cellpadding="3" border="1" border-collapse= "collapse">
		<tr class="header_kolom">
			<th class="h_tengah" style="width:5%;" > No. </th>
			<th class="h_tengah" style="width:8%;"> Kode Transaksi</th>
			<th class="h_tengah" style="width:7%;"> Tanggal Pinjam </th>
			<th class="h_tengah" style="width:12%;"> Identitas </th>
			<th class="h_tengah" style="width:13%;"> Nama Anggota </th>
			<th class="h_tengah" style="width:5%;"> Tenor </th>
			<th class="h_tengah" style="width:10%;"> Angsuran  </th>
            <th class="h_tengah" style="width:10%;"> Total Tagihan </th>
            <th class="h_tengah" style="width:10%;"> Sudah Di Bayar </th>
            <th class="h_tengah" style="width:10%;"> Kurang Bayar </th>
            <th class="h_tengah" style="width:10%;"> Lebih Bayar </th>
		</tr>';

		$no =1;
		$vangsuran = 0;
        $s_wajib = $this->angsuran_m->get_simpanan_wajib();
		foreach ($log as $row) {
			$anggota= $this->log_installment_m->get_data_anggota($row->anggota_id);
			$sdh_bayar = $this->pinjaman_m->get_jml_bayar($row->id);
			$denda = $this->log_installment_m->get_jml_denda($row->nomor_pinjaman);
			$vangsuran = $r->angsuran + $s_wajib->jumlah;
            $total_tagihan = (($row->angsuran + $s_wajib->jumlah) + $denda->total_denda) * $row->lama_angsuran;
            $kurang_bayar = $total_tagihan - $sdh_bayar;
            if ($kurang_bayar < 0) {
                $kurang_bayar = 0;
            }
            $lebih_bayar = $sdh_bayar;
            if ($sdh_bayar!= NULL || $sdh_bayar != "") {
                if ($lebih_bayar > $total_tagihan) {
                    $vlebih_bayar = $sdh_bayar - $total_tagihan;   
                } else {
                    $vlebih_bayar = 0;
                }
            } else {
                $vlebih_bayar = 0;
            }
            $date=date_create($row->tgl_pinjam);
            $date = date_format($date,"d-m-Y");
			// '.'AG'.sprintf('%04d', $row->anggota_id).'
			$html .= '
			<tr>
				<td class="h_tengah" >'.$no++.'</td>
				<td class="h_tengah"> '.$row->nomor_pinjaman.'</td>
                <td class="h_tengah"> '.$date.'</td>
                <td class="h_tengah"> '.$anggota->ktp.'</td>
				<td class="h_kiri"> '.$anggota->nama.'</td>
				<td class="h_tengah"> '.$row->lama_angsuran.'</td>
				<td class="h_kanan"> '.number_format($vangsuran).'</td>
				<td class="h_kanan"> '.number_format($total_tagihan).'</td>
                <td class="h_kanan"> '.number_format($sdh_bayar).'</td>
                <td class="h_kanan"> '.number_format($kurang_bayar).'</td>
                <td class="h_kanan"> '.number_format($vlebih_bayar).'</td>
			</tr>';
		}
		$html .= '
	
		</table>';
		$pdf->nsi_html($html);
		$pdf->Output('trans_sp'.date('Ymd_His') . '.pdf', 'I');
	} 
	
	function export_excel(){

		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
        
        $kode_transaksi = isset($_POST['kode_transaksi']) ? $_POST['kode_transaksi'] : '';
		$cari_nama = isset($_POST['cari_nama']) ? $_POST['cari_nama'] : '';
		$cari_anggota = isset($_POST['cari_anggota']) ? $_POST['cari_anggota'] : '';
		$search = array('kode_transaksi' => $kode_transaksi, 
			'cari_nama' => $cari_nama,
			'cari_anggota' => $cari_anggota);
		$data   = $this->log_installment_m->get_data_excel($search);
		$i	= 0;
		$rows   = array(); 
		$vangsuran = 0;
        $s_wajib = $this->angsuran_m->get_simpanan_wajib();
		
		echo "
			<table border='1' cellpadding='5'>
            <tr class='header_kolom'>
                <th class='h_tengah' style='width:5%;' > No. </th>
                <th class='h_tengah' style='width:8%;'> Kode Transaksi</th>
                <th class='h_tengah' style='width:7%;'> Tanggal Pinjam </th>
                <th class='h_tengah' style='width:12%;'> Identitas </th>
                <th class='h_tengah' style='width:13%;'> Nama Anggota </th>
                <th class='h_tengah' style='width:5%;'> Tenor </th>
                <th class='h_tengah' style='width:10%;'> Angsuran  </th>
                <th class='h_tengah' style='width:10%;'> Total Tagihan </th>
                <th class='h_tengah' style='width:10%;'> Sudah Di Bayar </th>
                <th class='h_tengah' style='width:10%;'> Kurang Bayar </th>
                <th class='h_tengah' style='width:10%;'> Lebih Bayar </th>
		    </tr>
          ";
          $no=1;
		foreach ($data['data'] as $row) {
            $anggota= $this->log_installment_m->get_data_anggota($row->anggota_id);
			$sdh_bayar = $this->pinjaman_m->get_jml_bayar($row->id);
			$vangsuran = $row->angsuran + $s_wajib->jumlah;
            $total_tagihan = ($row->angsuran + $s_wajib->jumlah) * $row->lama_angsuran;
            $kurang_bayar = $total_tagihan - $sdh_bayar;
            if ($kurang_bayar < 0) {
                $kurang_bayar = 0;
            }
            $lebih_bayar = $sdh_bayar;
            if ($sdh_bayar!= NULL || $sdh_bayar != "") {
                if ($lebih_bayar > $total_tagihan) {
                    $vlebih_bayar = $sdh_bayar - $total_tagihan;   
                } else {
                    $vlebih_bayar = 0;
                }
            } else {
                $vlebih_bayar = 0;
            }
            $date=date_create($row->tgl_pinjam);
            $date = date_format($date,"d-m-Y");
			echo "
			<tr>
                <td class='h_tengah'>".$no++."</td>
                <td class='h_tengah'>".$row->nomor_pinjaman."</td>
                <td class='h_tengah'>".$date."</td>
                <td class='h_tengah'>".$anggota->ktp."</td>
                <td class='h_kiri'> ".$anggota->nama."</td>
                <td class='h_tengah'>".$row->lama_angsuran."</td>
                <td class='h_kanan'>".number_format($vangsuran)."</td>
                <td class='h_kanan'>".number_format($total_tagihan)."</td>
                <td class='h_kanan'>".number_format($sdh_bayar)."</td>
                <td class='h_kanan'>".number_format($kurang_bayar)."</td>
                <td class='h_kanan'>".number_format($vlebih_bayar)."</td>
			</tr>
			";
		}
		
		echo "</table>";
		
		die();
	}
}