<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lap_laba_m extends CI_Model {

	public function __construct() {
		parent::__construct();
	}

	function get_jml_pinjaman($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		
		$this->db->select('SUM(jumlah) AS jml_total, SUM(provisi_pinjaman) as jml_prv');
		$this->db->from('v_hitung_pinjaman');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('month(tgl_pinjam) between '.$awal_bulan_dari.' and '.$bln_samp);
			$this->db->where('year(tgl_pinjam) = '.$thn_samp);
			
		}
		//var_dump($tgl_dari,' ',$tgl_samp);die();
		$query = $this->db->get();
		return $query->row();
	}

	function get_jml_estimasi_angsur($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));

		$this->db->select('SUM(ags_per_bulan * lama_angsuran) AS jml_total');
		$this->db->from('v_hitung_pinjaman');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('year(tgl_pinjam) = '.$thn_dari);
			$this->db->where('month(tgl_pinjam)between '.$awal_bulan_dari.' and '.$bln_samp);
		}

		$query = $this->db->get();
		return $query->row();
	}

	//jumlah biaya adm
	function get_jml_biaya_adm($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		$this->db->select('SUM(biaya_adm * lama_angsuran) AS jml_total');
		$this->db->from('v_hitung_pinjaman');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('month(tgl_pinjam)between '.$awal_bulan_dari.' and '.$bln_samp);
			$this->db->where('year(tgl_pinjam) = '.$thn_dari);
		}
		$query = $this->db->get();
		return $query->row();
	}

	//jumlah bunga
	function get_jml_bunga($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		$this->db->select('SUM(bunga_pinjaman * lama_angsuran) AS jml_total');
		$this->db->from('v_hitung_pinjaman');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('month(tgl_pinjam) between '.$awal_bulan_dari.' and '.$bln_samp);
			$this->db->where('year(tgl_pinjam) = '.$thn_dari);
		}
		$query = $this->db->get();
		return $query->row();
	}

	function get_jml_tagihan($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		$this->db->select('SUM(tagihan) AS jml_total');
		$this->db->from('v_hitung_pinjaman');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('month(tgl_pinjam) between '.$awal_bulan_dari.' and '.$bln_samp);
			$this->db->where('year(tgl_pinjam) = '.$thn_dari);
		}
		$query = $this->db->get();
		return $query->row();
	}

	function get_jml_angsuran($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		$this->db->select('SUM(jumlah_bayar) AS jml_total');
		$this->db->from('tbl_pinjaman_d');
		$this->db->join('tbl_pinjaman_h', 'tbl_pinjaman_h.id = tbl_pinjaman_d.pinjam_id', 'LEFT');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('month(tgl_pinjam) between '.$awal_bulan_dari.' and '.$bln_samp);
			$this->db->where('year(tgl_pinjam) = '.$thn_dari);
		}
		$query = $this->db->get();
		return $query->row();
	}

	function get_jml_denda($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bulan_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		$this->db->select('SUM(denda_rp) AS total_denda');
		$this->db->from('tbl_pinjaman_d');
		$this->db->join('tbl_pinjaman_h', 'tbl_pinjaman_h.id = tbl_pinjaman_d.pinjam_id', 'LEFT');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where('month(tgl_pinjam) between '.$awal_bulan_dari.' and '.$bln_samp);
			$this->db->where('year(tgl_pinjam) = '.$thn_dari);
		}
		$query = $this->db->get();
		return $query->row();
	}

	function get_peminjam_aktif($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where("year(tgl_pinjam) = year('".$tgl_dari."')");
			$this->db->where("month(tgl_pinjam) = month('".$tgl_dari."')");
		}

		$query = $this->db->get();
		return $query->num_rows();
	}

	//hitung jumlah peminjam lunas
	function get_peminjam_lunas($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('lunas','Lunas');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where("year(tgl_pinjam) = year('".$tgl_dari."')");
			$this->db->where("month(tgl_pinjam) = month('".$tgl_dari."')");
		}

		$query = $this->db->get();
		return $query->num_rows();
	}

	//hitung jumlah peminjam belum lunas
	function get_peminjam_belum($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$this->db->select('*');
		$this->db->from('v_hitung_pinjaman');
		$this->db->where('lunas','Belum');
		if ($jenis_laporan == 1) {
			$this->db->where('DATE(tgl_pinjam) >= ', ''.$tgl_dari.'');
			$this->db->where('DATE(tgl_pinjam) <= ', ''.$tgl_samp.'');
		} else {
			$this->db->where("year(tgl_pinjam) = year('".$tgl_dari."')");
			$this->db->where("month(tgl_pinjam) = month('".$tgl_dari."')");
		}

		$query = $this->db->get();
		return $query->num_rows();
	}

	function get_data_akun_dapat($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bln_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$awal_bln_samp = '01';
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		if ($jenis_laporan == 1) {
		$sql = "
			select jns_akun_id,no_akun,nama_akun,coalesce(induk_akun,'') as induk_akun,
			(
			select ifnull(sum(ifnull(za.credit,0)-ifnull(za.debit,0)),0)
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			where za.jns_akun_id = a.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_samp."'
			and z.validasi_status = 'X'
			) as value
			from jns_akun a 
			where aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 6
			order by no_akun ASC";
		} else {
			$sql = "
			select jns_akun_id,no_akun,nama_akun,coalesce(induk_akun,'') as induk_akun,
			(
			select ifnull(sum(ifnull(za.credit,0)-ifnull(za.debit,0)),0)
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			where za.jns_akun_id = a.jns_akun_id and month(z.journal_date) = ".$bln_samp."
			and year(z.journal_date) = ".$thn_samp." and z.validasi_status = 'X'
			) as value,
			(
				select ifnull(sum(ifnull(za.credit,0)-ifnull(za.debit,0)),0)
				from journal_voucher z 
				join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
        where za.jns_akun_id = a.jns_akun_id and month(z.journal_date) = ".$bln_dari."
        and year(z.journal_date) = ".$thn_dari."
				and z.validasi_status = 'X'
			) as valueold
			from jns_akun a 
			where aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 6
			order by no_akun ASC";
		}
		//var_dump($sql);die();
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_total_dapat($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bln_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$awal_bln_samp = '01';
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		if ($jenis_laporan == 1) {
		$sql = "
			select ifnull(sum(ifnull(za.credit,0)-ifnull(za.debit,0)),0) as value
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
			where z.journal_date between '".$tgl_dari."' and '".$tgl_samp."'
			and z.validasi_status = 'X'
			and aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 6
			order by no_akun ASC";
		} else {
			$sql = "
			select (
			select ifnull(sum(ifnull(za.credit,0)-ifnull(za.debit,0)),0) 
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
      where month(z.journal_date) = ".$bln_samp." 
      and year(z.journal_date) = ".$thn_samp."
			and z.validasi_status = 'X'
			and aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 6
			order by no_akun ASC
			) as value,
			(
			select ifnull(sum(ifnull(za.credit,0)-ifnull(za.debit,0)),0) 
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
			where month(z.journal_date) = ".$bln_dari." and year(z.journal_date) = ".$thn_dari."
			and z.validasi_status = 'X'
			and aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 6
			order by no_akun ASC
			) as valueold
			";
		}
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->row();
			return $out;
		} else {
			return array();
		}
	}

	function get_total_biaya($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bln_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$awal_bln_samp = '01';
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		if ($jenis_laporan == 1) {
			$sql = "
				select ifnull(sum(ifnull(za.debit,0)-ifnull(za.credit,0)),0) as value
				from journal_voucher z 
				join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
				join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
				where z.journal_date between '".$tgl_dari."' and '".$tgl_samp."'
				and z.validasi_status = 'X'
				and aktif = 'Y' 
				and kelompok_laporan = 'Laba Rugi'
				and kelompok_akunid = 5
				order by no_akun ASC";
		} else {
			$sql = "
				select 
				(
				select ifnull(sum(ifnull(za.debit,0)-ifnull(za.credit,0)),0) as value
				from journal_voucher z 
				join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
				join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
				where month(z.journal_date) =  ".$bln_samp." and year(z.journal_date) = ".$thn_samp."
				and z.validasi_status = 'X'
				and aktif = 'Y' 
				and kelompok_laporan = 'Laba Rugi'
				and kelompok_akunid = 5
				order by no_akun ASC
				) as value,
				(
					select ifnull(sum(ifnull(za.debit,0)-ifnull(za.credit,0)),0)
					from journal_voucher z 
					join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
					join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
					where month(z.journal_date) =  ".$bln_dari." and year(z.journal_date) = ".$thn_dari."
					and z.validasi_status = 'X'
					and aktif = 'Y' 
					and kelompok_laporan = 'Laba Rugi'
					and kelompok_akunid = 5
					order by no_akun ASC
				) as valueold";
		}
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->row();
			return $out;
		} else {
			return array();
		}
	}

	function get_data_akun_biaya($tgl_dari,$tgl_samp,$jenis_laporan=1) {
		$awal_bln_dari = '01';
		$bln_dari = date("m",strtotime($tgl_dari));
		$thn_dari = date("Y",strtotime($tgl_dari));
		$awal_bln_samp = '01';
		$bln_samp = date("m",strtotime($tgl_samp));
		$thn_samp = date("Y",strtotime($tgl_samp));
		if ($jenis_laporan == 1) {
		$sql = "
			select jns_akun_id,no_akun,nama_akun,coalesce(induk_akun,'') as induk_akun,
			(
			select ifnull(sum(ifnull(za.debit,0)-ifnull(za.credit,0)),0)
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			where za.jns_akun_id = a.jns_akun_id and z.journal_date between '".$tgl_dari."' and '".$tgl_samp."'
			and z.validasi_status = 'X'
			) as value
			from jns_akun a 
			where aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 5
			order by no_akun ASC";
		} else {
			$sql = "
			select jns_akun_id,no_akun,nama_akun,coalesce(induk_akun,'') as induk_akun,
			(
			select ifnull(sum(ifnull(za.debit,0)-ifnull(za.credit,0)),0)
			from journal_voucher z 
			join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
			where za.jns_akun_id = a.jns_akun_id and month(z.journal_date) = ".$bln_samp." and year(z.journal_date) = ".$thn_samp."
			and z.validasi_status = 'X'
			) as value,
			(
				select ifnull(sum(ifnull(za.debit,0)-ifnull(za.credit,0)),0)
				from journal_voucher z 
				join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
				where za.jns_akun_id = a.jns_akun_id and month(z.journal_date) =  ".$bln_dari." and year(z.journal_date) = ".$thn_dari."
				and z.validasi_status = 'X'
			) as valueold
			from jns_akun a 
			where aktif = 'Y' 
			and kelompok_laporan = 'Laba Rugi'
			and kelompok_akunid = 5
			order by no_akun ASC";
		}
		$query = $this->db->query($sql);
		if($query->num_rows() > 0) {
			$out = $query->result();
			return $out;
		} else {
			return array();
		}
	}

	function get_jml_akun($id){
		$this->db->select('debit,credit');
		$this->db->from('journal_voucher a'); 
		$this->db->join('journal_voucher_det b', 'b.journal_voucher_id=a.journal_voucherid', 'left');
		$this->db->where('b.jns_akun_id',$id);
		$query = $this->db->get();
		return $query->row();

	}
}