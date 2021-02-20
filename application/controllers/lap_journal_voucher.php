<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_journal_voucher extends AdminController {

	public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
        $this->load->model('journal_voucher_m');
	}	


	function cetak_laporan() {
		$header_journal = $this->journal_voucher_m->lap_data_journal();
		if($header_journal == FALSE) {
			echo 'DATA KOSONG<br>Pastikan Filter Tanggal dengan benar.';
			exit();
        }
        
            $tgl_dari = $_GET['tgl_dari']; 
		    $tgl_sampai = $_GET['tgl_sampai']; 

        if ($tgl_dari != "" && $tgl_sampai !="") {
            $tgl_dari = date('yy-m-d',strtotime($_GET['tgl_dari'])); 
		    $tgl_sampai = date('yy-m-d',strtotime($_GET['tgl_sampai'])); 
        }
		
		$cari_journalno = $_GET['cari_journalno']; 
		
		if ($cari_journalno == "") {
			$cari_journalno = "Journal : Semua";
		} else {
			$cari_journalno = "Journal : ". $cari_journalno ;
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
        '.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Journal Transaksi <br></span> <span> Periode '.$tgl_dari.' - '.$tgl_sampai.' | '.$cari_journalno.'</span> ', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
		<table width="100%" cellspacing="0" cellpadding="3" border="1">
            <tr class="header_kolom">
                <th style="width:3%;"> No</th>
				<th style="width:8%;"> Journal No</th>
				<th style="width:8%;"> Journal Date  </th>
				<th style="width:10%;"> Transaksi </th>
                <th style="width:15%;"> Keterangan  </th>
                <th style="width:15%;"> Akun  </th>
                <th style="width:10%;"> Debit  </th>
                <th style="width:10%;"> Kredit  </th>
                <th style="width:8%;"> Cabang  </th>
                <th style="width:10%;"> Notes  </th>
			</tr>';
		$no =1;
		$batas = 0;
		$total_pinjaman = 0;
		$total_denda = 0;
        $total_tagihan_debit = 0;
        $total_tagihan_credit = 0;
		$tot_sdh_dibayar = 0;
        $tot_sisa_tagihan = 0;
        $hjournalno = 0;
        $vjournalno = 0;
        $jnsakun = "";
        $jns_cabang= "";
        $hvoucherid = 0;
        $vvoucherid = 0;
        $vtotal = false;
       
		foreach ($header_journal as $r) {

            $total_tagihan_debit = 0;
            $total_tagihan_credit = 0;
            
            if ($r->headernote == "") {
                $r->headernote = "-";
            }
            $detail_journal = $this->journal_voucher_m->lap_detail_journal($r->journal_voucherid);
            foreach($detail_journal as $d) {

                if ($d->itemnote == "") {
                    $d->itemnote = "-";
                   }
        
                   $jnsakun = $this->general_m->get_jns_akun($d->jns_akun_id);
                   if ($jnsakun) {
                       foreach ($jnsakun as $rowakun) {
                           $jns_akun = $rowakun->nama_akun;
                       }    
                   } else {
                       $jns_akun = "-";
                   }
        
                   $jnscabang = $this->general_m->get_jns_cabang($d->jns_cabangid);  
                   if ($jnscabang) {
                       foreach ($jnscabang as $rowcabang) {
                           $jns_cabang = $rowcabang->nama_cabang;
                       }
                   } else {
                       $jns_cabang = "-";
                   }
        
                   $total_tagihan_debit += $d->debit;
                   $total_tagihan_credit += $d->credit;

                $html .= '
                <tr>
                    <td class="h_tengah">'.$no++.' </td>
                    <td class="h_tengah">'.$r->journal_no.' </td>
                    <td class="h_tengah">'.$r->journal_date.' </td>
                    <td class="h_tengah">'.$r->jns_transaksi.' </td>
                    <td class="h_tengah">'.$r->headernote.' </td>
                    <td class="h_tengah">'.$jns_akun.' </td>
                    <td class="h_kanan">'.number_format($d->debit,2,'.',',').' </td>
                    <td class="h_kanan">'.number_format($d->credit,2,'.',',').' </td>
                    <td class="h_tengah">'.$jns_cabang.' </td>
                    <td class="h_tengah">'.$d->itemnote.' </td>
                </tr>';
            }
           
            $html .= '
                            <tr class="header_kolom">
                            <td style="width:3%;" >  </td>
                            <td style="width:8%;"> </td>
                            <td style="width:8%;">   </td>
                            <td style="width:10%;">  </td>
                            <td style="width:15%;">   </td>
                            <td style="width:15%;" >Total</td>
                            <td style="width:10%;" class="h_kanan">'.number_format($total_tagihan_debit,2,'.',',').'</td>
                            <td style="width:10%;" class="h_kanan">'.number_format($total_tagihan_credit,2,'.',',').'</td>
                            <td style="width:8%;"></td>
                            <td style="width:10%;"></td>
                            </tr>';
            }
            

		
		$pdf->nsi_html($html);
		$pdf->Output('journal'.date('Ymd_His') . '.pdf', 'I');
    }

    function cetak_jv() {
		$header_journal = $this->journal_voucher_m->lap_jv();
		if($header_journal == FALSE) {
			echo 'DATA KOSONG<br>Pastikan data Journal benar.';
			exit();
        }

		//$cari_journalno = $_REQUEST['cari_journalno']; 
		
		//if ($cari_journalno != "") {
		//	$cari_journalno = "Journal : ". $cari_journalno ;
		//}

		$this->load->library('Pdf');
		$pdf = new Pdf('P', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
        $pdf->AddPage('P');

        $html = '';
        $html = '<br><br>';
        //header
        $html .= '<style>
        .h_tengah {text-align: center;}
        .h_kiri {text-align: left;}
        .h_kanan {text-align: right;}
        .txt_judul {font-size: 17pt; font-weight: bold; padding-bottom: 12px;}
        .header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
        .td {background-color: #4d4d4d;}
        </style>';
        foreach ($header_journal as $hdr) {
            if ($hdr->headernote != ""){
                $vhnote = $hdr->headernote;
            } else {
                $vhnote ="";
            }
            
            $hdate = date("d-M-Y", strtotime($hdr->journal_date));
            $html .= '<table width="100%" border="0">
                    <tr>
                        <td> 
                            '.$pdf->nsi_box($text = '<span class="txt_judul">Journal Voucher <br></span>', $width = '100%', $spacing = '0', $padding = '1', $border = '0', $align = 'center').'
                        </td>
                        <td class="h_tengah"> &nbsp; &nbsp; &nbsp;<b><font size="17px">'.$hdr->journal_no.' </font></b> <br><br>
                            JV DATE: '.$hdate .
                        '</td>
                    </tr>'; 
            $html .= '<tr>
                        <td colspan="2"> 
                            <table width="50%" border ="1">
                                <tr class="header_kolom">
                                    <td>Notes </td>
                                </tr>
                                <tr class="h_tengah">
                                    <td> '.$vhnote.'</td>
                                </tr>

                            </table>
                        </td>
                    </tr>';

        }
        $html .='</table><br><br>';

        //detail
		$html .= '
		<table width="100%" cellspacing="0" cellpadding="2" border="1" border-collapse="collapse">
            <tr class="header_kolom">
                <td style="width:10%;"> ACCOUNT NO#</td>
				<td style="width:22%;"> ACCOUNT NAME</td>
				<td style="width:22%;"> DESCRIPTION  </td>
				<td style="width:17%;"> CABANG </td>
                <td style="width:14%;"> DEBIT  </td>
                <td style="width:14%;"> CREDIT  </td>
			</tr>';
		$no =1;
		$batas = 0;
		$total_pinjaman = 0;
		$total_denda = 0;
        $total_tagihan_debit = 0;
        $total_tagihan_credit = 0;
		$tot_sdh_dibayar = 0;
        $tot_sisa_tagihan = 0;
        $hjournalno = 0;
        $vjournalno = 0;
        $jnsakun = "";
        $jns_cabang= "";
        $hvoucherid = 0;
        $vvoucherid = 0;
        $vtotal = false;
       
		foreach ($header_journal as $r) {
            
            if ($r->headernote == "") {
                $r->headernote = "-";
            }
            $detail_journal = $this->journal_voucher_m->lap_detail_jv($r->journal_voucherid);
            foreach($detail_journal as $d) {

                if ($d->itemnote == "") {
                    $d->itemnote = "-";
                   }
        
                   $jnsakun = $this->general_m->get_jns_akun($d->jns_akun_id);
                   if ($jnsakun) {
                       foreach ($jnsakun as $rowakun) {
                           $jns_akun = $rowakun->nama_akun;
                       }    
                   } else {
                       $jns_akun = "-";
                   }
        
                   if($d->nama_cabang != "") {
                        $jns_cabang = $d->nama_cabang;
                   } else {
                        $jns_cabang = "-";
                   }
                    
                   
        
                   $total_tagihan_debit += $d->debit;
                   $total_tagihan_credit += $d->credit;

                   $vorg = 0;
                   if ($d->debit != 0 && $d->credit == 0) {
                        $vorg = $d->debit;
                   } else if ($d->debit == 0 && $d->credit != 0) {
                        $vorg = $d->credit;
                   }


                $html .= '
                <tr>
                    <td class="h_tengah">'.$d->no_akun.' </td>
                    <td class="h_tengah">'.$d->nama_akun.' </td>
                    <td class="h_tengah">'.$d->itemnote.' </td>
                    <td class="h_tengah">'.$jns_cabang.' </td>
                    <td class="h_kanan">'.number_format($d->debit,2,'.',',').' </td>
                    <td class="h_kanan">'.number_format($d->credit,2,'.',',').' </td>
                </tr>';
            }
           
            $html .= '
                            <tr class="header_kolom">
                            <td style="width:71%;" collspan="5" class="h_kanan"><font size="12px">Total</font></td>
                            <td style="width:14%;" class="h_kanan">'.number_format($total_tagihan_debit,2,'.',',').'</td>
                            <td style="width:14%;" class="h_kanan" >'.number_format($total_tagihan_credit,2,'.',',').'</td>
                            </tr>';
            }
            $html .='</table>';

            $html .='<br><br>';
            $html .='<table width="100%" border="0">
            <tr>
                <td></td>
                <td class="h_tengah">Prepared By</td>
                <td class="h_tengah">Approved By</td>
            </tr>
            <tr >
                <td height="40px"></td>
            </tr>
            <tr>
                <td></td>
                <td class="h_tengah">...........................</td>
                <td class="h_tengah">...........................</td>
            </tr>
            </table>';
            

		
		$pdf->nsi_html($html);
		$pdf->Output('journal'.date('Ymd_His') . '.pdf', 'I');
    }

}