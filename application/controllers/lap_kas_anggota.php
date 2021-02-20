<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_kas_anggota extends OPPController {
	public function __construct() {
			parent::__construct();	
			$this->load->helper('fungsi');
			$this->load->model('general_m');
			$this->load->model('lap_kas_anggota_m');
			$this->load->model('angsuran_m');
		}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Data Kas Anggota';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		#include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

			#include seach
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';
 
		$config = array();
		$config["base_url"] = base_url() . "lap_kas_anggota/index/halaman";
		$jumlah_row = $this->lap_kas_anggota_m->get_jml_data_anggota();
		if(isset($_GET['anggota_id']) && $_GET['anggota_id'] > 0) {
			$jumlah_row = 1;
		}
		$config["total_rows"] = $jumlah_row; // banyak data
		$config["per_page"] = 10;
		$config["uri_segment"] = 4;
		$config['use_page_numbers'] = TRUE;

		$config['full_tag_open'] = '<ul class="pagination">';
		$config['full_tag_close'] = '</ul>';

		$config['first_link'] = '&laquo; First';
		$config['first_tag_open'] = '<li class="prev page">';
		$config['first_tag_close'] = '</li>';

		$config['last_link'] = 'Last &raquo;';
		$config['last_tag_open'] = '<li class="next page">';
		$config['last_tag_close'] = '</li>';

		$config['next_link'] = 'Next &rarr;';
		$config['next_tag_open'] = '<li class="next page">';
		$config['next_tag_close'] = '</li>';

		$config['prev_link'] = '&larr; Previous';
		$config['prev_tag_open'] = '<li class="prev page">';
		$config['prev_tag_close'] = '</li>';

		$config['cur_tag_open'] = '<li class="active"><a href="">';
		$config['cur_tag_close'] = '</a></li>';

		$config['num_tag_open'] = '<li class="page">';
		$config['num_tag_close'] = '</li>';

		$this->pagination->initialize($config);
		$offset = ($this->uri->segment(4)) ? $this->uri->segment(4) : 0;
		if($offset > 0) {
			$offset = ($offset * $config['per_page']) - $config['per_page'];
		}
		$this->data["control"]=$this;
		$this->data["data_anggota"] = $this->lap_kas_anggota_m->get_data_anggota($config["per_page"], $offset); // panggil seluruh data aanggota
		$this->data["halaman"] = $this->pagination->create_links();
		$this->data["offset"] = $offset;
		$this->data["s_wajib"] = $this->angsuran_m->get_simpanan_wajib();
		$this->data["data_jns_simpanan"] = $this->lap_kas_anggota_m->get_jenis_simpan(); // panggil seluruh data simpanan
		
		$this->data['isi'] = $this->load->view('lap_kas_anggota_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);
	}


	function cetak_laporan() {
		$anggota = $this->lap_kas_anggota_m->lap_data_anggota();
		$data_jns_simpanan = $this->lap_kas_anggota_m->get_jenis_simpan();
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		if($anggota == FALSE) {
			redirect('lap_kas_anggota');
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
             .txt_judul {font-size: 15pt; font-weight: bold; padding-bottom: 12px;}
             .header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
         </style>
         '.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Data Kas Anggota <br></span>', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
         <table width="100%" cellspacing="0" cellpadding="3" border="1" nobr="true">
         <tr class="header_kolom">
         	<th style="width:3%;" > No </th>
            <th class="header_tengah" style="width:5%;"> Photo</th>
            <th style="width:20%;"> Identitas  </th>
            <th style="width:35%;"> Saldo Simpanan </th>
			<th style="width:18%;"> Tagihan Kredit </th>
			<th style="width:19%;"> Keterangan</th>
         </tr>';
			$no =1;
			$batas = 1;
			foreach ($anggota as $row) {
				if($batas == 0) {
					$html .= '
					<tr class="header_kolom" pagebreak="false">
		            <th style="width:3%;" > No </th>
		            <th class="header_tengah" style="width:5%;"> Photo</th>
		            <th style="width:20%;"> Identitas  </th>
		            <th style="width:37%;"> Saldo Simpanan </th>
					<th style="width:18%;"> Tagihan Kredit </th>
					<th style="width:17%;"> Keterangan </th>
	            </tr>';
	            $batas = 1;
				}
				$batas++;
			
			//pinjaman
			$pinjaman = $this->lap_kas_anggota_m->get_data_pinjam($row->id);
			$pinjam_id = @$pinjaman->id;

			//denda
			$denda = $this->lap_kas_anggota_m->get_jml_denda($pinjam_id);
			$tagihan= ((@$pinjaman->ags_per_bulan + $s_wajib->jumlah) * @$pinjaman->lama_angsuran) + $denda->total_denda;
			//$tagihan= @$pinjaman->tagihan + $denda->total_denda;

			$peminjam_tot = $this->lap_kas_anggota_m->get_peminjam_tot($row->id);
			$peminjam_lunas = $this->lap_kas_anggota_m->get_peminjam_lunas($row->id);
			
			$tgl_tempo = explode(' ', @$pinjaman->tempo);
			$tgl_tempo_txt = jin_date_ina($tgl_tempo[0],'p');
			$tgl_tempo_r = $tgl_tempo[0];

			$tgl_tempo_rr = explode('-', $tgl_tempo_r);
			$thn = $tgl_tempo_rr[0];
			$bln = @$tgl_tempo_rr[1];

			//dibayar
			$dibayar = $this->lap_kas_anggota_m->get_jml_bayar($pinjam_id);
			$sisa_tagihan = $tagihan - $dibayar->total;

			if ((@$pinjaman->lunas == 'Belum') && (date('m') > $bln )) {
				$data = 'Macet';
			} else {
				$data = 'Lancar';
			}

			//photo
			$photo_w = 3 * 12;
			$photo_h = 4 * 12;
			if($row->file_pic == '') {
				$photo ='<img src="'.base_url().'assets/theme_admin/img/photo.jpg" alt="default" width="'.$photo_w.'" height="'.$photo_h.'" />';
			} else {
				$photo= '<img src="'.base_url().'uploads/anggota/' . $row->file_pic . '" alt="Foto" width="'.$photo_w.'" height="'.$photo_h.'" />';
			}

			//jk
			if ($row->jk == "L") {
				$jk="Laki-Laki"; 
			} else {
				$jk="Perempuan"; 
			}

			//jabatan
			if ($row->jabatan_id == "1") {
				$jabatan="Pengurus";
			} else {
				$jabatan="Anggota"; 
			}
			// AG'.sprintf('%04d', $row->id).'
         $html .= '
         <tr nobr="true">
				<td class="h_tengah" style="vertical-align: middle ">'.$no++.' </td>
				<td class="h_tengah" style="vertical-align: middle ">'.$photo.'</td>
				<td> 
				<table>
					<tr>
						<td><strong> '.$row->nama.'</strong></td>
					</tr>
					<tr>
						<td> '.$row->ktp.' </td>
					</tr>
					<tr>
						<td> '.$jk.' </td>
					</tr>
					<tr>
						<td> '.$jabatan.' - '.$row->departement.'</td>
					</tr>
					<tr>
						<td> '.$row->alamat.' Telp. '.$row->notelp.' </td>
					</tr>
				</table>
				</td>
				<td> 
					<table >';
					$simpanan_arr = array();
					$simpanan_row_total = 0; 
					foreach ($data_jns_simpanan as $jenis) {
						$simpanan_arr[$jenis->id] = $jenis->jns_simpan;
						$nilai_s = $this->lap_kas_anggota_m->get_jml_simpanan($jenis->id, $row->id);
						$nilai_p = $this->lap_kas_anggota_m->get_jml_penarikan($jenis->id, $row->id);	
						$simpanan_row=$nilai_s->jml_total - $nilai_p->jml_total;
						$simpanan_row_total += $simpanan_row;
		$html.=' <tr>
						<td> '.$jenis->jns_simpan.'</td>
						<td class="h_kanan"> '. number_format($simpanan_row,2,',','.').'</td>
					</tr>';
					}
		$html.='<tr>
						<td> <strong>Total Simpanan</strong></td>
						<td class="h_kanan"><strong> '.number_format($simpanan_row_total,2,',','.').'</strong></td>
					</tr>
					</table>
				</td> 
				<td>
					<table> 
					<tr>
						<td> Pokok Pinjaman</td>
						<td class="h_kanan">'.number_format(@nsi_round($pinjaman->jumlah),2,',','.').'</td>
					</tr>
					<tr>
						<td> Total Tagihan </td> 
						<td class="h_kanan"> '.number_format(nsi_round($tagihan),2,',','.').' </td>
					</tr>
					<tr>
						<td> Dibayar </td>
						<td class="h_kanan"> '.number_format(nsi_round($dibayar->total),2,',','.').'</td></tr>
					<tr>
						<td> Sisa Tagihan </td>
						<td class="h_kanan"> <strong> '.number_format(nsi_round($sisa_tagihan),2,',','.').'</strong>
						</td>
					</tr>
				</table>
			</td>
			<td> 
				<table> 
							<tr>
								<td> Jumlah Pinjaman </td>
								<td class="h_kanan">'.$peminjam_tot.'</td>
							</tr>
							<tr>
								<td> Pinjaman Lunas </td>
								<td class="h_kanan">'.$peminjam_lunas.'</td>
							</tr>
							<tr>
								<td> Pembayaran</td>
								<td class="h_kanan"> <code>'.$data.'</code></td>
							</tr>
							<tr>
								<td> Tanggal Tempo</td>
								<td class="h_kanan"> <code>'.$tgl_tempo_txt.'</code></td>
							</tr>
				</table><br>
				<h4><u>Informasi Pinjaman</u></h4><br>
			</td>	
		</tr>	
						
		'; 
		}     
      $html .= '</table>';
      $pdf->nsi_html($html);
      $pdf->Output('lap_kas_agt'.date('Ymd_His') . '.pdf', 'I');
	} 
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");
		
		$data['data'] = $this->lap_kas_anggota_m->get_data_anggota_excel(); // panggil seluruh data aanggota
		$i	= 1;
		$rows   = array(); 
		$data["data_jns_simpanan"] = $this->lap_kas_anggota_m->get_jenis_simpan(); // panggil seluruh data simpanan
		$s_wajib = $this->angsuran_m->get_simpanan_wajib();
		
		echo "
			<table border='1' cellpadding='5'>
			  <tr>
				<th>No</th>
				<th>Identitas</th>
				<th>Saldo Simpanan</th>
				<th>Tagihan Kredit</th>
				<th>Keterangan</th>
			  </tr>
  		";
		foreach ($data['data'] as $is) {
			//pinjaman
			$pinjaman = $this->lap_kas_anggota_m->get_data_pinjam($is->id);
			$pinjam_id = @$pinjaman->id;
			$anggota_id = @$pinjaman->anggota_id;
			
			$jml_pj = $this->lap_kas_anggota_m->get_jml_pinjaman($anggota_id);
			$pj_anggota= @$jml_pj->total;
			
			//denda
			$denda = $this->lap_kas_anggota_m->get_jml_denda($pinjam_id);
			$tagihan= ((@$pinjaman->ags_per_bulan + $s_wajib->jumlah) * @$pinjaman->lama_angsuran) + $denda->total_denda;
			//$tagihan= @$pinjaman->tagihan + $denda->total_denda;
			//dibayar
			$dibayar = $this->lap_kas_anggota_m->get_jml_bayar($pinjam_id);
			$sisa_tagihan = $tagihan - $dibayar->total;

			$peminjam_tot = $this->lap_kas_anggota_m->get_peminjam_tot($is->id);
			$peminjam_lunas = $this->lap_kas_anggota_m->get_peminjam_lunas($is->id);

			$tgl_tempo = explode(' ', @$pinjaman->tempo);
			$tgl_tempo_txt = jin_date_ina($tgl_tempo[0],'p');
			$tgl_tempo_r = $tgl_tempo[0];

			$tgl_tempo_rr = explode('-', $tgl_tempo_r);
			$thn = $tgl_tempo_rr[0];
			$bln = @$tgl_tempo_rr[1];
			
			if ((@$pinjaman->lunas == 'Belum') && (date('m') > $bln )) {
				$datas = 'Macet';
			} else {
				$datas = 'Lancar';
			}
			
			if ($is->jk == "L") {
				$jk="Laki-Laki";
			} else {
				$jk="Perempuan"; 
			}
			
			if ($is->jabatan_id == "1") {
				$jabatan="Pengurus";
			} else {
				$jabatan="Anggota"; 
			}
			echo "
			<tr>
				<td>$i</td>
				<td>
					<table>
						<tr><td> ID Anggota : $is->ktp</td></tr>
						<tr><td> Nama : <b>$is->nama</b> </td></tr>
						<tr><td> Jenis Kelamin : $jk </td></tr>
						<tr><td> Jabatan : $jabatan - $is->departement</td></tr>
						<tr><td> Alamat  : $is->alamat Telp. $is->notelp </td></tr>
					</table>
				</td>
				<td>
				";
				
				$simpanan_arr = array();
				$simpanan_row_total = 0; 
				$simpanan_total = 0; 
				foreach ($data['data_jns_simpanan'] as $jenis) {
					$simpanan_arr[$jenis->id] = $jenis->jns_simpan;
					$nilai_s = $this->lap_kas_anggota_m->get_jml_simpanan($jenis->id, $is->id);
					$nilai_p = $this->lap_kas_anggota_m->get_jml_penarikan($jenis->id, $is->id);
					
					$simpanan_row=$nilai_s->jml_total - $nilai_p->jml_total;
					$simpanan_row_total += $simpanan_row;
					$simpanan_total += $simpanan_row_total;

					// detail transaksi user

					$transaksi_user=$this->lap_kas_anggota_m->get_data_transaksi('1');

					echo'<table style="width:100%;">
							<tr>
								<td>'.$jenis->jns_simpan.'</td>
								<td class="h_kanan">'. number_format($simpanan_row,2,',','.').'</td>
							</tr>';
					}
					echo '<tr>
								<td><strong> Jumlah Simpanan </strong></td>
								<td class="h_kanan"><strong> '.number_format($simpanan_row_total,2,',','.').'</strong></td>
							</tr>
							</table>';
					echo '		
					<td>
						<table style="width:100%;"> 
							<tr>
								<td> Pokok Pinjaman</td>
								<td class="h_kanan">'.number_format(@nsi_round($pinjaman->jumlah),2,',','.').'</td>
							</tr>
							<tr>
								<td> Tagihan + Denda </td> 
								<td class="h_kanan"> '.number_format(nsi_round($tagihan),2,',','.').' </td>
							</tr>
							<tr>
								<td> Dibayar </td>
								<td class="h_kanan"> '.number_format(nsi_round($dibayar->total),2,',','.').'</td>
							</tr>
							<tr>
								<td><strong> Sisa Tagihan</strong></td>
								<td class="h_kanan"> <strong>'.number_format(nsi_round($sisa_tagihan),2,',','.').'</strong></td>
							</tr>
						</table>
					</td>
					<td> 
						<table style="width:100%;"> 
							<tr>
								<td> Jumlah Pinjaman </td>
								<td class="h_kanan">'.$peminjam_tot.'</td>
							</tr>
							<tr>
								<td> Pinjaman Lunas </td>
								<td class="h_kanan">'.$peminjam_lunas.'</td>
							</tr>
							<tr>
								<td> Pembayaran</td>
								<td class="h_kanan"> <code>'.$datas.'</code></td>
							</tr>
							<tr>
								<td> Tanggal Tempo</td>
								<td class="h_kanan"> <code>'.$tgl_tempo_txt.'</code></td>
							</tr>
						</table><br>
						<h4><u>Informasi Pinjaman</u></h4><br>
						';

						foreach($transaksi_user['data'] as $tu){ $barang=$this->lap_kas_anggota_m->get_data_barang($tu->barang_id);

						echo '<table>
						<tr>
							<td width="100px" align="left">Nama Barang</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.$barang->nm_barang.'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Harga Barang</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">Rp. '.number_format($tu->jumlah).'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Lama Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.$tu->lama_angsuran.' Bulan</td>
						</tr>
						<tr>
							<td width="100px" align="left">Provisi</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.$tu->provinsi.'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Pokok Angsuran</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.number_format($tu->pokok_angsuran,2,',','.') .'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Bunga Pinjaman</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.number_format(nsi_round($tu->bunga_pinjaman),2,',','.').'</td>
						</tr>
						<tr>
							<td width="100px" align="left">Biaya Admin</td> 
							<td width="10px" align="center"> : </td>
							<td width="75px" align="left">'.number_format($tu->biaya_adm,2,',','.') .'</td>
						</tr>
						<tr><td colspan="3">==============================<td></trd>
						</table>';

						}

						'
					</td>
				</tr>';
			$i++;
		}
		
		echo "</table>";
		
		die();
	}

}