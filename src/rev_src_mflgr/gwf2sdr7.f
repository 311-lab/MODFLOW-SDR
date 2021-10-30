      MODULE GWFSDRMODULE
        INTEGER,SAVE,POINTER  ::NSDR,MXSDR,NSDRVL,ISDRCB,IPRSDR
        INTEGER,SAVE,POINTER  ::NPSDR,ISDRPB,NNPSDR
        CHARACTER(LEN=16),SAVE, DIMENSION(:),   POINTER     ::SDRAUX
        REAL,             SAVE, DIMENSION(:,:), POINTER     ::SDRR
      TYPE GWFSDRTYPE
        INTEGER,POINTER  ::NSDR,MXSDR,NSDRVL,ISDRCB,IPRSDR
        INTEGER,POINTER  ::NPSDR,ISDRPB,NNPSDR
        CHARACTER(LEN=16), DIMENSION(:),   POINTER     ::SDRAUX
        REAL,              DIMENSION(:,:), POINTER     ::SDRR
      END TYPE
      TYPE(GWFSDRTYPE), SAVE:: GWFSDRDAT(100)
      END MODULE GWFSDRMODULE


      SUBROUTINE GWF2SDR7AR(IN,IGRID)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR SDR AND READ PARAMETER DEFINITIONS.
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IFREFM
      USE GWFSDRMODULE, ONLY:NSDR,MXSDR,NSDRVL,ISDRCB,IPRSDR,NPSDR,
     1                       ISDRPB,NNPSDR,SDRAUX,SDRR
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------Allocate scalar variables, which makes it possible for multiple
C1------grids to be defined.
      ALLOCATE(NSDR,MXSDR,NSDRVL,ISDRCB,IPRSDR,NPSDR,ISDRPB,NNPSDR)
C
C2------IDENTIFY PACKAGE AND INITIALIZE NSDRER AND NNPSDR.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'SDR -- SDR PACKAGE, VERSION 7, 5/2/2005',
     1' INPUT READ FROM UNIT ',I4)
      NSDR=0
      NNPSDR=0
C
C3------READ MAXIMUM NUMBER OF SDR REACHES AND UNIT OR FLAG FOR
C3------CELL-BY-CELL FLOW TERMS.
      CALL URDCOM(IN,IOUT,LINE)
      CALL UPARLSTAL(IN,IOUT,LINE,NPSDR,MXPR)
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(2I10)') MXACTR,ISDRCB
         LLOC=21
      ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTR,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ISDRCB,R,IOUT,IN)
      END IF
      WRITE(IOUT,3) MXACTR
    3 FORMAT(1X,'MAXIMUM OF ',I6,' ACTIVE SDR REACHES AT ONE TIME')
      IF(ISDRCB.LT.0) WRITE(IOUT,7)
    7 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE PRINTED WHEN ICBCFL NOT 0')
      IF(ISDRCB.GT.0) WRITE(IOUT,8) ISDRCB
    8 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE SAVED ON UNIT ',I4)
C
C4------READ AUXILIARY VARIABLES AND PRINT OPTION.
      ALLOCATE (SDRAUX(20))
      NAUX=0
      IPRSDR=1
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1        LINE(ISTART:ISTOP).EQ.'AUX') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
         IF(NAUX.LT.20) THEN
            NAUX=NAUX+1
            SDRAUX(NAUX)=LINE(ISTART:ISTOP)
            WRITE(IOUT,12) SDRAUX(NAUX)
   12       FORMAT(1X,'AUXILIARY SDR VARIABLE: ',A)
         END IF
         GO TO 10
      ELSE IF(LINE(ISTART:ISTOP).EQ.'NOPRINT') THEN
         WRITE(IOUT,13)
   13    FORMAT(1X,'LISTS OF SDR CELLS WILL NOT BE PRINTED')
         IPRSDR = 0
         GO TO 10
      END IF
C
C5------ALLOCATE SPACE FOR SDR ARRAYS.
C5------FOR EACH REACH, THERE ARE SEVEN INPUT DATA VALUES PLUS ONE
C5------LOCATION FOR CELL-BY-CELL FLOW.
      NSDRVL=8+NAUX
      ISDRPB=MXACTR+1
      MXSDR=MXACTR+MXPR
      ALLOCATE (SDRR(NSDRVL,MXSDR))
C
C6------READ NAMED PARAMETERS.
      WRITE(IOUT,99) NPSDR
   99 FORMAT(1X,//1X,I5,' SDR parameters')
      IF(NPSDR.GT.0) THEN
        LSTSUM=ISDRPB
        DO 120 K=1,NPSDR
          LSTBEG=LSTSUM
          CALL UPARLSTRP(LSTSUM,MXSDR,IN,IOUT,IP,'SDR','SDR',1,
     &                   NUMINST)
          NLST=LSTSUM-LSTBEG
          IF (NUMINST.EQ.0) THEN
C6A-----READ PARAMETER WITHOUT INSTANCES
            CALL ULSTRD(NLST,SDRR,LSTBEG,NSDRVL,MXSDR,1,IN,
     &            IOUT,'REACH NO.  LAYER   ROW   COL'//
     &            '     D    L    R    S',
     &            SDRAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRSDR)
          ELSE
C6B-----READ INSTANCES
            NINLST = NLST/NUMINST
            DO 110 I=1,NUMINST
            CALL UINSRP(I,IN,IOUT,IP,IPRSDR)
            CALL ULSTRD(NINLST,SDRR,LSTBEG,NSDRVL,MXSDR,1,IN,
     &            IOUT,'REACH NO.  LAYER   ROW   COL'//
     &            '     D    L    R    S',
     &            SDRAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRSDR)
            LSTBEG=LSTBEG+NINLST
  110       CONTINUE
          END IF
  120   CONTINUE
      END IF
C
C7------SAVE POINTERS TO DATA AND RETURN.
      CALL SGWF2SDR7PSV(IGRID)
      RETURN
      END
      SUBROUTINE GWF2SDR7RP(IN,IGRID)
C     ******************************************************************
C     READ SDR HEAD, CONDUCTANCE AND BOTTOM ELEVATION
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IFREFM
      USE GWFSDRMODULE, ONLY:NSDR,MXSDR,NSDRVL,IPRSDR,NPSDR,
     1                       ISDRPB,NNPSDR,SDRAUX,SDRR
C     ------------------------------------------------------------------
      CALL SGWF2SDR7PNT(IGRID)
C
C1------READ ITMP (NUMBER OF SDR REACHES OR FLAG TO REUSE DATA) AND
C1------NUMBER OF PARAMETERS.
      IF(NPSDR.GT.0) THEN
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(2I10)') ITMP,NP
         ELSE
            READ(IN,*) ITMP,NP
         END IF
      ELSE
         NP=0
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(I10)') ITMP
         ELSE
            READ(IN,*) ITMP
         END IF
      END IF
C
C------CALCULATE SOME CONSTANTS
      NAUX=NSDRVL-8
      IOUTU = IOUT
      IF (IPRSDR.EQ.0) IOUTU = -IOUT
C
C2------DETERMINE THE NUMBER OF NON-PARAMETER REACHES.
      IF(ITMP.LT.0) THEN
         WRITE(IOUT,7)
    7    FORMAT(1X,/1X,
     1   'REUSING NON-PARAMETER SDR REACHES FROM LAST STRESS PERIOD')
      ELSE
         NNPSDR=ITMP
      END IF
C
C3------IF THERE ARE NEW NON-PARAMETER REACHES, READ THEM.
      MXACTR=ISDRPB-1
      IF(ITMP.GT.0) THEN
         IF(NNPSDR.GT.MXACTR) THEN
            WRITE(IOUT,99) NNPSDR,MXACTR
   99       FORMAT(1X,/1X,'THE NUMBER OF ACTIVE REACHES (',I6,
     1                     ') IS GREATER THAN MXACTR(',I6,')')
            CALL USTOP(' ')
         END IF
         CALL ULSTRD(NNPSDR,SDRR,1,NSDRVL,MXSDR,1,IN,IOUT,
     1          'REACH NO.  LAYER   ROW   COL'//
     2          '     D      L      R      S',
     3          SDRAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRSDR)
      END IF
      NSDR=NNPSDR
C
C1C-----IF THERE ARE ACTIVE SDR PARAMETERS, READ THEM AND SUBSTITUTE
      CALL PRESET('SDR')
      IF(NP.GT.0) THEN
         NREAD=NSDRVL-1
         DO 30 N=1,NP
         CALL UPARLSTSUB(IN,'SDR',IOUTU,'SDR',SDRR,NSDRVL,MXSDR,NREAD,
     1                MXACTR,NSDR,5,5,
     2   'REACH NO.  LAYER   ROW   COL'//
     3   '     D      L      R      S.',SDRAUX,20,NAUX)
   30    CONTINUE
      END IF
C
C3------PRINT NUMBER OF REACHES IN CURRENT STRESS PERIOD.
      WRITE (IOUT,101) NSDR
  101 FORMAT(1X,/1X,I6,' SDR REACHES')
C
C8------RETURN.
  260 RETURN
      END
      SUBROUTINE GWF2SDR7FM(IGRID)
C     ******************************************************************
C     ADD SDR TERMS TO RHS 
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,HNEW,RHS,BOTM
      USE GWFSDRMODULE, ONLY:NSDR,SDRR
      USE GWFLPFMODULE, ONLY:HK
C
      DOUBLE PRECISION DHOOG,LHOOG,RHOOG,SHOOG,QHOOG,AHOOG,DDHOOG,HJ,HS
     &                 QQHOOG 
C     ------------------------------------------------------------------
      CALL SGWF2SDR7PNT(IGRID)
C
C1------IF NSDR<=0 THERE ARE NO SDR. RETURN.
      IF(NSDR.LE.0) RETURN
C
C2------PROCESS EACH CELL IN THE SDR LIST.
      DO 100 L=1,NSDR/2
C
C3------GET COLUMN, ROW AND LAYER OF CELL CONTAINING SDR.
      IL=SDRR(1,L)
      IR=SDRR(2,L)
      IC=SDRR(3,L)
      ILL=SDRR(1,L+NSDR/2)
      IRR=SDRR(2,L+NSDR/2)
      ICC=SDRR(3,L+NSDR/2)
      IRP=IR+1
      IRS=IR-1
      ICP=IC+1
      ICS=IC-1
C
C4-------IF THE CELL IS EXTERNAL SKIP IT.
      IF(IBOUND(IC,IR,IL).LE.0) GO TO 100
C
C5-------IF THE CELL IS INTERNAL GET THE SDR DATA.
      DHOOG=SDRR(4,L)
      LHOOG=SDRR(5,L)
      RHOOG=SDRR(6,L)
      SHOOG=SDRR(7,L)
      HJ=HNEW(IC,IR,IL)
      HS=1
C6------IF HEAD IS LOWER THAN SDR THEN SKIP THIS CELL.
C      IF((HNEW(IC,IR,IL)-(BOTM(IC,IR,0)-DHOOG)).LT.(-0.01)) GO TO 100
      IF (IBOUND(ICS,IR,IL).GT.0) THEN 
         HJ=HJ+HNEW(ICS,IR,IL) 
         HS=HS+1
      END IF
      IF (IBOUND(ICP,IR,IL).GT.0) THEN 
         HJ=HJ+HNEW(ICP,IR,IL)
         HS=HS+1
      END IF
C      IF (IBOUND(IC,IRS,IL).GT.0) THEN 
C         HJ=HJ+HNEW(IC,IRS,IL)
C         HS=HS+1
C      END IF
C      IF (IBOUND(IC,IRP,IL).GT.0) THEN 
C         HJ=HJ+HNEW(IC,IRP,IL)
C         HS=HS+1
C      END IF
      IF((HJ/HS).LT.(BOTM(IC,IR,0)-DHOOG)) GO TO 100    
C7------HEAD IS HIGHER THAN SDR. ADD TERMS TO RHS AND HCOF.
C      HNEW(IC,IR,IL)=(BOTM(IC,IR,0)-DHOOG)
      AHOOG=3.55-1.6*(BOTM(IC,IR,0)-DHOOG)/LHOOG+8/LHOOG/LHOOG
      IF(((BOTM(IC,IR,0)-DHOOG)/LHOOG).LE.0.3) THEN
      DDHOOG=(BOTM(IC,IR,0)-DHOOG)/(1.0+(BOTM(IC,IR,0)-DHOOG)/LHOOG*
     1(8.0/3.14*LOG((BOTM(IC,IR,0)-DHOOG)/RHOOG)-AHOOG))
      ELSE
      DDHOOG=LHOOG*3.14/8.0/(LOG(LHOOG/RHOOG)-1.15)
      ENDIF
      QHOOG=(8.0*HK(IC,IR,IL)*DDHOOG*(HNEW(ICC,IRR,ILL)-
     1(BOTM(IC,IR,0)-DHOOG))+4*HK(IC,IR,IL)*(HNEW(ICC,IRR,ILL)-
     2(BOTM(IC,IR,0)-DHOOG))**2)/LHOOG**2*SHOOG/(NSDR/2)
      IF(QHOOG.GE.0) THEN 
          QQHOOG=QHOOG
      ELSE
          QQHOOG=0
      ENDIF
      RHS(IC,IR,IL)=RHS(IC,IR,IL)+QQHOOG
  100 CONTINUE
C
C8------RETURN.
      RETURN
      END
      SUBROUTINE GWF2SDR7BD(KSTP,KPER,IGRID)
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR SDR
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,HNEW,BUFF,BOTM
      USE GWFLPFMODULE, ONLY:HK
      USE GWFBASMODULE, ONLY:MSUM,ICBCFL,IAUXSV,DELT,PERTIM,TOTIM,
     1                       VBVL,VBNM
      USE GWFSDRMODULE, ONLY:NSDR,ISDRCB,SDRR,NSDRVL,SDRAUX
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATOUT,QQ,DHOOG,LHOOG,RHOOG,SHOOG,QHOOG,AHOOG,
     1                 DDHOOG,HJ,HS,QQHOOG
C
      DATA TEXT /'          SDR'/
C     ------------------------------------------------------------------
      CALL SGWF2SDR7PNT(IGRID)
C
C1------INITIALIZE CELL-BY-CELL FLOW TERM FLAG (IBD) AND
C1------ACCUMULATOR (RATOUT).
      ZERO=0.
      RATOUT=ZERO
      IBD=0
      IF(ISDRCB.LT.0 .AND. ICBCFL.NE.0) IBD=-1
      IF(ISDRCB.GT.0) IBD=ICBCFL
      IBDLBL=0
C
C2------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NSDRVL-8
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,SDRAUX,ISDRCB,NCOL,NROW,NLAY,
     1          NSDR,IOUT,DELT,PERTIM,TOTIM,IBOUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 IL=1,NLAY
      DO 50 IR=1,NROW
      DO 50 IC=1,NCOL
      BUFF(IC,IR,IL)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO SDR THEN DO NOT ACCUMULATE SDR FLOW.
      IF(NSDR.LE.0) GO TO 200
C
C5------LOOP THROUGH EACH SDR CALCULATING FLOW.
      DO 100 L=1,NSDR/2
C
C5A-----GET LAYER, ROW & COLUMN OF CELL CONTAINING SDR.
      IL=SDRR(1,L)
      IR=SDRR(2,L)
      IC=SDRR(3,L)
      ILL=SDRR(1,L+NSDR/2)
      IRR=SDRR(2,L+NSDR/2)
      ICC=SDRR(3,L+NSDR/2)
      Q=ZERO
      IRP=IR+1
      IRS=IR-1
      ICP=IC+1
      ICS=IC-1
C
C5B-----IF CELL IS NO-FLOW OR CONSTANT-HEAD, IGNORE IT.
      IF(IBOUND(IC,IR,IL).LE.0) GO TO 99
C
C5C-----GET SDR PARAMETERS FROM SDR LIST.
      DHOOG=SDRR(4,L)
      LHOOG=SDRR(5,L)
      RHOOG=SDRR(6,L)
      SHOOG=SDRR(7,L)
      HJ=HNEW(IC,IR,IL)
      HS=1
C5D-----IF HEAD HIGHER THAN SDR, CALCULATE Q=QHOOG.
C5D-----SUBTRACT Q FROM RATOUT.
      IF (IBOUND(ICS,IR,IL).GT.0) THEN 
      HJ=HJ+HNEW(ICS,IR,IL) 
      HS=HS+1
      END IF
      IF (IBOUND(ICP,IR,IL).GT.0) THEN 
      HJ=HJ+HNEW(ICP,IR,IL)
      HS=HS+1
      END IF
C      IF (IBOUND(IC,IRS,IL).GT.0) THEN 
C      HJ=HJ+HNEW(IC,IRS,IL)
C      HS=HS+1
C      END IF
C      IF (IBOUND(IC,IRP,IL).GT.0) THEN 
C      HJ=HJ+HNEW(IC,IRP,IL)
C      HS=HS+1
C      END IF
C      IF((HNEW(IC,IR,IL)-(BOTM(IC,IR,0)-DHOOG)).GE.(-0.01)) THEN
      IF((HJ/HS).GE.(BOTM(IC,IR,0)-DHOOG)) THEN
          AHOOG=3.55-1.6*(BOTM(IC,IR,0)-DHOOG)/LHOOG+8/LHOOG/LHOOG
          IF(((BOTM(IC,IR,0)-DHOOG)/LHOOG).LE.0.3) THEN
              DDHOOG=(BOTM(IC,IR,0)-DHOOG)/(1.0+(BOTM(IC,IR,0)-DHOOG)
     1         /LHOOG*(8.0/3.14*LOG((BOTM(IC,IR,0)-DHOOG)/RHOOG)-AHOOG))
          ELSE
              DDHOOG=LHOOG*3.14/8.0/(LOG(LHOOG/RHOOG)-1.15)
          ENDIF
          QHOOG=(8.0*HK(IC,IR,IL)*DDHOOG*(HNEW(ICC,IRR,ILL)-
     1    (BOTM(IC,IR,0)-DHOOG))+4*HK(IC,IR,IL)*(HNEW(ICC,IRR,ILL)-
     2    (BOTM(IC,IR,0)-DHOOG))**2)/LHOOG**2*SHOOG/(NSDR/2)
          IF(QHOOG.GE.0) THEN 
              QQHOOG=QHOOG
          ELSE 
              QQHOOG=0
          ENDIF
          QQ=-QQHOOG
          Q=QQ 
          RATOUT=RATOUT-QQ
      END IF
C
C5E-----PRINT THE INDIVIDUAL RATES IF REQUESTED(ISDRCB<0).
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
         WRITE(IOUT,62) L,IL,IR,IC,Q
   62    FORMAT(1X,'SDR ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',I5,
     1       '   RATE ',1PG15.6)
         IBDLBL=1
      END IF
C
C5F-----ADD Q TO BUFFER.
      BUFF(IC,IR,IL)=BUFF(IC,IR,IL)+Q
C
C5G-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C5G-----COPY FLOW TO SDRR.
   99 IF(IBD.EQ.2) CALL UBDSVB(ISDRCB,NCOL,NROW,IC,IR,IL,Q,
     1                  SDRR(:,L),NSDRVL,NAUX,6,IBOUND,NLAY)
      SDRR(NSDRVL,L)=Q
  100 CONTINUE
C
C6------IF CELL-BY-CELL FLOW WILL BE SAVED AS A 3-D ARRAY,
C6------CALL UBUDSV TO SAVE THEM.
      IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,ISDRCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
C
C7------MOVE RATES,VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 ROUT=RATOUT
      VBVL(3,MSUM)=ZERO
      VBVL(4,MSUM)=ROUT
      VBVL(2,MSUM)=VBVL(2,MSUM)+ROUT*DELT
      VBNM(MSUM)=TEXT
C
C8------INCREMENT BUDGET TERM COUNTER.
      MSUM=MSUM+1
C
C9------RETURN.
      RETURN
      END
      SUBROUTINE GWF2SDR7DA(IGRID)
C  Deallocate SDR MEMORY
      USE GWFSDRMODULE
C
        CALL SGWF2SDR7PNT(IGRID)
        DEALLOCATE(NSDR)
        DEALLOCATE(MXSDR)
        DEALLOCATE(NSDRVL)
        DEALLOCATE(ISDRCB)
        DEALLOCATE(IPRSDR)
        DEALLOCATE(NPSDR)
        DEALLOCATE(ISDRPB)
        DEALLOCATE(NNPSDR)
        DEALLOCATE(SDRAUX)
        DEALLOCATE(SDRR)
C
      RETURN
      END
      SUBROUTINE SGWF2SDR7PNT(IGRID)
C  Change SDR data to a different grid.
      USE GWFSDRMODULE
C
        NSDR=>GWFSDRDAT(IGRID)%NSDR
        MXSDR=>GWFSDRDAT(IGRID)%MXSDR
        NSDRVL=>GWFSDRDAT(IGRID)%NSDRVL
        ISDRCB=>GWFSDRDAT(IGRID)%ISDRCB
        IPRSDR=>GWFSDRDAT(IGRID)%IPRSDR
        NPSDR=>GWFSDRDAT(IGRID)%NPSDR
        ISDRPB=>GWFSDRDAT(IGRID)%ISDRPB
        NNPSDR=>GWFSDRDAT(IGRID)%NNPSDR
        SDRAUX=>GWFSDRDAT(IGRID)%SDRAUX
        SDRR=>GWFSDRDAT(IGRID)%SDRR
C
      RETURN
      END
      SUBROUTINE SGWF2SDR7PSV(IGRID)
C  Save SDR data for a grid.
      USE GWFSDRMODULE
C
        GWFSDRDAT(IGRID)%NSDR=>NSDR
        GWFSDRDAT(IGRID)%MXSDR=>MXSDR
        GWFSDRDAT(IGRID)%NSDRVL=>NSDRVL
        GWFSDRDAT(IGRID)%ISDRCB=>ISDRCB
        GWFSDRDAT(IGRID)%IPRSDR=>IPRSDR
        GWFSDRDAT(IGRID)%NPSDR=>NPSDR
        GWFSDRDAT(IGRID)%ISDRPB=>ISDRPB
        GWFSDRDAT(IGRID)%NNPSDR=>NNPSDR
        GWFSDRDAT(IGRID)%SDRAUX=>SDRAUX
        GWFSDRDAT(IGRID)%SDRR=>SDRR
C
      RETURN
      END
