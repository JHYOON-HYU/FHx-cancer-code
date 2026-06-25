libname a "path/to/authorized/NHIS/data"; 

/******************* Variables *******************/

proc sql;
create table temp as select *
from A.BR_GR_09_10 A left join A.CA_ALL_NODUP B
on A.INDI_DSCM_NO=B.INDI_DSCM_NO
order by INDI_DSCM_NO; quit;

proc sql;
create table A.BR_GR_09_10_ALL as select *
from temp A left join A.DTH B
on A.INDI_DSCM_NO=B.INDI_DSCM_NO
order by INDI_DSCM_NO; quit; 

data A.BR_GR_09_10_ALL; set A.BR_GR_09_10_ALL; 
Y1=substr(HME_DT,1,4); M1=substr(HME_DT,5,2); D1=substr(HME_DT,7,2);
HME_DT_1=mdy(M1, D1, Y1); 
format HME_DT_1 MMDDYY8.; 
drop Y1 M1 D1; run; 

data BR; set A.BR_GR_09_10_ALL; 
AGE_CA = YEAR(MDCARE_STRT_DT_CA) - BYEAR; 
AGE_HME=STD_YYYY - BYEAR; 

if CA=1 then FU_DT_1=MDCARE_STRT_DT_CA; else 
if CA=. then FU_DT_1=mdy("12", "31", "2020"); 

if  DTH_ASSMD_DT ne . then FU_DT_2=DTH_ASSMD_DT; else 
if DTH_ASSMD_DT=. then FU_DT_2=mdy("12", "31", "2020"); else
if DTH_ASSMD_DT>mdy("12", "31", "2020") then FU_DT_2=mdy("12", "31", "2020"); 

FU_DATE=min(FU_DT_1, FU_DT_2); 
format FU_DATE MMDDYY8.;
FU_DAY=FU_DATE-HME_DT_1; 
FU_YEAR=FU_DAY/356.25;
run;

data A.BR_GR_09_10_ALL; set BR; 
if  .<DTH_ASSMD_DT <= HME_DT_1 or .<DTH_ASSMD_DT <= MDCARE_STRT_DT_CA then delete; 
run; 


/******************* Definition of subjects *******************/

data A.SUBJECT; set A.BR_GR_09_10_ALL; 
if QC_PFHX_CST_I=2 or QC_PFHX_CBR_I=2 or QC_PFHX_CCR_I=2 or QC_PFHX_CLV_I=2 or QC_PFHX_CCX_I=2 or QC_PFHX_ETC_I=2 then delete; 
if CA=1 and .< MDCARE_STRT_DT_CA <= HME_DT_1 then delete; 
if FU_DAY <= 180 then delete; run;  
run;


data A.SUBJECT; set A.SUBJECT; 

/*Family history of cancer*/
if QC_PFHX_CST_PRT=2 or QC_PFHX_CST_BRT=2 or QC_PFHX_CST_SST=2 or QC_PFHX_CST_CDR=2 then FHX_GC_1=1; else FHX_GC_1=0;
if QC_PFHX_CBR_PRT=2 or QC_PFHX_CBR_BRT=2 or QC_PFHX_CBR_SST=2 or QC_PFHX_CBR_CDR=2 then FHX_BC_1=1; else FHX_BC_1=0;
if QC_PFHX_CCR_PRT=2 or QC_PFHX_CCR_BRT=2 or QC_PFHX_CCR_SST=2 or QC_PFHX_CCR_CDR=2 then FHX_CC_1=1; else FHX_CC_1=0;
if QC_PFHX_CLV_PRT=2 or QC_PFHX_CLV_BRT=2 or QC_PFHX_CLV_SST=2 or QC_PFHX_CLV_CDR=2 then FHX_LC_1=1; else FHX_LC_1=0;
if QC_PFHX_CCX_PRT=2 or QC_PFHX_CCX_BRT=2 or QC_PFHX_CCX_SST=2 or QC_PFHX_CCX_CDR=2 then FHX_CXC_1=1; else FHX_CXC_1=0;
if QC_PFHX_ETC_PRT=2 or QC_PFHX_ETC_BRT=2 or QC_PFHX_ETC_SST=2 or QC_PFHX_ETC_CDR=2 then FHX_ETC_1=1; else FHX_ETC_1=0;
if FHX_GC_1=1 or FHX_BC_1=1 or FHX_CC_1=1 or FHX_LC_1=1 or FHX_CXC_1=1 or FHX_ETC_1=1 then FHX_any=1; else FHX_any=0; 

/*BMI*/if G1E_BMI=. then BMI_2=999; else if G1E_BMI<23 then BMI_2=1; else if G1E_BMI<25 then BMI_2=2; else if G1E_BMI<27.5 then BMI_2=3; else BMI_2=4; 
/*Smoking*/if Q_SMK_YN=. then SMK_YN_1=999; else if Q_SMK_YN in (1) then SMK_YN_1=0; else if Q_SMK_YN in (2,3) then SMK_YN_1=1; 
/*Drinking*/if Q_DRK_FRQ_V09N=. then DRK_FRQ_1=999; else if Q_DRK_FRQ_V09N=0 then DRK_FRQ_1=0;  else if Q_DRK_FRQ_V09N=1 then DRK_FRQ_1=1; else DRK_FRQ_1=1;
/*Physical activity*/if Q_PA_VD=. and Q_PA_MD=. and Q_PA_WALK=. then exer_2=999; 
else if Q_PA_VD=0 and Q_PA_MD=0 and Q_PA_WALK=0  then exer_2=0;
else if Q_PA_VD>=1 then exer_2=3; 
else if Q_PA_MD>=1 then exer_2=2; 
else if Q_PA_WALK>=1 then exer_2=1; else exer_2=0;

/*Diseases*/
if Q_PHX_DX_STK=1 and Q_PHX_TX_STK=1 then STK=1; else STK=0;
if Q_PHX_DX_HTDZ=1 and Q_PHX_TX_HTDZ=1 then HTDZ=1; else HTDZ=0;
if Q_PHX_DX_HTN=1 and Q_PHX_TX_HTN=1 then HTN=1; else HTN=0;
if Q_PHX_DX_DM=1 and Q_PHX_TX_DM=1 then DM=1; else DM=0;
if Q_PHX_DX_DLD=1 and Q_PHX_TX_DLD then DLD=1; else DLD=0;

if CA=. then CA=0 ; 
if CA=1 then do; CA_TYPE_1=substr(SICK_SYM1,2,2)+0; end; 
if 10<=CA_TYPE_1 <=14 then CA_PHARYNX=1; else CA_PHARYNX=0;
if CA_TYPE_1=15 then CA_ESOPAHGUS=1; else CA_ESOPAHGUS=0;
if CA_TYPE_1=16 then CA_STOMACH=1; else CA_STOMACH=0;
if CA_TYPE_1 in (18,19) then CA_COLON=1; else CA_COLON=0;
if CA_TYPE_1=20 then CA_RECTUM=1; else CA_RECTUM=0; 
if CA_TYPE_1=22 then CA_LIVER=1; else CA_LIVER=0;
if CA_TYPE_1 in (23,24) then CA_GB=1; else CA_GB=0;
if CA_TYPE_1=25 then CA_PANCR=1; else CA_PANCR=0;
if CA_TYPE_1=32 then CA_LARYNX=1; else CA_LARYNX=0;
if CA_TYPE_1 in (33,34) then CA_LUNG=1; else CA_LUNG=0;
if CA_TYPE_1 =50 then CA_BREAST=1; else CA_BREAST=0;
if CA_TYPE_1 =53 then CA_CERVIX=1; else CA_CERVIX=0;
if CA_TYPE_1 =54 then CA_UTERUS=1; else CA_UTERUS=0;
if CA_TYPE_1 =56 then CA_OVARY=1; else CA_OVARY=0;
if CA_TYPE_1 =64 then CA_KIDNEY=1; else CA_KIDNEY=0;
if CA_TYPE_1 =67 then CA_BLADDER=1; else CA_BLADDER=0;
if CA_TYPE_1 in (70,71,72) then CA_BRAIN=1; else CA_BRAIN=0;
if CA_TYPE_1 =73 then CA_THYROID=1; else CA_THYROID=0;
if CA_TYPE_1 in (18,19,20) then CA_CRC=1; else CA_CRC=0; 

if CA_PHARYNX=. then CA_PHARYNX=0;
if CA_ESOPAHGUS=. then CA_ESOPAHGUS=0;
if CA_STOMACH=. then CA_STOMACH=0;
if CA_COLON=. then CA_COLON=0;
if CA_RECTUM=. then CA_RECTUM=0;
if CA_LIVER=. then CA_LIVER=0;
if CA_GB=. then CA_GB=0;
if CA_PANCR=. then CA_PANCR=0;
if CA_LARYNX=. then CA_LARYNX=0;
if CA_LUNG=. then CA_LUNG=0;
if CA_BREAST=. then CA_BREAST=0;
if CA_CERVIX=. then CA_CERVIX=0;
if CA_UTERUS=. then CA_UTERUS=0;
if CA_OVARY=. then CA_OVARY=0;
if CA_KIDNEY=. then CA_KIDNEY=0;
if CA_BLADDER=. then CA_BLADDER=0;
if CA_BRAIN=. then CA_BRAIN=0;
if CA_THYROID=. then CA_THYROID=0; 
run;


/************** Cox model **************/

%macro log_f1(a);
proc phreg data=A.SUBJECT; 
class BMI_2(ref='1') SMK_YN_1(ref='0') DRK_FRQ_1( ref='0') exer_2(ref='0') FHX_any(ref='0') STK(ref='0') HTDZ(ref='0') HTN(ref='0') DM(ref='0') DLD(ref='0')/param=ref;
model FU_YEAR*&a.(0)=FHX_any AGE_HME STK HTDZ HTN DM DLD BMI_2 SMK_YN_1 DRK_FRQ_1 exer_2/rl; run; 
%mend;
%log_f1(CA); %log_f1(CA_STOMACH); %log_f1(CA_CRC); %log_f1(CA_LIVER); %log_f1(CA_GB); %log_f1(CA_PANCR); %log_f1(CA_LARYNX); %log_f1(CA_LUNG);
%log_f1(CA_BREAST); %log_f1(CA_CERVIX); %log_f1(CA_UTERUS); %log_f1(CA_OVARY); %log_f1(CA_KIDNEY); %log_f1(CA_BLADDER); %log_f1(CA_BRAIN); %log_f1(CA_THYROID); %log_f1(CA_PHARYNX); %log_f1(CA_ESOPAHGUS);


/************** Concordant_discordant models **************/

/*Con & Dis cancer outcome*/
data A.SUBJECT; set A.SUBJECT; 
IF CA=1 & CA_STOMACH=1 THEN CST=1; ELSE IF CA=1 & CA_STOMACH=0 THEN CST=2; ELSE CST=0 ; *1: CON, 2: DIS, 0: NONE ;
IF CA=1 & (CA_COLON=1 OR CA_RECTUM=1) THEN CCR=1; ELSE IF CA=1 & CA_COLON=0 AND CA_RECTUM=0 THEN CCR=2; ELSE CCR=0 ;
IF CA=1 & CA_BREAST=1 THEN CBR=1; ELSE IF CA=1 & CA_BREAST=0 THEN CBR=2; ELSE CBR=0 ;
IF CA=1 & CA_LIVER=1 THEN CLV=1; ELSE IF CA=1 & CA_LIVER=0 THEN CLV=2; ELSE CLV=0 ;
IF CA=1 & CA_CERVIX=1 THEN CCX=1; ELSE IF CA=1 & CA_CERVIX=0 THEN CCX=2; ELSE CCX=0 ;
run;

%macro log_f2(outcome=, fhx=);
data temp_&outcome.; set A.SUBJECT;
event1=(&outcome.=1);
event2=(&outcome.=2);
run;

proc phreg data=temp_&outcome.; where &fhx.^=888; 
class BMI_2(ref='1') SMK_YN_1(ref='0') DRK_FRQ_1( ref='0') exer_2(ref='0') STK(ref='0') HTDZ(ref='0') HTN(ref='0') DM(ref='0') DLD(ref='0') &fhx(ref='0')/param=ref;
model FU_YEAR*event1(0)=&fhx. AGE_HME STK HTDZ HTN DM DLD BMI_2 SMK_YN_1 DRK_FRQ_1 exer_2/rl;
run;

proc phreg data=temp_&outcome.; where &fhx.^=888; 
class BMI_2(ref='1') SMK_YN_1(ref='0') DRK_FRQ_1( ref='0') exer_2(ref='0') STK(ref='0') HTDZ(ref='0') HTN(ref='0') DM(ref='0') DLD(ref='0') &fhx(ref='0')/param=ref;
model FU_YEAR*event2(0)=&fhx. AGE_HME STK HTDZ HTN DM DLD BMI_2 SMK_YN_1 DRK_FRQ_1 exer_2/rl;
run;
%mend;
%log_f2(outcome=CST, fhx=FHX_GC_2); 
%log_f2(outcome=CCR, fhx=FHX_CC_2); 
%log_f2(outcome=CBR, fhx=FHX_BC_2); 
%log_f2(outcome=CLV, fhx=FHX_LC_2); 
%log_f2(outcome=CCX, fhx=FHX_CXC_2); 

%macro log_t2(outcome=, fhx=);
proc freq data=A.SUBJECT; table &outcome.*&fhx.; run; 
%mend;
%log_t2(outcome=CST, fhx=FHX_GC_2); 
%log_t2(outcome=CCR, fhx=FHX_CC_2); 
%log_t2(outcome=CBR, fhx=FHX_BC_2); 
%log_t2(outcome=CLV, fhx=FHX_LC_2); 
%log_t2(outcome=CCX, fhx=FHX_CXC_2); 


/************** Figure 1 **************/

%macro log_f2(a,b);
proc phreg data=A.SUBJECT; where &a^=888; 
class BMI_2(ref='1') SMK_YN_1(ref='0') DRK_FRQ_1( ref='0') exer_2(ref='0')  STK(ref='0') HTDZ(ref='0') HTN(ref='0') DM(ref='0') DLD(ref='0') &a(ref='0')/param=ref;
model FU_YEAR*&b.(0)= &a AGE_HME STK HTDZ HTN DM DLD BMI_2 SMK_YN_1 DRK_FRQ_1 exer_2/rl; run; 
%mend;
*gastric cancer fam;
%log_f2(FHX_GC_2, CA); %log_f2(FHX_GC_2,CA_STOMACH); %log_f2(FHX_GC_2,CA_CRC); %log_f2(FHX_GC_2,CA_LIVER); %log_f2(FHX_GC_2,CA_GB); %log_f2(FHX_GC_2,CA_PANCR);
%log_f2(FHX_GC_2,CA_LARYNX); %log_f2(FHX_GC_2,CA_LUNG); %log_f2(FHX_GC_2,CA_BREAST); %log_f2(FHX_GC_2,CA_CERVIX); %log_f2(FHX_GC_2,CA_UTERUS); 
%log_f2(FHX_GC_2,CA_OVARY); %log_f2(FHX_GC_2,CA_KIDNEY); %log_f2(FHX_GC_2,CA_BLADDER); %log_f2(FHX_GC_2,CA_BRAIN); %log_f2(FHX_GC_2,CA_THYROID); 
%log_f2(FHX_GC_2,CA_PHARYNX); %log_f2(FHX_GC_2,CA_ESOPAHGUS); 
*colorectal fam;
%log_f2(FHX_CC_2, CA); %log_f2(FHX_CC_2,CA_STOMACH); %log_f2(FHX_CC_2,CA_CRC); %log_f2(FHX_CC_2,CA_LIVER); %log_f2(FHX_CC_2,CA_GB); %log_f2(FHX_CC_2,CA_PANCR);
%log_f2(FHX_CC_2,CA_LARYNX); %log_f2(FHX_CC_2,CA_LUNG); %log_f2(FHX_CC_2,CA_BREAST); %log_f2(FHX_CC_2,CA_CERVIX); %log_f2(FHX_CC_2,CA_UTERUS); 
%log_f2(FHX_CC_2,CA_OVARY); %log_f2(FHX_CC_2,CA_KIDNEY); %log_f2(FHX_CC_2,CA_BLADDER); %log_f2(FHX_CC_2,CA_BRAIN); %log_f2(FHX_CC_2,CA_THYROID); 
%log_f2(FHX_CC_2,CA_PHARYNX); %log_f2(FHX_CC_2,CA_ESOPAHGUS); 
*breast fam;
%log_f2(FHX_BC_2, CA); %log_f2(FHX_BC_2,CA_STOMACH); %log_f2(FHX_BC_2,CA_CRC); %log_f2(FHX_BC_2,CA_LIVER); %log_f2(FHX_BC_2,CA_GB); %log_f2(FHX_BC_2,CA_PANCR);
%log_f2(FHX_BC_2,CA_LARYNX); %log_f2(FHX_BC_2,CA_LUNG); %log_f2(FHX_BC_2,CA_BREAST); %log_f2(FHX_BC_2,CA_CERVIX); %log_f2(FHX_BC_2,CA_UTERUS); 
%log_f2(FHX_BC_2,CA_OVARY); %log_f2(FHX_BC_2,CA_KIDNEY); %log_f2(FHX_BC_2,CA_BLADDER); %log_f2(FHX_BC_2,CA_BRAIN); %log_f2(FHX_BC_2,CA_THYROID); 
%log_f2(FHX_BC_2,CA_PHARYNX); %log_f2(FHX_BC_2,CA_ESOPAHGUS); 
*liver fam;
%log_f2(FHX_LC_2, CA); %log_f2(FHX_LC_2,CA_STOMACH); %log_f2(FHX_LC_2,CA_CRC); %log_f2(FHX_LC_2,CA_LIVER); %log_f2(FHX_LC_2,CA_GB); %log_f2(FHX_LC_2,CA_PANCR);
%log_f2(FHX_LC_2,CA_LARYNX); %log_f2(FHX_LC_2,CA_LUNG); %log_f2(FHX_LC_2,CA_BREAST); %log_f2(FHX_LC_2,CA_CERVIX); %log_f2(FHX_LC_2,CA_UTERUS); 
%log_f2(FHX_LC_2,CA_OVARY); %log_f2(FHX_LC_2,CA_KIDNEY); %log_f2(FHX_LC_2,CA_BLADDER); %log_f2(FHX_LC_2,CA_BRAIN); %log_f2(FHX_LC_2,CA_THYROID); 
%log_f2(FHX_LC_2,CA_PHARYNX); %log_f2(FHX_LC_2,CA_ESOPAHGUS); 
*cervix fam;
%log_f2(FHX_CXC_2, CA); %log_f2(FHX_CXC_2,CA_STOMACH); %log_f2(FHX_CXC_2,CA_CRC); %log_f2(FHX_CXC_2,CA_LIVER); %log_f2(FHX_CXC_2,CA_GB); %log_f2(FHX_CXC_2,CA_PANCR);
%log_f2(FHX_CXC_2,CA_LARYNX); %log_f2(FHX_CXC_2,CA_LUNG); %log_f2(FHX_CXC_2,CA_BREAST); %log_f2(FHX_CXC_2,CA_CERVIX); %log_f2(FHX_CXC_2,CA_UTERUS); 
%log_f2(FHX_CXC_2,CA_OVARY); %log_f2(FHX_CXC_2,CA_KIDNEY); %log_f2(FHX_CXC_2,CA_BLADDER); %log_f2(FHX_CXC_2,CA_BRAIN); %log_f2(FHX_CXC_2,CA_THYROID); 
%log_f2(FHX_CXC_2,CA_PHARYNX); %log_f2(FHX_CXC_2,CA_ESOPAHGUS); 



/************** Incidence rate **************/

%macro IR(event=, label=);
proc sql;
create table IR_&event. as select "&label." as ca_site length=50, FHX_any, count(*) as N, sum(&event.) as case, sum(FU_YEAR) as PY, calculated case/calculated PY*100000 as inci_rate
from A.SUBJECT
group by FHX_any;
quit;

data IR_&event.; set IR_&event.;
if case>0 then do;
lower_ci=(case-1.96*sqrt(case))/PY*100000;
upper_ci=(case+1.96*sqrt(case))/PY*100000;
end; 
else do;
lower_ci=0;
upper_ci=.;
end;

lower_ci=max(0, lower_ci);
format inci_rate lower_ci upper_ci 8.2;
run;
%mend;
%IR(event=CA, label=CA); %IR(event=CA_STOMACH, label=CA_STOMACH); %IR(event=CA_CRC, label=CA_CRC); %IR(event=CA_LIVER, label=CA_LIVER); 
%IR(event=CA_GB, label=CA_GB); %IR(event=CA_PANCR, label=CA_PANCR); %IR(event=CA_LARYNX, label=CA_LARYNX); %IR(event=CA_LUNG, label=CA_LUNG);
%IR(event=CA_BREAST, label=CA_BREAST); %IR(event=CA_CERVIX, label=CA_CERVIX); %IR(event=CA_UTERUS, label=CA_UTERUS); %IR(event=CA_OVARY, label=CA_OVARY); 
%IR(event=CA_KIDNEY, label=CA_KIDNEY); %IR(event=CA_BLADDER, label=CA_BLADDER); %IR(event=CA_BRAIN, label=CA_BRAIN); %IR(event=CA_THYROID, label=CA_THYROID);
%IR(event=CA_PHARYNX, label=CA_PHARYNX); %IR(event=CA_ESOPAHGUS, label=CA_ESOPAHGUS);

data IR_ALL; set IR_CA IR_CA_STOMACH IR_CA_CRC IR_CA_LIVER IR_CA_GB IR_CA_PANCR IR_CA_LARYNX IR_CA_LUNG
 IR_CA_BREAST IR_CA_CERVIX IR_CA_UTERUS IR_CA_OVARY IR_CA_KIDNEY IR_CA_BLADDER IR_CA_BRAIN IR_CA_THYROID IR_CA_PHARYNX IR_CA_ESOPAHGUS;
 run;
proc print data=IR_ALL noobs; run;

proc sort data=IR_ALL; by ca_site; run;
proc transpose data=IR_ALL out=case_wide prefix=case_;
by ca_site; id FHX_any; var case; run; 
proc transpose data=IR_ALL out=PY_wide prefix=PY_;
by ca_site; id FHX_any; var PY; run; 
proc transpose data=IR_ALL out=IR_wide prefix=IR_;
by ca_site; id FHX_any; var inci_rate; run; 
proc transpose data=IR_ALL out=LCI_wide prefix=LCI_;
by ca_site; id FHX_any; var lower_ci; run; 
proc transpose data=IR_ALL out=UCI_wide prefix=UCI_;
by ca_site; id FHX_any; var upper_ci; run; 

data IR_diff; merge case_wide PY_wide IR_wide LCI_wide UCI_wide; by ca_site;
rate_diff=IR_1-IR_0;
se_diff=100000*sqrt((case_1/(py_1**2))+(case_0/(py_0**2)));
lower_ci=rate_diff-1.96*se_diff;
upper_ci=rate_diff+1.96*se_diff;

ir_0_ci=cats(put(ir_0, 8.2), "(", put(lci_0, 8.2), "-", put(uci_0,8.2),")");
ir_1_ci=cats(put(ir_1, 8.2), "(", put(lci_1, 8.2), "-", put(uci_1,8.2),")");
rate_diff_ci=cats(put(rate_diff, 8.2), "(", put(lower_ci, 8.2), "-", put(upper_ci,8.2),")");
run; 
proc print data=IR_diff noobs label;
var ca_site ir_0_ci ir_1_ci rate_diff_ci; 
run;
