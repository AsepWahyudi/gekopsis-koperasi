<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_neraca extends OperatorController {

public function __construct() {
		parent::__construct();	
		$this->load->helper('fungsi');
		$this->load->model('general_m');
    $this->load->model('lap_neraca_m');
    $this->load->model('lap_laba_m');
	}	

	public function index() {
		$this->load->library("pagination");

		$this->data['judul_browser'] = 'Laporan';
		$this->data['judul_utama'] = 'Laporan';
		$this->data['judul_sub'] = 'Neraca Saldo';

		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/default/easyui.css';
		$this->data['css_files'][] = base_url() . 'assets/easyui/themes/icon.css';
		$this->data['js_files'][] = base_url() . 'assets/easyui/jquery.easyui.min.js';

		//include tanggal
		$this->data['css_files'][] = base_url() . 'assets/extra/bootstrap_date_time/css/bootstrap-datetimepicker.min.css';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/bootstrap-datetimepicker.min.js';
		$this->data['js_files'][] = base_url() . 'assets/extra/bootstrap_date_time/js/locales/bootstrap-datetimepicker.id.js';

		//include seach
		$this->data['css_files'][] = base_url() . 'assets/theme_admin/css/daterangepicker/daterangepicker-bs3.css';
		$this->data['js_files'][] = base_url() . 'assets/theme_admin/js/plugins/daterangepicker/daterangepicker.js';
		
		//$tgl_dari = isset($_GET['tgl_dari'])?$_GET['tgl_dari']:date('Y') . '-01-01';
		$tgl_dari = "";
		$thn_awal_dari = "";
		if (isset($_GET['tgl_dari'])){
			$tgl_dari = $_GET['tgl_dari'];
			$thn_awal_dari = date("Y",strtotime($_GET['tgl_dari']));
		} else {
			$tgl_dari = date('Y').'-01-01';
    }
    $tgl_start = date('Y').'-01-01';
		$tgl_sampai = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_sampai, 'p');
		$first_tgl_samp = date('Y-m-01', strtotime($tgl_sampai));
		$end_tgl_dari = date("Y-m-t", strtotime($tgl_dari));
		$end_tgl_dari_txt = jin_date_ina($end_tgl_dari, 'p');
		$first_tgl_samp_txt = jin_date_ina($first_tgl_samp, 'p');
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$tgl_awal_dari = $thn_awal_dari.'-01-01';
		$tgl_awal_dari = jin_date_ina($tgl_awal_dari, 'p');
		$tgl_periode_txt_c = $tgl_dari_txt .'  vs  '. $tgl_samp_txt;
		$tgl_periode_txt = $tgl_dari_txt .'  -  '. $tgl_samp_txt;
    $jenis_report = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;
		$this->data['tgl_dari'] = $tgl_dari;
		$this->data['tgl_samp'] = $tgl_sampai;
		$this->data['blnthn_dari'] = $blnthn_dari;
		$this->data['blnthn_samp'] = $blnthn_samp;
		$this->data['tgl_dari_txt'] = $tgl_dari_txt;
		$this->data['tgl_samp_txt'] = $tgl_samp_txt;
		$this->data['tgl_periode_txt'] = $tgl_periode_txt;
		$this->data['tgl_periode_txt_c'] = $tgl_periode_txt_c;
    
    $sql = "call InsertSHU ('".$tgl_dari."')";
    $this->db->query($sql);
    $sql = "call InsertSHU ('".$tgl_sampai."')";
    $this->db->query($sql);

		if ($jenis_report == 1) {
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (2,8,9) and parentid is not null
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();
      $this->data['kelompokakunaktiva'] = $kelompokakun;
      
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (10,11,12) and parentid is not null
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();
      $this->data['kelompokakunpasiva'] = $kelompokakun;
      
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (4) and parentid is null
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();
			$this->data['kelompokakunmodal'] = $kelompokakun;

			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (2,8,9)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql)->result_array();
      $this->data['indukakunaktiva'] = $indukakun;
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (10,11,12)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql)->result_array();
      $this->data['indukakunpasiva'] = $indukakun;
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (4)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql)->result_array();
			$this->data['indukakunmodal'] = $indukakun;

			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (2,8,9)
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (2,8,9)
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
			$akun = $this->db->query($sql)->result_array();
      $this->data['jns_akun_aktiva'] = $akun;
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (10,11,12)
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (10,11,12)
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
			$akun = $this->db->query($sql)->result_array();
      $this->data['jns_akun_pasiva'] = $akun;
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (4)
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (4)
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
			$akun = $this->db->query($sql)->result_array();
			$this->data['jns_akun_modal'] = $akun;
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (2,8,9)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (2,8,9)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql)->row_array();
      $this->data['totalaktiva'] = $total;
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (10,11,12)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (10,11,12)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql)->row_array();
      $this->data['totalpasiva'] = $total;
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (4)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (4)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql)->row_array();
			$this->data['totalmodal'] = $total;

			$sql1 = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid = 7
				order by no_urut asc ";
			$kelchan = $this->db->query($sql1)->result_array();
			$this->data['kelchan'] = $kelchan;

			$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.00.00','901.00.00') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc";
			$indukchan= $this->db->query($sql2)->result_array();
			$this->data['indukchan'] = $indukchan;

      $sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,
      (
        select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
        where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
        and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
        and za.validasi_status = 'X' 
      ) as debet,
      (
        select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
        where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
        and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
        and za.validasi_status = 'X' 
      ) as credit
			from jns_akun a
			where no_akun IN ('801.01.01','901.01.01') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by jns_akun_id asc";
			$chan= $this->db->query($sql3)->result_array();
      $this->data['chan'] = $chan;
			
		} else 
		if ($jenis_report == 2) {
			$sql = "
				select kelompok_debet, akun_debet, induk_akun_debet,kelompok_kredit, akun_kredit, induk_akun_kredit,
					case when (akun_debet is null) then '' else value_debet  end as value_debet,
          case when (akun_kredit is null) then '' else value_kredit  end as value_kredit,no_urut,is_total_debet,is_total_kredit,
          total_kelompok_debet,
          total_kelompok_kredit
				from
				(
				select ifnull(b.nama_kelompok,'') as kelompok_debet, b.kelompok_akunid as kelompok_akunid_debet, d.kelompok_akunid as kelompok_akunid_kredit,
					 concat(c.no_akun,' - ',c.nama_akun) as akun_debet, 
           ifnull(c.induk_akun,'') as induk_akun_debet,is_total_debet,is_total_kredit,
           case when is_total_debet = 0 then 0 else gettotalkelompok(b.kelompok_akunid,'DEBET','".$tgl_dari."','".$tgl_sampai."') end as total_kelompok_debet,
           case when is_total_kredit = 0 then 0 else gettotalkelompok(d.kelompok_akunid,'KREDIT','".$tgl_dari."','".$tgl_sampai."') end as total_kelompok_kredit,
           ifnull(d.nama_kelompok,'') as kelompok_kredit, 
					(
						select ifnull(sum(debit-credit),0)
						from journal_voucher z
						join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
						join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
						where za.jns_akun_id = c.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
						and z.validasi_status = 'X'
					) as value_debet,
					concat(e.no_akun,' - ',e.nama_akun) as akun_kredit , 
					ifnull(e.induk_akun,'') as induk_akun_kredit,
					(
						select ifnull(sum(credit-debit),0)
						from journal_voucher z
						join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
						join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
						where za.jns_akun_id = e.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
						and z.validasi_status = 'X'
					) as value_kredit,
					a.no_urut 
				from neraca_skonto a 
				left join kelompok_akun b on b.kelompok_akunid = a.kelompok_akunid_debet 
				left join jns_akun c on c.jns_akun_id = a.jns_akun_id_debet 
				left join kelompok_akun d on d.kelompok_akunid = a.kelompok_akunid_kredit 
				left join jns_akun e on e.jns_akun_id = a.jns_akun_id_kredit 
				order by a.no_urut asc
				) z order by no_urut asc";
			$this->data['datas'] = $this->db->query($sql)->result_array();

			$sql = "select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and za.validasi_status = 'X'
				and zb.jenis_akun = 'SUB AKUN'
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and za.validasi_status = 'X'
				and zb.jenis_akun = 'SUB AKUN'
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
			) as credit";
			$total = $this->db->query($sql)->row_array();
			$this->data['total'] = $total;

			$sql1 = "SELECT  ifnull(a.nama_kelompok,'' ) as kelompok_debet, ifnull(b.kelompok_akunid, 0) as kelompok_akunid_debet,
					concat(b.no_akun,' - ',b.nama_akun) as akun_debet, 
  					ifnull(b.induk_akun,'') as induk_akun_debet,a.no_urut 
			   		from  kelompok_akun a
	   				inner join jns_akun b on b.kelompok_akunid = a.kelompok_akunid
	   				WHERE b.kelompok_akunid = 7 and b.no_akun IN ('801.00.00','801.01.01','901.00.00','901.01.01') AND 
					   b.kelompok_laporan = 'Neraca' AND b.aktif = 'Y'";
					   $this->data['datachan'] = $this->db->query($sql1)->result_array();
		} else 
		if ($jenis_report == 3) {
			$awal_bln_dari = '01';
			$bln_samp = date("m",strtotime($tgl_sampai));
			$thn_samp = date("Y",strtotime($tgl_sampai));
			$bln_dari = date("m",strtotime($tgl_dari));
			$thn_dari = date("Y",strtotime($tgl_dari));
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (2,8,9) and parentid is not null
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();
      $this->data['kelompokakunaktiva'] = $kelompokakun;
      
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (10,11,12) and parentid is not null
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();
      $this->data['kelompokakunpasiva'] = $kelompokakun;
      
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (4) and parentid is null
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();
			$this->data['kelompokakunmodal'] = $kelompokakun;

      $sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (2,8,9)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql)->result_array();
      $this->data['indukakunaktiva'] = $indukakun;
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (10,11,12)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql)->result_array();
      $this->data['indukakunpasiva'] = $indukakun;
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (4)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql)->result_array();
			$this->data['indukakunmodal'] = $indukakun;

      $sql = "
      select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
      (
        select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
        and za.validasi_status = 'X' 
      ) as debet,
      (
        select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id 
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
        and za.validasi_status = 'X' 
      ) as credit
      from jns_akun a
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and jenis_akun = 'SUB AKUN' 
      AND saldo_normal = 'DEBET'
      AND a.kelompok_akunid in (2,8,9)
      order by no_akun asc ";
			$akun = $this->db->query($sql)->result_array();
      $this->data['jns_akun_aktiva'] = $akun;
      
      $sql = "
      select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
      (
        select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
        and za.validasi_status = 'X' 
      ) as debet,
      (
        select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id 
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
        and za.validasi_status = 'X' 
      ) as credit
      from jns_akun a
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and jenis_akun = 'SUB AKUN' 
      AND saldo_normal = 'CREDIT'
      AND a.kelompok_akunid in (10,11,12)
      order by no_akun asc 
      ";
			$akun = $this->db->query($sql)->result_array();
      $this->data['jns_akun_pasiva'] = $akun;
      
			$sql = " select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
      (
        select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
        and za.validasi_status = 'X' 
      ) as debet,
      (
        select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id 
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
        and za.validasi_status = 'X' 
      ) as credit
      from jns_akun a
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and jenis_akun = 'SUB AKUN' 
      AND saldo_normal = 'CREDIT'
      AND a.kelompok_akunid in (4)
      order by no_akun asc ";
			$akun = $this->db->query($sql)->result_array();
			$this->data['jns_akun_modal'] = $akun;
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (2,8,9)
				and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (2,8,9)
				and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql)->row_array();
      $this->data['totalaktiva'] = $total;
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (10,11,12)
				and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (10,11,12)
				and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql)->row_array();
      $this->data['totalpasiva'] = $total;
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (4)
				and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (4)
				and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql)->row_array();
      $this->data['totalmodal'] = $total;

			$sql1 = "select kelompok_akunid, nama_kelompok
			from kelompok_akun
			where kelompok_akunid = 7
			order by no_urut asc ";
			$kelchan = $this->db->query($sql1)->result_array();
			$this->data['kelchan'] = $kelchan;

			$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.00.00','901.00.00') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc";
			$indukchan= $this->db->query($sql2)->result_array();
			$this->data['indukchan'] = $indukchan;

      $sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,
      (
        select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_dari."')
        and za.validasi_status = 'X' 
      ) as debet,
      (
        select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        where z.jns_akun_id = a.jns_akun_id 
        and za.journal_date between '".$tgl_start."' and last_day('".$tgl_sampai."')
        and za.validasi_status = 'X' 
      ) as credit
			from jns_akun a
			where no_akun IN ('801.01.01','901.01.01') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by jns_akun_id asc";
			$chan= $this->db->query($sql3)->result_array();
			$this->data['chan'] = $chan;
			}
		
		$this->data['isi'] = $this->load->view('lap_neraca_list_v', $this->data, TRUE);
		$this->load->view('themes/layout_utama_v', $this->data);

	}

	function cetak() {
		$tgl_dari = "";
		$thn_awal_dari = "";
		if (isset($_GET['tgl_dari'])){
			$tgl_dari = $_GET['tgl_dari'];
			$thn_awal_dari = date("Y",strtotime($_GET['tgl_dari']));
		} else {
			$tgl_dari = date('Y').'-01-01';
    }
    $tgl_start = date('Y').'-01-01';
		$tgl_sampai = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_sampai, 'p');
		$first_tgl_samp = date('Y-m-01', strtotime($tgl_sampai));
		$end_tgl_dari = date("Y-m-t", strtotime($tgl_dari));
		$end_tgl_dari_txt = jin_date_ina($end_tgl_dari, 'p');
		$first_tgl_samp_txt = jin_date_ina($first_tgl_samp, 'p');
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$tgl_awal_dari = $thn_awal_dari.'-01-01';
		$tgl_awal_dari = jin_date_ina($tgl_awal_dari, 'p');
		$tgl_periode_txt_c = $tgl_dari_txt .'  vs  '. $tgl_samp_txt;
		$tgl_periode_txt = $tgl_dari_txt .'  -  '. $tgl_samp_txt;
    $jenis_report = isset($_GET['jenis_laporan'])?$_GET['jenis_laporan']:1;

		$this->load->library('Pdf');
		$pdf = new Pdf('L', 'mm', 'A4', true, 'UTF-8', false);
		$pdf->set_nsi_header(TRUE);
		$pdf->AddPage('L');

		if ($jenis_report == 1) {
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (2,8,9) and parentid is not null
				order by no_urut asc ";
			$kelompokakunaktiva = $this->db->query($sql)->result_array();
      
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (10,11,12) and parentid is not null
				order by no_urut asc ";
			$kelompokakunpasiva = $this->db->query($sql)->result_array();
      
			$sql = "select kelompok_akunid, nama_kelompok, status, parentid
				from kelompok_akun
				where kelompok_akunid in (4) and parentid is null
				order by no_urut asc ";
			$kelompokakunmodal = $this->db->query($sql)->result_array();

			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (2,8,9)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakunaktiva = $this->db->query($sql)->result_array();
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (10,11,12)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakunpasiva = $this->db->query($sql)->result_array();
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
      where kelompok_laporan = 'Neraca' 
      and aktif = 'Y' 
      and kelompok_akunid in (4)
      and jenis_akun = 'INDUK' 
      order by jns_akun_id asc ";
			$indukakunmodal = $this->db->query($sql)->result_array();

			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (2,8,9)
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (2,8,9)
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
			$jns_akun_aktiva = $this->db->query($sql)->result_array();
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (10,11,12)
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (10,11,12)
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
			$jns_akun_pasiva = $this->db->query($sql)->result_array();
      
			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,saldo_normal,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (4)
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X' and zb.kelompok_akunid in (4)
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
			$jns_akun_modal = $this->db->query($sql)->result_array();
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (2,8,9)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (2,8,9)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$totalaktiva = $this->db->query($sql)->row_array();
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (10,11,12)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (10,11,12)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$totalpasiva = $this->db->query($sql)->row_array();
      
      $sql = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (4)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and zb.jenis_akun = 'SUB AKUN' and zb.kelompok_akunid in (4)
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$totalmodal = $this->db->query($sql)->row_array();

			$sql1 = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid = 7
				order by no_urut asc ";
			$kelchan = $this->db->query($sql1)->result_array();

			$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.00.00','901.00.00') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc";
			$indukchan= $this->db->query($sql2)->result_array();

      $sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,
      (
        select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
        where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
        and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
        and za.validasi_status = 'X' 
      ) as debet,
      (
        select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
        from journal_voucher_det z 
        join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
        join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
        where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
        and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
        and za.validasi_status = 'X' 
      ) as credit
			from jns_akun a
			where no_akun IN ('801.01.01','901.01.01') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by jns_akun_id asc";
			$chan= $this->db->query($sql3)->result_array();
      
		$total = $this->db->query($sql)->row_array();$i=0;
		$html = '<style>
		.h_tengah {text-align: center;}
		.h_kiri {text-align: left;}
		.h_kanan {text-align: right;}
		.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
		.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
	</style>
	'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Neraca Saldo Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';

		$html .= '<br><br>
			<table class="table table-bordered">
			<tr class="header_kolom">
			<th width="50px"></th>
			<th width="400px"> Nama Akun</th>
			<th width="180px"> Debet </th>
			<th width="180px"> Kredit </th>
			</tr>
      <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>AKTIVA</strong></td>
      <td></td>
      <td></td>
    </tr>	';

    $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunaktiva as $kelompok) { 
      $kel1=$kelompok['nama_kelompok']; 
      $html .= '<tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong>'.$kelompok['nama_kelompok'].'</strong></td>
				<td></td>
				<td></td>
			</tr>	';
      foreach($indukakunaktiva as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {
          $html.= '<tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong>'.$induk['no_akun'].' - '.$induk['nama_akun'].'</strong></td>
            <td></td>
            <td></td>
          </tr>';
          foreach($jns_akun_aktiva as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{
              $html .= '<tr>
								<td> &nbsp;</td>
								<td>'.$akun['no_akun'].' - '.$akun['nama_akun'].'</td>
								<td align="right">'.number_format($akun['debet'],2,',','.').'</td>
								<td align="right">'.number_format($akun['credit'],2,',','.').'</td>
							</tr>';
							$subtotald += $akun['debet'];
              $subtotalc += $akun['credit'];
							$vsubtotald += $akun['debet'];
              $vsubtotalc += $akun['credit'];
            }
          }
        }
      }
      if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) {
        $html.= '<tr>
          <td colspan="2" class="h_kanan"><strong>Total '.$kelompok['nama_kelompok'].'</strong></td>
          <td class="h_kanan">'.number_format(nsi_round($subtotald),2,',','.').'</td>
          <td class="h_kanan">'.number_format(nsi_round($subtotalc),2,',','.').'</td>
        </tr>';
        $data=0;$subtotald=0;$subtotalc=0;
      } 
    }
    $html .= '<tr>
      <td colspan="2" class="h_kanan"><strong>Total AKTIVA</strong></td>
      <td class="h_kanan">'.number_format(nsi_round($totalaktiva['debet']),2,',','.').'</td>
      <td class="h_kanan">'.number_format(nsi_round($totalaktiva['credit']),2,',','.').'</td>
    </tr> 
    <tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>PASIVA</strong></td>
      <td></td>
      <td></td>
    </tr>';

    $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunpasiva as $kelompok) { 
      $kel1=$kelompok['nama_kelompok']; 
      $html .= '<tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong>'.$kelompok['nama_kelompok'].'</strong></td>
				<td></td>
				<td></td>
			</tr>	';
      foreach($indukakunpasiva as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {
          $html.= '<tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong>'.$induk['no_akun'].' - '.$induk['nama_akun'].'</strong></td>
            <td></td>
            <td></td>
          </tr>';
          foreach($jns_akun_pasiva as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{
              $html .= '<tr>
								<td> &nbsp;</td>
								<td>'.$akun['no_akun'].' - '.$akun['nama_akun'].'</td>
								<td align="right">'.number_format($akun['debet'],2,',','.').'</td>
								<td align="right">'.number_format($akun['credit'],2,',','.').'</td>
							</tr>';
							$subtotald += $akun['debet'];
              $subtotalc += $akun['credit'];
							$vsubtotald += $akun['debet'];
              $vsubtotalc += $akun['credit'];
            }
          }
        }
      }
      if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) {
        $html.= '<tr>
          <td colspan="2" class="h_kanan"><strong>Total '.$kelompok['nama_kelompok'].'</strong></td>
          <td class="h_kanan">'.number_format(nsi_round($subtotald),2,',','.').'</td>
          <td class="h_kanan">'.number_format(nsi_round($subtotalc),2,',','.').'</td>
        </tr>';
        $data=0;$subtotald=0;$subtotalc=0;
      } 
    }

    $html .= '<tr>
      <td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
      <td><strong>MODAL</strong></td>
      <td></td>
      <td></td>
    </tr>';

    $subtotald=0;$subtotalc=0;$vsubtotald=0;$vsubtotalc=0;$kel1="";$kel2="";
    foreach($kelompokakunmodal as $kelompok) { 
      $kel1=$kelompok['nama_kelompok']; 
      $html .= '<tr>
				<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
				<td><strong>'.$kelompok['nama_kelompok'].'</strong></td>
				<td></td>
				<td></td>
			</tr>	';
      foreach($indukakunmodal as $induk) {
				if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) {
          $html.= '<tr>
            <td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
            <td><strong>'.$induk['no_akun'].' - '.$induk['nama_akun'].'</strong></td>
            <td></td>
            <td></td>
          </tr>';
          foreach($jns_akun_modal as $akun) { 
						if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
						{
              $html .= '<tr>
								<td> &nbsp;</td>
								<td>'.$akun['no_akun'].' - '.$akun['nama_akun'].'</td>
								<td align="right">'.number_format($akun['debet'],2,',','.').'</td>
								<td align="right">'.number_format($akun['credit'],2,',','.').'</td>
							</tr>';
							$subtotald += $akun['debet'];
              $subtotalc += $akun['credit'];
							$vsubtotald += $akun['debet'];
              $vsubtotalc += $akun['credit'];
            }
          }
        }
      }
      if (($kelompok['nama_kelompok'] != "") && ($kel1 != $kel2) && ($kelompok['parentid'] != null)) {
        $html.= '<tr>
          <td colspan="2" class="h_kanan"><strong>Total '.$kelompok['nama_kelompok'].'</strong></td>
          <td class="h_kanan">'.number_format(nsi_round($subtotald),2,',','.').'</td>
          <td class="h_kanan">'.number_format(nsi_round($subtotalc),2,',','.').'</td>
        </tr>';
        $data=0;$subtotald=0;$subtotalc=0;
      } 
    }

    $html .= '<tr>
      <td colspan="2" class="h_kanan"><strong>Total MODAL</strong></td>
      <td class="h_kanan">'.number_format(nsi_round($totalmodal['debet']),2,',','.').'</td>
      <td class="h_kanan">'.number_format(nsi_round($totalmodal['credit']),2,',','.').'</td>
    </tr> ';

    $html .= '<tr>
      <td colspan="2" class="h_kanan"><strong>Total PASIVA</strong></td>
      <td class="h_kanan">'.number_format(nsi_round($totalpasiva['debet']+$totalmodal['debet']),2,',','.').'</td>
      <td class="h_kanan">'.number_format(nsi_round($totalpasiva['credit']+$totalmodal['credit']),2,',','.').'</td>
    </tr> ';

			$html .= '</table>';

      $html .= '<p></p><table class="table table-bordered">
			<tr class="header_kolom">
			<th width="50px"></th>
			<th width="400px"> Nama Akun</th>
			<th width="180px"> Debet </th>
			<th width="180px"> Kredit </th>
			</tr>';
			foreach($kelchan as $kelompok) {
					$html .= '<tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong>'.$kelompok['nama_kelompok'].'</strong></td>
						<td></td>
						<td></td>
					</tr>';
					foreach($indukchan as $induk){
						if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) 
						{
							$html .= '<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong>'.$induk['no_akun'].' - '.$induk['nama_akun'].'</strong></td>
								<td></td>
								<td></td>
							</tr>';
							foreach($chan as $akun) { 
								if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
								{
									$html .= '<tr>
										<td> &nbsp;</td>
										<td>'.$akun['no_akun'].' - '.$akun['nama_akun'].'</td>
										<td align="right">0</td>
										<td align="right">0</td>
									</tr>';
							  }
							}
						}
					}
			}
        $html .= '</table>';

		} else 
		if ($jenis_report == 2) {
			$sql = "
			select kelompok_debet, akun_debet, induk_akun_debet,kelompok_kredit, akun_kredit, induk_akun_kredit,
				case when (akun_debet is null) then '' else value_debet  end as value_debet,
	  case when (akun_kredit is null) then '' else value_kredit  end as value_kredit,no_urut,is_total_debet,is_total_kredit,
	  total_kelompok_debet,
	  total_kelompok_kredit
			from
			(
			select ifnull(b.nama_kelompok,'') as kelompok_debet, b.kelompok_akunid as kelompok_akunid_debet, d.kelompok_akunid as kelompok_akunid_kredit,
				 concat(c.no_akun,' - ',c.nama_akun) as akun_debet, 
	   ifnull(c.induk_akun,'') as induk_akun_debet,is_total_debet,is_total_kredit,
	   case when is_total_debet = 0 then 0 else gettotalkelompok(b.kelompok_akunid,'DEBET','".$tgl_dari."','".$tgl_sampai."') end as total_kelompok_debet,
	   case when is_total_kredit = 0 then 0 else gettotalkelompok(d.kelompok_akunid,'KREDIT','".$tgl_dari."','".$tgl_sampai."') end as total_kelompok_kredit,
	   ifnull(d.nama_kelompok,'') as kelompok_kredit, 
				(
					select ifnull(sum(debit-credit),0)
					from journal_voucher z
					join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
					join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
					where za.jns_akun_id = c.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and z.validasi_status = 'X'
				) as value_debet,
				concat(e.no_akun,' - ',e.nama_akun) as akun_kredit , 
				ifnull(e.induk_akun,'') as induk_akun_kredit,
				(
					select ifnull(sum(credit-debit),0)
					from journal_voucher z
					join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
					join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
					where za.jns_akun_id = e.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and z.validasi_status = 'X'
				) as value_kredit,
				a.no_urut 
			from neraca_skonto a 
			left join kelompok_akun b on b.kelompok_akunid = a.kelompok_akunid_debet 
			left join jns_akun c on c.jns_akun_id = a.jns_akun_id_debet 
			left join kelompok_akun d on d.kelompok_akunid = a.kelompok_akunid_kredit 
			left join jns_akun e on e.jns_akun_id = a.jns_akun_id_kredit 
			order by a.no_urut asc
			) z order by no_urut asc";
		$datas = $this->db->query($sql)->result_array();

		$sql = "select (
			select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
			from journal_voucher_det z 
			join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
			join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
			where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
			and za.validasi_status = 'X'
			and zb.jenis_akun = 'SUB AKUN'
			and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
		) as debet,
		(
			select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
			from journal_voucher_det z 
			join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
			join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
			where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
			and za.validasi_status = 'X'
			and zb.jenis_akun = 'SUB AKUN'
			and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
		) as credit";
		$total = $this->db->query($sql)->row_array();
		$this->data['total'] = $total;

		$html ='';
		$html = '<style>
		.h_tengah {text-align: center;}
		.h_kiri {text-align: left;}
		.h_kanan {text-align: right;}
		.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
		.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
		</style>
		'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Neraca Saldo Periode '.$tgl_periode_txt.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
		$html .= '<table class="table table-bordered">
				<tr class="header_kolom">
					<th width="10%"> </th>
					<th width="27.5%"> Keterangan</th>
					<th width="10%"> Jumlah</th>
					<th width="10%"> </th>
					<th width="27.5%"> Keterangan</th>
					<th width="15%"> Jumlah</th>
				</tr>';
				foreach($datas as $row) {  
					$keldebet1=$row['kelompok_debet'];
					if (($row['kelompok_debet'] == '') && ($row['akun_debet'] == '') && ($row['kelompok_kredit'] == '') && ($row['akun_kredit'] == '')) {
						$html .= '<tr>
									<td>&nbsp;</td>
									<td>&nbsp;</td>
									<td>&nbsp;</td>
									<td>&nbsp;</td>
									<td>&nbsp;</td>
									<td>&nbsp;</td>
								</tr>';
						} else {
							$html .= '<tr>';
							if ($row['kelompok_debet'] != '') { 
								if ($row['is_total_debet'] == 0) { 
									$html .= '<td><strong>'. $row['kelompok_debet'] .'</strong></td>';
								} else { 
									$html .= '<td><strong> TOTAL '.$row['kelompok_debet'] .'</strong></td>';
								} 
							} else { 
							   	$html .='<td>&nbsp;</td>';
							} 
							if ($row['akun_debet'] != '') { 
								if ($row['induk_akun_debet'] != '') { 
									$html .='<td>'.$row['akun_debet'] .'</td>
									<td class="h_kanan">'. number_format($row['value_debet'],2,',','.') .'</td>';
								  } else 
								  if ($row['induk_akun_debet'] == '') { 
									$html .='<td><strong>'.$row['akun_debet'] .'</strong></td>
									<td></td>';
								  }
							  } else
							  if (($row['kelompok_debet'] != '') && ($row['is_total_debet'])) { 
								$html .= '<td></td>
								  <td class="h_kanan"><strong>'. number_format($row['total_kelompok_debet'],2,',','.').'</strong></td>';
							 } else {
								$html .='<td></td>
										<td></td>';
								}
								if ($row['kelompok_kredit'] != '') { 
									if ($row['is_total_kredit'] == 0) { 
										$html .='<td><strong>'.$row['kelompok_kredit'] .'</strong></td>';
									 } else { 
										$html .='<td><strong> TOTAL '.$row['kelompok_kredit'] .'</strong></td>';
									 } 
								} else { 
									$html .='<td>&nbsp;</td>';
								} 
								if ($row['akun_kredit'] != '') { 
									if ($row['induk_akun_kredit'] != '') { 
										$html .='<td>'. $row['akun_kredit'] .'</td>
											<td class="h_kanan">'. number_format($row['value_kredit'],2,',','.') .'</td>';
									 } else 
									if ($row['induk_akun_kredit'] == '') { 
										$html .='<td><strong>'. $row['akun_kredit'] .'</strong></td>
											<td></td>';
									}
								} else
								if (($row['kelompok_kredit'] != '') && ($row['is_total_kredit'])) { 
									$html .='<td></td>
										<td class="h_kanan"><strong>'. number_format($row['total_kelompok_kredit'],2,',','.').'</strong></td>';
								} else { 
									$html .= '<td></td>
									<td></td>';
								}
							$html .= '</tr>';
						}

				}
				$html .= '<tr>
							<td colspan="2"><strong>JUMLAH AKTIVA</strong></td>
							<td class="h_kanan"><strong> '.number_format($total['debet'],2,',','.') .'</strong></td>
							<td colspan="2"><strong>JUMLAH PASIVA</strong></td>
							<td class="h_kanan"><strong>'.number_format($total['credit'],2,',','.') .'</strong></td>
						</tr>'; 
				$html .= '</table> <br>';
				$sql1 = "SELECT  ifnull(a.nama_kelompok,'' ) as kelompok_debet, ifnull(b.kelompok_akunid, 0) as kelompok_akunid_debet,
					concat(b.no_akun,' - ',b.nama_akun) as akun_debet, 
  					ifnull(b.induk_akun,'') as induk_akun_debet,a.no_urut 
			   		from  kelompok_akun a
	   				inner join jns_akun b on b.kelompok_akunid = a.kelompok_akunid
	   				WHERE b.kelompok_akunid = 7 and b.no_akun IN ('801.00.00','801.01.01','901.00.00','901.01.01') AND 
					   b.kelompok_laporan = 'Neraca' AND b.aktif = 'Y'";
					   $datachan = $this->db->query($sql1)->result_array();
				$html .= '<br>
					<table class="table table-bordered">
						<tr class="header_kolom">
								<th style="text-align:center; width:10%"> </th>
								<th style="text-align:center; width:30%"> Keterangan</th>
								<th style="text-align:center; width:10%"> Jumlah</th>
								<th style="text-align:center; width:10%"> </th>
								<th style="text-align:center; width:30%"> Keterangan</th>
								<th style="text-align:center; width:10%"> Jumlah</th>
							</tr>';
			$offbalancesheet = ""; foreach($datachan as $row) { 
				$offbalancesheet = $row['kelompok_debet'];
			} 
			$html .= '<tr>
				<td><b>'. $offbalancesheet.'</b></td>
				<td></td>
				<td></td>
				<td></td>
				<td></td>
				<td></td>
			</tr>'; 		
				foreach($datachan as $row1) { 
					$html .= '<tr>
					<td></td>
					<td>';if (strpos($row1['akun_debet'], '801.00.00') !== false || strpos($row1['akun_debet'], '901.00.00') !== false) 
							{ $html .= '<b>'.$row1['akun_debet'].'</b>'; } else { $html .= $row1['akun_debet'];} 
					$html .= '</td>
					<td>0</td>
					<td></td>
					<td></td>
					<td></td>
					</tr>';
				}
				$html .= '</table>';
		} else 
		if ($jenis_report == 3){
			$awal_bln_dari = '01';
			$bln_dari = date("m",strtotime($tgl_dari));
			$thn_dari = date("Y",strtotime($tgl_dari));
			$bln_samp = date("m",strtotime($tgl_sampai));
			$thn_samp = date("Y",strtotime($tgl_sampai));
			$sql = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid not in (5,6,7)
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();

			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
			where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by no_akun asc ";
			$indukakun = $this->db->query($sql)->result_array();

			$sql = "
				select induk_akun,jns_akun_id,no_akun,nama_akun,kelompok_akunid, case when (debetsamp > 0) then debetsamp else creditsamp end as valuesamp,
				case when (debetdari > 0) then debetdari else creditdari end as valuedari
				from 
				(
					select induk_akun,jns_akun_id,no_akun,nama_akun,kelompok_akunid,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_samp."
					and year(za.journal_date) = ".$thn_samp."
					and za.validasi_status = 'X'
				) as debetsamp,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_samp."
					and year(za.journal_date) = ".$thn_samp."
					and za.validasi_status = 'X'
				) as creditsamp,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_dari."
					and year(za.journal_date) = ".$thn_dari."
					and za.validasi_status = 'X'
				) as debetdari,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_dari."
					and year(za.journal_date) = ".$thn_dari."
					and za.validasi_status = 'X'
				) as creditdari
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc
				) z ";
			$jns_akun = $this->db->query($sql)->result_array();
			$html ='';
			$html = '<style>
				.h_tengah {text-align: center;}
				.h_kiri {text-align: left;}
				.h_kanan {text-align: right;}
				.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
				.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			</style>
			'.$pdf->nsi_box($text = '<span class="txt_judul">Laporan Neraca Saldo Periode '.$tgl_periode_txt_c.'</span>', $width = '100%', $spacing = '1', $padding = '1', $border = '0', $align = 'center').'';
			$html .=  '<table class="table table-bordered">
			<tr class="header_kolom">
				<th style="text-align:center; width:5%"> </th>
				<th style="text-align:center; width:60%"> Nama Akun</th>
				<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_dari)).'</th>
				<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_sampai)).'</th>
			</tr>';
			$subtotald = 0; $subtotalc =0;$kel1=0;$kel2=0;$totaldebet=0;$totalkredit=0;
			foreach($kelompokakun as $kelompok) {
				$kel1=$kelompok['nama_kelompok'];
				$html .= '<tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong>'. $kelompok['nama_kelompok'] .'</strong></td>
						<td></td>
						<td></td>
					</tr>';
					foreach($indukakun as $induk) {
						if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) 
						{
							$html .= '<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong>'.$induk['no_akun'].' - '.$induk['nama_akun'] .'</strong></td>
								<td></td>
								<td></td>
							</tr>';	
							foreach($jns_akun as $akun) { 
								$totaldebet += $akun['valuesamp'];
								$totalkredit += $akun['valuedari'];
								if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
								{
									$html .= '<tr>
										<td> &nbsp;</td>
										<td>'.$akun['no_akun'].' - '.$akun['nama_akun'] .'</td>
										<td align="right">'.number_format($akun['valuedari'],2,',','.') .'</td>
										<td align="right">'.number_format($akun['valuesamp'],2,',','.') .'</td>
									</tr>';	
									$subtotalc += $akun['valuedari']; $subtotald += $akun['valuesamp'];
								}
							}
						}
					}
					if ($kelompok['nama_kelompok'] != "" && $kel1 != $kel2) { 
							$html .= '<tr>
								<td colspan="2" class="h_kanan"><strong>TOTAL '.$kelompok['nama_kelompok'].'</strong></td>
								<td class="h_kanan">'.number_format(nsi_round($subtotalc),2,',','.').'</td>
								<td class="h_kanan">'.number_format(nsi_round($subtotald),2,',','.').'</td>
							</tr>';
						
						$data=0;$subtotalc=0;$subtotald=0;
					} 
					$kel2=$kelompok['nama_kelompok'];
				 }
			$html .= '</table> <br>';

			$sql1 = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid = 7
				order by no_urut asc ";
			$kelchan = $this->db->query($sql1)->result_array();
			$this->data['kelchan'] = $kelchan;

			$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.00.00','901.00.00') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc";
			$indukchan= $this->db->query($sql2)->result_array();
			$this->data['indukchan'] = $indukchan;

			$sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.01.01','901.01.01') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by jns_akun_id asc";
			$chan= $this->db->query($sql3)->result_array();
			$this->data['chan'] = $chan;

			$html .=  '<br> <table class="table table-bordered">
			<tr class="header_kolom">
				<th style="text-align:center; width:5%"> </th>
				<th style="text-align:center; width:60%"> Nama Akun</th>
				<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_dari)).'</th>
				<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_sampai)).'</th>
			</tr>';
			foreach($kelchan as $kelompok) { $kel1=$kelompok['nama_kelompok'];
					$html .= ' <tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong>'. $kelompok['nama_kelompok'].'</strong></td>
						<td></td>
						<td></td>
					</tr>';	
			 	foreach($indukchan as $induk) {
					$html .= '<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong>'.$induk["no_akun"]." - ".$induk['nama_akun'] .'</strong></td>
								<td></td>
								<td></td>
							</tr>';
						foreach($chan as $akun) { 
								if ($akun["kelompok_akunid"] == $induk["kelompok_akunid"] &&  $akun["induk_akun"] == $induk["jns_akun_id"])
								{
									$html .= '<tr>
											<td> &nbsp;</td>
											<td>'.$akun["no_akun"].' - '.$akun["nama_akun"].'</td>
											<td align="right">0</td>
											<td align="right">0</td>
										</tr>';	
								} 
						}	
				}
			 } 
			 $html .= '</table>';
		}
		
		$pdf->nsi_html($html);
		
		$pdf->Output('lap_neraca'.date('Ymd_His') . '.pdf', 'I');
	}
	
	function export_excel(){
		header("Content-type: application/vnd-ms-excel");
		header("Content-Disposition: attachment; filename=export-".date("Y-m-d_H:i:s").".xls");

		$tgl_dari = "";
		$thn_awal_dari = "";
		if (isset($_GET['tgl_dari'])){
			$tgl_dari = $_GET['tgl_dari'];
			$thn_awal_dari = date("Y",strtotime($_GET['tgl_dari']));
		} else {
			$tgl_dari = date('Y').'-01-01';
		}
		$tgl_sampai = isset($_GET['tgl_samp'])?$_GET['tgl_samp']:date('Y') . '-12-31';
		$tgl_dari_txt = jin_date_ina($tgl_dari, 'p');
		$tgl_samp_txt = jin_date_ina($tgl_sampai, 'p');
		$first_tgl_samp = date('Y-m-01', strtotime($tgl_sampai));
		$end_tgl_dari = date("Y-m-t", strtotime($tgl_dari));
		$end_tgl_dari_txt = jin_date_ina($end_tgl_dari, 'p');
		$first_tgl_samp_txt = jin_date_ina($first_tgl_samp, 'p');
		$blnthn_dari = isset($_GET['tgl_dari'])?date("Y-m",strtotime($_GET['tgl_dari'])):date("Y-m");
		$blnthn_samp = isset($_GET['tgl_samp'])?date("Y-m",strtotime($_GET['tgl_samp'])):date("Y-m");
		$tgl_awal_dari = $thn_awal_dari.'-01-01';
		$tgl_awal_dari = jin_date_ina($tgl_awal_dari, 'p');
		$tgl_periode_txt_c = $tgl_awal_dari . ' s/d ' . $end_tgl_dari_txt .'   -   '. $tgl_awal_dari . ' s/d ' . $tgl_samp_txt;
		$tgl_periode_txt = $tgl_dari_txt .'  -  '. $tgl_samp_txt;
		$jenis_report = $_GET['jenis_laporan'];
		$html ="";
	
		if ( $jenis_report == 1) {
			$sql1 = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid not in (5,6,7)
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql1)->result_array();
			

			$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
			where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc ";
			$indukakun = $this->db->query($sql2)->result_array();
			

			$sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X'
				) as debet,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
					and za.validasi_status = 'X'
				) as credit
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc ";
				$jns_akun = $this->db->query($sql3)->result_array();
				

			$sql4 = "	select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' 
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT'
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
				and za.validasi_status = 'X'
			) as credit";
			$total = $this->db->query($sql4)->row_array();

				$html = '<style>
				.h_tengah {text-align: center;}
				.h_kiri {text-align: left;}
				.h_kanan {text-align: right;}
				.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
				.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			</style>
			<span class="txt_judul">Laporan Neraca Saldo Periode '.$tgl_periode_txt.'</span>';
			$html .= '<table class="table table-bordered">
			<tr class="header_kolom">
				<th style="text-align:center; width:5%"> </th>
				<th style="text-align:center; width:60%"> Nama Akun</th>
				<th style="text-align:center; width:15%"> Debet </th>
				<th style="text-align:center; width:15%"> Kredit </th>
			</tr>';
			$subtotald=0;$subtotalc=0;$kel1="";$kel2="";
		foreach($kelompokakun as $kelompok) { 
			
					$kel1=$kelompok['nama_kelompok'];
					$html .= '<tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong>' . $kelompok['nama_kelompok'] . '</strong></td>
						<td></td>
						<td></td>
					</tr>';	
					foreach($indukakun as $induk) {
							if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) 
							{
								$html .= '<tr>
										<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
										<td><strong>'. $induk['no_akun'].' - '.$induk['nama_akun'] .'</strong></td>
										<td></td>
										<td></td>
								</tr>';	
							foreach($jns_akun as $akun) { 
									if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
									{
										$html .= '<tr>
											<td> &nbsp;</td>
											<td>' . $akun['no_akun'].' - '.$akun['nama_akun'] .
											'</td>
											<td align="right">'. number_format($akun['debet'],2,',','.').
											 '</td>
											<td align="right">'. number_format($akun['credit'],2,',','.').
											 '</td>
										</tr>';	
									$subtotald += $akun['debet'];$subtotalc += $akun['credit'];
									} 
							}
						}
					}

					if ($kelompok['nama_kelompok'] != "" && $kel1 != $kel2) {
						if ($subtotalc !== 0 && $subtotald !== 0) {
							$html .= '<tr>
								<td colspan="2" class="h_kanan"><strong>TOTAL '.$kelompok['nama_kelompok'].'</strong></td>
								<td class="h_kanan">'. number_format(nsi_round($subtotald),2,',','.') .'</td>
								<td class="h_kanan">'. number_format(nsi_round($subtotalc),2,',','.') .'</td>
							</tr>';
						}	
							$data=0;$subtotald=0;$subtotalc=0;
					} 
				$kel2=$kelompok['nama_kelompok'];
			}
			$html .= '<tr class="header_kolom" >
					<td colspan="2"> JUMLAH </td>
					<td align="right">' . number_format($total['debet'],2,',','.') .
						'</td>
					<td align="right">' .number_format($total['credit'],2,',','.') .
					'</td>
				</tr>
			</table>';

			$sql1 = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid = 7
				order by no_urut asc ";
			$kelchan = $this->db->query($sql1)->result_array();
			$this->data['kelchan'] = $kelchan;

			$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.00.00','901.00.00') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc";
			$indukchan= $this->db->query($sql2)->result_array();
			$this->data['indukchan'] = $indukchan;

			$sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
			from jns_akun
			where no_akun IN ('801.01.01','901.01.01') AND 
			kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by jns_akun_id asc";
			$chan= $this->db->query($sql3)->result_array();
			$this->data['chan'] = $chan;

			$html .= '<br><br>
			<table class="table table-bordered">
			<tr class="header_kolom">
			<th width="50px"></th>
			<th width="400px"> Nama Akun</th>
			<th width="180px"> Debet </th>
			<th width="180px"> Kredit </th>
			</tr>';
			foreach($kelchan as $kelompok) { $kel1=$kelompok['nama_kelompok'];
					$html .= ' <tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong>'. $kelompok['nama_kelompok'].'</strong></td>
						<td></td>
						<td></td>
					</tr>';	
			 	foreach($indukchan as $induk) {
					$html .= '<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong>'.$induk["no_akun"]." - ".$induk['nama_akun'] .'</strong></td>
								<td></td>
								<td></td>
							</tr>';
						foreach($chan as $akun) { 
								if ($akun["kelompok_akunid"] == $induk["kelompok_akunid"] &&  $akun["induk_akun"] == $induk["jns_akun_id"])
								{
									$html .= '<tr>
											<td> &nbsp;</td>
											<td>'.$akun["no_akun"].' - '.$akun["nama_akun"].'</td>
											<td align="right">0</td>
											<td align="right">0</td>
										</tr>';	
								} 
						}	
				}
			 } 
			 $html .= '</table>';
		
		} else if ($jenis_report == 2) {
			$sql = "
				select kelompok_debet, akun_debet, induk_akun_debet,kelompok_kredit, akun_kredit, induk_akun_kredit,
					case when (akun_debet is null) then '' else value_debet  end as value_debet,
          case when (akun_kredit is null) then '' else value_kredit  end as value_kredit,no_urut,is_total_debet,is_total_kredit,
          total_kelompok_debet,
          total_kelompok_kredit
				from
				(
				select ifnull(b.nama_kelompok,'') as kelompok_debet, b.kelompok_akunid as kelompok_akunid_debet, d.kelompok_akunid as kelompok_akunid_kredit,
					 concat(c.no_akun,' - ',c.nama_akun) as akun_debet, 
           ifnull(c.induk_akun,'') as induk_akun_debet,is_total_debet,is_total_kredit,
           case when is_total_debet = 0 then 0 else gettotalkelompok(b.kelompok_akunid,'DEBET','".$tgl_dari."','".$tgl_sampai."') end as total_kelompok_debet,
           case when is_total_kredit = 0 then 0 else gettotalkelompok(d.kelompok_akunid,'KREDIT','".$tgl_dari."','".$tgl_sampai."') end as total_kelompok_kredit,
           ifnull(d.nama_kelompok,'') as kelompok_kredit, 
					(
						select ifnull(sum(debit-credit),0)
						from journal_voucher z
						join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
						join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
						where za.jns_akun_id = c.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
						and z.validasi_status = 'X'
					) as value_debet,
					concat(e.no_akun,' - ',e.nama_akun) as akun_kredit , 
					ifnull(e.induk_akun,'') as induk_akun_kredit,
					(
						select ifnull(sum(credit-debit),0)
						from journal_voucher z
						join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
						join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
						where za.jns_akun_id = e.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
						and z.validasi_status = 'X'
					) as value_kredit,
					a.no_urut 
				from neraca_skonto a 
				left join kelompok_akun b on b.kelompok_akunid = a.kelompok_akunid_debet 
				left join jns_akun c on c.jns_akun_id = a.jns_akun_id_debet 
				left join kelompok_akun d on d.kelompok_akunid = a.kelompok_akunid_kredit 
				left join jns_akun e on e.jns_akun_id = a.jns_akun_id_kredit 
				order by a.no_urut asc
				) z order by no_urut asc";
			$datas = $this->db->query($sql)->result_array();

			$sql = "select (
				select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'DEBET' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and za.validasi_status = 'X'
				and zb.jenis_akun = 'SUB AKUN'
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
			) as debet,
			(
				select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
				from journal_voucher_det z 
				join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
				join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
				where zb.saldo_normal = 'CREDIT' and zb.kelompok_laporan = 'Neraca' and zb.aktif = 'Y' 
				and za.validasi_status = 'X'
				and zb.jenis_akun = 'SUB AKUN'
				and za.journal_date between '".$tgl_dari."' and '".$tgl_sampai."'
			) as credit";
			$total = $this->db->query($sql)->row_array();
			$this->data['total'] = $total;

			$html ='';
			$html = '<style>
				.h_tengah {text-align: center;}
				.h_kiri {text-align: left;}
				.h_kanan {text-align: right;}
				.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
				.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			</style>
			<span class="txt_judul">Laporan Neraca Saldo Periode '.$tgl_periode_txt.'</span>';
			$html .= '<table class="table table-bordered">
			<tr class="header_kolom">
			<th style="text-align:center; width:10%"> </th>
			<th style="text-align:center; width:30%"> Keterangan</th>
			<th style="text-align:center; width:10%"> Jumlah</th>
			<th style="text-align:center; width:10%"> </th>
			<th style="text-align:center; width:30%"> Keterangan</th>
			<th style="text-align:center; width:15%"> Jumlah</th>
		</tr>';
		foreach($datas as $row) { $keldebet1=$row['kelompok_debet'];
				if (($row['kelompok_debet'] == '') && ($row['akun_debet'] == '') && ($row['kelompok_kredit'] == '') && ($row['akun_kredit'] == '')) {
					$html .= '<tr>
								<td>&nbsp;</td>
								<td>&nbsp;</td>
								<td>&nbsp;</td>
								<td>&nbsp;</td>
								<td>&nbsp;</td>
								<td>&nbsp;</td>
							</tr>';
					} else {
			$html .= '<tr>';
						 	if ($row['kelompok_debet'] != '') { 
								if ($row['is_total_debet'] == 0) { 
									$html .= '<td><strong>'. $row['kelompok_debet'] .'</strong></td>';
								} else { 
									$html .= '<td><strong> TOTAL '.$row['kelompok_debet'] .'</strong></td>';
								} 
							 } else { 
								$html .='<td><br></td>';
							 } 
       				 		if ($row['akun_debet'] != '') { 
								if ($row['induk_akun_debet'] != '') { 
				    				$html .='<td>'.$row['akun_debet'] .'</td>
				    				<td class="h_kanan">'. number_format($row['value_debet'],2,',','.') .'</td>';
          						} else 
          						if ($row['induk_akun_debet'] == '') { 
									$html .='<td><strong>'.$row['akun_debet'] .'</strong></td>
									<td></td>';
          						}
          					} else
          					if (($row['kelompok_debet'] != '') && ($row['is_total_debet'])) { 
								$html .= '<td></td>
								  <td class="h_kanan"><strong>'. number_format($row['total_kelompok_debet'],2,',','.').'</strong></td>';
        					 } else {
								$html .='<td></td>
								<td></td>';
       						 }
							if ($row['kelompok_kredit'] != '') { 
								if ($row['is_total_kredit'] == 0) { 
									$html .='<td><strong>'.$row['kelompok_kredit'] .'</strong></td>';
								 } else { 
									$html .='<td><strong> TOTAL '.$row['kelompok_kredit'] .'</strong></td>';
								 } 
							} else { 
								$html .='<td><br></td>';
							} 
							if ($row['akun_kredit'] != '') { 
								if ($row['induk_akun_kredit'] != '') { 
									$html .='<td>'. $row['akun_kredit'] .'</td>
										<td class="h_kanan">'. number_format($row['value_kredit'],2,',','.') .'</td>';
								 } else 
								if ($row['induk_akun_kredit'] == '') { 
									$html .='<td><strong>'. $row['akun_kredit'] .'</strong></td>
										<td></td>';
								}
							} else
							if (($row['kelompok_kredit'] != '') && ($row['is_total_kredit'])) { 
								$html .='<td></td>
									<td class="h_kanan"><strong>'. number_format($row['total_kelompok_kredit'],2,',','.').'</td>';
							} else { 
								$html .= '<td></td>
								<td></td>';
							}
							$html .='</tr>';	
				}
			}
						$html .= '<tr>
							<td colspan="2"><strong>JUMLAH AKTIVA</strong></td>
							<td class="h_kanan"><strong> '.number_format($total['debet'],2,',','.') .'</strong></td>
							<td colspan="2"><strong>JUMLAH PASIVA</strong></td>
							<td class="h_kanan"><strong>'.number_format($total['credit'],2,',','.') .'</strong></td>
						</tr>'; 
					$html .= '</table> <br>';
					$sql1 = "SELECT  ifnull(a.nama_kelompok,'' ) as kelompok_debet, ifnull(b.kelompok_akunid, 0) as kelompok_akunid_debet,
					concat(b.no_akun,' - ',b.nama_akun) as akun_debet, 
  					ifnull(b.induk_akun,'') as induk_akun_debet,a.no_urut 
			   		from  kelompok_akun a
	   				inner join jns_akun b on b.kelompok_akunid = a.kelompok_akunid
	   				WHERE b.kelompok_akunid = 7 and b.no_akun IN ('801.00.00','801.01.01','901.00.00','901.01.01') AND 
					   b.kelompok_laporan = 'Neraca' AND b.aktif = 'Y'";
					   $datachan = $this->db->query($sql1)->result_array();
				$html .= '<br>
					<table class="table table-bordered">
						<tr class="header_kolom">
								<th style="text-align:center; width:10%"> </th>
								<th style="text-align:center; width:30%"> Keterangan</th>
								<th style="text-align:center; width:10%"> Jumlah</th>
								<th style="text-align:center; width:10%"> </th>
								<th style="text-align:center; width:30%"> Keterangan</th>
								<th style="text-align:center; width:10%"> Jumlah</th>
							</tr>';
			$offbalancesheet = ""; foreach($datachan as $row) { 
				$offbalancesheet = $row['kelompok_debet'];
			} 
			$html .= '<tr>
				<td><b>'. $offbalancesheet.'</b></td>
				<td></td>
				<td></td>
				<td></td>
				<td></td>
				<td></td>
			</tr>'; 		
				foreach($datachan as $row1) { 
					$html .= '<tr>
					<td></td>
					<td>';if (strpos($row1['akun_debet'], '801.00.00') !== false || strpos($row1['akun_debet'], '901.00.00') !== false) 
							{ $html .= '<b>'.$row1['akun_debet'].'</b>'; } else { $html .= $row1['akun_debet'];} 
					$html .= '</td>
					<td>0</td>
					<td></td>
					<td></td>
					<td></td>
					</tr>';
				}
				$html .= '</table>';
		} else 
		if ($jenis_report == 3) {

			$awal_bln_dari = '01';
			$bln_dari = date("m",strtotime($tgl_dari));
			$thn_dari = date("Y",strtotime($tgl_dari));
			$bln_samp = date("m",strtotime($tgl_sampai));
			$thn_samp = date("Y",strtotime($tgl_sampai));

			$sql = "select kelompok_akunid, nama_kelompok
				from kelompok_akun
				where kelompok_akunid not in (5,6,7)
				order by no_urut asc ";
			$kelompokakun = $this->db->query($sql)->result_array();

			$sql = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid
			from jns_akun
			where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by no_akun asc ";
			$indukakun = $this->db->query($sql)->result_array();

			$sql = "
				select induk_akun,jns_akun_id,no_akun,nama_akun,kelompok_akunid, case when (debetsamp > 0) then debetsamp else creditsamp end as valuesamp,
				case when (debetdari > 0) then debetdari else creditdari end as valuedari
				from 
				(
					select induk_akun,jns_akun_id,no_akun,nama_akun,kelompok_akunid,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_samp."
					and year(za.journal_date) = ".$thn_samp."
					and za.validasi_status = 'X'
				) as debetsamp,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_samp."
					and year(za.journal_date) = ".$thn_samp."
					and za.validasi_status = 'X'
				) as creditsamp,
				(
					select ifnull(sum(ifnull(z.debit,0)) - sum(ifnull(z.credit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'DEBET' 
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_dari."
					and year(za.journal_date) = ".$thn_dari."
					and za.validasi_status = 'X'
				) as debetdari,
				(
					select ifnull(sum(ifnull(z.credit,0)) - sum(ifnull(z.debit,0)),0)
					from journal_voucher_det z 
					join journal_voucher za on za.journal_voucherid = z.journal_voucher_id
					join jns_akun zb on zb.jns_akun_id = z.jns_akun_id
					where z.jns_akun_id = a.jns_akun_id and zb.saldo_normal = 'CREDIT'
					and month(za.journal_date) between ".$awal_bln_dari." and ".$bln_dari."
					and year(za.journal_date) = ".$thn_dari."
					and za.validasi_status = 'X'
				) as creditdari
				from jns_akun a
				where kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by no_akun asc
				) z ";
			$jns_akun = $this->db->query($sql)->result_array();
			$html ='';
			$html = '<style>
				.h_tengah {text-align: center;}
				.h_kiri {text-align: left;}
				.h_kanan {text-align: right;}
				.txt_judul {font-size: 12pt; font-weight: bold; padding-bottom: 15px;}
				.header_kolom {background-color: #cccccc; text-align: center; font-weight: bold;}
			</style>
			<span class="txt_judul">Laporan Neraca Saldo Periode '.$tgl_periode_txt_c.'</span>';
			$html .=  '<table class="table table-bordered">
			<tr class="header_kolom">
				<th style="text-align:center; width:5%"> </th>
				<th style="text-align:center; width:60%"> Nama Akun</th>
				<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_dari)).'</th>
				<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_sampai)).'</th>
			</tr>';
			$subtotald = 0; $subtotalc =0;$kel1=0;$kel2=0;$totaldebet=0;$totalkredit=0;
			foreach($kelompokakun as $kelompok) {
				$kel1=$kelompok['nama_kelompok'];
				$html .= '<tr>
						<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
						<td><strong>'. $kelompok['nama_kelompok'] .'</strong></td>
						<td></td>
						<td></td>
					</tr>';
					foreach($indukakun as $induk) {
						if ($induk['kelompok_akunid'] == $kelompok['kelompok_akunid']) 
						{
							$html .= '<tr>
								<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
								<td><strong>'.$induk['no_akun'].' - '.$induk['nama_akun'] .'</strong></td>
								<td></td>
								<td></td>
							</tr>';	
							foreach($jns_akun as $akun) { 
								$totaldebet += $akun['valuesamp'];
								$totalkredit += $akun['valuedari'];
								if (($akun['kelompok_akunid'] == $kelompok['kelompok_akunid']) && ($akun['induk_akun'] == $induk['jns_akun_id'])) 
								{
									$html .= '<tr>
										<td> &nbsp;</td>
										<td>'.$akun['no_akun'].' - '.$akun['nama_akun'] .'</td>
										<td align="right">'.number_format($akun['valuedari'],2,',','.') .'</td>
										<td align="right">'.number_format($akun['valuesamp'],2,',','.') .'</td>
									</tr>';	
									$subtotalc += $akun['valuedari']; $subtotald += $akun['valuesamp'];
								}
							}
						}
					}
					if ($kelompok['nama_kelompok'] != "" && $kel1 != $kel2) { 
						$html .= '<tr>
							<td colspan="2" class="h_kanan"><strong>TOTAL '.$kelompok['nama_kelompok'].'</strong></td>
							<td class="h_kanan">'.number_format(nsi_round($subtotalc),2,',','.').'</td>
							<td class="h_kanan">'.number_format(nsi_round($subtotald),2,',','.').'</td>
						</tr>';
						$data=0;$subtotalc=0;$subtotald=0;
					} 
					$kel2=$kelompok['nama_kelompok'];
				 }
			$html .= '</table>';

			$sql1 = "select kelompok_akunid, nama_kelompok
			from kelompok_akun
			where kelompok_akunid = 7
			order by no_urut asc ";
		$kelchan = $this->db->query($sql1)->result_array();
		$this->data['kelchan'] = $kelchan;

		$sql2 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
		from jns_akun
		where no_akun IN ('801.00.00','901.00.00') AND 
		kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'INDUK' order by jns_akun_id asc";
		$indukchan= $this->db->query($sql2)->result_array();
		$this->data['indukchan'] = $indukchan;

		$sql3 = "select jns_akun_id,no_akun,nama_akun,kelompok_akunid,induk_akun
		from jns_akun
		where no_akun IN ('801.01.01','901.01.01') AND 
		kelompok_laporan = 'Neraca' and aktif = 'Y' and jenis_akun = 'SUB AKUN' order by jns_akun_id asc";
		$chan= $this->db->query($sql3)->result_array();
		$this->data['chan'] = $chan;

		$html .=  '<br> <table class="table table-bordered">
		<tr class="header_kolom">
			<th style="text-align:center; width:5%"> </th>
			<th style="text-align:center; width:60%"> Nama Akun</th>
			<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_dari)).'</th>
			<th style="text-align:center; width:15%"> Bulan '. date("F Y",strtotime($tgl_sampai)).'</th>
		</tr>';
		foreach($kelchan as $kelompok) { $kel1=$kelompok['nama_kelompok'];
				$html .= ' <tr>
					<td class="h_tengah"> &nbsp; <i class="fa fa-folder-open-o"></i> </td>
					<td><strong>'. $kelompok['nama_kelompok'].'</strong></td>
					<td></td>
					<td></td>
				</tr>';	
			 foreach($indukchan as $induk) {
				$html .= '<tr>
							<td class="h_tengah"> &nbsp; <i class="fa fa-h-square"></i> </td>
							<td><strong>'.$induk["no_akun"]." - ".$induk['nama_akun'] .'</strong></td>
							<td></td>
							<td></td>
						</tr>';
					foreach($chan as $akun) { 
							if ($akun["kelompok_akunid"] == $induk["kelompok_akunid"] &&  $akun["induk_akun"] == $induk["jns_akun_id"])
							{
								$html .= '<tr>
										<td> &nbsp;</td>
										<td>'.$akun["no_akun"].' - '.$akun["nama_akun"].'</td>
										<td align="right">0</td>
										<td align="right">0</td>
									</tr>';	
							} 
					}	
			}
		 } 
		 $html .= '</table>';



		}
			

		echo $html;
		die();
	}
}