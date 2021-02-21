-- phpMyAdmin SQL Dump
-- version 4.9.5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Feb 21, 2021 at 07:05 AM
-- Server version: 10.2.36-MariaDB-cll-lve
-- PHP Version: 7.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gek2072_koperasi`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `ApproveAgsPinjaman` (IN `vid` INT, IN `vanggotaname` VARCHAR(150), IN `vpostby` VARCHAR(150))  BEGIN

	declare X, k, vcabangid, vdebit, vdebitakun,vjournalnum, vidjournal, vagsperbulan, vgiroakun1, vpokokbulansatu, vpokokbulansatuakun, 
	vbungabulansatu, vbungabulansatuakun, vsimpananwajib, vsimpananwajibakun integer;	
	declare vdate date;
	declare vtglbayar datetime;
	declare tahun VARCHAR(4);
	declare vjournalno, vjnstransaksi, vnomorpinjaman VARCHAR(50);
	declare vkredit, vkreditakun, colname VARCHAR(50);
	declare vket,vketangsuran, vketpokok, vketbunga, vketswajib, vbulantahun, vpostlog VARCHAR(250);
	DECLARE done INT DEFAULT FALSE;
	DECLARE cur1 CURSOR FOR  SELECT jumlah_bayar, jns_trans, tgl_bayar FROM tbl_pinjaman_d WHERE pinjam_id = vid;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;


	select nomor_pinjaman, angsuran_per_bulan, pencairan_bersih_akun, pokok_bulan_satu, pokok_bulan_satu_akun, 
		bunga_bulan_satu, bunga_bulan_satu_akun, simpanan_wajib, simpanan_wajib_akun, jns_cabangid 
		into vnomorpinjaman, vagsperbulan, vgiroakun1, vpokokbulansatu, vpokokbulansatuakun,
		vbungabulansatu, vbungabulansatuakun, vsimpananwajib, vsimpananwajibakun, vcabangid FROM tbl_pinjaman_h WHERE id = vid;
		
	  	select CURDATE() into vdate from dual;
	  	select year(vdate) into tahun;
		
		SET vjnstransaksi = CONCAT('Pembayaran Angsuran dan Simpanan Wajib ', tahun);	
		
	  	OPEN cur1;
			read_loop: LOOP 
			FETCH cur1 INTO vdebit, vdebitakun, vtglbayar;
				IF done THEN
					LEAVE read_loop;
				END IF;
						SELECT YEAR(vtglbayar) INTO tahun;
						SET vbulantahun = CONCAT(getbulan(vtglbayar),' ',tahun,' ');
						set vketangsuran = CONCAT('ANGSURAN ', vbulantahun, 'NO PINJ ',vnomorpinjaman);	
						SET vketpokok = CONCAT('POKOK ',vbulantahun, 'NO PINJ ',vnomorpinjaman);
					  	SET vketbunga = CONCAT('BUNGA ',vbulantahun, 'NO PINJ ',vnomorpinjaman);
					  	SET vketswajib = CONCAT('SIMPANAN WAJIB ',vbulantahun, 'NO PINJ ',vnomorpinjaman);
				 
				   SELECT max(journal_voucherid) AS jvid
				   INTO k
					FROM journal_voucher;
				  	
				  	select journal_no as nojurnal 
					into vjournalnum
					from journal_voucher 
					WHERE journal_voucherid = k;
					
					set vjournalnum = vjournalnum + 1;
					
					SELECT LPAD(vjournalnum, 7, 0)
						INTO vjournalno;
			
				INSERT INTO journal_voucher(journal_no, journal_date, jns_transaksi, headernote,validasi_status) 
                VALUES(vjournalno, vdate, 'Pemasukan Kas ', vjnstransaksi, 'X');
                
         SELECT journal_voucherid into vidjournal FROM journal_voucher WHERE journal_no = vjournalno;	
                
            INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getakunid('103.01.03'), vagsperbulan, 0, vcabangid, vketangsuran);
				INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, vpokokbulansatuakun, 0, vpokokbulansatu, vcabangid, vketpokok);	
				INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, vbungabulansatuakun, 0, vbungabulansatu, vcabangid, vketbunga);	
				INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, vsimpananwajibakun, 0, vsimpananwajib, vcabangid, vketswajib);	
                
             SET vpostlog = vjournalno;
  				 CALL inspostlog(vpostlog, vpostby, 'ANGSURAN DAN SIMPANAN',vidjournal);   
			 		
			END LOOP;
		CLOSE cur1;	
		
		CALL ApproveJournalPinjaman(vid, vanggotaname, vpostby);

END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `ApproveJournalPinjaman` (IN `vid` INT, IN `vanggotaname` VARCHAR(150), IN `vpostby` VARCHAR(150))  BEGIN

	declare X, k, vcabangid, vdebit, vdebitakun,vjournalnum, vidjournal, vagsperbulan, vpencairanbersih, vpokokbulansatu, vpokokbulansatuakun, 
	vbungabulansatu, vbungabulansatuakun, vsimpananwajib, vsimpananwajibakun integer;	
	declare vdate date;
	declare tahun VARCHAR(4);
	declare vjournalno, vjnstransaksi, vnomorpinjaman VARCHAR(50);
	declare vkredit, vkreditakun, colname VARCHAR(50);
	declare vket,vketangsuran, vketpokok, vketbunga, vketswajib, vpostlog VARCHAR(250);
	DECLARE done INT DEFAULT 0;
   
   	select nomor_pinjaman, ifnull(plafond_pinjaman,0) as dplafond_pinjaman, ifnull(plafond_pinjaman_akun, 0) AS dplafond_pinjaman_akun, 
		angsuran_per_bulan, pencairan_bersih, pokok_bulan_satu, pokok_bulan_satu_akun, 
		bunga_bulan_satu, bunga_bulan_satu_akun, simpanan_wajib, simpanan_wajib_akun, jns_cabangid 
		into vnomorpinjaman, vdebit, vdebitakun, vagsperbulan, vpencairanbersih, vpokokbulansatu, vpokokbulansatuakun,
		vbungabulansatu, vbungabulansatuakun, vsimpananwajib, vsimpananwajibakun, vcabangid FROM tbl_pinjaman_h WHERE id = vid;
		select CURDATE() into vdate from dual;
		select year(vdate) into tahun;
		
		SET vjnstransaksi = CONCAT('Pencairan Pinjaman ', tahun);
		
		SELECT max(journal_voucherid) AS jvid
				   INTO k
					FROM journal_voucher;
				  	
				  	select journal_no as nojurnal 
					into vjournalnum
					from journal_voucher 
					WHERE journal_voucherid = k;
					
					set vjournalnum = vjournalnum + 1;
					
					SELECT LPAD(vjournalnum, 7, 0)
						INTO vjournalno;
		
		
        INSERT INTO journal_voucher (journal_no, journal_date, jns_transaksi, headernote, validasi_status) 
                VALUES(vjournalno, vdate, 'Pengeluaran Kas ', vjnstransaksi, 'X');
        
		  SELECT journal_voucherid into vidjournal FROM journal_voucher WHERE journal_no = vjournalno;		
		  
		  INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, vdebitakun, vdebit, 0, vcabangid, CONCAT('PENC PINJ XTR PLATINUM AN ',vanggotaname)); 
		  	             
		   SET X = 1;
		 
			loop_journal:  LOOP
				IF  x > 9 THEN 
					LEAVE  loop_journal;
				END  IF;
				      
				if x = 1 then
					set vkredit = 'biaya_asuransi', vkreditakun = 'biaya_asuransi_akun', vket = CONCAT('PREM ASS PENC PINJ XTR PLATINUM AN ',vanggotaname);
				else
				if x = 2 then
					set vkredit = 'biaya_materai', vkreditakun = 'biaya_materai_akun',  vket = CONCAT('PEND MATERAI PENC PINJ XTR PLATINUM AN ',vanggotaname);
				else
				if x = 3 then
					set vkredit = 'simpanan_pokok', vkreditakun = 'simpanan_pokok_akun', vket = CONCAT('SIMP POKOK PENC PINJ XTR PLATINUM AN ',vanggotaname);
				else
				if x = 4 then
					set vkredit = 'biaya_administrasi', vkreditakun = 'biaya_administrasi_akun', vket = CONCAT('PEND ADM PENC PINJ XTR PLATINUM AN ',vanggotaname);
				else
				if x = 5 then
					set 	vkredit = 'pokok_bulan_satu', vkreditakun = 'pokok_bulan_satu_akun', vket=CONCAT('ANGS POKOK BLN KE 1 PENC PINJ XTR PLATINUM AN ', vanggotaname);
				else
				if x = 6 then
					set vkredit = 'pokok_bulan_dua', vkreditakun = 'pokok_bulan_dua_akun', vket=CONCAT('ANGS POKOK BLN KE 2 PENC PINJ XTR PLATINUM AN ', vanggotaname);
				else
				if x = 7 then
					set vkredit = 'bunga_bulan_satu', vkreditakun = 'bunga_bulan_satu_akun', vket=CONCAT('ANGS BUNGA BLN KE 1 PENC PINJ XTR PLATINUM AN ', vanggotaname);
				else
				if x = 8 then
					set vkredit = 'bunga_bulan_dua', vkreditakun = 'bunga_bulan_dua_akun', vket=CONCAT('ANGS BUNGA BLN KE 2 PENC PINJ XTR PLATINUM AN ', vanggotaname);	
					else
				if x = 9 then
					set vkredit = 'simpanan_wajib', vkreditakun = 'simpanan_wajib_akun', vket=CONCAT('SIMP WAJIB PENC PINJ XTR PLATINUM AN ', vanggotaname);				
				END if;
				END if;
				END if;
				END if;
				END if;
				END if;
				END if;
				END if;
				END if;		
					

				INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getvaltblpinjaman(vid, vkreditakun), 0, getvaltblpinjaman(vid,vkredit), vcabangid, vket);
                
				SET  x = x + 1;	 
			END LOOP;   
			
			set vket=CONCAT('SIMP WAJIB PENC PINJ XTR PLATINUM AN ', vanggotaname);
			INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getakunid('103.01.03'), 0, vpencairanbersih, vcabangid, vket);
                
         SET vpostlog = vjournalno;
  				 CALL inspostlog(vpostlog, vpostby, 'PINJAMAN PENCAIRAN BERSIH',vidjournal);          
			

END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `ApproveJournalSimpanan` (IN `vid` INT, IN `vpostby` VARCHAR(150))  BEGIN

	DECLARE k, vidjournal, vcabangid INTEGER;
	DECLARE vjumlah DECIMAL(10,2);
	DECLARE vjournalnum, vjournalno VARCHAR(50);
	DECLARE vket, vpostlog VARCHAR(150);
	DECLARE vdate DATE;
	
	SELECT jumlah, jns_cabangid into vjumlah, vcabangid FROM tbl_trans_sp WHERE id = vid;
	SELECT CURDATE() into vdate from dual;
	
	SELECT max(journal_voucherid) AS jvid
	INTO k
	FROM journal_voucher;
				  	
	SELECT journal_no as nojurnal 
	INTO vjournalnum
	FROM journal_voucher 
	WHERE journal_voucherid = k;
					
	SET vjournalnum = vjournalnum + 1;
					
	SELECT LPAD(vjournalnum, 7, 0)
	INTO vjournalno;
	
	SET vket = 'SIMPANAN SUKARELA ANGGOTA';	
	
	INSERT INTO journal_voucher(journal_no, journal_date, jns_transaksi, headernote, validasi_status) 
                VALUES(vjournalno, vdate, 'Pemasukan Kas ', ' PENERIMAAN SIMPANAN SUKARELA ANGGOTA','X');
                
  SELECT journal_voucherid INTO vidjournal FROM journal_voucher WHERE journal_no = vjournalno;	
                
	INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getakunid('107.01.01'), vjumlah, 0, vcabangid, vket);
                
	INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getakunid('270.01.03'), 0, vjumlah, vcabangid, vket);	
                
	SET vpostlog = vjournalno;
  				 CALL inspostlog(vpostlog, vpostby, 'SIMPANAN',vidjournal);  
END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `InsertSHU` (IN `vdate` DATE)  BEGIN
  DECLARE k,l INT;
  DECLARE vlaba DECIMAL(30,2);
  
  SET vdate = LAST_DAY(vdate);
  
  SELECT ifnull(SUM(ifnull(b.credit,0) - ifnull(b.debit,0)),0)
  INTO vlaba
  FROM journal_voucher a
  JOIN journal_voucher_det b ON b.journal_voucher_id = a.journal_voucherid
  JOIN jns_akun c ON c.jns_akun_id = b.jns_akun_id
  WHERE c.kelompok_laporan = 'Laba Rugi' 
  AND c.jenis_akun = 'SUB AKUN'
  AND month(a.journal_date) = MONTH(vdate)
  AND YEAR(a.journal_date) = YEAR(vdate);
  
  SELECT IFNULL(COUNT(1),0)
  INTO k
  FROM journal_voucher a
  JOIN journal_voucher_det b ON b.journal_voucher_id = a.journal_voucherid
  WHERE b.jns_akun_id = 79
  AND a.journal_date = vdate
  AND a.jns_transaksi = 'Pemindahbukuan';
  
  if (k > 0) then 
    SELECT a.journal_voucherid, b.journal_voucher_detid
    INTO k,l
    FROM journal_voucher a
    JOIN journal_voucher_det b ON b.journal_voucher_id = a.journal_voucherid
    WHERE b.jns_akun_id = 79
    AND a.journal_date = vdate
    AND a.jns_transaksi = 'Pemindahbukuan'
    LIMIT 1;
    
    if (vlaba < 0) then
      UPDATE journal_voucher_det
      SET debit = vlaba * -1, credit = 0
      WHERE journal_voucher_detid = l;  
    ELSE 
      UPDATE journal_voucher_det
      SET credit = vlaba, debit = 0
      WHERE journal_voucher_detid = l;  
    END if;
  else
    INSERT INTO journal_voucher (journal_no,journal_date,jns_transaksi,headernote,validasi_status)
    VALUES (CONCAT('SHU',MONTH(vdate),YEAR(vdate)),vdate,'Pemindahbukuan',CONCAT('PERHITUNGAN LABA/RUGI ',MONTH(vdate),' ',YEAR(vdate)),'X');
    
    SET k = LAST_INSERT_ID();
    
    if (vlaba < 0) then
      INSERT INTO journal_voucher_det (journal_voucher_id,jns_akun_id,debit,credit,jns_cabangid,itemnote)
      VALUES (k,79,vlaba,0,0,CONCAT('PERHITUNGAN LABA/RUGI ',MONTH(vdate),' ',YEAR(vdate)));
    
    else
      INSERT INTO journal_voucher_det (journal_voucher_id,jns_akun_id,debit,credit,jns_cabangid,itemnote)
      VALUES (k,79,0,vlaba,0,CONCAT('PERHITUNGAN LABA/RUGI ',MONTH(vdate),' ',YEAR(vdate)));
    
    END if;
  END if;
END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `inspostlog` (IN `vpostlog` TEXT, IN `vpostby` VARCHAR(150), IN `vpostjenis` VARCHAR(50), IN `vjid` INT)  BEGIN
	DECLARE vpostdate DATETIME;
	
	SELECT NOW() INTO vpostdate FROM DUAL;
	
	INSERT INTO postinglog (postdate, postby, jns_posting, postlog, journal_voucherid)
		VALUES (vpostdate, vpostby, vpostjenis, vpostlog, vjid); 

END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `JournalByrDiMuka` (IN `vid` INT, IN `vpostby` VARCHAR(150), IN `vbln` INT, IN `vthn` INT)  BEGIN
	DECLARE k, vnilaibayardimuka, vjournalnum, vidjournal, vcabangid, vsaldo, vbiayasewa, 
    vjangkawaktu, vdebitakun, vkreditakun, vjumlah,vawalsewa,vakhirsewa INTEGER;
	DECLARE vjnstransaksi, vjournalno, vpostlog VARCHAR(150);
	declare vdate date;
	DECLARE done INT DEFAULT FALSE;
	DECLARE cur1 CURSOR FOR  
    SELECT a.id,a.cabang_id,a.awal_sewa,a.akhir_sewa,a.saldo,a.biaya_sewa,a.jangka_waktu
    FROM sewa_kantor a
    WHERE a.id = vid 
    AND a.id NOT in
    (
    SELECT DISTINCT z.id
    FROM sewa_kantor_history z
    WHERE z.id = vid AND z.periodmonth = vbln AND z.periodyear = vthn
    )
    ;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

 		SET vdate = last_day(CONCAT(vthn,'-',vbln,'-01'));
		
		
 
 		OPEN cur1;
			read_loop: LOOP 
			FETCH cur1 INTO vid,vcabangid, vawalsewa,vakhirsewa,vsaldo, vbiayasewa, vjangkawaktu;
				IF done THEN
					LEAVE read_loop;
				END IF;
				 			
              SET vjnstransaksi = CONCAT('BDD SEWA KANTOR ',' BULAN ',vbln,' TAHUN ',vthn);
              
 					select max(journal_no) 
into vjournalnum
from journal_voucher where left(journal_no,1) = '0';
					
					set vjournalnum = vjournalnum + 1;
					
					SELECT LPAD(vjournalnum, 7, 0)
						INTO vjournalno;
 			
 			SET vjumlah = vsaldo / vjangkawaktu;
 			
 			 INSERT INTO journal_voucher(journal_no, journal_date, jns_transaksi, headernote, validasi_status) 
                VALUES(vjournalno, vdate, 'Pengeluaran Kas ', vjnstransaksi, 'X');
           
           SELECT journal_voucherid into vidjournal FROM journal_voucher WHERE journal_no = vjournalno;     
                
          INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getakunid('607.03.03'), vjumlah, 0, vcabangid, 'PENYUSUTAN GEDUNG KANTOR');
				INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
                VALUES(vidjournal, getakunid('145.01.01'), 0, vjumlah, vcabangid, 'PENYUSUTAN GEDUNG KANTOR');	
                
          SET vnilaibayardimuka = vbiayasewa - vjumlah;
          UPDATE sewa_kantor SET biaya_sewa = vnilaibayardimuka WHERE id = vid;
          
          SET vpostlog = vjournalno;
  			 CALL inspostlog(vpostlog, vpostby, 'POSTING BULANAN',vidjournal);
         
         INSERT INTO sewa_kantor_history(periodmonth,periodyear,id,cabang_id,awal_sewa,akhir_sewa,saldo,biaya_sewa,jangka_waktu)
         VALUES (vbln,vthn,vid,vcabangid, vawalsewa,vakhirsewa,vsaldo, vnilaibayardimuka, vjangkawaktu);
			 
 			END LOOP;
		CLOSE cur1;	

END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `JournalPostingBulanan` (IN `vid` INT, IN `vpostby` VARCHAR(150), IN `vbln` INT, IN `vthn` INT)  BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE vdate,vtanggalefektif DATE;
	DECLARE vpostlog TEXT;
	DECLARE vket1, vket2,vkodeasset,vnamaasset,vlokasiasset,vstatus VARCHAR(150);
	DECLARE vkategoriasset, vidjournal,vusiafiskal,vbarangid INTEGER;
	DECLARE vjournalno, vheadernote, vjnstransaksi, vakunsusut, vakunakumulasisusut VARCHAR(50);
	DECLARE vhargaperolehan, vnilaibuku, vakumulasipenyusutan, vnewnilaibuku, vassetid, vcabangid INTEGER;
	DECLARE k, vjournalnum, vjumlahakumulasi,vdepresia INTEGER;
	DECLARE cur1 CURSOR FOR 
    SELECT kode_asset_id,kode_asset,nama_asset,lokasi_asset,`kategori_asset`,`status`,`tanggal_efektif`,
      harga_perolehan,akumulasi_penyusutan,nilai_buku,depresia,usia_fiskal,barang_id,jns_cabangid
    FROM fixed_asset a
    WHERE kode_asset_id = vid
    AND kode_asset_id NOT in
    (
      SELECT DISTINCT kode_asset_id
      FROM fixed_asset_history 
      WHERE periodmonth = vbln AND periodyear = vthn AND kode_asset_id = vid
    )
    ;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	
  OPEN cur1;
  read_loop: LOOP
    FETCH cur1 INTO vassetid, vkodeasset,vnamaasset,vlokasiasset,vkategoriasset,vstatus,vtanggalefektif,vhargaperolehan, vakumulasipenyusutan, vnilaibuku,  vdepresia,vusiafiskal,vbarangid,vcabangid;
    
    IF done THEN
      LEAVE read_loop;
    END IF;

select max(journal_no) 
into vjournalnum
from journal_voucher where left(journal_no,1) = '0';
					
    SET vjournalnum = vjournalnum + 1;
					
    SELECT LPAD(vjournalnum, 7, 0)
    INTO vjournalno;
    
    SET vdate = last_day(CONCAT(vthn,'-',vbln,'-01'));
			
    SELECT accpenyusutan, accakumulasipenyusutan 
    INTO vakunsusut, vakunakumulasisusut
    FROM kategori_asset WHERE kategori_asset_id = vkategoriasset;
	 
    SET vheadernote = CONCAT(SUBSTRING_INDEX(getnamaakun(vakunsusut), '-', -1),' KODE ASSET ',vkodeasset, ' BULAN ',vbln,' TAHUN ',vthn);
    SET vjnstransaksi = TRIM(LEADING FROM REPLACE(SUBSTRING_INDEX(getnamaakun(vakunsusut), '-', -1),'KANTOR',''));
   
    SET vakumulasipenyusutan = vakumulasipenyusutan + vdepresia;
    SET vnilaibuku = vhargaperolehan - vakumulasipenyusutan;  		
  		
    SET vket1 = vheadernote;
    SET vket2 = vheadernote;
    
    if (vnilaibuku > 0) then
  		
		INSERT INTO journal_voucher(journal_no, journal_date, jns_transaksi, headernote, validasi_status) 
    VALUES(vjournalno, vdate, vjnstransaksi, vheadernote, 'X');
    
    SET vidjournal = LAST_INSERT_ID();
		  		
		INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
    VALUES(vidjournal, getakunid(vakunsusut), vdepresia, 0, vcabangid, vket1);
    
    INSERT INTO journal_voucher_det (journal_voucher_id, jns_akun_id, debit, credit, jns_cabangid, itemnote) 
    VALUES(vidjournal, getakunid(vakunakumulasisusut),0,  vdepresia, vcabangid, vket2);
              
    SET vpostlog = vjournalno;
		CALL inspostlog(vpostlog, vpostby, CONCAT('POSTING BULANAN ASET ',vkodeasset), vidjournal);
  		
    UPDATE fixed_asset 
    SET nilai_buku = vnilaibuku,akumulasi_penyusutan = vakumulasipenyusutan
    WHERE kode_asset_id = vassetid;
    
    INSERT INTO fixed_asset_history (kode_asset_id,kode_asset,nama_asset,lokasi_asset,`kategori_asset`,`status`,`tanggal_efektif`,
      harga_perolehan,akumulasi_penyusutan,nilai_buku,depresia,usia_fiskal,barang_id,jns_cabangid,periodmonth,periodyear)
    VALUES (vassetid, vkodeasset,vnamaasset,vlokasiasset,vkategoriasset,vstatus,vtanggalefektif,vhargaperolehan, vakumulasipenyusutan, vnilaibuku,  vdepresia,vusiafiskal,vbarangid,vcabangid,vbln,vthn);
    
    END if;
    
  END LOOP;
  
  CLOSE cur1;  
END$$

CREATE DEFINER=`gek2072`@`localhost` PROCEDURE `SimulasiPinjaman` (IN `vid` INT)  BEGIN
  DECLARE vjenis_pinjaman,vlama_angsuran,i,vdenda_hari,vtenor INT;
  DECLARE vjumlah_angsuran, vsimpanan_wajib,vsisa_pokok_awal,vangsuran_pokok,vangsuran_bunga,vtotal_angsuran_bank,vsisa_pokok_akhir, vangsuran_debitur,vplafond_pinjaman,vrate1, vrate2, vadmin_angsuran,vbiaya_adm, vpokok_angsuran,vbunga_pinjaman,vprovisi_pinjaman DECIMAL(30,2);
  DECLARE vdate,vtempo DATE;
  
  DELETE FROM tbl_pinjaman_simulasi
  WHERE tbl_pinjam_hid = vid;
  
  SELECT a.jenis_pinjam, a.lama_angsuran, date(a.tgl_pinjam), a.plafond_pinjaman, a.bunga, a.biaya_adm, a.lama_angsuran,
    a.pokok_angsuran,a.bunga_pinjaman,a.provisi_pinjaman,a.simpanan_wajib,a.tempo
  INTO vjenis_pinjaman,vlama_angsuran, vdate, vplafond_pinjaman, vrate2, vrate1, vtenor, vpokok_angsuran, vbunga_pinjaman, vprovisi_pinjaman,vsimpanan_wajib,vtempo
  FROM v_hitung_pinjaman a
  WHERE a.id = vid;
  
  SELECT b.opsi_val
  INTO vdenda_hari
  FROM suku_bunga b
  WHERE b.opsi_key = 'denda_hari';
  
  SELECT b.opsi_val
  INTO vbiaya_adm
  FROM suku_bunga b
  WHERE b.opsi_key = 'biaya_adm';
  
  SET i = 0;
  
  SET vsisa_pokok_awal = 0;  
  SET vjumlah_angsuran = 0;
  SET vsimpanan_wajib = 0;
  SET vangsuran_pokok = 0;
  SET vangsuran_bunga = 0;
  SET vtotal_angsuran_bank = 0;
  SET vsisa_pokok_akhir = 0;
  SET vangsuran_debitur = 0;
  SET vadmin_angsuran = 0;
  
  while i < vlama_angsuran DO
    if (vjenis_pinjaman = 9) then
      if (vsisa_pokok_awal = 0) then
        SET vsisa_pokok_awal = vplafond_pinjaman;
      END if;
      /*=($D$3*($D$5/12))/(1-1/(1+$D$5/12)^$D$4)*/
      SET vtotal_angsuran_bank = (vplafond_pinjaman * (vrate2 / 100) / 12) / (1-1/pow(1+((vrate2/100)/12),vtenor));
      SET vangsuran_debitur = (vplafond_pinjaman * (vrate1 / 100) / 12) / (1-1/pow(1+((vrate1/100)/12),vtenor));
      SET vangsuran_bunga = (vsisa_pokok_awal * (vrate2 / 100) / 12);
      SET vangsuran_pokok = vtotal_angsuran_bank - vangsuran_bunga;
      SET vsisa_pokok_akhir = vsisa_pokok_awal - vangsuran_pokok;
      SET vadmin_angsuran = vangsuran_debitur - vtotal_angsuran_bank;
      SET vbiaya_adm = vrate1;
      SET vjumlah_angsuran = vangsuran_debitur;
    else
      SET vangsuran_pokok = vpokok_angsuran * 1;
      SET vangsuran_bunga = vbunga_pinjaman;
      SET vjumlah_angsuran = vangsuran_pokok + vangsuran_bunga + vsimpanan_wajib;
    END if;
    
    INSERT INTO tbl_pinjaman_simulasi (tempo,tbl_pinjam_hid,blnke,periode,plafondpinjaman,bunga,biayaadm,sisapokokawal,angsuranpokok,angsuranbunga,totalangsuranbank,sisapokokakhir,adminangsuran,angsurandebitur,simpananwajib,jumlahangsuran)
    VALUES (vtempo,vid,i+1,concat(year(DATE_ADD(vdate,interval i+1 MONTH)),'-',MONTH(DATE_ADD(vdate,interval i+1 MONTH)),'-',vdenda_hari),vplafond_pinjaman,vrate2,vbiaya_adm,vsisa_pokok_awal,vangsuran_pokok,vangsuran_bunga,vtotal_angsuran_bank,vsisa_pokok_akhir,vadmin_angsuran,vangsuran_debitur,vsimpanan_wajib,vjumlah_angsuran);  
    
    if (vjenis_pinjaman = 9) then
      SET vsisa_pokok_awal = vsisa_pokok_akhir;
    END if;
    
    SET i = i + 1;
  END while;
  
END$$

--
-- Functions
--
CREATE DEFINER=`gek2072`@`localhost` FUNCTION `getakunid` (`vnoakun` VARCHAR(50)) RETURNS INT(11) BEGIN
DECLARE vakunid  INT;

	SELECT jns_akun_id
	INTO vakunid
	FROM jns_akun
	WHERE no_akun = vnoakun;
	
	return vakunid;
END$$

CREATE DEFINER=`gek2072`@`localhost` FUNCTION `getbulan` (`TGL` DATETIME) RETURNS VARCHAR(50) CHARSET utf8 BEGIN
DECLARE BULAN VARCHAR(50);

	IF EXTRACT(MONTH FROM TGL) = 1 THEN
         set BULAN = 'JANUARI';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 2 THEN
         set BULAN = 'FEBRUARI';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 3 THEN
         set BULAN = 'MARET';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 4 THEN
         set BULAN = 'APRIL';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 5 THEN
         set BULAN = 'MEI';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 6 THEN
         set BULAN = 'JUNI';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 7 THEN
         set BULAN = 'JULI';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 8 THEN
         set BULAN = 'AGUSTUS';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 9 THEN
         set BULAN = 'SEPTEMBER';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 10 THEN
         set BULAN = 'OKTOBER';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 11 THEN
         set BULAN = 'NOVEMBER';
   ELSE 
	IF EXTRACT(MONTH FROM TGL) = 12 THEN
         set BULAN = 'DESEMBER';
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;
   END IF;

RETURN BULAN;

END$$

CREATE DEFINER=`gek2072`@`localhost` FUNCTION `getnamaakun` (`vnoakun` VARCHAR(50)) RETURNS VARCHAR(50) CHARSET utf8 BEGIN

	DECLARE vnamaakun VARCHAR(100);

	SELECT nama_akun
	INTO vnamaakun
	FROM jns_akun
	WHERE no_akun = vnoakun;
	
	RETURN vnamaakun;
	
END$$

CREATE DEFINER=`gek2072`@`localhost` FUNCTION `gettotalkelompok` (`vid` INT, `vstatus` VARCHAR(50), `vstartdate` DATE, `venddate` DATE) RETURNS DECIMAL(30,6) BEGIN
  DECLARE vret DECIMAL (30,6);
  if (vstatus = 'DEBET') then
  SELECT ifnull(sum(ifnull(debit,0)-ifnull(credit,0)),0) 
  INTO vret
	from journal_voucher z
	join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
	join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
  JOIN kelompok_akun zc ON zc.kelompok_akunid = zb.kelompok_akunid
	where zb.jenis_akun='SUB AKUN' AND z.journal_date BETWEEN vstartdate AND venddate AND zc.kelompok_akunid = vid
	AND z.validasi_status = 'X';
  ELSE 
  SELECT ifnull(sum(ifnull(credit,0)-ifnull(debit,0)),0) 
  INTO vret
	from journal_voucher z
	join journal_voucher_det za on za.journal_voucher_id = z.journal_voucherid
	join jns_akun zb on zb.jns_akun_id = za.jns_akun_id
  JOIN kelompok_akun zc ON zc.kelompok_akunid = zb.kelompok_akunid
	where zb.jenis_akun='SUB AKUN' AND z.journal_date BETWEEN vstartdate AND venddate AND zc.kelompok_akunid = vid
	AND z.validasi_status = 'X';
  END if;
  RETURN vret;
END$$

CREATE DEFINER=`gek2072`@`localhost` FUNCTION `getvaltblpinjaman` (`vid` INT, `vcol` VARCHAR(100)) RETURNS INT(11) BEGIN
DECLARE vresultcol INT;


	if vcol = 'biaya_administrasi' then
			SELECT biaya_administrasi
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'biaya_administrasi_akun' then
			SELECT biaya_administrasi_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;	
	else
	if vcol = 'biaya_asuransi' then
			SELECT biaya_asuransi
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'biaya_asuransi_akun' then
			SELECT biaya_asuransi_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;	
	else
	if vcol = 'biaya_materai' then
			SELECT biaya_materai
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'biaya_materai_akun' then
			SELECT biaya_materai_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	else
	if vcol = 'simpanan_pokok' then
			SELECT simpanan_pokok
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'simpanan_pokok_akun' then
			SELECT simpanan_pokok_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	else
	if vcol = 'pokok_bulan_satu' then
			SELECT pokok_bulan_satu
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'pokok_bulan_satu_akun' then
			SELECT pokok_bulan_satu_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	else
	if vcol = 'pokok_bulan_dua' then
			SELECT pokok_bulan_dua
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'pokok_bulan_dua_akun' then
			SELECT pokok_bulan_dua_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	else
	if vcol = 'bunga_bulan_satu' then
			SELECT bunga_bulan_satu
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'bunga_bulan_satu_akun' then
			SELECT bunga_bulan_satu_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	else
	if vcol = 'bunga_bulan_dua' then
			SELECT bunga_bulan_dua
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'bunga_bulan_dua_akun' then
			SELECT bunga_bulan_dua_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	else
	if vcol = 'simpanan_wajib' then
			SELECT simpanan_wajib
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;		
	else
	if vcol = 'simpanan_wajib_akun' then
			SELECT simpanan_wajib_akun
			INTO vresultcol
			FROM tbl_pinjaman_h WHERE id = vid;
	END IF;
	END IF;		
	END IF;
	END IF;
	END IF;
	END IF;		
	END IF;
	END IF;		
	END IF;
	END IF;			
	END IF;
	END IF;
	END IF;
	END IF;	
	END IF;
	END IF;	
	END IF;
	END if;
	
RETURN vresultcol;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `auto_debet_tempo`
--

CREATE TABLE `auto_debet_tempo` (
  `id` int(11) NOT NULL,
  `status_anggota` int(11) NOT NULL,
  `tanggal_tempo` int(11) NOT NULL,
  `kas_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `auto_debet_tempo`
--

INSERT INTO `auto_debet_tempo` (`id`, `status_anggota`, `tanggal_tempo`, `kas_id`) VALUES
(1, 1, 12, 1),
(2, 2, 27, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ci_sessions`
--

CREATE TABLE `ci_sessions` (
  `session_id` varchar(40) NOT NULL DEFAULT '0',
  `ip_address` varchar(45) NOT NULL DEFAULT '0',
  `user_agent` varchar(120) NOT NULL,
  `last_activity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `user_data` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `ci_sessions`
--

INSERT INTO `ci_sessions` (`session_id`, `ip_address`, `user_agent`, `last_activity`, `user_data`) VALUES
('2b8f06665cf939aafd1bab98619f096a', '10.0.1.218', '', 1613856245, ''),
('e9e8b1470995d0dd797645dbf18b9936', '165.231.253.217', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1613862390, ''),
('362260ddc3781dc5b3e6585389d465d7', '36.71.241.85', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36', 1613862420, 'a:4:{s:9:\"user_data\";s:0:\"\";s:5:\"login\";b:1;s:6:\"u_name\";s:5:\"admin\";s:5:\"level\";s:5:\"Admin\";}'),
('7b019ad3bdfbe8d224f89eb74c803fe3', '10.0.1.218', '', 1613856245, '');

-- --------------------------------------------------------

--
-- Table structure for table `fixed_asset`
--

CREATE TABLE `fixed_asset` (
  `kode_asset_id` bigint(20) NOT NULL,
  `kode_asset` varchar(150) CHARACTER SET latin1 NOT NULL,
  `nama_asset` varchar(200) CHARACTER SET latin1 NOT NULL,
  `lokasi_asset` varchar(200) CHARACTER SET latin1 NOT NULL,
  `kategori_asset` int(11) NOT NULL DEFAULT 0,
  `status` varchar(10) DEFAULT NULL,
  `tanggal_efektif` date DEFAULT NULL,
  `harga_perolehan` int(11) NOT NULL DEFAULT 0,
  `akumulasi_penyusutan` int(12) NOT NULL,
  `nilai_buku` int(12) NOT NULL,
  `depresia` int(12) NOT NULL,
  `usia_fiskal` int(5) NOT NULL,
  `barang_id` bigint(20) NOT NULL DEFAULT 0,
  `jns_cabangid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Master Asset';

--
-- Dumping data for table `fixed_asset`
--

INSERT INTO `fixed_asset` (`kode_asset_id`, `kode_asset`, `nama_asset`, `lokasi_asset`, `kategori_asset`, `status`, `tanggal_efektif`, `harga_perolehan`, `akumulasi_penyusutan`, `nilai_buku`, `depresia`, `usia_fiskal`, `barang_id`, `jns_cabangid`) VALUES
(51, '001/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(52, '003/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(53, '005/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(54, '007/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(55, '009/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(56, '011/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(57, '013/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(58, '015/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(59, '023/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(60, '025/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(61, 'CN69L4B45M', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-25', 780000, 731250, 48750, 16250, 4, 0, NULL),
(62, 'CN69L4B45P', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-24', 780000, 731250, 48750, 16250, 4, 0, NULL),
(63, 'CN69L4B4J93', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-19', 780000, 731250, 48750, 16250, 4, 0, NULL),
(64, 'CN69L4B5F9', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-20', 780000, 731250, 48750, 16250, 4, 0, NULL),
(65, 'CN69L4B5FZ', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-22', 780000, 731250, 48750, 16250, 4, 0, NULL),
(66, 'CN69L4B5HK', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-21', 780000, 731250, 48750, 16250, 4, 0, NULL),
(67, 'CN69L4B5J7', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-18', 780000, 731250, 48750, 16250, 4, 0, NULL),
(68, 'CN69L4B5JC', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-17', 780000, 731250, 48750, 16250, 4, 0, NULL),
(69, 'CN6CJ47287', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-23', 780000, 731250, 48750, 16250, 4, 0, NULL),
(70, 'CN6CN4730N', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-26', 780000, 731250, 48750, 16250, 4, 0, NULL),
(71, 'INV018/001', 'MEJA KANTOR JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 6000000, 2750000, 3250000, 125000, 4, 0, NULL),
(72, 'INV020/025', 'PRINTER CANON BUKIT TINGGI', 'PUSAT', 5, 'ACTIVE', '2020-04-01', 1400000, 204167, 1195833, 29167, 4, 0, NULL),
(73, 'INV020/026', 'LAPTOP LENOVO THINKPAD T44OP CI5 CAB BOGOR', 'PUSAT', 4, 'ACTIVE', '2020-04-30', 4000000, 500000, 3500000, 83333, 4, 0, NULL),
(74, 'INV020/027', 'PRINTER HP2135 CAB BOGOR', 'PUSAT', 5, 'ACTIVE', '2020-04-30', 750000, 93750, 656250, 15625, 4, 0, NULL),
(75, 'INV-1/0001', 'Meja kerja', 'PUSAT', 6, 'ACTIVE', '2017-10-01', 6000000, 4625000, 1375000, 125000, 4, 0, NULL),
(76, 'INV-1/0002', 'Kursi kerja & Almari', 'PUSAT', 6, 'ACTIVE', '2017-10-01', 9900000, 7631250, 2268750, 206250, 4, 0, NULL),
(77, 'INV-1/0003', 'PRINTER HP L120', 'PUSAT', 5, 'ACTIVE', '2016-06-01', 1600000, 1600000, 0, 33333, 4, 0, NULL),
(78, 'INV-1/0004', 'PRINTER HP L120', 'PUSAT', 5, 'ACTIVE', '2016-12-01', 1600000, 1566666, 33334, 33333, 4, 0, NULL),
(79, 'INV-1/0005', 'PRINTER HP M102A', 'PUSAT', 5, 'ACTIVE', '2017-12-01', 2500000, 1822916, 677084, 52083, 4, 0, NULL),
(80, 'INV-1/0006', 'RAK BERKAS', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 1900000, 1385416, 514584, 39583, 4, 0, NULL),
(81, 'INV-1/0007', 'RAK SEPATU', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 100000, 72916, 27084, 2083, 4, 0, NULL),
(82, 'INV-1/0008', 'MODEM BOLT', 'PUSAT', 6, 'ACTIVE', '2016-01-01', 300000, 300000, 0, 6250, 4, 0, NULL),
(83, 'INV-1/0009', 'MODEM BOLT', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 350000, 255209, 94791, 7292, 4, 0, NULL),
(84, 'INV-1/0010', 'HP CUG', 'PUSAT', 6, 'ACTIVE', '2016-01-01', 275000, 275000, 0, 5729, 4, 0, NULL),
(85, 'INV-1/0011', 'HP CUG', 'PUSAT', 6, 'ACTIVE', '2017-11-01', 300000, 225000, 75000, 6250, 4, 0, NULL),
(86, 'INV-1/0012', 'WHITE BOARD', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 100000, 72916, 27084, 2083, 4, 0, NULL),
(87, 'INV-1/0013', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-02-01', 7000000, 6562500, 437500, 145833, 4, 0, NULL),
(88, 'INV-1/0014', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-02-01', 7000000, 6562500, 437500, 145833, 4, 0, NULL),
(89, 'INV-1/0015', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-09-01', 7000000, 5541666, 1458334, 145833, 4, 0, NULL),
(90, 'INV-1/0016', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-09-01', 7000000, 5541666, 1458334, 145833, 4, 0, NULL),
(91, 'INV-1/0018', 'PC HP ALL IN ONE', 'PUSAT', 1, 'ACTIVE', '2016-03-01', 4500000, 4500000, 0, 93750, 4, 0, NULL),
(92, 'INV-1/0019', 'PC HP ALL IN ONE', 'PUSAT', 1, 'ACTIVE', '2016-03-01', 4500000, 4500000, 0, 93750, 4, 0, NULL),
(93, 'INV-17/0001', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(94, 'INV-17/0002', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(95, 'INV-17/0003', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(96, 'INV-17/0004', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(97, 'INV-17/0005', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(98, 'INV-17/0006', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(99, 'INV-17/0007', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(100, 'INV-17/0008', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(101, 'INV-17/0009', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(102, 'INV-17/0010', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(103, 'INV-17/0011', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(104, 'INV-17/0012', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(105, 'INV-17/0013', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(106, 'INV-17/0014', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(107, 'INV-17/0015', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(108, 'INV-17/0016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(109, 'INV-17/0017', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(110, 'INV-17/0018', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(111, 'INV-17/0019', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(112, 'INV-17/0020', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(113, 'INV-17/0021', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(114, 'INV-17/0022', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(115, 'INV-17/0023', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(116, 'INV-17/0024', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(117, 'INV-17/0025', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(118, 'INV-17/0026', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(119, 'INV-17/0027', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(120, 'INV-17/0028', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(121, 'INV-17/0029', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(122, 'INV-17/0030', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(123, 'INV-17/0031', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(124, 'INV-17/0032', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(125, 'INV-17/0033', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(126, 'INV-17/0034', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(127, 'INV-17/0035', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(128, 'INV-17/0036', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(129, 'INV-17/0037', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(130, 'INV-17/0038', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(131, 'INV-17/0039', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(132, 'INV-17/0040', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(133, 'INV18/002', 'KURSI STAFF JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 6000000, 2750000, 3250000, 125000, 4, 0, NULL),
(134, 'INV18/003', 'KURSI MANAJER JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 1200000, 550000, 650000, 25000, 4, 0, NULL),
(135, 'INV18/005', 'PC DELL STAF JAKARTA', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 14000000, 6416667, 7583333, 291667, 4, 0, NULL),
(136, 'INV18/006', 'PC DELL STAFF JAKARTA', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 14000000, 6416667, 7583333, 291667, 4, 0, NULL),
(137, 'INV18/007', 'PC HP STAF & MANAJER JAKARTA', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 9000000, 4125000, 4875000, 187500, 4, 0, NULL),
(138, 'INV18/008', 'PRINTER EPSON L120 JAKARTA', 'PUSAT', 5, 'ACTIVE', '2019-01-02', 3200000, 1466667, 1733333, 66667, 4, 0, NULL),
(139, 'INV18/009', 'PRINTER HP M102A JAKARTA', 'PUSAT', 5, 'ACTIVE', '2019-01-02', 2500000, 1145833, 1354167, 52083, 4, 0, NULL),
(140, 'INV18/010', 'PRINTER SCAN HP 2135 JAKARTA', 'PUSAT', 5, 'ACTIVE', '2019-01-02', 2100000, 962500, 1137500, 43750, 4, 0, NULL),
(141, 'INV18-004', 'LEMARI BERKAS JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 2700000, 1237500, 1462500, 56250, 4, 0, NULL),
(142, 'INV19/001', '1 UNIT PC', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 880000, 403333, 476667, 18333, 4, 0, NULL),
(143, 'INV19/002', 'MODEM AN ARIF GUSTAMAN', 'PUSAT', 6, 'ACTIVE', '2019-01-03', 500000, 229167, 270833, 10417, 4, 0, NULL),
(144, 'INV19/003', 'PROYEKTOR ACER X1223H CAB. MALANG', 'PUSAT', 6, 'ACTIVE', '2019-01-25', 5000000, 2187500, 2812500, 104167, 4, 0, NULL),
(145, 'INV19/004', 'PC 2', 'PUSAT', 1, 'ACTIVE', '2019-01-25', 880000, 385000, 495000, 18333, 4, 0, NULL),
(146, 'INV19/005', 'PC & INSTAL APLIKASI KKB', 'PUSAT', 1, 'ACTIVE', '2019-01-25', 8380000, 3666250, 4713750, 174583, 4, 0, NULL),
(147, 'INV19/006', 'MEJA KANTOR, LEMARI FILE DAN KUSEN PINTU', 'PUSAT', 6, 'ACTIVE', '2019-01-28', 14204000, 6214250, 7989750, 295917, 4, 0, NULL),
(148, 'INV19/007', 'HP CUG CAB. LUMAJANG', 'PUSAT', 6, 'ACTIVE', '2019-01-30', 300000, 131250, 168750, 6250, 4, 0, NULL),
(149, 'INV19/008', 'MEJA PRINTER DAN PAPAN TULIS', 'PUSAT', 6, 'ACTIVE', '2019-01-31', 1200000, 525000, 675000, 25000, 4, 0, NULL),
(150, 'INV19/010', 'INVENTARIS KANTOR 2', 'PUSAT', 6, 'ACTIVE', '2019-02-07', 3870000, 1693125, 2176875, 80625, 4, 0, NULL),
(151, 'INV19/011', '1 UNIT STAVOL KOMPUTER', 'PUSAT', 5, 'ACTIVE', '2019-02-18', 470000, 195834, 274166, 9792, 4, 0, NULL),
(152, 'INV19/012', '1 UNIT HP NOKIA 105', 'PUSAT', 6, 'ACTIVE', '2019-02-18', 300000, 125000, 175000, 6250, 4, 0, NULL),
(153, 'INV19/013', 'ASUS NOTEBOOK AN. ANGGI ANDRIANSYAH', 'PUSAT', 4, 'ACTIVE', '2019-02-19', 4400000, 1833334, 2566666, 91667, 4, 0, NULL),
(154, 'INV19/014', '1 UNIT PC', 'PUSAT', 1, 'ACTIVE', '2019-02-22', 880000, 366666, 513334, 18333, 4, 0, NULL),
(155, 'INV19/015', 'HP CUG CABANG TOMOHON', 'PUSAT', 6, 'ACTIVE', '2019-02-22', 275000, 114583, 160417, 5729, 4, 0, NULL),
(156, 'INV19/016', 'HP SAMSUNG B310 CAB. SELONG', 'PUSAT', 6, 'ACTIVE', '2019-03-01', 350000, 145834, 204166, 7292, 4, 0, NULL),
(157, 'INV19/017', '1 UNIT RUMAH', 'PUSAT', 7, 'ACTIVE', '2019-03-11', 450000000, 37500000, 412500000, 1875000, 20, 0, 56),
(158, 'INV19/018', 'PRINTER EPSON L310 SWAMITRA MALABAR', 'PUSAT', 5, 'ACTIVE', '2019-03-25', 1805000, 714479, 1090521, 37604, 4, 0, NULL),
(159, 'INV19/019', 'LAPTOP', 'PUSAT', 4, 'ACTIVE', '2019-03-30', 8600000, 3404167, 5195833, 179167, 4, 0, NULL),
(160, 'INV19/020', 'HP NOKIA N3 NEW BLACK CAB. MALANG', 'PUSAT', 6, 'ACTIVE', '2019-04-02', 1199000, 474604, 724396, 24979, 4, 0, NULL),
(161, 'INV19/021', '1 UNIT PC CAB. SELONG', 'PUSAT', 1, 'ACTIVE', '2019-04-15', 4200000, 1662500, 2537500, 87500, 4, 0, NULL),
(162, 'INV19/022', 'LAPTOP HP ENVY X360-13AG0022AU AN. MUZAMMIL', 'PUSAT', 4, 'ACTIVE', '2019-04-16', 14800000, 5550000, 9250000, 308333, 4, 0, NULL),
(163, 'INV19/023', 'HP ADVAN (CUG) CAB. CILEGON', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 250000, 93750, 156250, 5208, 4, 0, NULL),
(164, 'INV19/024', 'HP SAMSUNG B 310 E (CUG) CAB. TANJUNGPINANG', 'PUSAT', 6, 'ACTIVE', '2019-05-27', 320000, 113334, 206666, 6667, 4, 0, NULL),
(165, 'INV19/025', 'DP PEMBELIAN MOBIL', 'PUSAT', 7, 'ACTIVE', '2019-10-29', 54800000, 13700000, 41100000, 1141667, 4, 0, 56),
(166, 'INV19/026', '6 UNIT LAPTOP ASUS A409UA-BV351T', 'PUSAT', 4, 'ACTIVE', '2019-12-19', 38310000, 7981250, 30328750, 798125, 4, 0, NULL),
(167, 'INV19/027', 'LAPTOP ACER A314 CAB. PROBOLINGGO', 'PUSAT', 4, 'ACTIVE', '2019-02-04', 4200000, 1837500, 2362500, 87500, 4, 0, NULL),
(168, 'INV19/028', 'PRINTER & SCANNER TIPE HP ADVENTAGE 2135', 'PUSAT', 5, 'ACTIVE', '2019-02-04', 650000, 284375, 365625, 13542, 4, 0, NULL),
(169, 'INV19/029', 'PRINTER HP DESKJET INK ADVANTAGE 2135 CAB. TANGGUL', 'PUSAT', 5, 'ACTIVE', '2019-07-12', 700000, 233333, 466667, 14583, 4, 0, NULL),
(170, 'INV19/030', 'PRINTER HP DJ2135 CAB. ACEH', 'PUSAT', 5, 'ACTIVE', '2019-08-30', 700000, 204166, 495834, 14583, 4, 0, NULL),
(171, 'INV19/031', 'MEJA KANTOR 1/2 BIRO CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 800000, 300000, 500000, 16667, 4, 0, NULL),
(172, 'INV19/032', 'KURSI KANTOR STAF BERODA CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 1050000, 393750, 656250, 21875, 4, 0, NULL),
(173, 'INV19/033', 'KURSI NASABAH CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 1000000, 375000, 625000, 20833, 4, 0, NULL),
(174, 'INV19/034', 'LEMARI CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 450000, 168750, 281250, 9375, 4, 0, NULL),
(175, 'INV20/001', 'HP CUG PYTONE WHITE CAB. TEGAL', 'PUSAT', 6, 'ACTIVE', '2020-01-07', 240000, 50000, 190000, 5000, 4, 0, NULL),
(176, 'INV20/002', 'PRINTER CANON MG2570S CAB. MANADO', 'PUSAT', 5, 'ACTIVE', '2020-01-15', 820000, 170833, 649167, 17083, 4, 0, NULL),
(177, 'INV20/003', 'PRINTER EPSON L3110 CAB. KUPANG', 'PUSAT', 5, 'ACTIVE', '2020-01-16', 2600000, 487500, 2112500, 54167, 4, 0, NULL),
(178, 'INV20/006', 'PRINTER HP 2135 CAB PADANG', 'PUSAT', 5, 'ACTIVE', '2020-02-05', 620000, 116250, 503750, 12917, 4, 0, NULL),
(179, 'INV20/007', '1 UNIT PC SERVER INTEL CORE 17 9700 K (PUSAT)', 'PUSAT', 1, 'ACTIVE', '2020-02-06', 28300000, 5306250, 22993750, 589583, 4, 0, NULL),
(180, 'INV20/008', '5 UNIT PC INTEL CORE 15 4570 FERIVIKASI DAN QA (PUSAT)', 'PUSAT', 1, 'ACTIVE', '2020-02-06', 22500000, 4218750, 18281250, 468750, 4, 0, NULL),
(181, 'INV20/009', '1 UNIT LENOVO THINKPAD E490 - X800 WILDAN (PUSAT)', 'PUSAT', 4, 'ACTIVE', '2020-02-06', 11650000, 2184375, 9465625, 242708, 4, 0, NULL),
(182, 'INV20/010', '1 UNIT LAPTOP LENOVO IDEAPAD 330S BRID ARIF G (PUSAT)', 'PUSAT', 4, 'ACTIVE', '2020-02-06', 8000000, 1500000, 6500000, 166667, 4, 0, NULL),
(183, 'INV20/011', '1 UNIT PRINTER BROTHER MFP 2540 DW OPR GG PUSAT JKT', 'PUSAT', 5, 'ACTIVE', '2020-02-06', 2565000, 480938, 2084062, 53438, 4, 0, NULL),
(184, 'INV20/012', '1 UNIT PRINTER BROTHER DCP 2540 DW OPR GG PUSAT JKT', 'PUSAT', 5, 'ACTIVE', '2020-02-06', 2550000, 478125, 2071875, 53125, 4, 0, NULL),
(185, 'INV20/013', '1 UNIT HARDDISK EXTERNAL 4 TB WD MY PASPORT GG PUSAT JKT', 'PUSAT', 5, 'ACTIVE', '2020-02-06', 1580000, 296250, 1283750, 32917, 4, 0, NULL),
(186, 'INV20/014', '1 UNIT LAPTOP ASUS X 441BA AMD CAB. DENPASAR', 'PUSAT', 4, 'ACTIVE', '2020-02-19', 5281000, 880167, 4400833, 110021, 4, 0, NULL),
(187, 'INV20/015', '1 UNIT PRINTER HP 310 INK TANK PSC CAB. DENPASAR', 'PUSAT', 5, 'ACTIVE', '2020-02-19', 1560000, 260000, 1300000, 32500, 4, 0, NULL),
(188, 'INV20/016', 'LAPTOP HP 141 DK0073AU CAB NGAWI', 'PUSAT', 4, 'ACTIVE', '2020-02-24', 3800000, 633334, 3166666, 79167, 4, 0, NULL),
(189, 'INV20/017', 'HP CUG CAB NGAWI', 'PUSAT', 6, 'ACTIVE', '2020-02-24', 235000, 39167, 195833, 4896, 4, 0, NULL),
(190, 'INV20/023', '1 UNIT LAPTOP LENOVO 330 CAB LUMAJANG', 'PUSAT', 4, 'ACTIVE', '2020-02-28', 3950000, 658334, 3291666, 82292, 4, 0, NULL),
(191, 'INV20/024', '1 UNIT PRINTER CANON MP 287 CAB LUMAJANG', 'PUSAT', 5, 'ACTIVE', '2020-02-28', 950000, 158334, 791666, 19792, 4, 0, NULL),
(192, 'INV20/025', '1 UNIT PC INTEL CORE I7M4770 TIM QA', 'PUSAT', 1, 'ACTIVE', '2020-05-29', 5520000, 575000, 4945000, 115000, 4, 0, NULL),
(193, 'INV20/026', '1 UNIT PRITER CANON G2010 CAB MADIUN', 'PUSAT', 5, 'ACTIVE', '2020-05-29', 1785000, 185938, 1599062, 37188, 4, 0, NULL),
(194, 'INV20/027', '1 UNIT SOFA TAMU CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 1885000, 196354, 1688646, 39271, 4, 0, NULL),
(195, 'INV20/028', '1 UNIT KURSI KANTOR CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 600000, 62500, 537500, 12500, 4, 0, NULL),
(196, 'INV20/029', '2 UNIT KIPAS ANGIN CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 530000, 55209, 474791, 11042, 4, 0, NULL),
(197, 'INV20/030', '1 UNIT LEMARI FILE CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 500000, 52084, 447916, 10417, 4, 0, NULL),
(198, 'INV20/031', '1 UNIT MEJA KANTOR CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 500000, 52084, 447916, 10417, 4, 0, NULL),
(199, 'INV20/032', '1 UNIT DISPENSER CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 155000, 16146, 138854, 3229, 4, 0, NULL),
(200, 'INV20/033', '1 UNIT MEJA KANTOR CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 1400000, 145834, 1254166, 29167, 4, 0, NULL),
(201, 'INV20/034', '4 UNIT KURSI SUSUN IMPERIAL CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 900000, 93750, 806250, 18750, 4, 0, NULL),
(202, 'INV20/035', '1 UNIT DISPENSER CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 275000, 28646, 246354, 5729, 4, 0, NULL),
(203, 'INV20/036', '1 UNIT KIPAS ANGIN MIYAKO CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 275000, 28646, 246354, 5729, 4, 0, NULL),
(204, 'INV20/037', '1 UNIT KARPET MDR 160 CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 200000, 20834, 179166, 4167, 4, 0, NULL),
(205, 'INV20/038', '1 UNIT LAPTOP ACER AMD A9', 'PUSAT', 4, 'ACTIVE', '2020-05-29', 4950000, 515625, 4434375, 103125, 4, 0, NULL),
(206, 'INV20/039', '1 UNIT LAPTOP ASUS X441 CAB JAMBI', 'PUSAT', 4, 'ACTIVE', '2020-06-30', 4000000, 333333, 3666667, 83333, 4, 0, NULL),
(207, 'INV20/040', '1 UNIT PRINTER HP DESKJET 2135 CAB JAMBI', 'PUSAT', 5, 'ACTIVE', '2020-06-30', 725000, 60417, 664583, 15104, 4, 0, NULL),
(208, 'INV20/041', 'BRANKAS CHUBBSAFES TYPE RPF 4 LACI KANTOR PUSAT GG JKT', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 8500000, 708333, 7791667, 177083, 4, 0, NULL),
(209, 'INV20/042', 'KURSI DAN MEJA TAMU RENG 321 CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 1200000, 100000, 1100000, 25000, 4, 0, NULL),
(210, 'INV20/043', '2 UNIT MEJA G-STAR 1/2 BIRO HITAM CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 800000, 66667, 733333, 16667, 4, 0, NULL),
(211, 'INV20/044', '2 UNIT KURSI KANTOR CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 650000, 54167, 595833, 13542, 4, 0, NULL),
(212, 'INV20/045', '2 UNIT STAND FAN COSMOS CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 480000, 40000, 440000, 10000, 4, 0, NULL),
(213, 'INV20/046', '1 UNIT RAK KUNA 5 TINGKAT CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 400000, 33333, 366667, 8333, 4, 0, NULL),
(214, 'INV20/047', '2 UNIT KURSI PLASTIK OL 209 COKLAT TUA CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 240000, 20000, 220000, 5000, 4, 0, NULL),
(215, 'INV20/048', '1 UNIT DISPENSER MIYAKO CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 200000, 16667, 183333, 4167, 4, 0, NULL),
(216, 'INV20/049', '1 UNIT PRINTER EPSON PRINT COPY CAB PALU', 'PUSAT', 5, 'ACTIVE', '2020-06-30', 2200000, 183333, 2016667, 45833, 4, 0, NULL),
(217, 'INV20/050', '2 UNIT MEJA KANTOR CAB TANJUNG PINANG', 'PUSAT', 6, 'ACTIVE', '2020-08-27', 1300000, 54166, 1245834, 27083, 4, 0, NULL),
(218, 'INV20/051', '2 UNIT MEJA TULIS DARK CAB TANJUNG PINANG', 'PUSAT', 6, 'ACTIVE', '2020-08-27', 1100000, 45834, 1054166, 22917, 4, 0, NULL),
(219, 'INV20/052', '2 UNIT KURSI KANTOR CAB TANJUNG PINANG', 'PUSAT', 6, 'ACTIVE', '2020-08-27', 1000000, 41666, 958334, 20833, 4, 0, NULL),
(220, 'INV20/18', '1 UNIT MEJA SHARING UK. 180 X 95 CM', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 1975000, 329167, 1645833, 41146, 4, 0, NULL),
(221, 'INV20/19', '2 UNIT EXHAUST FAN (KACA)', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 1900000, 316666, 1583334, 39583, 4, 0, NULL),
(222, 'INV20/20', '5 UNIT KURSI KERJA GG PUSAT', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 6375000, 1062501, 5312499, 132813, 4, 0, NULL),
(223, 'INV20/21', '5 UNIT KURSI HADAP GG PUSAT', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 5825000, 970833, 4854167, 121354, 4, 0, NULL),
(224, 'INV20/22', '2 UNIT MEJA KERJA UK. 100 CM X 60 CM + LACI GANTUNG', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 3110000, 518334, 2591666, 64792, 4, 0, NULL),
(225, 'INV20-004', 'LAPTOP LENOVO IPD V 130 AMD 4 CAB. MAROS', 'PUSAT', 4, 'ACTIVE', '2020-01-30', 3999000, 749813, 3249187, 83313, 4, 0, NULL),
(226, 'INV20-005', 'PRINTER 3 IN 1 CANON PIXMA E410', 'PUSAT', 5, 'ACTIVE', '2020-01-30', 800000, 150000, 650000, 16667, 4, 0, NULL),
(227, 'INV-26/0001', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(228, 'INV-26/0002', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(229, 'INV-26/0003', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(230, 'INV-26/0004', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(231, 'INV-26/0005', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(232, 'INV-26/0006', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(233, 'INV-26/0007', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(234, 'INV-26/0008', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(235, 'INV-26/0009', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(236, 'INV-26/0010', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `fixed_asset_history`
--

CREATE TABLE `fixed_asset_history` (
  `kode_asset_id` bigint(20) NOT NULL,
  `periodmonth` int(11) NOT NULL DEFAULT 0,
  `periodyear` int(11) NOT NULL DEFAULT 0,
  `kode_asset` varchar(150) CHARACTER SET latin1 NOT NULL,
  `nama_asset` varchar(200) CHARACTER SET latin1 NOT NULL,
  `lokasi_asset` varchar(200) CHARACTER SET latin1 NOT NULL,
  `kategori_asset` int(11) NOT NULL DEFAULT 0,
  `status` varchar(10) CHARACTER SET latin1 DEFAULT NULL,
  `tanggal_efektif` date NOT NULL DEFAULT '0000-00-00',
  `harga_perolehan` int(11) NOT NULL DEFAULT 0,
  `akumulasi_penyusutan` int(12) NOT NULL,
  `nilai_buku` int(12) NOT NULL,
  `depresia` int(12) NOT NULL,
  `usia_fiskal` int(5) NOT NULL,
  `barang_id` bigint(20) NOT NULL DEFAULT 0,
  `jns_cabangid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `fixed_asset_history`
--

INSERT INTO `fixed_asset_history` (`kode_asset_id`, `periodmonth`, `periodyear`, `kode_asset`, `nama_asset`, `lokasi_asset`, `kategori_asset`, `status`, `tanggal_efektif`, `harga_perolehan`, `akumulasi_penyusutan`, `nilai_buku`, `depresia`, `usia_fiskal`, `barang_id`, `jns_cabangid`) VALUES
(51, 10, 2020, '001/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(52, 10, 2020, '003/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(53, 10, 2020, '005/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(54, 10, 2020, '007/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(55, 10, 2020, '009/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(56, 10, 2020, '011/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(57, 10, 2020, '013/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(58, 10, 2020, '015/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(59, 10, 2020, '023/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(60, 10, 2020, '025/INV-GG/XII/2016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-01-17', 4100000, 3843750, 256250, 85417, 4, 0, NULL),
(61, 10, 2020, 'CN69L4B45M', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-25', 780000, 731250, 48750, 16250, 4, 0, NULL),
(62, 10, 2020, 'CN69L4B45P', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-24', 780000, 731250, 48750, 16250, 4, 0, NULL),
(63, 10, 2020, 'CN69L4B4J93', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-19', 780000, 731250, 48750, 16250, 4, 0, NULL),
(64, 10, 2020, 'CN69L4B5F9', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-20', 780000, 731250, 48750, 16250, 4, 0, NULL),
(65, 10, 2020, 'CN69L4B5FZ', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-22', 780000, 731250, 48750, 16250, 4, 0, NULL),
(66, 10, 2020, 'CN69L4B5HK', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-21', 780000, 731250, 48750, 16250, 4, 0, NULL),
(67, 10, 2020, 'CN69L4B5J7', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-18', 780000, 731250, 48750, 16250, 4, 0, NULL),
(68, 10, 2020, 'CN69L4B5JC', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-17', 780000, 731250, 48750, 16250, 4, 0, NULL),
(69, 10, 2020, 'CN6CJ47287', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-23', 780000, 731250, 48750, 16250, 4, 0, NULL),
(70, 10, 2020, 'CN6CN4730N', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-01-26', 780000, 731250, 48750, 16250, 4, 0, NULL),
(71, 10, 2020, 'INV018/001', 'MEJA KANTOR JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 6000000, 2750000, 3250000, 125000, 4, 0, NULL),
(72, 10, 2020, 'INV020/025', 'PRINTER CANON BUKIT TINGGI', 'PUSAT', 5, 'ACTIVE', '2020-04-01', 1400000, 204167, 1195833, 29167, 4, 0, NULL),
(73, 10, 2020, 'INV020/026', 'LAPTOP LENOVO THINKPAD T44OP CI5 CAB BOGOR', 'PUSAT', 4, 'ACTIVE', '2020-04-30', 4000000, 500000, 3500000, 83333, 4, 0, NULL),
(74, 10, 2020, 'INV020/027', 'PRINTER HP2135 CAB BOGOR', 'PUSAT', 5, 'ACTIVE', '2020-04-30', 750000, 93750, 656250, 15625, 4, 0, NULL),
(75, 10, 2020, 'INV-1/0001', 'Meja kerja', 'PUSAT', 6, 'ACTIVE', '2017-10-01', 6000000, 4625000, 1375000, 125000, 4, 0, NULL),
(76, 10, 2020, 'INV-1/0002', 'Kursi kerja & Almari', 'PUSAT', 6, 'ACTIVE', '2017-10-01', 9900000, 7631250, 2268750, 206250, 4, 0, NULL),
(78, 10, 2020, 'INV-1/0004', 'PRINTER HP L120', 'PUSAT', 5, 'ACTIVE', '2016-12-01', 1600000, 1566666, 33334, 33333, 4, 0, NULL),
(79, 10, 2020, 'INV-1/0005', 'PRINTER HP M102A', 'PUSAT', 5, 'ACTIVE', '2017-12-01', 2500000, 1822916, 677084, 52083, 4, 0, NULL),
(80, 10, 2020, 'INV-1/0006', 'RAK BERKAS', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 1900000, 1385416, 514584, 39583, 4, 0, NULL),
(81, 10, 2020, 'INV-1/0007', 'RAK SEPATU', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 100000, 72916, 27084, 2083, 4, 0, NULL),
(83, 10, 2020, 'INV-1/0009', 'MODEM BOLT', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 350000, 255209, 94791, 7292, 4, 0, NULL),
(85, 10, 2020, 'INV-1/0011', 'HP CUG', 'PUSAT', 6, 'ACTIVE', '2017-11-01', 300000, 225000, 75000, 6250, 4, 0, NULL),
(86, 10, 2020, 'INV-1/0012', 'WHITE BOARD', 'PUSAT', 6, 'ACTIVE', '2017-12-01', 100000, 72916, 27084, 2083, 4, 0, NULL),
(87, 10, 2020, 'INV-1/0013', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-02-01', 7000000, 6562500, 437500, 145833, 4, 0, NULL),
(88, 10, 2020, 'INV-1/0014', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-02-01', 7000000, 6562500, 437500, 145833, 4, 0, NULL),
(89, 10, 2020, 'INV-1/0015', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-09-01', 7000000, 5541666, 1458334, 145833, 4, 0, NULL),
(90, 10, 2020, 'INV-1/0016', 'PC DELL 3064', 'PUSAT', 1, 'ACTIVE', '2017-09-01', 7000000, 5541666, 1458334, 145833, 4, 0, NULL),
(93, 10, 2020, 'INV-17/0001', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(94, 10, 2020, 'INV-17/0002', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(95, 10, 2020, 'INV-17/0003', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(96, 10, 2020, 'INV-17/0004', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-06-17', 4100000, 3416667, 683333, 85417, 4, 0, NULL),
(97, 10, 2020, 'INV-17/0005', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(98, 10, 2020, 'INV-17/0006', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(99, 10, 2020, 'INV-17/0007', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(100, 10, 2020, 'INV-17/0008', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(101, 10, 2020, 'INV-17/0009', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-09-17', 4100000, 3160417, 939583, 85417, 4, 0, NULL),
(102, 10, 2020, 'INV-17/0010', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(103, 10, 2020, 'INV-17/0011', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(104, 10, 2020, 'INV-17/0012', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(105, 10, 2020, 'INV-17/0013', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(106, 10, 2020, 'INV-17/0014', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(107, 10, 2020, 'INV-17/0015', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(108, 10, 2020, 'INV-17/0016', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(109, 10, 2020, 'INV-17/0017', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(110, 10, 2020, 'INV-17/0018', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(111, 10, 2020, 'INV-17/0019', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(112, 10, 2020, 'INV-17/0020', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-11-17', 4100000, 2989584, 1110416, 85417, 4, 0, NULL),
(113, 10, 2020, 'INV-17/0021', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(114, 10, 2020, 'INV-17/0022', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(115, 10, 2020, 'INV-17/0023', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(116, 10, 2020, 'INV-17/0024', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(117, 10, 2020, 'INV-17/0025', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-06-17', 780000, 650000, 130000, 16250, 4, 0, NULL),
(118, 10, 2020, 'INV-17/0026', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(119, 10, 2020, 'INV-17/0027', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(120, 10, 2020, 'INV-17/0028', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(121, 10, 2020, 'INV-17/0029', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(122, 10, 2020, 'INV-17/0030', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-09-17', 780000, 601250, 178750, 16250, 4, 0, NULL),
(123, 10, 2020, 'INV-17/0031', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(124, 10, 2020, 'INV-17/0032', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(125, 10, 2020, 'INV-17/0033', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(126, 10, 2020, 'INV-17/0034', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(127, 10, 2020, 'INV-17/0035', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(128, 10, 2020, 'INV-17/0036', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(129, 10, 2020, 'INV-17/0037', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(130, 10, 2020, 'INV-17/0038', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(131, 10, 2020, 'INV-17/0039', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(132, 10, 2020, 'INV-17/0040', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-11-17', 780000, 568750, 211250, 16250, 4, 0, NULL),
(133, 10, 2020, 'INV18/002', 'KURSI STAFF JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 6000000, 2750000, 3250000, 125000, 4, 0, NULL),
(134, 10, 2020, 'INV18/003', 'KURSI MANAJER JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 1200000, 550000, 650000, 25000, 4, 0, NULL),
(135, 10, 2020, 'INV18/005', 'PC DELL STAF JAKARTA', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 14000000, 6416667, 7583333, 291667, 4, 0, NULL),
(136, 10, 2020, 'INV18/006', 'PC DELL STAFF JAKARTA', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 14000000, 6416667, 7583333, 291667, 4, 0, NULL),
(137, 10, 2020, 'INV18/007', 'PC HP STAF & MANAJER JAKARTA', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 9000000, 4125000, 4875000, 187500, 4, 0, NULL),
(138, 10, 2020, 'INV18/008', 'PRINTER EPSON L120 JAKARTA', 'PUSAT', 5, 'ACTIVE', '2019-01-02', 3200000, 1466667, 1733333, 66667, 4, 0, NULL),
(139, 10, 2020, 'INV18/009', 'PRINTER HP M102A JAKARTA', 'PUSAT', 5, 'ACTIVE', '2019-01-02', 2500000, 1145833, 1354167, 52083, 4, 0, NULL),
(140, 10, 2020, 'INV18/010', 'PRINTER SCAN HP 2135 JAKARTA', 'PUSAT', 5, 'ACTIVE', '2019-01-02', 2100000, 962500, 1137500, 43750, 4, 0, NULL),
(141, 10, 2020, 'INV18-004', 'LEMARI BERKAS JAKARTA', 'PUSAT', 6, 'ACTIVE', '2019-01-01', 2700000, 1237500, 1462500, 56250, 4, 0, NULL),
(142, 10, 2020, 'INV19/001', '1 UNIT PC', 'PUSAT', 1, 'ACTIVE', '2019-01-02', 880000, 403333, 476667, 18333, 4, 0, NULL),
(143, 10, 2020, 'INV19/002', 'MODEM AN ARIF GUSTAMAN', 'PUSAT', 6, 'ACTIVE', '2019-01-03', 500000, 229167, 270833, 10417, 4, 0, NULL),
(144, 10, 2020, 'INV19/003', 'PROYEKTOR ACER X1223H CAB. MALANG', 'PUSAT', 6, 'ACTIVE', '2019-01-25', 5000000, 2187500, 2812500, 104167, 4, 0, NULL),
(145, 10, 2020, 'INV19/004', 'PC 2', 'PUSAT', 1, 'ACTIVE', '2019-01-25', 880000, 385000, 495000, 18333, 4, 0, NULL),
(146, 10, 2020, 'INV19/005', 'PC & INSTAL APLIKASI KKB', 'PUSAT', 1, 'ACTIVE', '2019-01-25', 8380000, 3666250, 4713750, 174583, 4, 0, NULL),
(147, 10, 2020, 'INV19/006', 'MEJA KANTOR, LEMARI FILE DAN KUSEN PINTU', 'PUSAT', 6, 'ACTIVE', '2019-01-28', 14204000, 6214250, 7989750, 295917, 4, 0, NULL),
(148, 10, 2020, 'INV19/007', 'HP CUG CAB. LUMAJANG', 'PUSAT', 6, 'ACTIVE', '2019-01-30', 300000, 131250, 168750, 6250, 4, 0, NULL),
(149, 10, 2020, 'INV19/008', 'MEJA PRINTER DAN PAPAN TULIS', 'PUSAT', 6, 'ACTIVE', '2019-01-31', 1200000, 525000, 675000, 25000, 4, 0, NULL),
(150, 10, 2020, 'INV19/010', 'INVENTARIS KANTOR 2', 'PUSAT', 6, 'ACTIVE', '2019-02-07', 3870000, 1693125, 2176875, 80625, 4, 0, NULL),
(151, 10, 2020, 'INV19/011', '1 UNIT STAVOL KOMPUTER', 'PUSAT', 5, 'ACTIVE', '2019-02-18', 470000, 195834, 274166, 9792, 4, 0, NULL),
(152, 10, 2020, 'INV19/012', '1 UNIT HP NOKIA 105', 'PUSAT', 6, 'ACTIVE', '2019-02-18', 300000, 125000, 175000, 6250, 4, 0, NULL),
(153, 10, 2020, 'INV19/013', 'ASUS NOTEBOOK AN. ANGGI ANDRIANSYAH', 'PUSAT', 4, 'ACTIVE', '2019-02-19', 4400000, 1833334, 2566666, 91667, 4, 0, NULL),
(154, 10, 2020, 'INV19/014', '1 UNIT PC', 'PUSAT', 1, 'ACTIVE', '2019-02-22', 880000, 366666, 513334, 18333, 4, 0, NULL),
(155, 10, 2020, 'INV19/015', 'HP CUG CABANG TOMOHON', 'PUSAT', 6, 'ACTIVE', '2019-02-22', 275000, 114583, 160417, 5729, 4, 0, NULL),
(156, 10, 2020, 'INV19/016', 'HP SAMSUNG B310 CAB. SELONG', 'PUSAT', 6, 'ACTIVE', '2019-03-01', 350000, 145834, 204166, 7292, 4, 0, NULL),
(157, 10, 2020, 'INV19/017', '1 UNIT RUMAH', 'PUSAT', 7, 'ACTIVE', '2019-03-11', 450000000, 37500000, 412500000, 1875000, 20, 0, 56),
(158, 10, 2020, 'INV19/018', 'PRINTER EPSON L310 SWAMITRA MALABAR', 'PUSAT', 5, 'ACTIVE', '2019-03-25', 1805000, 714479, 1090521, 37604, 4, 0, NULL),
(159, 10, 2020, 'INV19/019', 'LAPTOP', 'PUSAT', 4, 'ACTIVE', '2019-03-30', 8600000, 3404167, 5195833, 179167, 4, 0, NULL),
(160, 10, 2020, 'INV19/020', 'HP NOKIA N3 NEW BLACK CAB. MALANG', 'PUSAT', 6, 'ACTIVE', '2019-04-02', 1199000, 474604, 724396, 24979, 4, 0, NULL),
(161, 10, 2020, 'INV19/021', '1 UNIT PC CAB. SELONG', 'PUSAT', 1, 'ACTIVE', '2019-04-15', 4200000, 1662500, 2537500, 87500, 4, 0, NULL),
(162, 10, 2020, 'INV19/022', 'LAPTOP HP ENVY X360-13AG0022AU AN. MUZAMMIL', 'PUSAT', 4, 'ACTIVE', '2019-04-16', 14800000, 5550000, 9250000, 308333, 4, 0, NULL),
(163, 10, 2020, 'INV19/023', 'HP ADVAN (CUG) CAB. CILEGON', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 250000, 93750, 156250, 5208, 4, 0, NULL),
(164, 10, 2020, 'INV19/024', 'HP SAMSUNG B 310 E (CUG) CAB. TANJUNGPINANG', 'PUSAT', 6, 'ACTIVE', '2019-05-27', 320000, 113334, 206666, 6667, 4, 0, NULL),
(165, 10, 2020, 'INV19/025', 'DP PEMBELIAN MOBIL', 'PUSAT', 7, 'ACTIVE', '2019-10-29', 54800000, 13700000, 41100000, 1141667, 4, 0, 56),
(166, 10, 2020, 'INV19/026', '6 UNIT LAPTOP ASUS A409UA-BV351T', 'PUSAT', 4, 'ACTIVE', '2019-12-19', 38310000, 7981250, 30328750, 798125, 4, 0, NULL),
(167, 10, 2020, 'INV19/027', 'LAPTOP ACER A314 CAB. PROBOLINGGO', 'PUSAT', 4, 'ACTIVE', '2019-02-04', 4200000, 1837500, 2362500, 87500, 4, 0, NULL),
(168, 10, 2020, 'INV19/028', 'PRINTER & SCANNER TIPE HP ADVENTAGE 2135', 'PUSAT', 5, 'ACTIVE', '2019-02-04', 650000, 284375, 365625, 13542, 4, 0, NULL),
(169, 10, 2020, 'INV19/029', 'PRINTER HP DESKJET INK ADVANTAGE 2135 CAB. TANGGUL', 'PUSAT', 5, 'ACTIVE', '2019-07-12', 700000, 233333, 466667, 14583, 4, 0, NULL),
(170, 10, 2020, 'INV19/030', 'PRINTER HP DJ2135 CAB. ACEH', 'PUSAT', 5, 'ACTIVE', '2019-08-30', 700000, 204166, 495834, 14583, 4, 0, NULL),
(171, 10, 2020, 'INV19/031', 'MEJA KANTOR 1/2 BIRO CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 800000, 300000, 500000, 16667, 4, 0, NULL),
(172, 10, 2020, 'INV19/032', 'KURSI KANTOR STAF BERODA CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 1050000, 393750, 656250, 21875, 4, 0, NULL),
(173, 10, 2020, 'INV19/033', 'KURSI NASABAH CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 1000000, 375000, 625000, 20833, 4, 0, NULL),
(174, 10, 2020, 'INV19/034', 'LEMARI CAB. PAMEKASAN', 'PUSAT', 6, 'ACTIVE', '2019-04-30', 450000, 168750, 281250, 9375, 4, 0, NULL),
(175, 10, 2020, 'INV20/001', 'HP CUG PYTONE WHITE CAB. TEGAL', 'PUSAT', 6, 'ACTIVE', '2020-01-07', 240000, 50000, 190000, 5000, 4, 0, NULL),
(176, 10, 2020, 'INV20/002', 'PRINTER CANON MG2570S CAB. MANADO', 'PUSAT', 5, 'ACTIVE', '2020-01-15', 820000, 170833, 649167, 17083, 4, 0, NULL),
(177, 10, 2020, 'INV20/003', 'PRINTER EPSON L3110 CAB. KUPANG', 'PUSAT', 5, 'ACTIVE', '2020-01-16', 2600000, 487500, 2112500, 54167, 4, 0, NULL),
(178, 10, 2020, 'INV20/006', 'PRINTER HP 2135 CAB PADANG', 'PUSAT', 5, 'ACTIVE', '2020-02-05', 620000, 116250, 503750, 12917, 4, 0, NULL),
(179, 10, 2020, 'INV20/007', '1 UNIT PC SERVER INTEL CORE 17 9700 K (PUSAT)', 'PUSAT', 1, 'ACTIVE', '2020-02-06', 28300000, 5306250, 22993750, 589583, 4, 0, NULL),
(180, 10, 2020, 'INV20/008', '5 UNIT PC INTEL CORE 15 4570 FERIVIKASI DAN QA (PUSAT)', 'PUSAT', 1, 'ACTIVE', '2020-02-06', 22500000, 4218750, 18281250, 468750, 4, 0, NULL),
(181, 10, 2020, 'INV20/009', '1 UNIT LENOVO THINKPAD E490 - X800 WILDAN (PUSAT)', 'PUSAT', 4, 'ACTIVE', '2020-02-06', 11650000, 2184375, 9465625, 242708, 4, 0, NULL),
(182, 10, 2020, 'INV20/010', '1 UNIT LAPTOP LENOVO IDEAPAD 330S BRID ARIF G (PUSAT)', 'PUSAT', 4, 'ACTIVE', '2020-02-06', 8000000, 1500000, 6500000, 166667, 4, 0, NULL),
(183, 10, 2020, 'INV20/011', '1 UNIT PRINTER BROTHER MFP 2540 DW OPR GG PUSAT JKT', 'PUSAT', 5, 'ACTIVE', '2020-02-06', 2565000, 480938, 2084062, 53438, 4, 0, NULL),
(184, 10, 2020, 'INV20/012', '1 UNIT PRINTER BROTHER DCP 2540 DW OPR GG PUSAT JKT', 'PUSAT', 5, 'ACTIVE', '2020-02-06', 2550000, 478125, 2071875, 53125, 4, 0, NULL),
(185, 10, 2020, 'INV20/013', '1 UNIT HARDDISK EXTERNAL 4 TB WD MY PASPORT GG PUSAT JKT', 'PUSAT', 5, 'ACTIVE', '2020-02-06', 1580000, 296250, 1283750, 32917, 4, 0, NULL),
(186, 10, 2020, 'INV20/014', '1 UNIT LAPTOP ASUS X 441BA AMD CAB. DENPASAR', 'PUSAT', 4, 'ACTIVE', '2020-02-19', 5281000, 880167, 4400833, 110021, 4, 0, NULL),
(187, 10, 2020, 'INV20/015', '1 UNIT PRINTER HP 310 INK TANK PSC CAB. DENPASAR', 'PUSAT', 5, 'ACTIVE', '2020-02-19', 1560000, 260000, 1300000, 32500, 4, 0, NULL),
(188, 10, 2020, 'INV20/016', 'LAPTOP HP 141 DK0073AU CAB NGAWI', 'PUSAT', 4, 'ACTIVE', '2020-02-24', 3800000, 633334, 3166666, 79167, 4, 0, NULL),
(189, 10, 2020, 'INV20/017', 'HP CUG CAB NGAWI', 'PUSAT', 6, 'ACTIVE', '2020-02-24', 235000, 39167, 195833, 4896, 4, 0, NULL),
(190, 10, 2020, 'INV20/023', '1 UNIT LAPTOP LENOVO 330 CAB LUMAJANG', 'PUSAT', 4, 'ACTIVE', '2020-02-28', 3950000, 658334, 3291666, 82292, 4, 0, NULL),
(191, 10, 2020, 'INV20/024', '1 UNIT PRINTER CANON MP 287 CAB LUMAJANG', 'PUSAT', 5, 'ACTIVE', '2020-02-28', 950000, 158334, 791666, 19792, 4, 0, NULL),
(192, 10, 2020, 'INV20/025', '1 UNIT PC INTEL CORE I7M4770 TIM QA', 'PUSAT', 1, 'ACTIVE', '2020-05-29', 5520000, 575000, 4945000, 115000, 4, 0, NULL),
(193, 10, 2020, 'INV20/026', '1 UNIT PRITER CANON G2010 CAB MADIUN', 'PUSAT', 5, 'ACTIVE', '2020-05-29', 1785000, 185938, 1599062, 37188, 4, 0, NULL),
(194, 10, 2020, 'INV20/027', '1 UNIT SOFA TAMU CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 1885000, 196354, 1688646, 39271, 4, 0, NULL),
(195, 10, 2020, 'INV20/028', '1 UNIT KURSI KANTOR CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 600000, 62500, 537500, 12500, 4, 0, NULL),
(196, 10, 2020, 'INV20/029', '2 UNIT KIPAS ANGIN CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 530000, 55209, 474791, 11042, 4, 0, NULL),
(197, 10, 2020, 'INV20/030', '1 UNIT LEMARI FILE CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 500000, 52084, 447916, 10417, 4, 0, NULL),
(198, 10, 2020, 'INV20/031', '1 UNIT MEJA KANTOR CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 500000, 52084, 447916, 10417, 4, 0, NULL),
(199, 10, 2020, 'INV20/032', '1 UNIT DISPENSER CAB JOMBANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 155000, 16146, 138854, 3229, 4, 0, NULL),
(200, 10, 2020, 'INV20/033', '1 UNIT MEJA KANTOR CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 1400000, 145834, 1254166, 29167, 4, 0, NULL),
(201, 10, 2020, 'INV20/034', '4 UNIT KURSI SUSUN IMPERIAL CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 900000, 93750, 806250, 18750, 4, 0, NULL),
(202, 10, 2020, 'INV20/035', '1 UNIT DISPENSER CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 275000, 28646, 246354, 5729, 4, 0, NULL),
(203, 10, 2020, 'INV20/036', '1 UNIT KIPAS ANGIN MIYAKO CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 275000, 28646, 246354, 5729, 4, 0, NULL),
(204, 10, 2020, 'INV20/037', '1 UNIT KARPET MDR 160 CAB KOPANG', 'PUSAT', 6, 'ACTIVE', '2020-05-29', 200000, 20834, 179166, 4167, 4, 0, NULL),
(205, 10, 2020, 'INV20/038', '1 UNIT LAPTOP ACER AMD A9', 'PUSAT', 4, 'ACTIVE', '2020-05-29', 4950000, 515625, 4434375, 103125, 4, 0, NULL),
(206, 10, 2020, 'INV20/039', '1 UNIT LAPTOP ASUS X441 CAB JAMBI', 'PUSAT', 4, 'ACTIVE', '2020-06-30', 4000000, 333333, 3666667, 83333, 4, 0, NULL),
(207, 10, 2020, 'INV20/040', '1 UNIT PRINTER HP DESKJET 2135 CAB JAMBI', 'PUSAT', 5, 'ACTIVE', '2020-06-30', 725000, 60417, 664583, 15104, 4, 0, NULL),
(208, 10, 2020, 'INV20/041', 'BRANKAS CHUBBSAFES TYPE RPF 4 LACI KANTOR PUSAT GG JKT', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 8500000, 708333, 7791667, 177083, 4, 0, NULL),
(209, 10, 2020, 'INV20/042', 'KURSI DAN MEJA TAMU RENG 321 CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 1200000, 100000, 1100000, 25000, 4, 0, NULL),
(210, 10, 2020, 'INV20/043', '2 UNIT MEJA G-STAR 1/2 BIRO HITAM CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 800000, 66667, 733333, 16667, 4, 0, NULL),
(211, 10, 2020, 'INV20/044', '2 UNIT KURSI KANTOR CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 650000, 54167, 595833, 13542, 4, 0, NULL),
(212, 10, 2020, 'INV20/045', '2 UNIT STAND FAN COSMOS CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 480000, 40000, 440000, 10000, 4, 0, NULL),
(213, 10, 2020, 'INV20/046', '1 UNIT RAK KUNA 5 TINGKAT CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 400000, 33333, 366667, 8333, 4, 0, NULL),
(214, 10, 2020, 'INV20/047', '2 UNIT KURSI PLASTIK OL 209 COKLAT TUA CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 240000, 20000, 220000, 5000, 4, 0, NULL),
(215, 10, 2020, 'INV20/048', '1 UNIT DISPENSER MIYAKO CAB PONTIANAK', 'PUSAT', 6, 'ACTIVE', '2020-06-30', 200000, 16667, 183333, 4167, 4, 0, NULL),
(216, 10, 2020, 'INV20/049', '1 UNIT PRINTER EPSON PRINT COPY CAB PALU', 'PUSAT', 5, 'ACTIVE', '2020-06-30', 2200000, 183333, 2016667, 45833, 4, 0, NULL),
(217, 10, 2020, 'INV20/050', '2 UNIT MEJA KANTOR CAB TANJUNG PINANG', 'PUSAT', 6, 'ACTIVE', '2020-08-27', 1300000, 54166, 1245834, 27083, 4, 0, NULL),
(218, 10, 2020, 'INV20/051', '2 UNIT MEJA TULIS DARK CAB TANJUNG PINANG', 'PUSAT', 6, 'ACTIVE', '2020-08-27', 1100000, 45834, 1054166, 22917, 4, 0, NULL),
(219, 10, 2020, 'INV20/052', '2 UNIT KURSI KANTOR CAB TANJUNG PINANG', 'PUSAT', 6, 'ACTIVE', '2020-08-27', 1000000, 41666, 958334, 20833, 4, 0, NULL),
(220, 10, 2020, 'INV20/18', '1 UNIT MEJA SHARING UK. 180 X 95 CM', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 1975000, 329167, 1645833, 41146, 4, 0, NULL),
(221, 10, 2020, 'INV20/19', '2 UNIT EXHAUST FAN (KACA)', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 1900000, 316666, 1583334, 39583, 4, 0, NULL),
(222, 10, 2020, 'INV20/20', '5 UNIT KURSI KERJA GG PUSAT', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 6375000, 1062501, 5312499, 132813, 4, 0, NULL),
(223, 10, 2020, 'INV20/21', '5 UNIT KURSI HADAP GG PUSAT', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 5825000, 970833, 4854167, 121354, 4, 0, NULL),
(224, 10, 2020, 'INV20/22', '2 UNIT MEJA KERJA UK. 100 CM X 60 CM + LACI GANTUNG', 'PUSAT', 6, 'ACTIVE', '2020-02-27', 3110000, 518334, 2591666, 64792, 4, 0, NULL),
(225, 10, 2020, 'INV20-004', 'LAPTOP LENOVO IPD V 130 AMD 4 CAB. MAROS', 'PUSAT', 4, 'ACTIVE', '2020-01-30', 3999000, 749813, 3249187, 83313, 4, 0, NULL),
(226, 10, 2020, 'INV20-005', 'PRINTER 3 IN 1 CANON PIXMA E410', 'PUSAT', 5, 'ACTIVE', '2020-01-30', 800000, 150000, 650000, 16667, 4, 0, NULL),
(227, 10, 2020, 'INV-26/0001', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(228, 10, 2020, 'INV-26/0002', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(229, 10, 2020, 'INV-26/0003', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(230, 10, 2020, 'INV-26/0004', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(231, 10, 2020, 'INV-26/0005', 'NB ASUS X441SA-BX001T', 'PUSAT', 4, 'ACTIVE', '2017-03-26', 4100000, 3672917, 427083, 85417, 4, 0, NULL),
(232, 10, 2020, 'INV-26/0006', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(233, 10, 2020, 'INV-26/0007', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(234, 10, 2020, 'INV-26/0008', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(235, 10, 2020, 'INV-26/0009', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL),
(236, 10, 2020, 'INV-26/0010', 'HP DJ2135', 'PUSAT', 5, 'ACTIVE', '2017-03-26', 780000, 698750, 81250, 16250, 4, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `history_autodebet`
--

CREATE TABLE `history_autodebet` (
  `id` int(11) NOT NULL,
  `tgl_autodebet` datetime DEFAULT NULL,
  `status_anggota` int(11) DEFAULT NULL,
  `username` varchar(50) CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `jns_akun`
--

CREATE TABLE `jns_akun` (
  `jns_akun_id` int(11) NOT NULL,
  `no_akun` varchar(30) NOT NULL,
  `nama_akun` varchar(50) NOT NULL,
  `induk_akun` int(11) DEFAULT NULL,
  `kelompok_akunid` int(11) NOT NULL,
  `kelompok_laporan` enum('Neraca','Laba Rugi','Channeling') NOT NULL,
  `jenis_akun` enum('INDUK','SUB AKUN') NOT NULL,
  `aktif` enum('Y','N') NOT NULL,
  `saldo_normal` enum('DEBET','CREDIT') NOT NULL DEFAULT 'DEBET'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_akun`
--

INSERT INTO `jns_akun` (`jns_akun_id`, `no_akun`, `nama_akun`, `induk_akun`, `kelompok_akunid`, `kelompok_laporan`, `jenis_akun`, `aktif`, `saldo_normal`) VALUES
(1, '101.00.00', 'KAS', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(2, '101.01.01', 'KAS UTAMA', 1, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(3, '103.00.00', 'GIRO PADA BANK', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(4, '103.01.01', 'GIRO PADA BANK BUKOPIN 1001343439', 3, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(5, '103.01.02', 'GIRO PADA BANK BUKOPIN 1001455431', 3, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(6, '103.01.03', 'GIRO PADA BANK BUKOPIN 1001127434', 3, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(7, '103.01.04', 'GIRO PADA BANK BUKOPIN 1001656437', 3, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(8, '107.00.00', 'PENEMPATAN PADA BANK', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(9, '107.01.01', 'TABUNGAN PADA BANK BUKOPIN 4301200943', 8, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(10, '107.01.02', 'TABUNGAN PADA BANK BUKOPIN 0101700404', 8, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(11, '107.02.01', 'TABUNGAN PADA BANK MANDIRI 1170007347602', 8, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(12, '111.00.00', 'PIUTANG', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(13, '111.01.01', 'PIUTANG SWAMITRA', 12, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(14, '111.02.01', 'PENYISIHAN KERUGIAN PIUTANG SWAMITRA.', 12, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(15, '111.03.01', 'PIUTANG LAINNYA', 12, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(16, '115.00.00', 'PENDAPATAN AKAN DITERIMA', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(17, '115.01.01', 'PAD-ADM CHANNELING', 16, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(18, '123.00.00', 'PINJAMAN YANG DIBERIKAN', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(19, '123.01.01', 'PINJAMAN XTRA PLATINUM', 18, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(20, '123.02.01', 'PENYISIHAN KERUGIAN PINJAMAN XTRA PLATINUM', 18, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(21, '123.06.01', 'PINJAMAN KARYAWAN', 18, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(22, '139.00.00', 'PENYERTAAN', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(23, '139.01.01', 'PENYERTAAN REKSADANA MANDIRI INVESTA PU', 22, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(24, '139.02.01', 'KENAIKAN (PENURUNAN) REKSADANA MANDIRI INVESTA PU', 22, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(25, '139.03.01', 'PENYERTAAN KEPADA SWAMTRA', 22, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(26, '143.00.00', 'UANG MUKA', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(27, '143.01.01', 'UM-SARANA & LOGISTIK', 26, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(28, '143.02.01', 'UM-SDM', 26, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(29, '145.00.00', 'BEBAN DIBAYAR DIMUKA', NULL, 2, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(30, '145.01.01', 'BDD-SEWA KANTOR', 29, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(31, '145.02.01', 'BDD-PPH 25', 29, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(32, '147.00.00', 'INVENTARIS', NULL, 8, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(33, '147.01.01', 'INVENTARIS KANTOR', 32, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(34, '147.01.02', 'AKUMULASI PENYUSUTAN INVENTARIS KANTOR', 32, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(35, '149.00.00', 'KENDARAAN', NULL, 8, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(36, '149.02.01', 'KENDARAAN KANTOR', 35, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(37, '149.02.02', 'AKUMULASI PENYUSUTAN KENDARAAN KANTOR', 35, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(38, '151.00.00', 'GEDUNG', NULL, 8, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(39, '151.01.01', 'GEDUNG KANTOR', 38, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(40, '151.01.02', 'AKUMULASI PENYUSUTAN GEDUNG KANTOR', 38, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(41, '153.00.00', 'TANAH', NULL, 8, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(42, '153.01.01', 'TANAH', 41, 8, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(43, '175.00.00', 'AKTIVA LAIN-LAIN', NULL, 9, 'Neraca', 'INDUK', 'Y', 'DEBET'),
(44, '175.01.01', 'AKTIVA DALAM PENYELESAIAN', 43, 9, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(45, '201.00.00', 'KEWAJIBAN SEGERA ', NULL, 10, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(46, '201.01.01', 'HUTANG BANK', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(47, '201.01.02', 'HUTANG LEASING', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(48, '201.01.03', 'HUTANG PAJAK', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(49, '201.02.01', 'KS PELUNASAN PINJAMAN', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(50, '201.03.01', 'BEBAN YADIB-PROFESIONAL FEE', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(51, '201.03.02', 'BEBAN YADIB-FEE PEMASARAN', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(52, '201.99.01', 'KEWAJIBAN SEGERA LAINNYA', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(53, '203.00.00', 'TABUNGAN ANGGOTA', NULL, 10, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(54, '203.01.01', 'TABUNGAN ANGGOTA', 53, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(55, '205.00.00', 'SIMPANAN BERJANGKA', NULL, 10, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(56, '205.01.01', 'SIMPANAN BERJANGKA ANGGOTA', 55, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(57, '207.00.00', 'HUTANG JANGKA PANJANG', NULL, 11, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(58, '207.01.01', 'HUTANG KEPADA ANGGOTA', 57, 11, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(59, '207.02.01', 'HUTANG KEPADA BANK BUKOPIN', 57, 11, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(60, '249.00.00', 'KEWAJIBAN LAIN-LAIN', NULL, 12, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(61, '249.01.01', 'PASIVA DALAM PENYELESAIAN', 60, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(62, '253.00.00', 'CADANGAN', NULL, 12, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(63, '253.01.01', 'CADANGAN THR & BONUS KARYAWAN', 62, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(64, '253.01.02', 'CADANGAN PENDIDIKAN KARYAWAN', 62, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(65, '253.02.01', 'CADANGAN FEE MITRA', 62, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(66, '253.03.01', 'CADANGAN KERUGIAN CHANNELING', 62, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(67, '253.04.01', 'CADANGAN ASURANSI ', 62, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(68, '253.99.01', 'CADANGAN LAINNYA', 62, 12, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(69, '270.00.00', 'M O D A L', NULL, 4, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(70, '270.01.01', 'SIMPANAN POKOK', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(71, '270.01.02', 'SIMPANAN WAJIB', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(72, '270.01.03', 'SIMPANAN SUKARELA', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(73, '270.01.04', 'SIMPANAN KHUSUS', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(74, '270.02.01', 'MODAL PENYERTAAN', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(75, '270.02.02', 'CADANGAN UMUM ', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(76, '270.02.03', 'CADANGAN PENDIDIKAN ANGGOTA', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(77, '270.02.04', 'CADANGAN SOSIAL', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(78, '270.98.01', 'SHU TAHUN LALU', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(79, '270.99.01', 'SHU TAHUN BERJALAN', 69, 4, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(80, '801.00.00', 'KONTIGENSI', NULL, 7, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(81, '801.01.01', 'TAGIHAN PINJAMAN CHANNELING', 80, 7, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(82, '901.00.00', 'KOMITMEN', NULL, 7, 'Neraca', 'INDUK', 'Y', 'CREDIT'),
(83, '901.01.01', 'TAGIHAN PINJAMAN CHANNELING', 82, 7, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(84, '601.00.00', 'BEBAN BUNGA', NULL, 5, 'Laba Rugi', 'INDUK', 'Y', 'DEBET'),
(85, '601.01.01', 'BEBAN BUNGA TABUNGAN', 84, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(86, '601.02.01', 'BEBAN BUNGA SIMPANAN BERJANGKA', 84, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(87, '601.03.01', 'BEBAN BUNGA HUTANG', 84, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(88, '603.00.00', 'BEBAN USAHA', NULL, 5, 'Laba Rugi', 'INDUK', 'Y', 'DEBET'),
(89, '603.01.01', 'BEBAN FEE MARKETING', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(90, '603.02.01', 'BEBAN FEE DSR', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(91, '603.02.02', 'BEBAN FEE BJS', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(92, '603.02.03', 'BEBAN FEE TJA', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(93, '603.03.01', 'BEBAN KERUGIAN CHANNELING', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(94, '603.04.01', 'BEBAN PENURUNAN NILAI PINJAMAN', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(95, '603.05.01', 'BEBAN KERUGIAN PENYERTAAN SWAMITRA', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(96, '603.06.01', 'BP-JASA PENAGIHAN', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(97, '605.00.00', 'BEBAN SDM', NULL, 5, 'Laba Rugi', 'INDUK', 'Y', 'DEBET'),
(98, '605.01.01', 'BEBAN GAJI', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(99, '605.01.02', 'TUNJANGAN TRANSPORT', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(100, '605.01.03', 'TUNJANGAN JABATAN', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(101, '605.01.04', 'TUNJANGAN KINERJA', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(102, '605.02.01', 'TUNJANGAN PREMI BPJS KS', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(103, '605.02.02', 'TUNJANGAN PREMI BPJS TK', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(104, '605.02.03', 'TUNJANGAN PAJAK PENGHASILAN', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(105, '605.03.01', 'THR KARYAWAN', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(106, '605.03.02', 'BONUS KARYAWAN', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(107, '605.03.03', 'BEBAN PENDIDIKAN ', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(108, '605.04.01', 'BEBAN PERJALANAN DINAS ', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(109, '607.00.00', 'BEBAN UMUM DAN ADMINISTRASI', NULL, 5, 'Laba Rugi', 'INDUK', 'Y', 'DEBET'),
(110, '607.01.01', 'BUA - PENYUSUTAN INVENTARIS KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(111, '607.01.02', 'BUA - PENYUSUTAN KENDARAAN KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(112, '607.01.03', 'BUA - PENYUSUTAN GEDUNG KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(113, '607.02.01', 'BUA - PEMELIHARAAN & PERBAIKAN INVENT KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(114, '607.02.02', 'BUA - PEMELIHARAAN & PERBAIKAN KENDARAAN', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(115, '607.02.03', 'BUA - PEMELIHARAAN & PERBAIKAN GEDUNG', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(116, '607.03.01', 'BUA - SEWA INVENTARIS KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(117, '607.03.02', 'BUA - SEWA KENDARAAN', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(118, '607.03.03', 'BUA - SEWA GEDUNG KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(119, '607.04.01', 'BUA - PEMBELIAN INVENTARIS KECIL KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(120, '607.05.01', 'BUA - BBM KENDARAAN', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(121, '607.05.02', 'BUA - PAJAK DAN ASURANSI KENDARAAN', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(122, '607.05.03', 'BUA - TRANSPORTASI', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(123, '607.06.01', 'BUA - LISTRIK GEDUNG KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(124, '607.06.02', 'BUA - AIR MINUM KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(125, '607.06.03', 'BUA - LINE KOMUNIKASI / INTERNET', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(126, '607.06.04', 'BUA - PAJAK / RETRIBUSI KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(127, '607.06.05', 'BUA - ALAT TULIS KANTOR', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(128, '607.06.06', 'BUA - EKSPEDISI', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(129, '607.06.07', 'BUA - MATERAI', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(130, '607.06.08', 'BUA - FOTO COPY', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(131, '607.06.09', 'BUA - SYSTEM APLIKASI/PROGRAM', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(132, '607.06.10', 'BUA - BEBAN BUNGA LEASING', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(133, '607.99.01', 'BEBAN UMUM & ADMINISTRASI LAINNYA', 109, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(134, '609.00.00', 'BEBAN NON OPERASIONAL', NULL, 5, 'Laba Rugi', 'INDUK', 'Y', 'DEBET'),
(135, '609.01.01', 'BEBAN RAT', 134, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(136, '609.01.02', 'SUMBANGAN DAN HADIAH', 134, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(137, '609.01.03', 'KERUGIAN PENJUALAN INVENTARIS KANTOR', 134, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(138, '609.01.04', 'KERUGIAN PENGHAPUSAN INVENTARIS KANTOR', 134, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(139, '609.99.01', 'BEBAN NON OPERASIONAL LAINNYA', 134, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(140, '611.00.00', 'BEBAN PAJAK BADAN', NULL, 5, 'Laba Rugi', 'INDUK', 'Y', 'DEBET'),
(141, '611.01.01', 'BEBAN PAJAK PENGHASILAN BADAN', 140, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(142, '401.00.00', 'PENDAPATAN USAHA', NULL, 6, 'Laba Rugi', 'INDUK', 'Y', 'CREDIT'),
(143, '401.01.01', 'PDT - FEE BAA CHANNELING', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(144, '401.01.02', 'PDT - FEE ADM PENCAIRAN CHANNELING', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(145, '401.02.01', 'PDT - BUNGA XTRA PLATINUM', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(146, '401.02.02', 'PDT - ADM XTRA PLATINUM', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(147, '401.03.01', 'PDT - FEE 70 20', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(148, '401.03.02', 'PDT - FEE FRONTING', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(149, '401.04.01', 'PDT - SWAMITRA CURUG', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(150, '401.04.02', 'PDT - SWAMITRA KRAMAT JATI', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(151, '401.04.03', 'PDT - SWAMITRA MALABAR', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(152, '401.04.04', 'PDT - SWAMITRA TAMBUN', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(153, '403.00.00', 'PENDAPATAN PENEMPATAN PD BANK', NULL, 6, 'Laba Rugi', 'INDUK', 'Y', 'CREDIT'),
(154, '403.01.01', 'PDT BUNGA TABUNGAN PADA BANK BUKOPIN', 153, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(155, '403.01.02', 'PDT BUNGA TABUNGAN PADA BANK MANDIRI', 153, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(156, '403.01.03', 'PDT BUNGA DEPOSITO PADA BANK', 153, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(157, '403.02.01', 'PDT BUNGA SIMPANAN PD KOPERASI LAIN', 153, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(158, '403.02.02', 'PDT BUNGA SIMP BERJK PD SWAMITRA LAIN', 153, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(159, '403.03.01', 'KENAIKAN (PENURUNAN) NAB RD MANDIRI INVESTA PU', 153, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(160, '411.00.00', 'KERUGIAN YANG DIPEROLEH LAGI', NULL, 6, 'Laba Rugi', 'INDUK', 'Y', 'CREDIT'),
(161, '411.01.01', 'PDT ATAS HARTA YANG TELAH DIHAPUSKAN', 160, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(162, '411.02.01', 'PDT ATAS PINJAMAN YANG TELAH DIHAPUSKAN', 160, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(163, '411.03.01', 'PDT ATAS BUNGA PINJ YANG TELAH DIHAPUSKAN', 160, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(164, '411.04.01', 'PDT ATAS DENDA PINJ YANG TELAH DIHAPUSKAN', 160, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(165, '425.00.00', 'PENDAPATAN OPERASIONAL LAINNYA', NULL, 6, 'Laba Rugi', 'INDUK', 'Y', 'CREDIT'),
(166, '425.01.01', 'PDT - ADM PINJAMAN KARYAWAN', 165, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(167, '425.01.02', 'PDT - BUNGA PINJAMAN KARYAWAN', 165, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(168, '425.02.01', 'PDT - DENDA KETERLAMBATAN PEMBAYARAN PINJ', 165, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(169, '425.03.01', 'PDT - JASA GIRO BANK BUKOPIN', 165, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(170, '425.04.01', 'PDT - FEE PAYMENT POINT', 165, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(171, '425.99.01', 'PENDAPATAN OPERASIONAL LAINNYA', 165, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(172, '431.00.00', 'PENDAPATAN NON OPERASIONAL', NULL, 6, 'Laba Rugi', 'INDUK', 'Y', 'CREDIT'),
(173, '431.01.01', 'KEUNTUNGAN PENJUALAN INVENTARIS KANTOR', 172, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(174, '431.02.01', 'KEUNTUNGAN PENJUALAN HARTA EX JAMINAN', 172, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(175, '431.99.01', 'PENDAPATAN NON OPS LAINNYA', 172, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(176, '605.99.01', 'BEBAN PERSONALIA LAINNYA', 97, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(177, '107.03.01', 'DEPOSITO PADA BANK BUKOPIN', 8, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(178, '123.01.02', 'PINJAMAN PLATINUM', 18, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(179, '123.02.02', 'PENYISIHAN KERUGIAN PINJAMAN PLATINUM', 18, 2, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(180, '145.99.01', 'BDD-LAINNYA', 29, 2, 'Neraca', 'SUB AKUN', 'Y', 'DEBET'),
(181, '201.04.01', 'PENDAPATAN DITERIMA DIMUKA', 45, 10, 'Neraca', 'SUB AKUN', 'Y', 'CREDIT'),
(182, '603.02.04', 'BEBAN FEE AJS', 88, 5, 'Laba Rugi', 'SUB AKUN', 'Y', 'DEBET'),
(183, '401.02.03', 'PDT - BUNGA PLATINUM', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(184, '401.02.04', 'PDT - PROVISI PLATINUM', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(185, '401.02.05', 'PDT - BAA PLATINUM', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT'),
(186, '401.02.06', 'PDT - ADM PLATINUM', 142, 6, 'Laba Rugi', 'SUB AKUN', 'Y', 'CREDIT');

-- --------------------------------------------------------

--
-- Table structure for table `jns_anggota`
--

CREATE TABLE `jns_anggota` (
  `id` int(10) NOT NULL,
  `kode` varchar(5) CHARACTER SET latin1 NOT NULL,
  `nama` varchar(50) CHARACTER SET latin1 NOT NULL,
  `status` enum('Y','T') CHARACTER SET latin1 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_anggota`
--

INSERT INTO `jns_anggota` (`id`, `kode`, `nama`, `status`) VALUES
(1, 'AT', 'ANGGOTA TETAP', 'Y'),
(2, 'ALB', 'ANGGOTA LUAR BIASA', 'Y'),
(3, 'CHA', 'CHANNELING', 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `jns_angsuran`
--

CREATE TABLE `jns_angsuran` (
  `id` int(11) NOT NULL,
  `ket` int(11) NOT NULL,
  `aktif` enum('Y','T','','') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_angsuran`
--

INSERT INTO `jns_angsuran` (`id`, `ket`, `aktif`) VALUES
(1, 12, 'Y'),
(4, 24, 'Y'),
(5, 36, 'Y'),
(6, 72, 'Y'),
(7, 60, 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `jns_cabang`
--

CREATE TABLE `jns_cabang` (
  `jns_cabangid` int(11) NOT NULL,
  `kode_cabang` varchar(30) NOT NULL,
  `nama_cabang` varchar(50) NOT NULL,
  `alamat_cabang` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_cabang`
--

INSERT INTO `jns_cabang` (`jns_cabangid`, `kode_cabang`, `nama_cabang`, `alamat_cabang`) VALUES
(1, 'ACEH', 'ACEH', '<p>\n ACEH</p>\n'),
(2, 'ARJOSARI', 'ARJOSARI', '<p>\n ARJOSARI</p>\n'),
(3, 'ATAMBUA', 'ATAMBUA', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    ATAMBUA</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(4, 'BANDUNG', 'BANDUNG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BANDUNG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(5, 'BANJARMASIN', 'BANJARMASIN', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BANJARMASIN</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(6, 'BANYUWANGI', 'BANYUWANGI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BANYUWANGI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(7, 'BEKASI', 'BEKASI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BEKASI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(8, 'BENCULUK', 'BENCULUK', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BENCULUK</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(9, 'BLITAR', 'BLITAR', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BLITAR</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(10, 'BOGOR', 'BOGOR', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BOGOR</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(11, 'BUKIT TINGGI', 'BUKIT TINGGI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    BUKIT TINGGI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(12, 'CILEGON', 'CILEGON', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    CILEGON</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(13, 'CIREBON', 'CIREBON', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    CIREBON</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(14, 'DENPASAR', 'DENPASAR', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    DENPASAR</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(15, 'JAKARTA 1', 'JAKARTA 1', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    JAKARTA 1</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(16, 'JAKARTA 2', 'JAKARTA 2', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    JAKARTA 2</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(17, 'JAKARTA 3', 'JAKARTA 3', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    JAKARTA 3</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(18, 'JAMBI', 'JAMBI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    JAMBI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(19, 'JEMBER', 'JEMBER', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    JEMBER</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(20, 'JOMBANG', 'JOMBANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n     <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n     <tbody>\n       <tr height=\"20\" >\n        <td class=\"xl65\" height=\"20\"  width=\"121\">\n        JOMBANG</td>\n      </tr>\n     </tbody>\n    </table>\n   </td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(21, 'KEDIRI', 'KEDIRI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    KEDIRI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(22, 'KEPANJEN', 'KEPANJEN', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    KEPANJEN</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(23, 'KOPANG', 'KOPANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    KOPANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(24, 'KUPANG', 'KUPANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    KUPANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(25, 'LUMAJANG', 'LUMAJANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    LUMAJANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(26, 'MAGELANG', 'MAGELANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    MAGELANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(27, 'MAKASSAR', 'MAKASSAR', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    MAKASSAR</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(28, 'MAKASSAR 2', 'MAKASSAR 2', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    MAKASSAR 2</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(29, 'MANADO', 'MANADO', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    MANADO</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(30, 'MEDAN', 'MEDAN', '<p>\n &nbsp;</p>\n <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    MEDAN</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(31, 'NGAWI', 'NGAWI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    NGAWI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(32, 'PADANG', 'PADANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PADANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(33, 'PALEMBANG', 'PALEMBANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PALEMBANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(34, 'PALU', 'PALU', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PALU</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(35, 'PAMEKASAN', 'PAMEKASAN', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PAMEKASAN</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(36, 'PARE PARE', 'PARE PARE', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PARE PARE</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(37, 'PEKANBARU', 'PEKANBARU', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PEKANBARU</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(38, 'PONTIANAK', 'PONTIANAK', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PONTIANAK</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(39, 'PROBOLINGGO', 'PROBOLINGGO', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PROBOLINGGO</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(40, 'PURWOKERTO', 'PURWOKERTO', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    PURWOKERTO</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(41, 'SAMARINDA', 'SAMARINDA', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SAMARINDA</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(42, 'SELONG', 'SELONG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SELONG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(43, 'SEMARANG', 'SEMARANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SEMARANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(44, 'SIDOARJO', 'SIDOARJO', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SIDOARJO</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(45, 'SITUBONDO', 'SITUBONDO', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SITUBONDO</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(46, 'SLEMAN', 'SLEMAN', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SLEMAN</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(47, 'SOLO', 'SOLO', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SOLO</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(48, 'SORONG', 'SORONG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SORONG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(49, 'SUKABUMI', 'SUKABUMI', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SUKABUMI</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(50, 'SURABAYA', 'SURABAYA', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    SURABAYA</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(51, 'TANGGUL', 'TANGGUL', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    TANGGUL</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(52, 'TANJUNG PINANG', 'TANJUNG PINANG', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    TANJUNG PINANG</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(53, 'TASIKMALAYA', 'TASIKMALAYA', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    TASIKMALAYA</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(54, 'TEGAL', 'TEGAL', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    TEGAL</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(55, 'TOMOHON', 'TOMOHON', '<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"  width=\"121\">\n <tbody>\n   <tr height=\"20\" >\n    <td class=\"xl65\" height=\"20\"  width=\"121\">\n    TOMOHON</td>\n  </tr>\n </tbody>\n</table>\n<p>\n &nbsp;</p>\n'),
(56, 'PUSAT JKT', 'KANTOR PUSAT JAKARTA', '<p>\n Jl. Margasatwa Cilandak&nbsp;</p>\n'),
(57, 'PUSAT MLG', 'KANTOR PUSAT MALANG', '<p>\n MALANG</p>\n');

-- --------------------------------------------------------

--
-- Table structure for table `jns_deposito`
--

CREATE TABLE `jns_deposito` (
  `id` int(5) NOT NULL,
  `jns_deposito` varchar(50) NOT NULL DEFAULT '0',
  `jumlah` double NOT NULL DEFAULT 0,
  `bunga` varchar(5) NOT NULL DEFAULT '0',
  `fixed` enum('Y','N') NOT NULL,
  `tenor` enum('Y','N') NOT NULL,
  `tampil` enum('Y','T') NOT NULL,
  `auto_simpan` enum('Y','N') DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_deposito`
--

INSERT INTO `jns_deposito` (`id`, `jns_deposito`, `jumlah`, `bunga`, `fixed`, `tenor`, `tampil`, `auto_simpan`) VALUES
(1, '0', 6000000, '1', 'Y', 'Y', 'Y', 'N'),
(2, '0', 0, '0.83', 'Y', 'Y', 'Y', 'Y'),
(3, '0', 10000000, '1', 'Y', 'Y', 'Y', 'Y'),
(4, 'Deposito Gemilang', 200000000, '15', 'Y', 'Y', 'Y', 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `jns_pengajuan`
--

CREATE TABLE `jns_pengajuan` (
  `jenis_id` int(11) NOT NULL,
  `jenis_pengajuan` varchar(20) CHARACTER SET latin1 DEFAULT NULL,
  `fix_angsuran` enum('Y','T') CHARACTER SET latin1 DEFAULT NULL,
  `lama_angsuran` int(11) DEFAULT NULL,
  `inisial_id` varchar(2) CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_pengajuan`
--

INSERT INTO `jns_pengajuan` (`jenis_id`, `jenis_pengajuan`, `fix_angsuran`, `lama_angsuran`, `inisial_id`) VALUES
(1, 'Biasa', 'T', 0, 'B'),
(2, 'Darurat', 'Y', 3, 'D'),
(3, 'Barang', 'T', 0, 'BR');

-- --------------------------------------------------------

--
-- Table structure for table `jns_pinjaman`
--

CREATE TABLE `jns_pinjaman` (
  `id` int(20) NOT NULL,
  `jns_pinjaman` varchar(35) CHARACTER SET latin1 NOT NULL,
  `jumlah` decimal(10,0) NOT NULL DEFAULT 0,
  `bunga` decimal(5,2) NOT NULL DEFAULT 0.00,
  `fixed` enum('Y','T') CHARACTER SET latin1 NOT NULL,
  `biaya_adm` decimal(30,2) NOT NULL DEFAULT 0.00,
  `simpanan_pokok` decimal(30,2) NOT NULL DEFAULT 0.00,
  `biaya_materai` decimal(30,2) NOT NULL DEFAULT 0.00,
  `biaya_asuransi` decimal(30,2) NOT NULL DEFAULT 0.00,
  `max` int(3) NOT NULL,
  `tampil` enum('Y','T') CHARACTER SET latin1 NOT NULL COMMENT 'y/n',
  `tenor` enum('Hari','Minggu','Bulan') CHARACTER SET latin1 DEFAULT NULL,
  `transaksi_toko` enum('Y','T') CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_pinjaman`
--

INSERT INTO `jns_pinjaman` (`id`, `jns_pinjaman`, `jumlah`, `bunga`, `fixed`, `biaya_adm`, `simpanan_pokok`, `biaya_materai`, `biaya_asuransi`, `max`, `tampil`, `tenor`, `transaksi_toko`) VALUES
(1, 'Pinjaman Xtra Platinum 1', 0, 20.40, 'Y', 5.00, 200000.00, 18000.00, 0.00, 12, 'Y', 'Bulan', 'T'),
(8, 'Pinjaman Xtra Platinum 2', 0, 45.60, 'Y', 5.00, 200000.00, 18000.00, 0.00, 24, 'Y', 'Bulan', 'T'),
(9, 'Pinjaman Channeling', 0, 15.00, 'T', 20.00, 0.00, 0.00, 0.00, 12, 'Y', 'Bulan', 'T');

-- --------------------------------------------------------

--
-- Table structure for table `jns_simpan`
--

CREATE TABLE `jns_simpan` (
  `id` int(5) NOT NULL,
  `jns_simpan` varchar(50) NOT NULL,
  `jumlah` double NOT NULL,
  `bunga` varchar(5) NOT NULL,
  `fixed` enum('Y','N') NOT NULL,
  `tenor` enum('Y','N') NOT NULL,
  `tampil` enum('Y','T') NOT NULL,
  `auto_simpan` enum('Y','N') DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `jns_simpan`
--

INSERT INTO `jns_simpan` (`id`, `jns_simpan`, `jumlah`, `bunga`, `fixed`, `tenor`, `tampil`, `auto_simpan`) VALUES
(32, 'SIMPANAN SUKARELA', 0, '0%', 'N', 'N', 'Y', 'Y'),
(40, 'SIMPANAN WAJIB ANGGOTA TETAP', 100000, '0%', 'Y', 'N', 'Y', 'Y'),
(41, 'SIMPANAN POKOK ANGGOTA TETAP', 2500000, '0%', 'Y', 'N', 'Y', 'Y'),
(42, 'SIMPANAN WAJIB ANGGOTA LUAR BIASA', 20000, '0%', 'Y', 'N', 'Y', 'Y'),
(43, 'SIMPANAN POKOK ANGGOTA LUAR BIASA', 200000, '0%', 'Y', 'N', 'Y', 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `journal_voucher`
--

CREATE TABLE `journal_voucher` (
  `journal_voucherid` int(11) NOT NULL,
  `journal_no` varchar(50) DEFAULT NULL,
  `journal_date` date NOT NULL,
  `jns_transaksi` enum('Pengeluaran Kas','Pemasukan Kas','Jurnal Umum','Pemindahbukuan','Penyusutan Inventaris','Penyusutan Kendaraan','Penyusutan Gedung') NOT NULL,
  `headernote` text NOT NULL,
  `validasi_status` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `journal_voucher`
--

INSERT INTO `journal_voucher` (`journal_voucherid`, `journal_no`, `journal_date`, `jns_transaksi`, `headernote`, `validasi_status`) VALUES
(4, '0000006', '2020-06-30', 'Pemindahbukuan', 'Transaksi Akhir Juni 2020', 'X'),
(8, '0000005', '2020-05-31', 'Pemindahbukuan', 'Transaksi Akhir Mei 2020', 'X'),
(12, '0000004', '2020-04-30', 'Pemindahbukuan', 'Transaksi Akhir April 2020', 'X'),
(16, '0000003', '2020-03-31', 'Pemindahbukuan', 'Transaksi Akhir Maret 2020', 'X'),
(20, '0000002', '2020-02-29', 'Pemindahbukuan', 'Transaksi Akhir Februari 2020', 'X'),
(24, '0000001', '2020-01-31', 'Pemindahbukuan', 'Transaksi Akhir Januari 2020', 'X'),
(81, '0000007', '2020-01-31', 'Pemindahbukuan', 'Transaksi Akhir Januari 2020', 'X'),
(85, '0000008', '2020-02-29', 'Pemindahbukuan', 'Transaksi Akhir Februari 2020', 'X'),
(89, '0000009', '2020-03-31', 'Pemindahbukuan', 'Transaksi Akhir Maret 2020', 'X'),
(93, '0000010', '2020-04-30', 'Pemindahbukuan', 'Transaksi Akhir April 2020', 'X'),
(101, '0000012', '2020-06-30', 'Pemindahbukuan', 'Transaksi Akhir Juni 2020', 'X'),
(134, '0000011', '2020-05-31', 'Pemindahbukuan', 'Transaksi Akhir Mei 2020', 'X'),
(138, 'SHU72020', '2020-07-31', 'Pemindahbukuan', 'PEMINDAH BUKUAN', 'X'),
(139, 'SHU122020', '2020-12-31', 'Pemindahbukuan', 'PERHITUNGAN LABA/RUGI 12 2020', 'X'),
(147, '0000013', '2020-07-31', 'Pemindahbukuan', 'Transaksi Juli 2020', 'X'),
(151, '0000014', '2020-08-31', 'Pemindahbukuan', 'Transaksi Agustus 2020', 'X'),
(155, '0000015', '2020-09-30', 'Pemindahbukuan', 'Transaksi September 2020', 'X'),
(156, 'SHU82020', '2020-08-31', 'Pemindahbukuan', 'PERHITUNGAN LABA/RUGI 8 2020', 'X'),
(157, 'SHU92020', '2020-09-30', 'Pemindahbukuan', 'PERHITUNGAN LABA/RUGI 9 2020', 'X'),
(158, '927/OUT/GG/X/2020', '2020-10-01', 'Pengeluaran Kas', 'BY OPR CAB PONTIANAK', 'X'),
(159, '928/OUT/GG/X/2020', '2020-10-01', 'Pengeluaran Kas', 'BY OPR CABANG BEKASI', 'X'),
(160, '929/OUT/GG/X/2020', '2020-10-01', 'Pengeluaran Kas', 'BY OPR CAB ACEH', 'X'),
(161, '930/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'BY OPR CAB PALEMBANG', 'X'),
(162, '931/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'BY OPR CAB PURWOKERTO', 'X'),
(163, '932/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'BY OPR CAB SORONG', 'X'),
(164, '933/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'BY OPR CAB PAMEKASAN', 'X'),
(165, '934/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'BY OPR CAB CIREBON', 'X'),
(166, '935A/OUT/GG/X/2020', '2020-10-06', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA', 'X'),
(167, '936/OUT/GG/X/2020', '2020-10-06', 'Pengeluaran Kas', 'BY OPR CAB KUPANG', 'X'),
(168, '937/OUT/GG/X/2020', '2020-10-07', 'Pengeluaran Kas', 'BY OPR CAB SLEMAN', 'X'),
(169, '938/OUT/GG/X/2020', '2020-10-07', 'Pengeluaran Kas', 'FEE FREELANCE CAB PALU', 'X'),
(170, '939A/OUT/GG/X/2020', '2020-10-07', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI', 'X'),
(171, '940/OUT/GG/X/2020', '2020-10-09', 'Pengeluaran Kas', 'BY OPR CAB SELONG', 'X'),
(172, '941/OUT/GG/X/2020', '2020-10-09', 'Pengeluaran Kas', 'FEE MUTASI KERBIS BULAN SEPT 2020', 'X'),
(173, '942/OUT/GG/X/2020', '2020-10-12', 'Pengeluaran Kas', 'BY OPR CAB KUPANG', 'X'),
(174, '943A/OUT/GG/X/2020', '2020-10-12', 'Pengeluaran Kas', 'PENC PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA', 'X'),
(175, '944/OUT/GG/X/2020', '2020-10-13', 'Pengeluaran Kas', 'BY OPR CAB BANJARMASIN', 'X'),
(176, '945/OUT/GG/X/2020', '2020-10-13', 'Pengeluaran Kas', 'BY OPR CAB PROBOLINGGO', 'X'),
(177, '946/OUT/GG/X/2020', '2020-10-13', 'Pengeluaran Kas', 'BY OPR CAB JOMBANG', 'X'),
(178, '947/OUT/GG/X/2020', '2020-10-14', 'Pengeluaran Kas', 'BY OPR CAB DENPASAR', 'X'),
(179, '948A/OUT/GG/X/2020', '2020-10-14', 'Pengeluaran Kas', 'PENC PINJ XTRA PLAT AN BR NAPITUPULU CAB JAMBI', 'X'),
(180, '949/OUT/GG/X/2020', '2020-10-15', 'Pengeluaran Kas', 'BY FLAGGING CAB ATAMBUA', 'X'),
(181, '951/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'BY OPR CAB MADIUN', 'X'),
(182, '952A/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'PENC PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI', 'X'),
(183, '953/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'BY OPR CAB TANJUNG PINANG', 'X'),
(184, '954A/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO', 'X'),
(185, '955A/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATIUNUM AN M FADAL CAB PAMEKASAN', 'X'),
(186, '956/OUT/GG/X/2020', '2020-10-19', 'Pengeluaran Kas', 'BY OPR CAB TANJUNG PINANG', 'X'),
(187, '957/OUT/GG/X/2020', '2020-10-19', 'Pengeluaran Kas', 'BY OPR CAB PONTIANAK', 'X'),
(188, '958/OUT/GG/X/2020', '2020-10-21', 'Pengeluaran Kas', 'PEMBAYARAN LEASING BLN OKTOBER 2020', 'X'),
(189, '959A/OUT/GG/X/2020', '2020-10-21', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI', 'X'),
(190, '960/OUT/GG/X/2020', '2020-10-22', 'Pengeluaran Kas', 'PEMBAYARAN JAHE MERAH TJA', 'X'),
(191, '934A/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'UANG TRANSPORT DEWAN PENGAWAS RAPAT TGL 1.10.2020', 'X'),
(192, '934B/OUT/GG/X/2020', '2020-10-05', 'Pengeluaran Kas', 'SEWA KANTOR PUSAT MALANG PERIODE NOVEMBER - OKTOBER 2021', 'X'),
(193, '936A/OUT/GG/X/2020', '2020-10-06', 'Pengeluaran Kas', 'BPJS KESEHATAN OKTOBER 2020', 'X'),
(194, '938A/OUT/GG/X/2020', '2020-10-07', 'Pengeluaran Kas', 'REIMBURSEMENT SWAMITRA TAMBUN', 'X'),
(195, '938B/OUT/GG/X/2020', '2020-10-07', 'Pengeluaran Kas', 'REIMBURSEMENT SWAMITRA MALABAR', 'X'),
(196, '940A/OUT/GG/X/2020', '2020-10-09', 'Pengeluaran Kas', 'PEMBAYARAN PPH 21 dan pph 25 SEPT 2020', 'X'),
(197, '942A/OUT/GG/X/2020', '2020-10-12', 'Pengeluaran Kas', 'PEMBAYARAN TERM 2 APLIKASI CORE SISTEM KOPERASI', 'X'),
(198, '946A/OUT/GG/X/2020', '2020-10-13', 'Pengeluaran Kas', 'FEE TJA SEPTEMBER 2020', 'X'),
(199, '946B/OUT/GG/X/2020', '2020-10-13', 'Pengeluaran Kas', 'TITIPAN PEMBAYARAN SEMBAKO KE TJA', 'X'),
(200, '957A/OUT/GG/X/2020', '2020-10-19', 'Pengeluaran Kas', 'PEMBAYARAN TAGIHAN TELKOM OKTOBER 2020', 'X'),
(201, '959B/OUT/GG/X/2020', '2020-10-21', 'Pengeluaran Kas', 'JAKARTA WEB HOSTING FAKTUR NO 37769 20.10.20-19.01.21', 'X'),
(202, '959C/OUT/GG/X/2020', '2020-10-21', 'Pengeluaran Kas', 'PEMBELIAN ATK GG PUSAT JAKARTA', 'X'),
(203, '961/OUT/GG/X/2020', '2020-10-22', 'Pengeluaran Kas', 'BY OPR CAB CILEGON', 'X'),
(204, '962/OUT/GG/X/2020', '2020-10-22', 'Pengeluaran Kas', 'PENURUNAN MTT SWAMITRA HI OKT 2020', 'X'),
(205, '963/OUT/GG/X/2020', '2020-10-22', 'Pengeluaran Kas', 'KKRG TRF BY OPR CAB DENPASAR', 'X'),
(206, '964/OUT/GG/X/2020', '2020-10-23', 'Pengeluaran Kas', 'PEMBAYARAN GAJI KARYAWAN BULAN OKTOBER 2020', 'X'),
(207, '965/OUT/GG/X/2020', '2020-10-23', 'Pengeluaran Kas', 'Hadiah pernikahan karyawan an Arif GustaMAN', 'X'),
(208, '966/OUT/GG/X/2020', '2020-10-23', 'Pengeluaran Kas', 'TALANGAN ANGSURAN PENSIUNAN BULAN OKTOBER 2020', 'X'),
(209, '967/OUT/GG/X/2020', '2020-10-26', 'Pengeluaran Kas', 'REIMBURSEMENT KAS KECIL TGL 22 SEPT - 26 OKT 2020', 'X'),
(210, '968/OUT/GG/X/2020', '2020-10-26', 'Pengeluaran Kas', 'BY OPR CAB ACEH', 'X'),
(211, '969/OUT/GG/X/2020', '2020-10-26', 'Pengeluaran Kas', 'BY OPR CAB JKT 3', 'X'),
(212, '970/OUT/GG/X/2020', '2020-10-26', 'Pengeluaran Kas', 'BY OPR CAB CIREBON', 'X'),
(213, '971/OUT/GG/X/2020', '2020-10-27', 'Pengeluaran Kas', 'PULSA OPERASIONAL OKTOBER 2020', 'X'),
(214, '972/OUT/GG/X/2020', '2020-10-27', 'Pengeluaran Kas', 'PENGAJUAN UMB BY OPR CAB ATAMBUA', 'X'),
(215, '973/OUT/GG/X/2020', '2020-10-27', 'Pengeluaran Kas', 'BY OPR CAB TASIKMALAYA', 'X'),
(216, '974/OUT/GG/X/2020', '2020-10-27', 'Pengeluaran Kas', 'PEMBAYARAN BUNGA KPD ANGGOTA AN MARWAN & NOFRIZAL', 'X'),
(217, 'JU/202010/0001', '2020-10-01', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO AN. BOBBY DAN FAISAL', 'X'),
(218, 'JU/202010/0002', '2020-10-02', 'Pengeluaran Kas', 'KRS KKR KWJ 06-09 2020 3701314390', 'X'),
(219, 'JU/202010/0003', '2020-10-02', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD', 'X'),
(220, 'JU/202010/0004', '2020-10-05', 'Pemasukan Kas', 'PENDAPATAN BAA OKTOBER 2020', 'X'),
(221, 'JU/202010/0005', '2020-10-07', 'Pengeluaran Kas', 'KRS KWJ 07-08 2020 5263330681', 'X'),
(222, 'JU/202010/0006', '2020-10-07', 'Pengeluaran Kas', 'KOREKSI BAA JULI 2020 5330310951', 'X'),
(223, 'JU/202010/0008', '2020-10-12', 'Pengeluaran Kas', 'PEMBAYARAN SEMBAKO', 'X'),
(226, 'JU/202010/0007', '2020-10-12', 'Pemindahbukuan', 'PINBUK DANA PEND FEE 70 20 SEPT 2020', 'X'),
(227, 'JU/202010/0009', '2020-10-19', 'Pemasukan Kas', 'PEMBAYARAN BPJS KESEHATAN SWAMITRA KRAMATJATI AGS-OKT 2020', 'X'),
(228, 'JU/202010/0010', '2020-10-20', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO BP EDY PRAMANA', 'X'),
(229, 'JU/202010/0011', '2020-10-21', 'Pemindahbukuan', 'PINBUK DANA DARI 439 KE REK 431', 'X'),
(230, 'JU/202010/0012', '2020-10-23', 'Pemasukan Kas', 'PEMBAYARAN JAHE DARI TJA', 'X'),
(231, 'JU/202010/0013', '2020-10-27', 'Pemasukan Kas', 'BIAYA ADM, JAGIR DAN PAJAK GIRO OKT 2020', 'X'),
(232, 'JU/202010/0014', '2020-10-27', 'Pemasukan Kas', 'PENGEMBALIAN UMB SERVIS MOBIL OPERASIONAL', 'X'),
(233, 'JU/202010/0015', '2020-10-27', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO', 'X'),
(234, 'JU/202010/0016', '2020-10-27', 'Jurnal Umum', 'PERTANGGUNGJAWABAN UMB BY OPR CAB ATAMBUA', 'X'),
(235, 'JU/202010/0017', '2020-10-27', 'Pemasukan Kas', 'PENURUNAN TALANGAN PENS OKTOBER 2020', 'X'),
(236, 'JU/202010/0018', '2020-10-07', 'Pemasukan Kas', 'TITIPAN PELUNASAN', 'X'),
(244, 'JU/202010/0020', '2020-10-12', 'Pemindahbukuan', 'PEMBAYARAN BUNGA XTRA PLATINUM OKTOBER 2020', 'X'),
(246, 'JU/202010/0023', '2020-10-21', 'Pemindahbukuan', 'PB DANA DARI 437 KE SIAGA BISNIS', 'X'),
(247, 'JU/202010/0024', '2020-10-27', 'Pemasukan Kas', 'BUNGA DAN BY ADMIN TABUNGAN BULAN OKT 2020', 'X'),
(248, 'JU/202010/0025', '2020-10-23', 'Pengeluaran Kas', 'SEMBAKO KARYAWAN GG', 'X'),
(249, 'JU/202010/0027', '2020-10-31', 'Pengeluaran Kas', 'PEMBAYARAN CICILAN MOBIL BULAN OKTOBER 2020', 'X'),
(250, 'JU/202010/0028', '2020-10-27', 'Jurnal Umum', 'AMORTISASI BIAYA OKT 2020', 'X'),
(251, 'JU/202010/0029', '2020-10-27', 'Jurnal Umum', 'ACCRUAL BIAYA DAN PENDAPATAN OKT 2020', 'X'),
(252, 'JU/202010/0030', '2020-10-06', 'Pemasukan Kas', 'FEE 70 20 SEPT 2020', 'X'),
(253, 'JU/202010/0031', '2020-10-27', 'Jurnal Umum', 'REKLAS TITIPAN', 'X'),
(254, 'SHU102020', '2020-10-31', 'Pemindahbukuan', 'PERHITUNGAN LABA/RUGI 10 2020', 'X'),
(255, '935/OUT/GG/X/2020', '2020-10-06', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA', 'X'),
(256, '939/OUT/GG/X/2020', '2020-10-07', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI', 'X'),
(257, '943/OUT/GG/X/2020', '2020-10-12', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA', 'X'),
(258, '948/OUT/GG/X/2020', '2020-10-14', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI', 'X'),
(259, '950/OUT/GG/X/2020', '2020-10-15', 'Pengeluaran Kas', 'PELUNASAN DEB MD AN ASLICHAH CAB JOMBANG', 'X'),
(260, '952/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI', 'X'),
(261, '954/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO', 'X'),
(262, '955/OUT/GG/X/2020', '2020-10-16', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN', 'X'),
(263, '959/OUT/GG/X/2020', '2020-10-21', 'Pengeluaran Kas', 'PENC PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI', 'X'),
(267, 'JU/202010/0021', '2020-10-12', 'Pemindahbukuan', 'PEMBAYARAN POKOK XTRA PLATINUM OKTOBER 2020', 'X'),
(271, 'JU/202010/0022', '2020-10-12', 'Pemindahbukuan', 'SETORAN SIMP WAJIB DEB XTRA PLATINUM OKTOBER 2020', 'X'),
(279, 'JUNI01', '2020-06-30', 'Jurnal Umum', '-', 'X'),
(281, 'MEI01', '2020-05-29', 'Jurnal Umum', '-', 'X'),
(282, 'APR01', '2020-04-30', 'Jurnal Umum', '-', 'X'),
(289, 'MAR01', '2020-03-31', 'Jurnal Umum', '-', 'X'),
(290, 'JAN01', '2020-01-31', 'Jurnal Umum', '-', 'X'),
(291, 'AGS01', '2020-08-31', 'Jurnal Umum', '-', 'X'),
(292, 'SEP01', '2020-09-30', 'Jurnal Umum', '-', 'X'),
(293, 'JUL01', '2020-07-31', 'Jurnal Umum', '-', 'X'),
(294, 'JUN02', '2020-06-30', 'Jurnal Umum', '-', 'X'),
(325, '0000016', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 001/INV-G', 'X'),
(326, '0000017', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 003/INV-G', 'X'),
(327, '0000018', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 005/INV-G', 'X'),
(328, '0000019', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 007/INV-G', 'X'),
(329, '0000020', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 009/INV-G', 'X'),
(330, '0000021', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 011/INV-G', 'X'),
(331, '0000022', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 013/INV-G', 'X'),
(332, '0000023', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 015/INV-G', 'X'),
(333, '0000024', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 023/INV-G', 'X'),
(334, '0000025', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 025/INV-G', 'X'),
(335, '0000026', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B45', 'X'),
(336, '0000027', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B45', 'X'),
(337, '0000028', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B4J', 'X'),
(338, '0000029', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5F', 'X'),
(339, '0000030', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5F', 'X'),
(340, '0000031', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5H', 'X'),
(341, '0000032', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5J', 'X'),
(342, '0000033', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5J', 'X'),
(343, '0000034', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN6CJ4728', 'X'),
(344, '0000035', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN6CN4730', 'X'),
(345, '0000036', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV018/00', 'X'),
(346, '0000037', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02', 'X'),
(347, '0000038', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02', 'X'),
(348, '0000039', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02', 'X'),
(349, '0000040', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(350, '0000041', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(351, '0000042', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(352, '0000043', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(353, '0000044', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(354, '0000045', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(355, '0000046', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000', 'X'),
(356, '0000047', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001', 'X'),
(357, '0000048', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001', 'X'),
(358, '0000049', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001', 'X'),
(359, '0000050', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001', 'X'),
(360, '0000051', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001', 'X'),
(361, '0000052', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001', 'X'),
(362, '0000053', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(363, '0000054', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(364, '0000055', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(365, '0000056', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(366, '0000057', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(367, '0000058', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(368, '0000059', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(369, '0000060', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(370, '0000061', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(371, '0000062', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(372, '0000063', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(373, '0000064', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(374, '0000065', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(375, '0000066', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(376, '0000067', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(377, '0000068', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(378, '0000069', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(379, '0000070', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(380, '0000071', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(381, '0000072', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(382, '0000073', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(383, '0000074', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(384, '0000075', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(385, '0000076', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(386, '0000077', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(387, '0000078', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(388, '0000079', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(389, '0000080', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(390, '0000081', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(391, '0000082', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(392, '0000083', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(393, '0000084', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(394, '0000085', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(395, '0000086', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(396, '0000087', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(397, '0000088', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(398, '0000089', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(399, '0000090', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(400, '0000091', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(401, '0000092', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00', 'X'),
(402, '0000093', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/002', 'X'),
(403, '0000094', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/003', 'X'),
(404, '0000095', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/005', 'X'),
(405, '0000096', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/006', 'X'),
(406, '0000097', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/007', 'X'),
(407, '0000098', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/008', 'X'),
(408, '0000099', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/009', 'X'),
(409, '0000100', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/010', 'X'),
(410, '0000101', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18-004', 'X'),
(411, '0000102', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/001', 'X'),
(412, '0000103', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/002', 'X'),
(413, '0000104', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/003', 'X'),
(414, '0000105', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/004', 'X'),
(415, '0000106', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/005', 'X'),
(416, '0000107', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/006', 'X'),
(417, '0000108', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/007', 'X'),
(418, '0000109', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/008', 'X'),
(419, '0000110', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/010', 'X'),
(420, '0000111', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/011', 'X'),
(421, '0000112', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/012', 'X'),
(422, '0000113', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/013', 'X'),
(423, '0000114', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/014', 'X'),
(424, '0000115', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/015', 'X'),
(425, '0000116', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/016', 'X'),
(426, '0000117', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/017', 'X'),
(427, '0000118', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/018', 'X'),
(428, '0000119', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/019', 'X'),
(429, '0000120', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/020', 'X'),
(430, '0000121', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/021', 'X'),
(431, '0000122', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/022', 'X'),
(432, '0000123', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/023', 'X'),
(433, '0000124', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/024', 'X'),
(434, '0000125', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/025', 'X'),
(435, '0000126', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/026', 'X'),
(436, '0000127', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/027', 'X'),
(437, '0000128', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/028', 'X'),
(438, '0000129', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/029', 'X'),
(439, '0000130', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/030', 'X'),
(440, '0000131', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/031', 'X'),
(441, '0000132', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/032', 'X'),
(442, '0000133', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/033', 'X'),
(443, '0000134', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/034', 'X'),
(444, '0000135', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/001', 'X'),
(445, '0000136', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/002', 'X'),
(446, '0000137', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/003', 'X'),
(447, '0000138', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/006', 'X'),
(448, '0000139', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/007', 'X'),
(449, '0000140', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/008', 'X'),
(450, '0000141', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/009', 'X'),
(451, '0000142', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/010', 'X'),
(452, '0000143', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/011', 'X'),
(453, '0000144', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/012', 'X'),
(454, '0000145', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/013', 'X'),
(455, '0000146', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/014', 'X'),
(456, '0000147', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/015', 'X'),
(457, '0000148', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/016', 'X'),
(458, '0000149', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/017', 'X'),
(459, '0000150', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/023', 'X'),
(460, '0000151', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/024', 'X'),
(461, '0000152', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/025', 'X'),
(462, '0000153', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/026', 'X'),
(463, '0000154', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/027', 'X'),
(464, '0000155', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/028', 'X'),
(465, '0000156', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/029', 'X'),
(466, '0000157', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/030', 'X'),
(467, '0000158', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/031', 'X'),
(468, '0000159', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/032', 'X'),
(469, '0000160', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/033', 'X'),
(470, '0000161', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/034', 'X'),
(471, '0000162', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/035', 'X'),
(472, '0000163', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/036', 'X'),
(473, '0000164', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/037', 'X'),
(474, '0000165', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/038', 'X'),
(475, '0000166', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/039', 'X'),
(476, '0000167', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/040', 'X'),
(477, '0000168', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/041', 'X'),
(478, '0000169', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/042', 'X'),
(479, '0000170', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/043', 'X'),
(480, '0000171', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/044', 'X'),
(481, '0000172', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/045', 'X'),
(482, '0000173', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/046', 'X'),
(483, '0000174', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/047', 'X'),
(484, '0000175', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/048', 'X'),
(485, '0000176', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/049', 'X'),
(486, '0000177', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/050', 'X'),
(487, '0000178', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/051', 'X'),
(488, '0000179', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/052', 'X'),
(489, '0000180', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/18 ', 'X'),
(490, '0000181', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/19 ', 'X'),
(491, '0000182', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/20 ', 'X'),
(492, '0000183', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/21 ', 'X'),
(493, '0000184', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/22 ', 'X'),
(494, '0000185', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20-004', 'X'),
(495, '0000186', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20-005', 'X'),
(496, '0000187', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(497, '0000188', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(498, '0000189', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(499, '0000190', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(500, '0000191', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(501, '0000192', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(502, '0000193', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(503, '0000194', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(504, '0000195', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(505, '0000196', '2020-10-31', 'Penyusutan Inventaris', ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00', 'X'),
(506, '0000197', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(507, '0000198', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(508, '0000199', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(509, '0000200', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(510, '0000201', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(511, '0000202', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(512, '0000203', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(513, '0000204', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(514, '0000205', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(515, '0000206', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(516, '0000207', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(517, '0000208', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(518, '0000209', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(519, '0000210', '2020-10-31', 'Pengeluaran Kas', 'BDD SEWA KANTOR  BULAN 10 TAHUN 2020', 'X'),
(520, 'JU/202011/0002', '2020-11-02', 'Pengeluaran Kas', 'KOREKSI BAA 202010 0706310349 AN. IDA BAGUS PUTU SUDA', 'X'),
(521, 'JU/202011/0003', '2020-11-03', 'Pemasukan Kas', 'Pendapatan BAA Nov 2020', 'X'),
(522, '975/OUT/GG/XI/2020', '2020-11-03', 'Pengeluaran Kas', 'By Opr Cab Kupang', 'X'),
(523, '976/OUT/GG/XI/2020', '2020-11-03', 'Pengeluaran Kas', 'By Opr Cab Palembang', 'X'),
(524, 'JU/202011/0004', '2020-11-04', 'Pemindahbukuan', 'Pemindahbukuan Dana Cad ke Rek 431', 'X'),
(525, '977/OUT/GG/XI/2020', '2020-11-05', 'Pengeluaran Kas', 'By Opr Cab Pontianak', 'X'),
(526, '978/OUT/GG/XI/2020', '2020-11-05', 'Pengeluaran Kas', 'PENGAJUAN UMB CAB SLEMAN', 'X'),
(527, '979/OUT/GG/XI/2020', '2020-11-02', 'Pengeluaran Kas', 'By Opr Cab Blitar', 'X'),
(528, '980/OUT/GG/XI/2020', '2020-11-05', 'Pengeluaran Kas', 'By Opr Cab Pamekasan', 'X'),
(529, '981/OUT/GG/XI/2020', '2020-11-05', 'Pengeluaran Kas', 'Pelunasan 3 Deb fraud SI No 1354', 'X'),
(530, 'JU/202011/0005', '2020-11-06', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO AN. BP EDDY PRAMANA', NULL),
(531, '982/OUT/GG/XI/2020', '2020-11-06', 'Pengeluaran Kas', 'UMB Rapat 8.11.2020', 'X'),
(532, 'JU/202011/0006', '2020-11-09', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD', 'X'),
(533, '983/OUT/GG/XI/2020', '2020-11-10', 'Pengeluaran Kas', 'By Opr Cab Tanjung Pinang', 'X'),
(534, '984/OUT/GG/XI/2020', '2020-11-11', 'Pengeluaran Kas', 'By Opr Cab Medan', 'X'),
(535, '985/OUT/GG/XI/2020', '2020-11-11', 'Pengeluaran Kas', 'By Opr Cab Tegal', 'X'),
(536, 'JU/202011/0007', '2020-11-12', 'Pemasukan Kas', 'PERTANGGUNGJAWABAN UMB RAPAT 8.11.2020', 'X'),
(537, 'JU/202011/0008', '2020-11-16', 'Pemindahbukuan', 'Pemindahbukuan dana ke Rek Mandiri', 'X'),
(538, '986/OUT/GG/XI/2020', '2020-11-20', 'Pengeluaran Kas', 'By Opr Cab Bukittinggi', 'X'),
(539, 'JU/202011/0012', '2020-11-23', 'Pemasukan Kas', 'GIRO DAN PAJAK GIRO', 'X'),
(540, '987/OUT/GG/XI/2020', '2020-11-23', 'Pengeluaran Kas', 'Penurunan MTT Swamitra HI Nov 2020', 'X'),
(541, '988/OUT/GG/XI/2020', '2020-11-23', 'Pengeluaran Kas', 'Talangan Angsuran Pensiunan Nov 2020', 'X'),
(542, '975A/OUT/GG/XI/2020', '2020-11-02', 'Pengeluaran Kas', 'BPJS TK Karyawan Okt 2020', 'X'),
(543, '975B/OUT/GG/XI/2020', '2020-11-02', 'Pengeluaran Kas', 'BPJS KS Karyawan Nov 2020', 'X'),
(544, '976B/OUT/GG/XI/2020', '2020-11-03', 'Pengeluaran Kas', 'DP Ruang Rapat tgl 8.11.2020', 'X'),
(545, 'JU/202011/0013', '2020-11-09', 'Pengeluaran Kas', 'PEMBAYARAN SEMBAKO AN ABD RAHMAN, BOBBY DAN EDDY P', 'X'),
(546, '982A/OUT/GG/XI/2020', '2020-11-09', 'Pengeluaran Kas', 'Talangan Pembayaran Sembako PT TJA', 'X'),
(547, '983A/OUT/GG/XI/2020', '2020-11-10', 'Pengeluaran Kas', 'Pembayaran PPH 21 Oktober 2020', 'X'),
(548, '985A/OUT/GG/XI/2020', '2020-11-12', 'Pengeluaran Kas', 'Pembelian Vitamin', 'X'),
(549, '986A/OUT/GG/XI/2020', '2020-11-20', 'Pengeluaran Kas', 'Meeting Pengurus dengan Advisor', 'X'),
(550, '986B/OUT/GG/XI/2020', '2020-11-20', 'Pengeluaran Kas', 'Pembayaran Tagihan Telkom Nov 2020 GG Pusat', 'X'),
(551, 'JU/202011/0014', '2020-11-20', 'Pengeluaran Kas', 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD', 'X'),
(552, '986C/OUT/GG/XI/2020', '2020-11-20', 'Pengeluaran Kas', 'Fee TJA Okt 2020', 'X'),
(553, 'JU/202011/0015', '2020-11-24', 'Jurnal Umum', 'SETORAN DANA PEMINDAHAN KE REKENING MANDIRI', 'X'),
(554, '989/OUT/GG/XI/2020', '2020-11-24', 'Pengeluaran Kas', 'By Opr Cab Bogor', 'X'),
(555, '991/OUT/GG/XI/2020', '2020-11-25', 'Pengeluaran Kas', 'Pembayaran Gaji November 2020', 'X'),
(556, '993/OUT/GG/XI/2020', '2020-11-25', 'Pengeluaran Kas', 'By Opr. Cab Aceh', 'X'),
(557, '994/OUT/GG/XI/2020', '2020-11-25', 'Pengeluaran Kas', 'By Opr Cab Jombang', 'X'),
(558, '995/OUT/GG/XI/2020', '2020-11-25', 'Pengeluaran Kas', 'BY CUG AGS SEPT 2020', 'X'),
(559, '996/OUT/GG/XI/2020', '2020-11-25', 'Pengeluaran Kas', 'BY OPR GG PUSAT MALANG AGS NOV 2020', 'X'),
(561, '997/OUT/GG/XI/2020', '2020-11-25', 'Pengeluaran Kas', 'BY OPR CAB CIREBON', 'X'),
(562, 'JU/202011/0016', '2020-11-26', 'Pemasukan Kas', 'PEMBAYARAN SEMBAKO AN EDY PRAMANA DAN MANUDIN HASAN', 'X'),
(563, '998/OUT/GG/XI/2020', '2020-11-27', 'Pengeluaran Kas', 'BY OPR CAB JKT 3', 'X'),
(564, 'JU/202011/0019', '2020-11-25', 'Pengeluaran Kas', 'PEMBAYARAN SEMBAKO KARYAWAN NOV 2020', 'X'),
(565, 'JU/202011/0020', '2020-11-26', 'Pengeluaran Kas', 'PEMBAYARAN SEMBAKO AN EDY PRAMANA DAN MANUDIN HASAN', 'X'),
(566, 'JU/202011/0021', '2020-11-27', 'Pengeluaran Kas', 'PBY BUNGA HUTANG KPD ANGGOTA', 'X'),
(567, 'JU/202011/0022', '2020-11-27', 'Pengeluaran Kas', 'PEMBELIAN BIOFITRO 10 BOTOL', 'X'),
(568, 'JU/202011/0023', '2020-11-30', 'Pengeluaran Kas', 'CICILAN MOBIL NOV 2020', 'X'),
(569, 'JU/202011/0025', '2020-11-04', 'Pemindahbukuan', 'PEMINDAHBUKUAN PELUNASAN', 'X'),
(570, 'JU/202011/0026', '2020-11-09', 'Pengeluaran Kas', 'FLAGGING', NULL),
(571, 'JU/202011/0027', '2020-11-11', 'Pengeluaran Kas', 'FEE MITRA', 'X'),
(572, 'JU/202011/0028', '2020-11-23', 'Pengeluaran Kas', 'PELUNASAN DEB FRAUD SI 1328 DAN SI 1431', 'X'),
(573, '999/OUT/GG/XII/2020', '2020-12-01', 'Pengeluaran Kas', 'PULSA OPERASIONAL KARYAWAN NOV 2020', 'X'),
(574, 'JU/202012/0001', '2020-12-01', 'Pemasukan Kas', 'PENDAPATAN BAA DESEMBER 2020', 'X'),
(575, 'JU/202012/0002', '2020-12-01', 'Pemindahbukuan', 'PEMINDAHBUKUAN DANA CADANGAN', 'X'),
(576, '1000/OUT/GG/XII/2020', '2020-12-02', 'Pengeluaran Kas', 'Pembelian Kopi', 'X'),
(577, '1001/OUT/GG/XII/2020', '2020-12-03', 'Pemindahbukuan', 'Pemindahbukuan Dana ke Mandiri', 'X'),
(578, '1002/OUT/GG/XII/2020', '2020-12-03', 'Pengeluaran Kas', 'By Opr Cab Kupang', 'X'),
(579, '992/OUT/GG/XII/2020', '2020-11-25', 'Pengeluaran Kas', 'By Opr Cab Kopang', 'X'),
(580, '990/OUT/GG/XII/2020', '2020-11-24', 'Pengeluaran Kas', 'Reimbursement kas kecil kantor pusat', 'X'),
(581, '1003/OUT/GG/XII/2020', '2020-12-03', 'Pengeluaran Kas', 'By Opr Cab Palu', 'X'),
(582, '1004/OUT/GG/XII/2020', '2020-12-04', 'Pemindahbukuan', 'Pemindahbukuan dana ke rek mandiri', 'X'),
(583, '1005/OUT/GG/XII/2020', '2020-12-04', 'Pengeluaran Kas', 'SPJ DAN UMB DINAS YOGYA 5-6.12.20', 'X'),
(584, '1006/OUT/GG/XII/2020', '2020-12-08', 'Pemindahbukuan', 'Pemindahbukuan Dana Ke Mandiri', 'X'),
(585, '1007/OUT/GG/XII/2020', '2020-12-08', 'Pengeluaran Kas', 'GAJI NOV DAN APRESIASI CA SITUBONDO', 'X'),
(586, '1008/OUT/GG/XII/2020', '2020-12-08', 'Pengeluaran Kas', 'BY OPR CAB TOMOHON', 'X'),
(587, '1009/OUT/GG/XII/2020', '2020-12-10', 'Pemindahbukuan', 'Pemindahan Dana ke Rek Mandiri', 'X'),
(588, 'JU/202012/0009', '2020-12-10', 'Pemasukan Kas', 'Pengembalian UMB Dinas Yogya 5-6.12.2020', 'X'),
(589, '1010/OUT/GG/XII/2020', '2020-12-14', 'Pengeluaran Kas', 'Reimbursement Kas Kecil Periode 27.10 s/d 14.12.2020', 'X'),
(590, 'JU/202012/0010', '2020-12-15', 'Pemasukan Kas', 'PENGEMBALIAN DANA TALANGAN DARI PAK MUZAMMIL', 'X'),
(591, '1011/OUT/GG/XII/2020', '2020-12-15', 'Pengeluaran Kas', 'BY OPR CAB PALEMBANG', 'X'),
(592, '1000A/OUT/GG/XII/2020', '2020-12-01', 'Pengeluaran Kas', 'PEMBAYARAN APRESIASI BM CA LAY OFF', 'X'),
(593, '1009A/OUT/GG/XII/2020', '2020-12-10', 'Pengeluaran Kas', 'PEMBAYARAN THR NATAL DAN APRESIASI KARYAWAN THN 2020', 'X'),
(594, 'JU/202012/0011', '2020-12-03', 'Pemasukan Kas', 'Pemindahbukuan Dana Dari 439', 'X'),
(595, '1003A/OUT/GG/XII/2020', '2020-12-03', 'Pengeluaran Kas', 'Pembelian Biofitro 12 botol', 'X'),
(596, 'JU/202012/0012', '2020-12-04', 'Pemindahbukuan', 'Pemindahbukuan dari rek 439', 'X'),
(597, 'JU/202012/0013', '2020-12-07', 'Pemindahbukuan', 'PEMINDAHBUKUAN DANA DARI REK 439', 'X'),
(598, 'JU/202012/0014', '2020-12-08', 'Pemindahbukuan', 'Pemindahbukuan Dana Dari Rek 439', 'X'),
(599, '1008A/OUT/GG/XII/2020', '2020-12-08', 'Pengeluaran Kas', 'Pembayaran BPJS TK Karyawan Nov 2020', 'X'),
(600, '1008B/OUT/GG/XII/2020', '2020-12-08', 'Pengeluaran Kas', 'Pembayaran BPJS KS Karyawan bulan Des 2020', 'X'),
(601, '1008C/OUT/GG/XII/2020', '2020-12-08', 'Pengeluaran Kas', 'Pembelian ATK GG PUSAT JKT', 'X'),
(602, 'JU/202012/0015', '2020-12-09', 'Pemindahbukuan', 'PEMINDAHBUKUAN DANA DARI REK 439', 'X'),
(603, 'JU/202012/0016', '2020-12-10', 'Pemindahbukuan', 'Pemindahbukuan Dana Dari Rek 439', 'X'),
(604, '1009B/OUT/GG/XII/2020', '2020-12-10', 'Pengeluaran Kas', 'Pembayaran PPH 21 Karyawan masa November 2020', 'X'),
(605, '1009C/OUT/GG/XII/2020', '2020-12-10', 'Pengeluaran Kas', 'Pembelian Tinta GG Pusat Jkt', 'X'),
(606, '1009D/OUT/GG/XII/2020', '2020-12-10', 'Pengeluaran Kas', 'Pinjaman an Deddy Methaputranto', 'X'),
(607, '1010A/OUT/GG/XII/2020', '2020-12-11', 'Pengeluaran Kas', 'UMB Rapat dengan Panin 11.12.20', 'X'),
(608, '1010B/OUT/GG/XII/2020', '2020-12-11', 'Pengeluaran Kas', 'Pembayaran Biofitro 15 Botol', 'X'),
(609, '1010C/OUT/GG/XII/2020', '2020-12-14', 'Pengeluaran Kas', 'Pembayaran Jakarta Webhosting 26.12.20-25.03.21', 'X'),
(610, 'JU/202012/0017', '2020-12-14', 'Pemasukan Kas', 'Pengembalian Sisa UMB Rapat Panin 11.12.20', 'X'),
(611, 'JU/202012/0018', '2020-12-15', 'Pengeluaran Kas', 'PBY SEMBAKO BOBBY KE TRANSFORMASI JANNAH ABADI', 'X'),
(612, '1012/OUT/GG/XII/2020', '2020-12-16', 'Pengeluaran Kas', 'Sumbangan Duka Cita Kary an Indra', 'X'),
(613, '1013/OUT/GG/XII/2020', '2020-12-18', 'Pengeluaran Kas', 'Krs Sisa Gaji Deb Pens an Eunice Ep Sahelang', 'X'),
(616, '1014/OUT/GG/XII/2020', '2020-12-21', 'Pengeluaran Kas', 'By Opr Cab Jombang', 'X'),
(617, '1015/OUT/GG/XII/2020', '2020-12-21', 'Pengeluaran Kas', 'By Opr Cab Pontianak', 'X'),
(618, '1016/OUT/GG/XII/2020', '2020-12-21', 'Pengeluaran Kas', 'BY OPR CAB JKT 3', 'X'),
(619, '1017/OUT/GG/XII/2020', '2020-12-21', 'Pemindahbukuan', 'Pemindahbukuan Dana ke Mandiri', 'X'),
(620, 'JU/202012/0020', '2020-12-21', 'Pemindahbukuan', 'PEMINDAHBUKUAN DANA DARI REK 439', 'X'),
(621, '1018/OUT/GG/XII/2020', '2020-12-21', 'Pengeluaran Kas', 'KSU GG TERM 1 AUDIT KE KANTOR AKUNTAN PUBLIK KURNIAWAN', 'X'),
(622, '1019/OUT/GG/XII/2020', '2020-12-22', 'Pengeluaran Kas', 'By Opr Cab Blitar', 'X'),
(623, '1020/OUT/GG/XII/2020', '2020-12-22', 'Pengeluaran Kas', 'BY OPS CAB DENPASAR', 'X'),
(624, '1021/OUT/GG/XII/2020', '2020-12-22', 'Pengeluaran Kas', 'PEMINDAHAN BUKU DANA KE MANDIRI ', 'X'),
(625, '1022/OUT/GG/XII/2020', '2020-12-22', 'Pengeluaran Kas', 'BY OPR CAB TANJUNG PINANG', 'X'),
(626, '1023/OUT/GG/XII/2020', '2020-12-22', 'Pengeluaran Kas', 'BY UMB RAPAT PANIN', 'X'),
(627, 'JU/202012/0021', '2020-12-22', 'Pemasukan Kas', 'PEMINDAHAN BUKU DARI 439', 'X'),
(628, 'JU/202012/0022', '2020-12-22', 'Pemasukan Kas', 'PERTANGGUNGJAWABAN UMB PANIN', 'X'),
(629, 'JU/202012/0023', '2020-12-23', 'Pemasukan Kas', 'BUNGA DAN PAJAK GIRO ', 'X'),
(630, '1025/OUT/GG/2020', '2020-12-23', 'Pengeluaran Kas', 'PENURUNAN MTT SWAMITRA HI ', 'X'),
(631, '1026/OUT/GG/XII/2020', '2020-12-23', 'Pengeluaran Kas', 'TALANGAN ANGSURAN PENS DES 2020 ', 'X'),
(632, '1027/OUT/GG/XII/2020', '2020-12-23', 'Pengeluaran Kas', 'BY PULSA BULANAN DES 2020 ', 'X'),
(633, '1028/OUT/GG/XII/2020', '2020-12-23', 'Pengeluaran Kas', 'BY OPR CAB CIREBON ', 'X'),
(634, 'JU/202012/0024', '2020-12-24', 'Pemasukan Kas', 'PBY SEMBAKO A.N DR EDY PRAMANA\n', 'X'),
(635, 'JU/202012/0025', '2020-12-24', 'Pengeluaran Kas', 'PBY SEMBAKO A.N ABD RAHM', 'X'),
(636, 'JU/202012/0026', '2020-12-23', 'Pemasukan Kas', 'PENGEMBALIAN TALANGAN SEMBAKO DARI TJA', 'X'),
(637, 'JU/202012/0027', '2020-12-23', 'Pemasukan Kas', 'PENGEMBALIAN KELEBIHAN TRANSFER DARI TJA', 'X'),
(639, '1029/OUT/GG/XII/2020', '2020-12-23', 'Pengeluaran Kas', 'Pby Biofitro KSU GG 10 Botol', 'X'),
(640, '1030/OUT/GG/XII/2020', '2020-12-27', 'Pengeluaran Kas', 'BUNGA HUTANG kpd Anggota KSU GG DES 20 an Marwan', 'X'),
(641, '1031/OUT/GG/XII/2020', '2020-12-28', 'Pengeluaran Kas', 'Cicilan Mobil Des 20 ke  ARIF GUSTAMAN', 'X'),
(643, '1033/OUT/GG/XII/2020', '2020-12-28', 'Pengeluaran Kas', 'Konsumsi Rapat Pengurus, Pengawas       ', 'X'),
(644, '1032/OUT/GG/XII/2020', '2020-12-28', 'Pengeluaran Kas', 'BUNGA HuTANG kpd Anggota KSU GG DES 20 an Nofrizal', 'X'),
(645, '1034/OUT/GG/XII/2020', '2020-12-28', 'Pengeluaran Kas', 'BY OPS CAB ACEH ', 'X'),
(649, '1024/OUT/GG/XII/2020', '2020-12-23', 'Pengeluaran Kas', 'Pembayaran Gaji Karyawan Des 2020', 'X'),
(651, 'JU/202012/0030', '2020-12-28', 'Pengeluaran Kas', 'PBY SEMBAKO EDDY P', 'X'),
(652, 'JU/202012/0031', '2020-12-28', 'Pemasukan Kas', 'PBY SEMBAKO A.N M HASAN', 'X'),
(653, 'JU/202012/0032', '2020-12-29', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE MANDIRI', 'X'),
(654, '1035/OUT/GG/XII/2020', '2020-12-29', 'Pengeluaran Kas', 'by ops cilegon ', 'X'),
(655, 'JU/202012/0033', '2020-12-29', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(656, '1036/OUT/GG/XII/2020', '2020-12-29', 'Pengeluaran Kas', 'pby bpjstk ', 'X'),
(657, '1037/OUT/GG/XII/2020', '2020-12-29', 'Pengeluaran Kas', 'PEMBAYARAN WebHOSTINGKE JIMMY', 'X'),
(658, 'JU/202012/0047', '2020-12-29', 'Pemasukan Kas', 'PENDAPATAN ADM DROPPING DES 2020', 'X'),
(659, 'JU/202012/0048', '2020-12-29', 'Pemasukan Kas', 'PENDAPATAN MATERAI', 'X'),
(660, 'JU/202012/0049', '2020-12-29', 'Pemasukan Kas', 'PENDAPATAN BAA DESEMBER 2020', 'X'),
(662, 'JU/202012/0050', '2020-12-29', 'Pengeluaran Kas', 'PBY  SEMBAKO M HASAN', 'X'),
(664, '1038/OUT/GG/XII/2020', '2020-12-30', 'Pengeluaran Kas', 'by ops atambua ', 'X'),
(665, '1039/OUT/GG/XII/2020', '2020-12-30', 'Pengeluaran Kas', 'by ops sidoarjo ', 'X'),
(666, '1040/OUT/GG/XII/2020', '2020-12-30', 'Pengeluaran Kas', 'Pelunasan Aplikasi Keuangan', 'X'),
(667, '1041/OUT/GG/XII/2020', '2020-12-30', 'Pengeluaran Kas', 'UMB RAPAT MESTIKA 30.12.2020', 'X'),
(668, '1042/OUT/GG/XII/2020', '2020-12-30', 'Pengeluaran Kas', 'Reimbursement Kas Kecil Periode 14.12.20 s/d 30.12.20', 'X'),
(669, '1043/OUT/GG/XII/2020', '2020-12-30', 'Pengeluaran Kas', 'Pemindahbukuan Dana dan PEngembalian Talngan Drop Cilegon', 'X'),
(670, 'JU/202101/0001', '2020-12-30', 'Pengeluaran Kas', 'B.ADM DES 2020 ACCOUNT NO.1001343439', 'X'),
(671, 'JU/202012/0055', '2020-12-30', 'Pengeluaran Kas', 'PEMB. JASA GIRO DES 2020 - 1001343439', 'X'),
(672, 'JU/202012/0056', '2020-12-30', 'Pengeluaran Kas', 'PAJAK JASA GIRO DES 2020 - 1001343439', 'X'),
(673, 'JU/202012/0057', '2020-12-30', 'Pengeluaran Kas', 'B.MATERAI DES 2020 ACC NO.1001343439', 'X'),
(674, 'JU/202012/0058', '2021-01-04', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE MANDIRI', 'X'),
(675, 'JU/202101/0002', '2020-12-31', 'Pemasukan Kas', 'PBY SEMBAKO DR  AGNY IRSYAD  UTK GILANG GEMILA', 'X'),
(676, 'JU/202012/0059', '2021-01-31', 'Pengeluaran Kas', 'BUNGA, BY ADM DAN PAJAK REK TABUNGAN DES 2020', 'X'),
(677, 'JU/202101/0003', '2021-01-04', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(678, '1044/OUT/GG/XII/2020', '2021-01-04', 'Pengeluaran Kas', 'pby bpjs kesehatan', 'X'),
(679, 'JU/202101/0005', '2021-01-05', 'Pemasukan Kas', 'PENURUNAN PIUTANG DES 2020', 'X'),
(680, 'JU/202101/0006', '2021-01-05', 'Pemasukan Kas', 'PENDAPATAN BAA JAN 2021', 'X'),
(681, 'JU/202101/0007', '2021-01-05', 'Pemasukan Kas', 'PENDAPATAN  BUNGA DEB XTRA JAN 2021', 'X'),
(682, 'JU/202101/0008', '2021-01-05', 'Pengeluaran Kas', 'MONTHLY CARD CHARGE 0004617003724020525', 'X'),
(684, 'JU/202101/0009', '2021-01-05', 'Pengeluaran Kas', 'PBY BIOFITRO KSU GG 15 BOTOL', 'X'),
(685, '1045/OUT/GG/I/2021', '2021-01-11', 'Pengeluaran Kas', 'by ops palembang ', 'X'),
(686, 'JU/202101/0010', '2021-01-14', 'Pengeluaran Kas', 'PEMINDAHAN DANA A.N DARWONO', 'X'),
(687, 'JU/202101/0011', '2021-01-14', 'Pengeluaran Kas', 'FEE PELUNASAN SWAMITRA HI', 'X'),
(688, '1046/OUT/GG/I/2021', '2021-01-18', 'Pengeluaran Kas', 'by opr cab denpasar ', 'X'),
(690, '1047/OUT/GG/I/2021', '2021-01-18', 'Pengeluaran Kas', 'by opr kopang ', 'X'),
(691, 'JU/202101/0012', '2021-01-18', 'Pemasukan Kas', 'PENDAPATAN  BUNGA DEB XTRA JAN 2021', 'X'),
(693, '1048/OUT/GG/I/2021', '2021-01-18', 'Pengeluaran Kas', 'pembelian aki mobil operasional ', 'X'),
(694, 'JU/202101/0013', '2021-01-18', 'Pengeluaran Kas', 'PINJAMAN KARYAWAN A,N TEDI SUHENDAR', 'X'),
(695, '1049/OUT/GG/I/2021', '2021-01-19', 'Pengeluaran Kas', 'By Opr Cab Pontianak ', 'X'),
(696, 'JU/202101/0014', '2021-01-15', 'Pengeluaran Kas', 'PEMBAYARAN TELKOM BULAN JANUARI  2021', 'X'),
(697, 'JU/202101/0015', '2021-01-12', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE JASA MADANI', 'X'),
(698, 'JU/202101/0016', '2021-01-18', 'Pengeluaran Kas', 'PEMBAYARAN PPH 21 DESEMBER 2020', 'X');
INSERT INTO `journal_voucher` (`journal_voucherid`, `journal_no`, `journal_date`, `jns_transaksi`, `headernote`, `validasi_status`) VALUES
(699, 'JU/202101/0017', '2021-01-20', 'Pengeluaran Kas', 'PBY MADU ASLI 1000GR                DIANA LESTARI', 'X'),
(700, 'JU/202101/0018', '2021-01-20', 'Pemasukan Kas', 'PENDAPATAN BUNGA DEB PLAT  JAN 2021', 'X'),
(701, 'JU/202101/0019', '2021-01-20', 'Pemasukan Kas', 'PENDAPATAN BAA DEB PLAT  JAN 2021', 'X'),
(702, 'JU/202101/0020', '2021-01-20', 'Pengeluaran Kas', 'pembayaran pokok Deb plat  jan 2021     ', 'X'),
(703, '1050/OUT/GG/I/2021', '2021-01-22', 'Pengeluaran Kas', 'biaya membership aplikasi zoom', 'X'),
(705, '1052/OUT/GG/I/2021', '2021-01-22', 'Pengeluaran Kas', 'by opr cab sleman', 'X'),
(706, '1051/OUT/GG/I/2021', '2021-01-22', 'Pengeluaran Kas', 'BY OPR CAB KUPANG ', 'X'),
(708, '1053/OUT/GG/I/2021', '2021-01-22', 'Pengeluaran Kas', 'by opr cab solo ', 'X'),
(709, '1054/OUT/GG/I/2021', '2021-01-21', 'Pengeluaran Kas', 'By Swab dan Vitamin swamitra tambun ', 'X'),
(710, '1055/OUT/GG/I/2021', '2021-01-23', 'Pengeluaran Kas', 'MEETING PENGURUS', 'X'),
(711, 'JU/202101/0021', '2021-01-11', 'Pengeluaran Kas', 'KSU GG PBY SEMBAKO', 'X'),
(712, '1056/OUT/GG/I/2021', '2021-01-24', 'Pengeluaran Kas', 'By listrik kantor ', 'X'),
(713, 'JU/202101/0022', '2021-01-22', 'Pengeluaran Kas', 'PENGISIAN SALDO AWAL BANK MANTAP', 'X'),
(714, 'JU/202101/0023', '2021-01-23', 'Pemasukan Kas', 'PBY SEMBAKO DR ABDUL RACHMA UTK GILANG GEMILANG', 'X'),
(715, 'JU/202101/0024', '2021-01-23', 'Pengeluaran Kas', 'TALANGAN ANGSURAN JAN 2021', 'X'),
(716, '1058/OUT/GG/I/2021', '2021-01-25', 'Pengeluaran Kas', 'kkr by transport Diana lestari ', 'X'),
(717, 'JU/202101/0025', '2021-01-25', 'Pemasukan Kas', 'PEMINDAHBUKUAN DR JEFRI MARLON', 'X'),
(718, 'JU/202101/0026', '2021-01-26', 'Pemasukan Kas', 'PEMINDAHBUKUAN DR JEFRI MARLON', NULL),
(719, '1059/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'pby token listrik ', 'X'),
(720, '1060/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'pengajuan by sewa kantor cab jombang ', 'X'),
(721, '1061/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'pengajuan by sewa kantor cab pontianak ', 'X'),
(722, '1062/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'By Opr Cab Aceh                 ', 'X'),
(723, 'JU/202101/0027', '2021-01-26', 'Pengeluaran Kas', 'PBY MADU ASLI 1000GR DIANA LESTARI', 'X'),
(724, '1063/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'pengajuan by sewa kantor cab kopang', 'X'),
(725, '1064/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'by opr cabang kupang ', 'X'),
(726, '1065/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'pengajuan by sewa kantor cab purwokerto ', 'X'),
(727, '1066/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'By Opr Cab Malang            ', 'X'),
(728, '1067/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'By Opr Cab Cirebon       ', 'X'),
(729, '1068/OUT/GG/I/2021', '2021-01-27', 'Pengeluaran Kas', 'by pembelian vit dan suplemen swamitra curug ', 'X'),
(730, '1069/OUT/GG/I/2021', '2021-01-27', 'Pengeluaran Kas', 'by pembelian vit dan suplemen swamitra kramatjati', 'X'),
(731, 'JU/202101/0028', '2021-01-27', 'Pemasukan Kas', 'PEMINDAHBUKUAN DR JEFRI MARLON', 'X'),
(732, 'PEMINDAHBUKUAN DR SUTRISNO', '2021-01-27', 'Pemasukan Kas', 'PEMINDAHBUKUAN DR SUTRISNO', 'X'),
(733, 'JU/202101/0030', '2021-01-27', 'Pemasukan Kas', 'PEMINDAHBUKUAN DR JEFRI MARLON', 'X'),
(734, '1070/OUT/GG/I/2021', '2021-01-26', 'Pengeluaran Kas', 'penurunan mtt swamitra harapan indah ', 'X'),
(735, 'JU/202101/0031', '2021-01-27', 'Pengeluaran Kas', 'BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN MARWAN', 'X'),
(736, '1071/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by swab antigen a.n rifaldi ', 'X'),
(737, '1072/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by swab antigen 6 org ', 'X'),
(738, '1073/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by swab antigen a.n ebnu utoro ', 'X'),
(739, 'JU/202101/0032', '2021-01-28', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE MANDIRI', 'X'),
(740, '1074/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by swab antigen a.n ridwan alviansyah ', 'X'),
(741, 'JU/202101/0033', '2021-01-28', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE MANDIRI', 'X'),
(742, 'JU/202101/0034', '2021-01-28', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE MANDIRI', 'X'),
(743, '1075/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'By Opr Cab Jakarta 3         ', 'X'),
(744, '1076/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by opr cab jombang ', 'X'),
(745, 'JU/202101/0035', '2021-01-28', 'Pengeluaran Kas', 'BY ADM TF PEMINDAHAN BUKUAN A.N HIDAYATULLOH', 'X'),
(746, 'JU/202101/0036', '2021-01-28', 'Pengeluaran Kas', 'BY ADM TF PEMINDAHAN BUKUAN A.N JEFRI MARLON', 'X'),
(747, 'JU/202101/0037', '2021-01-28', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(748, 'JU/202101/0038', '2021-01-28', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(759, 'JU/202101/0039', '2021-01-28', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(760, 'JU/202101/0040', '2021-01-27', 'Pengeluaran Kas', 'PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN MARWAN', 'X'),
(761, 'JU/202101/0041', '2021-01-28', 'Pengeluaran Kas', 'BY TF BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL', 'X'),
(763, 'JU/202101/0042', '2021-01-28', 'Pengeluaran Kas', 'BY TF PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL', 'X'),
(765, '1077/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by pulsa operasional jan 2021 ', 'X'),
(766, '1078/OUT/GG/I/2021', '2021-01-28', 'Pengeluaran Kas', 'by swab antigen 2 org ', 'X'),
(767, '1079/OUT/GG/I/2021', '2021-01-29', 'Pengeluaran Kas', 'By Opr Cab Purwokerto          ', 'X'),
(768, '1080/OUT/GG/I/2021', '2021-01-29', 'Pengeluaran Kas', 'by swab antigen a.n arif gustaman', 'X'),
(769, 'JU/202101/0045', '2021-01-29', 'Pemasukan Kas', 'PBY SEMBAKO DR EDDY P UNTUK GG', 'X'),
(770, 'JU/202101/0043', '2021-01-28', 'Pengeluaran Kas', 'CICILAN MOBIL JAN 21 KE  ARIF GUSTAMAN', 'X'),
(771, 'JU/202101/0046', '2021-01-28', 'Pengeluaran Kas', 'UMB KAS', 'X'),
(772, 'JU/202101/0047', '2021-01-29', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(774, 'JU/202101/0049', '2021-01-31', 'Pengeluaran Kas', 'B.ADM JAN 2021 ACCOUNT NO.1001343439', 'X'),
(775, 'PEMB. JASA GIRO JAN 2021 - 1001343439', '2021-01-31', 'Pemasukan Kas', 'PEMB. JASA GIRO JAN 2021 - 1001343439', 'X'),
(776, 'PAJAK JASA GIRO JAN 2021 - 1001343439', '2021-01-31', 'Pengeluaran Kas', 'PAJAK JASA GIRO JAN 2021 - 1001343439', 'X'),
(777, '1081/OUT/GG/1/2021', '2021-01-29', 'Pengeluaran Kas', 'Reimbusement kas kecil periode 4.1.2021 s/d 29.1.2021', 'X'),
(781, '601.01.01', '0000-00-00', '', '334975000', NULL),
(785, '601.01.01.02', '0000-00-00', '', '52100000', NULL),
(789, '601.01.01.03', '0000-00-00', '', '3100000', NULL),
(793, '407.01.01', '0000-00-00', '', '0', NULL),
(797, '111.01.01', '0000-00-00', '', '0', NULL),
(801, '203.99.01', '0000-00-00', '', '0', NULL),
(805, '103.04.01', '0000-00-00', '', '0', NULL),
(809, '103.06.01', '0000-00-00', '', '0', NULL),
(812, 'JU/202102/0001', '2021-02-01', 'Pemasukan Kas', 'PENURUNAN PIUTANG PENSIUN JAN 2021', 'X'),
(813, 'JU/202012/0063', '2021-02-01', 'Pemasukan Kas', 'PBY SEMBAKO DARI AGNY IRSYAD', 'X'),
(815, '1081/OUT/GG/II/2021', '2021-02-03', 'Pengeluaran Kas', 'By Opr Cab Madiun  ', 'X'),
(816, 'JU/202102/0002', '2021-02-03', 'Pemasukan Kas', 'PEMBAYARAN BUNGA DEB XTRA FEB 2021', 'X'),
(817, '1082/OUT/GG/II/2021', '2021-02-03', 'Pengeluaran Kas', 'Pengajuan UMB Operasional Atambua ', 'X'),
(818, 'JU/202102/0003', '2021-02-03', 'Pengeluaran Kas', 'PERTANGGUNGJAWABAN BY OPR CAB ATAMBUA', 'X'),
(819, '1083/OUT/GG/II/2021', '2021-02-03', 'Pengeluaran Kas', 'By Opr Cab Palembang', 'X'),
(821, '1084/OUT/GG/II/2021', '2021-02-05', 'Pengeluaran Kas', 'By pembelian vit cab malabar ', 'X'),
(822, 'JU/202102/0004', '2021-02-05', 'Pengeluaran Kas', 'MONTHLY CARD CHARGE 0004617003724020525', 'X'),
(823, '1085/OUT/GG/II/2021', '2021-02-09', 'Pengeluaran Kas', 'PBY BPJSTK ', 'X'),
(825, 'JU/202102/0006', '2021-02-10', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(826, 'JU/202102/0005', '2021-02-10', 'Pemasukan Kas', 'PEMINDAHBUKUAN DARI 439', 'X'),
(827, '1086/OUT/GG/II/2021', '2021-02-10', 'Pengeluaran Kas', 'pby BPJSKesehatan ', 'X'),
(828, 'JU/202102/0007', '2021-02-03', 'Pengeluaran Kas', 'UANG TALI KASIH Diana ', 'X'),
(829, 'JU/202102/0008', '2021-02-03', 'Pemasukan Kas', 'TRF DR AMRIZAL BANK MANDIRI (SEMBAKO)', 'X'),
(830, 'JU/202102/0009', '2021-02-08', 'Pengeluaran Kas', 'PIUTANG KARYAWAN A.N EBNU UTORO', 'X'),
(831, '1087/OUT/GG/II/2021', '2021-02-09', 'Pengeluaran Kas', 'By Opr Cab Tomohon', 'X'),
(832, 'JU/202102/0010', '2021-02-09', 'Pengeluaran Kas', 'PEMINDAHBUKUAN DANA KE MANDIRI', 'X'),
(833, '1088/OUT/GG/II/2021', '2021-02-16', 'Pengeluaran Kas', 'by swab antigen a.n linna susilawaty', 'X'),
(834, '1089/OUT/GG/II/2021', '2021-02-16', 'Pengeluaran Kas', 'By Opr Cab Pontianak', 'X'),
(835, '1090/OUT/GG/II/2021', '2021-02-16', 'Pengeluaran Kas', 'By Opr Cab Kupang', 'X');

-- --------------------------------------------------------

--
-- Table structure for table `journal_voucher_det`
--

CREATE TABLE `journal_voucher_det` (
  `journal_voucher_detid` int(11) NOT NULL,
  `journal_voucher_id` int(11) NOT NULL,
  `jns_akun_id` int(11) NOT NULL,
  `debit` decimal(30,2) NOT NULL DEFAULT 0.00,
  `credit` decimal(30,2) NOT NULL DEFAULT 0.00,
  `jns_cabangid` int(11) DEFAULT NULL,
  `itemnote` varchar(100) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `journal_voucher_det`
--

INSERT INTO `journal_voucher_det` (`journal_voucher_detid`, `journal_voucher_id`, `jns_akun_id`, `debit`, `credit`, `jns_cabangid`, `itemnote`) VALUES
(1, 4, 2, 0.00, 0.00, 0, ''),
(2, 4, 4, 0.00, 109772275.00, 0, ''),
(3, 4, 5, 0.00, 369100084.67, 0, ''),
(4, 4, 6, 1934936.24, 0.00, 0, ''),
(5, 4, 7, 91587133.24, 0.00, 0, ''),
(6, 4, 9, 69447661.33, 0.00, 0, ''),
(7, 4, 10, 0.00, 0.00, 0, ''),
(8, 4, 11, 658204406.00, 0.00, 0, ''),
(9, 4, 13, 0.00, 0.00, 0, ''),
(10, 4, 14, 0.00, 0.00, 0, ''),
(11, 4, 15, 0.00, 180011538.00, 0, ''),
(12, 4, 17, 0.00, 529012089.00, 0, ''),
(13, 4, 19, 394279154.00, 0.00, 0, ''),
(14, 4, 20, 0.00, 0.00, 0, ''),
(15, 4, 21, 6173568.00, 0.00, 0, ''),
(16, 4, 23, 0.00, 400000000.00, 0, ''),
(17, 4, 24, 0.00, 2910191.00, 0, ''),
(18, 4, 25, 0.00, 0.00, 0, ''),
(19, 4, 27, 9231500.00, 0.00, 0, ''),
(20, 4, 28, 0.00, 0.00, 0, ''),
(21, 4, 30, 0.00, 23277083.00, 0, ''),
(22, 4, 31, 30872772.00, 0.00, 0, ''),
(23, 4, 33, 19395000.00, 0.00, 0, ''),
(24, 4, 34, 0.00, 21974645.84, 0, ''),
(25, 4, 36, 0.00, 0.00, 0, ''),
(26, 4, 37, 0.00, 0.00, 0, ''),
(27, 4, 39, 0.00, 0.00, 0, ''),
(28, 4, 40, 0.00, 0.00, 0, ''),
(29, 4, 42, 0.00, 0.00, 0, ''),
(30, 4, 44, 0.00, 0.00, 0, ''),
(31, 4, 46, 0.00, 0.00, 0, ''),
(32, 4, 47, 2605611.00, 0.00, 0, ''),
(33, 4, 48, 0.00, 18027779.00, 0, ''),
(34, 4, 49, 0.00, 0.00, 0, ''),
(35, 4, 50, 0.00, 0.00, 0, ''),
(36, 4, 51, 0.00, 0.00, 0, ''),
(37, 4, 52, 405025560.00, 0.00, 0, ''),
(38, 4, 54, 0.00, 0.00, 0, ''),
(39, 4, 56, 0.00, 0.00, 0, ''),
(40, 4, 58, 0.00, 0.00, 0, ''),
(41, 4, 59, 0.00, 0.00, 0, ''),
(42, 4, 61, 0.00, 0.00, 0, ''),
(43, 4, 63, 0.00, 51735300.00, 0, ''),
(44, 4, 64, 0.00, 0.00, 0, ''),
(45, 4, 65, 225000000.00, 0.00, 0, ''),
(46, 4, 66, 75259460.00, 0.00, 0, ''),
(47, 4, 67, 0.00, 189981851.00, 0, ''),
(48, 4, 68, 0.00, 10000000.00, 0, ''),
(49, 4, 70, 0.00, 5400000.00, 0, ''),
(50, 4, 71, 0.00, 680000.00, 0, ''),
(51, 4, 72, 0.00, 0.00, 0, ''),
(52, 4, 73, 0.00, 10000000.00, 0, ''),
(53, 4, 74, 0.00, 0.00, 0, ''),
(54, 4, 75, 0.00, 0.00, 0, ''),
(55, 4, 76, 0.00, 0.00, 0, ''),
(56, 4, 77, 0.00, 0.00, 0, ''),
(57, 4, 78, 0.00, 0.00, 0, ''),
(58, 4, 79, 0.00, 67133925.31, 0, ''),
(59, 8, 2, 0.00, 0.00, 0, ''),
(60, 8, 4, 448891019.68, 0.00, 0, ''),
(61, 8, 5, 0.00, 265177365.94, 0, ''),
(62, 8, 6, 0.00, 0.00, 0, ''),
(63, 8, 7, 0.00, 0.00, 0, ''),
(64, 8, 9, 59403049.40, 0.00, 0, ''),
(65, 8, 10, 0.00, 0.00, 0, ''),
(66, 8, 11, 0.00, 14101.00, 0, ''),
(67, 8, 13, 0.00, 0.00, 0, ''),
(68, 8, 14, 0.00, 0.00, 0, ''),
(69, 8, 15, 45767335.00, 0.00, 0, ''),
(70, 8, 17, 5369100.00, 0.00, 0, ''),
(71, 8, 19, 0.00, 0.00, 0, ''),
(72, 8, 20, 0.00, 0.00, 0, ''),
(73, 8, 21, 0.00, 159275766.00, 0, ''),
(74, 8, 23, 0.00, 0.00, 0, ''),
(75, 8, 24, 1469820.00, 0.00, 0, ''),
(76, 8, 25, 0.00, 0.00, 0, ''),
(77, 8, 27, 0.00, 47097000.00, 0, ''),
(78, 8, 28, 0.00, 0.00, 0, ''),
(79, 8, 30, 0.00, 3277083.00, 0, ''),
(80, 8, 31, 30872772.00, 0.00, 0, ''),
(81, 8, 33, 19475000.00, 0.00, 0, ''),
(82, 8, 34, 0.00, 21602250.00, 0, ''),
(83, 8, 36, 0.00, 0.00, 0, ''),
(84, 8, 37, 0.00, 0.00, 0, ''),
(85, 8, 39, 0.00, 0.00, 0, ''),
(86, 8, 40, 0.00, 0.00, 0, ''),
(87, 8, 42, 0.00, 0.00, 0, ''),
(88, 8, 44, 0.00, 0.00, 0, ''),
(89, 8, 46, 0.00, 0.00, 0, ''),
(90, 8, 47, 4744444.00, 0.00, 0, ''),
(91, 8, 48, 0.00, 21289367.00, 0, ''),
(92, 8, 49, 0.00, 0.00, 0, ''),
(93, 8, 50, 0.00, 0.00, 0, ''),
(94, 8, 51, 0.00, 0.00, 0, ''),
(95, 8, 52, 0.00, 208407621.00, 0, ''),
(96, 8, 54, 0.00, 0.00, 0, ''),
(97, 8, 56, 0.00, 0.00, 0, ''),
(98, 8, 58, 0.00, 0.00, 0, ''),
(99, 8, 59, 0.00, 0.00, 0, ''),
(100, 8, 61, 0.00, 0.00, 0, ''),
(101, 8, 63, 308823399.00, 0.00, 0, ''),
(102, 8, 64, 0.00, 30000000.00, 0, ''),
(103, 8, 65, 0.00, 0.00, 0, ''),
(104, 8, 66, 51443466.91, 0.00, 0, ''),
(105, 8, 67, 0.00, 140334326.00, 0, ''),
(106, 8, 68, 0.00, 10627056.00, 0, ''),
(107, 8, 70, 0.00, 0.00, 0, ''),
(108, 8, 71, 0.00, 0.00, 0, ''),
(109, 8, 72, 0.00, 0.00, 0, ''),
(110, 8, 73, 0.00, 0.00, 0, ''),
(111, 8, 74, 0.00, 0.00, 0, ''),
(112, 8, 75, 0.00, 0.00, 0, ''),
(113, 8, 76, 0.00, 0.00, 0, ''),
(114, 8, 77, 20000000.00, 0.00, 0, ''),
(115, 8, 78, 0.00, 0.00, 0, ''),
(116, 8, 79, 0.00, 89157470.05, 0, ''),
(117, 12, 2, 0.00, 0.00, 0, ''),
(118, 12, 4, 0.00, 63825638.53, 0, ''),
(119, 12, 5, 0.00, 1092725332.39, 0, ''),
(120, 12, 6, 0.00, 0.00, 0, ''),
(121, 12, 7, 0.00, 0.00, 0, ''),
(122, 12, 9, 46221946.52, 0.00, 0, ''),
(123, 12, 10, 0.00, 0.00, 0, ''),
(124, 12, 11, 0.00, 10000000.00, 0, ''),
(125, 12, 13, 0.00, 0.00, 0, ''),
(126, 12, 14, 0.00, 0.00, 0, ''),
(127, 12, 15, 0.00, 280565346.00, 0, ''),
(128, 12, 17, 184000935.00, 0.00, 0, ''),
(129, 12, 19, 0.00, 0.00, 0, ''),
(130, 12, 20, 0.00, 0.00, 0, ''),
(131, 12, 21, 366265967.00, 0.00, 0, ''),
(132, 12, 23, 400000000.00, 0.00, 0, ''),
(133, 12, 24, 1440371.00, 0.00, 0, ''),
(134, 12, 25, 0.00, 0.00, 0, ''),
(135, 12, 27, 0.00, 17273500.00, 0, ''),
(136, 12, 28, 0.00, 0.00, 0, ''),
(137, 12, 30, 17556250.00, 0.00, 0, ''),
(138, 12, 31, 0.00, 0.00, 0, ''),
(139, 12, 33, 6150000.00, 0.00, 0, ''),
(140, 12, 34, 0.00, 21503291.66, 0, ''),
(141, 12, 36, 0.00, 0.00, 0, ''),
(142, 12, 37, 0.00, 0.00, 0, ''),
(143, 12, 39, 0.00, 0.00, 0, ''),
(144, 12, 40, 0.00, 0.00, 0, ''),
(145, 12, 42, 0.00, 0.00, 0, ''),
(146, 12, 44, 0.00, 0.00, 0, ''),
(147, 12, 46, 0.00, 0.00, 0, ''),
(148, 12, 47, 4744444.00, 0.00, 0, ''),
(149, 12, 48, 345656577.00, 0.00, 0, ''),
(150, 12, 49, 0.00, 0.00, 0, ''),
(151, 12, 50, 0.00, 0.00, 0, ''),
(152, 12, 51, 0.00, 0.00, 0, ''),
(153, 12, 52, 261866480.00, 0.00, 0, ''),
(154, 12, 54, 0.00, 0.00, 0, ''),
(155, 12, 56, 0.00, 0.00, 0, ''),
(156, 12, 58, 0.00, 0.00, 0, ''),
(157, 12, 59, 0.00, 0.00, 0, ''),
(158, 12, 61, 0.00, 0.00, 0, ''),
(159, 12, 63, 0.00, 35000000.00, 0, ''),
(160, 12, 64, 0.00, 15000000.00, 0, ''),
(161, 12, 65, 0.00, 0.00, 0, ''),
(162, 12, 66, 0.00, 405000000.00, 0, ''),
(163, 12, 67, 0.00, 161579602.00, 0, ''),
(164, 12, 68, 0.00, 46090556.00, 0, ''),
(165, 12, 70, 0.00, 0.00, 0, ''),
(166, 12, 71, 0.00, 45600000.00, 0, ''),
(167, 12, 72, 0.00, 0.00, 0, ''),
(168, 12, 73, 0.00, 0.00, 0, ''),
(169, 12, 74, 0.00, 0.00, 0, ''),
(170, 12, 75, 0.00, 482213829.00, 0, ''),
(171, 12, 76, 0.00, 12055346.00, 0, ''),
(172, 12, 77, 0.00, 30138364.00, 0, ''),
(173, 12, 78, 1205534570.88, 0.00, 0, ''),
(174, 12, 79, 0.00, 120866735.81, 0, ''),
(175, 16, 2, 0.00, 0.00, 0, ''),
(176, 16, 4, 122014728.40, 0.00, 0, ''),
(177, 16, 5, 149481610.15, 0.00, 0, ''),
(178, 16, 6, 0.00, 0.00, 0, ''),
(179, 16, 7, 0.00, 0.00, 0, ''),
(180, 16, 9, 0.00, 0.00, 0, ''),
(181, 16, 10, 0.00, 0.00, 0, ''),
(182, 16, 11, 25000000.00, 0.00, 0, ''),
(183, 16, 13, 0.00, 0.00, 0, ''),
(184, 16, 14, 0.00, 0.00, 0, ''),
(185, 16, 15, 0.00, 3297517.00, 0, ''),
(186, 16, 17, 0.00, 217789592.00, 0, ''),
(187, 16, 19, 0.00, 0.00, 0, ''),
(188, 16, 20, 0.00, 0.00, 0, ''),
(189, 16, 21, 8215967.00, 0.00, 0, ''),
(190, 16, 23, 0.00, 0.00, 0, ''),
(191, 16, 24, 0.00, 0.00, 0, ''),
(192, 16, 25, 0.00, 0.00, 0, ''),
(193, 16, 27, 34611000.00, 0.00, 0, ''),
(194, 16, 28, 0.00, 14000000.00, 0, ''),
(195, 16, 30, 0.00, 2443750.00, 0, ''),
(196, 16, 31, 0.00, 0.00, 0, ''),
(197, 16, 33, 510000.00, 0.00, 0, ''),
(198, 16, 34, 0.00, 21474125.00, 0, ''),
(199, 16, 36, 0.00, 0.00, 0, ''),
(200, 16, 37, 0.00, 0.00, 0, ''),
(201, 16, 39, 0.00, 0.00, 0, ''),
(202, 16, 40, 0.00, 0.00, 0, ''),
(203, 16, 42, 0.00, 0.00, 0, ''),
(204, 16, 44, 0.00, 0.00, 0, ''),
(205, 16, 46, 0.00, 0.00, 0, ''),
(206, 16, 47, 4744444.00, 0.00, 0, ''),
(207, 16, 48, 0.00, 43875354.00, 0, ''),
(208, 16, 49, 0.00, 0.00, 0, ''),
(209, 16, 50, 0.00, 0.00, 0, ''),
(210, 16, 51, 0.00, 0.00, 0, ''),
(211, 16, 52, 105594638.00, 0.00, 0, ''),
(212, 16, 54, 0.00, 0.00, 0, ''),
(213, 16, 56, 0.00, 0.00, 0, ''),
(214, 16, 58, 0.00, 0.00, 0, ''),
(215, 16, 59, 0.00, 0.00, 0, ''),
(216, 16, 61, 0.00, 0.00, 0, ''),
(217, 16, 63, 0.00, 180700000.00, 0, ''),
(218, 16, 64, 0.00, 20000000.00, 0, ''),
(219, 16, 65, 0.00, 0.00, 0, ''),
(220, 16, 66, 349077363.00, 0.00, 0, ''),
(221, 16, 67, 0.00, 166355493.00, 0, ''),
(222, 16, 68, 0.00, 1640000.00, 0, ''),
(223, 16, 70, 0.00, 0.00, 0, ''),
(224, 16, 71, 0.00, 0.00, 0, ''),
(225, 16, 72, 0.00, 0.00, 0, ''),
(226, 16, 73, 0.00, 0.00, 0, ''),
(227, 16, 74, 0.00, 0.00, 0, ''),
(228, 16, 75, 0.00, 0.00, 0, ''),
(229, 16, 76, 0.00, 0.00, 0, ''),
(230, 16, 77, 4000000.00, 0.00, 0, ''),
(231, 16, 78, 0.00, 0.00, 0, ''),
(232, 16, 79, 0.00, 131673919.55, 0, ''),
(233, 20, 2, 0.00, 0.00, 0, ''),
(234, 20, 4, 0.00, 438015531.87, 0, ''),
(235, 20, 5, 1024542995.94, 0.00, 0, ''),
(236, 20, 6, 0.00, 0.00, 0, ''),
(237, 20, 7, 0.00, 0.00, 0, ''),
(238, 20, 9, 0.00, 11437637.61, 0, ''),
(239, 20, 10, 0.00, 6364246.41, 0, ''),
(240, 20, 11, 0.00, 0.00, 0, ''),
(241, 20, 13, 77000000.00, 0.00, 0, ''),
(242, 20, 14, 0.00, 89000000.00, 0, ''),
(243, 20, 15, 0.00, 408003393.00, 0, ''),
(244, 20, 17, 255415732.00, 0.00, 0, ''),
(245, 20, 19, 0.00, 0.00, 0, ''),
(246, 20, 20, 0.00, 0.00, 0, ''),
(247, 20, 21, 0.00, 13889100.00, 0, ''),
(248, 20, 23, 0.00, 0.00, 0, ''),
(249, 20, 24, 0.00, 0.00, 0, ''),
(250, 20, 25, 0.00, 0.00, 0, ''),
(251, 20, 27, 0.00, 63407600.00, 0, ''),
(252, 20, 28, 17000000.00, 0.00, 0, ''),
(253, 20, 30, 58422917.00, 0.00, 0, ''),
(254, 20, 31, 0.00, 0.00, 0, ''),
(255, 20, 33, 112726000.00, 0.00, 0, ''),
(256, 20, 34, 0.00, 21027020.84, 0, ''),
(257, 20, 36, 0.00, 0.00, 0, ''),
(258, 20, 37, 0.00, 0.00, 0, ''),
(259, 20, 39, 0.00, 0.00, 0, ''),
(260, 20, 40, 0.00, 0.00, 0, ''),
(261, 20, 42, 0.00, 0.00, 0, ''),
(262, 20, 44, 0.00, 0.00, 0, ''),
(263, 20, 46, 0.00, 0.00, 0, ''),
(264, 20, 47, 4744444.00, 0.00, 0, ''),
(265, 20, 48, 0.00, 85853169.00, 0, ''),
(266, 20, 49, 0.00, 0.00, 0, ''),
(267, 20, 50, 0.00, 0.00, 0, ''),
(268, 20, 51, 0.00, 0.00, 0, ''),
(269, 20, 52, 415045485.00, 0.00, 0, ''),
(270, 20, 54, 0.00, 0.00, 0, ''),
(271, 20, 56, 0.00, 0.00, 0, ''),
(272, 20, 58, 0.00, 0.00, 0, ''),
(273, 20, 59, 0.00, 0.00, 0, ''),
(274, 20, 61, 0.00, 0.00, 0, ''),
(275, 20, 63, 0.00, 146583350.00, 0, ''),
(276, 20, 64, 0.00, 103470600.00, 0, ''),
(277, 20, 65, 0.00, 0.00, 0, ''),
(278, 20, 66, 0.00, 188088303.00, 0, ''),
(279, 20, 67, 0.00, 0.00, 0, ''),
(280, 20, 68, 0.00, 150000000.00, 0, ''),
(281, 20, 70, 0.00, 0.00, 0, ''),
(282, 20, 71, 0.00, 0.00, 0, ''),
(283, 20, 72, 0.00, 0.00, 0, ''),
(284, 20, 73, 0.00, 0.00, 0, ''),
(285, 20, 74, 0.00, 0.00, 0, ''),
(286, 20, 75, 0.00, 0.00, 0, ''),
(287, 20, 76, 0.00, 0.00, 0, ''),
(288, 20, 77, 12000000.00, 0.00, 0, ''),
(289, 20, 78, 0.00, 0.00, 0, ''),
(290, 20, 79, 0.00, 251757622.22, 0, ''),
(291, 24, 2, 6000000.00, 0.00, 0, ''),
(292, 24, 4, 546875826.79, 0.00, 0, ''),
(293, 24, 5, 1196421454.11, 0.00, 0, ''),
(294, 24, 6, 0.00, 0.00, 0, ''),
(295, 24, 7, 0.00, 0.00, 0, ''),
(296, 24, 9, 475109991.51, 0.00, 0, ''),
(297, 24, 10, 6364246.41, 0.00, 0, ''),
(298, 24, 11, 0.00, 0.00, 0, ''),
(299, 24, 13, 280063552.00, 0.00, 0, ''),
(300, 24, 14, 0.00, 100000000.00, 0, ''),
(301, 24, 15, 1161831295.97, 0.00, 0, ''),
(302, 24, 17, 400000000.00, 0.00, 0, ''),
(303, 24, 19, 0.00, 0.00, 0, ''),
(304, 24, 20, 0.00, 0.00, 0, ''),
(305, 24, 21, 425098895.00, 0.00, 0, ''),
(306, 24, 23, 0.00, 0.00, 0, ''),
(307, 24, 24, 0.00, 0.00, 0, ''),
(308, 24, 25, 0.00, 0.00, 0, ''),
(309, 24, 27, 150434650.00, 0.00, 0, ''),
(310, 24, 28, 4000000.00, 0.00, 0, ''),
(311, 24, 30, 180489583.00, 0.00, 0, ''),
(312, 24, 31, 0.00, 0.00, 0, ''),
(313, 24, 33, 927169000.00, 0.00, 0, ''),
(314, 24, 34, 0.00, 245374062.50, 0, ''),
(315, 24, 36, 0.00, 0.00, 0, ''),
(316, 24, 37, 0.00, 0.00, 0, ''),
(317, 24, 39, 0.00, 0.00, 0, ''),
(318, 24, 40, 0.00, 0.00, 0, ''),
(319, 24, 42, 0.00, 0.00, 0, ''),
(320, 24, 44, 0.00, 0.00, 0, ''),
(321, 24, 46, 0.00, 0.00, 0, ''),
(322, 24, 47, 0.00, 45027788.00, 0, ''),
(323, 24, 48, 0.00, 431483601.00, 0, ''),
(324, 24, 49, 0.00, 0.00, 0, ''),
(325, 24, 50, 0.00, 0.00, 0, ''),
(326, 24, 51, 0.00, 0.00, 0, ''),
(327, 24, 52, 0.00, 1279615652.00, 0, ''),
(328, 24, 54, 0.00, 0.00, 0, ''),
(329, 24, 56, 0.00, 0.00, 0, ''),
(330, 24, 58, 0.00, 0.00, 0, ''),
(331, 24, 59, 0.00, 0.00, 0, ''),
(332, 24, 61, 0.00, 0.00, 0, ''),
(333, 24, 63, 0.00, 194027630.00, 0, ''),
(334, 24, 64, 0.00, 300678749.00, 0, ''),
(335, 24, 65, 0.00, 225000000.00, 0, ''),
(336, 24, 66, 0.00, 716747006.00, 0, ''),
(337, 24, 67, 0.00, 239125142.00, 0, ''),
(338, 24, 68, 0.00, 191456500.00, 0, ''),
(339, 24, 70, 0.00, 97500000.00, 0, ''),
(340, 24, 71, 0.00, 120250000.00, 0, ''),
(341, 24, 72, 0.00, 0.00, 0, ''),
(342, 24, 73, 0.00, 184633167.00, 0, ''),
(343, 24, 74, 0.00, 0.00, 0, ''),
(344, 24, 75, 0.00, 0.00, 0, ''),
(345, 24, 76, 0.00, 38960444.00, 0, ''),
(346, 24, 77, 0.00, 16164891.00, 0, ''),
(347, 24, 78, 0.00, 1205534570.88, 0, ''),
(348, 24, 79, 0.00, 128279291.41, 0, ''),
(471, 81, 143, 0.00, 1003348439.00, 0, ''),
(472, 81, 144, 0.00, 403717482.83, 0, ''),
(473, 81, 145, 0.00, 0.00, 0, ''),
(474, 81, 146, 0.00, 0.00, 0, ''),
(475, 81, 147, 0.00, 110670336.00, 0, ''),
(476, 81, 148, 0.00, 0.00, 0, ''),
(477, 81, 149, 0.00, 0.00, 0, ''),
(478, 81, 150, 0.00, 0.00, 0, ''),
(479, 81, 151, 0.00, 0.00, 0, ''),
(480, 81, 152, 0.00, 0.00, 0, ''),
(481, 81, 154, 0.00, 0.00, 0, ''),
(482, 81, 155, 0.00, 0.00, 0, ''),
(483, 81, 156, 0.00, 0.00, 0, ''),
(484, 81, 157, 0.00, 0.00, 0, ''),
(485, 81, 158, 0.00, 0.00, 0, ''),
(486, 81, 159, 0.00, 0.00, 0, ''),
(487, 81, 161, 0.00, 0.00, 0, ''),
(488, 81, 162, 0.00, 0.00, 0, ''),
(489, 81, 163, 0.00, 0.00, 0, ''),
(490, 81, 164, 0.00, 0.00, 0, ''),
(491, 81, 166, 0.00, 0.00, 0, ''),
(492, 81, 167, 0.00, 0.00, 0, ''),
(493, 81, 168, 0.00, 0.00, 0, ''),
(494, 81, 169, 0.00, 0.00, 0, ''),
(495, 81, 170, 0.00, 0.00, 0, ''),
(496, 81, 171, 0.00, 0.00, 0, ''),
(497, 81, 173, 0.00, 0.00, 0, ''),
(498, 81, 174, 0.00, 0.00, 0, ''),
(499, 81, 175, 0.00, 0.00, 0, ''),
(500, 81, 85, 0.00, 0.00, 0, ''),
(501, 81, 86, 0.00, 0.00, 0, ''),
(502, 81, 87, 0.00, 0.00, 0, ''),
(503, 81, 89, 14330615.00, 0.00, 0, ''),
(504, 81, 90, 50212420.00, 0.00, 0, ''),
(505, 81, 91, 0.00, 0.00, 0, ''),
(506, 81, 92, 0.00, 0.00, 0, ''),
(507, 81, 93, 125000000.00, 0.00, 0, ''),
(508, 81, 94, 0.00, 0.00, 0, ''),
(509, 81, 95, 100000000.00, 0.00, 0, ''),
(510, 81, 96, 0.00, 0.00, 0, ''),
(511, 81, 98, 492828000.00, 0.00, 0, ''),
(512, 81, 99, 51425000.00, 0.00, 0, ''),
(513, 81, 100, 0.00, 0.00, 0, ''),
(514, 81, 101, 5100000.00, 0.00, 0, ''),
(515, 81, 102, 11434503.00, 0.00, 0, ''),
(516, 81, 103, 24197898.00, 0.00, 0, ''),
(517, 81, 104, 7915952.00, 0.00, 0, ''),
(518, 81, 105, 43112750.00, 0.00, 0, ''),
(519, 81, 106, 106130075.00, 0.00, 0, ''),
(520, 81, 107, 51735300.00, 0.00, 0, ''),
(521, 81, 108, 40000430.00, 0.00, 0, ''),
(522, 81, 176, 300000.00, 0.00, 0, ''),
(523, 81, 110, 19252770.83, 0.00, 0, ''),
(524, 81, 111, 0.00, 0.00, 0, ''),
(525, 81, 112, 0.00, 0.00, 0, ''),
(526, 81, 113, 2455000.00, 0.00, 0, ''),
(527, 81, 114, 0.00, 0.00, 0, ''),
(528, 81, 115, 0.00, 0.00, 0, ''),
(529, 81, 116, 0.00, 0.00, 0, ''),
(530, 81, 117, 0.00, 0.00, 0, ''),
(531, 81, 118, 12760417.00, 0.00, 0, ''),
(532, 81, 119, 112000.00, 0.00, 0, ''),
(533, 81, 120, 0.00, 0.00, 0, ''),
(534, 81, 121, 0.00, 0.00, 0, ''),
(535, 81, 122, 2083500.00, 0.00, 0, ''),
(536, 81, 123, 1277900.00, 0.00, 0, ''),
(537, 81, 124, 0.00, 0.00, 0, ''),
(538, 81, 125, 6774990.00, 0.00, 0, ''),
(539, 81, 126, 1163017.59, 0.00, 0, ''),
(540, 81, 127, 8045600.00, 0.00, 0, ''),
(541, 81, 128, 0.00, 0.00, 0, ''),
(542, 81, 129, 2871000.00, 0.00, 0, ''),
(543, 81, 130, 0.00, 0.00, 0, ''),
(544, 81, 131, 0.00, 0.00, 0, ''),
(545, 81, 132, 4375232.00, 0.00, 0, ''),
(546, 81, 133, 102921700.00, 0.00, 0, ''),
(547, 81, 135, 10000000.00, 0.00, 0, ''),
(548, 81, 136, 20790000.00, 0.00, 0, ''),
(549, 81, 137, 0.00, 0.00, 0, ''),
(550, 81, 138, 0.00, 0.00, 0, ''),
(551, 81, 139, 28091132.00, 0.00, 0, ''),
(552, 81, 141, 42759764.00, 0.00, 0, ''),
(553, 85, 143, 0.00, 1107195527.00, 0, ''),
(554, 85, 144, 0.00, 767026166.67, 0, ''),
(555, 85, 145, 0.00, 0.00, 0, ''),
(556, 85, 146, 0.00, 0.00, 0, ''),
(557, 85, 147, 0.00, 130415732.00, 0, ''),
(558, 85, 148, 0.00, 133826350.00, 0, ''),
(559, 85, 149, 0.00, 0.00, 0, ''),
(560, 85, 150, 0.00, 0.00, 0, ''),
(561, 85, 151, 0.00, 0.00, 0, ''),
(562, 85, 152, 0.00, 0.00, 0, ''),
(563, 85, 154, 0.00, 0.00, 0, ''),
(564, 85, 155, 0.00, 0.00, 0, ''),
(565, 85, 156, 0.00, 0.00, 0, ''),
(566, 85, 157, 0.00, 0.00, 0, ''),
(567, 85, 158, 0.00, 0.00, 0, ''),
(568, 85, 159, 0.00, 0.00, 0, ''),
(569, 85, 161, 0.00, 0.00, 0, ''),
(570, 85, 162, 0.00, 0.00, 0, ''),
(571, 85, 163, 0.00, 0.00, 0, ''),
(572, 85, 164, 0.00, 0.00, 0, ''),
(573, 85, 166, 0.00, 0.00, 0, ''),
(574, 85, 167, 0.00, 0.00, 0, ''),
(575, 85, 168, 0.00, 0.00, 0, ''),
(576, 85, 169, 0.00, 0.00, 0, ''),
(577, 85, 170, 0.00, 0.00, 0, ''),
(578, 85, 171, 0.00, 0.00, 0, ''),
(579, 85, 173, 0.00, 0.00, 0, ''),
(580, 85, 174, 0.00, 0.00, 0, ''),
(581, 85, 175, 0.00, 0.00, 0, ''),
(582, 85, 85, 0.00, 0.00, 0, ''),
(583, 85, 86, 0.00, 0.00, 0, ''),
(584, 85, 87, 0.00, 0.00, 0, ''),
(585, 85, 89, 67785136.00, 0.00, 0, ''),
(586, 85, 90, 113201211.00, 0.00, 0, ''),
(587, 85, 91, 0.00, 0.00, 0, ''),
(588, 85, 92, 127089750.00, 0.00, 0, ''),
(589, 85, 93, 200000000.00, 0.00, 0, ''),
(590, 85, 94, 0.00, 0.00, 0, ''),
(591, 85, 95, 89000000.00, 0.00, 0, ''),
(592, 85, 96, 0.00, 0.00, 0, ''),
(593, 85, 98, 491623999.00, 0.00, 0, ''),
(594, 85, 99, 59625000.00, 0.00, 0, ''),
(595, 85, 100, 0.00, 0.00, 0, ''),
(596, 85, 101, 3600000.00, 0.00, 0, ''),
(597, 85, 102, 10257332.00, 0.00, 0, ''),
(598, 85, 103, 31842888.00, 0.00, 0, ''),
(599, 85, 104, 7228959.00, 0.00, 0, ''),
(600, 85, 105, 43112750.00, 0.00, 0, ''),
(601, 85, 106, 160470600.00, 0.00, 0, ''),
(602, 85, 107, 103470600.00, 0.00, 0, ''),
(603, 85, 108, 21251543.00, 0.00, 0, ''),
(604, 85, 176, 0.00, 0.00, 0, ''),
(605, 85, 110, 21027020.83, 0.00, 0, ''),
(606, 85, 111, 0.00, 0.00, 0, ''),
(607, 85, 112, 0.00, 0.00, 0, ''),
(608, 85, 113, 17640000.00, 0.00, 0, ''),
(609, 85, 114, 0.00, 0.00, 0, ''),
(610, 85, 115, 0.00, 0.00, 0, ''),
(611, 85, 116, 0.00, 0.00, 0, ''),
(612, 85, 117, 0.00, 0.00, 0, ''),
(613, 85, 118, 20777083.00, 0.00, 0, ''),
(614, 85, 119, 1433100.00, 0.00, 0, ''),
(615, 85, 120, 0.00, 0.00, 0, ''),
(616, 85, 121, 0.00, 0.00, 0, ''),
(617, 85, 122, 2093000.00, 0.00, 0, ''),
(618, 85, 123, 2348244.00, 0.00, 0, ''),
(619, 85, 124, 0.00, 0.00, 0, ''),
(620, 85, 125, 3433200.00, 0.00, 0, ''),
(621, 85, 126, 1360473.13, 0.00, 0, ''),
(622, 85, 127, 5300700.00, 0.00, 0, ''),
(623, 85, 128, 0.00, 0.00, 0, ''),
(624, 85, 129, 3009000.00, 0.00, 0, ''),
(625, 85, 130, 0.00, 0.00, 0, ''),
(626, 85, 131, 0.00, 0.00, 0, ''),
(627, 85, 132, 4375232.00, 0.00, 0, ''),
(628, 85, 133, 126144350.00, 0.00, 0, ''),
(629, 85, 135, 10000000.00, 0.00, 0, ''),
(630, 85, 136, 13250000.00, 0.00, 0, ''),
(631, 85, 137, 0.00, 0.00, 0, ''),
(632, 85, 138, 0.00, 0.00, 0, ''),
(633, 85, 139, 39101813.49, 0.00, 0, ''),
(634, 85, 141, 85853169.00, 0.00, 0, ''),
(635, 89, 143, 0.00, 1074482734.00, 0, ''),
(636, 89, 144, 0.00, 549669308.92, 0, ''),
(637, 89, 145, 0.00, 0.00, 0, ''),
(638, 89, 146, 0.00, 0.00, 0, ''),
(639, 89, 147, 0.00, 112269640.00, 0, ''),
(640, 89, 148, 0.00, 275029037.00, 0, ''),
(641, 89, 149, 0.00, 0.00, 0, ''),
(642, 89, 150, 0.00, 0.00, 0, ''),
(643, 89, 151, 0.00, 0.00, 0, ''),
(644, 89, 152, 0.00, 0.00, 0, ''),
(645, 89, 154, 0.00, 0.00, 0, ''),
(646, 89, 155, 0.00, 0.00, 0, ''),
(647, 89, 156, 0.00, 0.00, 0, ''),
(648, 89, 157, 0.00, 0.00, 0, ''),
(649, 89, 158, 0.00, 0.00, 0, ''),
(650, 89, 159, 0.00, 0.00, 0, ''),
(651, 89, 161, 0.00, 0.00, 0, ''),
(652, 89, 162, 0.00, 0.00, 0, ''),
(653, 89, 163, 0.00, 0.00, 0, ''),
(654, 89, 164, 0.00, 0.00, 0, ''),
(655, 89, 166, 0.00, 0.00, 0, ''),
(656, 89, 167, 0.00, 0.00, 0, ''),
(657, 89, 168, 0.00, 0.00, 0, ''),
(658, 89, 169, 0.00, 0.00, 0, ''),
(659, 89, 170, 0.00, 0.00, 0, ''),
(660, 89, 171, 0.00, 0.00, 0, ''),
(661, 89, 173, 0.00, 0.00, 0, ''),
(662, 89, 174, 0.00, 0.00, 0, ''),
(663, 89, 175, 0.00, 0.00, 0, ''),
(664, 89, 85, 0.00, 0.00, 0, ''),
(665, 89, 86, 0.00, 0.00, 0, ''),
(666, 89, 87, 0.00, 0.00, 0, ''),
(667, 89, 89, 111413784.00, 0.00, 0, ''),
(668, 89, 90, 90077981.00, 0.00, 0, ''),
(669, 89, 91, 0.00, 0.00, 0, ''),
(670, 89, 92, 259052270.00, 0.00, 0, ''),
(671, 89, 93, 234170688.00, 0.00, 0, ''),
(672, 89, 94, 0.00, 0.00, 0, ''),
(673, 89, 95, 100000000.00, 0.00, 0, ''),
(674, 89, 96, 0.00, 0.00, 0, ''),
(675, 89, 98, 500846572.00, 0.00, 0, ''),
(676, 89, 99, 64250000.00, 0.00, 0, ''),
(677, 89, 100, 0.00, 0.00, 0, ''),
(678, 89, 101, 3600000.00, 0.00, 0, ''),
(679, 89, 102, 11822166.00, 0.00, 0, ''),
(680, 89, 103, 34325559.00, 0.00, 0, ''),
(681, 89, 104, 7037395.00, 0.00, 0, ''),
(682, 89, 105, 150000000.00, 0.00, 0, ''),
(683, 89, 106, 57000000.00, 0.00, 0, ''),
(684, 89, 107, 20000000.00, 0.00, 0, ''),
(685, 89, 108, 19639489.00, 0.00, 0, ''),
(686, 89, 176, 35250000.00, 0.00, 0, ''),
(687, 89, 110, 21474125.00, 0.00, 0, ''),
(688, 89, 111, 0.00, 0.00, 0, ''),
(689, 89, 112, 0.00, 0.00, 0, ''),
(690, 89, 113, 1698000.00, 0.00, 0, ''),
(691, 89, 114, 0.00, 0.00, 0, ''),
(692, 89, 115, 0.00, 0.00, 0, ''),
(693, 89, 116, 0.00, 0.00, 0, ''),
(694, 89, 117, 0.00, 0.00, 0, ''),
(695, 89, 118, 22443750.00, 0.00, 0, ''),
(696, 89, 119, 369000.00, 0.00, 0, ''),
(697, 89, 120, 0.00, 0.00, 0, ''),
(698, 89, 121, 0.00, 0.00, 0, ''),
(699, 89, 122, 2562000.00, 0.00, 0, ''),
(700, 89, 123, 2517244.00, 0.00, 0, ''),
(701, 89, 124, 0.00, 0.00, 0, ''),
(702, 89, 125, 9608030.00, 0.00, 0, ''),
(703, 89, 126, 1390748.37, 0.00, 0, ''),
(704, 89, 127, 7642542.00, 0.00, 0, ''),
(705, 89, 128, 0.00, 0.00, 0, ''),
(706, 89, 129, 4368500.00, 0.00, 0, ''),
(707, 89, 130, 0.00, 0.00, 0, ''),
(708, 89, 131, 0.00, 0.00, 0, ''),
(709, 89, 132, 4375194.00, 0.00, 0, ''),
(710, 89, 133, 33468750.00, 0.00, 0, ''),
(711, 89, 135, 10000000.00, 0.00, 0, ''),
(712, 89, 136, 2500000.00, 0.00, 0, ''),
(713, 89, 137, 0.00, 0.00, 0, ''),
(714, 89, 138, 0.00, 0.00, 0, ''),
(715, 89, 139, 12981707.00, 0.00, 0, ''),
(716, 89, 141, 43891306.00, 0.00, 0, ''),
(717, 93, 143, 0.00, 1111991782.00, 0, ''),
(718, 93, 144, 0.00, 459317110.09, 0, ''),
(719, 93, 145, 0.00, 0.00, 0, ''),
(720, 93, 146, 0.00, 0.00, 0, ''),
(721, 93, 147, 0.00, 92181400.00, 0, ''),
(722, 93, 148, 0.00, 387495675.00, 0, ''),
(723, 93, 149, 0.00, 0.00, 0, ''),
(724, 93, 150, 0.00, 0.00, 0, ''),
(725, 93, 151, 0.00, 0.00, 0, ''),
(726, 93, 152, 0.00, 0.00, 0, ''),
(727, 93, 154, 0.00, 0.00, 0, ''),
(728, 93, 155, 0.00, 0.00, 0, ''),
(729, 93, 156, 0.00, 0.00, 0, ''),
(730, 93, 157, 0.00, 0.00, 0, ''),
(731, 93, 158, 0.00, 0.00, 0, ''),
(732, 93, 159, 0.00, 1440371.00, 0, ''),
(733, 93, 161, 0.00, 0.00, 0, ''),
(734, 93, 162, 0.00, 0.00, 0, ''),
(735, 93, 163, 0.00, 0.00, 0, ''),
(736, 93, 164, 0.00, 0.00, 0, ''),
(737, 93, 166, 0.00, 0.00, 0, ''),
(738, 93, 167, 0.00, 0.00, 0, ''),
(739, 93, 168, 0.00, 0.00, 0, ''),
(740, 93, 169, 0.00, 0.00, 0, ''),
(741, 93, 170, 0.00, 0.00, 0, ''),
(742, 93, 171, 0.00, 0.00, 0, ''),
(743, 93, 173, 0.00, 0.00, 0, ''),
(744, 93, 174, 0.00, 0.00, 0, ''),
(745, 93, 175, 0.00, 0.00, 0, ''),
(746, 93, 85, 0.00, 0.00, 0, ''),
(747, 93, 86, 0.00, 0.00, 0, ''),
(748, 93, 87, 0.00, 0.00, 0, ''),
(749, 93, 89, 80876334.00, 0.00, 0, ''),
(750, 93, 90, 39612000.00, 0.00, 0, ''),
(751, 93, 91, 0.00, 0.00, 0, ''),
(752, 93, 92, 374066805.00, 0.00, 0, ''),
(753, 93, 93, 331151161.00, 0.00, 0, ''),
(754, 93, 94, 0.00, 0.00, 0, ''),
(755, 93, 95, 100000000.00, 0.00, 0, ''),
(756, 93, 96, 0.00, 0.00, 0, ''),
(757, 93, 98, 492992900.00, 0.00, 0, ''),
(758, 93, 99, 64825000.00, 0.00, 0, ''),
(759, 93, 100, 0.00, 0.00, 0, ''),
(760, 93, 101, 3600000.00, 0.00, 0, ''),
(761, 93, 102, 11639417.00, 0.00, 0, ''),
(762, 93, 103, 33733710.00, 0.00, 0, ''),
(763, 93, 104, 9395179.00, 0.00, 0, ''),
(764, 93, 105, 75000000.00, 0.00, 0, ''),
(765, 93, 106, 175330422.00, 0.00, 0, ''),
(766, 93, 107, 15000000.00, 0.00, 0, ''),
(767, 93, 108, 0.00, 0.00, 0, ''),
(768, 93, 176, 0.00, 0.00, 0, ''),
(769, 93, 110, 21503291.67, 0.00, 0, ''),
(770, 93, 111, 0.00, 0.00, 0, ''),
(771, 93, 112, 0.00, 0.00, 0, ''),
(772, 93, 113, 250000.00, 0.00, 0, ''),
(773, 93, 114, 0.00, 0.00, 0, ''),
(774, 93, 115, 0.00, 0.00, 0, ''),
(775, 93, 116, 0.00, 0.00, 0, ''),
(776, 93, 117, 0.00, 0.00, 0, ''),
(777, 93, 118, 22443750.00, 0.00, 0, ''),
(778, 93, 119, 152500.00, 0.00, 0, ''),
(779, 93, 120, 0.00, 0.00, 0, ''),
(780, 93, 121, 0.00, 0.00, 0, ''),
(781, 93, 122, 1001000.00, 0.00, 0, ''),
(782, 93, 123, 3052244.00, 0.00, 0, ''),
(783, 93, 124, 0.00, 0.00, 0, ''),
(784, 93, 125, 7934402.00, 0.00, 0, ''),
(785, 93, 126, 1105608.61, 0.00, 0, ''),
(786, 93, 127, 6242200.00, 0.00, 0, ''),
(787, 93, 128, 0.00, 0.00, 0, ''),
(788, 93, 129, 3069500.00, 0.00, 0, ''),
(789, 93, 130, 0.00, 0.00, 0, ''),
(790, 93, 131, 0.00, 0.00, 0, ''),
(791, 93, 132, 4375194.00, 0.00, 0, ''),
(792, 93, 133, 6229800.00, 0.00, 0, ''),
(793, 93, 135, 10000000.00, 0.00, 0, ''),
(794, 93, 136, 1000000.00, 0.00, 0, ''),
(795, 93, 137, 0.00, 0.00, 0, ''),
(796, 93, 138, 0.00, 0.00, 0, ''),
(797, 93, 139, 13260500.00, 0.00, 0, ''),
(798, 93, 141, 22716684.00, 0.00, 0, ''),
(881, 101, 143, 0.00, 1055090890.00, 0, ''),
(882, 101, 144, 0.00, 63644301.00, 0, ''),
(883, 101, 145, 0.00, 9352100.00, 0, ''),
(884, 101, 146, 0.00, 21711000.00, 0, ''),
(885, 101, 147, 0.00, 36885335.00, 0, ''),
(886, 101, 148, 0.00, 337545075.00, 0, ''),
(887, 101, 149, 0.00, 0.00, 0, ''),
(888, 101, 150, 0.00, 0.00, 0, ''),
(889, 101, 151, 0.00, 0.00, 0, ''),
(890, 101, 152, 0.00, 0.00, 0, ''),
(891, 101, 154, 0.00, 0.00, 0, ''),
(892, 101, 155, 0.00, 0.00, 0, ''),
(893, 101, 156, 0.00, 0.00, 0, ''),
(894, 101, 157, 0.00, 0.00, 0, ''),
(895, 101, 158, 0.00, 0.00, 0, ''),
(896, 101, 159, 0.00, 877016.59, 0, ''),
(897, 101, 161, 0.00, 0.00, 0, ''),
(898, 101, 162, 0.00, 0.00, 0, ''),
(899, 101, 163, 0.00, 0.00, 0, ''),
(900, 101, 164, 0.00, 0.00, 0, ''),
(901, 101, 166, 0.00, 0.00, 0, ''),
(902, 101, 167, 0.00, 0.00, 0, ''),
(903, 101, 168, 0.00, 0.00, 0, ''),
(904, 101, 169, 0.00, 0.00, 0, ''),
(905, 101, 170, 0.00, 0.00, 0, ''),
(906, 101, 171, 0.00, 0.00, 0, ''),
(907, 101, 173, 0.00, 0.00, 0, ''),
(908, 101, 174, 0.00, 0.00, 0, ''),
(909, 101, 175, 0.00, 4275173.97, 0, ''),
(910, 101, 85, 0.00, 0.00, 0, ''),
(911, 101, 86, 0.00, 0.00, 0, ''),
(912, 101, 87, 0.00, 0.00, 0, ''),
(913, 101, 89, 24174965.00, 0.00, 0, ''),
(914, 101, 90, 0.00, 0.00, 0, ''),
(915, 101, 91, 0.00, 0.00, 0, ''),
(916, 101, 92, 342487129.00, 0.00, 0, ''),
(917, 101, 93, 146149113.00, 0.00, 0, ''),
(918, 101, 94, 0.00, 0.00, 0, ''),
(919, 101, 95, 103000000.00, 0.00, 0, ''),
(920, 101, 96, 0.00, 0.00, 0, ''),
(921, 101, 98, 508850789.00, 0.00, 0, ''),
(922, 101, 99, 83375000.00, 0.00, 0, ''),
(923, 101, 100, 0.00, 0.00, 0, ''),
(924, 101, 101, 3600000.00, 0.00, 0, ''),
(925, 101, 102, 13084934.00, 0.00, 0, ''),
(926, 101, 103, 36527247.00, 0.00, 0, ''),
(927, 101, 104, 13221380.00, 0.00, 0, ''),
(928, 101, 105, 25867650.00, 0.00, 0, ''),
(929, 101, 106, 25867650.00, 0.00, 0, ''),
(930, 101, 107, 0.00, 0.00, 0, ''),
(931, 101, 108, 0.00, 0.00, 0, ''),
(932, 101, 176, 0.00, 0.00, 0, ''),
(933, 101, 110, 21974645.83, 0.00, 0, ''),
(934, 101, 111, 0.00, 0.00, 0, ''),
(935, 101, 112, 0.00, 0.00, 0, ''),
(936, 101, 113, 1075000.00, 0.00, 0, ''),
(937, 101, 114, 0.00, 0.00, 0, ''),
(938, 101, 115, 0.00, 0.00, 0, ''),
(939, 101, 116, 0.00, 0.00, 0, ''),
(940, 101, 117, 0.00, 0.00, 0, ''),
(941, 101, 118, 23277083.00, 0.00, 0, ''),
(942, 101, 119, 1145800.00, 0.00, 0, ''),
(943, 101, 120, 0.00, 0.00, 0, ''),
(944, 101, 121, 0.00, 0.00, 0, ''),
(945, 101, 122, 2386000.00, 0.00, 0, ''),
(946, 101, 123, 1643500.00, 0.00, 0, ''),
(947, 101, 124, 0.00, 0.00, 0, ''),
(948, 101, 125, 6814288.00, 0.00, 0, ''),
(949, 101, 126, 1485533.50, 0.00, 0, ''),
(950, 101, 127, 8333800.00, 0.00, 0, ''),
(951, 101, 128, 0.00, 0.00, 0, ''),
(952, 101, 129, 1624000.00, 0.00, 0, ''),
(953, 101, 130, 0.00, 0.00, 0, ''),
(954, 101, 131, 4950000.00, 0.00, 0, ''),
(955, 101, 132, 2605612.00, 0.00, 0, ''),
(956, 101, 133, 23435565.92, 0.00, 0, ''),
(957, 101, 135, 10000000.00, 0.00, 0, ''),
(958, 101, 136, 1392300.00, 0.00, 0, ''),
(959, 101, 137, 0.00, 0.00, 0, ''),
(960, 101, 138, 0.00, 0.00, 0, ''),
(961, 101, 139, 7114500.00, 0.00, 0, ''),
(962, 101, 141, 16783481.00, 0.00, 0, ''),
(1019, 134, 143, 0.00, 1122065569.00, 0, ''),
(1020, 134, 144, 0.00, 230696030.64, 0, ''),
(1021, 134, 145, 0.00, 0.00, 0, ''),
(1022, 134, 146, 0.00, 0.00, 0, ''),
(1023, 134, 147, 0.00, 85393150.00, 0, ''),
(1024, 134, 148, 0.00, 381782275.00, 0, ''),
(1025, 134, 149, 0.00, 9458399.00, 0, ''),
(1026, 134, 150, 0.00, 0.00, 0, ''),
(1027, 134, 151, 0.00, 48284880.00, 0, ''),
(1028, 134, 152, 0.00, 0.00, 0, ''),
(1029, 134, 154, 0.00, 0.00, 0, ''),
(1030, 134, 155, 0.00, 0.00, 0, ''),
(1031, 134, 156, 0.00, 0.00, 0, ''),
(1032, 134, 157, 0.00, 0.00, 0, ''),
(1033, 134, 158, 0.00, 0.00, 0, ''),
(1034, 134, 159, 0.00, 1469820.00, 0, ''),
(1035, 134, 161, 0.00, 0.00, 0, ''),
(1036, 134, 162, 0.00, 0.00, 0, ''),
(1037, 134, 163, 0.00, 0.00, 0, ''),
(1038, 134, 164, 0.00, 0.00, 0, ''),
(1039, 134, 166, 0.00, 0.00, 0, ''),
(1040, 134, 167, 0.00, 0.00, 0, ''),
(1041, 134, 168, 0.00, 0.00, 0, ''),
(1042, 134, 169, 0.00, 0.00, 0, ''),
(1043, 134, 170, 0.00, 0.00, 0, ''),
(1044, 134, 171, 0.00, 0.00, 0, ''),
(1045, 134, 173, 0.00, 0.00, 0, ''),
(1046, 134, 174, 0.00, 0.00, 0, ''),
(1047, 134, 175, 0.00, 0.00, 0, ''),
(1048, 134, 85, 0.00, 0.00, 0, ''),
(1049, 134, 86, 0.00, 0.00, 0, ''),
(1050, 134, 87, 0.00, 0.00, 0, ''),
(1051, 134, 89, 51443157.00, 0.00, 0, ''),
(1052, 134, 90, 0.00, 0.00, 0, ''),
(1053, 134, 91, 52154750.00, 0.00, 0, ''),
(1054, 134, 92, 412660556.00, 0.00, 0, ''),
(1055, 134, 93, 219269111.00, 0.00, 0, ''),
(1056, 134, 94, 0.00, 0.00, 0, ''),
(1057, 134, 95, 100000000.00, 0.00, 0, ''),
(1058, 134, 96, 0.00, 0.00, 0, ''),
(1059, 134, 98, 522995000.00, 0.00, 0, ''),
(1060, 134, 99, 86225000.00, 0.00, 0, ''),
(1061, 134, 100, 0.00, 0.00, 0, ''),
(1062, 134, 101, 3600000.00, 0.00, 0, ''),
(1063, 134, 102, 11573662.00, 0.00, 0, ''),
(1064, 134, 103, 35735841.00, 0.00, 0, ''),
(1065, 134, 104, 11637405.00, 0.00, 0, ''),
(1066, 134, 105, 0.00, 0.00, 0, ''),
(1067, 134, 106, 71735300.00, 0.00, 0, ''),
(1068, 134, 107, 30000000.00, 0.00, 0, ''),
(1069, 134, 108, 0.00, 0.00, 0, ''),
(1070, 134, 176, 0.00, 0.00, 0, ''),
(1071, 134, 110, 21602250.00, 0.00, 0, ''),
(1072, 134, 111, 0.00, 0.00, 0, ''),
(1073, 134, 112, 0.00, 0.00, 0, ''),
(1074, 134, 113, 2547000.00, 0.00, 0, ''),
(1075, 134, 114, 0.00, 0.00, 0, ''),
(1076, 134, 115, 0.00, 0.00, 0, ''),
(1077, 134, 116, 0.00, 0.00, 0, ''),
(1078, 134, 117, 0.00, 0.00, 0, ''),
(1079, 134, 118, 23277083.00, 0.00, 0, ''),
(1080, 134, 119, 940000.00, 0.00, 0, ''),
(1081, 134, 120, 0.00, 0.00, 0, ''),
(1082, 134, 121, 0.00, 0.00, 0, ''),
(1083, 134, 122, 2029000.00, 0.00, 0, ''),
(1084, 134, 123, 2996644.00, 0.00, 0, ''),
(1085, 134, 124, 0.00, 0.00, 0, ''),
(1086, 134, 125, 43415292.00, 0.00, 0, ''),
(1087, 134, 126, 632017.69, 0.00, 0, ''),
(1088, 134, 127, 3874600.00, 0.00, 0, ''),
(1089, 134, 128, 0.00, 0.00, 0, ''),
(1090, 134, 129, 2932500.00, 0.00, 0, ''),
(1091, 134, 130, 0.00, 0.00, 0, ''),
(1092, 134, 131, 0.00, 0.00, 0, ''),
(1093, 134, 132, 4375194.00, 0.00, 0, ''),
(1094, 134, 133, 21490923.90, 0.00, 0, ''),
(1095, 134, 135, 10000000.00, 0.00, 0, ''),
(1096, 134, 136, 4000000.00, 0.00, 0, ''),
(1097, 134, 137, 0.00, 0.00, 0, ''),
(1098, 134, 138, 0.00, 0.00, 0, ''),
(1099, 134, 139, 14561000.00, 0.00, 0, ''),
(1100, 134, 141, 22289367.00, 0.00, 0, ''),
(1102, 138, 79, 0.00, 78119424.79, 0, 'PEMINDAH BUKUAN'),
(1103, 139, 79, 0.00, 345134928.00, 0, 'PERHITUNGAN LABA/RUGI 12 2020'),
(1167, 147, 11, 0.00, 286186225.66, 0, ''),
(1168, 147, 6, 42033445.18, 0.00, 0, ''),
(1169, 147, 7, 1270946.33, 0.00, 0, ''),
(1170, 147, 9, 0.00, 393096491.99, 0, ''),
(1171, 147, 4, 0.00, 158402750.69, 0, ''),
(1172, 147, 5, 0.00, 555393596.56, 0, ''),
(1173, 147, 177, 900000000.00, 0.00, 0, ''),
(1174, 147, 15, 222481149.00, 0.00, 0, ''),
(1175, 147, 19, 399624988.00, 0.00, 0, ''),
(1176, 147, 17, 0.00, 31120253.49, 0, ''),
(1177, 147, 27, 0.00, 281500.00, 0, ''),
(1178, 147, 21, 23256902.00, 0.00, 0, ''),
(1179, 147, 31, 30872772.00, 0.00, 0, ''),
(1180, 147, 34, 0.00, 22378708.33, 0, ''),
(1181, 147, 180, 4083288.00, 0.00, 0, ''),
(1182, 147, 30, 0.00, 24527083.00, 0, ''),
(1183, 147, 66, 247890171.00, 0.00, 0, ''),
(1184, 147, 63, 0.00, 43112750.00, 0, ''),
(1185, 147, 68, 0.00, 10000000.00, 0, ''),
(1186, 147, 52, 0.00, 123029852.00, 0, ''),
(1187, 147, 47, 2605611.00, 0.00, 0, ''),
(1188, 147, 48, 0.00, 17785558.00, 0, ''),
(1189, 147, 181, 0.00, 20416438.00, 0, ''),
(1190, 147, 67, 0.00, 93395000.00, 0, ''),
(1191, 147, 70, 0.00, 5200000.00, 0, ''),
(1192, 147, 71, 0.00, 600000.00, 0, ''),
(1193, 147, 143, 0.00, 1065216719.00, 0, ''),
(1194, 147, 144, 0.00, 61635462.00, 0, ''),
(1195, 147, 145, 0.00, 9129000.00, 0, ''),
(1196, 147, 146, 0.00, 21785000.00, 0, ''),
(1197, 147, 147, 0.00, 5213575.23, 0, ''),
(1198, 147, 148, 0.00, 38374350.00, 0, ''),
(1199, 147, 175, 0.00, 3467959.68, 0, ''),
(1200, 147, 89, 8707043.00, 0.00, 0, ''),
(1201, 147, 92, 47854215.00, 0.00, 0, ''),
(1202, 147, 182, 8348250.00, 0.00, 0, ''),
(1203, 147, 93, 155076602.00, 0.00, 0, ''),
(1204, 147, 95, 100000000.00, 0.00, 0, ''),
(1205, 147, 98, 490955000.00, 0.00, 0, ''),
(1206, 147, 99, 78475000.00, 0.00, 0, ''),
(1207, 147, 101, 3600000.00, 0.00, 0, ''),
(1208, 147, 102, 10620022.00, 0.00, 0, ''),
(1209, 147, 103, 36527247.00, 0.00, 0, ''),
(1210, 147, 104, 8500000.00, 0.00, 0, ''),
(1211, 147, 106, 43112750.00, 0.00, 0, ''),
(1212, 147, 108, 1900000.00, 0.00, 0, ''),
(1213, 147, 110, 22378708.33, 0.00, 0, ''),
(1214, 147, 113, 300000.00, 0.00, 0, ''),
(1215, 147, 118, 24527083.00, 0.00, 0, ''),
(1216, 147, 119, 621100.00, 0.00, 0, ''),
(1217, 147, 122, 5487000.00, 0.00, 0, ''),
(1218, 147, 123, 5806988.00, 0.00, 0, ''),
(1219, 147, 125, 8036473.00, 0.00, 0, ''),
(1220, 147, 126, 2363591.79, 0.00, 0, ''),
(1221, 147, 127, 2390100.00, 0.00, 0, ''),
(1222, 147, 129, 1231500.00, 0.00, 0, ''),
(1223, 147, 131, 3586000.00, 0.00, 0, ''),
(1224, 147, 132, 2605612.00, 0.00, 0, ''),
(1225, 147, 133, 9203700.00, 0.00, 0, ''),
(1226, 147, 135, 10000000.00, 0.00, 0, ''),
(1227, 147, 136, 12619000.00, 0.00, 0, ''),
(1228, 147, 139, 2339800.00, 0.00, 0, ''),
(1229, 147, 141, 19529856.00, 0.00, 0, ''),
(1230, 151, 11, 202154292.38, 0.00, 0, ''),
(1231, 151, 6, 0.00, 42163816.43, 0, ''),
(1232, 151, 7, 103442045.78, 0.00, 0, ''),
(1233, 151, 9, 0.00, 19518422.93, 0, ''),
(1234, 151, 4, 152770271.48, 0.00, 0, ''),
(1235, 151, 5, 0.00, 21084.64, 0, ''),
(1236, 151, 15, 0.00, 287659941.00, 0, ''),
(1237, 151, 19, 249383325.00, 0.00, 0, ''),
(1238, 151, 17, 116958500.00, 0.00, 0, ''),
(1239, 151, 27, 8000000.00, 0.00, 0, ''),
(1240, 151, 21, 0.00, 18483098.00, 0, ''),
(1241, 151, 31, 30872772.00, 0.00, 0, ''),
(1242, 151, 34, 0.00, 22378708.33, 0, ''),
(1243, 151, 33, 3400000.00, 0.00, 0, ''),
(1244, 151, 180, 0.00, 1361096.00, 0, ''),
(1245, 151, 30, 0.00, 24527083.00, 0, ''),
(1246, 151, 66, 0.00, 33247420.00, 0, ''),
(1247, 151, 64, 0.00, 30000000.00, 0, ''),
(1248, 151, 63, 0.00, 94848050.00, 0, ''),
(1249, 151, 67, 0.00, 61282000.00, 0, ''),
(1250, 151, 68, 0.00, 35000000.00, 0, ''),
(1251, 151, 52, 39720952.00, 0.00, 0, ''),
(1252, 151, 48, 0.00, 25165071.00, 0, ''),
(1253, 151, 58, 0.00, 225000000.00, 0, ''),
(1254, 151, 47, 2605610.00, 0.00, 0, ''),
(1255, 151, 181, 6805479.00, 0.00, 0, ''),
(1256, 151, 70, 0.00, 3800000.00, 0, ''),
(1257, 151, 71, 0.00, 840000.00, 0, ''),
(1258, 151, 143, 0.00, 1076721923.00, 0, ''),
(1259, 151, 144, 0.00, 172757988.00, 0, ''),
(1260, 151, 145, 0.00, 12149032.00, 0, ''),
(1261, 151, 146, 0.00, 13391000.00, 0, ''),
(1262, 151, 147, 0.00, 1210450.00, 0, ''),
(1263, 151, 148, 0.00, 20305600.00, 0, ''),
(1264, 151, 175, 0.00, 8821048.18, 0, ''),
(1265, 151, 87, 219178.00, 0.00, 0, ''),
(1266, 151, 89, 18250547.00, 0.00, 0, ''),
(1267, 151, 92, 33474904.00, 0.00, 0, ''),
(1268, 151, 93, 171644168.00, 0.00, 0, ''),
(1269, 151, 95, 100000000.00, 0.00, 0, ''),
(1270, 151, 98, 485235000.00, 0.00, 0, ''),
(1271, 151, 99, 73975000.00, 0.00, 0, ''),
(1272, 151, 101, 3600000.00, 0.00, 0, ''),
(1273, 151, 102, 12905494.00, 0.00, 0, ''),
(1274, 151, 103, 37170687.00, 0.00, 0, ''),
(1275, 151, 104, 10986273.00, 0.00, 0, ''),
(1276, 151, 106, 119848050.00, 0.00, 0, ''),
(1277, 151, 107, 30000000.00, 0.00, 0, ''),
(1278, 151, 110, 22378708.33, 0.00, 0, ''),
(1279, 151, 113, 806000.00, 0.00, 0, ''),
(1280, 151, 118, 24527083.00, 0.00, 0, ''),
(1281, 151, 119, 724500.00, 0.00, 0, ''),
(1282, 151, 122, 1772000.00, 0.00, 0, ''),
(1283, 151, 123, 1505420.00, 0.00, 0, ''),
(1284, 151, 125, 3037500.00, 0.00, 0, ''),
(1285, 151, 126, 1824207.54, 0.00, 0, ''),
(1286, 151, 127, 5648000.00, 0.00, 0, ''),
(1287, 151, 129, 1190500.00, 0.00, 0, ''),
(1288, 151, 132, 2605610.00, 0.00, 0, ''),
(1289, 151, 133, 9702853.00, 0.00, 0, ''),
(1290, 151, 135, 10000000.00, 0.00, 0, ''),
(1291, 151, 139, 1500000.00, 0.00, 0, ''),
(1292, 151, 141, 24165071.00, 0.00, 0, ''),
(1293, 155, 11, 0.00, 316581124.51, 0, ''),
(1294, 155, 6, 0.00, 57983.71, 0, ''),
(1295, 155, 7, 78090454.13, 0.00, 0, ''),
(1296, 155, 9, 0.00, 178871519.21, 0, ''),
(1297, 155, 4, 0.00, 64020477.52, 0, ''),
(1298, 155, 5, 337754708.52, 0.00, 0, ''),
(1299, 155, 15, 236678324.03, 0.00, 0, ''),
(1300, 155, 178, 414224503.00, 0.00, 0, ''),
(1301, 155, 19, 183349991.00, 0.00, 0, ''),
(1302, 155, 17, 0.00, 182682609.00, 0, ''),
(1303, 155, 21, 0.00, 31649765.00, 0, ''),
(1304, 155, 31, 30872772.00, 0.00, 0, ''),
(1305, 155, 34, 0.00, 22449541.67, 0, ''),
(1306, 155, 180, 0.00, 1361096.00, 0, ''),
(1307, 155, 30, 0.00, 23527083.00, 0, ''),
(1308, 155, 63, 0.00, 61112750.00, 0, ''),
(1309, 155, 52, 0.00, 106603420.00, 0, ''),
(1310, 155, 48, 0.00, 18376917.00, 0, ''),
(1311, 155, 47, 1954209.00, 0.00, 0, ''),
(1312, 155, 181, 6805479.00, 0.00, 0, ''),
(1313, 155, 70, 0.00, 3000000.00, 0, ''),
(1314, 155, 71, 0.00, 1300000.00, 0, ''),
(1315, 155, 143, 0.00, 1045647889.00, 0, ''),
(1316, 155, 144, 0.00, 28329768.00, 0, ''),
(1317, 155, 145, 0.00, 19934700.00, 0, ''),
(1318, 155, 146, 0.00, 12708000.00, 0, ''),
(1319, 155, 183, 0.00, 13943219.00, 0, ''),
(1320, 155, 184, 0.00, 2102000.00, 0, ''),
(1321, 155, 185, 0.00, 2309104.00, 0, ''),
(1322, 155, 186, 0.00, 14876000.00, 0, ''),
(1323, 155, 147, 0.00, 1139724.00, 0, ''),
(1324, 155, 148, 0.00, 107425150.00, 0, ''),
(1325, 155, 175, 0.00, 9146495.62, 0, ''),
(1326, 155, 87, 1528767.00, 0.00, 0, ''),
(1327, 155, 89, 24444247.00, 0.00, 0, ''),
(1328, 155, 92, 115236520.00, 0.00, 0, ''),
(1329, 155, 93, 107452881.97, 0.00, 0, ''),
(1330, 155, 95, 83000000.00, 0.00, 0, ''),
(1331, 155, 98, 480665000.00, 0.00, 0, ''),
(1332, 155, 99, 76000000.00, 0.00, 0, ''),
(1333, 155, 101, 3600000.00, 0.00, 0, ''),
(1334, 155, 102, 12969311.00, 0.00, 0, ''),
(1335, 155, 103, 34010431.00, 0.00, 0, ''),
(1336, 155, 104, 7553427.00, 0.00, 0, ''),
(1337, 155, 106, 61112750.00, 0.00, 0, ''),
(1338, 155, 110, 22449541.67, 0.00, 0, ''),
(1339, 155, 113, 1080000.00, 0.00, 0, ''),
(1340, 155, 118, 23527083.00, 0.00, 0, ''),
(1341, 155, 119, 703000.00, 0.00, 0, ''),
(1342, 155, 122, 2966500.00, 0.00, 0, ''),
(1343, 155, 123, 4293700.00, 0.00, 0, ''),
(1344, 155, 125, 6292600.00, 0.00, 0, ''),
(1345, 155, 126, 5529295.92, 0.00, 0, ''),
(1346, 155, 127, 4306450.00, 0.00, 0, ''),
(1347, 155, 129, 1484500.00, 0.00, 0, ''),
(1348, 155, 131, 228600.00, 0.00, 0, ''),
(1349, 155, 132, 1954209.00, 0.00, 0, ''),
(1350, 155, 133, 55768150.00, 0.00, 0, ''),
(1351, 155, 135, 10000000.00, 0.00, 0, ''),
(1352, 155, 136, 720000.00, 0.00, 0, ''),
(1353, 155, 139, 4300500.00, 0.00, 0, ''),
(1354, 155, 141, 20876917.00, 0.00, 0, ''),
(1356, 147, 52, 0.00, 11073640.00, 0, ''),
(1357, 151, 52, 148008800.00, 0.00, 0, ''),
(1358, 151, 67, 0.00, 42165969.00, 0, ''),
(1359, 155, 52, 43375871.00, 0.00, 0, ''),
(1360, 155, 66, 0.00, 150000000.00, 0, ''),
(1361, 155, 67, 0.00, 38599357.00, 0, ''),
(1362, 155, 67, 0.00, 39405000.00, 0, ''),
(1363, 155, 68, 0.00, 10000000.00, 0, ''),
(1364, 156, 79, 0.00, 96660287.31, 0, 'PERHITUNGAN LABA/RUGI 8 2020'),
(1365, 157, 79, 0.00, 83507668.06, 0, 'PERHITUNGAN LABA/RUGI 9 2020'),
(1366, 158, 123, 55600.00, 0.00, 38, 'BY LISTRIK PONTIANAK'),
(1367, 158, 127, 43500.00, 0.00, 38, 'BY ATK PONTIANAK'),
(1368, 158, 133, 77700.00, 0.00, 38, 'BY KIRIM BERKAS DAN KEBUTUHAN KANTOR PONTIANAK'),
(1369, 158, 4, 0.00, 176800.00, 38, 'BY OPR CAB PONTIANAK'),
(1371, 159, 133, 119125.00, 0.00, 7, 'BY PRINT DAN FC CAB BEKASI'),
(1372, 159, 127, 64000.00, 0.00, 7, 'BY ATK CAB BEKASI'),
(1373, 159, 133, 43000.00, 0.00, 7, 'BY OPR CAB BEKASI'),
(1374, 159, 4, 0.00, 226125.00, 7, 'BY OPR CAB BEKASI'),
(1375, 160, 133, 100000.00, 0.00, 1, 'BY KIRIM BERKAS CAB ACEH'),
(1376, 160, 4, 0.00, 100000.00, 1, 'BY OPR CAB ACEH'),
(1378, 161, 125, 200000.00, 0.00, 33, 'BY INTERNET CAB PALEMBANG'),
(1381, 161, 129, 84000.00, 0.00, 33, 'BY MATERAI CAB PALEMBANG'),
(1382, 161, 133, 71000.00, 0.00, 33, 'BY KIRIM DOKUMEN CAB PALEMBANG'),
(1383, 161, 4, 0.00, 355000.00, 33, 'BY OPR CAB PALEMBANG'),
(1384, 162, 125, 282500.00, 0.00, 40, 'BY INTERNET CAB PURWOKERTO'),
(1385, 162, 129, 60000.00, 0.00, 40, 'BY MATERAI CAB PURWOKERTO'),
(1386, 162, 123, 53000.00, 0.00, 40, 'BY LISTRIK CAB PURWOKERTO'),
(1387, 162, 133, 31000.00, 0.00, 40, 'BY KIRIM BERKAS CAB PURWOKERTO'),
(1388, 162, 4, 0.00, 426500.00, 40, 'BY OPR CAB PURWOKERTO'),
(1389, 163, 133, 58000.00, 0.00, 48, 'BY KIRIM BERKAS CAB SORONG'),
(1390, 163, 4, 0.00, 58000.00, 48, 'BY OPR CAB SORONG'),
(1391, 164, 125, 300000.00, 0.00, 35, 'BY INTERNET CAB PAMEKASAN'),
(1392, 164, 133, 36000.00, 0.00, 35, 'BY KIRIM BERKAS CAB PAMEKASAN'),
(1393, 164, 4, 0.00, 336000.00, 35, 'BY OPR CAB PAMEKASAN'),
(1394, 165, 127, 430000.00, 0.00, 13, 'BY ATK CAB CIREBON'),
(1395, 165, 125, 300000.00, 0.00, 13, 'BY INTERNET CAB CIREBON'),
(1396, 165, 123, 255000.00, 0.00, 13, 'BY LISTRIK CAB CIREBON'),
(1397, 165, 133, 15000.00, 0.00, 13, 'BY KIRIM BERKAS CAB CIREBON'),
(1398, 165, 4, 0.00, 1000000.00, 13, 'BY OPR CAB CIREBON'),
(1399, 166, 6, 18000000.00, 0.00, 53, 'PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMLAYA'),
(1400, 166, 7, 3960000.00, 0.00, 53, 'PREM ASS PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1401, 166, 4, 900000.00, 0.00, 53, 'PEND ADM PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMLAYA'),
(1402, 166, 9, 750000.00, 0.00, 53, 'ANGS POKOK BLN KE 1 XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1403, 166, 4, 342000.00, 0.00, 53, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1404, 166, 9, 200000.00, 0.00, 53, 'SIMP POKOK PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1405, 166, 9, 20000.00, 0.00, 53, 'SIMP WAJIB PINJ XTRA PLAT AN JUARIAH CAB TASIKMALAYA'),
(1406, 166, 4, 18000.00, 0.00, 53, 'PEND MATERAI PINJ XTRA PLAT AN JUARIAH CAB TASIKMALAYA'),
(1407, 166, 6, 0.00, 6190000.00, 53, 'BIAYA PENC PINJ XTRA PLAT AN JUARIAH CAB TASIKMALAYA'),
(1408, 166, 9, 0.00, 18000000.00, 53, 'PENC PINJ XTRA PLAT AN JUARIAH CAB TASIKMALAYA'),
(1410, 167, 108, 1000000.00, 0.00, 24, 'BY PERJALANAN DINAS CAB KUPANG'),
(1411, 167, 4, 0.00, 1000000.00, 24, 'BY PERJALANAN DINAS CAB KUPANG'),
(1412, 168, 27, 235000.00, 0.00, 46, 'PENGAJUAN UMB BY OPR CAB SLEMAN'),
(1413, 168, 4, 0.00, 235000.00, 46, 'PENGAJUAN UMB BY OPR CAB SLEMAN'),
(1414, 169, 89, 300000.00, 0.00, 34, 'FEE FREELANCE CAB PALU'),
(1415, 169, 4, 0.00, 300000.00, 34, 'FEE FREELANCE CAB PALU'),
(1416, 170, 6, 15000000.00, 0.00, 31, 'PENC PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1417, 170, 7, 3000000.00, 0.00, 31, 'PREM ASS PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1418, 170, 9, 1250000.00, 0.00, 31, 'ANGS POKOK BLN KE 1 PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1419, 170, 4, 750000.00, 0.00, 31, 'PEND ADM PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1420, 170, 4, 255000.00, 0.00, 31, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1421, 170, 9, 200000.00, 0.00, 31, 'SIMP POKOK PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1422, 170, 9, 20000.00, 0.00, 31, 'SIMP WAJIB PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1423, 170, 4, 18000.00, 0.00, 31, 'PEND MATERAI PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1424, 170, 6, 0.00, 5493000.00, 31, 'BIAYA PENC PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1425, 170, 9, 0.00, 15000000.00, 31, 'PENC PINJ XTRA PLAT AN FX MARJONO CAB NGAWI'),
(1426, 171, 133, 58000.00, 0.00, 42, 'BY KIRIM BERKAS CAB SELONG'),
(1427, 171, 127, 42500.00, 0.00, 42, 'BY ATK CAB SELONG'),
(1428, 171, 4, 0.00, 100500.00, 42, 'BY OPR CAB SELONG'),
(1429, 172, 133, 350000.00, 0.00, 0, 'FEE MUTASI KERBIS BULAN SEPT 2020'),
(1430, 172, 11, 0.00, 100000.00, 0, 'FEE MUTASI KERBIS BULAN SEPT 2020'),
(1431, 172, 4, 0.00, 250000.00, 0, 'FEE MUTASI KERBIS BULAN SEPT 2020'),
(1432, 173, 133, 76000.00, 0.00, 24, 'BY KIRIM BERKAS CAB KUPANG'),
(1433, 173, 4, 0.00, 76000.00, 24, 'BY OPR CAB KUPANG'),
(1434, 174, 6, 13000000.00, 0.00, 53, 'PENC PINJ XTRA PLAT AN IDA SAMIAH CAB TAIKMALAYA'),
(1435, 174, 7, 2860000.00, 0.00, 53, 'PREM ASS PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1436, 174, 4, 650000.00, 0.00, 53, 'PEND ADM PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1437, 174, 9, 541667.00, 0.00, 53, 'ANGS POKOK BLN KE 1 PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1438, 174, 4, 247000.00, 0.00, 53, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1439, 174, 9, 200000.00, 0.00, 53, 'SIMP POKOK PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1440, 174, 9, 20000.00, 0.00, 53, 'SIMP WAJIB PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1441, 174, 4, 18000.00, 0.00, 53, 'PEND MATERAI PINJ XTRA PLAT AN IDA SAMIAH CAB TASIKMALAYA'),
(1442, 174, 6, 0.00, 4536667.00, 53, ''),
(1443, 174, 9, 0.00, 13000000.00, 53, 'PENC PINJ XTRA PALT AN IDA SAMIAH CAB TASIKMALAYA'),
(1444, 175, 139, 138000.00, 0.00, 5, 'BINGKISAN KE ASABRI CAB BANJARMASIN'),
(1445, 175, 4, 0.00, 138000.00, 5, 'BY OPR CAB BANJARMASIN'),
(1446, 176, 127, 71100.00, 0.00, 39, 'BY ATK CAB PROBOLINGGO'),
(1447, 176, 4, 0.00, 71100.00, 39, 'BY OPR CAB PROBOLINGGO'),
(1448, 177, 125, 300000.00, 0.00, 20, 'BY INTERNET CAB JOMBANG'),
(1449, 177, 129, 18000.00, 0.00, 20, 'BY MATERAI CAB JOMBANG'),
(1450, 177, 133, 16900.00, 0.00, 20, 'BY KEBUTUHAN KANTOR CAB JOMBANG'),
(1451, 177, 4, 0.00, 334900.00, 20, 'BY OPR CAB JOMBANG'),
(1452, 178, 129, 150000.00, 0.00, 14, 'BY MATERAI CAB DENPASAR'),
(1453, 178, 133, 91000.00, 0.00, 14, 'BY KIRIM BERKAS CAB DENPASAR'),
(1454, 178, 127, 7500.00, 0.00, 14, 'BY ATK CAB DENPASAR'),
(1455, 178, 52, 0.00, 49000.00, 14, 'KRG TRF BY OPR CAB DENPASAR'),
(1456, 178, 4, 0.00, 199500.00, 14, 'BY OPR CAB DENPASAR'),
(1457, 179, 6, 17800000.00, 0.00, 0, 'PENC PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1458, 179, 7, 3916000.00, 0.00, 18, 'PREM ASS PINJ XTRA PLAT AN M BR NAPITULU CAB JAMBI'),
(1459, 179, 4, 890000.00, 0.00, 18, 'PEND ADM PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1460, 179, 9, 741667.00, 0.00, 18, 'ANGS POKOK BLN KE 1 PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1461, 179, 4, 338200.00, 0.00, 18, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1462, 179, 9, 200000.00, 0.00, 18, 'SIMP POKOK PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1463, 179, 9, 20000.00, 0.00, 18, 'SIMP WAJIB PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1464, 179, 4, 18000.00, 0.00, 18, 'PEND MATERAI PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1465, 179, 6, 0.00, 6123867.00, 18, 'BY PENC PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1466, 179, 9, 0.00, 17800000.00, 18, 'PENC PINJ XTRA PLAT AN M BR NAPITUPULU CAB JAMBI'),
(1467, 180, 68, 521360.00, 0.00, 3, 'BY FLAGGING DEB CAB ATAMBUA'),
(1468, 180, 4, 0.00, 521360.00, 3, 'BY FLAGGING DEB CAB ATAMBUA'),
(1469, 181, 125, 102000.00, 0.00, 31, 'BY INTERNET CAB MADIUN'),
(1470, 181, 129, 65000.00, 0.00, 31, 'BY MATERAI CAB MADIUN'),
(1471, 181, 127, 43000.00, 0.00, 31, 'BY ATK CAB MADIUN'),
(1472, 181, 133, 36000.00, 0.00, 31, 'BY KIRIM BERKAS CAB MADIUN'),
(1473, 181, 4, 0.00, 246000.00, 31, 'BY OPR CAB MADIUN'),
(1474, 182, 6, 20000000.00, 0.00, 31, 'PENC PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1475, 182, 7, 4400000.00, 0.00, 31, 'PREM ASS PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1476, 182, 4, 1000000.00, 0.00, 31, 'PEND ADM PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1477, 182, 9, 833333.00, 0.00, 31, 'ANGS POKOK BLN KE 1 PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1478, 182, 9, 833333.00, 0.00, 31, 'ANGS POKOK BLN KE 2 PINJ XTRA PLAT CAB NGAWI'),
(1479, 182, 4, 380000.00, 0.00, 31, 'ANG BUNGA BLN KE 1 PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1480, 182, 4, 380000.00, 0.00, 31, 'ANGS BUNGA BLN KE 2 PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1481, 182, 9, 200000.00, 0.00, 31, 'SIMP POKOK PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1482, 182, 9, 40000.00, 0.00, 31, 'SIMP WAJIB PINJ XTRA PLAT AN SUBIYANTI'),
(1483, 182, 4, 18000.00, 0.00, 31, 'PEND MATERAI PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1484, 182, 6, 0.00, 8084666.00, 31, 'BIAYA PENC PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1485, 182, 9, 0.00, 20000000.00, 31, 'PENC PINJ XTRA PLAT AN SUBIYANTI CAB NGAWI'),
(1486, 183, 122, 285000.00, 0.00, 52, 'BY TRANSPORTASI CAB TANJUNG PINANG'),
(1487, 183, 4, 0.00, 285000.00, 52, 'BY OPR CAB TANJUNG PINANG'),
(1488, 184, 6, 15000000.00, 0.00, 45, 'PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1489, 184, 7, 3300000.00, 0.00, 45, 'PREM ASS XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1490, 184, 4, 750000.00, 0.00, 45, 'PEND ADM XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1491, 184, 9, 625000.00, 0.00, 45, 'ANGS POKOK BLN KE 1 XTRA PLATINUM'),
(1492, 184, 4, 285000.00, 0.00, 45, 'ANGS BUNGA BLN KE 1 XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1493, 184, 9, 200000.00, 0.00, 45, 'SIMP POKOK XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1494, 184, 9, 20000.00, 0.00, 45, 'SIMP WAJIB XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1495, 184, 4, 18000.00, 0.00, 45, 'PEND MATERAI XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1496, 184, 6, 0.00, 5198000.00, 45, 'BIAYA PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1497, 184, 9, 0.00, 15000000.00, 45, 'PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1498, 185, 6, 20000000.00, 0.00, 35, 'PENC PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1499, 185, 7, 4400000.00, 0.00, 35, 'PREM ASS PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1500, 185, 4, 1000000.00, 0.00, 35, 'PEND ADM PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1501, 185, 9, 833333.00, 0.00, 35, 'ANGS POKOK BLN KE 1 PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1502, 185, 4, 380000.00, 0.00, 35, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1503, 185, 9, 200000.00, 0.00, 35, 'SIMP POKOK PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1504, 185, 9, 20000.00, 0.00, 35, 'SIMP WAJIB PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1505, 185, 4, 18000.00, 0.00, 35, 'PEND MATERAI PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1506, 185, 6, 0.00, 6851333.00, 35, 'BIAYA PENC PINJ XTRA PLAT AN M FADAL CAB PAMEKASAN'),
(1507, 185, 9, 0.00, 20000000.00, 35, 'PENC PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1508, 186, 133, 413000.00, 0.00, 52, 'BY KEBUTUHAN KANTOR CAB TANJUNG PINANG'),
(1509, 186, 123, 250000.00, 0.00, 52, 'BY LISTRIK CAB TANJUNG PINANG'),
(1510, 186, 127, 160000.00, 0.00, 52, 'BY ATK CAB TANJUNG PINANG'),
(1511, 186, 125, 150000.00, 0.00, 52, 'BY INTERNET CAB TANJUNG PINANG'),
(1512, 186, 122, 100000.00, 0.00, 52, 'BY TRANSPORTASI CAB TANJUNG PINANG'),
(1513, 186, 4, 0.00, 1073000.00, 52, 'BY OPR CAB TANJUNG PINANG'),
(1514, 187, 125, 300000.00, 0.00, 38, 'BY INTERNET CAB PONTIANAK'),
(1515, 187, 4, 0.00, 300000.00, 38, 'BY OPR CAB PONTIANAK'),
(1516, 188, 132, 1302805.00, 0.00, 0, 'PEMBAYARAN LEASING LAPTOP BLN OKTOBER 2020'),
(1517, 188, 47, 1302805.00, 0.00, 0, 'PEMABAYARAN LEASING LAPTOP BLN OKT 2020'),
(1518, 188, 4, 0.00, 2605610.00, 0, 'PEMBAYARAN LEASING LAPTOP BLN OKT 2020'),
(1519, 189, 6, 20000000.00, 0.00, 21, 'PENC PINJ XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1520, 189, 7, 4000000.00, 0.00, 21, 'PREM ASS XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI');
INSERT INTO `journal_voucher_det` (`journal_voucher_detid`, `journal_voucher_id`, `jns_akun_id`, `debit`, `credit`, `jns_cabangid`, `itemnote`) VALUES
(1521, 189, 9, 1666667.00, 0.00, 21, 'ANGS POKOK BLN KE 1 XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1522, 189, 4, 1000000.00, 0.00, 21, 'PEND ADM XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1523, 189, 4, 340000.00, 0.00, 21, 'ANGS BUNGA BLN KE 1 XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1524, 189, 9, 200000.00, 0.00, 21, 'SIMP POKOK XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1526, 189, 9, 20000.00, 0.00, 21, 'SIMP WAJIB XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1527, 189, 4, 18000.00, 0.00, 21, 'PEND MATERAI XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1528, 189, 6, 0.00, 7244667.00, 21, 'BIAYA PENC PINJ XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1529, 189, 9, 0.00, 20000000.00, 21, 'PENC PINJ XTRA PLAT AN MISIRAN MISWANTO CAB KEDIRI'),
(1530, 190, 15, 1670000.00, 0.00, 0, 'PEMBAYARAN JAHE MERAH TJA'),
(1531, 190, 4, 0.00, 1670000.00, 0, 'PEMBAYARAN JAHE MERAH TJA'),
(1532, 191, 122, 1500000.00, 0.00, 56, 'UANG TRANSPORT DEWAN PENGAWAS RAPAT TGL 1.10.2020'),
(1533, 191, 11, 0.00, 1500000.00, 56, 'UANG TRANSPORT DEWAN PENGAWAS RAPAT TGL 1.10.2020'),
(1534, 192, 30, 50000000.00, 0.00, 57, 'SEWA KANTOR PUSAT MALANG PERIODE NOVEMBER - OKTOBER 2021'),
(1535, 192, 11, 0.00, 50000000.00, 57, 'SEWA KANTOR PUSAT MALANG PERIODE NOVEMBER - OKTOBER 2021'),
(1536, 193, 102, 13373128.00, 0.00, 0, 'BPJS KESEHATAN OKTOBER 2020'),
(1537, 193, 11, 0.00, 13373128.00, 0, 'BPJS KESEHATAN OKTOBER 2020'),
(1538, 194, 139, 1951000.00, 0.00, 0, 'REIMBURSEMENT SWAMITRA TAMBUN'),
(1539, 194, 11, 0.00, 1951000.00, 0, 'REIMBURSEMENT SWAMITRA TAMBUN'),
(1540, 195, 139, 235000.00, 0.00, 0, 'REIMBURSEMENT SWAMITRA MALABAR'),
(1541, 195, 11, 0.00, 235000.00, 0, 'REIMBURSEMENT SWAMITRA MALABAR'),
(1542, 196, 31, 15436386.00, 0.00, 0, 'PEMBAYARAN PPH 25 SEPT 2020'),
(1543, 196, 48, 7000000.00, 0.00, 0, 'PEMBAYARAN PPH 21 SEPT 2020'),
(1544, 196, 11, 0.00, 15436386.00, 0, 'PEMBAYARAN PPH 25 SEPT 2020'),
(1545, 196, 104, 0.00, 306895.00, 0, 'ADJUST PPH 21 SEPT 2020'),
(1546, 196, 11, 0.00, 6693105.00, 0, 'PEMBAYARAN PPH 21 SEPT 2020'),
(1547, 197, 131, 5775000.00, 0.00, 0, 'PEMBAYARAN TERM 2 APLIKASI CORE SISTEM KOPERASI'),
(1548, 197, 11, 0.00, 5775000.00, 0, 'PEMBAYARAN TERM 2 APLIKASI CORE SISTEM KOPERASI'),
(1549, 198, 92, 4436032.00, 0.00, 0, 'FEE TJA SEPTEMBER 2020'),
(1550, 198, 11, 0.00, 4436032.00, 0, 'FEE TJA SEPTEMBER 2020'),
(1551, 199, 52, 780500.00, 0.00, 0, 'TITIPAN PEMBAYARAN SEMBAKO KE TJA'),
(1552, 199, 11, 0.00, 780500.00, 0, 'TITIPAN PEMBAYARAN SEMBAKO KE TJA'),
(1553, 200, 125, 1512166.00, 0.00, 56, 'PEMBAYARAN TAGIHAN TELKOM OKTOBER 2020'),
(1554, 200, 133, 2500.00, 0.00, 56, 'BY TRF PEMBAYARAN TAGIHAN TELKOM OKTOBER 2020'),
(1555, 200, 11, 0.00, 1514666.00, 56, 'PEMBAYARAN TAGIHAN TELKOM OKTOBER 2020'),
(1556, 201, 139, 3135000.00, 0.00, 0, 'JAKARTA WEB HOSTING FAKTUR NO 37769 20.10.20-19.01.21'),
(1557, 201, 11, 0.00, 3135000.00, 0, 'JAKARTA WEB HOSTING FAKTUR NO 37769 20.10.20-19.01.21'),
(1558, 202, 127, 525500.00, 0.00, 0, 'PEMBELIAN ATK GG PUSAT JAKARTA'),
(1559, 202, 11, 0.00, 525500.00, 0, 'PEMBELIAN ATK GG PUSAT JAKARTA'),
(1560, 203, 127, 85200.00, 0.00, 12, 'BY ATK CAB CILEGON'),
(1561, 203, 119, 65000.00, 0.00, 12, 'PEMBELIAN PERLENGKAPAN KANTOR CAB CILEGON'),
(1562, 203, 4, 0.00, 150200.00, 12, 'BY OPR CAB CILEGON'),
(1563, 204, 95, 100000000.00, 0.00, 0, 'PENURUNAN MTT SWAMITRA HI OKT 2020'),
(1564, 204, 4, 0.00, 100000000.00, 0, 'PENURUNAN MTT SWAMITRA HI OKT 2020'),
(1565, 205, 52, 49000.00, 0.00, 14, 'KKRG TRF BY OPR CAB DENPASAR'),
(1566, 205, 4, 0.00, 49000.00, 14, 'KKRG TRF BY OPR CAB DENPASAR'),
(1567, 206, 98, 481473095.00, 0.00, 0, 'PEMBAYARAN GAJI KARYAWAN BULAN OKTOBER 2020'),
(1568, 206, 99, 78575000.00, 0.00, 0, 'PEMBAYARAN GAJI KARYAWAN BULAN OKTOBER 2020'),
(1569, 206, 101, 3600000.00, 0.00, 0, 'PEMBAYARAN GAJI KARYAWAN BULAN OKTOBER 2020'),
(1570, 206, 11, 0.00, 48165500.00, 0, 'PEMBAYARAN GAJI KARYAWAN BULAN OKTOBER 2020'),
(1571, 206, 4, 0.00, 475708095.00, 0, 'PEMBAYARAN GAJI KARYAWAN BULAN OKTOBER 2020'),
(1572, 206, 21, 0.00, 2500000.00, 0, 'Piutang Karyawan An. Jony Nur Efendy'),
(1573, 206, 175, 0.00, 75167.00, 0, 'PEND ADM Piutang Kary An. Tedi Suhendar'),
(1574, 206, 52, 0.00, 3903500.00, 0, 'TJA PEMBELIAN SEMBAKO KARYAWAN OKTOBER 2020'),
(1575, 206, 21, 0.00, 4000000.00, 0, 'Piutang Karyawan An. ARIF GUSTAMAN'),
(1576, 206, 21, 0.00, 3658000.00, 0, 'Piutang Karyawan An. Anggi Andriansyah'),
(1577, 206, 21, 0.00, 7291667.00, 0, 'Piutang Kary An. Muzammil'),
(1578, 206, 21, 0.00, 2000000.00, 0, 'Piutang Karyawan An. WILDAN RIZKY TRISNO'),
(1579, 206, 21, 0.00, 1945000.00, 0, 'Piutang Kary An. I Wayan Andiman'),
(1580, 206, 175, 0.00, 50067.00, 0, 'PEND ADM Piutang Karyawan An. LIDYA OKTAVIANA'),
(1581, 206, 175, 0.00, 55000.00, 0, 'Adm Angsuran Kary An. I Wayan Andiman'),
(1582, 206, 175, 0.00, 50000.00, 0, 'Adm Angsuran Kary An.WILDAN RIZKY TRISNO'),
(1583, 206, 175, 0.00, 50000.00, 0, 'Adm Angsuran Kary An. Baiq Dewi Septiani'),
(1584, 206, 175, 0.00, 50000.00, 0, 'Adm ADM ANGSURAN Piutang Kary An. SLAMET SETYAWAN'),
(1585, 206, 175, 0.00, 75000.00, 0, 'Adm Angsuran Kary An. Lalu Amril'),
(1586, 206, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. ARTHA DHARMA'),
(1587, 206, 21, 0.00, 1500000.00, 0, 'Piutang Kary An. Lalu Amril'),
(1588, 206, 21, 0.00, 333333.00, 0, 'Piutang Kary An. JOKO INDRA BUDI'),
(1589, 206, 175, 0.00, 75000.00, 0, 'Adm Angsuran Kary An. Wan Wahyudi'),
(1590, 206, 21, 0.00, 1333333.00, 0, 'Piutang Kary An. Tedi Suhendar'),
(1591, 206, 21, 0.00, 500000.00, 0, 'Piutang Karyawan An. EBNU UTORO'),
(1592, 206, 21, 0.00, 833333.00, 0, 'Piutang Kary An. SLAMET SETYAWAN'),
(1593, 206, 21, 0.00, 833333.00, 0, 'Piutang Karyawan An. LIDYA OKTAVIANA'),
(1594, 206, 21, 0.00, 833400.00, 0, 'Piutang Karyawan An. MAHARIS'),
(1595, 206, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. YUDI GUNTARA'),
(1596, 206, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. Baiq Dewi Septiani'),
(1597, 206, 21, 0.00, 750000.00, 0, 'Piutang Karyawan An. BAMBANG SUSANTO'),
(1598, 206, 175, 0.00, 50000.00, 0, 'Adm Angsuran Kary An.ARIF GUSTAMAN'),
(1599, 206, 21, 0.00, 583333.00, 0, 'Piutang Karyawan An. I GUSTI NGURAH MADE MURTIKA'),
(1600, 206, 21, 0.00, 583333.00, 0, 'Piutang Karyawan An. UJANG FUJIANA'),
(1601, 206, 175, 0.00, 700000.00, 0, 'Adm Angsuran Kary An.muzammil'),
(1602, 206, 21, 0.00, 700000.00, 0, 'Piutang Karyawan An. Imam Sandi'),
(1603, 206, 175, 0.00, 35000.00, 0, 'PEND ADM Piutang Karyawan An. Imam Sandi'),
(1604, 206, 175, 0.00, 20067.00, 0, 'Adm Angsuran Kary An. JOKO INDRA BUDI'),
(1605, 206, 175, 0.00, 35067.00, 0, 'PEND ADM Piutang Karyawan An. I GUSTI NGURAH MADE MURTIKA'),
(1606, 206, 175, 0.00, 50000.00, 0, 'PEND ADM Piutang Karyawan An. MAHARIS'),
(1607, 206, 175, 0.00, 35067.00, 0, 'PEND ADM Piutang Karyawan An. UJANG FUJIANA'),
(1608, 206, 175, 0.00, 37500.00, 0, 'PEND ADM Piutang Karyawan An. BAMBANG SUSANTO'),
(1609, 206, 21, 0.00, 1250000.00, 0, 'Piutang Karyawan An. Wan Wahyudi'),
(1610, 207, 136, 3000000.00, 0.00, 56, 'Hadiah pernikahan karyawan an Arif GustaMAN'),
(1611, 207, 4, 0.00, 3000000.00, 56, 'Hadiah pernikahan karyawan an Arif GustaMAN'),
(1612, 208, 93, 109191309.00, 0.00, 0, 'TALANGAN ANGSURAN PENSIUNAN BULAN OKTOBER 2020'),
(1613, 208, 4, 0.00, 109191309.00, 0, 'TALANGAN ANGSURAN PENSIUNAN BULAN OKTOBER 2020'),
(1614, 209, 2, 6000000.00, 0.00, 56, 'PENGISIAN KEMBALI KAS KECIL TGL 22 SEPT - 26 OKT 2020'),
(1615, 209, 122, 1083000.00, 0.00, 56, 'BBM, TOL DAN PARIKIR MOBIL OPERASIONAL'),
(1616, 209, 123, 1003000.00, 0.00, 56, 'BY LISTRIK GG PUSAT JKT'),
(1617, 209, 133, 927700.00, 0.00, 56, 'KONSUMSI MEETING GG PUSAT JKT OKT 2020'),
(1618, 209, 139, 600000.00, 0.00, 56, 'KARANGAN BUNGA PAPAN PERNIKAHAN KARYAWAN AN ARIF G'),
(1619, 209, 133, 512300.00, 0.00, 56, 'PEMBELIAN AQUA GALON 23 SEPT - 26 OKT GG PUSAT JKT'),
(1620, 209, 131, 482300.00, 0.00, 56, 'MEMBERSHIP ZOOM SEPT DAN OKT 2020'),
(1621, 209, 129, 300000.00, 0.00, 56, 'PEMBELIAN MATERAI GG PUSAT JKT'),
(1622, 209, 133, 300000.00, 0.00, 56, 'MEETING BUKOPIN S PARMAN'),
(1623, 209, 126, 300000.00, 0.00, 56, 'IURAN KEAMANAN GG PUSAT JKT OKT 2020'),
(1624, 209, 126, 200000.00, 0.00, 56, 'IURAN LINGKUNGAN DAN KEBERSIHAN GG PUSAT JKT OKT 2020'),
(1625, 209, 133, 161000.00, 0.00, 56, 'BIAYA KIRIM DOKUMEN BY GOJEK GG PUSAT JKT'),
(1626, 209, 133, 132000.00, 0.00, 56, 'PENGIRIMAN DOKUMEN VIA JNE 25 SEPT - 23 OKT GG PUSAT JKT'),
(1627, 209, 133, 125300.00, 0.00, 56, 'PEMBELIAN KEBUTUHAN PANTRY GG PUSAT JKT'),
(1628, 209, 139, 35000.00, 0.00, 56, 'BY LAUNDRY GG PUSAT JKT'),
(1629, 209, 4, 0.00, 6161600.00, 56, 'PENGISIAN KEMBALI KAS KECIL TGL 22 SEPT - 26 OKT 2020'),
(1630, 209, 2, 0.00, 6000000.00, 56, 'REIMBURSEMENT KAS KECIL TGL 22 SEPT - 26 OKT 2020'),
(1631, 210, 133, 200000.00, 0.00, 1, 'BY KIRIM BERKAS CAB ACEH'),
(1632, 210, 4, 0.00, 200000.00, 1, 'BY OPR CAB ACEH'),
(1633, 211, 123, 502500.00, 0.00, 17, 'BY LISTRIK CAB JKT 3'),
(1634, 211, 133, 300000.00, 0.00, 17, 'BY KEBERSIHAN CAB JKT 3'),
(1635, 211, 133, 18000.00, 0.00, 17, 'BY KIRIM BERKAS CAB JKT 3'),
(1636, 211, 4, 0.00, 18000.00, 17, 'BY KIRIM BERKAS CAB JKT 3'),
(1637, 211, 4, 0.00, 502500.00, 17, 'BY LISTRIK CAB JKT 3'),
(1638, 211, 4, 0.00, 300000.00, 17, 'BY KEBERSIHAN CAB JKT 3'),
(1639, 212, 127, 480000.00, 0.00, 13, 'BY ATK CAB CIREBON'),
(1640, 212, 125, 300000.00, 0.00, 13, 'BY INTERNET CAB CIREBON'),
(1641, 212, 123, 263000.00, 0.00, 13, 'BY LISTRIK CAB CIREBON'),
(1642, 212, 133, 30000.00, 0.00, 13, 'BY KIRIM BERKAS CAB CIREBON'),
(1643, 212, 4, 0.00, 1073000.00, 13, 'BY OPR CAB CIREBON'),
(1644, 213, 125, 1500000.00, 0.00, 56, 'PULSA OPERASIONAL OKTOBER 2020'),
(1645, 213, 4, 0.00, 1500000.00, 56, 'PULSA OPERASIONAL OKTOBER 2020'),
(1646, 214, 27, 714500.00, 0.00, 3, 'PENGAJUAN UMB BY OPR CAB ATAMBUA'),
(1647, 214, 4, 0.00, 714500.00, 3, 'PENGAJUAN UMB BY OPR CAB ATAMBUA'),
(1648, 215, 127, 177000.00, 0.00, 53, 'BY ATK CAB TASIKMALAYA'),
(1649, 215, 129, 105000.00, 0.00, 53, 'BY MATERAI CAB TASIKMALAYA'),
(1650, 215, 133, 97000.00, 0.00, 53, 'BY PRINT DAN KIRIM BERKAS CAB TASIKMALAYA'),
(1651, 215, 4, 0.00, 379000.00, 53, 'BY OPR CAB TASIKMALAYA'),
(1652, 216, 87, 821918.00, 0.00, 0, 'PEMBAYARAN BUNGA KPD ANGGOTA AN NOFRIZAL'),
(1653, 216, 87, 438356.00, 0.00, 0, 'PEMBAYARAN BUNGA KPD ANGGOTA AN MARWAN'),
(1654, 216, 52, 219178.00, 0.00, 0, 'PEMBAYARAN BUNGA KPD ANGGOTA AN MARWAN'),
(1655, 216, 11, 0.00, 821918.00, 0, 'PEMBAYARAN BUNGA KPD ANGGOTA AN NOFRIZAL'),
(1656, 216, 11, 0.00, 657534.00, 0, 'PEMBAYARAN BUNGA KPD ANGGOTA AN MARWAN'),
(1657, 217, 4, 128000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN. BOBBY'),
(1658, 217, 4, 67500.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN. M FAISAL'),
(1659, 217, 52, 0.00, 67500.00, 0, 'PEMBAYARAN SEMBAKO AN. M FAISAL'),
(1660, 217, 52, 0.00, 128000.00, 0, 'PEMBAYARAN SEMBAKO AN. BOBBY'),
(1661, 218, 93, 1852344.00, 0.00, 0, 'KRS KKR KWJ 06-09 2020 3701314390'),
(1662, 218, 4, 0.00, 1852344.00, 0, 'KRS KKR KWJ 06-09 2020 3701314390'),
(1663, 219, 4, 519000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD'),
(1664, 219, 52, 0.00, 519000.00, 0, 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD'),
(1665, 220, 4, 1033861717.00, 0.00, 0, 'PENDAPATAN BAA OKTOBER 2020'),
(1666, 220, 143, 0.00, 1033861717.00, 0, 'PENDAPATAN BAA OKTOBER 2020'),
(1667, 221, 93, 380000.00, 0.00, 0, 'KRS KWJ 07-08 2020 5263330681'),
(1668, 221, 4, 0.00, 380000.00, 0, 'KRS KWJ 07-08 2020 5263330681'),
(1669, 222, 143, 259963.00, 0.00, 0, 'KOREKSI BAA JULI 2020 5330310951'),
(1670, 223, 4, 66000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO'),
(1671, 222, 4, 0.00, 259963.00, 0, 'KOREKSI BAA JULI 2020 5330310951'),
(1672, 223, 52, 0.00, 66000.00, 0, 'PEMBAYARAN SEMBAKO'),
(1673, 226, 4, 1139723.71, 0.00, 0, 'PINBUK DANA PEND FEE 70 20 SEPT 2020'),
(1674, 226, 6, 0.00, 1139723.71, 0, 'PINBUK DANA PEND FEE 70 20 SEPT 2020'),
(1675, 227, 4, 748600.00, 0.00, 0, 'PEMBAYARAN BPJS KESEHATAN SWAMITRA KRAMATJATI AGS-OKT 2020'),
(1676, 227, 102, 0.00, 748600.00, 0, 'PEMBAYARAN BPJS KESEHATAN SWAMITRA KRAMATJATI AGS-OKT 2020'),
(1677, 228, 4, 567500.00, 0.00, 0, 'PEMBAYARAN SEMBAKO BP EDY PRAMANA'),
(1678, 228, 52, 0.00, 567500.00, 0, 'PEMBAYARAN SEMBAKO BP EDY PRAMANA'),
(1679, 229, 5, 600000000.00, 0.00, 0, 'PINBUK DANA DARI 439 KE REK 431'),
(1680, 229, 4, 0.00, 600000000.00, 0, 'PINBUK DANA DARI 439 KE REK 431'),
(1681, 230, 11, 1670000.00, 0.00, 0, 'PEMBAYARAN JAHE DARI TJA'),
(1682, 230, 15, 0.00, 1670000.00, 0, 'PEMBAYARAN JAHE DARI TJA'),
(1683, 231, 4, 719122.35, 0.00, 0, 'BIAYA ADM, JAGIR DAN PAJAK GIRO 439 OKT 2020'),
(1684, 231, 5, 437077.05, 0.00, 0, 'BIAYA ADM, JAGIR DAN PAJAK GIRO 431 OKT 2020'),
(1685, 231, 126, 188780.58, 0.00, 0, 'BY PAJAK GIRO 439 OKT 2020'),
(1686, 231, 126, 118269.26, 0.00, 0, 'BY PAJAK GIRO 431 OKT 2020'),
(1687, 231, 7, 89716.49, 0.00, 0, 'BIAYA ADM, JAGIR DAN PAJAK GIRO 437 OKT 2020'),
(1688, 231, 133, 60000.00, 0.00, 0, 'BY ADM GIRO 434 OKT 2020'),
(1689, 231, 126, 31429.12, 0.00, 0, 'BY PAJAK GIRO 437 OKT 2020'),
(1690, 231, 133, 30000.00, 0.00, 0, 'BY ADM GIRO 431 OKT 2020'),
(1691, 231, 133, 30000.00, 0.00, 0, 'BY ADM GIRO 439 OKT 2020'),
(1692, 231, 133, 30000.00, 0.00, 0, 'BY ADM GIRO 437 OKT 2020'),
(1693, 231, 129, 6000.00, 0.00, 0, 'BY MATERAI GIRO 431 OKT 2020'),
(1694, 231, 129, 6000.00, 0.00, 0, 'BY MATERAI GIRO 439 OKT 2020'),
(1695, 231, 129, 6000.00, 0.00, 0, 'BY MATERAI GIRO 434 OKT 2020'),
(1696, 231, 129, 6000.00, 0.00, 0, 'BY MATERAI GIRO 437 OKT 2020'),
(1697, 231, 126, 1165.17, 0.00, 0, 'BY PAJAK GIRO 434 OKT 2020'),
(1698, 231, 175, 0.00, 5825.87, 0, 'PEND JAGIR GIRO 434 OKT 2020'),
(1699, 231, 175, 0.00, 943902.93, 0, 'PEND JAGIR GIRO 439 OKT 2020'),
(1700, 231, 175, 0.00, 591346.31, 0, 'PEND JAGIR GIRO 431 OKT 2020'),
(1701, 231, 175, 0.00, 157145.61, 0, 'PEND JAGIR GIRO 437 OKT 2020'),
(1702, 231, 6, 0.00, 61339.30, 0, 'BIAYA ADM, JAGIR DAN PAJAK GIRO 434 OKT 2020'),
(1703, 232, 113, 1354000.00, 0.00, 0, 'BIAYA SERVIS MOBIL OPERASIONAL'),
(1704, 232, 4, 146000.00, 0.00, 0, 'PENGEMBALIAN UMB SERVIS MOBIL OPERASIONAL'),
(1705, 232, 27, 0.00, 1500000.00, 0, 'LAPORAN UMB SERVIS MOBIL OPERASIONAL'),
(1706, 233, 4, 128000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN TENGKU HARRY CAHYADI'),
(1707, 233, 4, 105000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN ABDUL RACHMAN'),
(1708, 233, 52, 0.00, 128000.00, 0, 'PEMBAYARAN SEMBAKO AN TENGKU HARRY CAHYADI'),
(1709, 233, 52, 0.00, 105000.00, 0, 'PEMBAYARAN SEMBAKO AN ABDUL RACHMAN'),
(1710, 234, 123, 405500.00, 0.00, 3, 'BY LISTRIK CAB ATAMBUA'),
(1711, 234, 125, 159000.00, 0.00, 3, 'BY INTERNET CAB ATAMBUA'),
(1712, 234, 126, 150000.00, 0.00, 3, 'BY KEAMANAN CAB ATAMBUA'),
(1713, 234, 27, 0.00, 714500.00, 3, 'PERTANGGUNGJAWABAN UMB BY OPR CAB ATAMBUA'),
(1714, 235, 4, 63760160.00, 0.00, 0, 'PENURUNAN TALANGAN PENS OKTOBER 2020'),
(1715, 235, 93, 0.00, 63760160.00, 0, 'PENURUNAN TALANGAN PENS OKTOBER 2020'),
(1716, 236, 5, 47513100.00, 0.00, 0, 'TITIPAN PELUNASAN'),
(1717, 236, 52, 0.00, 47513100.00, 0, 'TITIPAN PELUNASAN'),
(1722, 246, 9, 100000000.00, 0.00, 0, 'PB DANA DARI 437 KE SIAGA BISNIS'),
(1723, 246, 7, 0.00, 100000000.00, 0, 'PB DANA DARI 437 KE SIAGA BISNIS'),
(1724, 247, 11, 112017.72, 0.00, 0, 'BUNGA DAN BY ADMIN TABUNGAN MANDIRI BULAN OKT 2020'),
(1725, 247, 133, 59100.00, 0.00, 0, 'BY TRANSFER REK MANDIRI OKT 2020'),
(1726, 247, 126, 31129.43, 0.00, 0, 'BY PAJAK TABUNGAN MANDIRI BULAN OKT 2020'),
(1727, 247, 133, 15000.00, 0.00, 0, 'BY ADMIN TABUNGAN SIAGA BISNS BULAN OKT 2020'),
(1728, 247, 9, 14864.07, 0.00, 0, 'BUNGA DAN BY ADMIN TABUNGAN SIAGA BISNIS BULAN OKT 2020'),
(1729, 247, 133, 12500.00, 0.00, 0, 'BY ADMIN TABUNGAN MANDIRI BULAN OKT 2020'),
(1730, 247, 126, 7465.89, 0.00, 0, 'BY PAJAK TABUNGAN SIAGA BISNS BULAN OKT 2020'),
(1731, 247, 11, 0.00, 59100.00, 0, 'BY TRANSFER REK MANDIRI OKT 2020'),
(1732, 247, 175, 0.00, 37329.96, 0, 'BUNGA TABUNGAN SIAGA BISNS BULAN OKT 2020'),
(1733, 247, 175, 0.00, 155647.15, 0, 'BUNGA TABUNGAN MANDIRI BULAN OKT 2020'),
(1734, 248, 52, 3903500.00, 0.00, 0, 'SEMBAKO KARYAWAN GG'),
(1735, 248, 11, 0.00, 3903500.00, 0, 'SEMBAKO KARYAWAN GG'),
(1736, 249, 133, 4800000.00, 0.00, 0, 'PEMBAYARAN CICILAN MOBIL BULAN OKTOBER 2020'),
(1737, 249, 11, 0.00, 4800000.00, 0, 'PEMBAYARAN CICILAN MOBIL BULAN OKTOBER 2020'),
(1738, 250, 118, 23527083.00, 0.00, 0, 'AMORTISASI BDD SEWA OKT 2020'),
(1739, 250, 181, 6805480.00, 0.00, 0, 'AMORTISASI PDD OKT 2020'),
(1740, 250, 126, 1361096.00, 0.00, 0, 'AMORTISASI BDD LAIN OKT 2020'),
(1741, 250, 175, 0.00, 6805480.00, 0, 'AMORTISASI PDD OKT 2020'),
(1742, 250, 30, 0.00, 23527083.00, 0, 'AMORTISASI BDD SEWA OKT 2020'),
(1743, 250, 180, 0.00, 1361096.00, 0, 'AMORTISASI BDD LAIN OKT 2020'),
(1744, 251, 93, 92000000.00, 0.00, 0, 'BY GAGAL KLAIM ASURANSI'),
(1745, 251, 94, 60000000.00, 0.00, 0, 'CAD KERUGIAN PIUTANG OKT 2020'),
(1746, 251, 94, 60000000.00, 0.00, 0, 'CAD PENURUNAN NILAI PINJAMAN XTRA PLATINUM OKT 2020'),
(1747, 251, 95, 56021184.00, 0.00, 0, 'CAD PENGHAPUSAN PIUTANG SWAMITRA OKT 20'),
(1748, 251, 105, 43112750.00, 0.00, 0, 'ACCRUAL THR OKT 2020'),
(1749, 251, 103, 36073843.00, 0.00, 0, 'TUNJANGAN JAMSOSTEK OKT 2020'),
(1750, 251, 135, 10000000.00, 0.00, 0, 'BEBAN RAT OKTOBER 2020'),
(1751, 251, 104, 7000000.00, 0.00, 0, 'ACCRUAL PPH 21 OKT 2020'),
(1752, 251, 63, 0.00, 43112750.00, 0, 'ACCRUAL THR OKT 2020'),
(1753, 251, 68, 0.00, 10000000.00, 0, 'BEBAN RAT OKTOBER 2020'),
(1754, 251, 48, 0.00, 7000000.00, 0, 'ACCRUAL PPH 21 OKT 2020'),
(1755, 251, 52, 0.00, 36073843.00, 0, 'TUNJANGAN JAMSOSTEK OKT 2020'),
(1756, 251, 14, 0.00, 56021184.00, 0, 'CAD PENGHAPUSAN PIUTANG SWAMITRA OKT 20'),
(1757, 251, 20, 0.00, 60000000.00, 0, 'CAD PENURUNAN NILAI PINJAMAN XTRA PLATINUM OKT 2020'),
(1758, 251, 15, 0.00, 92000000.00, 0, 'GAGAL KLAIM AJW'),
(1759, 251, 15, 0.00, 60000000.00, 0, 'KERUGIAN PIUTANG OKT 2020'),
(1760, 252, 6, 1139723.71, 0.00, 0, 'FEE 70 20 SEPT 2020'),
(1761, 252, 139, 0.00, 0.20, 0, 'PEMBULATAN'),
(1762, 252, 17, 0.00, 1139723.51, 0, 'FEE 70 20 SEPT 2020'),
(1763, 253, 52, 179106595.00, 0.00, 0, 'REKLAS TITIPAN'),
(1764, 253, 66, 0.00, 179106595.00, 0, 'REKLAS TITIPAN'),
(1834, 244, 4, 19957300.00, 0.00, 0, 'PEMBAYARAN BUNGA XTRA PLATINUM OKTOBER 2020'),
(1835, 244, 145, 0.00, 289000.00, 0, 'BUNGA OKT 20 1021330005'),
(1836, 244, 145, 0.00, 285000.00, 0, 'BUNGA OKT 20 3701313890'),
(1837, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 1307320789'),
(1838, 244, 145, 0.00, 359100.00, 0, 'BUNGA OKT 20 3601311414'),
(1839, 244, 145, 0.00, 323000.00, 0, 'BUNGA OKT 20 3202311361'),
(1840, 244, 145, 0.00, 323000.00, 0, 'BUNGA OKT 20 3062310230'),
(1841, 244, 145, 0.00, 314500.00, 0, 'BUNGA OKT 20 2802311297'),
(1842, 244, 145, 0.00, 171000.00, 0, 'BUNGA OKT 20 3062310180'),
(1843, 244, 145, 0.00, 340000.00, 0, 'BUNGA OKT 20 1301330440'),
(1844, 244, 145, 0.00, 190000.00, 0, 'BUNGA OKT 20 1362310242'),
(1845, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 5201331865'),
(1846, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 4002310221'),
(1847, 244, 145, 0.00, 209000.00, 0, 'BUNGA OKT 20 1330310704'),
(1848, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 3901310348'),
(1849, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 3701313696'),
(1850, 244, 145, 0.00, 285000.00, 0, 'BUNGA OKT 20 1362310021'),
(1851, 244, 145, 0.00, 209000.00, 0, 'BUNGA OKT 20 4617310081'),
(1852, 244, 145, 0.00, 202300.00, 0, 'BUNGA OKT 20 2801311350'),
(1853, 244, 145, 0.00, 255000.00, 0, 'BUNGA OKT 20 2103312168'),
(1854, 244, 145, 0.00, 266000.00, 0, 'BUNGA OKT 20 1103310574'),
(1855, 244, 145, 0.00, 294500.00, 0, 'BUNGA OKT 20 1163320171'),
(1856, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 5201332644'),
(1857, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 2761310345'),
(1858, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 5201311991'),
(1859, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 3901310396'),
(1860, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 3901310337'),
(1861, 244, 145, 0.00, 340100.00, 0, 'BUNGA OKT 20 2801311392'),
(1862, 244, 145, 0.00, 342000.00, 0, 'BUNGA OKT 20 2801311292'),
(1863, 244, 145, 0.00, 190000.00, 0, 'BUNGA OKT 20 3062310119'),
(1864, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 4617310086'),
(1865, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 3301311781'),
(1866, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 0362310280'),
(1867, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 4824310175'),
(1868, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 3901310657'),
(1869, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 0310311336'),
(1870, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 4002310858'),
(1871, 244, 145, 0.00, 171000.00, 0, 'BUNGA OKT 20 3062310118'),
(1872, 244, 145, 0.00, 204000.00, 0, 'BUNGA OKT 20 4002310214'),
(1873, 244, 145, 0.00, 266000.00, 0, 'BUNGA OKT 20 1001330040'),
(1874, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 5101311755'),
(1875, 244, 145, 0.00, 255000.00, 0, 'BUNGA OKT 20 4002310968'),
(1876, 244, 145, 0.00, 338200.00, 0, 'BUNGA OKT 20 5101312194'),
(1877, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 3501102301'),
(1878, 244, 145, 0.00, 304000.00, 0, 'BUNGA OKT 20 364310450'),
(1879, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 0902310654'),
(1880, 244, 145, 0.00, 338200.00, 0, 'BUNGA OKT 20 2961310721'),
(1881, 244, 145, 0.00, 190000.00, 0, 'BUNGA OKT 20 3202311881'),
(1882, 244, 145, 0.00, 312800.00, 0, 'BUNGA OKT 20 0364310071'),
(1883, 244, 145, 0.00, 342000.00, 0, 'BUNGA OKT 20 4002330138'),
(1884, 244, 145, 0.00, 209100.00, 0, 'BUNGA OKT 20 2761310304'),
(1885, 244, 145, 0.00, 359100.00, 0, 'BUNGA OKT 20 4002310822'),
(1886, 244, 145, 0.00, 323000.00, 0, 'BUNGA OKT 20 1007310011'),
(1887, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 2961310487'),
(1888, 244, 145, 0.00, 323000.00, 0, 'BUNGA OKT 20 2961310507'),
(1889, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 3202311319'),
(1890, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 2503311510'),
(1891, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 1902310488'),
(1892, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 2001311286'),
(1893, 244, 145, 0.00, 380000.00, 0, 'BUNGA OKT 20 5601310965'),
(1894, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 5101312774'),
(1895, 244, 145, 0.00, 170000.00, 0, 'BUNGA OKT 20 3901310236'),
(1896, 244, 145, 0.00, 199500.00, 0, 'BUNGA OKT 20 3001311318'),
(1897, 244, 145, 0.00, 190000.00, 0, 'BUNGA OKT 20 310310993'),
(1898, 244, 145, 0.00, 285000.00, 0, 'BUNGA OKT 20 4002310844'),
(1899, 244, 145, 0.00, 119000.00, 0, 'BUNGA OKT 20 3901310311'),
(1900, 244, 145, 0.00, 342000.00, 0, 'BUNGA OKT 20 361312796'),
(1901, 244, 145, 0.00, 204000.00, 0, 'BUNGA OKT 20 0362330015'),
(1902, 244, 145, 0.00, 324900.00, 0, 'BUNGA OKT 20 5330310845'),
(1903, 254, 79, 127442292.42, 0.00, 0, 'PERHITUNGAN LABA/RUGI 10 2020'),
(1904, 255, 19, 18000000.00, 0.00, 53, 'PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1905, 255, 6, 0.00, 11810000.00, 53, 'PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1906, 255, 19, 0.00, 750000.00, 53, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1907, 255, 70, 0.00, 200000.00, 53, 'SIMP POKOK PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1908, 255, 67, 0.00, 3960000.00, 53, 'PREM ASS PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1909, 255, 71, 0.00, 20000.00, 53, 'SIMP WAJIB PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1910, 255, 146, 0.00, 900000.00, 53, 'PEND ADM PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1911, 255, 146, 0.00, 18000.00, 53, 'PEND MATERAI PENC PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1912, 255, 145, 0.00, 342000.00, 53, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN JUARIAH CAB TASIKMALAYA'),
(1913, 256, 19, 15000000.00, 0.00, 31, 'PENC PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1914, 256, 145, 0.00, 255000.00, 31, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1915, 256, 67, 0.00, 3000000.00, 31, 'PREM ASS PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1916, 256, 6, 0.00, 9507000.00, 31, 'PENC PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1917, 256, 146, 0.00, 18000.00, 31, 'PEND MATERAI PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1918, 256, 70, 0.00, 200000.00, 31, 'SIMP POKOK PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1919, 256, 71, 0.00, 20000.00, 31, 'SIMP WAJIB PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1920, 256, 146, 0.00, 750000.00, 31, 'PEND ADM PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1921, 256, 19, 0.00, 1250000.00, 31, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN FX MARJONO CAB NGAWI'),
(1922, 257, 19, 13000000.00, 0.00, 53, 'PENC PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1923, 257, 19, 0.00, 541667.00, 53, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1924, 257, 145, 0.00, 247000.00, 53, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1925, 257, 6, 0.00, 8463333.00, 53, 'PENC PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1926, 257, 146, 0.00, 18000.00, 53, 'PEND MATERAI PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1927, 257, 146, 0.00, 650000.00, 53, 'PEND ADM PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1928, 257, 67, 0.00, 2860000.00, 53, 'PREM ASS PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1929, 257, 71, 0.00, 20000.00, 53, 'SIMP WAJIB PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1930, 257, 70, 0.00, 200000.00, 53, 'SIMP POKOK PINJ XTRA PLATINUM AN IDA SAMIAH CAB TASIKMALAYA'),
(1931, 258, 19, 17800000.00, 0.00, 18, 'PENC PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1932, 258, 146, 0.00, 18000.00, 18, 'PEND MATERAI PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1933, 258, 19, 0.00, 741667.00, 18, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1934, 258, 146, 0.00, 890000.00, 18, 'PEND ADM PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1935, 258, 71, 0.00, 20000.00, 18, 'SIMP WAJIB PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1936, 258, 67, 0.00, 3916000.00, 18, 'PREM ASS PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1937, 258, 70, 0.00, 200000.00, 18, 'SIMP POKOK PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1938, 258, 145, 0.00, 338200.00, 18, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1939, 258, 6, 0.00, 11676133.00, 18, 'PENC PINJ XTRA PLATINUM AN M BR NAPITUPULU CAB JAMBI'),
(1940, 259, 9, 16500000.00, 0.00, 20, 'PELUNASAN DEB MD AN ASLICHAH CAB JOMBANG'),
(1941, 259, 67, 16500000.00, 0.00, 20, 'PENC KLAIM ASURANSI DEB MD AN ASLICHAH CAB JOMBANG'),
(1942, 259, 6, 16500000.00, 0.00, 20, 'PENC KLAIM ASURANSI DEB MD AN ASLICHAH CAB JOMBANG'),
(1943, 259, 6, 750000.00, 0.00, 20, 'KOREKSI POKOK OKT 20 4002330138'),
(1944, 259, 19, 750000.00, 0.00, 20, 'KOREKSI POKOK OKT 20 4002330138'),
(1945, 259, 6, 342000.00, 0.00, 20, 'KOREKSI BUNGA OKT 20 4002330138'),
(1946, 259, 145, 342000.00, 0.00, 20, 'KOREKSI BUNGA OKT 20 4002330138'),
(1947, 259, 6, 260000.00, 0.00, 20, 'PENGEMBALIAN SIMPAPAN POKOK DAN WAJIB AN ASLICHAH CAB JOMBANG'),
(1948, 259, 70, 200000.00, 0.00, 20, 'PENGEMBALIAN SIMPAPAN POKOK  AN ASLICHAH CAB JOMBANG'),
(1949, 259, 71, 60000.00, 0.00, 20, 'PENGEMBALIAN SIMPAPAN WAJIB  AN ASLICHAH CAB JOMBANG'),
(1950, 259, 9, 0.00, 260000.00, 20, 'PENGEMBALIAN SIMPAPAN POKOK DAN WAJIB AN ASLICHAH CAB JOMBANG'),
(1951, 259, 4, 0.00, 342000.00, 20, 'KOREKSI BUNGA OKT 20 4002330138'),
(1952, 259, 6, 0.00, 1092000.00, 20, 'PENGEMBALIAN POKOK DAN BUNGA OKT 20 4002330138'),
(1953, 259, 6, 0.00, 16500000.00, 20, 'PELUNASAN DEB MD AN ASLICHAH CAB JOMBANG'),
(1954, 259, 7, 0.00, 16500000.00, 20, 'PENC KLAIM ASURANSI DEB MD AN ASLICHAH CAB JOMBANG'),
(1955, 259, 19, 0.00, 16500000.00, 20, 'PELUNASAN DEB MD AN ASLICHAH CAB JOMBANG'),
(1956, 259, 9, 0.00, 750000.00, 20, 'KOREKSI POKOK OKT 20 4002330138'),
(1957, 259, 6, 0.00, 260000.00, 20, 'PENGEMBALIAN SIMPAPAN POKOK DAN WAJIB AN ASLICHAH CAB JOMBANG'),
(1958, 260, 19, 20000000.00, 0.00, 31, 'PENC PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1959, 260, 70, 0.00, 200000.00, 31, 'SIMP POKOK PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1960, 260, 71, 0.00, 40000.00, 31, 'SIMP WAJIB PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1961, 260, 145, 0.00, 380000.00, 31, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1962, 260, 146, 0.00, 1000000.00, 31, 'PEND ADM PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1963, 260, 145, 0.00, 380000.00, 31, 'ANGS BUNGA BLN KE 2 PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1964, 260, 19, 0.00, 833334.00, 31, 'ANGS POKOK BLN KE 2 PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1965, 260, 146, 0.00, 18000.00, 31, 'PEND MATERAI PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1966, 260, 19, 0.00, 833334.00, 31, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1967, 260, 67, 0.00, 4400000.00, 31, 'PREM ASS PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1968, 260, 6, 0.00, 11915332.00, 31, 'PENC PINJ XTRA PLATINUM AN SUBIYANTI CAB NGAWI'),
(1969, 261, 19, 15000000.00, 0.00, 45, 'PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1970, 261, 19, 0.00, 625000.00, 45, 'ANGS POKOK BLN KE I PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1971, 261, 146, 0.00, 18000.00, 45, 'PEND MATERAI PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1972, 261, 6, 0.00, 9802000.00, 45, 'PENC PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1973, 261, 145, 0.00, 285000.00, 45, 'ANGS BUNGA BLN KE I PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1974, 261, 71, 0.00, 20000.00, 45, 'SIMP WAJIB PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1975, 261, 67, 0.00, 3300000.00, 45, 'PREM ASS PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1976, 261, 146, 0.00, 750000.00, 45, 'PEND ADM PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1977, 261, 70, 0.00, 200000.00, 45, 'SIMP POKOK PINJ XTRA PLATINUM AN MARDIJAH CAB SITUBONDO'),
(1978, 262, 19, 20000000.00, 0.00, 35, 'PENC PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1979, 262, 19, 0.00, 833334.00, 35, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1980, 262, 146, 0.00, 18000.00, 35, 'PEND MATERAI PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1981, 262, 6, 0.00, 13148666.00, 35, 'PENC PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1982, 262, 145, 0.00, 380000.00, 35, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1983, 262, 71, 0.00, 20000.00, 35, 'SIMP WAJIB PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1984, 262, 67, 0.00, 4400000.00, 35, 'PREM ASS PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1985, 262, 146, 0.00, 1000000.00, 35, 'PEND ADM PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1986, 262, 70, 0.00, 200000.00, 35, 'SIMP POKOK PINJ XTRA PLATINUM AN M FADAL CAB PAMEKASAN'),
(1987, 263, 19, 20000000.00, 0.00, 21, 'PENC PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1988, 263, 19, 0.00, 1666667.00, 21, 'ANGS POKOK BLN KE 1 PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1989, 263, 146, 0.00, 18000.00, 21, 'PEND MATERAI PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1990, 263, 6, 0.00, 12755333.00, 21, 'PENC PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1991, 263, 145, 0.00, 340000.00, 21, 'ANGS BUNGA BLN KE 1 PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1992, 263, 146, 0.00, 1000000.00, 21, 'PEND ADM PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1993, 263, 67, 0.00, 4000000.00, 21, 'PREM ASS PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1994, 263, 71, 0.00, 20000.00, 21, 'SIMP WAJIB PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1995, 263, 70, 0.00, 200000.00, 21, 'SIMP POKOK PINJ XTRA PLATINUM AN MISIRAN MISWANTO CAB KEDIRI'),
(1996, 267, 9, 54316667.00, 0.00, 0, 'Pembayaran Angsuran Pokok Xtra Platinum Okt 2020'),
(1997, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 4002310221'),
(1998, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 1307320789'),
(1999, 267, 19, 0.00, 1416667.00, 0, 'POKOK OKT 20 1021330005'),
(2000, 267, 19, 0.00, 583333.00, 0, 'POKOK OKT 20 1103310574'),
(2001, 267, 19, 0.00, 645833.00, 0, 'POKOK OKT 20 1163320171'),
(2002, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 5201332644'),
(2003, 267, 19, 0.00, 437500.00, 0, 'POKOK OKT 20 3001311318'),
(2004, 267, 19, 0.00, 750000.00, 0, 'POKOK OKT 20 361312796'),
(2005, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3202311319'),
(2006, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 2503311510'),
(2007, 267, 19, 0.00, 1000000.00, 0, 'POKOK OKT 20 0362330015'),
(2008, 267, 19, 0.00, 712500.00, 0, 'POKOK OKT 20 5330310845'),
(2009, 267, 19, 0.00, 583333.00, 0, 'POKOK OKT 20 3901310311'),
(2010, 267, 19, 0.00, 991667.00, 0, 'POKOK OKT 20 2801311350'),
(2011, 267, 19, 0.00, 1250000.00, 0, 'POKOK OKT 20 2103312168'),
(2012, 267, 19, 0.00, 625000.00, 0, 'POKOK OKT 20 1362310021'),
(2013, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3901310236'),
(2014, 267, 19, 0.00, 10.00, 0, 'PEMBULATAN BAYAR POKOK OKT 2020'),
(2015, 267, 19, 0.00, 458333.00, 0, 'POKOK OKT 20 4617310081'),
(2016, 267, 19, 0.00, 458333.00, 0, 'POKOK OKT 20 1330310704'),
(2017, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3901310396'),
(2018, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3901310337'),
(2019, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 2761310345'),
(2020, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3901310348'),
(2021, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3701313696'),
(2022, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 5201311991'),
(2023, 267, 19, 0.00, 416667.00, 0, 'POKOK OKT 20 3062310119'),
(2024, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 4824310175'),
(2025, 267, 19, 0.00, 750000.00, 0, 'POKOK OKT 20 2801311292'),
(2026, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 0362310280'),
(2027, 267, 19, 0.00, 745833.00, 0, 'POKOK OKT 20 2801311392'),
(2028, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3901310657'),
(2029, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 0310311336'),
(2030, 267, 19, 0.00, 583333.00, 0, 'POKOK OKT 20 1001330040'),
(2031, 267, 19, 0.00, 375000.00, 0, 'POKOK OKT 20 3062310118'),
(2032, 267, 19, 0.00, 1000000.00, 0, 'POKOK OKT 20 4002310214'),
(2033, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3301311781'),
(2034, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 5201331865'),
(2035, 267, 19, 0.00, 787500.00, 0, 'POKOK OKT 20 3601311414'),
(2036, 267, 19, 0.00, 416667.00, 0, 'POKOK OKT 20 1362310242'),
(2037, 267, 19, 0.00, 625000.00, 0, 'POKOK OKT 20 3701313890'),
(2038, 267, 19, 0.00, 1666667.00, 0, 'POKOK OKT 20 1301330440'),
(2039, 267, 19, 0.00, 750000.00, 0, 'POKOK OKT 20 4002330138'),
(2040, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 4617310086'),
(2041, 267, 19, 0.00, 1533333.00, 0, 'POKOK OKT 20 0364310071'),
(2042, 267, 19, 0.00, 1541667.00, 0, 'POKOK OKT 20 2802311297'),
(2043, 267, 19, 0.00, 787500.00, 0, 'POKOK OKT 20 4002310822'),
(2044, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 4002310858'),
(2045, 267, 19, 0.00, 625000.00, 0, 'POKOK OKT 20 4002310844'),
(2046, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 1902310488'),
(2047, 267, 19, 0.00, 375000.00, 0, 'POKOK OKT 20 3062310180'),
(2048, 267, 19, 0.00, 708333.00, 0, 'POKOK OKT 20 3202311361'),
(2049, 267, 19, 0.00, 708333.00, 0, 'POKOK OKT 20 3062310230'),
(2050, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 2001311286'),
(2051, 267, 19, 0.00, 708333.00, 0, 'POKOK OKT 20 2961310507'),
(2052, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 2961310487'),
(2053, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 5601310965'),
(2054, 267, 19, 0.00, 416667.00, 0, 'POKOK OKT 20 310310993'),
(2055, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 5101312774'),
(2056, 267, 19, 0.00, 741667.00, 0, 'POKOK OKT 20 2961310721'),
(2057, 267, 19, 0.00, 741667.00, 0, 'POKOK OKT 20 5101312194'),
(2058, 267, 19, 0.00, 1025000.00, 0, 'POKOK OKT 20 2761310304'),
(2059, 267, 19, 0.00, 416667.00, 0, 'POKOK OKT 20 3202311881'),
(2060, 267, 19, 0.00, 708333.00, 0, 'POKOK OKT 20 1007310011'),
(2061, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 0902310654'),
(2062, 267, 19, 0.00, 666667.00, 0, 'POKOK OKT 20 364310450'),
(2063, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 3501102301'),
(2064, 267, 19, 0.00, 833333.00, 0, 'POKOK OKT 20 5101311755'),
(2065, 267, 19, 0.00, 1250000.00, 0, 'POKOK OKT 20 4002310968'),
(2066, 271, 9, 1360000.00, 0.00, 0, 'Setoran Simpanan Wajib Deb Xtra Platinum Sept 2020'),
(2067, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1330310704'),
(2068, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3901310348'),
(2069, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3701313696'),
(2070, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1362310021'),
(2071, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4617310081'),
(2072, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2801311350'),
(2073, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2103312168'),
(2074, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5201311991'),
(2075, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1163320171'),
(2076, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5201332644'),
(2077, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002310221'),
(2078, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1103310574'),
(2079, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3901310396'),
(2080, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3901310337'),
(2081, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2761310345'),
(2082, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4824310175'),
(2083, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3062310118'),
(2084, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002310214'),
(2085, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2801311392'),
(2086, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2801311292'),
(2087, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3062310119'),
(2088, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1001330040'),
(2089, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3202311881'),
(2090, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1007310011'),
(2091, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2761310304'),
(2092, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3901310657'),
(2093, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 0310311336'),
(2094, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002310858'),
(2095, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1362310242'),
(2096, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5201331865'),
(2097, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3601311414'),
(2098, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1021330005'),
(2099, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3701313890'),
(2100, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1301330440'),
(2101, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2802311297'),
(2102, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4617310086'),
(2103, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3301311781'),
(2104, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 0362310280'),
(2105, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002310822'),
(2106, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 0364310071'),
(2107, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002330138'),
(2108, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2961310507'),
(2109, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2961310487'),
(2110, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2503311510'),
(2111, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 310310993'),
(2112, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5101312774'),
(2113, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5601310965'),
(2114, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3202311319'),
(2115, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 0362330015'),
(2116, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3001311318'),
(2117, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3901310236'),
(2118, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 361312796'),
(2119, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3901310311'),
(2120, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5330310845'),
(2121, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5101311755'),
(2122, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 0902310654'),
(2123, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 364310450'),
(2124, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2961310721'),
(2125, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 5101312194'),
(2126, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002310968'),
(2127, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3501102301'),
(2128, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 4002310844'),
(2129, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1902310488'),
(2130, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 2001311286'),
(2131, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3202311361'),
(2132, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3062310230'),
(2133, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 3062310180'),
(2134, 271, 71, 0.00, 20000.00, 0, 'SIMP WAJIB OKT 20 1307320789'),
(2135, 279, 67, 100445851.00, 0.00, 0, '-'),
(2136, 279, 52, 0.00, 100445851.00, 0, '-'),
(2137, 281, 67, 140334326.00, 0.00, 0, '-'),
(2138, 281, 52, 0.00, 140334326.00, 0, '-'),
(2139, 282, 67, 161579602.00, 0.00, 0, '-'),
(2140, 282, 52, 0.00, 161579602.00, 0, '-'),
(2141, 289, 67, 166355493.00, 0.00, 0, '-'),
(2142, 289, 52, 0.00, 166355493.00, 0, '-'),
(2143, 290, 67, 239125142.00, 0.00, 0, '-'),
(2144, 290, 52, 0.00, 239125142.00, 0, '-'),
(2145, 291, 67, 42165969.00, 0.00, 0, '-'),
(2146, 291, 52, 0.00, 42165969.00, 0, '-'),
(2147, 292, 67, 38599357.00, 0.00, 0, '-'),
(2148, 292, 52, 0.00, 38599357.00, 0, '-'),
(2149, 293, 52, 900000000.00, 0.00, 0, '-'),
(2150, 293, 177, 0.00, 900000000.00, 0, '-'),
(2151, 294, 66, 225000000.00, 0.00, 0, '-'),
(2152, 294, 65, 0.00, 225000000.00, 0, '-'),
(2153, 325, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 001/INV-G'),
(2154, 325, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 001/INV-G'),
(2155, 326, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 003/INV-G'),
(2156, 326, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 003/INV-G'),
(2157, 327, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 005/INV-G'),
(2158, 327, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 005/INV-G'),
(2159, 328, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 007/INV-G'),
(2160, 328, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 007/INV-G'),
(2161, 329, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 009/INV-G'),
(2162, 329, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 009/INV-G'),
(2163, 330, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 011/INV-G'),
(2164, 330, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 011/INV-G'),
(2165, 331, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 013/INV-G'),
(2166, 331, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 013/INV-G'),
(2167, 332, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 015/INV-G'),
(2168, 332, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 015/INV-G'),
(2169, 333, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 023/INV-G'),
(2170, 333, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 023/INV-G'),
(2171, 334, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 025/INV-G'),
(2172, 334, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET 025/INV-G'),
(2173, 335, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B45'),
(2174, 335, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B45'),
(2175, 336, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B45'),
(2176, 336, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B45'),
(2177, 337, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B4J'),
(2178, 337, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B4J'),
(2179, 338, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5F'),
(2180, 338, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5F'),
(2181, 339, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5F'),
(2182, 339, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5F'),
(2183, 340, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5H'),
(2184, 340, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5H'),
(2185, 341, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5J'),
(2186, 341, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5J'),
(2187, 342, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5J'),
(2188, 342, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN69L4B5J'),
(2189, 343, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN6CJ4728'),
(2190, 343, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN6CJ4728'),
(2191, 344, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN6CN4730'),
(2192, 344, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET CN6CN4730'),
(2193, 345, 110, 125000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV018/00'),
(2194, 345, 34, 0.00, 125000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV018/00'),
(2195, 346, 110, 29167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02'),
(2196, 346, 34, 0.00, 29167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02'),
(2197, 347, 110, 83333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02'),
(2198, 347, 34, 0.00, 83333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02'),
(2199, 348, 110, 15625.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02'),
(2200, 348, 34, 0.00, 15625.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV020/02'),
(2201, 349, 110, 125000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2202, 349, 34, 0.00, 125000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2203, 350, 110, 206250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2204, 350, 34, 0.00, 206250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2205, 351, 110, 33333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2206, 351, 34, 0.00, 33333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2207, 352, 110, 52083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2208, 352, 34, 0.00, 52083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2209, 353, 110, 39583.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2210, 353, 34, 0.00, 39583.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2211, 354, 110, 2083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2212, 354, 34, 0.00, 2083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2213, 355, 110, 7292.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2214, 355, 34, 0.00, 7292.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/000'),
(2215, 356, 110, 6250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2216, 356, 34, 0.00, 6250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2217, 357, 110, 2083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2218, 357, 34, 0.00, 2083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2219, 358, 110, 145833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2220, 358, 34, 0.00, 145833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2221, 359, 110, 145833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2222, 359, 34, 0.00, 145833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2223, 360, 110, 145833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2224, 360, 34, 0.00, 145833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2225, 361, 110, 145833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2226, 361, 34, 0.00, 145833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-1/001'),
(2227, 362, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2228, 362, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2229, 363, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2230, 363, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2231, 364, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2232, 364, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2233, 365, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2234, 365, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2235, 366, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2236, 366, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2237, 367, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2238, 367, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2239, 368, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2240, 368, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2241, 369, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2242, 369, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2243, 370, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2244, 370, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2245, 371, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2246, 371, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2247, 372, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2248, 372, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2249, 373, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2250, 373, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2251, 374, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2252, 374, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2253, 375, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2254, 375, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00');
INSERT INTO `journal_voucher_det` (`journal_voucher_detid`, `journal_voucher_id`, `jns_akun_id`, `debit`, `credit`, `jns_cabangid`, `itemnote`) VALUES
(2255, 376, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2256, 376, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2257, 377, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2258, 377, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2259, 378, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2260, 378, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2261, 379, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2262, 379, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2263, 380, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2264, 380, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2265, 381, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2266, 381, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2267, 382, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2268, 382, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2269, 383, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2270, 383, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2271, 384, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2272, 384, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2273, 385, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2274, 385, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2275, 386, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2276, 386, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2277, 387, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2278, 387, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2279, 388, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2280, 388, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2281, 389, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2282, 389, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2283, 390, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2284, 390, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2285, 391, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2286, 391, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2287, 392, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2288, 392, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2289, 393, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2290, 393, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2291, 394, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2292, 394, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2293, 395, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2294, 395, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2295, 396, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2296, 396, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2297, 397, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2298, 397, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2299, 398, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2300, 398, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2301, 399, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2302, 399, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2303, 400, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2304, 400, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2305, 401, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2306, 401, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-17/00'),
(2307, 402, 110, 125000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/002'),
(2308, 402, 34, 0.00, 125000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/002'),
(2309, 403, 110, 25000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/003'),
(2310, 403, 34, 0.00, 25000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/003'),
(2311, 404, 110, 291667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/005'),
(2312, 404, 34, 0.00, 291667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/005'),
(2313, 405, 110, 291667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/006'),
(2314, 405, 34, 0.00, 291667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/006'),
(2315, 406, 110, 187500.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/007'),
(2316, 406, 34, 0.00, 187500.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/007'),
(2317, 407, 110, 66667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/008'),
(2318, 407, 34, 0.00, 66667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/008'),
(2319, 408, 110, 52083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/009'),
(2320, 408, 34, 0.00, 52083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/009'),
(2321, 409, 110, 43750.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/010'),
(2322, 409, 34, 0.00, 43750.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18/010'),
(2323, 410, 110, 56250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18-004'),
(2324, 410, 34, 0.00, 56250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV18-004'),
(2325, 411, 110, 18333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/001'),
(2326, 411, 34, 0.00, 18333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/001'),
(2327, 412, 110, 10417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/002'),
(2328, 412, 34, 0.00, 10417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/002'),
(2329, 413, 110, 104167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/003'),
(2330, 413, 34, 0.00, 104167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/003'),
(2331, 414, 110, 18333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/004'),
(2332, 414, 34, 0.00, 18333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/004'),
(2333, 415, 110, 174583.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/005'),
(2334, 415, 34, 0.00, 174583.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/005'),
(2335, 416, 110, 295917.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/006'),
(2336, 416, 34, 0.00, 295917.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/006'),
(2337, 417, 110, 6250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/007'),
(2338, 417, 34, 0.00, 6250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/007'),
(2339, 418, 110, 25000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/008'),
(2340, 418, 34, 0.00, 25000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/008'),
(2341, 419, 110, 80625.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/010'),
(2342, 419, 34, 0.00, 80625.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/010'),
(2343, 420, 110, 9792.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/011'),
(2344, 420, 34, 0.00, 9792.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/011'),
(2345, 421, 110, 6250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/012'),
(2346, 421, 34, 0.00, 6250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/012'),
(2347, 422, 110, 91667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/013'),
(2348, 422, 34, 0.00, 91667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/013'),
(2349, 423, 110, 18333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/014'),
(2350, 423, 34, 0.00, 18333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/014'),
(2351, 424, 110, 5729.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/015'),
(2352, 424, 34, 0.00, 5729.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/015'),
(2353, 425, 110, 7292.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/016'),
(2354, 425, 34, 0.00, 7292.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/016'),
(2355, 426, 110, 1875000.00, 0.00, 56, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/017'),
(2356, 426, 34, 0.00, 1875000.00, 56, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/017'),
(2357, 427, 110, 37604.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/018'),
(2358, 427, 34, 0.00, 37604.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/018'),
(2359, 428, 110, 179167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/019'),
(2360, 428, 34, 0.00, 179167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/019'),
(2361, 429, 110, 24979.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/020'),
(2362, 429, 34, 0.00, 24979.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/020'),
(2363, 430, 110, 87500.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/021'),
(2364, 430, 34, 0.00, 87500.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/021'),
(2365, 431, 110, 308333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/022'),
(2366, 431, 34, 0.00, 308333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/022'),
(2367, 432, 110, 5208.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/023'),
(2368, 432, 34, 0.00, 5208.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/023'),
(2369, 433, 110, 6667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/024'),
(2370, 433, 34, 0.00, 6667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/024'),
(2371, 434, 110, 1141667.00, 0.00, 56, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/025'),
(2372, 434, 34, 0.00, 1141667.00, 56, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/025'),
(2373, 435, 110, 798125.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/026'),
(2374, 435, 34, 0.00, 798125.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/026'),
(2375, 436, 110, 87500.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/027'),
(2376, 436, 34, 0.00, 87500.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/027'),
(2377, 437, 110, 13542.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/028'),
(2378, 437, 34, 0.00, 13542.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/028'),
(2379, 438, 110, 14583.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/029'),
(2380, 438, 34, 0.00, 14583.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/029'),
(2381, 439, 110, 14583.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/030'),
(2382, 439, 34, 0.00, 14583.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/030'),
(2383, 440, 110, 16667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/031'),
(2384, 440, 34, 0.00, 16667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/031'),
(2385, 441, 110, 21875.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/032'),
(2386, 441, 34, 0.00, 21875.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/032'),
(2387, 442, 110, 20833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/033'),
(2388, 442, 34, 0.00, 20833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/033'),
(2389, 443, 110, 9375.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/034'),
(2390, 443, 34, 0.00, 9375.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV19/034'),
(2391, 444, 110, 5000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/001'),
(2392, 444, 34, 0.00, 5000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/001'),
(2393, 445, 110, 17083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/002'),
(2394, 445, 34, 0.00, 17083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/002'),
(2395, 446, 110, 54167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/003'),
(2396, 446, 34, 0.00, 54167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/003'),
(2397, 447, 110, 12917.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/006'),
(2398, 447, 34, 0.00, 12917.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/006'),
(2399, 448, 110, 589583.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/007'),
(2400, 448, 34, 0.00, 589583.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/007'),
(2401, 449, 110, 468750.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/008'),
(2402, 449, 34, 0.00, 468750.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/008'),
(2403, 450, 110, 242708.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/009'),
(2404, 450, 34, 0.00, 242708.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/009'),
(2405, 451, 110, 166667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/010'),
(2406, 451, 34, 0.00, 166667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/010'),
(2407, 452, 110, 53438.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/011'),
(2408, 452, 34, 0.00, 53438.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/011'),
(2409, 453, 110, 53125.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/012'),
(2410, 453, 34, 0.00, 53125.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/012'),
(2411, 454, 110, 32917.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/013'),
(2412, 454, 34, 0.00, 32917.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/013'),
(2413, 455, 110, 110021.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/014'),
(2414, 455, 34, 0.00, 110021.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/014'),
(2415, 456, 110, 32500.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/015'),
(2416, 456, 34, 0.00, 32500.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/015'),
(2417, 457, 110, 79167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/016'),
(2418, 457, 34, 0.00, 79167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/016'),
(2419, 458, 110, 4896.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/017'),
(2420, 458, 34, 0.00, 4896.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/017'),
(2421, 459, 110, 82292.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/023'),
(2422, 459, 34, 0.00, 82292.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/023'),
(2423, 460, 110, 19792.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/024'),
(2424, 460, 34, 0.00, 19792.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/024'),
(2425, 461, 110, 115000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/025'),
(2426, 461, 34, 0.00, 115000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/025'),
(2427, 462, 110, 37188.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/026'),
(2428, 462, 34, 0.00, 37188.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/026'),
(2429, 463, 110, 39271.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/027'),
(2430, 463, 34, 0.00, 39271.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/027'),
(2431, 464, 110, 12500.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/028'),
(2432, 464, 34, 0.00, 12500.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/028'),
(2433, 465, 110, 11042.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/029'),
(2434, 465, 34, 0.00, 11042.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/029'),
(2435, 466, 110, 10417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/030'),
(2436, 466, 34, 0.00, 10417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/030'),
(2437, 467, 110, 10417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/031'),
(2438, 467, 34, 0.00, 10417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/031'),
(2439, 468, 110, 3229.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/032'),
(2440, 468, 34, 0.00, 3229.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/032'),
(2441, 469, 110, 29167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/033'),
(2442, 469, 34, 0.00, 29167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/033'),
(2443, 470, 110, 18750.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/034'),
(2444, 470, 34, 0.00, 18750.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/034'),
(2445, 471, 110, 5729.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/035'),
(2446, 471, 34, 0.00, 5729.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/035'),
(2447, 472, 110, 5729.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/036'),
(2448, 472, 34, 0.00, 5729.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/036'),
(2449, 473, 110, 4167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/037'),
(2450, 473, 34, 0.00, 4167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/037'),
(2451, 474, 110, 103125.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/038'),
(2452, 474, 34, 0.00, 103125.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/038'),
(2453, 475, 110, 83333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/039'),
(2454, 475, 34, 0.00, 83333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/039'),
(2455, 476, 110, 15104.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/040'),
(2456, 476, 34, 0.00, 15104.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/040'),
(2457, 477, 110, 177083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/041'),
(2458, 477, 34, 0.00, 177083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/041'),
(2459, 478, 110, 25000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/042'),
(2460, 478, 34, 0.00, 25000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/042'),
(2461, 479, 110, 16667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/043'),
(2462, 479, 34, 0.00, 16667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/043'),
(2463, 480, 110, 13542.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/044'),
(2464, 480, 34, 0.00, 13542.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/044'),
(2465, 481, 110, 10000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/045'),
(2466, 481, 34, 0.00, 10000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/045'),
(2467, 482, 110, 8333.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/046'),
(2468, 482, 34, 0.00, 8333.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/046'),
(2469, 483, 110, 5000.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/047'),
(2470, 483, 34, 0.00, 5000.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/047'),
(2471, 484, 110, 4167.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/048'),
(2472, 484, 34, 0.00, 4167.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/048'),
(2473, 485, 110, 45833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/049'),
(2474, 485, 34, 0.00, 45833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/049'),
(2475, 486, 110, 27083.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/050'),
(2476, 486, 34, 0.00, 27083.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/050'),
(2477, 487, 110, 22917.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/051'),
(2478, 487, 34, 0.00, 22917.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/051'),
(2479, 488, 110, 20833.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/052'),
(2480, 488, 34, 0.00, 20833.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/052'),
(2481, 489, 110, 41146.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/18 '),
(2482, 489, 34, 0.00, 41146.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/18 '),
(2483, 490, 110, 39583.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/19 '),
(2484, 490, 34, 0.00, 39583.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/19 '),
(2485, 491, 110, 132813.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/20 '),
(2486, 491, 34, 0.00, 132813.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/20 '),
(2487, 492, 110, 121354.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/21 '),
(2488, 492, 34, 0.00, 121354.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/21 '),
(2489, 493, 110, 64792.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/22 '),
(2490, 493, 34, 0.00, 64792.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20/22 '),
(2491, 494, 110, 83313.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20-004'),
(2492, 494, 34, 0.00, 83313.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20-004'),
(2493, 495, 110, 16667.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20-005'),
(2494, 495, 34, 0.00, 16667.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV20-005'),
(2495, 496, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2496, 496, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2497, 497, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2498, 497, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2499, 498, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2500, 498, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2501, 499, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2502, 499, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2503, 500, 110, 85417.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2504, 500, 34, 0.00, 85417.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2505, 501, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2506, 501, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2507, 502, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2508, 502, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2509, 503, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2510, 503, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2511, 504, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2512, 504, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2513, 505, 110, 16250.00, 0.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2514, 505, 34, 0.00, 16250.00, NULL, ' PENYUSUTAN INVENTARIS KANTOR KODE ASSET INV-26/00'),
(2515, 506, 118, 885417.00, 0.00, 35, 'PENYUSUTAN GEDUNG KANTOR'),
(2516, 506, 30, 0.00, 885417.00, 35, 'PENYUSUTAN GEDUNG KANTOR'),
(2517, 507, 118, 7166667.00, 0.00, 56, 'PENYUSUTAN GEDUNG KANTOR'),
(2518, 507, 30, 0.00, 7166667.00, 56, 'PENYUSUTAN GEDUNG KANTOR'),
(2519, 508, 118, 541667.00, 0.00, 42, 'PENYUSUTAN GEDUNG KANTOR'),
(2520, 508, 30, 0.00, 541667.00, 42, 'PENYUSUTAN GEDUNG KANTOR'),
(2521, 509, 118, 1250000.00, 0.00, 40, 'PENYUSUTAN GEDUNG KANTOR'),
(2522, 509, 30, 0.00, 1250000.00, 40, 'PENYUSUTAN GEDUNG KANTOR'),
(2523, 510, 118, 1166667.00, 0.00, 38, 'PENYUSUTAN GEDUNG KANTOR'),
(2524, 510, 30, 0.00, 1166667.00, 38, 'PENYUSUTAN GEDUNG KANTOR'),
(2525, 511, 118, 1266667.00, 0.00, 23, 'PENYUSUTAN GEDUNG KANTOR'),
(2526, 511, 30, 0.00, 1266667.00, 23, 'PENYUSUTAN GEDUNG KANTOR'),
(2527, 512, 118, 2916667.00, 0.00, 17, 'PENYUSUTAN GEDUNG KANTOR'),
(2528, 512, 30, 0.00, 2916667.00, 17, 'PENYUSUTAN GEDUNG KANTOR'),
(2529, 513, 118, 1250000.00, 0.00, 20, 'PENYUSUTAN GEDUNG KANTOR'),
(2530, 513, 30, 0.00, 1250000.00, 20, 'PENYUSUTAN GEDUNG KANTOR'),
(2531, 514, 118, 1250000.00, 0.00, 50, 'PENYUSUTAN GEDUNG KANTOR'),
(2532, 514, 30, 0.00, 1250000.00, 50, 'PENYUSUTAN GEDUNG KANTOR'),
(2533, 515, 118, 1250000.00, 0.00, 13, 'PENYUSUTAN GEDUNG KANTOR'),
(2534, 515, 30, 0.00, 1250000.00, 13, 'PENYUSUTAN GEDUNG KANTOR'),
(2535, 516, 118, 833333.00, 0.00, 52, 'PENYUSUTAN GEDUNG KANTOR'),
(2536, 516, 30, 0.00, 833333.00, 52, 'PENYUSUTAN GEDUNG KANTOR'),
(2537, 517, 118, 1666667.00, 0.00, 7, 'PENYUSUTAN GEDUNG KANTOR'),
(2538, 517, 30, 0.00, 1666667.00, 7, 'PENYUSUTAN GEDUNG KANTOR'),
(2539, 518, 118, 833333.00, 0.00, 56, 'PENYUSUTAN GEDUNG KANTOR'),
(2540, 518, 30, 0.00, 833333.00, 56, 'PENYUSUTAN GEDUNG KANTOR'),
(2541, 519, 118, 1250000.00, 0.00, 34, 'PENYUSUTAN GEDUNG KANTOR'),
(2542, 519, 30, 0.00, 1250000.00, 34, 'PENYUSUTAN GEDUNG KANTOR'),
(2543, 520, 143, 60230.00, 0.00, 0, 'KOREKSI BAA 202010 0706310349 AN. IDA BAGUS PUTU SUDA'),
(2544, 520, 4, 0.00, 60230.00, 0, 'KOREKSI BAA 202010 0706310349 AN. IDA BAGUS PUTU SUDA'),
(2545, 521, 4, 1023528178.00, 0.00, 0, 'Pendapatan BAA Nov 2020'),
(2546, 521, 143, 0.00, 1023528178.00, 0, 'Pendapatan BAA Nov 2020'),
(2547, 522, 133, 38000.00, 0.00, 24, 'By kirim berkas Cab Kupang'),
(2548, 522, 4, 0.00, 38000.00, 24, 'By kirim berkas Cab Kupang'),
(2549, 523, 125, 200000.00, 0.00, 33, 'By internet cab Palembang'),
(2550, 523, 133, 44000.00, 0.00, 33, 'By kirim berkas Cab Palembang'),
(2551, 523, 4, 0.00, 244000.00, 33, 'By Opr Cab Palembang'),
(2552, 524, 5, 350000000.00, 0.00, 0, 'Pemindahbukuan Dana Cad ke Rek 431'),
(2553, 524, 4, 0.00, 350000000.00, 0, 'Pemindahbukuan Dana Cad ke Rek 431'),
(2554, 525, 125, 300000.00, 0.00, 38, 'By Internet Cab Pontianak'),
(2555, 525, 133, 56000.00, 0.00, 38, 'By kirim berkas cab Pontianak'),
(2556, 525, 123, 40500.00, 0.00, 38, 'By Pdam Cab Pontianak'),
(2557, 525, 4, 0.00, 396500.00, 38, 'By Opr Cab Pontianak'),
(2558, 526, 27, 160000.00, 0.00, 46, 'PENGAJUAN UMB CAB SLEMAN'),
(2559, 526, 4, 0.00, 156916.00, 46, 'PENGAJUAN UMB CAB SLEMAN'),
(2560, 526, 15, 0.00, 3084.00, 46, 'KELEBIHAN UMB OPR CAB SLEMAN'),
(2561, 527, 122, 150000.00, 0.00, 9, 'By Transport Cab Blitar'),
(2562, 527, 133, 55000.00, 0.00, 9, 'By Kirim berkas Cab Blitar'),
(2563, 527, 127, 20900.00, 0.00, 9, 'By ATK Cab Blitar'),
(2564, 527, 4, 0.00, 225900.00, 9, 'By Opr Cab Blitar'),
(2565, 528, 125, 300000.00, 0.00, 35, 'By Internet Cab Pamekasan'),
(2566, 528, 129, 30000.00, 0.00, 35, 'By Materai Cab Pamekasan'),
(2567, 528, 123, 22500.00, 0.00, 35, 'By Listrik Cab Pamekasan'),
(2568, 528, 4, 0.00, 352500.00, 35, 'By Opr Cab Pamekasan'),
(2569, 529, 66, 138867547.00, 0.00, 0, 'Pelunasan 3 Deb fraud SI No 1354'),
(2570, 529, 5, 0.00, 138867547.00, 0, 'Pelunasan 3 Deb fraud SI No 1354'),
(2571, 530, 4, 20000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN. BP EDDY PRAMANA'),
(2572, 530, 52, 0.00, 20000.00, 0, 'PEMBAYARAN SEMBAKO AN. BP EDDY PRAMANA'),
(2573, 531, 27, 10000000.00, 0.00, 0, 'UMB Rapat 8.11.2020'),
(2574, 531, 4, 0.00, 10000000.00, 0, 'UMB Rapat 8.11.2020'),
(2575, 532, 4, 519000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD'),
(2576, 532, 52, 0.00, 519000.00, 0, 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD'),
(2577, 533, 123, 250000.00, 0.00, 52, 'By Listrik Cab Tj Pinang'),
(2578, 533, 125, 150000.00, 0.00, 52, 'By Internet Cab Tj Pinang'),
(2579, 533, 4, 0.00, 400000.00, 52, 'By Opr Cab Tanjung Pinang'),
(2580, 534, 133, 188900.00, 0.00, 30, 'By Kirim berkas Cab Medan'),
(2581, 534, 4, 0.00, 188900.00, 30, 'By Kirim berkas Cab Medan'),
(2582, 535, 133, 36000.00, 0.00, 54, 'By Kirim Berkas Cab Tegal'),
(2583, 535, 4, 0.00, 36000.00, 54, 'By Kirim Berkas Cab Tegal'),
(2584, 536, 133, 5721500.00, 0.00, 0, 'PERTANGGUNGJAWABAN UMB RAPAT 8.11.2020'),
(2585, 536, 4, 4278500.00, 0.00, 0, 'REFUND KELEBIHAN UMB RAPAT 8.11.2020'),
(2586, 536, 27, 0.00, 10000000.00, 0, 'PERTANGGUNGJAWABAN UMB RAPAT 8.11.2020'),
(2587, 537, 15, 40000000.00, 0.00, 0, 'Pemindahbukuan dana ke Rek Mandiri'),
(2588, 537, 4, 0.00, 40000000.00, 0, 'Pemindahbukuan dana ke Rek Mandiri'),
(2589, 538, 133, 150000.00, 0.00, 11, 'By Rapid Test Cab BUkittinggi'),
(2590, 538, 4, 0.00, 150000.00, 11, 'By Rapid Test Cab Bukittinggi'),
(2591, 539, 175, 0.00, 5541780.00, 0, 'GIRO DAN PAJAK GIRO'),
(2592, 539, 126, 1108356.00, 0.00, 0, 'GIRO DAN PAJAK GIRO'),
(2593, 539, 4, 4433424.00, 0.00, 0, 'GIRO DAN PAJAK GIRO'),
(2594, 540, 95, 100000000.00, 0.00, 0, 'Penurunan MTT Swamitra HI Nov 2020'),
(2595, 540, 4, 0.00, 100000000.00, 0, 'Penurunan MTT Swamitra HI Nov 2020'),
(2596, 541, 93, 99977171.00, 0.00, 0, 'Talangan Angsuran Pensiunan Nov 2020'),
(2597, 541, 4, 0.00, 99977171.00, 0, 'Talangan Angsuran Pensiunan Nov 2020'),
(2598, 542, 52, 36073843.00, 0.00, 0, 'BPJS TK Karyawan Okt 2020'),
(2599, 542, 11, 0.00, 36073843.00, 0, 'BPJS TK Karyawan Okt 2020'),
(2600, 543, 102, 13586945.00, 0.00, 0, 'BPJS KS Karyawan Nov 2020'),
(2601, 543, 11, 0.00, 13586945.00, 0, 'BPJS KS Karyawan Nov 2020'),
(2602, 544, 133, 1050000.00, 0.00, 0, 'DP Ruang Rapat tgl 8.11.2020'),
(2603, 544, 11, 0.00, 1050000.00, 0, 'DP Ruang Rapat tgl 8.11.2020'),
(2604, 545, 52, 105000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN ABD RAHMAN'),
(2605, 545, 11, 0.00, 105000.00, 0, 'PEMBAYARAN SEMBAKO AN ABD RAHMAN'),
(2606, 545, 52, 128000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN BOBBY '),
(2607, 545, 11, 0.00, 128000.00, 0, 'PEMBAYARAN SEMBAKO AN BOBBY'),
(2608, 545, 52, 20000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN  EDDY P'),
(2609, 545, 11, 0.00, 20000.00, 0, 'PEMBAYARAN SEMBAKO AN EDDY P'),
(2610, 546, 15, 4359000.00, 0.00, 0, 'Talangan Pembayaran Sembako PT TJA'),
(2611, 546, 133, 6500.00, 0.00, 0, 'Talangan Pembayaran Sembako PT TJA'),
(2612, 546, 11, 0.00, 4365500.00, 0, 'Talangan Pembayaran Sembako PT TJA'),
(2613, 547, 48, 7000000.00, 0.00, 0, 'Pembayaran PPH 21 Oktober 2020'),
(2614, 547, 104, 0.00, 247918.00, 0, 'Adjusment PPH 21 Oktober 2020'),
(2615, 547, 11, 0.00, 6752082.00, 0, 'Pembayaran PPH 21 Oktober 2020'),
(2616, 548, 139, 1000000.00, 0.00, 0, 'Pembelian Vitamin'),
(2617, 548, 133, 6500.00, 0.00, 0, 'By Trf Pembelian Vitamin'),
(2618, 548, 11, 0.00, 1006500.00, 0, 'Pembelian Vitamin'),
(2619, 549, 133, 1000000.00, 0.00, 0, 'Meeting Pengurus dengan Advisor'),
(2620, 549, 11, 0.00, 1000000.00, 0, 'Meeting Pengurus dengan Advisor'),
(2621, 550, 125, 1441500.00, 0.00, 0, 'Pembayaran Tagihan Telkom Nov 2020 GG Pusat'),
(2622, 550, 133, 2500.00, 0.00, 0, 'Adm Pembayaran Tagihan Telkom Nov 2020 GG Pusat'),
(2623, 550, 11, 0.00, 1444000.00, 0, 'Pembayaran Tagihan Telkom Nov 2020 GG Pusat'),
(2624, 551, 52, 519000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD'),
(2625, 551, 11, 0.00, 519000.00, 0, 'PEMBAYARAN SEMBAKO AN AGNY IRSYAD'),
(2626, 552, 92, 612500.00, 0.00, 0, 'Fee TJA Okt 2020'),
(2627, 552, 11, 0.00, 612500.00, 0, 'Fee TJA Okt 2020'),
(2628, 553, 11, 40000000.00, 0.00, 0, 'SETORAN DANA PEMINDAHAN KE REKENING MANDIRI'),
(2629, 553, 15, 0.00, 40000000.00, 0, 'SETORAN DANA PEMINDAHAN KE REKENING MANDIRI'),
(2630, 554, 122, 200000.00, 0.00, 0, 'By Opr Cab Bogor'),
(2631, 554, 4, 0.00, 200000.00, 0, 'By Opr Cab Bogor'),
(2632, 555, 98, 482235000.00, 0.00, 0, 'Gaji Karyawan Nov 2020'),
(2633, 555, 122, 56725000.00, 0.00, 0, 'Transport Karyawan Nov 2020'),
(2634, 555, 101, 3600000.00, 0.00, 0, 'Tunj Kinerja Nov 2020'),
(2635, 555, 21, 0.00, 3658000.00, 0, 'Piutang Karyawan An. Anggi Andriansyah'),
(2636, 555, 21, 0.00, 2500000.00, 0, 'Piutang Karyawan An. Jony Nur Efendy'),
(2637, 555, 21, 0.00, 4000000.00, 0, 'Piutang Karyawan An. Arif Gustaman'),
(2638, 555, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. Bambang Triono'),
(2639, 555, 175, 0.00, 75000.00, 0, 'Adm Angsuran Kary An. Wan Wahyudi'),
(2640, 555, 21, 0.00, 1250000.00, 0, 'Piutang Karyawan An. Wan Wahyudi'),
(2641, 555, 175, 0.00, 700000.00, 0, 'Adm Angsuran Kary An.muzammil'),
(2642, 555, 21, 0.00, 7291667.00, 0, 'Piutang Kary An. Muzammil'),
(2643, 555, 175, 0.00, 50000.00, 0, 'Adm Angsuran Kary An.arif Gustaman'),
(2644, 555, 11, 0.00, 49679000.00, 0, 'Pembayaran Gaji November 2020'),
(2645, 555, 4, 0.00, 447872650.00, 0, 'Pembayaran Gaji November 2020'),
(2646, 555, 52, 0.00, 1864250.00, 0, 'Sembako Karyawan Nov 2020'),
(2647, 555, 52, 0.00, 2000000.00, 0, 'Gaji Karyawan Ca Situbondo'),
(2648, 555, 15, 0.00, 2500000.00, 0, 'Pengembalian Titipan Pinbuk Ke Mandiri'),
(2649, 555, 21, 0.00, 500000.00, 0, 'Piutang Karyawan An. Ebnu Utoro'),
(2650, 555, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. Artha Dharma'),
(2651, 555, 175, 0.00, 35067.00, 0, 'Pend Adm Piutang Karyawan An. Ujang Fujiana'),
(2652, 555, 21, 0.00, 3500000.00, 0, 'Piutang Karyawan An. Maharis'),
(2653, 555, 175, 0.00, 37500.00, 0, 'Pend Adm Piutang Karyawan An. Bambang Susanto'),
(2654, 555, 175, 0.00, 35067.00, 0, 'Pend Adm Piutang Karyawan An. I Gusti Ngurah Made Murtika'),
(2655, 555, 21, 0.00, 583333.00, 0, 'Piutang Karyawan An. I Gusti Ngurah Made Murtika'),
(2656, 555, 21, 0.00, 833333.00, 0, 'Piutang Karyawan An. Lidya Oktaviana'),
(2657, 555, 21, 0.00, 2100000.00, 0, 'Piutang Karyawan An. Imam Sandi'),
(2658, 555, 21, 0.00, 750000.00, 0, 'Piutang Karyawan An. Bambang Susanto'),
(2659, 555, 175, 0.00, 50067.00, 0, 'Pend Adm Piutang Karyawan An. Lidya Oktaviana'),
(2660, 555, 21, 0.00, 333333.00, 0, 'Piutang Kary An. Joko Indra Budi'),
(2661, 555, 175, 0.00, 75000.00, 0, 'Adm Angsuran Kary An. Lalu Amril'),
(2662, 555, 21, 0.00, 1350000.00, 0, 'Piutang Kary An. Lalu Amril'),
(2663, 555, 21, 0.00, 583333.00, 0, 'Piutang Karyawan An. Ujang Fujiana'),
(2664, 555, 21, 0.00, 895000.00, 0, 'Piutang Karyawan An. Baiq Dewi Septiani'),
(2665, 555, 21, 0.00, 3555000.00, 0, 'Piutang Kary An. I Wayan Andiman'),
(2666, 555, 175, 0.00, 20067.00, 0, 'Adm Angsuran Kary An. Joko Indra Budi'),
(2667, 555, 175, 0.00, 50000.00, 0, 'Adm Angsuran Piutang Kary An. Slamet Setyawan'),
(2668, 555, 21, 0.00, 833333.00, 0, 'Piutang Kary An. Slamet Setyawan'),
(2669, 555, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. Yudi Guntara'),
(2670, 556, 133, 115000.00, 0.00, 0, 'by kirim dokumen cab Aceh'),
(2671, 556, 4, 0.00, 115000.00, 0, 'By Opr Cab Aceh'),
(2672, 557, 125, 300000.00, 0.00, 0, 'By Internet Cab Jombang'),
(2673, 557, 4, 0.00, 300000.00, 0, 'By Opr Cab Jombang'),
(2674, 558, 125, 2805000.00, 0.00, 0, 'BY CUG AGS SEPT 2020'),
(2675, 558, 4, 0.00, 2805000.00, 0, 'BY CUG AGS SEPT 2020'),
(2676, 559, 133, 3000000.00, 0.00, 0, 'BY KEBERSIHAN GG PUSAT MALANG AGS NOV 2020'),
(2677, 559, 125, 2107222.00, 0.00, 0, 'BY INTERNET AGS NOV 2020 GG PUSAT MALANG'),
(2678, 559, 125, 639112.00, 0.00, 0, 'BY CUG PAK MUZAMMIL AGS OKT 2020 GG PUSAT MALANG'),
(2679, 559, 123, 432600.00, 0.00, 0, 'BY LISTRIK AGS NOV 2020 GG PUSAT MALANG'),
(2680, 559, 133, 251600.00, 0.00, 0, 'BY KEPERLUAN KANTOR PUSAT GG MALANG'),
(2681, 559, 4, 0.00, 6430534.00, 0, 'BY OPR GG PUSAT MALANG AGS NOV 2020'),
(2682, 561, 125, 300000.00, 0.00, 0, 'BY INTERNET CAB CIREBON'),
(2683, 561, 127, 280000.00, 0.00, 0, 'PEMBELIAN TINTA CIREBON'),
(2684, 561, 123, 263000.00, 0.00, 0, 'BY LISTRIK DAN PDAM CIREBON'),
(2685, 561, 127, 100000.00, 0.00, 0, 'BY ATK CIREBON'),
(2686, 561, 133, 15000.00, 0.00, 0, 'BY KIRIM BERKAS CIREBON'),
(2687, 561, 4, 0.00, 958000.00, 0, 'BY OPR CAB CIREBON'),
(2688, 562, 4, 505000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN EDY PRAMANA'),
(2689, 562, 52, 0.00, 505000.00, 0, 'PEMBAYARAN SEMBAKO AN EDY PRAMANA'),
(2690, 562, 4, 676000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN MANUDIN HASAN'),
(2691, 562, 52, 0.00, 676000.00, 0, 'PEMBAYARAN SEMBAKO AN MANUDIN HASAN'),
(2692, 563, 123, 502500.00, 0.00, 0, 'BY LISTRIK CAB JKT 3'),
(2693, 563, 4, 0.00, 502500.00, 0, 'BY LISTRIK CAB JKT 3'),
(2694, 563, 133, 300000.00, 0.00, 0, 'GAJI OB CAB JKT 3'),
(2695, 563, 4, 0.00, 300000.00, 0, 'GAJI OB CAB JKT 3'),
(2696, 563, 133, 18000.00, 0.00, 0, 'BY KIRIM DOKUMEN CAB JKT 3'),
(2697, 563, 4, 0.00, 18000.00, 0, 'BY KIRIM DOKUMEN CAB JKT 3'),
(2698, 564, 52, 1864250.00, 0.00, 0, 'PEMBAYARAN SEMBAKO KARYAWAN NOV 2020'),
(2699, 564, 11, 0.00, 1864250.00, 0, 'PEMBAYARAN SEMBAKO KARYAWAN NOV 2020'),
(2700, 565, 52, 505000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN EDY PRAMANA'),
(2701, 565, 11, 0.00, 505000.00, 0, 'PEMBAYARAN SEMBAKO AN EDY PRAMANA'),
(2702, 565, 52, 676000.00, 0.00, 0, 'PEMBAYARAN SEMBAKO AN MANUDIN HASAN'),
(2703, 565, 11, 0.00, 676000.00, 0, 'PEMBAYARAN SEMBAKO AN MANUDIN HASAN'),
(2704, 566, 87, 849315.00, 0.00, 0, 'PBY BUNGA HUTANG KPD ANGGOTA AN NOFRIZAL'),
(2705, 566, 11, 0.00, 849315.00, 0, 'PBY BUNGA HUTANG KPD ANGGOTA AN NOFRIZAL'),
(2706, 566, 87, 679452.00, 0.00, 0, 'PBY BUNGA HUTANG KPD ANGGOTA AN MARWAN'),
(2707, 566, 11, 0.00, 679452.00, 0, 'PBY BUNGA HUTANG KPD ANGGOTA AN MARWAN'),
(2708, 567, 15, 1000000.00, 0.00, 0, 'TJA TAGIHAN BIOFITRO 5 BOTOL'),
(2709, 567, 133, 1000000.00, 0.00, 0, 'PEMBELIAN BIOFITRO 5 BOTOL'),
(2710, 567, 133, 6500.00, 0.00, 0, 'BY TRF PEMBELIAN BIOFITRO 10 BOTOL'),
(2711, 567, 11, 0.00, 2006500.00, 0, 'PEMBELIAN BIOFITRO 10 BOTOL'),
(2712, 568, 133, 4800000.00, 0.00, 0, 'CICILAN MOBIL NOV 2020'),
(2713, 568, 133, 6500.00, 0.00, 0, 'by trf CICILAN MOBIL NOV 2020'),
(2714, 568, 11, 0.00, 4806500.00, 0, 'CICILAN MOBIL NOV 2020'),
(2715, 569, 52, 47513100.00, 0.00, 0, 'PEMINDAHBUKUAN PELUNASAN'),
(2716, 569, 5, 0.00, 47513100.00, 0, 'PEMINDAHBUKUAN PELUNASAN'),
(2717, 570, 68, 150000000.00, 0.00, 0, 'FLAGGING'),
(2718, 570, 5, 0.00, 150000000.00, 0, 'FLAGGING'),
(2719, 571, 68, 225000000.00, 0.00, 0, 'FEE MITRA'),
(2720, 571, 5, 0.00, 225000000.00, 0, 'FEE MITRA'),
(2721, 572, 66, 195588375.00, 0.00, 0, 'PELUNASAN DEB FRAUD SI 1328 '),
(2722, 572, 5, 0.00, 195588375.00, 0, 'PELUNASAN DEB FRAUD SI 1328 '),
(2723, 572, 66, 259158651.00, 0.00, 0, 'PELUNASAN DEB FRAUD SI 1431'),
(2724, 572, 5, 0.00, 259158651.00, 0, 'PELUNASAN DEB FRAUD SI 1431'),
(2725, 573, 125, 1500000.00, 0.00, 56, 'PULSA OPERASIONAL KARYAWAN NOV 2020'),
(2726, 573, 4, 0.00, 1500000.00, 56, 'PULSA OPERASIONAL KARYAWAN NOV 2020'),
(2727, 574, 4, 1006608393.00, 0.00, 0, 'PENDAPATAN BAA DESEMBER 2020'),
(2728, 574, 143, 0.00, 1006608393.00, 0, 'PENDAPATAN BAA DESEMBER 2020'),
(2729, 575, 5, 500000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA CADANGAN'),
(2730, 575, 4, 0.00, 500000000.00, 0, 'PEMINDAHBUKUAN DANA CADANGAN'),
(2731, 576, 133, 225000.00, 0.00, 0, 'Pembelian Kopi'),
(2732, 576, 4, 0.00, 225000.00, 0, 'PEMBELIAN KOPI'),
(2733, 577, 15, 30000000.00, 0.00, 0, 'Pemindahbukuan Dana ke Mandiri'),
(2734, 577, 133, 45000.00, 0.00, 0, 'By Trf Pemindahbukuan Dana ke Mandiri'),
(2735, 577, 4, 0.00, 30045000.00, 0, 'Pemindahbukuan Dana ke Mandiri'),
(2736, 578, 133, 38000.00, 0.00, 24, 'By kirim dokumen Cab Kupang'),
(2737, 578, 4, 0.00, 38000.00, 24, 'By Opr Cab Kupang'),
(2738, 579, 127, 172006.00, 0.00, 23, 'By ATK Cab Kopang'),
(2739, 579, 133, 54000.00, 0.00, 23, 'By kirim berkas cab Kopang'),
(2740, 579, 123, 23000.00, 0.00, 23, 'By listrik cab kopang'),
(2741, 579, 4, 0.00, 249006.00, 23, 'By Opr Cab Kopang'),
(2742, 580, 2, 5922500.00, 0.00, 56, 'Pengisian kas kecil periode 27.10.20 s/d 24.11.20'),
(2743, 580, 133, 1238400.00, 0.00, 56, 'Konsumsi meeting Nov 2020'),
(2744, 580, 123, 1002000.00, 0.00, 56, 'By Listrik GG Pusat Jkt'),
(2745, 580, 139, 600000.00, 0.00, 56, 'Karangan BUnga papan wedding Kary Swamitra'),
(2746, 580, 133, 470100.00, 0.00, 56, 'Pembelian kebutuhan Pantry GG Pusat Jkt'),
(2747, 580, 122, 400000.00, 0.00, 56, 'Parkir, BBM dan Tol mobil operasional'),
(2748, 580, 122, 358000.00, 0.00, 56, 'By Bbm, Parkir dan tol mobil operasional'),
(2749, 580, 126, 300000.00, 0.00, 56, 'Uang keamanan GG Pusat Jkt Nov 2020'),
(2750, 580, 122, 300000.00, 0.00, 56, 'Transport Taxi Dari Andara ke Bekasi'),
(2751, 580, 122, 300000.00, 0.00, 56, 'Bbm dan tol mobil operasional'),
(2752, 580, 131, 240500.00, 0.00, 56, 'By langganan zoom November 2020'),
(2753, 580, 119, 200000.00, 0.00, 56, 'Pembelian lampu kantor GG Pusat Jkt'),
(2754, 580, 126, 200000.00, 0.00, 56, 'Iuran lingkungan dan sampah Nov 2020 GG Pusat Jkt'),
(2755, 580, 133, 132000.00, 0.00, 56, 'By kirim dokumen By Jne GG Pusat Jkt'),
(2756, 580, 125, 101500.00, 0.00, 56, 'Pembelian Pulsa'),
(2757, 580, 127, 45000.00, 0.00, 56, 'Pembelian ATK GG Pusat Jkt'),
(2758, 580, 133, 35000.00, 0.00, 56, 'By Laundry GG Pusat Jkt'),
(2759, 580, 4, 0.00, 5922500.00, 56, 'Pengisian Kas Kecil Periode 27.10.20 s/d 24.11.20'),
(2760, 580, 2, 0.00, 5922500.00, 56, 'Reimbursement Kas Kecil Periode 27.10.20 s/d 24.11.20'),
(2761, 581, 133, 120000.00, 0.00, 34, 'By Kirim dokumen Cab Palu'),
(2762, 581, 127, 110000.00, 0.00, 34, 'By ATK Cab Palu'),
(2763, 581, 4, 0.00, 230000.00, 34, 'By Opr Cab Palu'),
(2764, 582, 15, 90000000.00, 0.00, 0, 'Pemindahbukuan dana ke rek mandiri'),
(2765, 582, 133, 45000.00, 0.00, 0, 'By Trf Pemindahbukuan dana ke rek mandiri'),
(2766, 582, 4, 0.00, 90045000.00, 0, 'Pemindahbukuan dana ke rek mandiri'),
(2767, 583, 28, 5000000.00, 0.00, 56, 'UMB DINAS YOGYA 5-6.12.20'),
(2768, 583, 4, 0.00, 5000000.00, 56, 'UMB DINAS YOGYA 5-6.12.20'),
(2769, 583, 108, 500000.00, 0.00, 56, 'SPJ DINAS YOGYA 5-6.12.20 HARI S'),
(2770, 583, 4, 0.00, 500000.00, 56, 'SPJ DINAS YOGYA 5-6.12.20 HARI S'),
(2771, 583, 108, 500000.00, 0.00, 56, 'SPJ DINAS YOGYA 5-6.12.20 ARIF G'),
(2772, 583, 4, 0.00, 500000.00, 56, 'SPJ DINAS YOGYA 5-6.12.20 ARIF G'),
(2773, 583, 108, 500000.00, 0.00, 56, 'SPJ DINAS YOGYA 5-6.12.20 HIDAYATULLAH'),
(2774, 583, 4, 0.00, 500000.00, 56, 'SPJ DINAS YOGYA 5-6.12.20 HIDAYATULLAH'),
(2775, 584, 15, 50000000.00, 0.00, 0, 'Pemindahbukuan Dana Ke Mandiri'),
(2776, 584, 133, 37500.00, 0.00, 0, 'By Trf Pemindahbukuan Dana Ke Mandiri'),
(2777, 584, 4, 0.00, 50037500.00, 0, 'Pemindahbukuan Dana Ke Mandiri'),
(2778, 585, 52, 2000000.00, 0.00, 45, 'GAJI NOV CA SITUBONDO'),
(2779, 585, 4, 0.00, 2000000.00, 45, 'GAJI NOV CA SITUBONDO'),
(2780, 585, 63, 555556.00, 0.00, 45, 'APRESIASI CA SITUBONDO'),
(2781, 585, 5, 0.00, 555556.00, 45, 'APRESIASI CA SITUBONDO'),
(2782, 586, 133, 111000.00, 0.00, 55, 'By Kirim Berkas Cab Tomohon'),
(2783, 586, 4, 0.00, 111000.00, 55, 'By Opr Cab Tomohon'),
(2784, 587, 15, 30000000.00, 0.00, 0, 'Pemindahan Dana ke Rek Mandiri'),
(2785, 587, 133, 22500.00, 0.00, 0, 'By Trf Pemindahan Dana ke Rek Mandiri'),
(2786, 587, 4, 0.00, 30022500.00, 0, 'Pemindahan Dana ke Rek Mandiri'),
(2787, 588, 108, 3261400.00, 0.00, 0, 'By Dinas Yogya 5-6.12.2020'),
(2788, 588, 4, 1738600.00, 0.00, 0, 'Pengembalian UMB Dinas Yogya 5-6.12.2020'),
(2789, 588, 28, 0.00, 5000000.00, 0, 'Pertanggungjawaban UMB Dinas Yogya 5-6.12.2020'),
(2791, 589, 2, 5690000.00, 0.00, 0, 'Pengisian Kas Kecil Periode 27.10 s/d 14.12.2020'),
(2792, 589, 133, 2027800.00, 0.00, 0, 'Konsumsi meeting 25 Nov s/d 10 Des 2020'),
(2793, 589, 133, 589800.00, 0.00, 0, 'Pembelian kebutuhan pantry '),
(2794, 589, 113, 545000.00, 0.00, 0, 'Servis mobil operasional'),
(2795, 589, 123, 502000.00, 0.00, 0, 'Pembelian token listrik GG Pusat Jkt'),
(2796, 589, 133, 490600.00, 0.00, 0, 'By cetak Company Profile dan FC Dokumen'),
(2797, 589, 126, 300000.00, 0.00, 0, 'Iuran keamanan kantor GG Pusat Jkt'),
(2798, 589, 136, 250000.00, 0.00, 0, 'Sumbangan maulid nabi Muhammad SAW'),
(2799, 589, 131, 232500.00, 0.00, 0, 'By langganan zoom Des 2020'),
(2800, 589, 122, 200000.00, 0.00, 0, 'BBM dan Tol mobil operasional'),
(2801, 589, 126, 200000.00, 0.00, 0, 'Iuran lingkungan GG pusat Jkt'),
(2802, 589, 136, 185000.00, 0.00, 0, 'Pembelian kue ulang tahun karyawan an Adi Pratama'),
(2803, 589, 133, 117000.00, 0.00, 0, 'By kirim dokumen GG Pusat JKt'),
(2804, 589, 127, 50300.00, 0.00, 0, 'Pembelian ATK GG Pusat Jkt'),
(2805, 589, 4, 0.00, 5690000.00, 0, 'Pengisian Kas Kecil Periode 27.10 s/d 14.12.2020'),
(2806, 589, 2, 0.00, 5690000.00, 0, 'Reimbursement Kas Kecil Periode 27.10 s/d 14.12.2020'),
(2807, 590, 4, 30000000.00, 0.00, 0, 'PENGEMBALIAN DANA TALANGAN DARI PAK MUZAMMIL'),
(2808, 590, 15, 0.00, 30000000.00, 0, 'PENGEMBALIAN DANA TALANGAN DARI PAK MUZAMMIL'),
(2809, 591, 125, 200000.00, 0.00, 33, 'BY INTERNET CAB PALEMBANG'),
(2810, 591, 127, 125000.00, 0.00, 33, 'BY ATK CAB PALEMBANG'),
(2811, 591, 4, 0.00, 325000.00, 33, 'BY OPR CAB PALEMBANG'),
(2812, 592, 63, 68456088.00, 0.00, 0, 'PEMBAYARAN APRESIASI BM CA LAY OFF'),
(2813, 592, 5, 0.00, 68456088.00, 0, 'PEMBAYARAN APRESIASI BM CA LAY OFF'),
(2814, 593, 63, 156308000.00, 0.00, 0, 'PEMBAYARAN APRESIASI KARYAWAN THN 2020'),
(2815, 593, 5, 0.00, 123108000.00, 0, 'PEMBAYARAN APRESIASI KARYAWAN THN 2020'),
(2816, 593, 11, 0.00, 33200000.00, 0, 'PEMBAYARAN APRESIASI KARYAWAN THN 2020'),
(2817, 593, 63, 18304167.00, 0.00, 0, 'PEMBAYARAN THR NATAL KARYAWAN THN 2020'),
(2818, 593, 5, 0.00, 18304167.00, 0, 'PEMBAYARAN THR NATAL KARYAWAN THN 2020'),
(2819, 594, 11, 20000000.00, 0.00, 0, 'Pemindahbukuan Dana Dari 439'),
(2820, 594, 15, 0.00, 20000000.00, 0, 'Pemindahbukuan Dana Dari 439'),
(2821, 595, 15, 2400000.00, 0.00, 0, 'Pembelian Biofitro 12 botol'),
(2822, 595, 133, 6500.00, 0.00, 0, 'By Trf Pembelian Biofitro 12 botol'),
(2823, 595, 11, 0.00, 2406500.00, 0, 'Pembelian Biofitro 12 botol'),
(2824, 596, 11, 50000000.00, 0.00, 0, 'Pemindahbukuan dari rek 439'),
(2825, 596, 15, 0.00, 50000000.00, 0, 'Pemindahbukuan dari rek 439'),
(2826, 597, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA DARI REK 439'),
(2827, 597, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DANA DARI REK 439'),
(2828, 598, 11, 65000000.00, 0.00, 0, 'Pemindahbukuan Dana Dari Rek 439'),
(2829, 598, 15, 0.00, 65000000.00, 0, 'Pemindahbukuan Dana Dari Rek 439'),
(2830, 599, 52, 36073843.00, 0.00, 0, 'Pembayaran BPJS TK Karyawan Nov 2020'),
(2831, 599, 11, 0.00, 35993653.00, 0, 'Pembayaran BPJS TK Karyawan Nov 2020'),
(2832, 599, 103, 0.00, 80190.00, 0, 'Ajustment BPJS TK Nov 2020'),
(2833, 600, 102, 11232120.00, 0.00, 0, 'Pembayaran BPJS KS Karyawan bulan Des 2020'),
(2834, 600, 11, 0.00, 11232120.00, 0, 'Pembayaran BPJS KS Karyawan bulan Des 2020'),
(2835, 601, 127, 379000.00, 0.00, 56, 'Pembelian ATK GG PUSAT JKT'),
(2836, 601, 11, 0.00, 379000.00, 56, 'Pembelian ATK GG PUSAT JKT'),
(2837, 602, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA DARI REK 439'),
(2838, 602, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DANA DARI REK 439'),
(2839, 603, 11, 45000000.00, 0.00, 0, 'Pemindahbukuan Dana Dari Rek 439'),
(2840, 603, 15, 0.00, 45000000.00, 0, 'Pemindahbukuan Dana Dari Rek 439'),
(2841, 604, 48, 7000000.00, 0.00, 0, 'Pembayaran PPH 21 Karyawan masa November 2020'),
(2842, 604, 104, 0.00, 404855.00, 0, 'Ajusment PPH 21 Karyawan masa November 2020'),
(2843, 604, 11, 0.00, 6595145.00, 0, 'Pembayaran PPH 21 Karyawan masa November 2020'),
(2844, 605, 127, 678000.00, 0.00, 56, 'Pembelian tinta GG Pusat Jkt'),
(2845, 605, 133, 31900.00, 0.00, 56, 'Ongkir PEMBELIAN TINTA GG PUSAT JAKARTA '),
(2846, 605, 11, 0.00, 709900.00, 56, 'PEMBELIAN TINTA GG PUSAT JAKARTA '),
(2847, 606, 15, 100000000.00, 0.00, 0, 'Pinjaman an Deddy Methaputranto'),
(2848, 606, 133, 2900.00, 0.00, 0, 'By Trf Pinjaman an Deddy Methaputranto'),
(2849, 606, 11, 0.00, 100002900.00, 0, 'Pinjaman an Deddy Methaputranto'),
(2850, 607, 27, 3000000.00, 0.00, 56, 'UMB Rapat dengan Panin 11.12.20'),
(2851, 607, 11, 0.00, 3000000.00, 56, 'UMB Rapat dengan Panin 11.12.20'),
(2852, 608, 15, 3000000.00, 0.00, 56, 'Pembayaran Biofitro 15 Botol'),
(2853, 608, 133, 6500.00, 0.00, 56, 'By Trf Pembayaran Biofitro 15 Botol'),
(2854, 608, 11, 0.00, 3006500.00, 56, 'Pembayaran Biofitro 15 Botol'),
(2855, 609, 139, 3663000.00, 0.00, 56, 'Pembayaran Jakarta Webhosting 26.12.20-25.03.21'),
(2856, 609, 11, 0.00, 3663000.00, 56, 'Pembayaran Jakarta Webhosting 26.12.20-25.03.21'),
(2857, 610, 133, 2030000.00, 0.00, 56, 'By Rapat Panin 11.12.20'),
(2858, 610, 27, 0.00, 3000000.00, 56, 'Pertanggungjawaban UMB Rapat Panin 11.12.20'),
(2859, 610, 11, 970000.00, 0.00, 56, 'Pengembalian Sisa UMB Rapat Panin 11.12.20'),
(2860, 611, 52, 256000.00, 0.00, 56, 'PBY SEMBAKO BOBBY KE TRANSFORMASI JANNAH ABADI'),
(2861, 611, 11, 0.00, 256000.00, 56, 'PBY SEMBAKO BOBBY KE TRANSFORMASI JANNAH ABADI'),
(2862, 612, 136, 5000000.00, 0.00, 56, 'Sumbangan Duka Cita Kary an Indra'),
(2863, 612, 4, 0.00, 5000000.00, 56, 'Sumbangan Duka Cita Kary an Indra'),
(2864, 613, 93, 600000.00, 0.00, 0, 'Krs Sisa Gaji Deb Pens an Eunice Ep Sahelang'),
(2865, 613, 4, 0.00, 600000.00, 0, 'Krs Sisa Gaji Deb Pens an Eunice Ep Sahelang'),
(2869, 616, 125, 300000.00, 0.00, 20, 'By Internet Cab Jombang'),
(2870, 616, 4, 0.00, 300000.00, 20, 'By Internet Cab Jombang'),
(2871, 617, 125, 300000.00, 0.00, 38, 'By Internet Cab Pontianak'),
(2872, 617, 123, 54600.00, 0.00, 38, 'By Listrik Cab Pontianak'),
(2873, 617, 133, 25000.00, 0.00, 38, 'By Kirim dokumen Cab Pontianak'),
(2874, 617, 133, 22000.00, 0.00, 38, 'Pembelian Aqua Cab Pontianak'),
(2875, 617, 4, 0.00, 401600.00, 38, 'By Opr Cab Pontianak'),
(2876, 618, 123, 502500.00, 0.00, 17, 'By Listrik Cab JKT 3'),
(2877, 618, 4, 0.00, 502500.00, 17, 'By Listrik Cab JKT 3'),
(2878, 618, 133, 300000.00, 0.00, 17, 'Gaji OB Cab JKT 3'),
(2879, 618, 4, 0.00, 300000.00, 17, 'Gaji OB Cab JKT 3'),
(2880, 619, 15, 40000000.00, 0.00, 0, 'Pemindahbukuan Dana ke Mandiri'),
(2881, 619, 133, 30000.00, 0.00, 0, 'By Trf Pemindahbukuan Dana ke Mandiri'),
(2882, 619, 4, 0.00, 40030000.00, 0, 'Pemindahbukuan Dana ke Mandiri'),
(2883, 620, 11, 40000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA DARI REK 439'),
(2884, 620, 15, 0.00, 40000000.00, 0, 'PEMINDAHBUKUAN DANA DARI REK 439'),
(2885, 621, 52, 8425000.00, 0.00, 56, 'KSU GG TERM 1 AUDIT KE KANTOR AKUNTAN PUBLIK KURNIAWAN'),
(2886, 621, 133, 650000.00, 0.00, 56, 'KSU GG TERM 1 AUDIT KE KANTOR AKUNTAN PUBLIK KURNIAWAN'),
(2887, 621, 11, 0.00, 9075000.00, 56, 'KSU GG TERM 1 AUDIT KE KANTOR AKUNTAN PUBLIK KURNIAWAN'),
(2888, 622, 122, 174930.00, 0.00, 9, 'By BBM Cab Blitar'),
(2889, 622, 127, 98800.00, 0.00, 9, 'By ATK Cab Blitar');
INSERT INTO `journal_voucher_det` (`journal_voucher_detid`, `journal_voucher_id`, `jns_akun_id`, `debit`, `credit`, `jns_cabangid`, `itemnote`) VALUES
(2890, 622, 133, 18000.00, 0.00, 9, 'By kirim berkas Cab Blitar'),
(2891, 622, 4, 0.00, 291730.00, 9, 'By Opr Cab Blitar'),
(2892, 623, 133, 70000.00, 0.00, 14, ''),
(2893, 623, 4, 0.00, 70000.00, 14, ''),
(2894, 624, 15, 10000000.00, 0.00, 0, 'PEMINDAHAN BUKU DANA KE MANDIRI'),
(2895, 624, 133, 7500.00, 0.00, 0, 'BY TRF PEMINDAHAN BUKU DANA KE MANDIRI'),
(2896, 624, 4, 0.00, 10007500.00, 0, 'PEMINDAHAN BUKU DANA KE MANDIRI '),
(2897, 625, 123, 250000.00, 0.00, 52, 'BY LISTRIK DAN AIR '),
(2898, 625, 125, 150000.00, 0.00, 52, 'BY PAKET DATA DAN TELEPON '),
(2899, 625, 133, 36000.00, 0.00, 52, 'BY PENGIRIMAN BERKAS'),
(2900, 625, 127, 25000.00, 0.00, 52, 'BY ISI PRINTER '),
(2901, 625, 4, 0.00, 461000.00, 52, 'BY OPR CAB TANJUNG PINANG '),
(2902, 626, 27, 4000000.00, 0.00, 0, 'BY UMB RAPAT PANIN'),
(2903, 626, 11, 0.00, 4000000.00, 0, 'UMB RAPAT PANIN'),
(2904, 627, 11, 10000000.00, 0.00, 0, 'PEMINDAHAN BUKU DARI 439'),
(2905, 627, 15, 0.00, 10000000.00, 0, 'PEMINDAHAN BUKU DARI 439'),
(2906, 628, 11, 2739850.00, 0.00, 0, 'PERTANGGUNGJAWABAN UMB PANIN'),
(2907, 628, 133, 1260150.00, 0.00, 0, 'PERTANGGUNGJAWABAN UMB PANIN'),
(2908, 628, 27, 0.00, 4000000.00, 0, 'PERTANGGUNGJAWABAN UMB PANIN'),
(2909, 629, 126, 1072602.00, 0.00, 0, 'BUNGA DAN PAJAK GIRO'),
(2910, 629, 4, 0.00, 1072602.00, 0, 'BUNGA DAN PAJAK GIRO'),
(2911, 629, 171, 5363013.00, 0.00, 0, 'BUNGA DAN PAJAK GIRO'),
(2912, 629, 4, 0.00, 5363013.00, 0, 'BUNGA DAN PAJAK GIRO'),
(2913, 630, 4, 0.00, 1000000000.00, 0, 'PENURUNAN MTT SWAMITRA HI '),
(2914, 630, 95, 100000000.00, 0.00, 0, 'PENURUNAN MTT SWAMITRA HI '),
(2915, 631, 93, 67663918.00, 0.00, 0, 'TALANGAN ANGSURAN PENS DES 2020'),
(2916, 631, 4, 0.00, 67663918.00, 0, 'TALANGAN ANGSURAN PENS DES 2020'),
(2917, 632, 125, 1500000.00, 0.00, 0, 'BY PULSA BULANAN DES 2020 '),
(2918, 632, 4, 0.00, 1500000.00, 0, 'BY PULSA BULANAN DES 2020 '),
(2919, 633, 127, 430000.00, 0.00, 13, 'PBY ATK'),
(2920, 633, 125, 300000.00, 0.00, 13, 'PBY WIFI '),
(2921, 633, 123, 263000.00, 0.00, 13, 'PBY PDAM DAN GAS ALAM'),
(2922, 633, 133, 15000.00, 0.00, 13, ''),
(2923, 633, 4, 0.00, 1008000.00, 13, 'BY OPR CAB CIREBON '),
(2924, 634, 4, 1005000.00, 0.00, 0, 'PBY SEMBAKO A.N DR EDY PRAMANA'),
(2925, 634, 52, 0.00, 1005000.00, 0, 'PBY SEMBAKO A.N DR EDY PRAMANA'),
(2926, 635, 11, 0.00, 179000.00, 0, 'PBY SEMBAKO A.N ABD RAHM'),
(2927, 635, 52, 179000.00, 0.00, 0, 'PBY SEMBAKO A.N ABD RAHM'),
(2928, 636, 11, 4359000.00, 0.00, 0, 'PENGEMBALIAN TALANGAN SEMBAKO DARI TJA'),
(2929, 636, 52, 0.00, 4359000.00, 0, 'PENGEMBALIAN TALANGAN SEMBAKO DARI TJA'),
(2930, 637, 11, 1500000.00, 0.00, 0, 'PENGEMBALIAN KELEBIHAN TRANSFER DARI TJA'),
(2932, 637, 52, 0.00, 1500000.00, 0, 'PENGEMBALIAN KELEBIHAN TRANSFER DARI TJA'),
(2934, 639, 11, 0.00, 2006500.00, 0, 'Pby Biofitro KSU GG 10 Botol'),
(2935, 639, 15, 2000000.00, 0.00, 0, 'Pby Biofitro KSU GG 10 Botol'),
(2936, 639, 133, 6500.00, 0.00, 0, 'by admin bank '),
(2937, 640, 11, 0.00, 657534.00, 0, 'BUNGA HUTANG kpd Anggota KSU GG DES 20 an Marwan'),
(2938, 640, 87, 657534.00, 0.00, 0, 'BUNGA HUTANG kpd Anggota KSU GG DES 20 an Marwan'),
(2939, 641, 11, 0.00, 4802900.00, 0, 'Cicilan Mobil Des 20 ke  ARIF GUSTAMAN'),
(2940, 641, 133, 4800000.00, 0.00, 0, 'Cicilan Mobil Des 20 ke  ARIF GUSTAMAN'),
(2941, 641, 133, 2900.00, 0.00, 0, 'by trf adm bank '),
(2945, 643, 4, 0.00, 2066872.00, 0, 'Konsumsi Rapat Pengurus, Pengawas '),
(2946, 643, 133, 2066872.00, 0.00, 0, 'Konsumsi Rapat Pengurus, Pengawas '),
(2947, 644, 11, 0.00, 824818.00, 0, 'BUNGA HuTANG kpd Anggota KSU GG DES 20 an Nofrizal'),
(2948, 644, 133, 2900.00, 0.00, 0, 'BUNGA HuTANG kpd Anggota KSU GG DES 20 an Nofrizal'),
(2949, 644, 87, 821918.00, 0.00, 0, 'BUNGA HuTANG kpd Anggota KSU GG DES 20 an Nofrizal'),
(2950, 645, 4, 0.00, 270000.00, 0, 'BY OPS CAB ACEH '),
(2951, 645, 133, 270000.00, 0.00, 0, 'BY PENGIRIMAN BERKAS'),
(2952, 649, 98, 371535000.00, 0.00, 0, 'GAJI KARYAWAN DES 2020'),
(2953, 649, 99, 56600000.00, 0.00, 0, 'TRANSPORT KARYAWAN DES 2020'),
(2954, 649, 101, 3100000.00, 0.00, 0, 'TUNJ KINERJA DES 2020'),
(2955, 649, 175, 0.00, 75167.00, 0, 'PEND ADM Piutang Kary An. Tedi Suhendar'),
(2956, 649, 21, 0.00, 1333333.00, 0, 'Piutang Kary An. Tedi Suhendar'),
(2957, 649, 175, 0.00, 50067.00, 0, 'PEND ADM Piutang Karyawan An. LIDYA OKTAVIANA'),
(2958, 649, 21, 0.00, 833333.00, 0, 'Piutang Karyawan An. LIDYA OKTAVIANA'),
(2959, 649, 175, 0.00, 37500.00, 0, 'PEND ADM Piutang Karyawan An. BAMBANG SUSANTO'),
(2960, 649, 21, 0.00, 750000.00, 0, 'Piutang Karyawan An. BAMBANG SUSANTO'),
(2961, 649, 175, 0.00, 35067.00, 0, 'PEND ADM Piutang Karyawan An. I GUSTI NGURAH MADE MURTIKA'),
(2962, 649, 21, 0.00, 583333.00, 0, 'Piutang Karyawan An. I GUSTI NGURAH MADE MURTIKA'),
(2963, 649, 175, 0.00, 20067.00, 0, 'Adm Angsuran Kary An. JOKO INDRA BUDI'),
(2964, 649, 21, 0.00, 333333.00, 0, 'Piutang Kary An. JOKO INDRA BUDI'),
(2965, 649, 175, 0.00, 50000.00, 0, 'ADM ANGSURAN Piutang Kary An. SLAMET SETYAWAN'),
(2966, 649, 21, 0.00, 833333.00, 0, 'Piutang Kary An. SLAMET SETYAWAN'),
(2967, 649, 175, 0.00, 35067.00, 0, 'PEND ADM Piutang Karyawan An. UJANG FUJIANA'),
(2968, 649, 21, 0.00, 583333.00, 0, 'Piutang Karyawan An. UJANG FUJIANA'),
(2969, 649, 175, 0.00, 75000.00, 0, 'Adm Angsuran Kary An. Wan Wahyudi'),
(2970, 649, 21, 0.00, 1250000.00, 0, 'Piutang Karyawan An. Wan Wahyudi'),
(2971, 649, 175, 0.00, 700000.00, 0, 'Adm Angsuran Kary An.muzammil'),
(2972, 649, 21, 0.00, 7291667.00, 0, 'Piutang Kary An. Muzammil'),
(2973, 649, 21, 0.00, 2500000.00, 0, 'Piutang Karyawan An. Jony Nur Efendy'),
(2974, 649, 21, 0.00, 3658000.00, 0, 'Piutang Karyawan An. Anggi Andriansyah'),
(2975, 649, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. BAMBANG TRIONO'),
(2976, 649, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. ARIF GUSTAMAN'),
(2977, 649, 21, 0.00, 500000.00, 0, 'Piutang Karyawan An. EBNU UTORO'),
(2978, 649, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. YUDI GUNTARA'),
(2979, 649, 21, 0.00, 1000000.00, 0, 'Piutang Karyawan An. ARTHA DHARMA'),
(2980, 649, 11, 0.00, 52540500.00, 0, 'PEMBAYARAN GAJI DESEMBER 2020'),
(2981, 649, 4, 0.00, 348314650.00, 0, 'PEMBAYARAN GAJI DESEMBER 2020'),
(2982, 649, 52, 0.00, 4852250.00, 0, 'SEMBAKO KARYAWAN DES 2020'),
(2983, 651, 11, 0.00, 1005000.00, 0, 'PBY SEMBAKO EDDY P'),
(2984, 651, 52, 1005000.00, 0.00, 0, 'PBY SEMBAKO EDDY P'),
(2985, 652, 4, 676000.00, 0.00, 0, 'PBY SEMBAKO A.N M HASAN'),
(2986, 652, 52, 0.00, 676000.00, 0, 'PBY SEMBAKO A.N M HASAN'),
(2987, 653, 4, 0.00, 40030000.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(2988, 653, 15, 40000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(2989, 653, 133, 30000.00, 0.00, 0, 'by tf adm bank '),
(2990, 654, 4, 0.00, 150000.00, 12, 'by ops cilegon '),
(2991, 654, 129, 66000.00, 0.00, 12, 'by materai '),
(2992, 654, 133, 84000.00, 0.00, 12, 'by pengiriman berkas '),
(2993, 655, 11, 40000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(2994, 655, 15, 0.00, 40000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(2995, 656, 11, 0.00, 27050285.00, 0, 'pby bpjstk '),
(2996, 656, 103, 27050285.00, 0.00, 0, 'pby bpjstk '),
(2997, 657, 11, 0.00, 3135000.00, 0, 'PEMBAYARAN WebHOSTINGKE JIMMY'),
(2998, 657, 139, 3135000.00, 0.00, 0, 'PEMBAYARAN WebHOSTINGKE JIMMY'),
(2999, 658, 4, 23107000.00, 0.00, 0, 'PENDAPATAN ADM DROPPING DES 2020'),
(3000, 658, 144, 0.00, 23107000.00, 0, 'PENDAPATAN ADM DROPPING DES 2020'),
(3001, 659, 4, 162000.00, 0.00, 0, 'PENDAPATAN MATERAI'),
(3002, 659, 175, 0.00, 162000.00, 0, 'PENDAPATAN MATERAI'),
(3003, 660, 4, 1465797.00, 0.00, 0, 'PENDAPATAN BAA DESEMBER 2020'),
(3004, 660, 143, 0.00, 1465797.00, 0, 'PENDAPATAN BAA DESEMBER 2020'),
(3007, 662, 11, 0.00, 676000.00, 0, 'PBY  SEMBAKO M HASAN'),
(3008, 662, 52, 676000.00, 0.00, 0, 'PBY  SEMBAKO M HASAN'),
(3012, 664, 4, 0.00, 640500.00, 3, 'by ops atambua '),
(3013, 664, 27, 640500.00, 0.00, 3, 'by ops atambua '),
(3014, 665, 4, 0.00, 332999.00, 44, 'by ops sidoarjo '),
(3015, 665, 133, 117000.00, 0.00, 44, 'by pengiriman berkas'),
(3016, 665, 127, 215999.00, 0.00, 44, 'by isi tinta '),
(3017, 666, 52, 5775000.00, 0.00, 0, 'Pelunasan Aplikasi Keuangan'),
(3018, 666, 133, 6500.00, 0.00, 0, 'By Trf Pelunasan Aplikasi Keuangan'),
(3019, 666, 11, 0.00, 5781500.00, 0, 'Pelunasan Aplikasi Keuangan'),
(3020, 667, 27, 1500000.00, 0.00, 0, 'UMB RAPAT MESTIKA 30.12.2020'),
(3021, 667, 11, 0.00, 1500000.00, 0, 'UMB RAPAT MESTIKA 30.12.2020'),
(3022, 668, 2, 5894400.00, 0.00, 0, 'Pengisian Kas Kecil Periode 14.12.20 s/d 30.12.20'),
(3023, 668, 133, 2614700.00, 0.00, 56, 'Pembelian keperluan kantor pusat GG Jkt'),
(3024, 668, 125, 1444500.00, 0.00, 56, 'By Internet GG Pusat Jkt'),
(3025, 668, 122, 979000.00, 0.00, 56, 'BBM Tol dan Parkir mobil operasional'),
(3026, 668, 123, 503000.00, 0.00, 56, 'By listrik GG Pusat Jkt'),
(3027, 668, 119, 274200.00, 0.00, 56, 'Pembelian Hand sanitiser'),
(3028, 668, 129, 49000.00, 0.00, 56, 'By Materai GG Pusat Jkt'),
(3029, 668, 127, 30000.00, 0.00, 56, 'By ATK GG pusat Jkt'),
(3030, 668, 133, 6500.00, 0.00, 56, 'By Trf'),
(3031, 668, 11, 0.00, 6500.00, 56, 'By Trf'),
(3032, 668, 2, 0.00, 5894400.00, 56, 'Reimbursement Kas Kecil Periode 14.12.20 s/d 30.12.20'),
(3033, 668, 11, 0.00, 5894400.00, 56, 'Pengisian Kas Kecil Periode 14.12.20 s/d 30.12.20'),
(3034, 669, 15, 10000000.00, 0.00, 0, 'Pemindahbukuan Dana Ke Mandiri'),
(3035, 669, 15, 8000000.00, 0.00, 0, 'Pengembalian Talangan Drop Cilegon'),
(3036, 669, 133, 7500.00, 0.00, 0, 'By Trf Pemindahbukuan Dana Ke Mandiri'),
(3037, 669, 4, 0.00, 10007500.00, 0, 'Pemindahbukuan Dana Ke Mandiri'),
(3038, 669, 4, 0.00, 8000000.00, 0, 'PEngembalian Talngan Drop Cilegon'),
(3039, 670, 4, 0.00, 30000.00, 0, 'B.ADM DES 2020 ACCOUNT NO.1001343439'),
(3040, 670, 133, 30000.00, 0.00, 0, 'B.ADM DES 2020 ACCOUNT NO.1001343439'),
(3041, 671, 4, 507139.00, 0.00, 0, 'PEMB. JASA GIRO DES 2020 - 1001343439'),
(3042, 671, 175, 0.00, 507139.00, 0, 'PEMB. JASA GIRO DES 2020 - 1001343439'),
(3043, 672, 4, 0.00, 101427.00, 0, 'PAJAK JASA GIRO DES 2020 - 1001343439'),
(3044, 672, 126, 101427.00, 0.00, 0, 'PAJAK JASA GIRO DES 2020 - 1001343439'),
(3045, 673, 4, 6000.00, 0.00, 0, 'B.MATERAI DES 2020 ACC NO.1001343439'),
(3046, 673, 129, 0.00, 6000.00, 0, 'B.MATERAI DES 2020 ACC NO.1001343439'),
(3047, 674, 4, 0.00, 10007500.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3048, 674, 15, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3049, 675, 52, 0.00, 1050000.00, 0, 'PBY SEMBAKO DR  AGNY IRSYAD  UTK GILANG GEMILA'),
(3050, 674, 133, 7500.00, 0.00, 0, 'by tf adm bank '),
(3051, 675, 4, 1050000.00, 0.00, 0, 'PBY SEMBAKO DR  AGNY IRSYAD  UTK GILANG GEMILA'),
(3052, 676, 11, 49253.00, 0.00, 0, 'BUNGA, BY ADM DAN PAJAK REK TABUNGAN DES 2020'),
(3053, 676, 126, 0.00, 6125.00, 0, 'pajak des 2020'),
(3054, 676, 133, 0.00, 12500.00, 0, 'by adm des 2020 '),
(3055, 677, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3056, 676, 175, 0.00, 30628.00, 0, 'bunga des 2020 '),
(3057, 677, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3058, 678, 11, 0.00, 11497090.00, 0, 'pby bpjs kesehatan'),
(3059, 678, 102, 11497090.00, 0.00, 0, 'pby bpjs kesehatan'),
(3060, 679, 4, 41754469.00, 0.00, 0, 'PENURUNAN PIUTANG DES 2020'),
(3061, 680, 143, 0.00, 995300685.00, 0, 'PENDAPATAN BAA JAN 2021'),
(3062, 679, 15, 0.00, 41754469.00, 0, 'PENURUNAN PIUTANG DES 2020'),
(3063, 680, 4, 995300685.00, 0.00, 0, 'PENDAPATAN BAA JAN 2021'),
(3064, 681, 4, 26736166.00, 0.00, 0, 'PENDAPATAN  BUNGA DEB XTRA JAN 2021'),
(3065, 681, 145, 0.00, 26736166.00, 0, 'PENDAPATAN  BUNGA DEB XTRA JAN 2021'),
(3066, 682, 11, 8500.00, 0.00, 0, 'MONTHLY CARD CHARGE 0004617003724020525'),
(3067, 682, 133, 0.00, 8500.00, 0, 'MONTHLY CARD CHARGE 0004617003724020525'),
(3071, 684, 11, 0.00, 3002900.00, 0, 'PBY BIOFITRO KSU GG 15 BOTOL'),
(3072, 684, 15, 3000000.00, 0.00, 0, 'PBY BIOFITRO KSU GG 15 BOTOL'),
(3073, 684, 133, 2900.00, 0.00, 0, 'BY TF BIOFITRO KSU GG 15 BOTOL'),
(3074, 685, 4, 0.00, 200000.00, 33, 'by ops palembang '),
(3075, 685, 127, 200000.00, 0.00, 33, 'modem internet '),
(3076, 686, 11, 0.00, 2506500.00, 0, 'PEMINDAHAN DANA A.N DARWONO'),
(3077, 686, 133, 6500.00, 0.00, 0, 'BY TF PEMINDAHAN DANA A.N DARWONO'),
(3078, 686, 15, 2500000.00, 0.00, 0, 'PEMINDAHAN DANA A.N DARWONO'),
(3079, 687, 11, 0.00, 829500.00, 0, 'FEE PELUNASAN SWAMITRA HI'),
(3080, 687, 133, 6500.00, 0.00, 0, 'BY TF FEE PELUNASAN SWAMITRA HI'),
(3081, 687, 13, 823000.00, 0.00, 0, 'FEE PELUNASAN SWAMITRA HI'),
(3082, 688, 4, 0.00, 240000.00, 14, 'by opr cab denpasar '),
(3083, 688, 129, 240000.00, 0.00, 14, 'BY MATERAI '),
(3085, 690, 133, 250000.00, 0.00, 23, 'by swab antigen '),
(3086, 690, 4, 0.00, 250000.00, 23, 'by opr kopang '),
(3087, 691, 4, 888200.00, 0.00, 0, 'PENDAPATAN  BUNGA DEB XTRA JAN 2021'),
(3088, 691, 145, 0.00, 888200.00, 0, 'PENDAPATAN  BUNGA DEB XTRA JAN 2021'),
(3091, 693, 4, 0.00, 1368000.00, 0, 'pembelian aki mobil operasional '),
(3092, 693, 33, 1368000.00, 0.00, 0, 'pembelian aki mobil operasional '),
(3093, 694, 4, 0.00, 1500000.00, 0, 'PINJAMAN KARYAWAN A,N TEDI SUHENDAR'),
(3094, 694, 21, 1500000.00, 0.00, 0, 'PINJAMAN KARYAWAN A,N TEDI SUHENDAR'),
(3095, 695, 4, 0.00, 501000.00, 0, 'By Opr Cab Pontianak '),
(3096, 695, 127, 150000.00, 0.00, 0, 'pembelian cstridge blsck hp 680 '),
(3097, 695, 123, 40500.00, 0.00, 0, 'pembayaran tagihan pdam '),
(3098, 695, 125, 310500.00, 0.00, 0, 'pembayaran tagihan telkom '),
(3099, 696, 123, 2000000.00, 0.00, 0, 'PEMBAYARAN TELKOM BULAN JANUARI  2021'),
(3100, 696, 11, 0.00, 2000000.00, 0, 'PEMBAYARAN TELKOM BULAN JANUARI  2021'),
(3101, 697, 11, 0.00, 240000000.00, 0, 'PEMINDAHBUKUAN DANA KE JASA MADANI'),
(3102, 697, 15, 240000000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE JASA MADANI'),
(3103, 698, 11, 0.00, 23842719.00, 0, 'PEMBAYARAN PPH 21 DESEMBER 2020'),
(3104, 698, 48, 23842719.00, 0.00, 0, 'PEMBAYARAN PPH 21 DESEMBER 2020'),
(3105, 699, 15, 65000.00, 0.00, 0, 'PBY MADU ASLI 1000GR                DIANA LESTARI'),
(3106, 699, 4, 0.00, 65000.00, 0, 'PBY MADU ASLI 1000GR                DIANA LESTARI'),
(3107, 700, 4, 5010241.00, 0.00, 0, 'PENDAPATAN BUNGA DEB PLAT  JAN 2021'),
(3108, 700, 183, 0.00, 5010241.00, 0, 'PENDAPATAN BUNGA DEB PLAT  JAN 2021'),
(3109, 701, 4, 1154552.00, 0.00, 0, 'PENDAPATAN BAA DEB PLAT  JAN 2021'),
(3110, 701, 185, 0.00, 1154552.00, 0, 'PENDAPATAN BAA DEB PLAT  JAN 2021'),
(3111, 702, 4, 0.00, 5049113.00, 0, 'pembayaran pokok Deb plat  jan 2021     '),
(3112, 702, 178, 5049113.00, 0.00, 0, 'pembayaran pokok Deb plat  jan 2021     '),
(3113, 703, 4, 0.00, 230000.00, 0, 'biaya membership aplikasi zoom'),
(3114, 703, 131, 230000.00, 0.00, 0, 'biaya membership aplikasi zoom'),
(3117, 705, 4, 0.00, 165532.00, 46, 'by opr cab sleman'),
(3118, 705, 133, 15000.00, 0.00, 46, 'by pengiriman dokumen md an soenarijah '),
(3119, 705, 123, 65700.00, 0.00, 46, 'by pdam dan listrik bln jan 2021'),
(3120, 705, 123, 84832.00, 0.00, 46, 'by pdam dan listrik bln des 2020'),
(3121, 706, 133, 250000.00, 0.00, 24, 'BY OPR CAB KUPANG '),
(3122, 706, 4, 0.00, 250000.00, 24, 'BY swab antigen cab kupang '),
(3123, 708, 113, 138375.00, 0.00, 47, 'by servis laptop cab solo '),
(3124, 708, 68, 96000.00, 0.00, 47, 'by flaging deb cab solo '),
(3125, 708, 4, 0.00, 234375.00, 47, 'by opr cab solo '),
(3126, 709, 139, 2000000.00, 0.00, 0, 'By Swab dan Vitamin swamitra tambun '),
(3127, 709, 133, 6500.00, 0.00, 0, 'By tf Swab dan Vitamin swamitra tambun '),
(3128, 709, 11, 0.00, 2006500.00, 0, 'By Swab dan Vitamin swamitra tambun '),
(3129, 710, 133, 2000000.00, 0.00, 0, 'MEETING PENGURUS'),
(3130, 710, 11, 0.00, 2000000.00, 0, 'MEETING PENGURUS'),
(3131, 711, 11, 0.00, 1152240.00, 0, 'KSU GG PBY SEMBAKO'),
(3132, 711, 133, 2900.00, 0.00, 0, 'by tf KSU GG PBY SEMBAKO'),
(3133, 711, 15, 1149340.00, 0.00, 0, 'KSU GG PBY SEMBAKO'),
(3134, 712, 11, 0.00, 2006500.00, 0, 'By listrik kantor '),
(3135, 712, 133, 6500.00, 0.00, 0, 'by tf By listrik kantor '),
(3136, 712, 123, 2000000.00, 0.00, 0, 'By listrik kantor '),
(3137, 713, 11, 0.00, 5000000.00, 0, 'pemindahbukuan ke bank mantap'),
(3138, 713, 15, 5000000.00, 0.00, 0, 'pemindahbukuan ke bank mantap'),
(3139, 714, 52, 128500.00, 0.00, 0, 'PBY SEMBAKO DR ABDUL RACHMA UTK GILANG GEMILANG'),
(3140, 714, 4, 0.00, 128500.00, 0, 'PBY SEMBAKO DR ABDUL RACHMA UTK GILANG GEMILANG'),
(3141, 715, 93, 63186896.00, 0.00, 0, 'TALANGAN ANGSURAN JAN 2021'),
(3142, 715, 4, 0.00, 63186896.00, 0, 'TALANGAN ANGSURAN JAN 2021'),
(3143, 716, 4, 0.00, 300000.00, 0, 'kkr by transport Diana lestari '),
(3144, 716, 99, 300000.00, 0.00, 0, 'kkr by transport Diana lestari '),
(3145, 717, 15, 0.00, 25000000.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3146, 717, 11, 25000000.00, 0.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3147, 718, 15, 0.00, 25000000.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3148, 718, 11, 25000000.00, 0.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3149, 719, 11, 0.00, 706500.00, 0, 'pby token listrik '),
(3150, 719, 123, 706500.00, 0.00, 0, 'pby token listrik '),
(3151, 720, 4, 0.00, 15000000.00, 20, 'pengajuan by sewa kantor cab jombang '),
(3152, 720, 30, 15000000.00, 0.00, 20, 'pengajuan by sewa kantor cab jombang '),
(3153, 721, 4, 0.00, 15000000.00, 38, 'pengajuan by sewa kantor cab pontianak '),
(3154, 721, 30, 15000000.00, 0.00, 38, 'pengajuan by sewa kantor cab pontianak '),
(3155, 722, 4, 0.00, 170000.00, 1, 'By Opr Cab Aceh                 '),
(3156, 722, 133, 50000.00, 0.00, 1, 'by pengiriman berkas md an rusli '),
(3157, 722, 133, 120000.00, 0.00, 1, 'by pengiriman dokumen '),
(3158, 723, 4, 0.00, 65000.00, 0, 'PBY MADU ASLI 1000GR DIANA LESTARI'),
(3159, 723, 15, 65000.00, 0.00, 0, 'PBY MADU ASLI 1000GR DIANA LESTARI'),
(3160, 724, 4, 0.00, 13700000.00, 23, 'pengajuan by sewa kantor cab kopang'),
(3161, 724, 30, 13500000.00, 0.00, 23, 'by sewa kantor cab kopang'),
(3162, 724, 123, 200000.00, 0.00, 23, 'by pdam cab kopang '),
(3163, 725, 133, 76000.00, 0.00, 24, 'by pengiriman berkas klaim an amabrita, ahmatu '),
(3164, 725, 4, 0.00, 76000.00, 24, 'by opr cabang kupang '),
(3165, 726, 4, 0.00, 15000000.00, 40, 'pengajuan by sewa kantor cab purwokerto '),
(3166, 726, 30, 15000000.00, 0.00, 40, 'by sewa kantor cab purwokerto '),
(3167, 727, 133, 1743300.00, 0.00, 57, 'by ongkos bln des 20/jan 21'),
(3168, 727, 133, 901000.00, 0.00, 57, 'by internet bln des 20/jan 21'),
(3169, 727, 113, 378000.00, 0.00, 57, 'by talangan kantor cab malang '),
(3170, 727, 133, 257749.00, 0.00, 57, 'by cug bp muzammil bln des 220/jan 21'),
(3171, 727, 123, 127800.00, 0.00, 57, 'by pdam bln des 20/ jan 21'),
(3172, 727, 4, 0.00, 3407849.00, 57, 'By Opr Cab Malang            '),
(3173, 728, 4, 0.00, 943000.00, 13, 'by ops cab cirebon '),
(3174, 728, 125, 300000.00, 0.00, 13, 'by wifi cab cirebon '),
(3175, 728, 123, 263000.00, 0.00, 13, 'by pdam dan by listrik '),
(3176, 728, 127, 380000.00, 0.00, 13, 'by alat tulis kantor '),
(3177, 729, 11, 0.00, 422900.00, 0, 'by pembelian vit dan suplemen swamitra curug '),
(3178, 729, 139, 420000.00, 0.00, 0, 'by pembelian vit dan suplemen swamitra curug '),
(3179, 729, 133, 2900.00, 0.00, 0, 'by tf pembelian vit dan suplemen swamitra curug '),
(3180, 730, 139, 430000.00, 0.00, 0, 'by pembelian vit dan suplemen swamitra kramatjati'),
(3181, 730, 133, 2900.00, 0.00, 0, 'by tf pembelian vit dan suplemen swamitra kramatjati'),
(3182, 730, 11, 0.00, 432900.00, 0, 'by pembelian vit dan suplemen swamitra kramatjati'),
(3183, 731, 15, 0.00, 25000000.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3184, 731, 11, 25000000.00, 0.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3185, 732, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DR SUTRISNO'),
(3186, 732, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DR SUTRISNO'),
(3187, 733, 15, 0.00, 25000000.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3188, 733, 11, 25000000.00, 0.00, 0, 'PEMINDAHBUKUAN DR JEFRI MARLON'),
(3189, 734, 4, 0.00, 83000000.00, 16, 'penurunan mtt swamitra harapan indah '),
(3190, 734, 25, 83000000.00, 0.00, 16, 'penurunan mtt swamitra harapan indah '),
(3191, 735, 11, 0.00, 679452.00, 0, 'BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN MARWAN'),
(3192, 735, 87, 679452.00, 0.00, 0, 'BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN MARWAN'),
(3193, 736, 133, 250000.00, 0.00, 0, 'by swab antigen a.n rifaldi '),
(3194, 736, 4, 0.00, 250000.00, 0, 'by swab antigen a.n rifaldi '),
(3195, 737, 133, 1545000.00, 0.00, 0, 'by swab antigen 6 org '),
(3196, 737, 4, 0.00, 1545000.00, 0, 'by swab antigen 6 org '),
(3197, 738, 133, 250000.00, 0.00, 0, 'by swab antigen a.n ebnu utoro '),
(3198, 738, 4, 0.00, 250000.00, 0, 'by swab antigen a.n ebnu utoro '),
(3199, 739, 15, 20015000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3200, 739, 4, 0.00, 20015000.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3201, 740, 133, 259000.00, 0.00, 0, 'by swab antigen a.n ridwan alviansyah '),
(3202, 740, 4, 0.00, 259000.00, 0, 'by swab antigen a.n ridwan alviansyah '),
(3203, 741, 4, 0.00, 20015000.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3204, 741, 15, 20015000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3205, 742, 4, 0.00, 20015000.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3206, 742, 15, 20015000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3207, 743, 4, 0.00, 828500.00, 0, 'By Opr Cab Jakarta 3         '),
(3208, 743, 133, 26000.00, 0.00, 0, 'by pengiriman dokumen cab jkt 3'),
(3209, 743, 123, 502500.00, 0.00, 0, 'by istrik cab jkt 3 '),
(3210, 743, 133, 300000.00, 0.00, 0, 'gaji ob jkt 3 '),
(3211, 744, 4, 0.00, 300000.00, 20, 'by opr cab jombang '),
(3212, 744, 125, 300000.00, 0.00, 20, 'by indihome cab jombang '),
(3213, 745, 4, 0.00, 30000.00, 0, 'BY ADM TF PEMINDAHAN BUKUAN A.N HIDAYATULLOH'),
(3214, 745, 133, 30000.00, 0.00, 0, 'BY ADM TF PEMINDAHAN BUKUAN A.N HIDAYATULLOH'),
(3215, 746, 4, 0.00, 30000.00, 0, 'BY ADM TF PEMINDAHAN BUKUAN A.N JEFRI MARLON'),
(3216, 746, 133, 30000.00, 0.00, 0, 'BY ADM TF PEMINDAHAN BUKUAN A.N JEFRI MARLON'),
(3217, 747, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3218, 747, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3219, 748, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3220, 748, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3221, 759, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3222, 759, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3223, 760, 11, 0.00, 100000000.00, 0, 'PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN MARWAN'),
(3224, 760, 58, 100000000.00, 0.00, 0, 'PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN MARWAN'),
(3225, 761, 11, 0.00, 852215.00, 0, 'BY TF BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL'),
(3226, 761, 87, 849315.00, 0.00, 0, 'BY TF BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL'),
(3227, 761, 133, 2900.00, 0.00, 0, 'BY adm TF BUNGA HUTANG KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL'),
(3231, 763, 11, 0.00, 125002900.00, 0, 'BY TF PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL'),
(3232, 763, 58, 125000000.00, 0.00, 0, 'BY TF PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL'),
(3233, 763, 133, 2900.00, 0.00, 0, 'BY adm TF PENCAIRAN SIMPANAN BERJANGKA  KPD ANGGOTA KSU GG JAN 21 AN NOVRIZAL'),
(3236, 765, 125, 1300000.00, 0.00, 0, 'by pulsa operasional jan 2021 '),
(3237, 765, 4, 0.00, 1300000.00, 0, 'by pulsa operasional jan 2021 '),
(3238, 766, 133, 518000.00, 0.00, 0, 'by swab antigen 2 org '),
(3239, 766, 4, 0.00, 518000.00, 0, 'by swab antigen 2 org '),
(3240, 767, 4, 0.00, 543000.00, 40, 'By Opr Cab Purwokerto          '),
(3241, 767, 133, 119000.00, 0.00, 40, 'by pengiriman berkas '),
(3242, 767, 123, 424000.00, 0.00, 40, 'by listrik dan pdam '),
(3243, 768, 133, 250000.00, 0.00, 0, 'by swab antigen a.n arif gustaman'),
(3244, 768, 4, 0.00, 250000.00, 0, 'by swab antigen a.n arif gustaman'),
(3245, 769, 4, 660000.00, 0.00, 0, 'PBY SEMBAKO DR EDDY P UNTUK GG'),
(3246, 769, 52, 0.00, 660000.00, 0, 'PBY SEMBAKO DR EDDY P UNTUK GG'),
(3247, 770, 11, 4802900.00, 0.00, 0, 'CICILAN MOBIL JAN 21 KE  ARIF GUSTAMAN'),
(3248, 770, 133, 0.00, 2900.00, 0, 'by tf CICILAN MOBIL JAN 21 KE  ARIF GUSTAMAN'),
(3249, 770, 133, 0.00, 4800000.00, 0, 'CICILAN MOBIL JAN 21 KE  ARIF GUSTAMAN'),
(3250, 771, 133, 2900.00, 0.00, 0, 'by tf UMB KAS'),
(3251, 771, 27, 6000000.00, 0.00, 0, 'UMB KAS'),
(3252, 771, 11, 0.00, 6002900.00, 0, 'UMB KAS'),
(3253, 772, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3254, 772, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3257, 774, 133, 30000.00, 0.00, 0, 'B.ADM JAN 2021 ACCOUNT NO.1001343439'),
(3258, 774, 4, 0.00, 30000.00, 0, 'B.ADM JAN 2021 ACCOUNT NO.1001343439'),
(3259, 775, 175, 0.00, 886323.00, 0, 'PEMB. JASA GIRO JAN 2021 - 1001343439'),
(3260, 775, 4, 886323.00, 0.00, 0, 'PEMB. JASA GIRO JAN 2021 - 1001343439'),
(3261, 776, 126, 177264.00, 0.00, 0, 'PAJAK JASA GIRO JAN 2021 - 1001343439'),
(3262, 776, 4, 0.00, 177264.00, 0, 'PAJAK JASA GIRO JAN 2021 - 1001343439'),
(3263, 777, 2, 6000000.00, 0.00, 56, 'Reimbusement kas kecil periode 4.1.2021 s/d 29.1.2021'),
(3264, 777, 133, 2798500.00, 0.00, 56, 'pembelian keprluan kantor pusat gg jkt '),
(3265, 777, 122, 600000.00, 0.00, 56, 'pengisian bbm  toll dan parkir mobil '),
(3266, 777, 125, 1435500.00, 0.00, 56, 'by indihome kantor '),
(3267, 777, 123, 503000.00, 0.00, 56, 'pembelian listrik kantor '),
(3268, 777, 129, 400000.00, 0.00, 56, 'pembelian materai '),
(3269, 777, 119, 263000.00, 0.00, 56, 'kebutuhan pantry '),
(3270, 777, 2, 0.00, 6000000.00, 56, 'Reimbusement kas kecil periode 4.1.2021 s/d 29.1.2021'),
(3271, 777, 11, 0.00, 6000000.00, 56, 'pengisian kas kecil periode 4.1.2021 s/d 29.1.2021'),
(3272, 781, 0, 0.00, 0.00, NULL, ''),
(3273, 785, 0, 0.00, 0.00, NULL, ''),
(3274, 789, 0, 0.00, 0.00, NULL, ''),
(3275, 793, 0, 0.00, 0.00, NULL, ''),
(3276, 797, 0, 0.00, 0.00, NULL, ''),
(3277, 793, 0, 0.00, 0.00, NULL, ''),
(3278, 793, 0, 0.00, 0.00, NULL, ''),
(3279, 797, 0, 0.00, 0.00, NULL, ''),
(3280, 797, 0, 0.00, 0.00, NULL, ''),
(3281, 797, 0, 0.00, 0.00, NULL, ''),
(3282, 797, 0, 0.00, 0.00, NULL, ''),
(3283, 793, 0, 0.00, 0.00, NULL, ''),
(3284, 797, 0, 0.00, 0.00, NULL, ''),
(3285, 793, 0, 0.00, 0.00, NULL, ''),
(3286, 797, 0, 0.00, 0.00, NULL, ''),
(3287, 793, 0, 0.00, 0.00, NULL, ''),
(3288, 797, 0, 0.00, 0.00, NULL, ''),
(3289, 797, 0, 0.00, 0.00, NULL, ''),
(3290, 797, 0, 0.00, 0.00, NULL, ''),
(3291, 797, 0, 0.00, 0.00, NULL, ''),
(3292, 793, 0, 0.00, 0.00, NULL, ''),
(3293, 797, 0, 0.00, 0.00, NULL, ''),
(3294, 793, 0, 0.00, 0.00, NULL, ''),
(3295, 797, 0, 0.00, 0.00, NULL, ''),
(3296, 797, 0, 0.00, 0.00, NULL, ''),
(3297, 797, 0, 0.00, 0.00, NULL, ''),
(3298, 793, 0, 0.00, 0.00, NULL, ''),
(3299, 801, 0, 0.00, 0.00, NULL, ''),
(3300, 805, 0, 0.00, 0.00, NULL, ''),
(3301, 809, 0, 0.00, 0.00, NULL, ''),
(3304, 812, 4, 72751513.00, 0.00, 0, 'PENURUNAN PIUTANG PENSIUN JAN 2021'),
(3305, 812, 15, 0.00, 72751513.00, 0, 'PENURUNAN PIUTANG PENSIUN JAN 2021'),
(3306, 813, 52, 0.00, 1183500.00, 0, 'PBY SEMBAKO DARI AGNY IRSYAD'),
(3307, 813, 4, 1183500.00, 0.00, 0, 'PBY SEMBAKO DARI AGNY IRSYAD'),
(3313, 815, 127, 158600.00, 0.00, 0, 'alat tulis kantor '),
(3314, 815, 125, 102000.00, 0.00, 0, 'by internet '),
(3315, 815, 129, 97500.00, 0.00, 0, 'by materai '),
(3316, 815, 133, 64500.00, 0.00, 0, 'by resi pengiriman '),
(3317, 815, 4, 0.00, 422600.00, 0, 'By Opr Cab Madiun  '),
(3318, 816, 145, 0.00, 27624366.00, 0, 'PEMBAYARAN BUNGA DEB XTRA FEB 2021'),
(3319, 816, 4, 27624366.00, 0.00, 0, 'PEMBAYARAN BUNGA DEB XTRA FEB 2021'),
(3320, 817, 27, 640000.00, 0.00, 3, 'Pengajuan UMB Operasional Atambua '),
(3321, 817, 4, 0.00, 640000.00, 3, 'Pengajuan UMB Operasional Atambua '),
(3322, 818, 27, 0.00, 640000.00, 3, 'PERTANGGUNGJAWABAN BY OPR CAB ATAMBUA'),
(3323, 819, 127, 200000.00, 0.00, 33, 'pembelian modem '),
(3324, 818, 125, 159500.00, 0.00, 3, 'by internet '),
(3325, 818, 123, 405500.00, 0.00, 3, 'by listrik '),
(3326, 818, 133, 75000.00, 0.00, 3, 'by iuran sampah cab atambua '),
(3327, 819, 119, 125000.00, 0.00, 33, 'pembelian perlengkapan kantor '),
(3328, 819, 4, 0.00, 325000.00, 33, 'By Opr Cab Palembang'),
(3331, 821, 139, 250000.00, 0.00, 0, 'By pembelian vit cab malabar '),
(3332, 821, 133, 2900.00, 0.00, 0, 'By tf pembelian vit cab malabar '),
(3333, 821, 11, 0.00, 252900.00, 0, 'By pembelian vit cab malabar '),
(3334, 822, 133, 8500.00, 0.00, 0, 'MONTHLY CARD CHARGE 0004617003724020525'),
(3335, 822, 11, 0.00, 8500.00, 0, 'MONTHLY CARD CHARGE 0004617003724020525'),
(3336, 823, 103, 25586706.00, 0.00, 0, 'PBY BPJSTK '),
(3337, 823, 11, 0.00, 25586706.00, 0, 'PBY BPJSTK '),
(3340, 825, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3341, 825, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3342, 826, 15, 0.00, 10000000.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3343, 826, 11, 10000000.00, 0.00, 0, 'PEMINDAHBUKUAN DARI 439'),
(3344, 827, 102, 11442090.00, 0.00, 0, 'pby BPJSKesehatan '),
(3345, 827, 11, 0.00, 11442090.00, 0, 'pby BPJSKesehatan '),
(3346, 828, 139, 7500000.00, 0.00, 0, 'UANG TALI KASIH  Diana '),
(3347, 828, 4, 0.00, 7500000.00, 0, 'UANG TALI KASIH  Diana '),
(3348, 829, 52, 0.00, 1225000.00, 0, 'TRF DR AMRIZAL BANK MANDIRI (SEMBAKO)'),
(3349, 829, 4, 1225000.00, 0.00, 0, 'TRF DR AMRIZAL BANK MANDIRI (SEMBAKO)'),
(3350, 830, 21, 500000.00, 0.00, 0, 'PIUTANG KARYAWAN A.N EBNU UTORO'),
(3351, 830, 4, 0.00, 500000.00, 0, 'PIUTANG KARYAWAN A.N EBNU UTORO'),
(3352, 831, 133, 111000.00, 0.00, 55, 'By Opr Cab Tomohon'),
(3353, 831, 4, 0.00, 111000.00, 55, 'By Opr Cab Tomohon'),
(3354, 832, 4, 0.00, 20025000.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3355, 832, 15, 20025000.00, 0.00, 0, 'PEMINDAHBUKUAN DANA KE MANDIRI'),
(3356, 833, 4, 0.00, 250000.00, 0, 'by swab antigen a.n linna susilawaty'),
(3357, 833, 133, 250000.00, 0.00, 0, 'by swab antigen a.n linna susilawaty'),
(3358, 834, 133, 23000.00, 0.00, 38, 'by air mineral '),
(3359, 834, 125, 300000.00, 0.00, 38, 'by telkom '),
(3360, 834, 123, 22500.00, 0.00, 38, 'by token listrik '),
(3361, 834, 129, 18000.00, 0.00, 38, 'by materai '),
(3362, 834, 4, 0.00, 404000.00, 38, 'By Opr Cab Pontianak'),
(3363, 834, 123, 40500.00, 0.00, 38, 'by pdam '),
(3364, 835, 133, 76000.00, 0.00, 24, 'by pengiriman berkas klaim '),
(3365, 835, 4, 0.00, 76000.00, 24, 'By Opr Cab Kupang');

-- --------------------------------------------------------

--
-- Table structure for table `kategori_asset`
--

CREATE TABLE `kategori_asset` (
  `kategori_asset_id` int(5) NOT NULL,
  `kategori_asset` varchar(150) CHARACTER SET latin1 NOT NULL DEFAULT '0',
  `accpenyusutan` varchar(30) CHARACTER SET latin1 DEFAULT NULL,
  `accakumulasipenyusutan` varchar(30) CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `kategori_asset`
--

INSERT INTO `kategori_asset` (`kategori_asset_id`, `kategori_asset`, `accpenyusutan`, `accakumulasipenyusutan`) VALUES
(1, 'KOMPUTER', '607.01.01', '147.01.02'),
(3, 'MONITOR', '607.01.01', '147.01.02'),
(4, 'NOTEBOOK', '607.01.01', '147.01.02'),
(5, 'KOMPUTER HARDWARE', '607.01.01', '147.01.02'),
(6, 'PERALATAN KANTOR', '607.01.01', '147.01.02'),
(7, 'INVENTARIS', '607.01.01', '147.01.02'),
(8, 'BANGUNAN', '607.01.03', '151.01.02');

-- --------------------------------------------------------

--
-- Table structure for table `kelompok_akun`
--

CREATE TABLE `kelompok_akun` (
  `kelompok_akunid` int(11) NOT NULL,
  `nama_kelompok` varchar(50) NOT NULL,
  `no_urut` tinyint(4) NOT NULL DEFAULT 0,
  `parentid` int(11) DEFAULT NULL,
  `status` enum('DEBET','KREDIT') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `kelompok_akun`
--

INSERT INTO `kelompok_akun` (`kelompok_akunid`, `nama_kelompok`, `no_urut`, `parentid`, `status`) VALUES
(1, 'AKTIVA', 1, NULL, 'DEBET'),
(2, 'AKTIVA LANCAR', 2, 1, 'DEBET'),
(3, 'PASIVA', 5, NULL, 'KREDIT'),
(4, 'MODAL', 9, NULL, 'KREDIT'),
(5, 'BEBAN', 2, NULL, 'DEBET'),
(6, 'PENDAPATAN', 1, NULL, 'KREDIT'),
(7, 'CHANNELLING', 0, NULL, ''),
(8, 'AKTIVA TETAP', 3, 1, 'DEBET'),
(9, 'AKTIVA LAIN-LAIN', 4, 1, 'DEBET'),
(10, 'KEWAJIBAN LANCAR', 6, 3, 'KREDIT'),
(11, 'KEWAJIBAN TIDAK LANCAR', 7, 3, 'KREDIT'),
(12, 'KEWAJIBAN LAIN-LAIN', 8, 3, 'KREDIT');

-- --------------------------------------------------------

--
-- Table structure for table `nama_kas_tbl`
--

CREATE TABLE `nama_kas_tbl` (
  `id` bigint(20) NOT NULL,
  `nama` varchar(225) CHARACTER SET latin1 NOT NULL,
  `jns_akun_id` int(11) NOT NULL,
  `aktif` enum('Y','T') CHARACTER SET latin1 NOT NULL,
  `tmpl_simpan` enum('Y','T') CHARACTER SET latin1 NOT NULL,
  `tmpl_penarikan` enum('Y','T') CHARACTER SET latin1 NOT NULL,
  `tmpl_pinjaman` enum('Y','T') CHARACTER SET latin1 NOT NULL,
  `tmpl_bayar` enum('Y','T') CHARACTER SET latin1 NOT NULL,
  `tmpl_pemasukan` enum('Y','T') NOT NULL,
  `tmpl_pengeluaran` enum('Y','T') NOT NULL,
  `tmpl_transfer` enum('Y','T') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `nama_kas_tbl`
--

INSERT INTO `nama_kas_tbl` (`id`, `nama`, `jns_akun_id`, `aktif`, `tmpl_simpan`, `tmpl_penarikan`, `tmpl_pinjaman`, `tmpl_bayar`, `tmpl_pemasukan`, `tmpl_pengeluaran`, `tmpl_transfer`) VALUES
(1, 'Kas Utama', 2, 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `neraca_skonto`
--

CREATE TABLE `neraca_skonto` (
  `neraca_skonto_id` int(11) NOT NULL,
  `kelompok_akunid_debet` int(11) NOT NULL,
  `jns_akun_id_debet` int(11) NOT NULL,
  `is_total_debet` tinyint(4) NOT NULL DEFAULT 0,
  `kelompok_akunid_kredit` int(11) NOT NULL,
  `jns_akun_id_kredit` int(11) NOT NULL,
  `is_total_kredit` tinyint(4) NOT NULL DEFAULT 0,
  `no_urut` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `neraca_skonto`
--

INSERT INTO `neraca_skonto` (`neraca_skonto_id`, `kelompok_akunid_debet`, `jns_akun_id_debet`, `is_total_debet`, `kelompok_akunid_kredit`, `jns_akun_id_kredit`, `is_total_kredit`, `no_urut`) VALUES
(1, 1, 0, 0, 3, 0, 0, 1),
(2, 2, 0, 0, 10, 0, 0, 2),
(3, 0, 1, 0, 0, 45, 0, 3),
(4, 0, 2, 0, 0, 46, 0, 4),
(5, 0, 0, 0, 0, 47, 0, 5),
(6, 0, 3, 0, 0, 48, 0, 6),
(7, 0, 4, 0, 0, 49, 0, 7),
(9, 0, 5, 0, 0, 50, 0, 8),
(10, 0, 6, 0, 0, 51, 0, 9),
(11, 0, 7, 0, 0, 52, 0, 10),
(12, 0, 8, 0, 0, 53, 0, 12),
(13, 0, 9, 0, 0, 54, 0, 13),
(14, 0, 10, 0, 0, 0, 0, 14),
(15, 0, 11, 0, 0, 55, 0, 15),
(16, 0, 0, 0, 0, 56, 0, 16),
(18, 0, 12, 0, 11, 0, 0, 19),
(19, 0, 13, 0, 0, 57, 0, 20),
(20, 0, 14, 0, 0, 58, 0, 21),
(21, 0, 15, 0, 0, 59, 0, 22),
(22, 0, 0, 0, 11, 0, 1, 23),
(36, 0, 0, 0, 0, 0, 0, 11),
(38, 0, 16, 0, 12, 0, 0, 24),
(39, 0, 17, 0, 0, 60, 0, 25),
(40, 0, 0, 0, 0, 61, 0, 26),
(41, 0, 18, 0, 0, 0, 0, 27),
(42, 0, 19, 0, 0, 62, 0, 28),
(43, 0, 20, 0, 0, 63, 0, 29),
(44, 0, 21, 0, 0, 64, 0, 30),
(45, 0, 0, 0, 0, 65, 0, 31),
(46, 0, 22, 0, 0, 66, 0, 32),
(47, 0, 23, 0, 0, 67, 0, 33),
(48, 0, 24, 0, 0, 68, 0, 34),
(49, 0, 25, 0, 12, 0, 1, 35),
(50, 0, 0, 0, 4, 0, 0, 36),
(51, 0, 26, 0, 0, 69, 0, 37),
(52, 0, 27, 0, 0, 70, 0, 38),
(53, 0, 28, 0, 0, 71, 0, 39),
(54, 0, 0, 0, 0, 72, 0, 40),
(55, 0, 29, 0, 0, 73, 0, 41),
(56, 0, 30, 0, 0, 0, 0, 42),
(57, 0, 31, 0, 0, 74, 0, 43),
(58, 2, 0, 1, 0, 75, 0, 44),
(59, 8, 0, 0, 0, 77, 0, 45),
(60, 0, 32, 0, 0, 0, 0, 46),
(61, 0, 33, 0, 0, 78, 0, 47),
(62, 0, 34, 0, 0, 79, 0, 48),
(63, 0, 35, 0, 0, 0, 0, 49),
(64, 0, 36, 0, 0, 0, 0, 50),
(65, 0, 37, 0, 0, 0, 0, 51),
(66, 0, 0, 0, 0, 0, 0, 52),
(67, 0, 38, 0, 0, 0, 0, 53),
(68, 0, 39, 0, 0, 0, 0, 54),
(69, 0, 40, 0, 0, 0, 0, 55),
(70, 0, 0, 0, 0, 0, 0, 56),
(71, 0, 41, 0, 0, 0, 0, 57),
(72, 0, 42, 0, 0, 0, 0, 58),
(73, 8, 0, 1, 0, 0, 0, 59),
(74, 9, 0, 0, 0, 0, 0, 60),
(75, 0, 43, 0, 0, 0, 0, 61),
(76, 0, 44, 0, 0, 0, 0, 62),
(77, 0, 0, 0, 10, 0, 1, 18),
(78, 9, 0, 1, 4, 0, 1, 63);

-- --------------------------------------------------------

--
-- Table structure for table `pekerjaan`
--

CREATE TABLE `pekerjaan` (
  `id_kerja` varchar(5) CHARACTER SET latin1 NOT NULL,
  `jenis_kerja` varchar(30) CHARACTER SET latin1 NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `pekerjaan`
--

INSERT INTO `pekerjaan` (`id_kerja`, `jenis_kerja`) VALUES
('1', 'TNI'),
('2', 'PNS'),
('3', 'Karyawan Swasta'),
('4', 'Guru'),
('5', 'Buruh'),
('6', 'Tani'),
('7', 'Pedagang'),
('8', 'Wiraswasta'),
('9', 'Mengurus Rumah Tangga'),
('99', 'Lainnya'),
('98', 'Pensiunan'),
('97', 'Penjahit');

-- --------------------------------------------------------

--
-- Table structure for table `postinglog`
--

CREATE TABLE `postinglog` (
  `id` bigint(20) NOT NULL,
  `postdate` datetime NOT NULL,
  `postby` varchar(150) CHARACTER SET latin1 DEFAULT NULL,
  `jns_posting` varchar(50) CHARACTER SET latin1 DEFAULT NULL,
  `postlog` text CHARACTER SET latin1 NOT NULL,
  `journal_voucherid` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `postinglog`
--

INSERT INTO `postinglog` (`id`, `postdate`, `postby`, `jns_posting`, `postlog`, `journal_voucherid`) VALUES
(1, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 001/INV-GG/XII/2016', '0000016', 325),
(2, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 003/INV-GG/XII/2016', '0000017', 326),
(3, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 005/INV-GG/XII/2016', '0000018', 327),
(4, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 007/INV-GG/XII/2016', '0000019', 328),
(5, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 009/INV-GG/XII/2016', '0000020', 329),
(6, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 011/INV-GG/XII/2016', '0000021', 330),
(7, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 013/INV-GG/XII/2016', '0000022', 331),
(8, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 015/INV-GG/XII/2016', '0000023', 332),
(9, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 023/INV-GG/XII/2016', '0000024', 333),
(10, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET 025/INV-GG/XII/2016', '0000025', 334),
(11, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B45M', '0000026', 335),
(12, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B45P', '0000027', 336),
(13, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B4J93', '0000028', 337),
(14, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B5F9', '0000029', 338),
(15, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B5FZ', '0000030', 339),
(16, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B5HK', '0000031', 340),
(17, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B5J7', '0000032', 341),
(18, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN69L4B5JC', '0000033', 342),
(19, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN6CJ47287', '0000034', 343),
(20, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET CN6CN4730N', '0000035', 344),
(21, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV018/001', '0000036', 345),
(22, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV020/025', '0000037', 346),
(23, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV020/026', '0000038', 347),
(24, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV020/027', '0000039', 348),
(25, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0001', '0000040', 349),
(26, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0002', '0000041', 350),
(27, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0004', '0000042', 351),
(28, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0005', '0000043', 352),
(29, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0006', '0000044', 353),
(30, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0007', '0000045', 354),
(31, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0009', '0000046', 355),
(32, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0011', '0000047', 356),
(33, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0012', '0000048', 357),
(34, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0013', '0000049', 358),
(35, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0014', '0000050', 359),
(36, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0015', '0000051', 360),
(37, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-1/0016', '0000052', 361),
(38, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0001', '0000053', 362),
(39, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0002', '0000054', 363),
(40, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0003', '0000055', 364),
(41, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0004', '0000056', 365),
(42, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0005', '0000057', 366),
(43, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0006', '0000058', 367),
(44, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0007', '0000059', 368),
(45, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0008', '0000060', 369),
(46, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0009', '0000061', 370),
(47, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0010', '0000062', 371),
(48, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0011', '0000063', 372),
(49, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0012', '0000064', 373),
(50, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0013', '0000065', 374),
(51, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0014', '0000066', 375),
(52, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0015', '0000067', 376),
(53, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0016', '0000068', 377),
(54, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0017', '0000069', 378),
(55, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0018', '0000070', 379),
(56, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0019', '0000071', 380),
(57, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0020', '0000072', 381),
(58, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0021', '0000073', 382),
(59, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0022', '0000074', 383),
(60, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0023', '0000075', 384),
(61, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0024', '0000076', 385),
(62, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0025', '0000077', 386),
(63, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0026', '0000078', 387),
(64, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0027', '0000079', 388),
(65, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0028', '0000080', 389),
(66, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0029', '0000081', 390),
(67, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0030', '0000082', 391),
(68, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0031', '0000083', 392),
(69, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0032', '0000084', 393),
(70, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0033', '0000085', 394),
(71, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0034', '0000086', 395),
(72, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0035', '0000087', 396),
(73, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0036', '0000088', 397),
(74, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0037', '0000089', 398),
(75, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0038', '0000090', 399),
(76, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0039', '0000091', 400),
(77, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-17/0040', '0000092', 401),
(78, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/002', '0000093', 402),
(79, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/003', '0000094', 403),
(80, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/005', '0000095', 404),
(81, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/006', '0000096', 405),
(82, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/007', '0000097', 406),
(83, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/008', '0000098', 407),
(84, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/009', '0000099', 408),
(85, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18/010', '0000100', 409),
(86, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV18-004', '0000101', 410),
(87, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/001', '0000102', 411),
(88, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/002', '0000103', 412),
(89, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/003', '0000104', 413),
(90, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/004', '0000105', 414),
(91, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/005', '0000106', 415),
(92, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/006', '0000107', 416),
(93, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/007', '0000108', 417),
(94, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/008', '0000109', 418),
(95, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/010', '0000110', 419),
(96, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/011', '0000111', 420),
(97, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/012', '0000112', 421),
(98, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/013', '0000113', 422),
(99, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/014', '0000114', 423),
(100, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/015', '0000115', 424),
(101, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/016', '0000116', 425),
(102, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/017', '0000117', 426),
(103, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/018', '0000118', 427),
(104, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/019', '0000119', 428),
(105, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/020', '0000120', 429),
(106, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/021', '0000121', 430),
(107, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/022', '0000122', 431),
(108, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/023', '0000123', 432),
(109, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/024', '0000124', 433),
(110, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/025', '0000125', 434),
(111, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/026', '0000126', 435),
(112, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/027', '0000127', 436),
(113, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/028', '0000128', 437),
(114, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/029', '0000129', 438),
(115, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/030', '0000130', 439),
(116, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/031', '0000131', 440),
(117, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/032', '0000132', 441),
(118, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/033', '0000133', 442),
(119, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV19/034', '0000134', 443),
(120, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/001', '0000135', 444),
(121, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/002', '0000136', 445),
(122, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/003', '0000137', 446),
(123, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/006', '0000138', 447),
(124, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/007', '0000139', 448),
(125, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/008', '0000140', 449),
(126, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/009', '0000141', 450),
(127, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/010', '0000142', 451),
(128, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/011', '0000143', 452),
(129, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/012', '0000144', 453),
(130, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/013', '0000145', 454),
(131, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/014', '0000146', 455),
(132, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/015', '0000147', 456),
(133, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/016', '0000148', 457),
(134, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/017', '0000149', 458),
(135, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/023', '0000150', 459),
(136, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/024', '0000151', 460),
(137, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/025', '0000152', 461),
(138, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/026', '0000153', 462),
(139, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/027', '0000154', 463),
(140, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/028', '0000155', 464),
(141, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/029', '0000156', 465),
(142, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/030', '0000157', 466),
(143, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/031', '0000158', 467),
(144, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/032', '0000159', 468),
(145, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/033', '0000160', 469),
(146, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/034', '0000161', 470),
(147, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/035', '0000162', 471),
(148, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/036', '0000163', 472),
(149, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/037', '0000164', 473),
(150, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/038', '0000165', 474),
(151, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/039', '0000166', 475),
(152, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/040', '0000167', 476),
(153, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/041', '0000168', 477),
(154, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/042', '0000169', 478),
(155, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/043', '0000170', 479),
(156, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/044', '0000171', 480),
(157, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/045', '0000172', 481),
(158, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/046', '0000173', 482),
(159, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/047', '0000174', 483),
(160, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/048', '0000175', 484),
(161, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/049', '0000176', 485),
(162, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/050', '0000177', 486),
(163, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/051', '0000178', 487),
(164, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/052', '0000179', 488),
(165, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/18', '0000180', 489),
(166, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/19', '0000181', 490),
(167, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/20', '0000182', 491),
(168, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/21', '0000183', 492),
(169, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20/22', '0000184', 493),
(170, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20-004', '0000185', 494),
(171, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV20-005', '0000186', 495),
(172, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0001', '0000187', 496),
(173, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0002', '0000188', 497),
(174, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0003', '0000189', 498),
(175, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0004', '0000190', 499),
(176, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0005', '0000191', 500),
(177, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0006', '0000192', 501),
(178, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0007', '0000193', 502),
(179, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0008', '0000194', 503),
(180, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0009', '0000195', 504),
(181, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN ASET INV-26/0010', '0000196', 505),
(182, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000197', 506),
(183, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000198', 507),
(184, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000199', 508),
(185, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000200', 509),
(186, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000201', 510),
(187, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000202', 511),
(188, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000203', 512),
(189, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000204', 513),
(190, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000205', 514),
(191, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000206', 515),
(192, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000207', 516),
(193, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000208', 517),
(194, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000209', 518),
(195, '2020-11-19 04:57:27', 'admin', 'POSTING BULANAN', '0000210', 519);

-- --------------------------------------------------------

--
-- Table structure for table `repayment_schedule_d`
--

CREATE TABLE `repayment_schedule_d` (
  `id` int(11) NOT NULL,
  `pinjam_id` int(11) NOT NULL DEFAULT 0,
  `bulan_ke` int(4) NOT NULL DEFAULT 0,
  `pokok_angsuran` int(11) NOT NULL DEFAULT 0,
  `bunga_angsuran` int(11) NOT NULL DEFAULT 0,
  `simpanan_wajib` int(11) NOT NULL DEFAULT 0,
  `jumlah_angsuran` int(11) NOT NULL DEFAULT 0,
  `tgl_tempo` datetime NOT NULL,
  `update_data` datetime NOT NULL,
  `user_name` varchar(255) NOT NULL,
  `keterangan` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `repayment_schedule_h`
--

CREATE TABLE `repayment_schedule_h` (
  `id` int(11) NOT NULL,
  `tgl_pinjam` datetime NOT NULL,
  `anggota_id` int(11) NOT NULL DEFAULT 0,
  `nomor_pinjaman` varchar(50) DEFAULT NULL,
  `jenis_pinjaman` int(2) NOT NULL,
  `lama_angsuran` int(11) NOT NULL DEFAULT 0,
  `angsuran_per_bulan` int(11) DEFAULT NULL,
  `no_perjanjian_kredit` varchar(50) DEFAULT NULL,
  `nomor_rekening` varchar(100) DEFAULT NULL,
  `nomor_pensiunan` varchar(100) DEFAULT NULL,
  `jumlah` int(11) NOT NULL DEFAULT 0,
  `bunga` float(10,2) NOT NULL,
  `lunas` enum('Belum','Lunas') NOT NULL,
  `dk` enum('D','K') NOT NULL,
  `kas_id` int(11) NOT NULL DEFAULT 0,
  `jns_trans` int(11) NOT NULL DEFAULT 0,
  `jns_cabangid` int(11) DEFAULT NULL,
  `update_data` datetime NOT NULL,
  `user_name` varchar(255) NOT NULL,
  `keterangan` varchar(255) NOT NULL,
  `contoh` int(23) NOT NULL,
  `file` varchar(240) NOT NULL,
  `biaya_asuransi_akun` int(11) NOT NULL,
  `biaya_administrasi_akun` int(11) NOT NULL,
  `simpanan_pokok_akun` int(11) NOT NULL,
  `pokok_bulan_satu_akun` int(11) NOT NULL,
  `pokok_bulan_dua_akun` int(11) NOT NULL,
  `bunga_bulan_satu_akun` int(11) NOT NULL,
  `bunga_bulan_dua_akun` int(11) NOT NULL,
  `pencairan_bersih_akun` int(11) NOT NULL,
  `plafond_pinjaman_akun` int(11) NOT NULL DEFAULT 0,
  `simpanan_wajib_akun` int(11) NOT NULL DEFAULT 0,
  `biaya_materai_akun` int(11) NOT NULL DEFAULT 0,
  `biaya_asuransi` int(11) NOT NULL DEFAULT 0,
  `biaya_administrasi` int(11) NOT NULL DEFAULT 0,
  `biaya_materai` int(11) NOT NULL DEFAULT 0,
  `simpanan_pokok` int(11) NOT NULL DEFAULT 0,
  `simpanan_wajib` int(11) NOT NULL DEFAULT 0,
  `pokok_bulan_satu` int(11) NOT NULL DEFAULT 0,
  `bunga_bulan_satu` int(11) NOT NULL DEFAULT 0,
  `pokok_bulan_dua` int(11) NOT NULL DEFAULT 0,
  `bunga_bulan_dua` int(11) NOT NULL DEFAULT 0,
  `pencairan_bersih` int(11) NOT NULL DEFAULT 0,
  `plafond_pinjaman` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `setting_autodebet`
--

CREATE TABLE `setting_autodebet` (
  `id` int(11) NOT NULL,
  `tgl_tempo_anggota` int(11) DEFAULT NULL,
  `tgl_tempo_anggota_luarbiasa` int(11) DEFAULT NULL,
  `kas_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `setting_autodebet`
--

INSERT INTO `setting_autodebet` (`id`, `tgl_tempo_anggota`, `tgl_tempo_anggota_luarbiasa`, `kas_id`) VALUES
(1, 28, 28, 1);

-- --------------------------------------------------------

--
-- Table structure for table `sewa_kantor`
--

CREATE TABLE `sewa_kantor` (
  `id` int(5) NOT NULL,
  `cabang_id` int(5) NOT NULL DEFAULT 0,
  `awal_sewa` date DEFAULT NULL,
  `akhir_sewa` date DEFAULT NULL,
  `saldo` int(12) NOT NULL DEFAULT 0,
  `biaya_sewa` int(12) NOT NULL DEFAULT 0,
  `jangka_waktu` int(2) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sewa_kantor`
--

INSERT INTO `sewa_kantor` (`id`, `cabang_id`, `awal_sewa`, `akhir_sewa`, `saldo`, `biaya_sewa`, `jangka_waktu`) VALUES
(1, 35, '2020-10-01', '2020-12-01', 2656250, -885417, 3),
(2, 56, '2020-10-01', '2021-09-01', 86000000, -7166667, 12),
(3, 42, '2020-10-01', '2020-11-01', 1083333, -541667, 2),
(4, 40, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(5, 38, '2020-10-01', '2021-01-01', 4666667, -1166667, 4),
(6, 23, '2020-10-01', '2021-01-01', 5066667, -1266667, 4),
(7, 17, '2020-10-01', '2021-01-01', 11666667, -2916667, 4),
(8, 20, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(9, 50, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(10, 13, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(11, 52, '2020-10-01', '2021-01-01', 3333333, -833333, 4),
(12, 7, '2020-10-01', '2021-02-01', 8333333, -1666667, 5),
(13, 56, '2020-10-01', '2022-04-01', 15833333, -833333, 19),
(14, 34, '2020-10-01', '2021-06-01', 11250000, -1250000, 9);

-- --------------------------------------------------------

--
-- Table structure for table `sewa_kantor_history`
--

CREATE TABLE `sewa_kantor_history` (
  `id` int(5) NOT NULL DEFAULT 0,
  `periodmonth` int(5) NOT NULL DEFAULT 0,
  `periodyear` int(5) NOT NULL DEFAULT 0,
  `cabang_id` int(5) NOT NULL DEFAULT 0,
  `awal_sewa` date DEFAULT NULL,
  `akhir_sewa` date DEFAULT NULL,
  `saldo` int(12) NOT NULL DEFAULT 0,
  `biaya_sewa` int(12) NOT NULL DEFAULT 0,
  `jangka_waktu` int(2) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sewa_kantor_history`
--

INSERT INTO `sewa_kantor_history` (`id`, `periodmonth`, `periodyear`, `cabang_id`, `awal_sewa`, `akhir_sewa`, `saldo`, `biaya_sewa`, `jangka_waktu`) VALUES
(1, 10, 2020, 35, '2020-10-01', '2020-12-01', 2656250, -885417, 3),
(2, 10, 2020, 56, '2020-10-01', '2021-09-01', 86000000, -7166667, 12),
(3, 10, 2020, 42, '2020-10-01', '2020-11-01', 1083333, -541667, 2),
(4, 10, 2020, 40, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(5, 10, 2020, 38, '2020-10-01', '2021-01-01', 4666667, -1166667, 4),
(6, 10, 2020, 23, '2020-10-01', '2021-01-01', 5066667, -1266667, 4),
(7, 10, 2020, 17, '2020-10-01', '2021-01-01', 11666667, -2916667, 4),
(8, 10, 2020, 20, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(9, 10, 2020, 50, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(10, 10, 2020, 13, '2020-10-01', '2021-01-01', 5000000, -1250000, 4),
(11, 10, 2020, 52, '2020-10-01', '2021-01-01', 3333333, -833333, 4),
(12, 10, 2020, 7, '2020-10-01', '2021-02-01', 8333333, -1666667, 5),
(13, 10, 2020, 56, '2020-10-01', '2022-04-01', 15833333, -833333, 19),
(14, 10, 2020, 34, '2020-10-01', '2021-06-01', 11250000, -1250000, 9);

-- --------------------------------------------------------

--
-- Table structure for table `suku_bunga`
--

CREATE TABLE `suku_bunga` (
  `id` int(10) NOT NULL,
  `opsi_key` varchar(20) NOT NULL,
  `opsi_val` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `suku_bunga`
--

INSERT INTO `suku_bunga` (`id`, `opsi_key`, `opsi_val`) VALUES
(1, 'bg_tab', '0'),
(2, 'bg_pinjam', '20,4'),
(3, 'biaya_adm', '20000'),
(4, 'denda', ''),
(5, 'denda_hari', '24'),
(6, 'dana_cadangan', '40'),
(7, 'jasa_anggota', '40'),
(8, 'dana_pengurus', '5'),
(9, 'dana_karyawan', '5'),
(10, 'dana_pend', '5'),
(11, 'dana_sosial', '5'),
(12, 'jasa_usaha', '5'),
(13, 'jasa_modal', '5'),
(14, 'pjk_pph', '25'),
(15, 'pinjaman_bunga_tipe', 'A'),
(16, 'js_pemb_daerah_kerja', '0'),
(17, 'jasa_dana_pembinaan', '0');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_anggota`
--

CREATE TABLE `tbl_anggota` (
  `id` bigint(20) NOT NULL,
  `no_anggota` varchar(20) DEFAULT NULL,
  `nama` varchar(255) CHARACTER SET latin1 NOT NULL,
  `identitas` varchar(255) NOT NULL,
  `jk` enum('L','P') NOT NULL,
  `tmp_lahir` varchar(225) NOT NULL,
  `tgl_lahir` date NOT NULL,
  `status` varchar(30) NOT NULL,
  `agama` varchar(30) NOT NULL,
  `pendidikan` varchar(255) DEFAULT NULL,
  `ktp` varchar(255) DEFAULT NULL,
  `departement` varchar(255) NOT NULL,
  `pekerjaan` varchar(30) NOT NULL,
  `ibu_kandung` varchar(50) DEFAULT NULL,
  `kelurahan` varchar(50) DEFAULT NULL,
  `kecamatan` varchar(50) DEFAULT NULL,
  `kode_pos` varchar(15) DEFAULT NULL,
  `alamat` text CHARACTER SET latin1 NOT NULL,
  `alamat_domisili` text NOT NULL,
  `kota` varchar(255) NOT NULL,
  `notelp` varchar(12) NOT NULL,
  `tgl_daftar` date NOT NULL,
  `jabatan_id` int(10) NOT NULL,
  `aktif` enum('Y','N') NOT NULL,
  `code` varchar(255) NOT NULL,
  `pass_word` varchar(225) NOT NULL,
  `file_pic` varchar(225) NOT NULL,
  `jns_anggotaid` int(11) NOT NULL COMMENT '1: biasa 2: luarbiasa',
  `category` varchar(50) NOT NULL,
  `nomor_rekening` varchar(100) DEFAULT NULL,
  `nama_bank` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_anggota`
--

INSERT INTO `tbl_anggota` (`id`, `no_anggota`, `nama`, `identitas`, `jk`, `tmp_lahir`, `tgl_lahir`, `status`, `agama`, `pendidikan`, `ktp`, `departement`, `pekerjaan`, `ibu_kandung`, `kelurahan`, `kecamatan`, `kode_pos`, `alamat`, `alamat_domisili`, `kota`, `notelp`, `tgl_daftar`, `jabatan_id`, `aktif`, `code`, `pass_word`, `file_pic`, `jns_anggotaid`, `category`, `nomor_rekening`, `nama_bank`) VALUES
(1, 'ALB000001', 'MAMAN SUPRATMAN', 'KTP', 'L', 'BANDUNG', '1940-08-06', 'D', 'ISLAM', '0', '2101120608400001', '', 'PENSIUNAN', 'RUPI', 'TOAPAYA SELATAN', 'TOAPAYA', '29153', 'KP. SIMPANGAN KM 16 RT.05/RW.02', '', 'BINTAN', '081266162960', '2020-06-08', 0, 'Y', '', '', '', 2, '', '3901310236', 'BUKOPIN'),
(2, 'ALB000002', 'Saimah', 'KTP', 'P', 'Banyumas', '1942-07-12', 'J', 'ISLAM', '0', '3302015207420003', '', 'PENSIUNAN', 'Rantem', 'Lumbir', 'Lumbir', '53177', 'Lumbir Rt004 Rw001 Lumbir Banyumas', '', 'Banyumas', '085290054839', '2020-06-08', 0, 'Y', '', '', '', 2, '', '3001311318', 'BUKOPIN'),
(3, 'ALB000003', 'MARDIAH', 'KTP', 'P', 'BUKITTINGGI', '1940-03-03', 'J', 'ISLAM', '0', '1305154303400001', '', 'PENSIUNAN', 'KASUMAH', 'SICINCIN', '2X11 ENAM LINGKUNG', '25584', 'BARI MUDIK SICINCIN 2X 11 ENAM LINGKUNG', '', 'PADANG PARIAMAN', '081372810644', '2020-06-09', 0, 'Y', '', '', '', 2, '', '0362330015', 'BUKOPIN'),
(4, 'ALB000004', 'ABD. ROHMAN', 'KTP', 'L', 'BOGOR', '1941-01-20', 'D', 'ISLAM', '0', '3201332001410001', '', 'PENSIUNAN', 'SUHAENI', 'PARIGI MEKAR', 'CISEENG', '16120', 'KP SETU RT. 002 RW.001', '', 'BOGOR', '089638946921', '2020-06-08', 0, 'Y', '', '', '', 2, '', '5330310845', 'BUKOPIN'),
(5, 'ALB000005', 'DARIYAM', 'KTP', 'P', 'PACITAN', '1940-07-01', 'J', 'ISLAM', '0', '2172024107400013', '', 'PENSIUNAN', 'SUGI', 'Kampung Bulang', 'TANJUNGPINNG TIMUR', '29123', 'Jl. Gatot Subroto no.01 rt.01/rw.08 ', '', 'TANJUNGPINANG', '081372568679', '2020-06-09', 0, 'Y', '', '', '', 2, '', '3901310311', 'BUKOPIN'),
(6, 'ALB000006', 'Sutrisno HP', 'KTP', 'L', 'Madiun', '1940-08-17', 'D', 'ISLAM', '0', '3517091708400007', '', 'PENSIUNAN', 'Amirah', 'Kaliwungu', 'Jombang', '61419', 'Jl Kencana Wungu 19 RT 002 RW 001 ', '', 'Jombang', '085732454913', '2020-06-10', 0, 'Y', '', '', '', 2, '', '4002330226', 'BUKOPIN'),
(7, 'ALB000007', 'ST NARI', 'KTP', 'L', 'DURIAN KADOK', '1940-07-01', 'D', 'ISLAM', '0', '1305050107400011', '', 'PENSIUNAN', 'TIALIH', 'SUNGAI SARIAK', 'VII KOTO SUNGAI SARIAK', '25573', 'PASA DURIAN', '', 'KABUPATEN PADANG PARIAMAN', '085364090487', '2020-06-09', 0, 'Y', '', '', '', 2, '', '0361312796', 'BUKOPIN'),
(8, 'ALB000008', 'ABDUL FATAH BOEDIONO', 'KTP', 'L', 'KEDIRI', '1940-12-15', 'K', 'ISLAM', '0', '3511091512400002', '', 'PENSIUNAN', 'Martini', 'SUMBER KALONG', 'Wonosari', '68282', 'SUMBER KALONG RT 023 RW 008 ', '', 'BONDOWOSO', '083122155083', '2020-06-10', 0, 'Y', '', '', '', 2, '', '0361312796', 'BUKOPIN'),
(9, 'ALB000009', 'SUNARJA', 'KTP', 'L', 'PANDEGLANG', '1940-10-04', 'K', 'ISLAM', '0', '3601302110400001', '', 'PENSIUNAN', 'KAMSARIAH', 'KADUBELANG', 'MEKARJAYA', '42271', 'KP PERIGI RT 001/001 ', '', 'PANDEGLANG', '085212620383', '2020-06-10', 0, 'Y', '', '', '', 2, '', '2503311510', 'BUKOPIN'),
(10, 'ALB000010', 'M.SALIM HASAN', 'KTP', 'L', 'KERAWANG', '1941-01-25', 'K', 'ISLAM', '0', '6171012501410002', '', 'PENSIUNAN', 'ANYI', 'BANSIR LAUT', 'PONTIANAK TENGGARA', '78124', 'JL.IMAM BONJOL GG.H.ALI NO 59', '', 'KOTA PONTIANAK', '085346941170', '2020-06-10', 0, 'Y', '', '', '', 2, '', '2961310487', 'BUKOPIN'),
(11, 'ALB000011', 'SALBIAH', 'KTP', 'P', 'SINGAKAWANG', '1942-08-02', 'J', 'ISLAM', '0', '6172014208420002', '', 'PENSIUNAN', 'JUBAIDAH', 'ROBAN', 'SINGKAWANG TENGAH', '79112', 'JLN.JENDRAL SUDIRMAN GG.BARU', '', 'SINGKAWANG', '08979593323', '2020-06-11', 0, 'Y', '', '', '', 2, '', '2961310487', 'BUKOPIN'),
(12, 'ALB000012', 'Theetan Tjong Soebekti', 'KTP', 'L', 'Pamekasan', '1940-08-02', 'K', 'ISLAM', '0', '3510100208400004', '', 'PENSIUNAN', 'Fatimah', 'Tegalharjo', 'Glenmore', '68466', 'Dsn Gunung Krikil RT 004 RW 001', '', 'Banyuwangi', '081244177736', '2020-06-07', 0, 'Y', '', '', '', 2, '', '5601310965', 'BUKOPIN'),
(13, 'ALB000013', 'SITI AMINI', 'KTP', 'P', 'MAGETAN', '1940-02-02', 'J', 'ISLAM', '0', '3520064202400001', '', 'PENSIUNAN', 'SAKIMAH', 'TAMBRAN', 'MAGETAN', '63318', 'JL PANDU NO 293 RT/RW 02/02', '', 'MAGETAN', '085648752842', '2020-06-10', 0, 'Y', '', '', '', 2, '', '5101312774', 'BUKOPIN'),
(14, 'ALB000014', 'ISKANDAR MAKMUR', 'KTP', 'L', 'RENGAT', '1941-02-07', 'K', 'ISLAM', '0', '1207240702410002', '', 'PENSIUNAN', 'ZAINAB', 'KELAMBIR V KAMPUNG', 'HAMPARAN PERAK', '20374', 'DUSUN III', '', 'KABUPATEN DELI SERDANG', '082164093983', '2020-06-15', 0, 'Y', '', '', '', 2, '', '0310310993', 'BUKOPIN'),
(15, 'ALB000015', 'SUTJIPTO', 'KTP', 'L', 'MALANG', '1941-01-24', 'D', 'ISLAM', '0', '3507252401410002', '', 'PENSIUNAN', 'SITI A', 'SUMBERPORONG', 'LAWANG', '65212', 'KRAJAN UTARA RT 002 RW 003', '', 'KABUPATEN MALANG', '081334324551', '2020-06-12', 0, 'Y', '', '', '', 2, '', '2001311286', 'BUKOPIN'),
(16, 'ALB000016', 'H SYAPAWI ACHMAD', 'KTP', 'L', 'KUTAI LAMA', '1940-07-11', 'D', 'ISLAM', '0', '6402041107400002', '', 'PENSIUNAN', 'INDUN', 'ANGGANA', 'ANGGANA', '75381', 'JL SUKALIMA  RT 05', '', 'KUTAI KERTANEGARA', '082333831921', '2020-06-16', 0, 'Y', '', '', '', 2, '', '1902310488', 'BUKOPIN'),
(17, 'ALB000017', 'Suwartinah', 'KTP', 'P', 'Malang', '1940-10-11', 'J', 'ISLAM', '0', '3576025110400001', '', 'PENSIUNAN', 'Suratmi', 'Wates', 'Magersari', '61317', 'Jl Kelud VIII/6-8 RT 001 RW 005', '', 'Mojokerto', '08814394135', '2020-06-15', 0, 'Y', '', '', '', 2, '', '4002310844', 'BUKOPIN'),
(18, 'ALB000018', 'Sri Musringah Lous', 'KTP', 'P', 'Banjarnegara', '1940-12-12', 'J', 'ISLAM', '0', '3304055212400006', '', 'PENSIUNAN', 'Satijah', 'Banjarkulon', 'Banjarmangu', '53452', 'Banjarkulon RT 003 RW 003 ', '', 'Banjarnegara', '083808426447', '2020-06-16', 0, 'Y', '', '', '', 2, '', '3062310180', 'BUKOPIN'),
(19, 'ALB000019', 'Supardi Adi Nugroho', 'KTP', 'L', 'Yogyakarta', '1941-02-03', 'D', 'ISLAM', '0', '3304060302410001', '', 'PENSIUNAN', 'wakiyem', 'Wangon', 'Banjarnegara', '53417', 'eel Malang RT001 RW001', '', 'Banjarnegara', '082300081678', '2020-06-18', 0, 'Y', '', '', '', 2, '', '3062310230', 'BUKOPIN'),
(20, 'ALB000020', 'RUKMIATI', 'KTP', 'P', 'BONDOWOSO', '1941-03-06', 'J', 'ISLAM', '0', '3511184603410001', '', 'PENSIUNAN', 'SUHRIYA', 'REJOAGUNG', 'SUMBER WRINGIN', '68287', 'RECES RT 002 RW 001', '', 'BONDOWOSO', '081239192002', '2020-06-19', 0, 'Y', '', '', '', 2, '', '3202311361', 'BUKOPIN'),
(21, 'ALB000021', 'HJ JAJAH HERJATI', 'KTP', 'P', 'TASIKMALAYA', '1941-09-10', '', '', '0', '3278065009410006', '', '', 'ROHANAH', 'CIHERANG', 'CIBEUREM', '46196', 'CIBANGUN KALER 1 RT/RW 003/010', '', 'TASIKMALAYA', '082119884475', '2020-06-22', 2, 'Y', '', '', '', 2, '', '3501102301', 'BUKOPIN'),
(22, 'ALB000022', 'RUBAMA', 'KTP', 'P', 'MUARO', '1940-07-01', 'J', 'ISLAM', '0', '1303044107400033', '', 'PENSIUNAN', 'SORU', 'MUARO', 'SIJUNJUNG', '27511', 'JORONG TANGAH', '', 'SIJUNJUNG', '081277775956', '2020-06-11', 0, 'Y', '', '', '', 2, '', '0364310450', 'BUKOPIN'),
(23, 'ALB000023', 'DJAIT', 'KTP', 'L', 'PONOROGO', '1940-12-08', 'D', 'ISLAM', '0', '3502030812400001', '', 'PENSIUNAN', 'SARIMAH', 'NAMBAK', 'BUNGKAL', '63462', 'JL PEMUDA RT/RW 01/01', '', 'PONOROGO', '081281966228', '2020-06-19', 0, 'Y', '', '', '', 2, '', '5101311755', 'BUKOPIN'),
(24, 'ALB000024', 'Soewarno SH', 'KTP', 'L', 'Ngawi', '1941-07-07', 'K', 'ISLAM', '0', '3517090707410002', '', 'PENSIUNAN', 'Suwarti', 'Sengon', 'Jombang', '61418', 'Jl Patimura Rt 025 Rw 005', '', 'Jombang', '087837463873', '2020-06-24', 0, 'Y', '', '', '', 2, '', '4002310968', 'BUKOPIN'),
(25, 'ALB000025', 'SUHADI BA', 'KTP', 'L', 'MADIUN', '1941-07-17', 'D', 'ISLAM', '0', '3577011707410002', '', 'PENSIUNAN', 'SUMIATI', 'SUKOSARI', 'KARTOHARJO', '63114', 'JL SRI WIDODO NO 21 RT/RW 11/04', '', 'MADIUN', '081335803395', '2020-06-19', 0, 'Y', '', '', '', 2, '', '5101312194', 'BUKOPIN'),
(26, 'ALB000026', 'E MUNADJAT', 'KTP', 'L', 'KUNINGAN', '1941-04-16', 'K', 'ISLAM', '0', '3208181604410002', '', 'PENSIUNAN', 'KEMOH', 'CIGUGUR', 'CIGUGUR', '45552', 'Lingk Wage Tt/rw 002/008', '', 'Kuningan', '081324595651', '2020-06-24', 0, 'Y', '', '', '', 2, '', '0902310654', 'BUKOPIN'),
(27, 'ALB000027', 'YULIATI', 'KTP', 'P', 'PEMANGKAT', '1941-03-06', 'J', 'ISLAM', '0', '6171054603410002', '', 'PENSIUNAN', 'FATIMAH', 'DARAT SEKIP', 'PONTIANAK KOTA', '78117', 'JL.HOS COKROAMINOTO NO 348/81', '', 'PONTIANAK KOTA', '082154711686', '2020-07-01', 0, 'Y', '', '', '', 2, '', '2961310721', 'BUKOPIN'),
(28, 'ALB000028', 'SITI JUBAEDAH', 'KTP', 'P', 'SUBANG', '1940-06-16', 'J', 'ISLAM', '0', '3271055606400003', '', 'PENSIUNAN', 'SARKEM', 'KEDUNG HALANG', 'BOGOR UTARA', '16158', 'JL BEMBANGUNAN RT 005/006 KEL KEDUNG HALANG KEC BO', '', 'BOGOR', '085313327299', '2020-07-01', 0, 'Y', '', '', '', 2, '', '2761310304', 'BUKOPIN'),
(29, 'ALB000029', 'MUSILAH', 'KTP', 'P', 'BANTUL', '1941-12-31', 'K', 'ISLAM', '0', '3471067112410005', '', 'PENSIUNAN', 'ROYOB', 'NGAMPILAN', 'NGAMPILAN', '55261', 'NGADIWINATAN NG I/984 RT 058 RW 012 NGAMPILAN NGAM', '', 'YOGYAKARTA', '083890622220', '2020-07-02', 0, 'Y', '', '', '', 2, '', '1007310011', 'BUKOPIN'),
(30, 'ALB000030', 'HAMDIJA', 'KTP', 'P', 'SITUBONDO', '1941-07-01', 'J', 'ISLAM', '0', '3512024107410069', '', 'PENSIUNAN', 'ROSE', 'BLORO', 'BESUKI', '68356', 'KP. BLORO BARAT RT.002 RW.001 DESA BLORO KEC. BESU', '', 'SITUBONDO', '082230922229', '2020-07-02', 0, 'Y', '', '', '', 2, '', '3202311881', 'BUKOPIN'),
(31, 'ALB000031', 'Sarmat', 'KTP', 'L', 'Jombang', '1940-09-01', 'D', 'ISLAM', '0', '3517050109400001', '', 'PENSIUNAN', 'Sarniti', 'Carangwulung', 'Wonosalam', '61476', 'Carangwulung Rt 004 Rw 005 Carangwulung Wonosalam', '', 'Jombang', '082142593821', '2020-07-06', 0, 'Y', '', '', '', 2, '', '4002310858', 'BUKOPIN'),
(32, 'ALB000032', 'ANISAH NASUTION', 'KTP', 'P', 'MEDAN', '1939-12-27', 'J', 'ISLAM', '0', '1271206712390001', '', 'PENSIUNAN', 'REWAN LUBIS', 'GLUGUR DARAT I', 'MEDAN TIMUR', '20238', 'JL. PASAR III GG. MULIA NO.02 RT/RW 02/02 ', '', 'KOTA MEDAN', '082180379800', '2020-07-06', 0, 'Y', '', '', '', 2, '', '0310311336', 'BUKOPIN'),
(33, 'ALB000033', 'H RADEN BAGUS SADINO', 'KTP', 'L', 'BLITAR', '1939-08-12', 'K', 'ISLAM', '0', '2102051208390004', '', 'PENSIUNAN', 'SITI TEDOEH', 'DARUSSALAM', 'TEBING', '29665', 'PURI GRANIT INDAH RT. 04 RW. 01', '', 'KARIMUN', '08126114109', '2020-07-07', 0, 'Y', '', '', '', 2, '', '3901310657', 'BUKOPIN'),
(34, 'ALB000034', 'ANDI SUTRISNO', 'KTP', 'L', 'CIREBON', '1942-08-30', 'K', 'ISLAM', '3', '3404013008420001', '', 'PENSIUNAN', 'KARSITI', 'BALECATUR', 'GAMPING', '55295', 'JATISAWIT RT 005 RW 038 BALECATUR GAMPING SLEMAN', '', 'SLEMAN', '082131116572', '2020-07-07', 0, 'Y', '', '', '', 2, '', '1001330040', 'BUKOPIN'),
(35, 'ALB000035', 'Saeun', 'KTP', 'L', 'Jombang', '1940-06-03', 'K', 'ISLAM', '0', '3517200306400002', '', 'PENSIUNAN', 'Munirah', 'Ngogri', 'Megaluh', '61457', 'Dsn Ngogri RT 005 RW 001 Ngogri Megaluh ', '', 'Jombang', '085236605844', '2020-07-09', 0, 'Y', '', '', '', 2, '', '4002310214', 'BUKOPIN'),
(36, 'ALB000036', 'Siti sutaryati', 'KTP', 'P', 'Banjarnegara', '1942-09-19', 'J', 'ISLAM', '0', '3304065909420001', '', 'PENSIUNAN', 'Sudariyah', 'Kutabanjarnegara', 'Banjarnegara', '53415', 'Kutabanjarnegara RT 002 RW 007 Kutabanjarnegara Ba', '', 'Kabupaten', '08212129964', '2020-07-07', 0, 'Y', '', '', '', 2, '', '3062310118', 'BUKOPIN'),
(37, 'ALB000037', 'DRG RUSFENDI GARNIWA', 'KTP', 'L', 'BANDUNG', '1940-07-28', 'D', 'ISLAM', '4', '3175072807400001', '', 'PENSIUNAN', 'RUSTIKA', 'MALAKA JAYA', 'DUREN SAWIT', '13460', 'JL RAYA BUNGA RAMPAI NO 13 RT 002 RW 006 KEL MALAK', '', 'JAKARTA TIMUR', '08170801219', '2020-07-08', 0, 'Y', '', '', '', 2, '', '4824310175', 'BUKOPIN'),
(38, 'ALB000038', 'Burhani', 'KTP', 'L', 'Banjarnegara', '1941-03-24', 'K', 'ISLAM', '0', '3304122403410001', '', 'PENSIUNAN', 'wartini', 'Sawangan', 'Punggelan', '53462', 'Kerajan RT03 RW01 Sawangan Punggelan Banjarnegara', '', 'Kabupaten', '085292147827', '2020-07-07', 0, 'Y', '', '', '', 2, '', '3062310119', 'BUKOPIN'),
(39, 'ALB000039', 'SUDJASMI', 'KTP', 'P', 'PURWOREJO ', '1941-04-12', 'J', 'ISLAM', '0', '0550075204410001', '', 'PENSIUNAN', 'PAINI', 'CEMPAKA PUTIH', 'JELUTUNG', '36134', 'LRG.KEMANG RT.04 KEL.CEMPAKA PUTIH KEC.JELUTUNG', '', 'KOTA JAMBI', '085266388078', '2020-07-09', 0, 'Y', '', '', '', 2, '', '2801311292', 'BUKOPIN'),
(40, 'ALB000040', 'SUARTI', 'KTP', 'P', 'JAMBI', '1940-08-17', 'J', 'ISLAM', '0', '1571025708400021', '', 'PENSIUNAN', 'SUROTA', 'PAAL MERAH', 'PAAL MERAH', '36139', 'JL.YUKA RT.13 KEL.PAAL MERAH KEC.PAAL MERAH KOTA J', '', 'KOTA JAMBI', '085266042967', '2020-07-09', 0, 'Y', '', '', '', 2, '', '2801311392', 'BUKOPIN'),
(41, 'ALB000041', 'S YUSHAR', 'KTP', 'L', 'GADUT', '1941-07-21', 'K', 'ISLAM', '0', '1306062107410001', '', 'PENSIUNAN', 'JALISYAH', 'LADANG LAWEH', 'BANUHAMPU', '26181', 'BULAAAN GADANG JORONG PARIK RINTANG KELURAHAN LADA', '', 'AGAM', '081374588940', '2020-07-14', 0, 'Y', '', '', '', 2, '', '0362310280', 'BUKOPIN'),
(42, 'ALB000042', 'JENNY DEETJE MANTIK WAROUW', 'KTP', 'P', 'TONDANO', '1940-12-01', 'K', 'KRISTEN', '0', '7171074112400001', '', 'PENSIUNAN', 'GERTHRUIDA SARAUN', 'TANJUNG BATU', 'WANEA', '95117', 'LINGKUNGAN IV RW 004 ', '', 'MANADO', '082194599626', '2020-07-13', 0, 'Y', '', '', '', 2, '', '3301311781', 'BUKOPIN'),
(43, 'ALB000043', 'SUNTIANI', 'KTP', 'P', 'MALANG', '1940-11-27', 'J', 'ISLAM', '0', '3671126711400003', '', 'PENSIUNAN', 'MASRAN', 'KARANG TENGAH', 'KARANG TENGAH', '15157', 'JL.MALABAR I /16  RT.001 RW.006 KEL.KARANG TENGAH ', '', 'KOTA TANGERANG', '087764933303', '2020-07-13', 0, 'Y', '', '', '', 2, '', '4617310086', 'BUKOPIN'),
(44, 'ALB000044', 'Aslichah', 'KTP', 'P', 'Surabaya', '1941-12-21', 'J', 'ISLAM', '0', '3576026112410002', '', 'PENSIUNAN', 'nursechah', 'Wates', 'Magersari', '61317', 'Pandan IV/07 RT 002 RW 001 Wates Magersari', '', 'Mojokerto', '081515668747', '2020-07-14', 0, 'Y', '', '', '', 2, '', '4002330138', 'BUKOPIN'),
(45, 'ALB000045', 'MASRI MS', 'KTP', 'L', 'PALALUAR', '1939-09-14', 'K', 'ISLAM', '0', '1303081409390002', '', 'PENSIUNAN', 'MARYAM', 'LIMO KOTO', 'KOTO VII', '27562', 'JORONG TANJUNG AMPALU ', '', 'KABUPATEN SIJUNJUNG', '082286063526', '2020-07-13', 0, 'Y', '', '', '', 2, '', '0364310071', 'BUKOPIN'),
(46, 'ALB000046', 'Supiyah', 'KTP', 'P', 'Jombang', '1941-05-09', 'J', 'ISLAM', '0', '3517184905410001', '', 'PENSIUNAN', 'Umisalamah', 'Bandarkedungmulyo', 'Bandarkedungmulyo', '61462', 'Dsn Bandar RT 004 RW 002 Bandarkedungmulyo Bandark', '', 'Jombang', '081330762467', '2020-07-16', 0, 'Y', '', '', '', 2, '', '4002310822', 'BUKOPIN'),
(47, 'ALB000047', 'DAUD SUBADRI', 'KTP', 'L', 'PENDOPO', '1939-07-16', 'D', 'ISLAM', '0', '1571011607390001', '', 'PENSIUNAN', 'SAPUNAH', 'SUNGAI PUTRI', 'TELANAIPURA', '36122', 'JL.ADE IRMA SURYANI RT.002 NO.07 KEL.SUNGAI PUTRI ', '', 'KOTA JAMBI', '081366802121', '2020-07-17', 0, 'Y', '', '', '', 2, '', '2802311297', 'BUKOPIN'),
(48, 'ALB000048', 'MASDAR', 'KTP', 'P', 'UJUNG PANDANG', '1940-10-10', 'J', 'ISLAM', '0', '7372045010400001', '', 'PENSIUNAN', 'HJ. P. IYOMPO', 'CAPPAGALUNG', 'BACUKIKI BARAT', '91122', 'JL. SIRATAL MUSTAKIM', '', 'PAREPARE', '08114211304', '2020-07-16', 0, 'Y', '', '', '', 2, '', '3601311414', 'BUKOPIN'),
(49, 'ALB000049', 'SUKAR', 'KTP', 'L', 'TULUNGAGUNG', '1941-03-01', 'D', 'ISLAM', '0', '3504091503410001', '', 'PENSIUNAN', 'BAHIRAH', 'BENDUNGAN', 'GONDANG', '66263', 'DSN.KRAJAN RT.02/01 BENDUNGAN KEC.GONDANG', '', 'TULUNGAGUNG', '082334153924', '2020-07-16', 0, 'Y', '', '', '', 2, '', '5201331865', 'BUKOPIN'),
(50, 'ALB000050', 'JARIAH', 'KTP', 'P', 'SIGLI', '1942-07-01', 'J', 'ISLAM', '0', '1107094107420091', '', 'PENSIUNAN', 'HAFASAH', 'GAMPONG HASAN', 'KOTA SIGLI', '23351', 'GAMPONG HASAN', '', 'PIDIE', '085210771215', '2020-07-08', 0, 'Y', '', '', '', 2, '', '1362310242', 'BUKOPIN'),
(51, 'ALB000051', 'GAMALI', 'KTP', 'L', 'LUWU', '1938-11-14', 'K', 'ISLAM', '0', '3578231411380001', '', 'PENSIUNAN', 'RABIYAH', 'JAMBANGAN', 'JAMBANGAN', '60232', 'JL JAMBANGAN 4/10', '', 'SURABAYA', '081228327008', '2020-07-26', 0, 'Y', '', '', '', 2, '', '1301330440', 'BUKOPIN'),
(52, 'ALB000052', 'SYAHRI SUWANDI', 'KTP', 'L', 'PURWOKERTO', '1940-09-29', 'K', 'ISLAM', '4', '5271022909400001', '', 'PENSIUNAN', 'SULASTRI', 'MATARAM TIMUR', 'MATARAM', '83121', 'JL SERULING V/8 KR BEDIL MTR RT 007 RW 059 KEL MAT', '', 'MATARAM', '087864306591', '2020-07-23', 0, 'Y', '', '', '', 2, '', '3701313890', 'BUKOPIN'),
(53, 'ALB000053', 'SOEGIARTO', 'KTP', 'L', 'Surabaya', '1939-08-05', 'K', 'ISLAM', '0', '6372020508390001', '', 'PENSIUNAN', 'Kasirah', 'Landasan ulin utara', 'Liang Anggang', '70723', 'JL SUKAMARA GANG KHARISMA NO 7 RT 006 RW 002', '', 'BANJARBRU', '085390919069', '2020-07-24', 0, 'Y', '', '', '', 2, '', '1021330005', 'BUKOPIN'),
(54, 'ALB000054', 'ATMANI', 'KTP', 'P', 'SAMPANG', '1941-03-18', 'J', 'ISLAM', '0', '3527035803470002', '', 'PENSIUNAN', 'BASINI', 'RONGTENGAH', 'SAMPANG', '69211', 'JL PAJUDAN RT 006 RW 003', '', 'SAMPANG', '085334297747', '2020-08-04', 0, 'Y', '', '', '', 2, '', '1307320789', 'BUKOPIN'),
(55, 'ALB000055', 'Achmad Latif', 'KTP', 'L', 'Jombang', '1940-09-30', 'D', 'ISLAM', '0', '3517073009400001', '', 'PENSIUNAN', 'Um Fatoyah', 'Gondek', 'Mojowarno', '61475', 'Jl H Thamrin  Rt 005 Rw 008 Gondek Mojowarno', '', 'Jombang', '085851122036', '2020-08-05', 0, 'Y', '', '', '', 2, '', '4002310221', 'BUKOPIN'),
(56, 'ALB000056', 'ISTIANINGSIH', 'KTP', 'P', 'KEDIRI', '1940-08-07', 'J', 'ISLAM', '0', '3503114708400002', '', 'PENSIUNAN', 'LESTARI', 'KARANGSOKO', 'TRENGGALEK', '66314', 'DSN.SUKOREJO RT.28/06 KARANGSOKO, TRENGGALEK', '', 'TRENGGALEK', '', '2020-08-05', 0, 'Y', '', '', '', 2, '', '5201332644', 'BUKOPIN'),
(57, 'ALB000057', 'MUDAFIR', 'KTP', 'L', 'PAMEKASAN', '0000-00-00', 'K', 'ISLAM', '0', '3528123112420002', '', 'PENSIUNAN', 'SIBA', 'KADUR', 'KADUR', '69355', 'DSN PRENGPENGAN RT 000 RW 003', '', 'PAMEKASAN', '', '2020-08-03', 0, 'Y', '', '', '', 2, '', '1163320171', 'BUKOPIN'),
(58, 'ALB000058', 'TRUIDA SOEDJIWO', 'KTP', 'P', 'KLATEN', '1940-10-01', 'J', 'ISLAM', '0', '3310174110400007', '', 'PENSIUNAN', 'RIWEN', 'KEPRABON', 'POLANHARJO', '', 'PRABON RT 4 RW 2', '', 'KLATEN', '', '2020-08-04', 0, 'Y', '', '', '', 2, '', '1103310574', 'BUKOPIN'),
(59, 'ALB000059', 'H MOH BADRI', 'KTP', 'L', 'SUKABUMI', '1941-03-16', 'D', 'ISLAM', '0', '3202231402560001', '', 'PENSIUNAN', 'HJ SITI SALMAH', 'CILENDEK TIMUR', 'KOTA BOGOR BARAT', '16112', 'CILENDEK TIMUR RT 03 RW 06 KEL CILENDEK TIMUR KEC ', '', 'BOGOR', '085718550101', '2020-08-11', 0, 'Y', '', '', '', 2, '', '2761310345', 'BUKOPIN'),
(60, 'ALB000060', 'SOEMARDI B SOEMOKARSO', 'KTP', 'L', 'SOLO', '1940-09-12', 'K', 'ISLAM', '0', '2172041209400001', '', 'PENSIUNAN', 'SUTI', 'TANJUNGPINANG TIMUR', 'BUKIT BESTARI', '29122', 'JL. BASUKI RAHMAT GG. TEMPINIS I NO. 19 RT. 01 RW.', '', 'TANJUNGPINANG', '081277457952', '2020-08-12', 0, 'Y', '', '', '', 2, '', '3901310337', 'BUKOPIN'),
(61, 'ALB000061', 'DRS RUSDI SAYUTI', 'KTP', 'L', 'LINTAU', '1940-09-16', 'K', 'ISLAM', '4', '2172011609400001', '', 'PENSIUNAN', 'SITI HAWA', 'KAMPUNG BARU', 'TANJUNGPINANG BARAT', '0', 'JL. PANTAI IMPIAN LUMBA-LUMBA III RT. 01 RW. 06', '', 'TANJUNGPINANG', '081364566708', '2020-08-14', 0, 'Y', '', '', '', 2, '', '3901310396', 'BUKOPIN'),
(62, 'ALB000062', 'SUNARTI', 'KTP', 'P', 'TULUNGAGUNG', '1940-08-18', 'J', 'ISLAM', '0', '3504085808480001', '', 'PENSIUNAN', 'KENAH', 'BUNGUR', 'KARANGREJO', '66253', 'DSN.BUNGUR RT.05/01 BUNGUR KEC.KARANGREJO', '', 'TULUNGAGUNG', '', '2020-08-12', 0, 'Y', '', '', '', 2, '', '5201311991', 'BUKOPIN'),
(63, 'ALB000063', 'I GDE NYOMAN MENDRA', 'KTP', 'L', 'TABANAN', '1940-12-11', 'K', 'HINDU', '0', '5271031112400001', '', 'PENSIUNAN', 'NI KETUT SIKA', 'LINGSAR', 'LINGSAR', '0', 'LINGSAR TIMUR KEL LINGSAR KEC LINGSAR', '', 'LOMBOK  BARAT', '087765562351', '2020-08-18', 0, 'Y', '', '', '', 2, '', '3701313696', 'BUKOPIN'),
(64, 'ALB000064', 'ABDUL KAHAR HAS', 'KTP', 'L', 'BENGKALIS', '1941-01-11', 'K', 'ISLAM', '0', '2172041101410001', '', 'PENSIUNAN', 'HABIBAH', 'TANJUNG AYUN SAKTI', 'BUKIT BESTARI', '29124', 'JL. MENTENG I KOMP M.A.N NO. 1 RT. 04 RW. 12', '', 'TANJUNGPINANG', '085263310242', '2020-08-13', 0, 'Y', '', '', '', 2, '', '3901310348', 'BUKOPIN'),
(65, 'ALB000065', 'YOHANNA TAHALELE', 'KTP', 'P', 'CIMAHI', '1939-08-03', 'J', 'KRISTEN', '0', '7210014308390001', '', 'PENSIUNAN', 'SUPHIA RUWAH', 'KALUKUBULA', 'SIGI BIROMARU', '94364', 'JL BTN KELAPA MAS PERMAI B3', '', 'KABUPATEN', '081245228681', '2020-08-11', 0, 'Y', '', '', '', 2, '', '5501311928', 'BUKOPIN'),
(66, 'ALB000066', 'BACHRUM', 'KTP', 'L', 'TAPAKTUAN', '1941-12-01', 'K', 'ISLAM', '0', '1106071204430002', '', 'PENSIUNAN', 'NURHAYATI', 'LAM BHEU', 'DARUL IMARAH', '23352', 'JL KR.JREU UTAMA NO.139', '', 'ACEH BESAR', '082360779210', '2020-08-12', 0, 'Y', '', '', '', 2, '', '1330310704', 'BUKOPIN'),
(67, 'ALB000067', 'SYAMSIAH', 'KTP', 'P', 'TUMPOK 40', '1941-05-13', 'J', 'ISLAM', '0', '1107165305410001', '', 'PENSIUNAN', 'TI HAWA', 'TUMPOK 40', 'PIDIE', '24151', 'TUMPOK 40 KEC.PIDIE', '', 'PIDIE', '085277619389', '2020-08-11', 0, 'Y', '', '', '', 2, '', '1362310021', 'BUKOPIN'),
(68, 'ALB000068', 'CHOTTOB', 'KTP', 'L', 'SUGIWARAS', '1940-10-15', 'D', 'ISLAM', '0', '1671081510400002', '', 'PENSIUNAN', 'STAMNA', 'SAKO', 'SAKO', '30163', 'RSS-A BLOK -22 NO.10 GRIYA HARAPAN RT/RW 78/32', '', 'PALEMBANG', '081218112536', '2020-08-25', 0, 'Y', '', '', '', 2, '', '2103312168', 'BUKOPIN'),
(69, 'ALB000069', 'SUDARMI', 'KTP', 'P', 'Boyolali', '1940-07-15', 'J', 'ISLAM', '0', '1509045507400001', '', 'PENSIUNAN', 'MARKUMI', 'TIRTA KENCANA', 'RIMBO BUJANG', '37553', 'JL.KOLIM RT.05 KEL.TIRTA KENCANA KEC.RIMBO BUJANG ', '', 'KABUPATEN TEBO', '085369567523', '2020-08-20', 0, 'Y', '', '', '', 2, '', '2801311350', 'BUKOPIN'),
(70, 'ALB000070', 'SANTJE JULIANA ROBOT', 'KTP', 'P', 'LANGOWAN', '1938-07-25', 'J', 'KRISTEN', '0', '7171036507380001', '', 'PENSIUNAN', 'MARIA MALANGKONOR', 'TERNATE TANJUNG', 'SINGKIL', '95232', 'LINGKUNGAN II TERNATE TANJUNG KECAMATAN SINGKIL', '', 'MANANADO', '081242138376', '2020-08-26', 0, 'Y', '', '', '', 2, '', '3301317805', 'BUKOPIN'),
(71, 'ALB000071', 'SUNTIANI', 'KTP', 'P', 'MALANG', '1940-11-27', 'J', 'ISLAM', '3', '3671126711400003', '', 'PENSIUNAN', 'MASRAN', 'KARANG TENGAH', 'KARANG TENGAH', '15157', 'JL.MALABAR I/16 RT.001/006 KEL.KARANG TENGAH KEC.K', '', 'KOTA TANGERANG', '087764933303', '2020-08-26', 0, 'Y', '', '', '', 2, '', '4617310081', 'BUKOPIN'),
(72, 'ALB000072', 'ATMANAH', 'KTP', 'P', 'TANJUNG UBAN', '1941-09-30', 'J', 'ISLAM', '0', '2172027009410001', '', 'PENSIUNAN', 'JAWIAH', 'BATU IX', 'TANJUNGPINANG TIMUR', '29125', 'KP. SIDO JASA RT. 04 RW. 03', '', 'TANJUNGPINANG', '082174556793', '2020-08-18', 0, 'Y', '', '', '', 2, '', '3901310659', 'BUKOPIN'),
(73, 'ALB000073', 'H SOEBEKTI PRAPTO BSc', 'KTP', 'L', 'KROYA', '1941-08-18', 'K', 'ISLAM', '4', '5271021808410001', '', 'PENSIUNAN', 'KARTINI', 'TANJUNG KARANG PERMAI', 'SEKARBELA', '83115', 'JL KAPUAS IV/12  PERUMNAS LINGKUNGAN BARITO RT 009', '', 'MATARAM', '085239580642', '2020-09-01', 0, 'Y', '', '', '', 2, '', '3701313969', 'BUKOPIN'),
(74, 'ALB000074', 'SAMPURNI', 'KTP', 'P', 'PASURUAN', '1941-05-04', 'J', 'ISLAM', '0', '3514014405410002', '', 'PENSIUNAN', 'MURIANI', 'GAJAHREJO', 'PURWODADI', '67163', 'DUSUN BAKALAN RT. 007 RW. 002 DESA GAJAHREJO KEC. ', '', 'KABUPATEN PASURUAN', '085272663844', '2020-09-02', 0, 'Y', '', '', '', 2, '', '3402311277', 'BUKOPIN'),
(75, 'ALB000075', 'FATIMAH NOORMA', 'KTP', 'P', 'PALEMBANG', '1940-09-05', 'J', 'ISLAM', '0', '1671114509400003', '', 'PENSIUNAN', 'SUKAISI', 'TALANG SEMUT', 'BUKIT KECIL', '30135', 'JL.MERDEKA NO.687/363 RT/RW 007/003', '', 'PALEMBANG', '082181276587', '2020-09-03', 0, 'Y', '', '', '', 2, '', '2103311779', 'BUKOPIN'),
(76, 'ALB000076', 'DJUNAENI', 'KTP', 'P', 'BOGOR', '1940-12-11', 'J', 'ISLAM', '0', '3171075112400001', '', 'PENSIUNAN', 'SITI KOMARIAH', 'PETAMBURAN', 'TANAH ABANG', '10260', 'JL.PETAMBURAN RT.001/006 KEL.PETAMBURAN KEC.TANAH ', '', 'KOTA JAKARTA PUSAT', '085776246938', '2020-09-10', 0, 'Y', '', '', '', 2, '', '4403350003', 'BUKOPIN'),
(77, 'ALB000077', 'NURMA', 'KTP', 'P', 'PADANG', '1939-12-12', 'J', 'ISLAM', '0', '1371115212390005', '', 'PENSIUNAN', 'ANI', 'AIR PACAH', 'KOTO TANGAH', '25176', 'JL MARANSI AIR PACAH PADANG RT 005 / RW 004 ', '', 'KOTA PADANG', '085265327230', '2020-09-13', 0, 'Y', '', '', '', 2, '', '0361330202', 'BUKOPIN'),
(78, 'ALB000078', 'ALI SUIR', 'KTP', 'L', 'PALEMBAYAN', '1941-06-30', 'K', 'ISLAM', '0', '1305113006410007', '', 'PENSIUNAN', 'KILAUK', 'SINTUK', 'SINTUK TOBOH GADANG', '25582', 'TANJUNG PISANG ', '', 'KABUPATEN PADANG PARIAMAN', '085272727340', '2020-09-16', 0, 'Y', '', '', '', 2, '', '0361312875', 'BUKOPIN'),
(79, 'ALB000079', 'MAWARDI', 'KTP', 'L', 'TAPAKTUAN', '1941-07-16', 'K', 'ISLAM', '0', '1106011607410003', '', 'PENSIUNAN', 'SITI ANSANI', 'PAROY', 'LHOONG', '23354', 'GAMPONG PAROY', '', 'ACEH BESAR', '081269878756', '2020-09-14', 0, 'Y', '', '', '', 2, '', '1330330112', 'BUKOPIN'),
(80, 'ALB000080', 'ASMARA', 'KTP', 'P', 'TANJUNGPINANG', '1943-07-01', 'J', 'ISLAM', '0', '2101064107430073', '', 'PENSIUNAN', 'MIZAH', 'KIJANG KOTA', 'BINTAN TIMUR', '29151', 'KP. SEI DATUK RT. 02 RW. 05', '', 'BINTAN', '081270006313', '2020-09-17', 0, 'Y', '', '', '', 2, '', '3901310661', 'BUKOPIN'),
(81, 'ALB000081', 'SUNDIAH', 'KTP', 'P', 'KEDIRI', '1943-01-01', 'J', 'ISLAM', '0', '6472064101430011', '', 'PENSIUNAN', 'SUPINGATUN', 'KARANG ASAM ILIR', 'SUNGAI KUNJANG', '75126', 'JL SLAMET RIADI RT 16', '', 'SAMARINDA', '085348581463', '2020-09-16', 0, 'Y', '', '', '', 2, '', '1902310389', 'BUKOPIN'),
(82, 'ALB000082', 'Sulaiman', 'KTP', 'L', 'Lamongan', '1940-12-31', 'D', 'ISLAM', '0', '3578143006400015', '', 'PENSIUNAN', 'Sukaemi', 'Manukan Wetan', 'Tandes', '60185', 'Jl Sikatan  XI/16 Rt 005 Rw 001 Manukan Wetan Tand', '', 'Surabaya', '085607197387', '2020-09-09', 0, 'Y', '', '', '', 2, '', '1307321111', 'BUKOPIN'),
(83, 'ALB000083', 'MASDOEKI', 'KTP', 'L', 'BLITAR', '1941-05-23', 'K', 'ISLAM', '0', '3572032305410002', '', 'PENSIUNAN', 'RAKIL', 'SANANWETAN', 'SANANWETAN', '66131', 'JL.KEP SERIBU 7/46 C RT.2 RW.10 KEL.SANANWETAN KEC', '', 'KOTA BLITAR', '085856855568', '2020-09-21', 0, 'Y', '', '', '', 2, '', '5263330341', 'BUKOPIN'),
(84, 'ALB000084', 'FIENTJE  ANTAMENG ', 'KTP', 'P', 'SAWANG', '1940-11-07', 'J', 'KRISTEN', '0', '7109044711400002', '', 'PENSIUNAN', 'MARTHA DARUMBA', 'SAWANG', 'SIAU TIMUR SELATAN', '95851', 'SAWANG SIAU TIMUR SELATAN', '', 'SIAU TAGULANDANG BIARO', '082344483346', '2020-09-22', 0, 'Y', '', '', '', 2, '', '3301311804', 'BUKOPIN'),
(85, 'ALB000085', 'MARGERETHA HEHANUSSA', 'KTP', 'P', 'ALLANG', '1941-04-26', 'J', 'KRISTEN', '0', '9201076604410001', '', 'PENSIUNAN', 'YAKOBA HUWAE', 'MARIYAI', 'MARIAT', '98445', 'JL.MENUR', '', 'KABUPATEN SORONG', '082197716107', '2020-09-17', 0, 'Y', '', '', '', 2, '', '5401341182', 'BUKOPIN'),
(86, 'ALB000086', 'MOEDJIJATOEN', 'KTP', 'P', 'BLITAR', '1942-09-13', 'J', 'ISLAM', '0', '3505015309420001', '', 'PENSIUNAN', 'BANISAH', 'KEBONAGUNG', 'WONODADI', '66155', 'KEBONAGUNG I RT.2 RW.1 DESA KEBONAGUNG KEC.WONODAD', '', 'KABUPATEN BLITAR', '081316489417', '2020-09-18', 0, 'Y', '', '', '', 2, '', '5263310431', 'BUKOPIN'),
(87, 'ALB000087', 'SUJI DG RATU', 'KTP', 'P', 'TAKALAR', '1942-12-31', 'J', 'ISLAM', '0', '7371027112420032', '', 'PENSIUNAN', 'DG. NGEMPENG', 'KARANG ANYAR', 'MAMAJANG', '90134', 'JL. CENDERAWASI LR. 15 NO. 36 ZE', '', 'MAKASSAR', '082352119540', '2020-09-23', 0, 'Y', '', '', '', 2, '', '1605311221', 'BUKOPIN'),
(88, 'ALB000088', 'Ruminah', 'KTP', 'P', 'Banjarnegara', '1942-04-21', 'J', 'ISLAM', '0', '3304066104420007', '', 'PENSIUNAN', 'Toyibah', 'Karangtengah', 'Karangtengah', '53416', 'Karangtengah RT005 RW001 Karangtengah Banjarnegara', '', 'Kabupaten', '081216474135', '2020-09-25', 0, 'Y', '', '', '', 2, '', '3062310210', 'BUKOPIN'),
(89, NULL, 'ANGGI ANDRIANSYAH', 'ADMIN', 'L', '-', '2020-10-22', 'Kawin', '', '-', '-', '', '', NULL, '-', NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '-', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 1, '', '4206001952', 'BANK BUKOPIN'),
(90, 'ASRIAL CHANIAGO', 'ASRIAL CHANIAGO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', 'Kawin', '', '-', '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 1, '', '0101002901', 'BANK BUKOPIN'),
(91, NULL, 'ASRIAL CHANIAGO', 'ADMIN', 'L', '-', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101002901', 'BANK BUKOPIN'),
(92, NULL, 'ASRIAL CHANIAGO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', 'Kawin', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 1, '', '0101002901', 'BANK BUKOPIN'),
(93, NULL, 'BAMBANG TRIONO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', 'Kawin', '', '-', '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101000539', 'BANK BUKOPIN'),
(94, NULL, 'BENFITRADI', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', 'Kawin', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101099708', 'BANK BUKOPIN'),
(95, NULL, 'EDY PRAMANA', 'ADMIN', 'L', 'KENDAL', '0000-00-00', 'Kawin', '', NULL, '3175041406580009', '', '', NULL, NULL, NULL, NULL, 'JL SDI NO. 64 RT 008 RW 006\nKEL BATU AMPAR\nKEC KRAMAT TJATI', '', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101031544', 'BANK BUKOPIN'),
(96, NULL, 'FATHURROHIM', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '370100008', 'BANK BUKOPIN'),
(97, NULL, 'HARI HARMONO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101056791', 'BANK BUKOPIN'),
(98, NULL, 'HARYO AGUNG SUDARSONO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0430200008', 'BANK BUKOPIN'),
(99, NULL, 'HASANUDDIN TARUG', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0801016185', 'BANK BUKOPIN'),
(100, NULL, 'HENDRA SIDHARTA', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '4202002029', 'BANK BUKOPIN'),
(101, NULL, 'MUKDAN LUBIS', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101058098', 'BANK BUKOPIN'),
(102, NULL, 'HANNY RACHMALIA', 'ADMIN', 'P', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101109915', 'BANK BUKOPIN'),
(103, NULL, 'JONY NUR EFFENDY', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101099194', 'BANK BUKOPIN'),
(104, NULL, 'KADMINA', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101087600', 'BANK BUKOPIN'),
(105, NULL, 'IR KAREL PALALLO', 'ADMIN', 'L', 'AMBON', '0000-00-00', 'Kawin', 'Islam', NULL, '3275041201550012', '', '', NULL, NULL, NULL, NULL, 'JL PANGRANGO I BLOK 3 NO. 8 RT 005 RW 014\nKEL. KAYURINGIN JAYA\nKEC. BEKASI SELATAN\nBEKASI', '', 'BEKASI', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '4705002209', 'BANK BUKOPIN'),
(106, NULL, 'MANUDIN HASAN', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101054903', 'BANK BUKOPIN'),
(107, NULL, 'MOCH AZIZ YUSUP', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '1001200001', 'BANK BUKOPIN'),
(108, NULL, 'MULYANA', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101005822', 'BANK BUKOPIN'),
(109, NULL, 'RACHMURSITO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '1101008298', 'BANK BUKOPIN'),
(110, NULL, 'RUDY SOESATYO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '7710006095', 'BANK BUKOPIN'),
(111, NULL, 'SUFLAN RIZAL', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '2001024225', 'BANK BUKOPIN'),
(112, NULL, 'SUTRISNO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '7710030047', 'BANK BUKOPIN'),
(113, NULL, 'ZENIANTO WIBOWO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101003216', 'BANK BUKOPIN'),
(114, NULL, 'DEDY ERADIAS', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '2201001593', 'BANK BUKOPIN'),
(115, NULL, 'MARWAN', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '4901000008', 'BANK BUKOPIN'),
(116, NULL, 'TENGKU HARRY CAHYADI', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '128001202', 'BANK BUKOPIN'),
(117, NULL, 'YUFITA DEVIANI', 'ADMIN', 'P', 'BEKASI', '0000-00-00', 'Kawin', 'Islam', NULL, '3275016206890020', '', '', NULL, NULL, NULL, NULL, 'DUREN JAYA BLOK D 275\nDUREN JAYA\nBEKASI TIMUR', 'BEKASI', 'BEKASI', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '4206001955', 'BANK BUKOPIN'),
(118, NULL, 'HIMAWAN BUDI SANTOSO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101088432', 'BANK BUKOPIN'),
(119, NULL, 'MARTHA IRAWAN PUTRA UTAMA', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0702015497', 'BANK BUKOPIN'),
(120, NULL, 'SADARUDDIN', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0101045385', 'BANK BUKOPIN'),
(121, NULL, 'JEFRI MARLON', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '0501023551', 'BANK BUKOPIN'),
(122, NULL, 'ARIF GUSTAMAN', 'ADMIN', 'L', 'JAKARTA', '0000-00-00', 'Kawin', '', NULL, '3175071408820004', '', '', NULL, NULL, NULL, NULL, 'KAV DKI BLK K.6/9\nRT 013 RW 009\nKEL.PONDOK KELAPA\nKEC.DUREN SAWIT\n', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '-', '-'),
(123, NULL, 'HARI SANTOSO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '-', '-'),
(124, NULL, 'HIDAYATULLAH', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, '-', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '-', '-'),
(125, NULL, 'BAMBANG WIDYATMOKO', 'ADMIN', 'L', 'JAKARTA', '2605-01-17', '', '', NULL, 'JAKARTA', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '-', '-'),
(126, NULL, 'ENDANG SETYAWIDI', 'ADMIN', 'P', 'JAKARTA', '2605-01-17', '', '', NULL, 'JAKARTA', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '-', '-'),
(127, NULL, 'NURUL HUSNA', 'ADMIN', 'P', 'JAKARTA', '2605-01-17', '', '', NULL, 'JAKARTA', '', '', NULL, NULL, NULL, NULL, 'JAKARTA', 'JAKARTA', 'JAKARTA', '', '2605-01-17', 1, 'Y', '', '1c30de80c0800d4c78776649d772d644d991f552', '', 0, '', '-', '-'),
(128, 'ALB000089', 'JUARIAH', 'KTP', 'P', 'TASIKMALAYA', '1941-05-08', 'J', 'ISLAM', '0', '3278084805410001', '', 'PENSIUNAN', 'MURDANINGSIH', 'MANGKUBUMI', 'MANGKUBUMI', '46181', 'CIBATUR RT/RW 003/012 KEL MANGKUBUMI KEC MANGKUBUM', '', 'TASIKMALAYA', '082317704699', '2020-10-02', 0, 'Y', '', '', '', 2, '', '3501310912', 'BUKOPIN'),
(129, 'ALB000090', 'FX MARJONO', 'KTP', 'L', 'MOJOKERTO', '1940-12-23', 'K', 'KHATOLIK', '0', '3577022312400001', '', 'PENSIUNAN', 'Ra Indijah Amar', 'Pangongangan', 'Manguharjo', '63121', 'Jl A Yani No 21 Madiun RT/RW 12/05 Pangongangan Ma', '', 'MADIUN', '081234763321', '2020-10-05', 0, 'Y', '', '', '', 2, '', '5101330465', 'BUKOPIN'),
(130, 'ALB000091', 'IDA SAMIAH', 'KTP', 'P', 'MAJALENGKA', '1940-10-10', 'J', 'ISLAM', '0', '3278065010400004', '', 'PENSIUNAN', 'EMEH', 'SETIARATU', 'CIBEUREUM', '46196', 'KP SILUMAN RT/RW  002/009 KEL SETIARATU KEC CIBEUR', '', 'TASIKMALAYA', '085323033114', '2020-10-08', 0, 'Y', '', '', '', 2, '', '3501310862', 'BUKOPIN'),
(131, 'ALB000092', 'M.BR.NAPITUPULU', 'KTP', 'P', 'TARUTUNG', '1942-09-04', 'J', 'KRISTEN', '0', '1571024409420001', '', 'PENSIUNAN', 'S.BR SIMANJUNTAK', 'WIJAYA PURA', 'JAMBI SELATAN', '36131', 'JLN.M.YUSUF NASRI RT.19 NO.22 KEL.WIJAYA PURA KEC.', '', 'KOTA JAMBI', '081366247217', '2020-10-13', 0, 'Y', '', '', '', 2, '', '2802311300', 'BUKOPIN'),
(132, 'ALB000093', 'SUBIYANTI', 'KTP', 'P', 'MAGETAN', '1942-01-04', 'L', 'ISLAM', '0', '3520124101420010', '', 'PENSIUNAN', 'sumirah', 'rejomulyo', 'barat', '63137', 'Desa Rejomulyo RT/RW 10/02 Rejomulyo Barat', '', 'MAGETAN', '', '2020-10-13', 0, 'Y', '', '', '', 2, '', '5101311458', 'BUKOPIN'),
(133, 'ALB000094', 'MARDIJAH', 'KTP', 'P', 'BANYUWANGI', '1942-02-08', 'J', 'ISLAM', '0', '3511114802420001', '', 'PENSIUNAN', 'Mursinem', 'TAMAN SARI', 'BONDOWOSO', '68216', 'Ade Irma Suryani 8 RT 03 RW 01 Desa Tamansari Kec.', '', 'BONDOWOSO', '085258844462', '2020-10-12', 0, 'Y', '', '', '', 2, '', '3202311459', 'BUKOPIN'),
(134, 'ALB000095', 'M FADAL', 'KTP', 'L', 'PAMEKASAN', '1942-01-01', 'K', 'ISLAM', '0', '3528040101420004', '', 'PENSIUNAN', 'MARIYAH', 'TEJAH BARAT', 'PAMEKASAN', '69351', 'JL TEJA RT 001 RW 001', '', 'PAMEKASAN', '085336245359', '2020-10-13', 0, 'Y', '', '', '', 2, '', '1307320786', 'BUKOPIN'),
(135, 'ALB000096', 'MISIRAN MISWANTO', 'KTP', 'L', 'PONOROGO', '1941-08-12', 'D', 'ISLAM', '0', '3503101208410001', '', 'PENSIUNAN', 'MUNAH', 'WONOREJO', 'GANDUSARI', '66372', 'DSN.SETRI RT.02/01 WONOREJO KEC.GANDUSARI', '', 'TRENGGALEK', '', '2020-10-20', 0, 'Y', '', '', '', 2, '', '5201312081', 'BUKOPIN'),
(136, NULL, 'AHMAD', 'admin', 'L', 'MUARA LAKITAN', '1946-08-07', 'Kawin', 'Islam', NULL, '1605020708460004', '', 'Pensiunan', 'SAHIMON', 'MUARALAKITAN', 'MUARALAKITAN', '31666', 'KEL.MUARA LAKITAN RT/RW 009/003', 'KEL.MUARA LAKITAN RT/RW 009/003', 'MUSI RAWAS', '081373684818', '2020-09-01', 2, 'N', '', '224bec3dd08832bc6a69873f15a50df406045f40', '', 3, '', '2124310016', 'BUKOPIN'),
(137, NULL, 'ANIMAH', 'admin', 'P', 'KARANG DALAM', '1944-12-30', 'Cerai Mati', 'Islam', NULL, '1604087012440003', '', 'Pensiunan', 'DJASIDAH', 'KARANG DALAM', 'PULAU PINANG', '31463', 'KARANG DALAM RT/RW -/-', 'KARANG DALAM RT/RW -/-', 'LAHAT', '082178520907', '2020-09-01', 2, 'N', '', '224bec3dd08832bc6a69873f15a50df406045f40', '', 3, '', '2123310021', 'BUKOPIN'),
(138, NULL, 'DARWONO', 'admin', 'L', 'AUSTRALIA', '1945-11-27', '', '', NULL, '2172012711450001', '', 'Pensiunan', NULL, NULL, NULL, NULL, 'KP. MEKAR SARI RT.03 RW. 08 PINANG KENCANA', '', 'TANJUNGPINANG', '081364478104', '2020-09-04', 2, 'N', '', '224bec3dd08832bc6a69873f15a50df406045f40', '', 3, '', '3901310652', 'BUKOPIN'),
(139, NULL, 'DJALEHA', 'admin', 'P', 'TELUK BAYUR', '1948-03-04', '', '', NULL, '6472034403480001', '', '', NULL, NULL, NULL, NULL, 'JL ANGGREK PANDA 3', '', 'SAMARINDA', '082255806559', '2020-09-01', 2, 'N', '', '', '', 3, '', '1902310570', 'BUKOPIN'),
(140, NULL, 'DJODJOH SURYATI', 'admin', 'P', 'TASIKMALAYA', '1945-12-29', '', '', NULL, '3206136912450001', '', '', NULL, NULL, NULL, NULL, 'KP KUDANG 025/001 KEL BANYUASIH KEC TARAJU', '', 'TASIKMALAYA', '', '2020-09-01', 2, 'N', '', '', '', 3, '', '3501311000', 'BUKOPIN'),
(141, NULL, 'JOSEP MAKU', 'admin', 'L', 'ATAMBUA', '1948-05-04', '', '', NULL, '5304210405480002', '', '', NULL, NULL, NULL, NULL, 'LINGKUNGAN HALINURAK RT 015 RW 005', '', 'BELU', '081246846361', '2020-09-02', 2, 'N', '', '', '', 3, '', '1622310017', 'BUKOPIN'),
(142, NULL, 'ROHMI M', 'admin', 'L', 'TANJUNG KARANGAN', '1946-07-21', '', '', NULL, '1603012107460001', '', '', NULL, NULL, NULL, NULL, 'DS.TANJUNG KARANGAN RT/RW 001/001', '', 'MUARA ENIM', '082182048596', '2020-09-01', 2, 'N', '', '', '', 3, '', '2125310007', 'BUKOPIN'),
(143, NULL, 'SAMINAH', 'admin', 'P', 'SOLO', '1942-11-10', '', '', NULL, '3174105011420001', '', '', NULL, NULL, NULL, NULL, 'KP. SAWAH RT.004 RW.006', '', 'JAKARTA SELATAN', '081380865661', '2020-09-01', 2, 'N', '', '', '', 3, '', '5302310245', 'BUKOPIN'),
(144, NULL, 'TR SIAHAAN', 'admin', 'P', 'BALIGE', '1946-03-19', '', '', NULL, '1271051903460001', '', '', NULL, NULL, NULL, NULL, 'JL. TM HAMZAH GG. MELATI NO.10  KEL. SEI AGUL KEC', '', 'KOTA MEDAN', '085762897857', '2020-09-03', 2, 'N', '', '', '', 3, '', '6401330011', 'BUKOPIN');

--
-- Triggers `tbl_anggota`
--
DELIMITER $$
CREATE TRIGGER `tbl_anggota_before_insert` BEFORE INSERT ON `tbl_anggota` FOR EACH ROW BEGIN
	
  DECLARE vjns_anggotaid INT;
  DECLARE vkode, vnomor_anggota, vmaxid VARCHAR(50);
  
  if ( NEW.no_anggota is NULL )  then
  
	  SELECT b.kode
	  INTO vkode
	  FROM jns_anggota b
	  WHERE b.id = NEW.jns_anggotaid;
	  
	  SELECT CONCAT(vkode,lpad(MAX(REPLACE(no_anggota,vkode,''))+1,6,'0'))
	  INTO vmaxid
	  FROM tbl_anggota WHERE no_anggota LIKE CONCAT(vkode , '%');

	  if ( vmaxid IS NULL ) then
	  		SET NEW.no_anggota = CONCAT(vkode,'000001');
	  	else 
	  		SET NEW.no_anggota = vmaxid;
	  end if;
  
  end if;
  
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_barang`
--

CREATE TABLE `tbl_barang` (
  `id` bigint(20) NOT NULL,
  `nm_barang` varchar(255) CHARACTER SET latin1 NOT NULL,
  `type` varchar(50) CHARACTER SET latin1 NOT NULL,
  `merk` varchar(50) CHARACTER SET latin1 NOT NULL,
  `harga` decimal(50,0) NOT NULL DEFAULT 0,
  `jml_brg` int(11) NOT NULL,
  `ket` varchar(255) CHARACTER SET latin1 NOT NULL,
  `inventory` enum('Y','T') CHARACTER SET latin1 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_barang`
--

INSERT INTO `tbl_barang` (`id`, `nm_barang`, `type`, `merk`, `harga`, `jml_brg`, `ket`, `inventory`) VALUES
(1, 'sidu f4', 'kertas', 'sidu', 60000, 2, 'sidu kertas', 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_pengajuan`
--

CREATE TABLE `tbl_pengajuan` (
  `id` bigint(20) NOT NULL,
  `no_ajuan` int(11) NOT NULL,
  `ajuan_id` varchar(255) NOT NULL,
  `anggota_id` bigint(20) NOT NULL,
  `tgl_input` datetime NOT NULL,
  `jenis` varchar(255) NOT NULL,
  `nominal` bigint(20) NOT NULL,
  `lama_ags` int(11) NOT NULL,
  `keterangan` varchar(255) NOT NULL,
  `status` tinyint(4) NOT NULL,
  `alasan` varchar(255) NOT NULL,
  `tgl_cair` date NOT NULL,
  `tgl_update` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_pinjaman_d`
--

CREATE TABLE `tbl_pinjaman_d` (
  `id` int(11) NOT NULL,
  `tgl_bayar` datetime NOT NULL,
  `pinjam_id` int(11) NOT NULL DEFAULT 0,
  `angsuran_ke` int(11) NOT NULL DEFAULT 0,
  `jumlah_bayar` decimal(30,2) NOT NULL DEFAULT 0.00,
  `denda_rp` decimal(30,2) NOT NULL DEFAULT 0.00,
  `terlambat` int(11) NOT NULL,
  `ket_bayar` enum('Angsuran','Pelunasan','Bayar Denda') NOT NULL,
  `dk` enum('D','K') NOT NULL,
  `kas_id` int(11) NOT NULL DEFAULT 0,
  `jns_trans` int(11) NOT NULL DEFAULT 0,
  `update_data` datetime NOT NULL,
  `user_name` varchar(255) NOT NULL,
  `keterangan` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_pinjaman_d`
--

INSERT INTO `tbl_pinjaman_d` (`id`, `tgl_bayar`, `pinjam_id`, `angsuran_ke`, `jumlah_bayar`, `denda_rp`, `terlambat`, `ket_bayar`, `dk`, `kas_id`, `jns_trans`, `update_data`, `user_name`, `keterangan`) VALUES
(2, '2020-09-17 06:25:00', 88, 1, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(3, '2020-09-28 12:25:00', 87, 1, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(4, '2020-09-28 16:25:00', 87, 2, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(5, '2020-09-23 16:30:00', 84, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(6, '2020-10-16 16:35:00', 83, 1, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(7, '2020-09-24 12:35:00', 86, 1, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(8, '2020-09-24 13:35:00', 85, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(9, '2020-09-24 13:35:00', 85, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020'),
(10, '2020-09-17 13:40:00', 80, 1, 1142333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(11, '2020-09-17 13:50:00', 80, 2, 1142333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020'),
(12, '2020-09-17 13:50:00', 78, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(13, '2020-09-18 13:55:00', 81, 1, 622000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(14, '2020-09-17 13:20:00', 79, 1, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(15, '2020-09-16 10:35:00', 77, 1, 1324333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(16, '2020-10-19 10:39:00', 76, 1, 735867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(17, '2020-09-18 10:30:00', 82, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(18, '2020-10-19 10:43:00', 75, 1, 712300.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(19, '2020-09-04 10:45:00', 74, 1, 1063467.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(20, '2020-09-03 10:30:00', 73, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(21, '2020-09-03 10:45:00', 73, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020'),
(22, '2020-08-27 10:50:00', 70, 1, 1106800.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(23, '2020-08-27 10:50:00', 70, 2, 1106800.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(24, '2020-08-28 10:50:00', 71, 1, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(25, '2020-10-01 10:50:00', 71, 2, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(26, '2020-08-27 10:55:00', 68, 1, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(27, '2020-10-01 10:55:00', 68, 2, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(28, '2020-08-27 11:00:00', 69, 1, 1213967.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(29, '2020-10-01 11:00:00', 69, 2, 1213967.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(30, '2020-08-25 11:05:00', 63, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(31, '2020-10-01 11:05:00', 63, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(32, '2020-08-31 11:05:00', 72, 1, 1045267.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(33, '2020-08-31 11:05:00', 72, 2, 1045267.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(34, '2020-08-18 11:10:00', 61, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(35, '2020-10-01 11:10:00', 61, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(36, '2020-08-25 11:10:00', 64, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020 '),
(37, '2020-10-01 11:10:00', 64, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020 '),
(38, '2020-08-24 11:15:00', 62, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(39, '2020-10-01 11:15:00', 62, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(40, '2020-08-13 11:15:00', 60, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(41, '2020-10-01 11:15:00', 60, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(42, '2020-08-26 11:25:00', 66, 1, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(43, '2020-10-01 11:25:00', 66, 2, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(44, '2020-08-26 11:30:00', 67, 1, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(45, '2020-10-01 11:30:00', 67, 2, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(46, '2020-08-12 11:30:00', 59, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(47, '2020-10-01 11:30:00', 59, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(48, '2020-08-26 11:35:00', 65, 1, 1169500.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(49, '2020-08-26 11:35:00', 65, 2, 1169500.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(50, '2020-08-07 11:40:00', 55, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(51, '2020-10-01 11:40:00', 55, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(52, '2020-08-07 13:35:00', 56, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(53, '2020-10-01 13:35:00', 56, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(54, '2020-08-10 13:35:00', 58, 1, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(55, '2020-10-01 13:35:00', 58, 2, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(56, '2020-08-06 13:40:00', 54, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(57, '2020-10-01 13:40:00', 54, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(58, '2020-08-10 13:45:00', 57, 1, 960333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sept 2020'),
(59, '2020-10-01 13:45:00', 57, 2, 960333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(60, '2020-07-27 13:45:00', 51, 1, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(61, '2020-07-27 13:45:00', 51, 2, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(62, '2020-10-01 13:45:00', 51, 3, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(63, '2020-07-30 13:50:00', 53, 1, 1725667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(64, '2020-07-30 13:50:00', 53, 2, 1725667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(65, '2020-10-01 13:50:00', 53, 3, 1725667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(66, '2020-07-28 13:55:00', 52, 1, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(67, '2020-09-01 13:55:00', 52, 2, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(68, '2020-10-01 13:55:00', 52, 3, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(69, '2020-07-20 13:55:00', 47, 1, 1876167.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(70, '2020-09-01 13:55:00', 47, 2, 1876167.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(71, '2020-10-01 13:55:00', 47, 3, 1876167.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(72, '2020-07-20 14:00:00', 48, 1, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(73, '2020-07-20 14:00:00', 48, 2, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(74, '2020-10-01 14:00:00', 48, 3, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs okt 2020'),
(75, '2020-07-23 14:00:00', 49, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(76, '2020-09-01 14:00:00', 49, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(77, '2020-10-01 14:00:00', 49, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(78, '2020-07-17 14:05:00', 46, 1, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(79, '2020-09-01 14:00:00', 46, 2, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(80, '2020-10-01 14:05:00', 46, 3, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(81, '2020-07-16 14:00:00', 44, 1, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(82, '2020-09-01 14:00:00', 44, 2, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(83, '2020-10-15 14:00:00', 44, 3, 16500000.00, 0.00, 0, 'Pelunasan', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Pelunasan Deb MD an Aslichah'),
(84, '2020-07-15 14:00:00', 41, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(85, '2020-09-01 14:00:00', 41, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(86, '2020-10-01 14:00:00', 41, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs okt 2020'),
(87, '2020-07-16 14:00:00', 42, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(88, '2020-09-01 14:00:00', 42, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(89, '2020-10-01 14:00:00', 42, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(90, '2020-07-16 14:00:00', 43, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(91, '2020-09-01 14:00:00', 43, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(92, '2020-10-01 14:00:00', 43, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(93, '2020-07-17 14:00:00', 45, 1, 1866133.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(94, '2020-09-01 14:00:00', 45, 2, 1866133.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(95, '2020-10-01 14:00:00', 45, 3, 1866133.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(96, '2020-07-13 14:00:00', 39, 1, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(97, '2020-09-01 14:00:00', 39, 2, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(98, '2020-10-01 14:00:00', 39, 3, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(99, '2020-07-14 14:00:00', 40, 1, 1105933.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(100, '2020-09-01 14:00:00', 40, 2, 1105933.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(101, '2020-10-01 14:40:00', 40, 3, 1105933.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(102, '2020-07-10 14:00:00', 35, 1, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(103, '2020-09-01 14:00:00', 35, 2, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(104, '2020-10-01 14:40:00', 35, 3, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(105, '2020-07-10 14:00:00', 37, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(106, '2020-09-01 14:00:00', 37, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(107, '2020-10-01 14:00:00', 37, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(108, '2020-07-23 14:00:00', 50, 1, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(109, '2020-07-23 14:00:00', 50, 2, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(110, '2020-10-01 12:00:00', 50, 3, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(111, '2020-07-13 08:00:00', 38, 1, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(112, '2020-09-01 08:00:00', 38, 2, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(113, '2020-10-01 08:00:00', 38, 3, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(114, '2020-07-09 08:00:00', 33, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(115, '2020-07-09 08:00:00', 33, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(116, '2020-10-01 08:00:00', 33, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(117, '2020-07-09 08:00:00', 34, 1, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(118, '2020-09-01 08:00:00', 34, 2, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(119, '2020-10-01 08:00:00', 34, 3, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(120, '2020-07-10 08:00:00', 36, 1, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(121, '2020-09-01 08:00:00', 36, 2, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(122, '2020-10-01 08:00:00', 36, 3, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(123, '2020-07-08 08:00:00', 32, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(124, '2020-09-01 08:00:00', 32, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(125, '2020-10-01 08:00:00', 32, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(126, '2020-07-06 08:00:00', 31, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(127, '2020-09-01 08:00:00', 31, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(128, '2020-10-01 08:00:00', 31, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(129, '2020-07-03 08:00:00', 29, 1, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(130, '2020-09-01 08:00:00', 29, 2, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(131, '2020-10-01 08:00:00', 29, 3, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(132, '2020-07-03 08:00:00', 30, 1, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(133, '2020-09-01 08:00:00', 30, 2, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(134, '2020-10-01 08:00:00', 30, 3, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(135, '2020-07-02 08:00:00', 27, 1, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(136, '2020-09-01 08:00:00', 27, 2, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(137, '2020-10-01 08:00:00', 27, 3, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(138, '2020-07-03 08:00:00', 28, 1, 1254100.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(139, '2020-09-01 08:00:00', 28, 2, 1254100.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(140, '2020-10-01 08:00:00', 28, 3, 1254100.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(141, '2020-06-30 08:00:00', 26, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(142, '2020-06-30 08:00:00', 26, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(143, '2020-09-01 08:00:00', 26, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(144, '2020-10-01 08:00:00', 26, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(145, '2020-06-25 08:00:00', 24, 1, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(146, '2020-08-01 08:00:00', 24, 2, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(147, '2020-09-01 08:00:00', 24, 3, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(148, '2020-10-01 08:00:00', 24, 4, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(149, '2020-06-22 08:00:00', 21, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(150, '2020-08-01 08:00:00', 21, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(151, '2020-09-01 08:00:00', 21, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(152, '2020-10-01 08:00:00', 21, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(153, '2020-06-25 08:00:00', 23, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(154, '2020-08-01 08:00:00', 23, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(155, '2020-09-01 08:00:00', 23, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(156, '2020-10-01 08:00:00', 23, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(157, '2020-06-25 08:00:00', 25, 1, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(158, '2020-08-01 08:00:00', 25, 2, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(159, '2020-09-01 08:00:00', 25, 3, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(160, '2020-10-01 08:00:00', 25, 4, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(161, '2020-06-22 08:00:00', 20, 1, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(162, '2020-08-01 08:00:00', 20, 2, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(163, '2020-09-01 08:00:00', 20, 3, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(164, '2020-10-01 08:00:00', 20, 4, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(165, '2020-06-19 08:00:00', 19, 1, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(166, '2020-08-01 08:00:00', 19, 2, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(167, '2020-09-01 08:00:00', 19, 3, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(168, '2020-10-01 08:00:00', 19, 4, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(169, '2020-06-19 08:00:00', 18, 1, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(170, '2020-08-01 08:00:00', 18, 2, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(171, '2020-09-01 08:00:00', 18, 3, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(172, '2020-10-01 08:00:00', 18, 4, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(173, '2020-06-17 08:00:00', 16, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(174, '2020-08-01 08:00:00', 16, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(175, '2020-09-01 08:00:00', 16, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(176, '2020-10-01 08:00:00', 16, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(177, '2020-06-18 08:00:00', 17, 1, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(178, '2020-08-01 08:00:00', 17, 2, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(179, '2020-09-01 08:00:00', 17, 3, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(180, '2020-10-01 08:00:00', 17, 4, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(181, '2020-06-17 08:00:00', 14, 1, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(182, '2020-08-01 15:20:00', 14, 2, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(183, '2020-09-01 08:00:00', 14, 3, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(184, '2020-10-01 08:00:00', 14, 4, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(185, '2020-06-17 08:00:00', 15, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(186, '2020-08-01 08:00:00', 15, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(187, '2020-09-01 08:00:00', 15, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(188, '2020-10-01 08:00:00', 15, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(189, '2020-06-15 08:00:00', 11, 1, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(190, '2020-08-01 08:00:00', 11, 2, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(191, '2020-09-01 08:00:00', 11, 3, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(192, '2020-10-01 08:00:00', 11, 4, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs okt 2020'),
(193, '2020-06-23 08:00:00', 22, 1, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(194, '2020-08-01 08:00:00', 22, 2, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(195, '2020-09-01 08:00:00', 22, 3, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(196, '2020-10-01 08:00:00', 22, 4, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(197, '2020-06-16 08:00:00', 13, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(198, '2020-06-16 12:00:00', 13, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(199, '2020-09-01 08:00:00', 13, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(200, '2020-10-01 08:00:00', 13, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(201, '2020-06-11 08:00:00', 8, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(202, '2020-08-01 08:00:00', 8, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(203, '2020-09-01 08:00:00', 8, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(204, '2020-10-01 08:00:00', 8, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(205, '2020-06-11 08:00:00', 9, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(206, '2020-08-01 08:00:00', 9, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(207, '2020-09-01 08:00:00', 9, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(208, '2020-10-01 08:00:00', 9, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(209, '2020-06-12 08:00:00', 10, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(210, '2020-08-01 08:00:00', 10, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(211, '2020-09-01 08:00:00', 10, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(212, '2020-10-01 08:00:00', 10, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(213, '2020-06-11 08:00:00', 6, 1, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(214, '2020-09-09 08:00:00', 6, 2, 14375000.00, 0.00, 0, 'Pelunasan', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Pelunasan Deb MD Sutrisno HP'),
(215, '2020-06-11 08:00:00', 7, 1, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(216, '2020-08-01 08:00:00', 7, 2, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(217, '2020-09-01 08:00:00', 7, 3, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(218, '2020-10-01 08:00:00', 7, 4, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(221, '2020-06-09 08:00:00', 3, 1, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(222, '2020-06-09 08:00:00', 3, 2, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(223, '2020-09-01 08:00:00', 3, 3, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(224, '2020-10-01 08:00:00', 3, 4, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(225, '2020-06-10 08:00:00', 5, 1, 722333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(226, '2020-08-01 08:00:00', 5, 2, 722333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(227, '2020-09-01 08:00:00', 5, 3, 722333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(228, '2020-10-01 08:00:00', 5, 4, 722333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(229, '2020-06-08 08:00:00', 1, 1, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(230, '2020-08-01 08:00:00', 1, 2, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(231, '2020-09-01 08:00:00', 1, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(232, '2020-10-01 08:00:00', 1, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(233, '2020-06-09 08:00:00', 2, 1, 657000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(234, '2020-06-09 08:00:00', 2, 2, 657000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(235, '2020-09-01 08:00:00', 2, 3, 657000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(236, '2020-10-01 08:00:00', 2, 4, 657000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(237, '2020-06-10 08:00:00', 4, 1, 1057400.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(238, '2020-08-01 08:00:00', 4, 2, 1057400.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(239, '2020-09-01 08:00:00', 4, 3, 1057400.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(240, '2020-10-01 08:00:00', 4, 4, 1057400.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(241, '2020-06-15 08:00:00', 12, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Jul 2020'),
(242, '2020-06-15 08:00:00', 12, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Ags 2020'),
(243, '2020-09-01 08:00:00', 12, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Sep 2020'),
(244, '2020-10-01 08:00:00', 12, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020'),
(246, '2020-10-21 09:25:00', 96, 1, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020 0108000222'),
(247, '2020-10-16 09:30:00', 95, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020 0121000382'),
(248, '2020-10-14 09:40:00', 92, 1, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020 0134000283'),
(249, '2020-10-16 09:45:00', 93, 1, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0105000496'),
(250, '2020-10-16 09:45:00', 93, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Des 2020 0105000496'),
(251, '2020-10-16 09:45:00', 94, 1, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0103000328'),
(252, '2020-10-12 09:50:00', 91, 1, 808667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020 0148000249'),
(253, '2020-10-07 09:55:00', 90, 1, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Okt 2020 0105000491'),
(254, '2020-11-02 09:55:00', 88, 2, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0149000622'),
(255, '2020-11-02 10:00:00', 84, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0157000588'),
(256, '2020-11-02 10:05:00', 83, 2, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0158000166'),
(257, '2020-11-02 10:05:00', 86, 2, 93000000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0158000165'),
(258, '2020-11-02 10:15:00', 81, 2, 622000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0140000135'),
(259, '2020-11-02 10:15:00', 78, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0132000380'),
(260, '2020-11-02 10:20:00', 79, 2, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0136000251'),
(261, '2020-11-02 10:20:00', 77, 2, 1324333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0132000379'),
(262, '2020-11-02 10:35:00', 76, 2, 735867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0156000097'),
(263, '2020-11-02 10:40:00', 82, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000412'),
(264, '2020-11-02 09:15:00', 75, 2, 712300.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0127000365'),
(265, '2020-11-02 09:15:00', 74, 2, 1063467.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0129000262'),
(266, '2020-11-02 09:30:00', 70, 3, 1106800.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0157000583'),
(267, '2020-11-02 09:25:00', 71, 3, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0156000096'),
(268, '2020-11-02 10:40:00', 68, 3, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0127000358'),
(269, '2020-11-02 09:45:00', 69, 3, 1213967.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0134000278'),
(270, '2020-11-02 09:45:00', 72, 3, 1045267.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000428'),
(271, '2020-11-02 09:25:00', 63, 3, 1197948.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0123000252'),
(272, '2020-11-02 08:20:00', 61, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000426'),
(273, '2020-11-02 08:20:00', 64, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000424'),
(274, '2020-11-02 08:20:00', 60, 3, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000422'),
(275, '2020-11-02 08:25:00', 66, 3, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0136000249'),
(276, '2020-11-02 08:25:00', 62, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0108000221'),
(277, '2020-11-02 08:20:00', 65, 3, 1169500.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0143000444'),
(278, '2020-11-02 08:20:00', 67, 3, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0136000248 '),
(279, '2020-11-02 08:20:00', 59, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0152000157'),
(280, '2020-11-02 08:40:00', 56, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0108000220'),
(281, '2020-11-02 08:20:00', 55, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000391'),
(282, '2020-11-02 08:20:00', 58, 3, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0107000610'),
(283, '2020-11-02 08:20:00', 54, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0121000378'),
(284, '2020-11-02 08:20:00', 57, 3, 960333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020'),
(285, '2020-11-02 08:40:00', 51, 4, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0114000130'),
(286, '2020-11-02 08:20:00', 53, 4, 1725667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0131000244'),
(287, '2020-11-02 08:20:00', 52, 4, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0123000247'),
(288, '2020-11-02 08:40:00', 47, 4, 1876167.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0134000274'),
(289, '2020-11-02 08:40:00', 49, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0108000219'),
(290, '2020-11-02 08:20:00', 46, 4, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000388'),
(291, '2020-11-02 08:40:00', 48, 4, 1.17, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0146000121'),
(292, '2020-11-02 08:40:00', 41, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0163000087'),
(293, '2020-11-02 08:40:00', 45, 4, 1866133.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0132000368'),
(294, '2020-11-02 08:20:00', 42, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0126000385'),
(295, '2020-11-02 08:40:00', 43, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0156000095'),
(296, '2020-11-02 08:40:00', 35, 4, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000386'),
(297, '2020-11-02 08:20:00', 40, 4, 1105933.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0134000271'),
(298, '2020-11-02 08:20:00', 39, 4, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0134000272'),
(299, '2020-11-02 08:20:00', 50, 4, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0136000246'),
(300, '2020-11-02 08:20:00', 37, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0118000295'),
(301, '2020-11-02 08:20:00', 36, 4, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0149000583'),
(302, '2020-11-02 08:20:00', 33, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000419'),
(303, '2020-11-02 08:20:00', 38, 4, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0149000585'),
(304, '2020-11-02 08:20:00', 34, 4, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0125000430'),
(305, '2020-11-02 08:20:00', 31, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000385'),
(306, '2020-11-02 08:20:00', 32, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0133000194'),
(307, '2020-11-02 08:20:00', 29, 4, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0125000429'),
(308, '2020-11-02 08:20:00', 30, 4, 626.67, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0103000318'),
(309, '2020-11-02 08:20:00', 27, 4, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0141000264'),
(310, '2020-11-02 08:20:00', 28, 4, 1254100.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0152000153'),
(311, '2020-11-02 08:20:00', 26, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0135000414'),
(312, '2020-11-02 08:20:00', 24, 5, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000384'),
(313, '2020-11-02 08:20:00', 21, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0148000244'),
(314, '2020-11-02 08:20:00', 20, 5, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0103000315'),
(315, '2020-11-02 08:20:00', 25, 5, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0105000471'),
(316, '2020-11-02 08:20:00', 23, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0105000470'),
(317, '2020-11-02 08:20:00', 19, 5, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0149000581'),
(318, '2020-11-02 08:20:00', 16, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0140000128'),
(319, '2020-11-02 08:20:00', 18, 5, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0149000577'),
(320, '2020-11-02 08:20:00', 17, 5, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0115000383'),
(321, '2020-11-02 08:20:00', 14, 5, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0133000193'),
(322, '2020-11-02 08:20:00', 15, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0129000260'),
(323, '2020-11-02 08:20:00', 11, 5, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020    0141000262'),
(324, '2020-11-02 08:20:00', 22, 5, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0132000367 '),
(325, '2020-11-02 08:20:00', 10, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0141000256'),
(326, '2020-11-02 08:20:00', 8, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0103000313'),
(327, '2020-11-02 08:20:00', 13, 5, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0105000469'),
(328, '2020-11-02 08:20:00', 9, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0144000256'),
(329, '2020-11-02 08:20:00', 7, 5, 1.11, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0132000366'),
(330, '2020-11-02 08:20:00', 3, 5, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0163000084'),
(331, '2020-11-02 08:20:00', 5, 5, 722333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000409'),
(332, '2020-11-02 08:20:00', 1, 5, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0151000408'),
(333, '2020-11-02 08:20:00', 2, 5, 657000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0149000576'),
(334, '2020-11-02 08:20:00', 4, 5, 1057400.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0122000218'),
(335, '2020-11-02 08:20:00', 12, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', 'Angs Nov 2020 0170000030'),
(336, '2020-12-01 10:40:00', 1, 6, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(337, '2020-12-01 10:40:00', 2, 6, 657000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(338, '2020-12-01 10:40:00', 3, 6, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(339, '2020-12-01 10:40:00', 4, 6, 1057400.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(340, '2020-12-01 10:40:00', 5, 6, 722333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(341, '2020-12-01 10:40:00', 7, 6, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(342, '2020-12-01 10:40:00', 8, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(343, '2020-12-01 10:40:00', 9, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(344, '2020-12-01 10:40:00', 10, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(345, '2020-12-01 10:40:00', 11, 6, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(346, '2020-12-01 10:40:00', 12, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(347, '2020-12-01 10:40:00', 13, 6, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(348, '2020-12-01 10:40:00', 14, 6, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(349, '2020-12-01 10:40:00', 15, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(350, '2020-12-01 10:40:00', 16, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(351, '2020-12-01 10:40:00', 17, 6, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(352, '2020-12-01 10:40:00', 18, 6, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(353, '2020-12-01 10:40:00', 19, 6, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(354, '2020-12-01 10:40:00', 20, 6, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(355, '2020-12-01 10:40:00', 21, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(356, '2020-12-01 10:40:00', 22, 6, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(357, '2020-12-01 10:40:00', 26, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(358, '2020-12-01 10:40:00', 23, 6, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(359, '2020-12-01 10:40:00', 24, 6, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(360, '2020-12-14 10:40:00', 25, 6, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(361, '2020-12-01 10:40:00', 27, 5, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(362, '2020-12-01 10:40:00', 28, 5, 1254100.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(363, '2020-12-01 10:40:00', 29, 5, 1051333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(364, '2020-12-01 10:40:00', 30, 5, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(365, '2020-12-01 10:40:00', 31, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(366, '2020-12-01 10:40:00', 32, 5, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(367, '2020-12-01 10:40:00', 33, 5, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(368, '2020-12-01 10:40:00', 34, 5, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(369, '2020-12-01 10:40:00', 35, 5, 1224000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(370, '2020-12-01 10:40:00', 36, 5, 566000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(371, '2020-12-01 10:40:00', 37, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(372, '2020-12-01 10:40:00', 38, 5, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(373, '2020-12-01 10:40:00', 39, 5, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(374, '2020-12-01 10:40:00', 40, 5, 1105933.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(375, '2020-12-01 10:40:00', 41, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(376, '2020-12-01 10:40:00', 42, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(377, '2020-12-01 10:40:00', 43, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(378, '2020-12-01 10:40:00', 45, 5, 1866133.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(379, '2020-12-01 10:40:00', 46, 5, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(380, '2020-12-01 10:40:00', 47, 5, 1876167.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(381, '2020-12-01 10:40:00', 48, 5, 1166600.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(382, '2020-12-01 10:40:00', 49, 5, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(383, '2020-12-01 10:40:00', 50, 5, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(384, '2020-12-01 10:40:00', 51, 5, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(385, '2020-12-01 10:40:00', 52, 5, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(386, '2020-12-03 10:40:00', 53, 5, 1725667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(387, '2020-12-01 10:40:00', 54, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(388, '2020-12-01 10:40:00', 55, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(389, '2020-12-01 10:40:00', 56, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(390, '2020-12-01 10:40:00', 57, 4, 960333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', '');
INSERT INTO `tbl_pinjaman_d` (`id`, `tgl_bayar`, `pinjam_id`, `angsuran_ke`, `jumlah_bayar`, `denda_rp`, `terlambat`, `ket_bayar`, `dk`, `kas_id`, `jns_trans`, `update_data`, `user_name`, `keterangan`) VALUES
(391, '2020-12-01 10:40:00', 58, 4, 869333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(392, '2020-12-01 10:40:00', 59, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(393, '2020-12-01 10:40:00', 60, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(394, '2020-12-01 10:40:00', 61, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(395, '2020-12-01 10:40:00', 62, 4, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(396, '2020-12-01 10:40:00', 63, 4, 1268718.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(397, '2020-12-01 10:40:00', 64, 4, 1023333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(398, '2020-12-01 10:40:00', 65, 4, 1169500.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(399, '2020-12-01 10:40:00', 66, 4, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(400, '2020-12-01 10:40:00', 67, 4, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(401, '2020-12-01 10:40:00', 68, 4, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(402, '2020-12-01 10:40:00', 69, 4, 1213967.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(403, '2020-12-01 10:40:00', 70, 4, 1106800.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(404, '2020-12-01 10:40:00', 71, 4, 687333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(405, '2020-12-01 10:40:00', 72, 4, 1045267.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(406, '2020-12-01 10:40:00', 73, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(407, '2020-12-01 10:40:00', 74, 3, 1063467.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(408, '2020-12-01 10:40:00', 75, 3, 712300.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(409, '2020-12-01 10:40:00', 76, 3, 735867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(410, '2020-12-01 10:40:00', 77, 3, 1324333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(411, '2020-12-01 10:40:00', 78, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(412, '2020-12-01 10:40:00', 79, 3, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(413, '2020-12-01 10:40:00', 80, 3, 1142333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(414, '2020-12-01 10:40:00', 81, 3, 622000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(415, '2020-12-01 10:40:00', 82, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(416, '2020-12-01 10:40:00', 83, 3, 990667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(417, '2020-12-01 10:40:00', 84, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(418, '2020-12-01 10:40:00', 85, 3, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(419, '2020-12-01 10:40:00', 86, 3, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(420, '2020-12-01 10:40:00', 87, 3, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(421, '2020-12-01 10:40:00', 88, 3, 626667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(422, '2020-12-01 10:40:00', 89, 1, 1112000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(423, '2020-12-01 10:40:00', 90, 2, 1525000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(424, '2020-12-01 10:40:00', 91, 2, 808667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(425, '2020-12-01 10:40:00', 92, 2, 1099867.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(426, '2020-12-01 10:41:00', 94, 2, 930000.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(427, '2020-12-01 10:41:00', 95, 2, 1233333.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', ''),
(428, '2020-12-01 10:41:00', 96, 2, 2026667.00, 0.00, 0, 'Angsuran', 'D', 1, 48, '0000-00-00 00:00:00', 'admin', '');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_pinjaman_h`
--

CREATE TABLE `tbl_pinjaman_h` (
  `id` int(11) NOT NULL,
  `tgl_pinjam` datetime NOT NULL,
  `anggota_id` int(11) NOT NULL DEFAULT 0,
  `barang_id` int(11) NOT NULL DEFAULT 0,
  `nomor_pinjaman` varchar(50) DEFAULT NULL,
  `jenis_pinjaman` int(2) NOT NULL,
  `lama_angsuran` int(11) NOT NULL DEFAULT 0,
  `angsuran_per_bulan` int(11) DEFAULT NULL,
  `no_perjanjian_kredit` varchar(50) DEFAULT NULL,
  `nomor_rekening` varchar(100) DEFAULT NULL,
  `nomor_pensiunan` varchar(100) DEFAULT NULL,
  `jumlah` int(11) NOT NULL DEFAULT 0,
  `bunga` float(10,2) NOT NULL,
  `biaya_adm` decimal(30,2) NOT NULL DEFAULT 0.00,
  `lunas` enum('Belum','Lunas') NOT NULL,
  `dk` enum('D','K') NOT NULL,
  `kas_id` int(11) NOT NULL DEFAULT 0,
  `jns_trans` int(11) NOT NULL DEFAULT 0,
  `jns_cabangid` int(11) DEFAULT NULL,
  `update_data` datetime NOT NULL,
  `user_name` varchar(255) NOT NULL,
  `keterangan` varchar(255) NOT NULL,
  `contoh` int(23) NOT NULL,
  `file` varchar(240) NOT NULL,
  `biaya_asuransi_akun` int(11) NOT NULL,
  `biaya_administrasi_akun` int(11) NOT NULL,
  `simpanan_pokok_akun` int(11) NOT NULL,
  `pokok_bulan_satu_akun` int(11) NOT NULL,
  `pokok_bulan_dua_akun` int(11) NOT NULL,
  `bunga_bulan_satu_akun` int(11) NOT NULL,
  `bunga_bulan_dua_akun` int(11) NOT NULL,
  `pencairan_bersih_akun` int(11) NOT NULL,
  `plafond_pinjaman_akun` int(11) NOT NULL DEFAULT 0,
  `simpanan_wajib_akun` int(11) NOT NULL DEFAULT 0,
  `biaya_materai_akun` int(11) NOT NULL DEFAULT 0,
  `biaya_asuransi` int(11) NOT NULL DEFAULT 0,
  `biaya_administrasi` decimal(30,2) NOT NULL DEFAULT 0.00,
  `biaya_materai` int(11) NOT NULL DEFAULT 0,
  `simpanan_pokok` int(11) NOT NULL DEFAULT 0,
  `simpanan_wajib` int(11) NOT NULL DEFAULT 0,
  `pokok_bulan_satu` int(11) NOT NULL DEFAULT 0,
  `bunga_bulan_satu` int(11) NOT NULL DEFAULT 0,
  `pokok_bulan_dua` int(11) NOT NULL DEFAULT 0,
  `bunga_bulan_dua` int(11) NOT NULL DEFAULT 0,
  `pencairan_bersih` int(11) NOT NULL DEFAULT 0,
  `nama_vendor` varchar(150) NOT NULL,
  `plafond_pinjaman` int(11) NOT NULL DEFAULT 0,
  `validasi_by` varchar(150) NOT NULL,
  `validasi_status` char(1) DEFAULT NULL,
  `validasi_date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_pinjaman_h`
--

INSERT INTO `tbl_pinjaman_h` (`id`, `tgl_pinjam`, `anggota_id`, `barang_id`, `nomor_pinjaman`, `jenis_pinjaman`, `lama_angsuran`, `angsuran_per_bulan`, `no_perjanjian_kredit`, `nomor_rekening`, `nomor_pensiunan`, `jumlah`, `bunga`, `biaya_adm`, `lunas`, `dk`, `kas_id`, `jns_trans`, `jns_cabangid`, `update_data`, `user_name`, `keterangan`, `contoh`, `file`, `biaya_asuransi_akun`, `biaya_administrasi_akun`, `simpanan_pokok_akun`, `pokok_bulan_satu_akun`, `pokok_bulan_dua_akun`, `bunga_bulan_satu_akun`, `bunga_bulan_dua_akun`, `pencairan_bersih_akun`, `plafond_pinjaman_akun`, `simpanan_wajib_akun`, `biaya_materai_akun`, `biaya_asuransi`, `biaya_administrasi`, `biaya_materai`, `simpanan_pokok`, `simpanan_wajib`, `pokok_bulan_satu`, `bunga_bulan_satu`, `pokok_bulan_dua`, `bunga_bulan_dua`, `pencairan_bersih`, `nama_vendor`, `plafond_pinjaman`, `validasi_by`, `validasi_status`, `validasi_date`) VALUES
(1, '2020-06-08 00:00:00', 1, 0, '0151000408', 1, 12, 1003334, '13826/GG-PK/06/2020', '3901310236', 'L470100037O', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(2, '2020-06-08 00:00:00', 2, 0, '0149000576', 1, 24, 637000, '13825/GG-PK/06/2020', '3001311318', 'V2119370600', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10500000, '', 'X', '0000-00-00 00:00:00'),
(3, '2020-06-09 00:00:00', 3, 0, '0163000084', 1, 12, 1204000, '13834/GG-PK/06/2020', '0362330015', 'P46OO164680', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 12000000, '', 'X', '0000-00-00 00:00:00'),
(4, '2020-06-08 00:00:00', 4, 0, '0122000218', 1, 24, 1037400, '13823/GG-PK/06/2020', '5330310845', '0100538160O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17100000, '', 'X', '0000-00-00 00:00:00'),
(5, '2020-06-09 00:00:00', 5, 0, '0151000409', 1, 12, 702334, '13829/GG-PK/06/2020', '3901310311', 'X4700075690', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 7000000, '', 'X', '0000-00-00 00:00:00'),
(6, '2020-06-10 00:00:00', 6, 0, '0115000381', 1, 24, 910000, '13845/GG-PK/06/2020', '4002330226', '20172200177O', 0, 45.60, 0.00, 'Lunas', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(7, '2020-06-09 00:00:00', 7, 0, '0132000366', 1, 24, 1092000, '13830/GG-PK/06/2020', '0361312796', '13043472200', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18000000, '', 'X', '0000-00-00 00:00:00'),
(8, '2020-06-10 00:00:00', 8, 0, '0103000313', 1, 24, 1213334, '13844/GG-PK/06/2020', '3202311319', '51006985300', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(9, '2020-06-10 00:00:00', 9, 0, '0144000256', 1, 24, 1213334, '13846/GG-PK/06/2020', '2503311510', '13013908300', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(10, '2020-06-10 00:00:00', 10, 0, '0141000256', 1, 24, 1213334, '13842/GG-PK/06/2020', '2961310487', 'V140050730I', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(11, '2020-06-11 00:00:00', 11, 0, '0141000262', 1, 24, 1031334, '13855/GG-PK/06/2020', '2961310507', '14002688100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17000000, '', 'X', '0000-00-00 00:00:00'),
(12, '2020-06-07 00:00:00', 12, 0, '0170000030', 1, 24, 1213334, '13820/GG-PK/06/2020', '5601310965', 'X1208661700', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(13, '2020-06-10 00:00:00', 13, 0, '0105000469', 1, 12, 1003334, '13841/GG-PK/06/2020', '5101312774', 'D5600338020', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(14, '2020-06-15 00:00:00', 14, 0, '0133000193', 1, 24, 606667, '13864/GG-PK/06/2020', '0310310993', '13027928000', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(15, '2020-06-12 00:00:00', 15, 0, '0129000260', 1, 24, 1213334, '13859/GG-PK/06/2020', '2001311286', 'L5600107940', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(16, '2020-06-16 00:00:00', 16, 0, '0140000128', 1, 24, 1213334, '13869/GG-PK/06/2020', '1902310488', '55000684310', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(17, '2020-06-15 00:00:00', 17, 0, '0115000383', 1, 24, 910000, '13861/GG-PK/06/2020', '4002310844', 'L5600076590', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(18, '2020-06-16 00:00:00', 18, 0, '0149000577', 1, 24, 546000, '13868/GG-PK/06/2020', '3062310180', '03000713900', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 9000000, '', 'X', '0000-00-00 00:00:00'),
(19, '2020-06-18 00:00:00', 19, 0, '0149000581', 1, 24, 1031334, '13872/GG-PK/06/2020', '3062310230', '14006804900', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17000000, '', 'X', '0000-00-00 00:00:00'),
(20, '2020-06-19 00:00:00', 20, 0, '0103000315', 1, 24, 1031334, '13882/GG-PK/06/2020', '3202311361', 'X5600809630', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17000000, '', 'X', '0000-00-00 00:00:00'),
(21, '2020-06-22 00:00:00', 21, 0, '0148000244', 1, 24, 1213334, '13889/GG-PK/06/2020', '3501102301', '15002056800', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(22, '2020-06-11 00:00:00', 22, 0, '0132000367', 1, 24, 970667, '13852/GG-PK/06/2020', '0364310450', 'P460016108O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 16000000, '', 'X', '0000-00-00 00:00:00'),
(23, '2020-06-19 00:00:00', 23, 0, '0105000470', 1, 24, 1213334, '13878/GG-PK/06/2020', '5101311755', 'V211820320O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(24, '2020-06-24 00:00:00', 24, 0, '0115000384', 1, 12, 1505000, '13898/GG-PK/06/2020', '4002310968', '1303244800O', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(25, '2020-06-19 00:00:00', 25, 0, '0105000471', 1, 24, 1079867, '13879/GG-PK/06/2020', '5101312194', '13081394100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17800000, '', 'X', '0000-00-00 00:00:00'),
(26, '2020-06-24 00:00:00', 26, 0, '0135000414', 1, 24, 1213334, '13903/GG-PK/06/2020', '0902310654', '48003300100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(27, '2020-07-01 00:00:00', 27, 0, '0141000264', 8, 24, 1079867, '13919/GG-PK/07/2020', '2961310721', '1200304160O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17800000, '', 'X', '0000-00-00 00:00:00'),
(28, '2020-07-01 00:00:00', 28, 0, '0152000153', 1, 12, 1234100, '13912/GG-PK/07/2020', '2761310304', 'U0047712000', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 12300000, '', 'X', '0000-00-00 00:00:00'),
(29, '2020-07-02 00:00:00', 29, 0, '0125000429', 8, 24, 1031334, '13925/GG-PK/07/2020', '1007310011', '49000967800', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17000000, '', 'X', '0000-00-00 00:00:00'),
(30, '2020-07-02 00:00:00', 30, 0, '0103000318', 8, 24, 606667, '13923/GG-PK/07/2020', '3202311881', '01001905100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(31, '2020-07-06 00:00:00', 31, 0, '0115000385', 8, 24, 1213334, '13929/GG-PK/07/2020', '4002310858', '13031471700', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(32, '2020-07-06 00:00:00', 32, 0, '0133000194', 1, 12, 1003334, '13938/GG-PK/07/2020', '0310311336', '13012826300', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(33, '2020-07-07 00:00:00', 33, 0, '0151000419', 1, 12, 1003334, '13943/GG-PK/07/2020', '3901310657', 'V2201677600', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(34, '2020-07-07 00:00:00', 34, 0, '0125000430', 8, 24, 849334, '13942/GG-PK/07/2020', '1001330040', '199713006650', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 14000000, '', 'X', '0000-00-00 00:00:00'),
(35, '2020-07-09 00:00:00', 35, 0, '0115000386', 1, 12, 1204000, '13962/GG-PK/07/2020', '4002310214', '13049563000', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 12000000, '', 'X', '0000-00-00 00:00:00'),
(36, '2020-07-07 00:00:00', 36, 0, '0149000583', 8, 24, 546000, '13939/GG-PK/07/2020', '3062310118', '15005914400', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 9000000, '', 'X', '0000-00-00 00:00:00'),
(37, '2020-07-08 00:00:00', 37, 0, '0118000295', 8, 24, 1213334, '13955/GG-PK/07/2020', '4824310175', '1400584760O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(38, '2020-07-07 00:00:00', 38, 0, '0149000585', 8, 24, 606667, '13947/GG-PK/07/2020', '3062310119', '13027079900', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(39, '2020-07-09 00:00:00', 39, 0, '0134000272', 8, 24, 1092000, '13957/GG-PK/07/2020', '2801311292', 'X480003615O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18000000, '', 'X', '0000-00-00 00:00:00'),
(40, '2020-07-09 00:00:00', 40, 0, '0134000271', 8, 24, 1085934, '13956/GG-PK/07/2020', '2801311392', 'D4800023050', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17900000, '', 'X', '0000-00-00 00:00:00'),
(41, '2020-07-14 00:00:00', 41, 0, '0163000087', 8, 24, 1213334, '13981/GG-PK/07/2020', '0362310280', '199721021570', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(42, '2020-07-13 00:00:00', 42, 0, '0126000385', 8, 24, 1213334, '13974/GG-PK/07/2020', '3301311781', '13033565700', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(43, '2020-07-13 00:00:00', 43, 0, '0156000095', 8, 24, 1213334, '13972/GG-PK/07/2020', '4617310086', '06001390600', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(44, '2020-07-14 00:00:00', 44, 0, '0115000387', 8, 24, 1092000, '13979/GG-PK/07/2020', '4002330138', '199321008410', 0, 45.60, 0.00, 'Lunas', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18000000, '', 'X', '0000-00-00 00:00:00'),
(45, '2020-07-13 00:00:00', 45, 0, '0132000368', 1, 12, 1846134, '13973/GG-PK/07/2020', '0364310071', '15006162900', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18400000, '', 'X', '0000-00-00 00:00:00'),
(46, '2020-07-16 00:00:00', 46, 0, '0115000388', 8, 24, 1146600, '13991/GG-PK/07/2020', '4002310822', '13031464000', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18900000, '', 'X', '0000-00-00 00:00:00'),
(47, '2020-07-17 00:00:00', 47, 0, '0134000274', 1, 12, 1856167, '13992/GG-PK/07/2020', '2802311297', 'D4800021690', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18500000, '', 'X', '0000-00-00 00:00:00'),
(48, '2020-07-16 00:00:00', 48, 0, '0146000121', 8, 24, 1146600, '13990/GG-PK/07/2020', '3601311414', 'D6300050310', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18900000, '', 'X', '0000-00-00 00:00:00'),
(49, '2020-07-16 00:00:00', 49, 0, '0108000219', 8, 24, 1213334, '13985/GG-PK/07/2020', '5201331865', '198911048620', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(50, '2020-07-08 00:00:00', 50, 0, '0136000246', 8, 24, 606667, '13952/GG-PK/07/2020', '1362310242', '00127693100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(51, '2020-07-26 00:00:00', 51, 0, '0114000130', 1, 12, 2006667, '14024/GG-PK/07/2020', '1301330440', '942103649', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(52, '2020-07-23 00:00:00', 52, 0, '0123000247', 8, 24, 910000, '14018/GG-PK/07/2020', '3701313890', '01003613600', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(53, '2020-07-24 00:00:00', 53, 0, '0131000244', 1, 12, 1705667, '14020/GG-PK/07/2020', '1021330005', 'D5900051170', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17000000, '', 'X', '0000-00-00 00:00:00'),
(54, '2020-08-04 00:00:00', 54, 0, '0121000378', 8, 24, 1213334, '14046/GG-PK/08/2020', '1307320789', '13023868500', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(55, '2020-08-05 00:00:00', 55, 0, '0115000391', 8, 24, 1213334, '14053/GG-PK/08/2020', '4002310221', '13O41844100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(56, '2020-08-05 00:00:00', 56, 0, '0108000220', 8, 24, 1213334, '14051/GG-PK/08/2020', '5201332644', '201711063190', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(57, '2020-08-03 00:00:00', 57, 0, '0121000377', 8, 24, 940334, '14033/GG-PK/08/2020', '1163320171', '1308503030O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15500000, '', 'X', '0000-00-00 00:00:00'),
(58, '2020-08-04 00:00:00', 58, 0, '0107000610', 8, 24, 849334, '14042/GG-PK/08/2020', '1103310574', 'X5500166000', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 14000000, '', 'X', '0000-00-00 00:00:00'),
(59, '2020-08-11 00:00:00', 59, 0, '0152000157', 8, 24, 1213334, '14087/GG-PK/08/2020', '2761310345', '15012481100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(60, '2020-08-12 00:00:00', 60, 0, '0151000422', 1, 12, 1003334, '14099/GG-PK/08/2020', '3901310337', '199514036130', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(61, '2020-08-14 00:00:00', 61, 0, '0151000426', 1, 12, 1003334, '14130/GG-PK/08/2020', '3901310396', '01004600800', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(62, '2020-08-12 00:00:00', 62, 0, '0108000221', 8, 24, 1213334, '14097/GG-PK/08/2020', '5201311991', '13017478900', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(63, '2020-08-18 00:00:00', 63, 0, '0123000252', 8, 24, 1213334, '14139/GG-PK/08/2020', '3701313696', '61000325700', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(64, '2020-08-13 00:00:00', 64, 0, '0151000424', 1, 12, 1003334, '14111/GG-PK/08/2020', '3901310348', '15002244400', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(65, '2020-08-11 00:00:00', 65, 0, '0143000444', 1, 12, 1103667, '14095/GG-PK/08/2020', '5501311928', 'D6200087900', 0, 25.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 11000000, '', 'X', '0000-00-00 00:00:00'),
(66, '2020-08-12 00:00:00', 66, 0, '0136000249', 8, 24, 667334, '14102/GG-PK/08/2020', '1330310704', 'D440100536O', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 11000000, '', 'X', '0000-00-00 00:00:00'),
(67, '2020-08-11 00:00:00', 67, 0, '0136000248', 8, 24, 910000, '14093/GG-PK/08/2020', '1362310021', '39000147900', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(68, '2020-08-25 00:00:00', 68, 0, '0127000358', 1, 12, 1505000, '14174/GG-PK/08/2020', '2103312168', '15009663300', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(69, '2020-08-20 00:00:00', 69, 0, '0134000278', 1, 12, 1193967, '14152/GG-PK/08/2020', '2801311350', '13010237600', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 11900000, '', 'X', '0000-00-00 00:00:00'),
(70, '2020-08-26 00:00:00', 70, 0, '0157000583', 1, 12, 1043467, '14184/GG-PK/08/2020', '3301317805', '05000903800', 0, 25.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10400000, '', 'X', '0000-00-00 00:00:00'),
(71, '2020-08-26 00:00:00', 43, 0, '0156000096', 8, 24, 667334, '14187/GG-PK/08/2020', '4617310081', 'O9001934300', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 11000000, '', 'X', '0000-00-00 00:00:00'),
(72, '2020-08-18 00:00:00', 72, 0, '0151000428', 8, 24, 1025267, '14140/GG-PK/08/2020', '3901310659', '201622000370', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 16900000, '', 'X', '0000-00-00 00:00:00'),
(73, '2020-09-01 00:00:00', 73, 0, '0145000214', 8, 24, 1213334, '14201/GG-PK/09/2020', '3701313969', '16000860700', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(74, '2020-09-02 00:00:00', 74, 0, '0129000262', 8, 24, 1043467, '14255/GG-PK/09/2020', '3402311277', '13030756300', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17200000, '', 'X', '0000-00-00 00:00:00'),
(75, '2020-09-03 00:00:00', 75, 0, '0127000365', 1, 12, 692300, '14271/GG-PK/09/2020', '2103311779', 'NPP05079730', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 6900000, '', 'X', '0000-00-00 00:00:00'),
(76, '2020-09-10 00:00:00', 76, 0, '0156000097', 8, 24, 715867, '14301/GG-PK/09/2020', '4403350003', '47000281100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 11800000, '', 'X', '0000-00-00 00:00:00'),
(77, '2020-09-13 00:00:00', 77, 0, '0132000379', 1, 12, 1304334, '14303/GG-PK/09/2020', '0361330202', '201414013280', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 13000000, '', 'X', '0000-00-00 00:00:00'),
(78, '2020-09-16 00:00:00', 78, 0, '0132000380', 8, 24, 1213334, '14306/GG-PK/09/2020', '0361312875', '12003902900', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(79, '2020-09-14 00:00:00', 79, 0, '0136000251', 8, 24, 970667, '14304/GG-PK/09/2020', '1330330112', '199011010690', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 16000000, '', 'X', '0000-00-00 00:00:00'),
(80, '2020-09-17 00:00:00', 80, 0, '0151000436', 8, 24, 1122334, '14309/GG-PK/09/2020', '3901310661', '13001100800', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18500000, '', 'X', '0000-00-00 00:00:00'),
(81, '2020-09-16 00:00:00', 81, 0, '0140000135', 1, 12, 602000, '14307/GG-PK/09/2020', '1902310389', 'P3207030100', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 6000000, '', 'X', '0000-00-00 00:00:00'),
(82, '2020-09-09 00:00:00', 82, 0, '0115000412', 8, 24, 1213334, '14300/GG-PK/09/2020', '1307321111', '51002704000', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(83, '2020-09-21 00:00:00', 83, 0, '0158000166', 8, 24, 970667, '14311/GG-PK/09/2020', '5263330341', '198914021120', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 16000000, '', 'X', '0000-00-00 00:00:00'),
(84, '2020-09-22 00:00:00', 84, 0, '0157000588', 8, 24, 1213334, '14312/GG-PK/09/2020', '3301311804', '13018217500', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(85, '2020-09-17 00:00:00', 85, 0, '0160000077', 8, 24, 1213334, '14308/GG-PK/09/2020', '5401341182', '13030700800', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', 'X', '0000-00-00 00:00:00'),
(86, '2020-09-18 00:00:00', 86, 0, '0158000165', 8, 24, 910000, '14310/GG-PK/09/2020', '5263310431', 'X1203825400', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', 'X', '0000-00-00 00:00:00'),
(87, '2020-09-23 00:00:00', 87, 0, '0173000066', 8, 24, 1092000, '14313/GG-PK/09/2020', '1605311221', '13075993200', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18000000, '', 'X', '0000-00-00 00:00:00'),
(88, '2020-09-25 00:00:00', 88, 0, '0149000622', 8, 24, 606667, '14314/GG-PK/09/2020', '3062310210', 'X5500204990', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 10000000, '', 'X', '0000-00-00 00:00:00'),
(89, '2020-10-02 00:00:00', 128, 0, '0148000246', 8, 24, 1092000, '14316/GG-PK/10/2020', '3501310912', '48000845800', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 18000000, '', NULL, '0000-00-00 00:00:00'),
(90, '2020-10-05 00:00:00', 129, 0, '0105000491', 1, 12, 1505000, '14317/GG-PK/10/2020', '5101330465', 'U5600028830', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', NULL, '0000-00-00 00:00:00'),
(91, '2020-10-08 00:00:00', 130, 0, '0148000249', 8, 24, 788667, '14320/GG-PK/10/2020', '3501310862', 'V0910039300', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 13000000, '', NULL, '0000-00-00 00:00:00'),
(92, '2020-10-13 00:00:00', 131, 0, '0134000283', 8, 24, 1079867, '14323/GG-PK/10/2020', '2802311300', '11000744200', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 17800000, '', NULL, '0000-00-00 00:00:00'),
(93, '2020-10-13 00:00:00', 132, 0, '0105000496', 8, 24, 1213334, '14324/GG-PK/10/2020', '5101311458', '38001374100', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', NULL, '0000-00-00 00:00:00'),
(94, '2020-10-12 00:00:00', 133, 0, '0103000328', 8, 24, 910000, '14321/GG-PK/10/2020', '3202311459', '51001098200', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 15000000, '', NULL, '0000-00-00 00:00:00'),
(95, '2020-10-13 00:00:00', 134, 0, '0121000382', 8, 24, 1213334, '14322/GG-PK/10/2020', '1307320786', '199411020080', 0, 45.60, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', NULL, '0000-00-00 00:00:00'),
(96, '2020-10-20 00:00:00', 135, 0, '0108000222', 1, 12, 2006667, '14326/GG-PK/10/2020', '5201312081', '13017875500', 0, 20.40, 0.00, 'Belum', 'D', 1, 0, NULL, '0000-00-00 00:00:00', 'admin', '', 0, '', 2, 2, 2, 2, 0, 2, 0, 2, 2, 0, 2, 0, 0.00, 0, 0, 0, 0, 0, 0, 0, 0, '', 20000000, '', NULL, '0000-00-00 00:00:00'),
(97, '2020-09-01 10:20:00', 0, 0, '0127000362', 9, 60, 1488956, '14216/GG-PK/09/2020', '2124310016', '13094629800', 0, 15.00, 20.00, 'Belum', 'K', 1, 7, 33, '0000-00-00 00:00:00', 'admin', '', 0, 'a156ff48608505aa2054998bf09895ba', 67, 186, 70, 178, 178, 183, 183, 0, 178, 71, 186, 0, 20.00, 0, 0, 0, 0, 0, 0, 0, 56199980, '', 56200000, '', NULL, '0000-00-00 00:00:00');

--
-- Triggers `tbl_pinjaman_h`
--
DELIMITER $$
CREATE TRIGGER `tbl_pinjaman_h_after_insert` AFTER INSERT ON `tbl_pinjaman_h` FOR EACH ROW BEGIN
  CALL SimulasiPinjaman(NEW.id);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tbl_pinjaman_h_after_update` AFTER UPDATE ON `tbl_pinjaman_h` FOR EACH ROW BEGIN
  CALL SimulasiPinjaman(NEW.id);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_pinjaman_simulasi`
--

CREATE TABLE `tbl_pinjaman_simulasi` (
  `tbl_pinjam_hid` int(11) NOT NULL,
  `blnke` tinyint(4) NOT NULL DEFAULT 0,
  `periode` date NOT NULL,
  `tempo` date NOT NULL,
  `plafondpinjaman` decimal(30,2) NOT NULL DEFAULT 0.00,
  `bunga` decimal(30,2) NOT NULL DEFAULT 0.00,
  `biayaadm` decimal(30,2) NOT NULL DEFAULT 0.00,
  `sisapokokawal` decimal(30,2) NOT NULL DEFAULT 0.00,
  `angsuranpokok` decimal(30,2) NOT NULL DEFAULT 0.00,
  `angsuranbunga` decimal(30,2) NOT NULL DEFAULT 0.00,
  `totalangsuranbank` decimal(30,2) NOT NULL DEFAULT 0.00,
  `sisapokokakhir` decimal(30,2) NOT NULL DEFAULT 0.00,
  `adminangsuran` decimal(30,2) NOT NULL DEFAULT 0.00,
  `angsurandebitur` decimal(30,2) NOT NULL DEFAULT 0.00,
  `simpananwajib` decimal(30,2) NOT NULL DEFAULT 0.00,
  `jumlahangsuran` decimal(30,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_pinjaman_simulasi`
--

INSERT INTO `tbl_pinjaman_simulasi` (`tbl_pinjam_hid`, `blnke`, `periode`, `tempo`, `plafondpinjaman`, `bunga`, `biayaadm`, `sisapokokawal`, `angsuranpokok`, `angsuranbunga`, `totalangsuranbank`, `sisapokokakhir`, `adminangsuran`, `angsurandebitur`, `simpananwajib`, `jumlahangsuran`) VALUES
(44, 1, '2020-08-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 2, '2020-09-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 3, '2020-10-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 4, '2020-11-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 5, '2020-12-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 6, '2021-01-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 7, '2021-02-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 8, '2021-03-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 9, '2021-04-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 10, '2021-05-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 11, '2021-06-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 12, '2021-07-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 13, '2021-08-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 14, '2021-09-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 15, '2021-10-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 16, '2021-11-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 17, '2021-12-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 18, '2022-01-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 19, '2022-02-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 20, '2022-03-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 21, '2022-04-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 22, '2022-05-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 23, '2022-06-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(44, 24, '2022-07-24', '2022-07-14', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(6, 1, '2020-07-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 2, '2020-08-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 3, '2020-09-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 4, '2020-10-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 5, '2020-11-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 6, '2020-12-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 7, '2021-01-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 8, '2021-02-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 9, '2021-03-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 10, '2021-04-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 11, '2021-05-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 12, '2021-06-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 13, '2021-07-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 14, '2021-08-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 15, '2021-09-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 16, '2021-10-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 17, '2021-11-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 18, '2021-12-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 19, '2022-01-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 20, '2022-02-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 21, '2022-03-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 22, '2022-04-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 23, '2022-05-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(6, 24, '2022-06-24', '2022-06-10', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(93, 1, '2020-11-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 2, '2020-12-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 3, '2021-01-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 4, '2021-02-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 5, '2021-03-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 6, '2021-04-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 7, '2021-05-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 8, '2021-06-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 9, '2021-07-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 10, '2021-08-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 11, '2021-09-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 12, '2021-10-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 13, '2021-11-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 14, '2021-12-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 15, '2022-01-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 16, '2022-02-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 17, '2022-03-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 18, '2022-04-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 19, '2022-05-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 20, '2022-06-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 21, '2022-07-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 22, '2022-08-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 23, '2022-09-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(93, 24, '2022-10-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(97, 1, '2020-10-24', '2025-09-01', 56200000.00, 15.00, 20.00, 56200000.00, 634494.07, 702500.00, 1336994.07, 55565505.93, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 2, '2020-11-24', '2025-09-01', 56200000.00, 15.00, 20.00, 55565505.93, 642425.25, 694568.82, 1336994.07, 54923080.68, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 3, '2020-12-24', '2025-09-01', 56200000.00, 15.00, 20.00, 54923080.68, 650455.56, 686538.51, 1336994.07, 54272625.12, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 4, '2021-01-24', '2025-09-01', 56200000.00, 15.00, 20.00, 54272625.12, 658586.26, 678407.81, 1336994.07, 53614038.86, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 5, '2021-02-24', '2025-09-01', 56200000.00, 15.00, 20.00, 53614038.86, 666818.58, 670175.49, 1336994.07, 52947220.28, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 6, '2021-03-24', '2025-09-01', 56200000.00, 15.00, 20.00, 52947220.28, 675153.82, 661840.25, 1336994.07, 52272066.46, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 7, '2021-04-24', '2025-09-01', 56200000.00, 15.00, 20.00, 52272066.46, 683593.24, 653400.83, 1336994.07, 51588473.22, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 8, '2021-05-24', '2025-09-01', 56200000.00, 15.00, 20.00, 51588473.22, 692138.15, 644855.92, 1336994.07, 50896335.07, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 9, '2021-06-24', '2025-09-01', 56200000.00, 15.00, 20.00, 50896335.07, 700789.88, 636204.19, 1336994.07, 50195545.19, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 10, '2021-07-24', '2025-09-01', 56200000.00, 15.00, 20.00, 50195545.19, 709549.76, 627444.31, 1336994.07, 49485995.43, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 11, '2021-08-24', '2025-09-01', 56200000.00, 15.00, 20.00, 49485995.43, 718419.13, 618574.94, 1336994.07, 48767576.30, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 12, '2021-09-24', '2025-09-01', 56200000.00, 15.00, 20.00, 48767576.30, 727399.37, 609594.70, 1336994.07, 48040176.93, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 13, '2021-10-24', '2025-09-01', 56200000.00, 15.00, 20.00, 48040176.93, 736491.86, 600502.21, 1336994.07, 47303685.07, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 14, '2021-11-24', '2025-09-01', 56200000.00, 15.00, 20.00, 47303685.07, 745698.01, 591296.06, 1336994.07, 46557987.06, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 15, '2021-12-24', '2025-09-01', 56200000.00, 15.00, 20.00, 46557987.06, 755019.23, 581974.84, 1336994.07, 45802967.83, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 16, '2022-01-24', '2025-09-01', 56200000.00, 15.00, 20.00, 45802967.83, 764456.97, 572537.10, 1336994.07, 45038510.86, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 17, '2022-02-24', '2025-09-01', 56200000.00, 15.00, 20.00, 45038510.86, 774012.68, 562981.39, 1336994.07, 44264498.18, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 18, '2022-03-24', '2025-09-01', 56200000.00, 15.00, 20.00, 44264498.18, 783687.84, 553306.23, 1336994.07, 43480810.34, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 19, '2022-04-24', '2025-09-01', 56200000.00, 15.00, 20.00, 43480810.34, 793483.94, 543510.13, 1336994.07, 42687326.40, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 20, '2022-05-24', '2025-09-01', 56200000.00, 15.00, 20.00, 42687326.40, 803402.49, 533591.58, 1336994.07, 41883923.91, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 21, '2022-06-24', '2025-09-01', 56200000.00, 15.00, 20.00, 41883923.91, 813445.02, 523549.05, 1336994.07, 41070478.89, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 22, '2022-07-24', '2025-09-01', 56200000.00, 15.00, 20.00, 41070478.89, 823613.08, 513380.99, 1336994.07, 40246865.81, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 23, '2022-08-24', '2025-09-01', 56200000.00, 15.00, 20.00, 40246865.81, 833908.25, 503085.82, 1336994.07, 39412957.56, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 24, '2022-09-24', '2025-09-01', 56200000.00, 15.00, 20.00, 39412957.56, 844332.10, 492661.97, 1336994.07, 38568625.46, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 25, '2022-10-24', '2025-09-01', 56200000.00, 15.00, 20.00, 38568625.46, 854886.25, 482107.82, 1336994.07, 37713739.21, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 26, '2022-11-24', '2025-09-01', 56200000.00, 15.00, 20.00, 37713739.21, 865572.33, 471421.74, 1336994.07, 36848166.88, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 27, '2022-12-24', '2025-09-01', 56200000.00, 15.00, 20.00, 36848166.88, 876391.98, 460602.09, 1336994.07, 35971774.90, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 28, '2023-01-24', '2025-09-01', 56200000.00, 15.00, 20.00, 35971774.90, 887346.88, 449647.19, 1336994.07, 35084428.02, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 29, '2023-02-24', '2025-09-01', 56200000.00, 15.00, 20.00, 35084428.02, 898438.72, 438555.35, 1336994.07, 34185989.30, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 30, '2023-03-24', '2025-09-01', 56200000.00, 15.00, 20.00, 34185989.30, 909669.20, 427324.87, 1336994.07, 33276320.10, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 31, '2023-04-24', '2025-09-01', 56200000.00, 15.00, 20.00, 33276320.10, 921040.07, 415954.00, 1336994.07, 32355280.03, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 32, '2023-05-24', '2025-09-01', 56200000.00, 15.00, 20.00, 32355280.03, 932553.07, 404441.00, 1336994.07, 31422726.96, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 33, '2023-06-24', '2025-09-01', 56200000.00, 15.00, 20.00, 31422726.96, 944209.98, 392784.09, 1336994.07, 30478516.98, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 34, '2023-07-24', '2025-09-01', 56200000.00, 15.00, 20.00, 30478516.98, 956012.61, 380981.46, 1336994.07, 29522504.37, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 35, '2023-08-24', '2025-09-01', 56200000.00, 15.00, 20.00, 29522504.37, 967962.77, 369031.30, 1336994.07, 28554541.60, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 36, '2023-09-24', '2025-09-01', 56200000.00, 15.00, 20.00, 28554541.60, 980062.30, 356931.77, 1336994.07, 27574479.30, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 37, '2023-10-24', '2025-09-01', 56200000.00, 15.00, 20.00, 27574479.30, 992313.08, 344680.99, 1336994.07, 26582166.22, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 38, '2023-11-24', '2025-09-01', 56200000.00, 15.00, 20.00, 26582166.22, 1004716.99, 332277.08, 1336994.07, 25577449.23, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 39, '2023-12-24', '2025-09-01', 56200000.00, 15.00, 20.00, 25577449.23, 1017275.95, 319718.12, 1336994.07, 24560173.28, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 40, '2024-01-24', '2025-09-01', 56200000.00, 15.00, 20.00, 24560173.28, 1029991.90, 307002.17, 1336994.07, 23530181.38, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 41, '2024-02-24', '2025-09-01', 56200000.00, 15.00, 20.00, 23530181.38, 1042866.80, 294127.27, 1336994.07, 22487314.58, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 42, '2024-03-24', '2025-09-01', 56200000.00, 15.00, 20.00, 22487314.58, 1055902.64, 281091.43, 1336994.07, 21431411.94, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 43, '2024-04-24', '2025-09-01', 56200000.00, 15.00, 20.00, 21431411.94, 1069101.42, 267892.65, 1336994.07, 20362310.52, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 44, '2024-05-24', '2025-09-01', 56200000.00, 15.00, 20.00, 20362310.52, 1082465.19, 254528.88, 1336994.07, 19279845.33, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 45, '2024-06-24', '2025-09-01', 56200000.00, 15.00, 20.00, 19279845.33, 1095996.00, 240998.07, 1336994.07, 18183849.33, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 46, '2024-07-24', '2025-09-01', 56200000.00, 15.00, 20.00, 18183849.33, 1109695.95, 227298.12, 1336994.07, 17074153.38, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 47, '2024-08-24', '2025-09-01', 56200000.00, 15.00, 20.00, 17074153.38, 1123567.15, 213426.92, 1336994.07, 15950586.23, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 48, '2024-09-24', '2025-09-01', 56200000.00, 15.00, 20.00, 15950586.23, 1137611.74, 199382.33, 1336994.07, 14812974.49, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 49, '2024-10-24', '2025-09-01', 56200000.00, 15.00, 20.00, 14812974.49, 1151831.89, 185162.18, 1336994.07, 13661142.60, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 50, '2024-11-24', '2025-09-01', 56200000.00, 15.00, 20.00, 13661142.60, 1166229.79, 170764.28, 1336994.07, 12494912.81, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 51, '2024-12-24', '2025-09-01', 56200000.00, 15.00, 20.00, 12494912.81, 1180807.66, 156186.41, 1336994.07, 11314105.15, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 52, '2025-01-24', '2025-09-01', 56200000.00, 15.00, 20.00, 11314105.15, 1195567.76, 141426.31, 1336994.07, 10118537.39, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 53, '2025-02-24', '2025-09-01', 56200000.00, 15.00, 20.00, 10118537.39, 1210512.35, 126481.72, 1336994.07, 8908025.04, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 54, '2025-03-24', '2025-09-01', 56200000.00, 15.00, 20.00, 8908025.04, 1225643.76, 111350.31, 1336994.07, 7682381.28, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 55, '2025-04-24', '2025-09-01', 56200000.00, 15.00, 20.00, 7682381.28, 1240964.30, 96029.77, 1336994.07, 6441416.98, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 56, '2025-05-24', '2025-09-01', 56200000.00, 15.00, 20.00, 6441416.98, 1256476.36, 80517.71, 1336994.07, 5184940.62, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 57, '2025-06-24', '2025-09-01', 56200000.00, 15.00, 20.00, 5184940.62, 1272182.31, 64811.76, 1336994.07, 3912758.31, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 58, '2025-07-24', '2025-09-01', 56200000.00, 15.00, 20.00, 3912758.31, 1288084.59, 48909.48, 1336994.07, 2624673.72, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 59, '2025-08-24', '2025-09-01', 56200000.00, 15.00, 20.00, 2624673.72, 1304185.65, 32808.42, 1336994.07, 1320488.07, 151962.19, 1488956.26, 0.00, 1488956.26),
(97, 60, '2025-09-24', '2025-09-01', 56200000.00, 15.00, 20.00, 1320488.07, 1320487.97, 16506.10, 1336994.07, 0.10, 151962.19, 1488956.26, 0.00, 1488956.26),
(1, 1, '2020-07-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 2, '2020-08-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 3, '2020-09-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 4, '2020-10-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 5, '2020-11-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 6, '2020-12-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 7, '2021-01-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 8, '2021-02-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 9, '2021-03-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 10, '2021-04-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 11, '2021-05-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(1, 12, '2021-06-24', '2021-06-08', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(2, 1, '2020-07-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 2, '2020-08-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 3, '2020-09-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 4, '2020-10-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 5, '2020-11-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 6, '2020-12-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 7, '2021-01-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 8, '2021-02-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 9, '2021-03-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 10, '2021-04-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 11, '2021-05-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 12, '2021-06-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 13, '2021-07-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 14, '2021-08-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 15, '2021-09-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 16, '2021-10-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 17, '2021-11-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 18, '2021-12-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 19, '2022-01-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 20, '2022-02-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 21, '2022-03-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 22, '2022-04-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 23, '2022-05-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(2, 24, '2022-06-24', '2022-06-08', 10500000.00, 45.60, 20000.00, 0.00, 437500.00, 199500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 637000.00),
(3, 1, '2020-07-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 2, '2020-08-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 3, '2020-09-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 4, '2020-10-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 5, '2020-11-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 6, '2020-12-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 7, '2021-01-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 8, '2021-02-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 9, '2021-03-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 10, '2021-04-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 11, '2021-05-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(3, 12, '2021-06-24', '2021-06-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(4, 1, '2020-07-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 2, '2020-08-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 3, '2020-09-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 4, '2020-10-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 5, '2020-11-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 6, '2020-12-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 7, '2021-01-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 8, '2021-02-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 9, '2021-03-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 10, '2021-04-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 11, '2021-05-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 12, '2021-06-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 13, '2021-07-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 14, '2021-08-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 15, '2021-09-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 16, '2021-10-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 17, '2021-11-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 18, '2021-12-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 19, '2022-01-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 20, '2022-02-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 21, '2022-03-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 22, '2022-04-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 23, '2022-05-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(4, 24, '2022-06-24', '2022-06-08', 17100000.00, 45.60, 20000.00, 0.00, 712500.00, 324900.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1037400.00),
(5, 1, '2020-07-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 2, '2020-08-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 3, '2020-09-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 4, '2020-10-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 5, '2020-11-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 6, '2020-12-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 7, '2021-01-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 8, '2021-02-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 9, '2021-03-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 10, '2021-04-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 11, '2021-05-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(5, 12, '2021-06-24', '2021-06-09', 7000000.00, 20.40, 20000.00, 0.00, 583333.33, 119000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 702333.33),
(7, 1, '2020-07-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 2, '2020-08-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 3, '2020-09-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 4, '2020-10-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 5, '2020-11-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 6, '2020-12-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 7, '2021-01-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 8, '2021-02-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 9, '2021-03-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 10, '2021-04-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 11, '2021-05-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 12, '2021-06-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 13, '2021-07-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 14, '2021-08-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 15, '2021-09-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 16, '2021-10-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 17, '2021-11-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 18, '2021-12-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 19, '2022-01-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 20, '2022-02-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 21, '2022-03-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 22, '2022-04-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 23, '2022-05-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(7, 24, '2022-06-24', '2022-06-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(8, 1, '2020-07-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 2, '2020-08-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 3, '2020-09-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 4, '2020-10-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 5, '2020-11-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 6, '2020-12-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 7, '2021-01-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 8, '2021-02-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 9, '2021-03-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 10, '2021-04-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 11, '2021-05-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 12, '2021-06-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 13, '2021-07-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 14, '2021-08-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 15, '2021-09-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 16, '2021-10-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 17, '2021-11-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 18, '2021-12-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 19, '2022-01-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 20, '2022-02-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 21, '2022-03-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 22, '2022-04-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 23, '2022-05-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(8, 24, '2022-06-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 1, '2020-07-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 2, '2020-08-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 3, '2020-09-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 4, '2020-10-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 5, '2020-11-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 6, '2020-12-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 7, '2021-01-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 8, '2021-02-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 9, '2021-03-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 10, '2021-04-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 11, '2021-05-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 12, '2021-06-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 13, '2021-07-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 14, '2021-08-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 15, '2021-09-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 16, '2021-10-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 17, '2021-11-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 18, '2021-12-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 19, '2022-01-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 20, '2022-02-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 21, '2022-03-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 22, '2022-04-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 23, '2022-05-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(9, 24, '2022-06-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 1, '2020-07-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 2, '2020-08-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 3, '2020-09-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 4, '2020-10-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 5, '2020-11-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 6, '2020-12-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 7, '2021-01-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 8, '2021-02-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 9, '2021-03-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 10, '2021-04-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 11, '2021-05-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 12, '2021-06-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 13, '2021-07-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 14, '2021-08-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 15, '2021-09-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 16, '2021-10-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 17, '2021-11-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 18, '2021-12-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 19, '2022-01-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 20, '2022-02-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 21, '2022-03-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 22, '2022-04-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 23, '2022-05-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(10, 24, '2022-06-24', '2022-06-10', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(11, 1, '2020-07-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 2, '2020-08-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 3, '2020-09-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 4, '2020-10-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 5, '2020-11-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 6, '2020-12-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 7, '2021-01-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 8, '2021-02-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 9, '2021-03-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 10, '2021-04-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 11, '2021-05-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 12, '2021-06-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 13, '2021-07-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 14, '2021-08-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 15, '2021-09-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 16, '2021-10-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 17, '2021-11-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 18, '2021-12-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 19, '2022-01-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 20, '2022-02-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 21, '2022-03-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 22, '2022-04-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 23, '2022-05-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(11, 24, '2022-06-24', '2022-06-11', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(12, 1, '2020-07-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 2, '2020-08-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 3, '2020-09-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 4, '2020-10-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 5, '2020-11-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 6, '2020-12-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 7, '2021-01-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 8, '2021-02-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 9, '2021-03-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 10, '2021-04-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 11, '2021-05-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 12, '2021-06-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 13, '2021-07-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 14, '2021-08-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 15, '2021-09-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 16, '2021-10-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 17, '2021-11-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 18, '2021-12-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 19, '2022-01-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33);
INSERT INTO `tbl_pinjaman_simulasi` (`tbl_pinjam_hid`, `blnke`, `periode`, `tempo`, `plafondpinjaman`, `bunga`, `biayaadm`, `sisapokokawal`, `angsuranpokok`, `angsuranbunga`, `totalangsuranbank`, `sisapokokakhir`, `adminangsuran`, `angsurandebitur`, `simpananwajib`, `jumlahangsuran`) VALUES
(12, 20, '2022-02-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 21, '2022-03-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 22, '2022-04-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 23, '2022-05-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(12, 24, '2022-06-24', '2022-06-07', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(13, 1, '2020-07-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 2, '2020-08-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 3, '2020-09-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 4, '2020-10-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 5, '2020-11-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 6, '2020-12-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 7, '2021-01-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 8, '2021-02-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 9, '2021-03-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 10, '2021-04-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 11, '2021-05-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(13, 12, '2021-06-24', '2021-06-10', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(14, 1, '2020-07-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 2, '2020-08-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 3, '2020-09-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 4, '2020-10-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 5, '2020-11-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 6, '2020-12-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 7, '2021-01-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 8, '2021-02-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 9, '2021-03-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 10, '2021-04-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 11, '2021-05-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 12, '2021-06-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 13, '2021-07-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 14, '2021-08-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 15, '2021-09-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 16, '2021-10-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 17, '2021-11-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 18, '2021-12-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 19, '2022-01-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 20, '2022-02-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 21, '2022-03-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 22, '2022-04-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 23, '2022-05-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(14, 24, '2022-06-24', '2022-06-15', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(15, 1, '2020-07-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 2, '2020-08-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 3, '2020-09-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 4, '2020-10-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 5, '2020-11-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 6, '2020-12-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 7, '2021-01-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 8, '2021-02-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 9, '2021-03-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 10, '2021-04-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 11, '2021-05-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 12, '2021-06-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 13, '2021-07-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 14, '2021-08-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 15, '2021-09-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 16, '2021-10-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 17, '2021-11-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 18, '2021-12-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 19, '2022-01-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 20, '2022-02-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 21, '2022-03-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 22, '2022-04-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 23, '2022-05-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(15, 24, '2022-06-24', '2022-06-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 1, '2020-07-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 2, '2020-08-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 3, '2020-09-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 4, '2020-10-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 5, '2020-11-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 6, '2020-12-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 7, '2021-01-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 8, '2021-02-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 9, '2021-03-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 10, '2021-04-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 11, '2021-05-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 12, '2021-06-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 13, '2021-07-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 14, '2021-08-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 15, '2021-09-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 16, '2021-10-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 17, '2021-11-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 18, '2021-12-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 19, '2022-01-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 20, '2022-02-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 21, '2022-03-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 22, '2022-04-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 23, '2022-05-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(16, 24, '2022-06-24', '2022-06-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(17, 1, '2020-07-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 2, '2020-08-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 3, '2020-09-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 4, '2020-10-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 5, '2020-11-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 6, '2020-12-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 7, '2021-01-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 8, '2021-02-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 9, '2021-03-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 10, '2021-04-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 11, '2021-05-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 12, '2021-06-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 13, '2021-07-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 14, '2021-08-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 15, '2021-09-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 16, '2021-10-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 17, '2021-11-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 18, '2021-12-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 19, '2022-01-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 20, '2022-02-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 21, '2022-03-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 22, '2022-04-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 23, '2022-05-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(17, 24, '2022-06-24', '2022-06-15', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(18, 1, '2020-07-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 2, '2020-08-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 3, '2020-09-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 4, '2020-10-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 5, '2020-11-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 6, '2020-12-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 7, '2021-01-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 8, '2021-02-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 9, '2021-03-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 10, '2021-04-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 11, '2021-05-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 12, '2021-06-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 13, '2021-07-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 14, '2021-08-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 15, '2021-09-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 16, '2021-10-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 17, '2021-11-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 18, '2021-12-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 19, '2022-01-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 20, '2022-02-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 21, '2022-03-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 22, '2022-04-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 23, '2022-05-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(18, 24, '2022-06-24', '2022-06-16', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(19, 1, '2020-07-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 2, '2020-08-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 3, '2020-09-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 4, '2020-10-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 5, '2020-11-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 6, '2020-12-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 7, '2021-01-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 8, '2021-02-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 9, '2021-03-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 10, '2021-04-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 11, '2021-05-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 12, '2021-06-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 13, '2021-07-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 14, '2021-08-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 15, '2021-09-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 16, '2021-10-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 17, '2021-11-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 18, '2021-12-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 19, '2022-01-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 20, '2022-02-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 21, '2022-03-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 22, '2022-04-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 23, '2022-05-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(19, 24, '2022-06-24', '2022-06-18', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 1, '2020-07-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 2, '2020-08-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 3, '2020-09-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 4, '2020-10-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 5, '2020-11-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 6, '2020-12-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 7, '2021-01-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 8, '2021-02-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 9, '2021-03-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 10, '2021-04-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 11, '2021-05-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 12, '2021-06-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 13, '2021-07-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 14, '2021-08-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 15, '2021-09-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 16, '2021-10-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 17, '2021-11-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 18, '2021-12-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 19, '2022-01-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 20, '2022-02-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 21, '2022-03-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 22, '2022-04-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 23, '2022-05-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(20, 24, '2022-06-24', '2022-06-19', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(21, 1, '2020-07-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 2, '2020-08-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 3, '2020-09-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 4, '2020-10-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 5, '2020-11-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 6, '2020-12-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 7, '2021-01-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 8, '2021-02-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 9, '2021-03-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 10, '2021-04-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 11, '2021-05-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 12, '2021-06-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 13, '2021-07-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 14, '2021-08-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 15, '2021-09-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 16, '2021-10-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 17, '2021-11-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 18, '2021-12-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 19, '2022-01-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 20, '2022-02-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 21, '2022-03-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 22, '2022-04-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 23, '2022-05-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(21, 24, '2022-06-24', '2022-06-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(22, 1, '2020-07-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 2, '2020-08-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 3, '2020-09-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 4, '2020-10-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 5, '2020-11-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 6, '2020-12-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 7, '2021-01-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 8, '2021-02-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 9, '2021-03-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 10, '2021-04-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 11, '2021-05-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 12, '2021-06-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 13, '2021-07-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 14, '2021-08-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 15, '2021-09-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 16, '2021-10-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 17, '2021-11-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 18, '2021-12-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 19, '2022-01-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 20, '2022-02-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 21, '2022-03-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 22, '2022-04-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 23, '2022-05-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(22, 24, '2022-06-24', '2022-06-11', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(26, 1, '2020-07-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 2, '2020-08-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 3, '2020-09-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 4, '2020-10-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 5, '2020-11-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 6, '2020-12-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 7, '2021-01-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 8, '2021-02-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 9, '2021-03-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 10, '2021-04-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 11, '2021-05-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 12, '2021-06-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 13, '2021-07-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 14, '2021-08-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 15, '2021-09-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 16, '2021-10-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 17, '2021-11-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 18, '2021-12-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 19, '2022-01-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 20, '2022-02-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 21, '2022-03-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 22, '2022-04-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 23, '2022-05-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(26, 24, '2022-06-24', '2022-06-24', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 1, '2020-07-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 2, '2020-08-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 3, '2020-09-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 4, '2020-10-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 5, '2020-11-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 6, '2020-12-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 7, '2021-01-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 8, '2021-02-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 9, '2021-03-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 10, '2021-04-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 11, '2021-05-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 12, '2021-06-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 13, '2021-07-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 14, '2021-08-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 15, '2021-09-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 16, '2021-10-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 17, '2021-11-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 18, '2021-12-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 19, '2022-01-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 20, '2022-02-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 21, '2022-03-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 22, '2022-04-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 23, '2022-05-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(23, 24, '2022-06-24', '2022-06-19', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(24, 1, '2020-07-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 2, '2020-08-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 3, '2020-09-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 4, '2020-10-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 5, '2020-11-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 6, '2020-12-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 7, '2021-01-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 8, '2021-02-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 9, '2021-03-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 10, '2021-04-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 11, '2021-05-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(24, 12, '2021-06-24', '2021-06-24', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(25, 1, '2020-07-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 2, '2020-08-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 3, '2020-09-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 4, '2020-10-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 5, '2020-11-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 6, '2020-12-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 7, '2021-01-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 8, '2021-02-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 9, '2021-03-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 10, '2021-04-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 11, '2021-05-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 12, '2021-06-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 13, '2021-07-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 14, '2021-08-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 15, '2021-09-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 16, '2021-10-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 17, '2021-11-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 18, '2021-12-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 19, '2022-01-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 20, '2022-02-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 21, '2022-03-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 22, '2022-04-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 23, '2022-05-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(25, 24, '2022-06-24', '2022-06-19', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 1, '2020-08-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 2, '2020-09-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 3, '2020-10-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 4, '2020-11-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 5, '2020-12-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 6, '2021-01-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 7, '2021-02-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 8, '2021-03-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 9, '2021-04-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 10, '2021-05-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 11, '2021-06-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 12, '2021-07-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 13, '2021-08-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 14, '2021-09-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 15, '2021-10-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 16, '2021-11-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 17, '2021-12-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 18, '2022-01-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 19, '2022-02-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 20, '2022-03-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 21, '2022-04-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 22, '2022-05-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 23, '2022-06-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(27, 24, '2022-07-24', '2022-07-01', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(28, 1, '2020-08-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 2, '2020-09-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 3, '2020-10-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 4, '2020-11-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 5, '2020-12-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 6, '2021-01-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 7, '2021-02-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 8, '2021-03-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 9, '2021-04-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 10, '2021-05-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 11, '2021-06-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(28, 12, '2021-07-24', '2021-07-01', 12300000.00, 20.40, 20000.00, 0.00, 1025000.00, 209100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1234100.00),
(29, 1, '2020-08-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 2, '2020-09-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 3, '2020-10-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 4, '2020-11-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 5, '2020-12-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 6, '2021-01-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 7, '2021-02-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 8, '2021-03-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 9, '2021-04-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 10, '2021-05-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 11, '2021-06-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 12, '2021-07-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 13, '2021-08-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 14, '2021-09-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33);
INSERT INTO `tbl_pinjaman_simulasi` (`tbl_pinjam_hid`, `blnke`, `periode`, `tempo`, `plafondpinjaman`, `bunga`, `biayaadm`, `sisapokokawal`, `angsuranpokok`, `angsuranbunga`, `totalangsuranbank`, `sisapokokakhir`, `adminangsuran`, `angsurandebitur`, `simpananwajib`, `jumlahangsuran`) VALUES
(29, 15, '2021-10-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 16, '2021-11-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 17, '2021-12-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 18, '2022-01-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 19, '2022-02-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 20, '2022-03-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 21, '2022-04-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 22, '2022-05-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 23, '2022-06-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(29, 24, '2022-07-24', '2022-07-02', 17000000.00, 45.60, 20000.00, 0.00, 708333.33, 323000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1031333.33),
(30, 1, '2020-08-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 2, '2020-09-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 3, '2020-10-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 4, '2020-11-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 5, '2020-12-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 6, '2021-01-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 7, '2021-02-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 8, '2021-03-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 9, '2021-04-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 10, '2021-05-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 11, '2021-06-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 12, '2021-07-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 13, '2021-08-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 14, '2021-09-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 15, '2021-10-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 16, '2021-11-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 17, '2021-12-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 18, '2022-01-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 19, '2022-02-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 20, '2022-03-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 21, '2022-04-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 22, '2022-05-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 23, '2022-06-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(30, 24, '2022-07-24', '2022-07-02', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(31, 1, '2020-08-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 2, '2020-09-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 3, '2020-10-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 4, '2020-11-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 5, '2020-12-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 6, '2021-01-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 7, '2021-02-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 8, '2021-03-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 9, '2021-04-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 10, '2021-05-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 11, '2021-06-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 12, '2021-07-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 13, '2021-08-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 14, '2021-09-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 15, '2021-10-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 16, '2021-11-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 17, '2021-12-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 18, '2022-01-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 19, '2022-02-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 20, '2022-03-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 21, '2022-04-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 22, '2022-05-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 23, '2022-06-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(31, 24, '2022-07-24', '2022-07-06', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(32, 1, '2020-08-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 2, '2020-09-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 3, '2020-10-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 4, '2020-11-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 5, '2020-12-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 6, '2021-01-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 7, '2021-02-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 8, '2021-03-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 9, '2021-04-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 10, '2021-05-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 11, '2021-06-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(32, 12, '2021-07-24', '2021-07-06', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 1, '2020-08-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 2, '2020-09-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 3, '2020-10-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 4, '2020-11-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 5, '2020-12-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 6, '2021-01-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 7, '2021-02-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 8, '2021-03-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 9, '2021-04-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 10, '2021-05-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 11, '2021-06-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(33, 12, '2021-07-24', '2021-07-07', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(34, 1, '2020-08-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 2, '2020-09-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 3, '2020-10-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 4, '2020-11-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 5, '2020-12-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 6, '2021-01-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 7, '2021-02-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 8, '2021-03-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 9, '2021-04-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 10, '2021-05-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 11, '2021-06-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 12, '2021-07-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 13, '2021-08-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 14, '2021-09-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 15, '2021-10-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 16, '2021-11-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 17, '2021-12-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 18, '2022-01-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 19, '2022-02-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 20, '2022-03-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 21, '2022-04-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 22, '2022-05-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 23, '2022-06-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(34, 24, '2022-07-24', '2022-07-07', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(35, 1, '2020-08-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 2, '2020-09-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 3, '2020-10-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 4, '2020-11-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 5, '2020-12-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 6, '2021-01-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 7, '2021-02-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 8, '2021-03-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 9, '2021-04-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 10, '2021-05-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 11, '2021-06-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(35, 12, '2021-07-24', '2021-07-09', 12000000.00, 20.40, 20000.00, 0.00, 1000000.00, 204000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1204000.00),
(36, 1, '2020-08-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 2, '2020-09-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 3, '2020-10-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 4, '2020-11-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 5, '2020-12-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 6, '2021-01-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 7, '2021-02-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 8, '2021-03-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 9, '2021-04-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 10, '2021-05-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 11, '2021-06-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 12, '2021-07-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 13, '2021-08-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 14, '2021-09-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 15, '2021-10-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 16, '2021-11-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 17, '2021-12-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 18, '2022-01-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 19, '2022-02-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 20, '2022-03-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 21, '2022-04-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 22, '2022-05-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 23, '2022-06-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(36, 24, '2022-07-24', '2022-07-07', 9000000.00, 45.60, 20000.00, 0.00, 375000.00, 171000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 546000.00),
(37, 1, '2020-08-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 2, '2020-09-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 3, '2020-10-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 4, '2020-11-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 5, '2020-12-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 6, '2021-01-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 7, '2021-02-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 8, '2021-03-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 9, '2021-04-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 10, '2021-05-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 11, '2021-06-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 12, '2021-07-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 13, '2021-08-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 14, '2021-09-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 15, '2021-10-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 16, '2021-11-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 17, '2021-12-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 18, '2022-01-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 19, '2022-02-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 20, '2022-03-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 21, '2022-04-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 22, '2022-05-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 23, '2022-06-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(37, 24, '2022-07-24', '2022-07-08', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(38, 1, '2020-08-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 2, '2020-09-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 3, '2020-10-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 4, '2020-11-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 5, '2020-12-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 6, '2021-01-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 7, '2021-02-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 8, '2021-03-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 9, '2021-04-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 10, '2021-05-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 11, '2021-06-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 12, '2021-07-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 13, '2021-08-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 14, '2021-09-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 15, '2021-10-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 16, '2021-11-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 17, '2021-12-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 18, '2022-01-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 19, '2022-02-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 20, '2022-03-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 21, '2022-04-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 22, '2022-05-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 23, '2022-06-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(38, 24, '2022-07-24', '2022-07-07', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(39, 1, '2020-08-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 2, '2020-09-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 3, '2020-10-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 4, '2020-11-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 5, '2020-12-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 6, '2021-01-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 7, '2021-02-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 8, '2021-03-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 9, '2021-04-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 10, '2021-05-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 11, '2021-06-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 12, '2021-07-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 13, '2021-08-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 14, '2021-09-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 15, '2021-10-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 16, '2021-11-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 17, '2021-12-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 18, '2022-01-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 19, '2022-02-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 20, '2022-03-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 21, '2022-04-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 22, '2022-05-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 23, '2022-06-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(39, 24, '2022-07-24', '2022-07-09', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(40, 1, '2020-08-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 2, '2020-09-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 3, '2020-10-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 4, '2020-11-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 5, '2020-12-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 6, '2021-01-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 7, '2021-02-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 8, '2021-03-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 9, '2021-04-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 10, '2021-05-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 11, '2021-06-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 12, '2021-07-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 13, '2021-08-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 14, '2021-09-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 15, '2021-10-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 16, '2021-11-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 17, '2021-12-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 18, '2022-01-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 19, '2022-02-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 20, '2022-03-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 21, '2022-04-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 22, '2022-05-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 23, '2022-06-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(40, 24, '2022-07-24', '2022-07-09', 17900000.00, 45.60, 20000.00, 0.00, 745833.33, 340100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1085933.33),
(41, 1, '2020-08-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 2, '2020-09-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 3, '2020-10-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 4, '2020-11-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 5, '2020-12-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 6, '2021-01-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 7, '2021-02-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 8, '2021-03-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 9, '2021-04-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 10, '2021-05-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 11, '2021-06-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 12, '2021-07-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 13, '2021-08-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 14, '2021-09-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 15, '2021-10-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 16, '2021-11-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 17, '2021-12-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 18, '2022-01-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 19, '2022-02-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 20, '2022-03-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 21, '2022-04-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 22, '2022-05-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 23, '2022-06-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(41, 24, '2022-07-24', '2022-07-14', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 1, '2020-08-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 2, '2020-09-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 3, '2020-10-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 4, '2020-11-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 5, '2020-12-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 6, '2021-01-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 7, '2021-02-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 8, '2021-03-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 9, '2021-04-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 10, '2021-05-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 11, '2021-06-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 12, '2021-07-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 13, '2021-08-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 14, '2021-09-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 15, '2021-10-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 16, '2021-11-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 17, '2021-12-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 18, '2022-01-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 19, '2022-02-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 20, '2022-03-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 21, '2022-04-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 22, '2022-05-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 23, '2022-06-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(42, 24, '2022-07-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 1, '2020-08-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 2, '2020-09-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 3, '2020-10-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 4, '2020-11-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 5, '2020-12-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 6, '2021-01-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 7, '2021-02-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 8, '2021-03-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 9, '2021-04-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 10, '2021-05-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 11, '2021-06-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 12, '2021-07-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 13, '2021-08-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 14, '2021-09-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 15, '2021-10-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 16, '2021-11-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 17, '2021-12-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 18, '2022-01-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 19, '2022-02-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 20, '2022-03-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 21, '2022-04-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 22, '2022-05-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 23, '2022-06-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(43, 24, '2022-07-24', '2022-07-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(45, 1, '2020-08-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 2, '2020-09-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 3, '2020-10-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 4, '2020-11-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 5, '2020-12-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 6, '2021-01-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 7, '2021-02-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 8, '2021-03-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 9, '2021-04-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 10, '2021-05-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 11, '2021-06-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(45, 12, '2021-07-24', '2021-07-13', 18400000.00, 20.40, 20000.00, 0.00, 1533333.33, 312800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1846133.33),
(46, 1, '2020-08-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 2, '2020-09-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 3, '2020-10-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 4, '2020-11-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 5, '2020-12-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 6, '2021-01-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 7, '2021-02-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 8, '2021-03-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 9, '2021-04-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 10, '2021-05-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 11, '2021-06-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 12, '2021-07-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 13, '2021-08-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 14, '2021-09-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 15, '2021-10-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 16, '2021-11-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 17, '2021-12-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 18, '2022-01-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 19, '2022-02-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 20, '2022-03-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 21, '2022-04-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 22, '2022-05-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 23, '2022-06-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(46, 24, '2022-07-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(47, 1, '2020-08-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 2, '2020-09-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 3, '2020-10-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 4, '2020-11-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 5, '2020-12-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 6, '2021-01-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 7, '2021-02-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 8, '2021-03-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 9, '2021-04-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 10, '2021-05-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 11, '2021-06-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(47, 12, '2021-07-24', '2021-07-17', 18500000.00, 20.40, 20000.00, 0.00, 1541666.67, 314500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1856166.67),
(48, 1, '2020-08-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 2, '2020-09-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 3, '2020-10-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 4, '2020-11-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 5, '2020-12-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 6, '2021-01-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 7, '2021-02-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 8, '2021-03-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 9, '2021-04-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00);
INSERT INTO `tbl_pinjaman_simulasi` (`tbl_pinjam_hid`, `blnke`, `periode`, `tempo`, `plafondpinjaman`, `bunga`, `biayaadm`, `sisapokokawal`, `angsuranpokok`, `angsuranbunga`, `totalangsuranbank`, `sisapokokakhir`, `adminangsuran`, `angsurandebitur`, `simpananwajib`, `jumlahangsuran`) VALUES
(48, 10, '2021-05-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 11, '2021-06-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 12, '2021-07-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 13, '2021-08-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 14, '2021-09-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 15, '2021-10-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 16, '2021-11-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 17, '2021-12-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 18, '2022-01-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 19, '2022-02-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 20, '2022-03-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 21, '2022-04-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 22, '2022-05-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 23, '2022-06-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(48, 24, '2022-07-24', '2022-07-16', 18900000.00, 45.60, 20000.00, 0.00, 787500.00, 359100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1146600.00),
(49, 1, '2020-08-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 2, '2020-09-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 3, '2020-10-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 4, '2020-11-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 5, '2020-12-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 6, '2021-01-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 7, '2021-02-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 8, '2021-03-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 9, '2021-04-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 10, '2021-05-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 11, '2021-06-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 12, '2021-07-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 13, '2021-08-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 14, '2021-09-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 15, '2021-10-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 16, '2021-11-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 17, '2021-12-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 18, '2022-01-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 19, '2022-02-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 20, '2022-03-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 21, '2022-04-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 22, '2022-05-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 23, '2022-06-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(49, 24, '2022-07-24', '2022-07-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(50, 1, '2020-08-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 2, '2020-09-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 3, '2020-10-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 4, '2020-11-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 5, '2020-12-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 6, '2021-01-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 7, '2021-02-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 8, '2021-03-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 9, '2021-04-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 10, '2021-05-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 11, '2021-06-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 12, '2021-07-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 13, '2021-08-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 14, '2021-09-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 15, '2021-10-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 16, '2021-11-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 17, '2021-12-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 18, '2022-01-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 19, '2022-02-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 20, '2022-03-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 21, '2022-04-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 22, '2022-05-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 23, '2022-06-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(50, 24, '2022-07-24', '2022-07-08', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(51, 1, '2020-08-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 2, '2020-09-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 3, '2020-10-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 4, '2020-11-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 5, '2020-12-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 6, '2021-01-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 7, '2021-02-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 8, '2021-03-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 9, '2021-04-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 10, '2021-05-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 11, '2021-06-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(51, 12, '2021-07-24', '2021-07-26', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(52, 1, '2020-08-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 2, '2020-09-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 3, '2020-10-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 4, '2020-11-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 5, '2020-12-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 6, '2021-01-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 7, '2021-02-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 8, '2021-03-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 9, '2021-04-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 10, '2021-05-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 11, '2021-06-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 12, '2021-07-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 13, '2021-08-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 14, '2021-09-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 15, '2021-10-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 16, '2021-11-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 17, '2021-12-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 18, '2022-01-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 19, '2022-02-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 20, '2022-03-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 21, '2022-04-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 22, '2022-05-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 23, '2022-06-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(52, 24, '2022-07-24', '2022-07-23', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(53, 1, '2020-08-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 2, '2020-09-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 3, '2020-10-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 4, '2020-11-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 5, '2020-12-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 6, '2021-01-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 7, '2021-02-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 8, '2021-03-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 9, '2021-04-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 10, '2021-05-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 11, '2021-06-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(53, 12, '2021-07-24', '2021-07-24', 17000000.00, 20.40, 20000.00, 0.00, 1416666.67, 289000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1705666.67),
(54, 1, '2020-09-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 2, '2020-10-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 3, '2020-11-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 4, '2020-12-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 5, '2021-01-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 6, '2021-02-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 7, '2021-03-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 8, '2021-04-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 9, '2021-05-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 10, '2021-06-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 11, '2021-07-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 12, '2021-08-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 13, '2021-09-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 14, '2021-10-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 15, '2021-11-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 16, '2021-12-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 17, '2022-01-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 18, '2022-02-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 19, '2022-03-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 20, '2022-04-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 21, '2022-05-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 22, '2022-06-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 23, '2022-07-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(54, 24, '2022-08-24', '2022-08-04', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 1, '2020-09-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 2, '2020-10-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 3, '2020-11-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 4, '2020-12-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 5, '2021-01-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 6, '2021-02-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 7, '2021-03-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 8, '2021-04-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 9, '2021-05-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 10, '2021-06-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 11, '2021-07-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 12, '2021-08-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 13, '2021-09-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 14, '2021-10-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 15, '2021-11-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 16, '2021-12-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 17, '2022-01-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 18, '2022-02-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 19, '2022-03-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 20, '2022-04-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 21, '2022-05-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 22, '2022-06-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 23, '2022-07-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(55, 24, '2022-08-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 1, '2020-09-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 2, '2020-10-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 3, '2020-11-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 4, '2020-12-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 5, '2021-01-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 6, '2021-02-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 7, '2021-03-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 8, '2021-04-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 9, '2021-05-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 10, '2021-06-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 11, '2021-07-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 12, '2021-08-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 13, '2021-09-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 14, '2021-10-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 15, '2021-11-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 16, '2021-12-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 17, '2022-01-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 18, '2022-02-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 19, '2022-03-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 20, '2022-04-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 21, '2022-05-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 22, '2022-06-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 23, '2022-07-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(56, 24, '2022-08-24', '2022-08-05', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(57, 1, '2020-09-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 2, '2020-10-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 3, '2020-11-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 4, '2020-12-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 5, '2021-01-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 6, '2021-02-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 7, '2021-03-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 8, '2021-04-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 9, '2021-05-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 10, '2021-06-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 11, '2021-07-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 12, '2021-08-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 13, '2021-09-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 14, '2021-10-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 15, '2021-11-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 16, '2021-12-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 17, '2022-01-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 18, '2022-02-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 19, '2022-03-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 20, '2022-04-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 21, '2022-05-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 22, '2022-06-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 23, '2022-07-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(57, 24, '2022-08-24', '2022-08-03', 15500000.00, 45.60, 20000.00, 0.00, 645833.33, 294500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 940333.33),
(58, 1, '2020-09-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 2, '2020-10-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 3, '2020-11-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 4, '2020-12-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 5, '2021-01-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 6, '2021-02-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 7, '2021-03-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 8, '2021-04-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 9, '2021-05-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 10, '2021-06-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 11, '2021-07-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 12, '2021-08-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 13, '2021-09-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 14, '2021-10-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 15, '2021-11-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 16, '2021-12-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 17, '2022-01-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 18, '2022-02-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 19, '2022-03-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 20, '2022-04-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 21, '2022-05-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 22, '2022-06-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 23, '2022-07-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(58, 24, '2022-08-24', '2022-08-04', 14000000.00, 45.60, 20000.00, 0.00, 583333.33, 266000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 849333.33),
(59, 1, '2020-09-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 2, '2020-10-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 3, '2020-11-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 4, '2020-12-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 5, '2021-01-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 6, '2021-02-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 7, '2021-03-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 8, '2021-04-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 9, '2021-05-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 10, '2021-06-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 11, '2021-07-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 12, '2021-08-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 13, '2021-09-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 14, '2021-10-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 15, '2021-11-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 16, '2021-12-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 17, '2022-01-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 18, '2022-02-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 19, '2022-03-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 20, '2022-04-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 21, '2022-05-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 22, '2022-06-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 23, '2022-07-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(59, 24, '2022-08-24', '2022-08-11', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(60, 1, '2020-09-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 2, '2020-10-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 3, '2020-11-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 4, '2020-12-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 5, '2021-01-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 6, '2021-02-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 7, '2021-03-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 8, '2021-04-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 9, '2021-05-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 10, '2021-06-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 11, '2021-07-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(60, 12, '2021-08-24', '2021-08-12', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 1, '2020-09-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 2, '2020-10-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 3, '2020-11-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 4, '2020-12-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 5, '2021-01-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 6, '2021-02-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 7, '2021-03-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 8, '2021-04-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 9, '2021-05-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 10, '2021-06-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 11, '2021-07-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(61, 12, '2021-08-24', '2021-08-14', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(62, 1, '2020-09-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 2, '2020-10-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 3, '2020-11-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 4, '2020-12-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 5, '2021-01-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 6, '2021-02-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 7, '2021-03-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 8, '2021-04-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 9, '2021-05-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 10, '2021-06-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 11, '2021-07-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 12, '2021-08-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 13, '2021-09-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 14, '2021-10-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 15, '2021-11-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 16, '2021-12-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 17, '2022-01-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 18, '2022-02-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 19, '2022-03-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 20, '2022-04-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 21, '2022-05-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 22, '2022-06-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 23, '2022-07-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(62, 24, '2022-08-24', '2022-08-12', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 1, '2020-09-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 2, '2020-10-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 3, '2020-11-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 4, '2020-12-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 5, '2021-01-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 6, '2021-02-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 7, '2021-03-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 8, '2021-04-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 9, '2021-05-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 10, '2021-06-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 11, '2021-07-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 12, '2021-08-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 13, '2021-09-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 14, '2021-10-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 15, '2021-11-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 16, '2021-12-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 17, '2022-01-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 18, '2022-02-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 19, '2022-03-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 20, '2022-04-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 21, '2022-05-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 22, '2022-06-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 23, '2022-07-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(63, 24, '2022-08-24', '2022-08-18', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(64, 1, '2020-09-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 2, '2020-10-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 3, '2020-11-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 4, '2020-12-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 5, '2021-01-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 6, '2021-02-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 7, '2021-03-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 8, '2021-04-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 9, '2021-05-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 10, '2021-06-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 11, '2021-07-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(64, 12, '2021-08-24', '2021-08-13', 10000000.00, 20.40, 20000.00, 0.00, 833333.33, 170000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1003333.33),
(65, 1, '2020-09-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 2, '2020-10-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 3, '2020-11-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 4, '2020-12-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 5, '2021-01-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 6, '2021-02-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 7, '2021-03-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 8, '2021-04-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 9, '2021-05-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 10, '2021-06-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 11, '2021-07-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(65, 12, '2021-08-24', '2021-08-11', 11000000.00, 25.40, 20000.00, 0.00, 916666.67, 232800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1149466.67),
(66, 1, '2020-09-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 2, '2020-10-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 3, '2020-11-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 4, '2020-12-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 5, '2021-01-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 6, '2021-02-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 7, '2021-03-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 8, '2021-04-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 9, '2021-05-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 10, '2021-06-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 11, '2021-07-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 12, '2021-08-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 13, '2021-09-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 14, '2021-10-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 15, '2021-11-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 16, '2021-12-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33);
INSERT INTO `tbl_pinjaman_simulasi` (`tbl_pinjam_hid`, `blnke`, `periode`, `tempo`, `plafondpinjaman`, `bunga`, `biayaadm`, `sisapokokawal`, `angsuranpokok`, `angsuranbunga`, `totalangsuranbank`, `sisapokokakhir`, `adminangsuran`, `angsurandebitur`, `simpananwajib`, `jumlahangsuran`) VALUES
(66, 17, '2022-01-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 18, '2022-02-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 19, '2022-03-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 20, '2022-04-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 21, '2022-05-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 22, '2022-06-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 23, '2022-07-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(66, 24, '2022-08-24', '2022-08-12', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(67, 1, '2020-09-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 2, '2020-10-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 3, '2020-11-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 4, '2020-12-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 5, '2021-01-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 6, '2021-02-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 7, '2021-03-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 8, '2021-04-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 9, '2021-05-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 10, '2021-06-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 11, '2021-07-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 12, '2021-08-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 13, '2021-09-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 14, '2021-10-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 15, '2021-11-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 16, '2021-12-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 17, '2022-01-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 18, '2022-02-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 19, '2022-03-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 20, '2022-04-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 21, '2022-05-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 22, '2022-06-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 23, '2022-07-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(67, 24, '2022-08-24', '2022-08-11', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(68, 1, '2020-09-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 2, '2020-10-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 3, '2020-11-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 4, '2020-12-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 5, '2021-01-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 6, '2021-02-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 7, '2021-03-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 8, '2021-04-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 9, '2021-05-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 10, '2021-06-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 11, '2021-07-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(68, 12, '2021-08-24', '2021-08-25', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(69, 1, '2020-09-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 2, '2020-10-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 3, '2020-11-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 4, '2020-12-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 5, '2021-01-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 6, '2021-02-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 7, '2021-03-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 8, '2021-04-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 9, '2021-05-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 10, '2021-06-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 11, '2021-07-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(69, 12, '2021-08-24', '2021-08-20', 11900000.00, 20.40, 20000.00, 0.00, 991666.67, 202300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1193966.67),
(70, 1, '2020-09-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 2, '2020-10-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 3, '2020-11-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 4, '2020-12-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 5, '2021-01-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 6, '2021-02-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 7, '2021-03-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 8, '2021-04-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 9, '2021-05-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 10, '2021-06-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 11, '2021-07-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(70, 12, '2021-08-24', '2021-08-26', 10400000.00, 25.40, 20000.00, 0.00, 866666.67, 220100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1086766.67),
(71, 1, '2020-09-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 2, '2020-10-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 3, '2020-11-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 4, '2020-12-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 5, '2021-01-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 6, '2021-02-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 7, '2021-03-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 8, '2021-04-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 9, '2021-05-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 10, '2021-06-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 11, '2021-07-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 12, '2021-08-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 13, '2021-09-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 14, '2021-10-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 15, '2021-11-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 16, '2021-12-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 17, '2022-01-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 18, '2022-02-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 19, '2022-03-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 20, '2022-04-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 21, '2022-05-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 22, '2022-06-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 23, '2022-07-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(71, 24, '2022-08-24', '2022-08-26', 11000000.00, 45.60, 20000.00, 0.00, 458333.33, 209000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 667333.33),
(72, 1, '2020-09-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 2, '2020-10-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 3, '2020-11-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 4, '2020-12-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 5, '2021-01-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 6, '2021-02-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 7, '2021-03-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 8, '2021-04-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 9, '2021-05-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 10, '2021-06-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 11, '2021-07-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 12, '2021-08-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 13, '2021-09-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 14, '2021-10-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 15, '2021-11-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 16, '2021-12-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 17, '2022-01-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 18, '2022-02-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 19, '2022-03-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 20, '2022-04-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 21, '2022-05-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 22, '2022-06-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 23, '2022-07-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(72, 24, '2022-08-24', '2022-08-18', 16900000.00, 45.60, 20000.00, 0.00, 704166.67, 321100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1025266.67),
(73, 1, '2020-10-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 2, '2020-11-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 3, '2020-12-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 4, '2021-01-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 5, '2021-02-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 6, '2021-03-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 7, '2021-04-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 8, '2021-05-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 9, '2021-06-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 10, '2021-07-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 11, '2021-08-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 12, '2021-09-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 13, '2021-10-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 14, '2021-11-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 15, '2021-12-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 16, '2022-01-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 17, '2022-02-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 18, '2022-03-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 19, '2022-04-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 20, '2022-05-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 21, '2022-06-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 22, '2022-07-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 23, '2022-08-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(73, 24, '2022-09-24', '2022-09-01', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(74, 1, '2020-10-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 2, '2020-11-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 3, '2020-12-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 4, '2021-01-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 5, '2021-02-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 6, '2021-03-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 7, '2021-04-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 8, '2021-05-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 9, '2021-06-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 10, '2021-07-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 11, '2021-08-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 12, '2021-09-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 13, '2021-10-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 14, '2021-11-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 15, '2021-12-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 16, '2022-01-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 17, '2022-02-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 18, '2022-03-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 19, '2022-04-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 20, '2022-05-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 21, '2022-06-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 22, '2022-07-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 23, '2022-08-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(74, 24, '2022-09-24', '2022-09-02', 17200000.00, 45.60, 20000.00, 0.00, 716666.67, 326800.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1043466.67),
(75, 1, '2020-10-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 2, '2020-11-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 3, '2020-12-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 4, '2021-01-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 5, '2021-02-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 6, '2021-03-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 7, '2021-04-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 8, '2021-05-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 9, '2021-06-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 10, '2021-07-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 11, '2021-08-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(75, 12, '2021-09-24', '2021-09-03', 6900000.00, 20.40, 20000.00, 0.00, 575000.00, 117300.00, 0.00, 0.00, 0.00, 0.00, 0.00, 692300.00),
(76, 1, '2020-10-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 2, '2020-11-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 3, '2020-12-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 4, '2021-01-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 5, '2021-02-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 6, '2021-03-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 7, '2021-04-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 8, '2021-05-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 9, '2021-06-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 10, '2021-07-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 11, '2021-08-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 12, '2021-09-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 13, '2021-10-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 14, '2021-11-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 15, '2021-12-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 16, '2022-01-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 17, '2022-02-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 18, '2022-03-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 19, '2022-04-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 20, '2022-05-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 21, '2022-06-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 22, '2022-07-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 23, '2022-08-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(76, 24, '2022-09-24', '2022-09-10', 11800000.00, 45.60, 20000.00, 0.00, 491666.67, 224200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 715866.67),
(77, 1, '2020-10-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 2, '2020-11-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 3, '2020-12-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 4, '2021-01-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 5, '2021-02-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 6, '2021-03-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 7, '2021-04-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 8, '2021-05-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 9, '2021-06-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 10, '2021-07-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 11, '2021-08-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(77, 12, '2021-09-24', '2021-09-13', 13000000.00, 20.40, 20000.00, 0.00, 1083333.33, 221000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1304333.33),
(78, 1, '2020-10-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 2, '2020-11-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 3, '2020-12-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 4, '2021-01-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 5, '2021-02-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 6, '2021-03-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 7, '2021-04-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 8, '2021-05-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 9, '2021-06-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 10, '2021-07-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 11, '2021-08-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 12, '2021-09-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 13, '2021-10-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 14, '2021-11-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 15, '2021-12-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 16, '2022-01-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 17, '2022-02-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 18, '2022-03-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 19, '2022-04-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 20, '2022-05-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 21, '2022-06-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 22, '2022-07-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 23, '2022-08-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(78, 24, '2022-09-24', '2022-09-16', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(79, 1, '2020-10-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 2, '2020-11-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 3, '2020-12-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 4, '2021-01-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 5, '2021-02-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 6, '2021-03-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 7, '2021-04-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 8, '2021-05-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 9, '2021-06-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 10, '2021-07-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 11, '2021-08-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 12, '2021-09-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 13, '2021-10-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 14, '2021-11-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 15, '2021-12-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 16, '2022-01-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 17, '2022-02-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 18, '2022-03-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 19, '2022-04-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 20, '2022-05-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 21, '2022-06-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 22, '2022-07-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 23, '2022-08-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(79, 24, '2022-09-24', '2022-09-14', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(80, 1, '2020-10-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 2, '2020-11-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 3, '2020-12-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 4, '2021-01-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 5, '2021-02-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 6, '2021-03-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 7, '2021-04-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 8, '2021-05-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 9, '2021-06-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 10, '2021-07-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 11, '2021-08-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 12, '2021-09-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 13, '2021-10-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 14, '2021-11-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 15, '2021-12-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 16, '2022-01-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 17, '2022-02-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 18, '2022-03-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 19, '2022-04-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 20, '2022-05-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 21, '2022-06-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 22, '2022-07-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 23, '2022-08-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(80, 24, '2022-09-24', '2022-09-17', 18500000.00, 45.60, 20000.00, 0.00, 770833.33, 351500.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1122333.33),
(81, 1, '2020-10-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 2, '2020-11-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 3, '2020-12-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 4, '2021-01-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 5, '2021-02-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 6, '2021-03-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 7, '2021-04-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 8, '2021-05-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 9, '2021-06-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 10, '2021-07-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 11, '2021-08-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(81, 12, '2021-09-24', '2021-09-16', 6000000.00, 20.40, 20000.00, 0.00, 500000.00, 102000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 602000.00),
(82, 1, '2020-10-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 2, '2020-11-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 3, '2020-12-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 4, '2021-01-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 5, '2021-02-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 6, '2021-03-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 7, '2021-04-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 8, '2021-05-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 9, '2021-06-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 10, '2021-07-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 11, '2021-08-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 12, '2021-09-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 13, '2021-10-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 14, '2021-11-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 15, '2021-12-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 16, '2022-01-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 17, '2022-02-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 18, '2022-03-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 19, '2022-04-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 20, '2022-05-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 21, '2022-06-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 22, '2022-07-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 23, '2022-08-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(82, 24, '2022-09-24', '2022-09-09', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(83, 1, '2020-10-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 2, '2020-11-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 3, '2020-12-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 4, '2021-01-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 5, '2021-02-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 6, '2021-03-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 7, '2021-04-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 8, '2021-05-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 9, '2021-06-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 10, '2021-07-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 11, '2021-08-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 12, '2021-09-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 13, '2021-10-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 14, '2021-11-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 15, '2021-12-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 16, '2022-01-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 17, '2022-02-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 18, '2022-03-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 19, '2022-04-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 20, '2022-05-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 21, '2022-06-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 22, '2022-07-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 23, '2022-08-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(83, 24, '2022-09-24', '2022-09-21', 16000000.00, 45.60, 20000.00, 0.00, 666666.67, 304000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 970666.67),
(84, 1, '2020-10-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 2, '2020-11-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 3, '2020-12-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 4, '2021-01-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 5, '2021-02-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 6, '2021-03-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 7, '2021-04-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 8, '2021-05-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 9, '2021-06-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 10, '2021-07-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 11, '2021-08-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 12, '2021-09-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 13, '2021-10-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 14, '2021-11-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 15, '2021-12-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 16, '2022-01-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 17, '2022-02-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 18, '2022-03-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 19, '2022-04-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 20, '2022-05-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 21, '2022-06-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 22, '2022-07-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(84, 23, '2022-08-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33);
INSERT INTO `tbl_pinjaman_simulasi` (`tbl_pinjam_hid`, `blnke`, `periode`, `tempo`, `plafondpinjaman`, `bunga`, `biayaadm`, `sisapokokawal`, `angsuranpokok`, `angsuranbunga`, `totalangsuranbank`, `sisapokokakhir`, `adminangsuran`, `angsurandebitur`, `simpananwajib`, `jumlahangsuran`) VALUES
(84, 24, '2022-09-24', '2022-09-22', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 1, '2020-10-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 2, '2020-11-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 3, '2020-12-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 4, '2021-01-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 5, '2021-02-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 6, '2021-03-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 7, '2021-04-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 8, '2021-05-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 9, '2021-06-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 10, '2021-07-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 11, '2021-08-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 12, '2021-09-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 13, '2021-10-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 14, '2021-11-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 15, '2021-12-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 16, '2022-01-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 17, '2022-02-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 18, '2022-03-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 19, '2022-04-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 20, '2022-05-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 21, '2022-06-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 22, '2022-07-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 23, '2022-08-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(85, 24, '2022-09-24', '2022-09-17', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(86, 1, '2020-10-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 2, '2020-11-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 3, '2020-12-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 4, '2021-01-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 5, '2021-02-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 6, '2021-03-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 7, '2021-04-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 8, '2021-05-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 9, '2021-06-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 10, '2021-07-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 11, '2021-08-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 12, '2021-09-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 13, '2021-10-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 14, '2021-11-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 15, '2021-12-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 16, '2022-01-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 17, '2022-02-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 18, '2022-03-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 19, '2022-04-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 20, '2022-05-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 21, '2022-06-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 22, '2022-07-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 23, '2022-08-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(86, 24, '2022-09-24', '2022-09-18', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(87, 1, '2020-10-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 2, '2020-11-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 3, '2020-12-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 4, '2021-01-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 5, '2021-02-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 6, '2021-03-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 7, '2021-04-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 8, '2021-05-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 9, '2021-06-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 10, '2021-07-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 11, '2021-08-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 12, '2021-09-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 13, '2021-10-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 14, '2021-11-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 15, '2021-12-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 16, '2022-01-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 17, '2022-02-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 18, '2022-03-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 19, '2022-04-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 20, '2022-05-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 21, '2022-06-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 22, '2022-07-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 23, '2022-08-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(87, 24, '2022-09-24', '2022-09-23', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(88, 1, '2020-10-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 2, '2020-11-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 3, '2020-12-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 4, '2021-01-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 5, '2021-02-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 6, '2021-03-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 7, '2021-04-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 8, '2021-05-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 9, '2021-06-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 10, '2021-07-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 11, '2021-08-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 12, '2021-09-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 13, '2021-10-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 14, '2021-11-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 15, '2021-12-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 16, '2022-01-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 17, '2022-02-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 18, '2022-03-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 19, '2022-04-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 20, '2022-05-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 21, '2022-06-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 22, '2022-07-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 23, '2022-08-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(88, 24, '2022-09-24', '2022-09-25', 10000000.00, 45.60, 20000.00, 0.00, 416666.67, 190000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 606666.67),
(89, 1, '2020-11-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 2, '2020-12-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 3, '2021-01-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 4, '2021-02-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 5, '2021-03-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 6, '2021-04-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 7, '2021-05-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 8, '2021-06-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 9, '2021-07-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 10, '2021-08-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 11, '2021-09-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 12, '2021-10-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 13, '2021-11-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 14, '2021-12-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 15, '2022-01-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 16, '2022-02-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 17, '2022-03-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 18, '2022-04-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 19, '2022-05-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 20, '2022-06-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 21, '2022-07-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 22, '2022-08-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 23, '2022-09-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(89, 24, '2022-10-24', '2022-10-02', 18000000.00, 45.60, 20000.00, 0.00, 750000.00, 342000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1092000.00),
(90, 1, '2020-11-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 2, '2020-12-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 3, '2021-01-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 4, '2021-02-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 5, '2021-03-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 6, '2021-04-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 7, '2021-05-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 8, '2021-06-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 9, '2021-07-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 10, '2021-08-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 11, '2021-09-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(90, 12, '2021-10-24', '2021-10-05', 15000000.00, 20.40, 20000.00, 0.00, 1250000.00, 255000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1505000.00),
(91, 1, '2020-11-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 2, '2020-12-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 3, '2021-01-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 4, '2021-02-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 5, '2021-03-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 6, '2021-04-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 7, '2021-05-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 8, '2021-06-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 9, '2021-07-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 10, '2021-08-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 11, '2021-09-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 12, '2021-10-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 13, '2021-11-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 14, '2021-12-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 15, '2022-01-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 16, '2022-02-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 17, '2022-03-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 18, '2022-04-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 19, '2022-05-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 20, '2022-06-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 21, '2022-07-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 22, '2022-08-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 23, '2022-09-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(91, 24, '2022-10-24', '2022-10-08', 13000000.00, 45.60, 20000.00, 0.00, 541666.67, 247000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 788666.67),
(92, 1, '2020-11-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 2, '2020-12-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 3, '2021-01-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 4, '2021-02-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 5, '2021-03-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 6, '2021-04-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 7, '2021-05-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 8, '2021-06-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 9, '2021-07-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 10, '2021-08-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 11, '2021-09-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 12, '2021-10-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 13, '2021-11-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 14, '2021-12-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 15, '2022-01-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 16, '2022-02-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 17, '2022-03-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 18, '2022-04-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 19, '2022-05-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 20, '2022-06-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 21, '2022-07-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 22, '2022-08-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 23, '2022-09-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(92, 24, '2022-10-24', '2022-10-13', 17800000.00, 45.60, 20000.00, 0.00, 741666.67, 338200.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1079866.67),
(94, 1, '2020-11-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 2, '2020-12-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 3, '2021-01-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 4, '2021-02-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 5, '2021-03-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 6, '2021-04-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 7, '2021-05-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 8, '2021-06-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 9, '2021-07-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 10, '2021-08-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 11, '2021-09-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 12, '2021-10-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 13, '2021-11-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 14, '2021-12-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 15, '2022-01-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 16, '2022-02-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 17, '2022-03-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 18, '2022-04-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 19, '2022-05-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 20, '2022-06-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 21, '2022-07-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 22, '2022-08-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 23, '2022-09-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(94, 24, '2022-10-24', '2022-10-12', 15000000.00, 45.60, 20000.00, 0.00, 625000.00, 285000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 910000.00),
(95, 1, '2020-11-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 2, '2020-12-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 3, '2021-01-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 4, '2021-02-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 5, '2021-03-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 6, '2021-04-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 7, '2021-05-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 8, '2021-06-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 9, '2021-07-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 10, '2021-08-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 11, '2021-09-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 12, '2021-10-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 13, '2021-11-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 14, '2021-12-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 15, '2022-01-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 16, '2022-02-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 17, '2022-03-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 18, '2022-04-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 19, '2022-05-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 20, '2022-06-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 21, '2022-07-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 22, '2022-08-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 23, '2022-09-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(95, 24, '2022-10-24', '2022-10-13', 20000000.00, 45.60, 20000.00, 0.00, 833333.33, 380000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1213333.33),
(96, 1, '2020-11-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 2, '2020-12-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 3, '2021-01-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 4, '2021-02-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 5, '2021-03-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 6, '2021-04-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 7, '2021-05-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 8, '2021-06-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 9, '2021-07-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 10, '2021-08-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 11, '2021-09-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67),
(96, 12, '2021-10-24', '2021-10-20', 20000000.00, 20.40, 20000.00, 0.00, 1666666.67, 340000.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2006666.67);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_setting`
--

CREATE TABLE `tbl_setting` (
  `id` bigint(20) NOT NULL,
  `opsi_key` varchar(255) NOT NULL,
  `opsi_val` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_setting`
--

INSERT INTO `tbl_setting` (`id`, `opsi_key`, `opsi_val`) VALUES
(1, 'nama_lembaga', 'KOPERASI KSU GILANG GEMILANG'),
(2, 'nama_ketua', 'SUTRISNO'),
(3, 'hp_ketua', ''),
(4, 'alamat', 'Jl Margasatwa No. 99 Pondok Labu, Cilandak, Kota Jakarta Selatan'),
(5, 'telepon', '(021) 27829693'),
(6, 'kota', 'Jakarta Selatan'),
(7, 'email', 'gilanggemilang.keuangan@gmail.com'),
(8, 'web', ''),
(9, 'no_badan_hukum', 'No.614/BH/MENEG.I-/VI/2007');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_transaksi_toko`
--

CREATE TABLE `tbl_transaksi_toko` (
  `id` int(20) NOT NULL,
  `tgl` datetime NOT NULL,
  `anggota_id` int(11) DEFAULT NULL,
  `id_barang` int(20) NOT NULL,
  `harga` varchar(30) CHARACTER SET latin1 NOT NULL,
  `jumlah` int(5) NOT NULL,
  `keterangan` tinytext CHARACTER SET latin1 NOT NULL,
  `tipe` enum('masuk','keluar') CHARACTER SET latin1 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_trans_dp`
--

CREATE TABLE `tbl_trans_dp` (
  `id` mediumint(9) NOT NULL,
  `tgl_transaksi` datetime NOT NULL,
  `anggota_id` int(11) NOT NULL DEFAULT 0,
  `anggota_nama` varchar(50) NOT NULL,
  `jenis_id` int(5) NOT NULL,
  `tenor` int(4) NOT NULL,
  `jumlah` double NOT NULL,
  `bunga` varchar(5) NOT NULL,
  `keterangan` varchar(255) NOT NULL,
  `lunas` enum('Belum','Lunas','-') DEFAULT NULL,
  `akun` enum('Setoran','Penarikan') NOT NULL,
  `dk` enum('D','K') NOT NULL,
  `kas_id` int(11) NOT NULL DEFAULT 0,
  `update_data` datetime NOT NULL,
  `user_name` varchar(255) NOT NULL,
  `nama_penyetor` varchar(255) NOT NULL,
  `no_identitas` varchar(20) NOT NULL,
  `alamat` varchar(255) NOT NULL,
  `buat_ulang` enum('Y','N') DEFAULT NULL,
  `is_approve` char(1) DEFAULT NULL,
  `approve_by` varchar(100) DEFAULT NULL,
  `approve_date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_trans_dp_d`
--

CREATE TABLE `tbl_trans_dp_d` (
  `id` int(11) NOT NULL DEFAULT 0,
  `tgl_bayar` datetime DEFAULT NULL,
  `deposito_id` int(11) DEFAULT NULL,
  `angsuran_ke` int(11) DEFAULT NULL,
  `jumlah_bayar` decimal(30,2) DEFAULT 0.00,
  `keterangan` varchar(50) CHARACTER SET latin1 DEFAULT NULL,
  `username` varchar(50) CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_trans_kas`
--

CREATE TABLE `tbl_trans_kas` (
  `id` int(11) NOT NULL DEFAULT 0,
  `tgl_catat` datetime NOT NULL,
  `jumlah` double NOT NULL,
  `keterangan` varchar(255) NOT NULL,
  `akun` enum('Pemasukan','Pengeluaran','Transfer') NOT NULL,
  `dari_kas_id` int(11) DEFAULT NULL,
  `untuk_kas_id` int(11) DEFAULT NULL,
  `jns_trans` int(11) DEFAULT NULL,
  `dk` enum('D','K') DEFAULT NULL,
  `update_data` datetime NOT NULL,
  `user_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_trans_sp`
--

CREATE TABLE `tbl_trans_sp` (
  `id` int(11) NOT NULL,
  `tgl_transaksi` datetime NOT NULL,
  `anggota_id` int(11) NOT NULL DEFAULT 0,
  `anggota_nama` varchar(50) NOT NULL,
  `jenis_id` int(5) NOT NULL,
  `tenor` int(4) DEFAULT NULL,
  `jumlah` double NOT NULL,
  `bunga` varchar(5) NOT NULL,
  `keterangan` varchar(255) DEFAULT NULL,
  `lunas` enum('Belum','Lunas','-') DEFAULT NULL,
  `akun` enum('Setoran','Penarikan') NOT NULL,
  `dk` enum('D','K') NOT NULL,
  `kas_id` int(11) NOT NULL DEFAULT 0,
  `update_data` datetime DEFAULT NULL,
  `user_name` varchar(255) NOT NULL,
  `nama_penyetor` varchar(255) DEFAULT NULL,
  `no_identitas` varchar(20) DEFAULT NULL,
  `alamat` varchar(255) DEFAULT NULL,
  `buat_ulang` enum('Y','N') DEFAULT NULL,
  `is_approve` char(1) DEFAULT NULL,
  `approve_by` varchar(100) DEFAULT NULL,
  `approve_date` datetime DEFAULT NULL,
  `jns_cabangid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_trans_sp`
--

INSERT INTO `tbl_trans_sp` (`id`, `tgl_transaksi`, `anggota_id`, `anggota_nama`, `jenis_id`, `tenor`, `jumlah`, `bunga`, `keterangan`, `lunas`, `akun`, `dk`, `kas_id`, `update_data`, `user_name`, `nama_penyetor`, `no_identitas`, `alamat`, `buat_ulang`, `is_approve`, `approve_by`, `approve_date`, `jns_cabangid`) VALUES
(1, '2020-06-10 16:13:00', 4, 'ABD. ROHMAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(2, '2020-08-19 16:13:00', 4, 'ABD. ROHMAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(3, '2020-09-23 16:13:00', 4, 'ABD. ROHMAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(4, '2020-06-11 16:13:00', 8, 'ABDUL FATAH BOEDIONO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(5, '2020-08-19 16:13:00', 8, 'ABDUL FATAH BOEDIONO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(6, '2020-09-23 16:13:00', 8, 'ABDUL FATAH BOEDIONO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(7, '2020-08-25 16:13:00', 64, 'ABDUL KAHAR HAS', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(8, '2020-08-07 16:13:00', 55, 'Achmad Latif', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(9, '2020-09-17 16:13:00', 78, 'ALI SUIR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(10, '2020-07-09 16:13:00', 34, 'ANDI SUTRISNO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(11, '2020-09-23 16:13:00', 34, 'ANDI SUTRISNO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(12, '2020-07-08 16:13:00', 32, 'ANISAH NASUTION', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(13, '2020-09-23 16:13:00', 32, 'ANISAH NASUTION', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(14, '2020-07-16 16:13:00', 44, 'Aslichah', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(15, '2020-09-23 16:13:00', 44, 'Aslichah', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(16, '2020-09-17 16:13:00', 80, 'ASMARA', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(17, '2020-08-31 16:13:00', 72, 'ATMANAH', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(18, '2020-08-06 16:13:00', 54, 'ATMANI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(19, '2020-08-26 16:13:00', 66, 'BACHRUM', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(20, '2020-07-13 16:13:00', 38, 'Burhani', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(21, '2020-09-23 16:13:00', 38, 'Burhani', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(22, '2020-08-27 16:13:00', 68, 'CHOTTOB', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(23, '2020-06-10 16:13:00', 5, 'DARIYAM', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(24, '2020-08-19 16:13:00', 5, 'DARIYAM', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(25, '2020-09-23 16:13:00', 5, 'DARIYAM', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(26, '2020-07-20 16:13:00', 47, 'DAUD SUBADRI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(27, '2020-09-23 16:13:00', 47, 'DAUD SUBADRI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(28, '2020-06-25 16:13:00', 23, 'DJAIT', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(29, '2020-08-19 16:13:00', 23, 'DJAIT', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(30, '2020-09-23 16:13:00', 23, 'DJAIT', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(31, '2020-09-14 16:13:00', 76, 'DJUNAENI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(32, '2020-07-10 16:13:00', 37, 'DRG RUSFENDI GARNIWA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(33, '2020-09-23 16:13:00', 37, 'DRG RUSFENDI GARNIWA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(34, '2020-08-18 16:13:00', 61, 'DRS RUSDI SAYUTI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(35, '2020-06-30 16:13:00', 26, 'E MUNADJAT', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(36, '2020-09-23 16:13:00', 26, 'E MUNADJAT', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(37, '2020-09-07 16:13:00', 75, 'FATIMAH NOORMA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(38, '2020-09-23 16:13:00', 84, 'FIENTJE  ANTAMENG', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(39, '2020-07-27 16:13:00', 51, 'GAMALI', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(40, '2020-08-12 16:13:00', 59, 'H MOH BADRI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(41, '2020-07-09 16:13:00', 33, 'H RADEN BAGUS SADINO', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(42, '2020-09-03 16:13:00', 73, 'H SOEBEKTI PRAPTO BSc', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(43, '2020-06-17 16:13:00', 16, 'H SYAPAWI ACHMAD', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(44, '2020-08-19 16:13:00', 16, 'H SYAPAWI ACHMAD', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(45, '2020-09-23 16:13:00', 16, 'H SYAPAWI ACHMAD', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(46, '2020-07-03 16:13:00', 30, 'HAMDIJA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(47, '2020-09-23 16:13:00', 30, 'HAMDIJA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(48, '2020-06-22 16:13:00', 21, 'HJ JAJAH HERJATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(49, '2020-08-19 16:13:00', 21, 'HJ JAJAH HERJATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(50, '2020-09-23 16:13:00', 21, 'HJ JAJAH HERJATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(51, '2020-08-25 16:15:00', 63, 'I GDE NYOMAN MENDRA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(52, '2020-06-17 16:15:00', 14, 'ISKANDAR MAKMUR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(53, '2020-08-19 16:15:00', 14, 'ISKANDAR MAKMUR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(54, '2020-09-23 16:15:00', 14, 'ISKANDAR MAKMUR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(55, '2020-08-07 16:15:00', 56, 'ISTIANINGSIH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(56, '2020-07-23 16:15:00', 50, 'JARIAH', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(57, '2020-07-16 16:15:00', 42, 'JENNY DEETJE MANTIK WAROUW', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(58, '2020-09-23 16:15:00', 42, 'JENNY DEETJE MANTIK WAROUW', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(59, '2020-06-12 16:15:00', 10, 'M.SALIM HASAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(60, '2020-08-19 16:15:00', 10, 'M.SALIM HASAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(61, '2020-09-23 16:15:00', 10, 'M.SALIM HASAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(62, '2020-06-08 16:15:00', 1, 'MAMAN SUPRATMAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(63, '2020-08-19 16:15:00', 1, 'MAMAN SUPRATMAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(64, '2020-09-23 16:15:00', 1, 'MAMAN SUPRATMAN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(65, '2020-06-09 16:15:00', 3, 'MARDIAH', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(66, '2020-09-23 16:15:00', 3, 'MARDIAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(67, '2020-09-24 16:15:00', 85, 'MARGERETHA HEHANUSSA', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(68, '2020-07-20 16:15:00', 48, 'MASDAR', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(69, '2020-09-23 16:15:00', 83, 'MASDOEKI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(70, '2020-07-17 16:15:00', 45, 'MASRI MS', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(71, '2020-09-23 16:15:00', 45, 'MASRI MS', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(72, '2020-09-17 16:15:00', 79, 'MAWARDI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(73, '2020-09-24 16:15:00', 86, 'MOEDJIJATOEN', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(74, '2020-08-10 16:15:00', 57, 'MUDAFIR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(75, '2020-07-03 16:15:00', 29, 'MUSILAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(76, '2020-09-23 16:15:00', 29, 'MUSILAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(77, '2020-09-16 16:15:00', 77, 'NURMA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(78, '2020-06-23 16:15:00', 22, 'RUBAMA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(79, '2020-08-19 16:15:00', 22, 'RUBAMA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(80, '2020-09-23 16:15:00', 22, 'RUBAMA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(81, '2020-06-22 16:15:00', 20, 'RUKMIATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(82, '2020-08-19 16:15:00', 20, 'RUKMIATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(83, '2020-09-23 16:15:00', 20, 'RUKMIATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(84, '2020-09-28 16:15:00', 88, 'Ruminah', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(85, '2020-07-15 16:15:00', 41, 'S YUSHAR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(86, '2020-09-23 16:15:00', 41, 'S YUSHAR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(87, '2020-07-10 16:15:00', 35, 'Saeun', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(88, '2020-09-23 16:15:00', 35, 'Saeun', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(89, '2020-06-09 16:15:00', 2, 'SAIMAH', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(90, '2020-09-23 16:15:00', 2, 'SAIMAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(91, '2020-06-15 16:15:00', 11, 'SALBIAH', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(92, '2020-09-23 16:15:00', 11, 'SALBIAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(93, '2020-09-04 16:15:00', 74, 'SAMPURNI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(94, '2020-08-27 16:15:00', 70, 'SANTJE JULIANA ROBOT', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(95, '2020-07-06 16:15:00', 31, 'Sarmat', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(96, '2020-09-23 16:15:00', 31, 'Sarmat', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(97, '2020-06-16 16:15:00', 13, 'SITI AMINI', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(98, '2020-09-23 16:15:00', 13, 'SITI AMINI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(99, '2020-07-03 16:15:00', 28, 'SITI JUBAEDAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(100, '2020-09-23 16:15:00', 28, 'SITI JUBAEDAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(101, '2020-07-10 16:16:00', 36, 'Siti sutaryati', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(102, '2020-09-23 16:16:00', 36, 'Siti sutaryati', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(103, '2020-07-30 16:16:00', 53, 'SOEGIARTO', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(104, '2020-08-13 16:16:00', 60, 'SOEMARDI B SOEMOKARSO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(105, '2020-06-25 16:16:00', 24, 'Soewarno SH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(106, '2020-08-19 16:16:00', 24, 'Soewarno SH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(107, '2020-09-23 16:16:00', 24, 'Soewarno SH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(108, '2020-06-19 16:16:00', 18, 'Sri Musringah Lous', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(109, '2020-08-19 16:16:00', 18, 'Sri Musringah Lous', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(110, '2020-09-23 16:16:00', 18, 'Sri Musringah Lous', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(111, '2020-06-11 16:16:00', 7, 'ST NARI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(112, '2020-08-19 16:16:00', 7, 'ST NARI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(113, '2020-09-23 16:16:00', 7, 'ST NARI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(114, '2020-07-14 16:16:00', 40, 'SUARTI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(115, '2020-09-23 16:16:00', 40, 'SUARTI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(116, '2020-08-27 16:16:00', 69, 'SUDARMI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(117, '2020-07-13 16:16:00', 39, 'SUDJASMI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(118, '2020-09-23 16:16:00', 39, 'SUDJASMI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(119, '2020-06-25 16:16:00', 25, 'SUHADI BA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(120, '2020-08-19 16:16:00', 25, 'SUHADI BA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(121, '2020-09-23 16:16:00', 25, 'SUHADI BA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(122, '2020-09-28 16:16:00', 87, 'SUJI DG RATU', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(123, '2020-07-23 16:16:00', 49, 'SUKAR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(124, '2020-09-23 16:16:00', 49, 'SUKAR', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(125, '2020-09-18 16:16:00', 82, 'Sulaiman', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(126, '2020-06-11 16:16:00', 9, 'SUNARJA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(127, '2020-08-19 16:16:00', 9, 'SUNARJA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(128, '2020-09-23 16:16:00', 9, 'SUNARJA', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(129, '2020-08-24 16:16:00', 62, 'SUNARTI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(130, '2020-09-18 16:16:00', 81, 'SUNDIAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(131, '2020-07-16 16:16:00', 43, 'SUNTIANI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(132, '2020-09-23 16:16:00', 43, 'SUNTIANI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(133, '2020-06-19 16:16:00', 19, 'Supardi Adi Nugroho', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(134, '2020-08-19 16:16:00', 19, 'Supardi Adi Nugroho', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(135, '2020-09-23 16:16:00', 19, 'Supardi Adi Nugroho', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(136, '2020-07-17 16:16:00', 46, 'Supiyah', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(137, '2020-09-23 16:16:00', 46, 'Supiyah', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(138, '2020-06-17 16:16:00', 15, 'SUTJIPTO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(139, '2020-08-19 16:16:00', 15, 'SUTJIPTO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(140, '2020-09-23 16:16:00', 15, 'SUTJIPTO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(141, '2020-06-11 16:16:00', 6, 'SUTRISNO HP', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(142, '2020-08-19 16:16:00', 6, 'SUTRISNO HP', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(143, '2020-06-18 16:16:00', 17, 'SUWARTINAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(144, '2020-08-19 16:16:00', 17, 'SUWARTINAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(145, '2020-09-23 16:16:00', 17, 'SUWARTINAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(146, '2020-07-28 16:16:00', 52, 'SYAHRI SUWANDI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(147, '2020-09-23 16:16:00', 52, 'SYAHRI SUWANDI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(148, '2020-08-26 16:16:00', 67, 'SYAMSIAH', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(149, '2020-06-15 16:16:00', 12, 'THEETAN TJONG SOEBEKTI', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(150, '2020-09-23 16:16:00', 12, 'THEETAN TJONG SOEBEKTI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(151, '2020-08-10 16:17:00', 58, 'TRUIDA SOEDJIWO', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(152, '2020-08-26 16:17:00', 65, 'YOHANNA TAHALELE', 42, 1, 40000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(153, '2020-07-02 16:17:00', 27, 'YULIATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(154, '2020-09-23 16:17:00', 27, 'YULIATI', 42, 1, 20000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(155, '2020-06-10 16:20:00', 4, 'ABD. ROHMAN', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(156, '2020-06-11 16:20:00', 8, 'ABDUL FATAH BOEDIONO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(157, '2020-08-25 16:20:00', 64, 'ABDUL KAHAR HAS', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(158, '2020-08-07 16:20:00', 55, 'Achmad Latif', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(159, '2020-09-17 16:20:00', 78, 'ALI SUIR', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(160, '2020-07-09 16:20:00', 34, 'ANDI SUTRISNO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(161, '2020-07-08 16:20:00', 32, 'ANISAH NASUTION', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(162, '2020-07-16 16:20:00', 44, 'Aslichah', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(163, '2020-09-17 16:20:00', 80, 'ASMARA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(164, '2020-08-31 16:20:00', 72, 'ATMANAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(165, '2020-08-06 16:20:00', 54, 'ATMANI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(166, '2020-08-26 16:20:00', 66, 'BACHRUM', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(167, '2020-07-13 16:20:00', 38, 'Burhani', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(168, '2020-08-27 16:20:00', 68, 'CHOTTOB', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(169, '2020-06-10 16:20:00', 5, 'DARIYAM', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(170, '2020-07-20 16:20:00', 47, 'DAUD SUBADRI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(171, '2020-06-25 16:20:00', 23, 'DJAIT', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(172, '2020-09-14 16:20:00', 76, 'DJUNAENI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(173, '2020-07-10 16:20:00', 37, 'DRG RUSFENDI GARNIWA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(174, '2020-08-18 16:20:00', 61, 'DRS RUSDI SAYUTI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(175, '2020-06-30 16:20:00', 26, 'E MUNADJAT', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(176, '2020-09-07 16:20:00', 75, 'FATIMAH NOORMA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(177, '2020-09-23 16:20:00', 84, 'FIENTJE  ANTAMENG', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(178, '2020-07-27 16:20:00', 51, 'GAMALI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(179, '2020-08-12 16:20:00', 59, 'H MOH BADRI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(180, '2020-07-09 16:20:00', 33, 'H RADEN BAGUS SADINO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(181, '2020-09-03 16:20:00', 73, 'H SOEBEKTI PRAPTO BSc', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(182, '2020-06-17 16:20:00', 16, 'H SYAPAWI ACHMAD', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(183, '2020-07-03 16:20:00', 30, 'HAMDIJA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(184, '2020-06-22 16:20:00', 21, 'HJ JAJAH HERJATI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(185, '2020-08-25 16:20:00', 63, 'I GDE NYOMAN MENDRA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(186, '2020-06-17 16:20:00', 14, 'ISKANDAR MAKMUR', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(187, '2020-08-07 16:20:00', 56, 'ISTIANINGSIH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(188, '2020-07-23 16:20:00', 50, 'JARIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(189, '2020-07-16 16:20:00', 42, 'JENNY DEETJE MANTIK WAROUW', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(190, '2020-06-12 16:20:00', 10, 'M.SALIM HASAN', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(191, '2020-06-08 16:20:00', 1, 'MAMAN SUPRATMAN', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(192, '2020-06-09 16:20:00', 3, 'MARDIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(193, '2020-09-24 16:20:00', 85, 'MARGERETHA HEHANUSSA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(194, '2020-07-20 16:20:00', 48, 'MASDAR', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(195, '2020-09-23 16:20:00', 83, 'MASDOEKI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(196, '2020-07-17 16:20:00', 45, 'MASRI MS', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(197, '2020-09-17 16:20:00', 79, 'MAWARDI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(198, '2020-09-24 16:20:00', 86, 'MOEDJIJATOEN', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(199, '2020-08-10 16:20:00', 57, 'MUDAFIR', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(200, '2020-07-03 16:20:00', 29, 'MUSILAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(201, '2020-09-16 16:20:00', 77, 'NURMA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(202, '2020-06-23 16:20:00', 22, 'RUBAMA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(203, '2020-06-22 16:20:00', 20, 'RUKMIATI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(204, '2020-09-28 16:20:00', 88, 'Ruminah', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(205, '2020-07-15 16:20:00', 41, 'S YUSHAR', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(206, '2020-07-10 16:20:00', 35, 'Saeun', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(207, '2020-06-09 16:20:00', 2, 'SAIMAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(208, '2020-06-15 16:20:00', 11, 'SALBIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(209, '2020-09-04 16:20:00', 74, 'SAMPURNI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(210, '2020-08-27 16:20:00', 70, 'SANTJE JULIANA ROBOT', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(211, '2020-07-06 16:20:00', 31, 'Sarmat', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(212, '2020-06-16 16:20:00', 13, 'SITI AMINI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(213, '2020-07-03 16:20:00', 28, 'SITI JUBAEDAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(214, '2020-07-10 16:20:00', 36, 'Siti sutaryati', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(215, '2020-07-30 16:20:00', 53, 'SOEGIARTO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(216, '2020-08-13 16:20:00', 60, 'SOEMARDI B SOEMOKARSO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(217, '2020-06-25 16:20:00', 24, 'Soewarno SH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(218, '2020-06-19 16:20:00', 18, 'Sri Musringah Lous', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(219, '2020-06-11 16:20:00', 7, 'ST NARI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(220, '2020-07-14 16:20:00', 40, 'SUARTI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(221, '2020-08-27 16:20:00', 69, 'SUDARMI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(222, '2020-07-13 16:20:00', 39, 'SUDJASMI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(223, '2020-06-25 16:20:00', 25, 'SUHADI BA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(224, '2020-09-28 16:20:00', 87, 'SUJI DG RATU', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(225, '2020-07-23 16:20:00', 49, 'SUKAR', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(226, '2020-09-18 16:20:00', 82, 'Sulaiman', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(227, '2020-06-11 16:20:00', 9, 'SUNARJA', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(228, '2020-08-24 16:20:00', 62, 'SUNARTI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(229, '2020-09-18 16:20:00', 81, 'SUNDIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(230, '2020-08-28 16:20:00', 43, 'SUNTIANI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(231, '2020-06-19 16:20:00', 19, 'Supardi Adi Nugroho', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(232, '2020-07-17 16:20:00', 46, 'Supiyah', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(233, '2020-06-17 16:20:00', 15, 'SUTJIPTO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(234, '2020-06-11 16:20:00', 6, 'SUTRISNO HP', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(235, '2020-06-18 16:20:00', 17, 'SUWARTINAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(236, '2020-07-28 16:20:00', 52, 'SYAHRI SUWANDI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(237, '2020-08-26 16:20:00', 67, 'SYAMSIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(238, '2020-06-15 16:20:00', 12, 'THEETAN TJONG SOEBEKTI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(239, '2020-08-10 16:20:00', 58, 'TRUIDA SOEDJIWO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(240, '2020-08-26 16:20:00', 65, 'YOHANNA TAHALELE', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(241, '2020-07-02 16:20:00', 27, 'YULIATI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, 'X', 'admin', '2020-10-16 04:12:20', NULL),
(242, '2020-10-22 10:00:00', 89, 'ANGGI ANDRIANSYAH', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(243, '2020-10-22 10:00:00', 89, 'ANGGI ANDRIANSYAH', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(244, '2020-10-22 10:00:00', 89, 'ANGGI ANDRIANSYAH', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(245, '2020-10-22 10:10:00', 90, 'ASRIAL CHANIAGO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ASRIAL CHANIAGO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(246, '2020-10-22 10:11:00', 90, 'ASRIAL CHANIAGO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ASRIAL CHANIAGO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(247, '2020-10-22 10:11:00', 90, 'ASRIAL CHANIAGO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ASRIAL CHANIAGO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(248, '2020-10-22 10:15:00', 93, 'BAMBANG TRIONO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BAMBANG TRIONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(249, '2020-10-22 10:15:00', 93, 'BAMBANG TRIONO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BAMBANG TRIONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(250, '2020-10-22 10:15:00', 93, 'BAMBANG TRIONO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BAMBANG TRIONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(251, '2020-10-22 10:21:00', 94, 'BENFITRADI', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BENFITRIADI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(252, '2020-10-22 10:21:00', 94, 'BENFITRADI', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BENFITRIADI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(253, '2020-10-22 10:21:00', 94, 'BENFITRADI', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BENFITRIADI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(254, '2020-10-22 10:27:00', 95, 'EDY PRAMANA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'EDY PRAMANA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(255, '2020-10-22 10:27:00', 95, 'EDY PRAMANA', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'EDY PRAMANA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(256, '2020-10-22 10:27:00', 95, 'EDY PRAMANA', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'EDY PRAMANA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(257, '2020-10-22 10:32:00', 96, 'FATHURROHIM', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'FATHURROHIM', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(258, '2020-10-22 10:32:00', 96, 'FATHURROHIM', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'FATHURROHIM', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(259, '2020-10-22 10:32:00', 96, 'FATHURROHIM', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'FATHURROHIM', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56);
INSERT INTO `tbl_trans_sp` (`id`, `tgl_transaksi`, `anggota_id`, `anggota_nama`, `jenis_id`, `tenor`, `jumlah`, `bunga`, `keterangan`, `lunas`, `akun`, `dk`, `kas_id`, `update_data`, `user_name`, `nama_penyetor`, `no_identitas`, `alamat`, `buat_ulang`, `is_approve`, `approve_by`, `approve_date`, `jns_cabangid`) VALUES
(260, '2020-10-22 10:37:00', 97, 'HARI HARMONO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARI HARMONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(261, '2020-10-22 10:37:00', 97, 'HARI HARMONO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARI HARMONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(262, '2020-10-22 10:37:00', 97, 'HARI HARMONO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARI HARMONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(263, '2020-10-22 10:40:00', 98, 'HARYO AGUNG SUDARSONO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARYO AGUNG SUDARSONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(264, '2020-10-22 10:40:00', 98, 'HARYO AGUNG SUDARSONO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARYO AGUNG SUDARSONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(265, '2020-10-22 10:40:00', 98, 'HARYO AGUNG SUDARSONO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARYO AGUNG SUDARSONO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(266, '2020-10-22 10:48:00', 99, 'HASANUDDIN TARUG', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HASANUDDIN TARUG', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(267, '2020-10-22 10:48:00', 99, 'HASANUDDIN TARUG', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HASANUDDIN TARUG', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(268, '2020-10-22 10:48:00', 99, 'HASANUDDIN TARUG', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HASANUDDIN TARUG', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(269, '2020-10-22 11:00:00', 100, 'HENDRA SIDHARTA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HENDRA SIDHARTA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(271, '2020-10-22 11:02:00', 100, 'HENDRA SIDHARTA', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HENDRA SIDHARTA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(272, '2020-10-22 11:02:00', 100, 'HENDRA SIDHARTA', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HENDRA SIDHARTA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(273, '2020-10-22 11:06:00', 101, 'MUKDAN LUBIS', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MUKDAN LUBIS', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(274, '2020-10-22 11:06:00', 101, 'MUKDAN LUBIS', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MUKDAN LUBIS', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(275, '2020-10-22 11:06:00', 101, 'MUKDAN LUBIS', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MUKDAN LUBIS', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(276, '2020-10-22 11:09:00', 102, 'HANNY RACHMALIA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HANNY RACHMALIA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(277, '2020-10-22 11:09:00', 102, 'HANNY RACHMALIA', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HANNY RACHMALIA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(278, '2020-10-22 11:09:00', 102, 'HANNY RACHMALIA', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HANNY RACHMALIA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(279, '2020-10-22 11:13:00', 103, 'JONY NUR EFFENDY', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'JONY NUR EFFENDY', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(280, '2020-10-22 11:13:00', 103, 'JONY NUR EFFENDY', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'JONY NUR EFFENDY', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(281, '2020-10-22 11:13:00', 103, 'JONY NUR EFFENDY', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'JONY NUR EFFENDY', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(282, '2020-10-22 11:16:00', 104, 'KADMINA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'KADMINA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(283, '2020-10-22 11:16:00', 104, 'KADMINA', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'KADMINA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(284, '2020-10-22 11:16:00', 104, 'KADMINA', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'KADMINA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(285, '2020-10-22 11:21:00', 105, 'IR KAREL PALALLO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'KAREL PALALO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(286, '2020-10-22 11:21:00', 105, 'IR KAREL PALALLO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'KAREL PALALLO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(287, '2020-10-22 11:21:00', 105, 'IR KAREL PALALLO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'KAREL PALALLO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(288, '2020-10-22 11:25:00', 106, 'MANUDIN HASAN', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MANUDIN HASAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(289, '2020-10-22 11:25:00', 106, 'MANUDIN HASAN', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MANUDIN HASAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(290, '2020-10-22 11:25:00', 106, 'MANUDIN HASAN', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MANUDIN HASAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(291, '2020-10-22 11:28:00', 107, 'MOCH AZIZ YUSUP', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MOCH AZIZ YUSUP', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(292, '2020-10-22 11:28:00', 107, 'MOCH AZIZ YUSUP', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MOCH AZIZ YUSUP', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(294, '2020-10-22 11:31:00', 0, '', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MUHAMMAD FAISAL', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(295, '2020-10-22 11:32:00', 0, '', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MUHAMMAD FAISAL', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(296, '2020-10-22 11:32:00', 0, '', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MUHAMMAD FAISAL', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(297, '2020-10-22 11:36:00', 108, 'MULYANA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MULYANA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(298, '2020-10-22 11:36:00', 108, 'MULYANA', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MULYANA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(299, '2020-10-22 11:36:00', 108, 'MULYANA', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MULYANA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(300, '2020-10-22 11:39:00', 109, 'RACHMURSITO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'RACHMURSITO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(301, '2020-10-22 11:39:00', 109, 'RACHMURSITO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'RACHMURSITO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(302, '2020-10-22 11:39:00', 109, 'RACHMURSITO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'RACHMURSITO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(303, '2020-10-22 11:39:00', 107, 'MOCH AZIZ YUSUP', 40, 1, 4800000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MOCH AZIZ YUSUP', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(304, '2020-10-22 11:45:00', 110, 'RUDY SOESATYO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'RUDY SOESATYO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(305, '2020-10-22 11:45:00', 110, 'RUDY SOESATYO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'RUDY SOESATYO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(306, '2020-10-22 11:45:00', 110, 'RUDY SOESATYO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'RUDY SOESATYO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(307, '2020-10-22 11:48:00', 111, 'SUFLAN RIZAL', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SUFLAN RIZAL', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(308, '2020-10-22 11:48:00', 111, 'SUFLAN RIZAL', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SUFLAN RIZAL', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(309, '2020-10-22 11:48:00', 111, 'SUFLAN RIZAL', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SUFLAN RIZAL', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(310, '2020-10-22 11:51:00', 112, 'SUTRISNO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SUTRISNO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(311, '2020-10-22 11:51:00', 112, 'SUTRISNO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SUTRISNO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(312, '2020-10-22 11:51:00', 112, 'SUTRISNO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SUTRISNO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(313, '2020-10-22 11:54:00', 113, 'ZENIANTO WIBOWO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ZENIANTO WIBOWO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(314, '2020-10-22 11:54:00', 113, 'ZENIANTO WIBOWO', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ZENIANTO WIBOWO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(315, '2020-10-22 11:54:00', 113, 'ZENIANTO WIBOWO', 32, 1, 7693049, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ZENIANTO WIBOWO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(316, '2020-10-22 12:08:00', 114, 'DEDY ERADIAS', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'DEDY ERADIAS', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(317, '2020-10-22 12:08:00', 114, 'DEDY ERADIAS', 40, 1, 4800000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'DEDY ERADIAS', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(318, '2020-10-22 12:12:00', 115, 'MARWAN', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MARWAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(319, '2020-10-22 12:12:00', 115, 'MARWAN', 40, 1, 4800000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MARWAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(320, '2020-10-22 12:15:00', 116, 'TENGKU HARRY CAHYADI', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'TENGKU HARRY CAHYADI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(321, '2020-10-22 12:15:00', 116, 'TENGKU HARRY CAHYADI', 40, 1, 4800000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'TENGKU HARRY CAHYADI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(322, '2020-10-22 12:19:00', 117, 'YUFITA DEVIANI', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'YUFITA DEVIANI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(323, '2020-10-22 12:19:00', 0, '', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'YUVITA DEVIANI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(324, '2020-10-22 12:23:00', 118, 'HIMAWAN BUDI SANTOSO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HIMAWAN BUDI SANTOSO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(325, '2020-10-22 12:23:00', 118, 'HIMAWAN BUDI SANTOSO', 40, 1, 3100000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HIMAWAN BUDI SANTOSO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(326, '2020-10-22 12:23:00', 0, '', 40, 1, 5300000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'YUVITA DEVIANI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(327, '2020-10-22 12:31:00', 119, 'MARTHA IRAWAN PUTRA UTAMA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MARTHA RIAWAN PUTRA UTAMA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(328, '2020-10-22 12:31:00', 119, 'MARTHA IRAWAN PUTRA UTAMA', 40, 1, 3100000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'MARTHA RIAWAN PUTRA UTAMA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(329, '2020-10-22 12:34:00', 120, 'SADARUDDIN', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SADARUDDIN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(330, '2020-10-22 12:34:00', 120, 'SADARUDDIN', 40, 1, 3100000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'SADARUDDIN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(331, '2020-10-22 12:36:00', 121, 'JEFRI MARLON', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'JEFRI MARLON', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(332, '2020-10-22 12:36:00', 121, 'JEFRI MARLON', 40, 1, 1250000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'JEFRI MARLON', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(333, '2020-10-22 12:40:00', 122, 'ARIF GUSTAMAN', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ARIF GUSTAMAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(334, '2020-10-22 12:40:00', 122, 'ARIF GUSTAMAN', 40, 1, 1200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ARIF GUSTAMAN', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(335, '2020-10-22 12:42:00', 123, 'HARI SANTOSO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARI SANTOSO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(336, '2020-10-22 12:42:00', 123, 'HARI SANTOSO', 40, 1, 1200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HARI SANTOSO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(337, '2020-10-22 12:44:00', 124, 'HIDAYATULLAH', 40, 1, 1200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HIDAYATULLAH', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(338, '2020-10-22 12:44:00', 124, 'HIDAYATULLAH', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'HIDAYATULLAH', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(339, '2020-10-22 12:47:00', 0, 'ANGGI ANDRIANSYAH', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'AGNI IRSYAD', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(340, '2020-10-22 12:47:00', 0, '', 40, 1, 1200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'AGNI IRSYAD', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(341, '2020-10-22 12:51:00', 125, 'BAMBANG WIDYATMOKO', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BAMBANG WIDYATMOKO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(342, '2020-10-22 12:51:00', 125, 'BAMBANG WIDYATMOKO', 40, 1, 1200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'BAMBANG WIDYATMOKO', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(343, '2020-10-22 12:54:00', 126, 'ENDANG SETYAWIDI', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ENDANG SETYAWIDI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(344, '2020-10-22 12:54:00', 126, 'ENDANG SETYAWIDI', 40, 1, 1200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ENDANG SETYAWIDI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(345, '2020-10-22 12:54:00', 126, 'ENDANG SETYAWIDI', 32, 1, 10000000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'ENDANG SETYAWIDI', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(346, '2020-10-22 12:57:00', 127, 'NURUL HUSNA', 41, 1, 2500000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'NURUL HUSNA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(347, '2020-10-22 12:57:00', 127, 'NURUL HUSNA', 40, 1, 1700000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', 'NURUL HUSNA', '', '', 'Y', NULL, NULL, '0000-00-00 00:00:00', 56),
(348, '2020-10-06 11:01:00', 128, 'JUARIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(349, '2020-10-07 11:01:00', 129, 'FX MARJONO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(350, '2020-10-12 11:01:00', 130, 'IDA SAMIAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(351, '2020-10-14 11:01:00', 131, 'M.BR.NAPITUPULU', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(352, '2020-10-16 11:01:00', 132, 'SUBIYANTI', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(353, '2020-10-16 11:01:00', 133, 'MARDIJAH', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(354, '2020-10-16 11:01:00', 134, 'M FADAL', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL),
(355, '2020-10-21 11:01:00', 135, 'MISIRAN MISWANTO', 43, 1, 200000, '0', '', 'Belum', 'Setoran', 'D', 1, '0000-00-00 00:00:00', 'admin', '', '', '', NULL, NULL, NULL, '0000-00-00 00:00:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_trans_sp_d`
--

CREATE TABLE `tbl_trans_sp_d` (
  `id` int(11) NOT NULL DEFAULT 0,
  `tgl_bayar` datetime DEFAULT NULL,
  `simpan_id` int(11) DEFAULT NULL,
  `angsuran_ke` int(11) DEFAULT NULL,
  `jumlah_bayar` int(11) DEFAULT NULL,
  `keterangan` varchar(50) CHARACTER SET latin1 DEFAULT NULL,
  `username` varchar(50) CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_trans_sp_d`
--

INSERT INTO `tbl_trans_sp_d` (`id`, `tgl_bayar`, `simpan_id`, `angsuran_ke`, `jumlah_bayar`, `keterangan`, `username`) VALUES
(0, '2020-08-19 15:36:00', 69, 1, 2, '', 'admin');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_user`
--

CREATE TABLE `tbl_user` (
  `id` int(11) NOT NULL DEFAULT 0,
  `u_name` varchar(255) NOT NULL,
  `real_name` varchar(50) NOT NULL,
  `pass_word` varchar(255) NOT NULL,
  `aktif` enum('Y','N') NOT NULL,
  `level` enum('Admin','Operator','Appraiser','Manajer','Pengurus') NOT NULL,
  `jns_cabangid` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `tbl_user`
--

INSERT INTO `tbl_user` (`id`, `u_name`, `real_name`, `pass_word`, `aktif`, `level`, `jns_cabangid`) VALUES
(0, 'probo', 'probo', '7ba8e289ad2ca8f04bfc430f12ee4283fad51dda', 'Y', 'Manajer', NULL),
(1, 'admin', 'Administrator', '224bec3dd08832bc6a69873f15a50df406045f40', 'Y', 'Admin', NULL),
(2, 'ninda.dwi', 'Ninda Dwi Ariani', '1e157dd5081c6699192c94068932336f5c00ebf5', 'Y', 'Operator', NULL),
(3, 'bambang.triono', 'Bambang Triono', '224bec3dd08832bc6a69873f15a50df406045f40', 'Y', 'Manajer', NULL),
(4, 'diana.lestari', 'Diana Lestari', '1e157dd5081c6699192c94068932336f5c00ebf5', 'Y', 'Admin', NULL),
(5, 'sutrisno.s', 'Sutrisno', '1e157dd5081c6699192c94068932336f5c00ebf5', 'Y', 'Pengurus', NULL),
(6, 'anggi.andriansyah', 'Anggi Andriansyah', '1e157dd5081c6699192c94068932336f5c00ebf5', 'Y', 'Pengurus', NULL),
(7, 'jony.nur', 'Jony Nur Effendy', '1e157dd5081c6699192c94068932336f5c00ebf5', 'Y', 'Pengurus', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_hitung_pinjaman`
-- (See below for the actual view)
--
CREATE TABLE `v_hitung_pinjaman` (
`nama` varchar(255)
,`ktp` varchar(255)
,`rekening` varchar(100)
,`jenis_pinjam` int(2)
,`id` int(11)
,`validasi_status` char(1)
,`jns_cabangid` int(11)
,`simpanan_wajib` int(11)
,`simpanan_wajib_akun` int(11)
,`pencairan_bersih_akun` int(11)
,`bunga_bulan_dua` int(11)
,`bunga_bulan_dua_akun` int(11)
,`pokok_bulan_dua` int(11)
,`pokok_bulan_dua_akun` int(11)
,`pencairan_bersih` int(11)
,`bunga_bulan_satu_akun` int(11)
,`bunga_bulan_satu` int(11)
,`pokok_bulan_satu_akun` int(11)
,`pokok_bulan_satu` int(11)
,`simpanan_pokok_akun` int(11)
,`simpanan_pokok` int(11)
,`biaya_materai_akun` int(11)
,`biaya_materai` int(11)
,`biaya_administrasi_akun` int(11)
,`biaya_administrasi` decimal(30,2)
,`biaya_asuransi_akun` int(11)
,`biaya_asuransi` int(11)
,`nama_vendor` varchar(150)
,`nomor_pensiunan` varchar(100)
,`nomor_rekening` varchar(100)
,`no_perjanjian_kredit` varchar(50)
,`angsuran_per_bulan` int(11)
,`plafond_pinjaman_akun` int(11)
,`plafond_pinjaman` int(11)
,`jenis_pinjaman` int(2)
,`nomor_pinjaman` varchar(50)
,`tgl_pinjam` datetime
,`anggota_id` int(11)
,`lama_angsuran` int(11)
,`jumlah` int(11)
,`bunga` float(10,2)
,`biaya_adm` decimal(30,2)
,`file` varchar(240)
,`tenor` enum('Hari','Minggu','Bulan')
,`lunas` enum('Belum','Lunas')
,`dk` enum('D','K')
,`kas_id` int(11)
,`user_name` varchar(255)
,`pokok_angsuran` decimal(14,4)
,`bunga_pinjaman` double(17,0)
,`provisi_pinjaman` bigint(14)
,`ags_per_bulan` double(17,0)
,`tgl_denda` date
,`tempo` datetime
,`tagihan` double(17,0)
,`keterangan` varchar(255)
,`barang_id` int(11)
,`bln_sudah_angsur` bigint(11)
,`tgl_bayar` datetime
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_hitung_repayment`
-- (See below for the actual view)
--
CREATE TABLE `v_hitung_repayment` (
`id` int(11)
,`jns_cabangid` int(11)
,`simpanan_wajib` int(11)
,`simpanan_wajib_akun` int(11)
,`pencairan_bersih_akun` int(11)
,`bunga_bulan_dua` int(11)
,`bunga_bulan_dua_akun` int(11)
,`pokok_bulan_dua` int(11)
,`pokok_bulan_dua_akun` int(11)
,`pencairan_bersih` int(11)
,`bunga_bulan_satu_akun` int(11)
,`bunga_bulan_satu` int(11)
,`pokok_bulan_satu_akun` int(11)
,`pokok_bulan_satu` int(11)
,`simpanan_pokok_akun` int(11)
,`simpanan_pokok` int(11)
,`biaya_materai_akun` int(11)
,`biaya_materai` int(11)
,`biaya_administrasi_akun` int(11)
,`biaya_administrasi` int(11)
,`biaya_asuransi_akun` int(11)
,`biaya_asuransi` int(11)
,`nomor_pensiunan` varchar(100)
,`nomor_rekening` varchar(100)
,`no_perjanjian_kredit` varchar(50)
,`angsuran_per_bulan` int(11)
,`plafond_pinjaman_akun` int(11)
,`plafond_pinjaman` int(11)
,`jenis_pinjaman` int(2)
,`nomor_pinjaman` varchar(50)
,`tgl_pinjam` datetime
,`anggota_id` int(11)
,`lama_angsuran` int(11)
,`jumlah` int(11)
,`bunga` float(10,2)
,`file` varchar(240)
,`tenor` enum('Hari','Minggu','Bulan')
,`lunas` enum('Belum','Lunas')
,`dk` enum('D','K')
,`kas_id` int(11)
,`user_name` varchar(255)
,`pokok_angsuran` decimal(14,4)
,`bunga_pinjaman` double(17,0)
,`provisi_pinjaman` bigint(14)
,`ags_per_bulan` double(17,0)
,`tempo` datetime
,`tagihan` double(17,0)
,`keterangan` varchar(255)
,`bln_sudah_angsur` bigint(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_transaksi`
-- (See below for the actual view)
--
CREATE TABLE `v_transaksi` (
`tbl` varchar(1)
,`id` int(11)
,`tgl` datetime
,`kredit` double
,`debet` double
,`dari_kas` int(11)
,`untuk_kas` int(11)
,`transaksi` int(11)
,`ket` varchar(255)
,`user` varchar(255)
);

-- --------------------------------------------------------

--
-- Structure for view `v_hitung_pinjaman`
--
DROP TABLE IF EXISTS `v_hitung_pinjaman`;

CREATE ALGORITHM=UNDEFINED DEFINER=`gek2072`@`localhost` SQL SECURITY DEFINER VIEW `v_hitung_pinjaman`  AS  select `tbl_anggota`.`nama` AS `nama`,`tbl_anggota`.`ktp` AS `ktp`,`tbl_anggota`.`nomor_rekening` AS `rekening`,`tbl_pinjaman_h`.`jenis_pinjaman` AS `jenis_pinjam`,`tbl_pinjaman_h`.`id` AS `id`,`tbl_pinjaman_h`.`validasi_status` AS `validasi_status`,`tbl_pinjaman_h`.`jns_cabangid` AS `jns_cabangid`,`tbl_pinjaman_h`.`simpanan_wajib` AS `simpanan_wajib`,`tbl_pinjaman_h`.`simpanan_wajib_akun` AS `simpanan_wajib_akun`,`tbl_pinjaman_h`.`pencairan_bersih_akun` AS `pencairan_bersih_akun`,`tbl_pinjaman_h`.`bunga_bulan_dua` AS `bunga_bulan_dua`,`tbl_pinjaman_h`.`bunga_bulan_dua_akun` AS `bunga_bulan_dua_akun`,`tbl_pinjaman_h`.`pokok_bulan_dua` AS `pokok_bulan_dua`,`tbl_pinjaman_h`.`pokok_bulan_dua_akun` AS `pokok_bulan_dua_akun`,`tbl_pinjaman_h`.`pencairan_bersih` AS `pencairan_bersih`,`tbl_pinjaman_h`.`bunga_bulan_satu_akun` AS `bunga_bulan_satu_akun`,`tbl_pinjaman_h`.`bunga_bulan_satu` AS `bunga_bulan_satu`,`tbl_pinjaman_h`.`pokok_bulan_satu_akun` AS `pokok_bulan_satu_akun`,`tbl_pinjaman_h`.`pokok_bulan_satu` AS `pokok_bulan_satu`,`tbl_pinjaman_h`.`simpanan_pokok_akun` AS `simpanan_pokok_akun`,`tbl_pinjaman_h`.`simpanan_pokok` AS `simpanan_pokok`,`tbl_pinjaman_h`.`biaya_materai_akun` AS `biaya_materai_akun`,`tbl_pinjaman_h`.`biaya_materai` AS `biaya_materai`,`tbl_pinjaman_h`.`biaya_administrasi_akun` AS `biaya_administrasi_akun`,`tbl_pinjaman_h`.`biaya_administrasi` AS `biaya_administrasi`,`tbl_pinjaman_h`.`biaya_asuransi_akun` AS `biaya_asuransi_akun`,`tbl_pinjaman_h`.`biaya_asuransi` AS `biaya_asuransi`,`tbl_pinjaman_h`.`nama_vendor` AS `nama_vendor`,`tbl_pinjaman_h`.`nomor_pensiunan` AS `nomor_pensiunan`,`tbl_pinjaman_h`.`nomor_rekening` AS `nomor_rekening`,`tbl_pinjaman_h`.`no_perjanjian_kredit` AS `no_perjanjian_kredit`,`tbl_pinjaman_h`.`angsuran_per_bulan` AS `angsuran_per_bulan`,`tbl_pinjaman_h`.`plafond_pinjaman_akun` AS `plafond_pinjaman_akun`,`tbl_pinjaman_h`.`plafond_pinjaman` AS `plafond_pinjaman`,`tbl_pinjaman_h`.`jenis_pinjaman` AS `jenis_pinjaman`,`tbl_pinjaman_h`.`nomor_pinjaman` AS `nomor_pinjaman`,`tbl_pinjaman_h`.`tgl_pinjam` AS `tgl_pinjam`,`tbl_pinjaman_h`.`anggota_id` AS `anggota_id`,`tbl_pinjaman_h`.`lama_angsuran` AS `lama_angsuran`,`tbl_pinjaman_h`.`plafond_pinjaman` AS `jumlah`,`tbl_pinjaman_h`.`bunga` AS `bunga`,`tbl_pinjaman_h`.`biaya_adm` AS `biaya_adm`,`tbl_pinjaman_h`.`file` AS `file`,`jns_pinjaman`.`tenor` AS `tenor`,`tbl_pinjaman_h`.`lunas` AS `lunas`,`tbl_pinjaman_h`.`dk` AS `dk`,`tbl_pinjaman_h`.`kas_id` AS `kas_id`,`tbl_pinjaman_h`.`user_name` AS `user_name`,`tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` AS `pokok_angsuran`,round(ceiling(`tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` * `tbl_pinjaman_h`.`bunga` / 100),-2) AS `bunga_pinjaman`,round(ceiling(`tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` / 100),-2) AS `provisi_pinjaman`,round(ceiling((`tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` * `tbl_pinjaman_h`.`bunga` / 100 + `tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` + `tbl_pinjaman_h`.`biaya_adm`) * 100 / 100),-2) AS `ags_per_bulan`,ifnull((select `z`.`periode` from `tbl_pinjaman_simulasi` `z` where `z`.`tbl_pinjam_hid` = `tbl_pinjaman_h`.`id` and month(`z`.`periode`) = month(`tbl_pinjaman_d`.`tgl_bayar`) and year(`z`.`periode`) = year(`tbl_pinjaman_d`.`tgl_bayar`)),str_to_date(concat(year(`tbl_pinjaman_d`.`tgl_bayar`),'-',month(`tbl_pinjaman_d`.`tgl_bayar`),'-',(select `suku_bunga`.`opsi_val` from `suku_bunga` where `suku_bunga`.`opsi_key` = 'denda_hari')),'%Y-%m-%d')) AS `tgl_denda`,`tbl_pinjaman_h`.`tgl_pinjam` + interval `tbl_pinjaman_h`.`lama_angsuran` month AS `tempo`,round(ceiling((`tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` * `tbl_pinjaman_h`.`bunga` / 100 + `tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` + `tbl_pinjaman_h`.`biaya_adm`) * 100 / 100 + `tbl_pinjaman_h`.`plafond_pinjaman` / `tbl_pinjaman_h`.`lama_angsuran` / 100),-2) * `tbl_pinjaman_h`.`lama_angsuran` AS `tagihan`,`tbl_pinjaman_h`.`keterangan` AS `keterangan`,`tbl_pinjaman_h`.`barang_id` AS `barang_id`,ifnull(max(`tbl_pinjaman_d`.`angsuran_ke`),0) AS `bln_sudah_angsur`,`tbl_pinjaman_d`.`tgl_bayar` AS `tgl_bayar` from (((`tbl_pinjaman_h` left join `tbl_pinjaman_d` on(`tbl_pinjaman_h`.`id` = `tbl_pinjaman_d`.`pinjam_id`)) left join `jns_pinjaman` on(`tbl_pinjaman_h`.`jenis_pinjaman` = `jns_pinjaman`.`id`)) left join `tbl_anggota` on(`tbl_pinjaman_h`.`anggota_id` = `tbl_anggota`.`id`)) group by `tbl_pinjaman_h`.`id` ;

-- --------------------------------------------------------

--
-- Structure for view `v_hitung_repayment`
--
DROP TABLE IF EXISTS `v_hitung_repayment`;

CREATE ALGORITHM=UNDEFINED DEFINER=`gek2072`@`localhost` SQL SECURITY DEFINER VIEW `v_hitung_repayment`  AS  select `repayment_schedule_h`.`id` AS `id`,`repayment_schedule_h`.`jns_cabangid` AS `jns_cabangid`,`repayment_schedule_d`.`simpanan_wajib` AS `simpanan_wajib`,`repayment_schedule_h`.`simpanan_wajib_akun` AS `simpanan_wajib_akun`,`repayment_schedule_h`.`pencairan_bersih_akun` AS `pencairan_bersih_akun`,`repayment_schedule_h`.`bunga_bulan_dua` AS `bunga_bulan_dua`,`repayment_schedule_h`.`bunga_bulan_dua_akun` AS `bunga_bulan_dua_akun`,`repayment_schedule_h`.`pokok_bulan_dua` AS `pokok_bulan_dua`,`repayment_schedule_h`.`pokok_bulan_dua_akun` AS `pokok_bulan_dua_akun`,`repayment_schedule_h`.`pencairan_bersih` AS `pencairan_bersih`,`repayment_schedule_h`.`bunga_bulan_satu_akun` AS `bunga_bulan_satu_akun`,`repayment_schedule_h`.`bunga_bulan_satu` AS `bunga_bulan_satu`,`repayment_schedule_h`.`pokok_bulan_satu_akun` AS `pokok_bulan_satu_akun`,`repayment_schedule_h`.`pokok_bulan_satu` AS `pokok_bulan_satu`,`repayment_schedule_h`.`simpanan_pokok_akun` AS `simpanan_pokok_akun`,`repayment_schedule_h`.`simpanan_pokok` AS `simpanan_pokok`,`repayment_schedule_h`.`biaya_materai_akun` AS `biaya_materai_akun`,`repayment_schedule_h`.`biaya_materai` AS `biaya_materai`,`repayment_schedule_h`.`biaya_administrasi_akun` AS `biaya_administrasi_akun`,`repayment_schedule_h`.`biaya_administrasi` AS `biaya_administrasi`,`repayment_schedule_h`.`biaya_asuransi_akun` AS `biaya_asuransi_akun`,`repayment_schedule_h`.`biaya_asuransi` AS `biaya_asuransi`,`repayment_schedule_h`.`nomor_pensiunan` AS `nomor_pensiunan`,`repayment_schedule_h`.`nomor_rekening` AS `nomor_rekening`,`repayment_schedule_h`.`no_perjanjian_kredit` AS `no_perjanjian_kredit`,`repayment_schedule_h`.`angsuran_per_bulan` AS `angsuran_per_bulan`,`repayment_schedule_h`.`plafond_pinjaman_akun` AS `plafond_pinjaman_akun`,`repayment_schedule_h`.`plafond_pinjaman` AS `plafond_pinjaman`,`repayment_schedule_h`.`jenis_pinjaman` AS `jenis_pinjaman`,`repayment_schedule_h`.`nomor_pinjaman` AS `nomor_pinjaman`,`repayment_schedule_h`.`tgl_pinjam` AS `tgl_pinjam`,`repayment_schedule_h`.`anggota_id` AS `anggota_id`,`repayment_schedule_h`.`lama_angsuran` AS `lama_angsuran`,`repayment_schedule_h`.`plafond_pinjaman` AS `jumlah`,`repayment_schedule_h`.`bunga` AS `bunga`,`repayment_schedule_h`.`file` AS `file`,`jns_pinjaman`.`tenor` AS `tenor`,`repayment_schedule_h`.`lunas` AS `lunas`,`repayment_schedule_h`.`dk` AS `dk`,`repayment_schedule_h`.`kas_id` AS `kas_id`,`repayment_schedule_h`.`user_name` AS `user_name`,`repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` AS `pokok_angsuran`,round(ceiling(`repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` * `repayment_schedule_h`.`bunga` / 100),-2) AS `bunga_pinjaman`,round(ceiling(`repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` / 100),-2) AS `provisi_pinjaman`,round(ceiling((`repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` * `repayment_schedule_h`.`bunga` / 100 + `repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` + `repayment_schedule_h`.`biaya_administrasi`) * 100 / 100),-2) AS `ags_per_bulan`,`repayment_schedule_h`.`tgl_pinjam` + interval `repayment_schedule_h`.`lama_angsuran` month AS `tempo`,round(ceiling((`repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` * `repayment_schedule_h`.`bunga` / 100 + `repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` + `repayment_schedule_h`.`biaya_administrasi`) * 100 / 100 + `repayment_schedule_h`.`plafond_pinjaman` / `repayment_schedule_h`.`lama_angsuran` / 100),-2) * `repayment_schedule_h`.`lama_angsuran` AS `tagihan`,`repayment_schedule_h`.`keterangan` AS `keterangan`,ifnull(max(`repayment_schedule_d`.`bulan_ke`),0) AS `bln_sudah_angsur` from ((`repayment_schedule_h` left join `repayment_schedule_d` on(`repayment_schedule_h`.`id` = `repayment_schedule_d`.`pinjam_id`)) left join `jns_pinjaman` on(`repayment_schedule_h`.`jenis_pinjaman` = `jns_pinjaman`.`id`)) group by `repayment_schedule_h`.`id` ;

-- --------------------------------------------------------

--
-- Structure for view `v_transaksi`
--
DROP TABLE IF EXISTS `v_transaksi`;

CREATE ALGORITHM=UNDEFINED DEFINER=`gek2072`@`localhost` SQL SECURITY DEFINER VIEW `v_transaksi`  AS  select 'A' AS `tbl`,`tbl_pinjaman_h`.`id` AS `id`,`tbl_pinjaman_h`.`tgl_pinjam` AS `tgl`,`tbl_pinjaman_h`.`jumlah` AS `kredit`,0 AS `debet`,`tbl_pinjaman_h`.`kas_id` AS `dari_kas`,NULL AS `untuk_kas`,`tbl_pinjaman_h`.`jns_trans` AS `transaksi`,`tbl_pinjaman_h`.`keterangan` AS `ket`,`tbl_pinjaman_h`.`user_name` AS `user` from `tbl_pinjaman_h` union select 'B' AS `tbl`,`tbl_pinjaman_d`.`id` AS `id`,`tbl_pinjaman_d`.`tgl_bayar` AS `tgl`,0 AS `kredit`,`tbl_pinjaman_d`.`jumlah_bayar` AS `debet`,NULL AS `dari_kas`,`tbl_pinjaman_d`.`kas_id` AS `untuk_kas`,`tbl_pinjaman_d`.`jns_trans` AS `transaksi`,`tbl_pinjaman_d`.`keterangan` AS `ket`,`tbl_pinjaman_d`.`user_name` AS `user` from `tbl_pinjaman_d` union select 'C' AS `tbl`,`tbl_trans_sp`.`id` AS `id`,`tbl_trans_sp`.`tgl_transaksi` AS `tgl`,if(`tbl_trans_sp`.`dk` = 'K',`tbl_trans_sp`.`jumlah`,0) AS `kredit`,if(`tbl_trans_sp`.`dk` = 'D',`tbl_trans_sp`.`jumlah`,0) AS `debet`,if(`tbl_trans_sp`.`dk` = 'K',`tbl_trans_sp`.`kas_id`,NULL) AS `dari_kas`,if(`tbl_trans_sp`.`dk` = 'D',`tbl_trans_sp`.`kas_id`,NULL) AS `untuk_kas`,`tbl_trans_sp`.`jenis_id` AS `transaksi`,`tbl_trans_sp`.`keterangan` AS `ket`,`tbl_trans_sp`.`user_name` AS `user` from `tbl_trans_sp` union select 'D' AS `tbl`,`tbl_trans_kas`.`id` AS `id`,`tbl_trans_kas`.`tgl_catat` AS `tgl`,if(`tbl_trans_kas`.`dk` = 'K',`tbl_trans_kas`.`jumlah`,if(`tbl_trans_kas`.`dk` is null,`tbl_trans_kas`.`jumlah`,0)) AS `kredit`,if(`tbl_trans_kas`.`dk` = 'D',`tbl_trans_kas`.`jumlah`,if(`tbl_trans_kas`.`dk` is null,`tbl_trans_kas`.`jumlah`,0)) AS `debet`,`tbl_trans_kas`.`dari_kas_id` AS `dari_kas`,`tbl_trans_kas`.`untuk_kas_id` AS `untuk_kas`,`tbl_trans_kas`.`jns_trans` AS `transaksi`,`tbl_trans_kas`.`keterangan` AS `ket`,`tbl_trans_kas`.`user_name` AS `user` from `tbl_trans_kas` order by `tgl` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `auto_debet_tempo`
--
ALTER TABLE `auto_debet_tempo`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ci_sessions`
--
ALTER TABLE `ci_sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD KEY `last_activity_idx` (`last_activity`);

--
-- Indexes for table `fixed_asset`
--
ALTER TABLE `fixed_asset`
  ADD PRIMARY KEY (`kode_asset_id`),
  ADD KEY `kode_asset` (`kode_asset`);

--
-- Indexes for table `fixed_asset_history`
--
ALTER TABLE `fixed_asset_history`
  ADD UNIQUE KEY `uq_fixasshist` (`kode_asset_id`);

--
-- Indexes for table `history_autodebet`
--
ALTER TABLE `history_autodebet`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jns_akun`
--
ALTER TABLE `jns_akun`
  ADD PRIMARY KEY (`jns_akun_id`) USING BTREE,
  ADD UNIQUE KEY `kd_aktiva` (`no_akun`) USING BTREE,
  ADD KEY `fk_jnsakun_kelakun` (`kelompok_akunid`),
  ADD KEY `fk_jnsakun_induk_akun` (`induk_akun`);

--
-- Indexes for table `jns_anggota`
--
ALTER TABLE `jns_anggota`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jns_anggota_kode` (`kode`),
  ADD UNIQUE KEY `uq_jns_anggota_nama` (`nama`);

--
-- Indexes for table `jns_angsuran`
--
ALTER TABLE `jns_angsuran`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jns_angsuran` (`ket`);

--
-- Indexes for table `jns_cabang`
--
ALTER TABLE `jns_cabang`
  ADD PRIMARY KEY (`jns_cabangid`),
  ADD UNIQUE KEY `kode_cabang` (`kode_cabang`);

--
-- Indexes for table `jns_deposito`
--
ALTER TABLE `jns_deposito`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jns_pengajuan`
--
ALTER TABLE `jns_pengajuan`
  ADD PRIMARY KEY (`jenis_id`),
  ADD UNIQUE KEY `jns_pengajuan` (`jenis_pengajuan`);

--
-- Indexes for table `jns_pinjaman`
--
ALTER TABLE `jns_pinjaman`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jns_pinjaman` (`jns_pinjaman`);

--
-- Indexes for table `jns_simpan`
--
ALTER TABLE `jns_simpan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_jns_simpan` (`jns_simpan`);

--
-- Indexes for table `journal_voucher`
--
ALTER TABLE `journal_voucher`
  ADD PRIMARY KEY (`journal_voucherid`),
  ADD UNIQUE KEY `uq_journal_no` (`journal_no`);

--
-- Indexes for table `journal_voucher_det`
--
ALTER TABLE `journal_voucher_det`
  ADD PRIMARY KEY (`journal_voucher_detid`);

--
-- Indexes for table `kategori_asset`
--
ALTER TABLE `kategori_asset`
  ADD PRIMARY KEY (`kategori_asset_id`),
  ADD UNIQUE KEY `kategori_asset` (`kategori_asset`) USING BTREE;

--
-- Indexes for table `kelompok_akun`
--
ALTER TABLE `kelompok_akun`
  ADD PRIMARY KEY (`kelompok_akunid`),
  ADD UNIQUE KEY `uq_nama_kelompok` (`nama_kelompok`);

--
-- Indexes for table `nama_kas_tbl`
--
ALTER TABLE `nama_kas_tbl`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `neraca_skonto`
--
ALTER TABLE `neraca_skonto`
  ADD PRIMARY KEY (`neraca_skonto_id`);

--
-- Indexes for table `postinglog`
--
ALTER TABLE `postinglog`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `repayment_schedule_d`
--
ALTER TABLE `repayment_schedule_d`
  ADD PRIMARY KEY (`id`) USING BTREE,
  ADD KEY `user_name` (`user_name`) USING BTREE,
  ADD KEY `pinjam_id` (`pinjam_id`) USING BTREE;

--
-- Indexes for table `repayment_schedule_h`
--
ALTER TABLE `repayment_schedule_h`
  ADD PRIMARY KEY (`id`) USING BTREE,
  ADD KEY `anggota_id` (`anggota_id`) USING BTREE,
  ADD KEY `kas_id` (`kas_id`) USING BTREE,
  ADD KEY `user_name` (`user_name`) USING BTREE,
  ADD KEY `jns_trans` (`jns_trans`) USING BTREE;

--
-- Indexes for table `setting_autodebet`
--
ALTER TABLE `setting_autodebet`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sewa_kantor`
--
ALTER TABLE `sewa_kantor`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cabang_id` (`cabang_id`);

--
-- Indexes for table `sewa_kantor_history`
--
ALTER TABLE `sewa_kantor_history`
  ADD UNIQUE KEY `uq_sewa_kantor` (`id`);

--
-- Indexes for table `suku_bunga`
--
ALTER TABLE `suku_bunga`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_anggota`
--
ALTER TABLE `tbl_anggota`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_barang`
--
ALTER TABLE `tbl_barang`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_barang_nm` (`type`,`nm_barang`,`merk`) USING BTREE;

--
-- Indexes for table `tbl_pengajuan`
--
ALTER TABLE `tbl_pengajuan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`anggota_id`);

--
-- Indexes for table `tbl_pinjaman_d`
--
ALTER TABLE `tbl_pinjaman_d`
  ADD PRIMARY KEY (`id`),
  ADD KEY `kas_id` (`kas_id`),
  ADD KEY `user_name` (`user_name`),
  ADD KEY `pinjam_id` (`pinjam_id`),
  ADD KEY `jns_trans` (`jns_trans`);

--
-- Indexes for table `tbl_pinjaman_h`
--
ALTER TABLE `tbl_pinjaman_h`
  ADD PRIMARY KEY (`id`),
  ADD KEY `anggota_id` (`anggota_id`),
  ADD KEY `kas_id` (`kas_id`),
  ADD KEY `user_name` (`user_name`),
  ADD KEY `jns_trans` (`jns_trans`),
  ADD KEY `barang_id` (`barang_id`);

--
-- Indexes for table `tbl_pinjaman_simulasi`
--
ALTER TABLE `tbl_pinjaman_simulasi`
  ADD KEY `ix_tblpinjamsim` (`tbl_pinjam_hid`,`blnke`,`periode`);

--
-- Indexes for table `tbl_setting`
--
ALTER TABLE `tbl_setting`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_transaksi_toko`
--
ALTER TABLE `tbl_transaksi_toko`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_trans_dp`
--
ALTER TABLE `tbl_trans_dp`
  ADD PRIMARY KEY (`id`),
  ADD KEY `anggota_id` (`anggota_id`),
  ADD KEY `jenis_id` (`jenis_id`),
  ADD KEY `kas_id` (`kas_id`),
  ADD KEY `user_name` (`user_name`);

--
-- Indexes for table `tbl_trans_dp_d`
--
ALTER TABLE `tbl_trans_dp_d`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_trans_kas`
--
ALTER TABLE `tbl_trans_kas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_name` (`user_name`),
  ADD KEY `dari_kas_id` (`dari_kas_id`,`untuk_kas_id`),
  ADD KEY `untuk_kas_id` (`untuk_kas_id`),
  ADD KEY `jns_trans` (`jns_trans`);

--
-- Indexes for table `tbl_trans_sp`
--
ALTER TABLE `tbl_trans_sp`
  ADD PRIMARY KEY (`id`),
  ADD KEY `anggota_id` (`anggota_id`),
  ADD KEY `jenis_id` (`jenis_id`),
  ADD KEY `kas_id` (`kas_id`),
  ADD KEY `user_name` (`user_name`);

--
-- Indexes for table `tbl_trans_sp_d`
--
ALTER TABLE `tbl_trans_sp_d`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_user`
--
ALTER TABLE `tbl_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `u_name` (`u_name`,`jns_cabangid`) USING BTREE;

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `auto_debet_tempo`
--
ALTER TABLE `auto_debet_tempo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `fixed_asset`
--
ALTER TABLE `fixed_asset`
  MODIFY `kode_asset_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=237;

--
-- AUTO_INCREMENT for table `history_autodebet`
--
ALTER TABLE `history_autodebet`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jns_akun`
--
ALTER TABLE `jns_akun`
  MODIFY `jns_akun_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=187;

--
-- AUTO_INCREMENT for table `jns_anggota`
--
ALTER TABLE `jns_anggota`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `jns_angsuran`
--
ALTER TABLE `jns_angsuran`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `jns_cabang`
--
ALTER TABLE `jns_cabang`
  MODIFY `jns_cabangid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT for table `jns_deposito`
--
ALTER TABLE `jns_deposito`
  MODIFY `id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `jns_pengajuan`
--
ALTER TABLE `jns_pengajuan`
  MODIFY `jenis_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `jns_pinjaman`
--
ALTER TABLE `jns_pinjaman`
  MODIFY `id` int(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `jns_simpan`
--
ALTER TABLE `jns_simpan`
  MODIFY `id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT for table `journal_voucher`
--
ALTER TABLE `journal_voucher`
  MODIFY `journal_voucherid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=836;

--
-- AUTO_INCREMENT for table `journal_voucher_det`
--
ALTER TABLE `journal_voucher_det`
  MODIFY `journal_voucher_detid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3366;

--
-- AUTO_INCREMENT for table `kategori_asset`
--
ALTER TABLE `kategori_asset`
  MODIFY `kategori_asset_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `kelompok_akun`
--
ALTER TABLE `kelompok_akun`
  MODIFY `kelompok_akunid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `nama_kas_tbl`
--
ALTER TABLE `nama_kas_tbl`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `neraca_skonto`
--
ALTER TABLE `neraca_skonto`
  MODIFY `neraca_skonto_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT for table `postinglog`
--
ALTER TABLE `postinglog`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=197;

--
-- AUTO_INCREMENT for table `repayment_schedule_d`
--
ALTER TABLE `repayment_schedule_d`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `repayment_schedule_h`
--
ALTER TABLE `repayment_schedule_h`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `setting_autodebet`
--
ALTER TABLE `setting_autodebet`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `sewa_kantor`
--
ALTER TABLE `sewa_kantor`
  MODIFY `id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `suku_bunga`
--
ALTER TABLE `suku_bunga`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `tbl_anggota`
--
ALTER TABLE `tbl_anggota`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=145;

--
-- AUTO_INCREMENT for table `tbl_barang`
--
ALTER TABLE `tbl_barang`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_pengajuan`
--
ALTER TABLE `tbl_pengajuan`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_pinjaman_d`
--
ALTER TABLE `tbl_pinjaman_d`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=429;

--
-- AUTO_INCREMENT for table `tbl_pinjaman_h`
--
ALTER TABLE `tbl_pinjaman_h`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=98;

--
-- AUTO_INCREMENT for table `tbl_setting`
--
ALTER TABLE `tbl_setting`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `tbl_transaksi_toko`
--
ALTER TABLE `tbl_transaksi_toko`
  MODIFY `id` int(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_trans_dp`
--
ALTER TABLE `tbl_trans_dp`
  MODIFY `id` mediumint(9) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_trans_sp`
--
ALTER TABLE `tbl_trans_sp`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=356;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `jns_akun`
--
ALTER TABLE `jns_akun`
  ADD CONSTRAINT `fk_jnsakun_induk_akun` FOREIGN KEY (`induk_akun`) REFERENCES `jns_akun` (`jns_akun_id`),
  ADD CONSTRAINT `fk_jnsakun_kelakun` FOREIGN KEY (`kelompok_akunid`) REFERENCES `kelompok_akun` (`kelompok_akunid`) ON UPDATE CASCADE;

--
-- Constraints for table `sewa_kantor`
--
ALTER TABLE `sewa_kantor`
  ADD CONSTRAINT `fk_cabang_id` FOREIGN KEY (`cabang_id`) REFERENCES `jns_cabang` (`jns_cabangid`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
