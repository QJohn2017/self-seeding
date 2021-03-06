clc;clear
close all

snum = 51;
R56 = 100;
filter = 3;

mainfold = ['genesis/XLBEG1_ssnum_',num2str(snum),'_chicane_',num2str(R56),'_filter_',num2str(filter)];
Nu1 = 7;
aw0_1 = 2.56;
taper_coef1 = [15,15,15,15,15]*1e-4;
taper1_scan5 = taper_coef1;
taper1_scan3 = taper_coef1;
taper1_scan4 = taper_coef1;
taper1_scan12 = taper_coef1;
taper1_scan6 = taper_coef1;
taper1_scan7 = taper_coef1;
taper1_scan8 = taper_coef1;
taper_jump1 = [0,0,0,0,0,0,0,0];
taper_Nu1 = [taper1_scan12;taper1_scan12;taper1_scan3;taper1_scan4;taper1_scan5;taper1_scan6;taper1_scan7;taper1_scan8];

Nu2 = 7;
aw0_2 = 2.5;
taper_coef2 = [-20,-17.5,-15,-12.5,-10]*1e-4;
taper2_scan5 = taper_coef2;
taper2_scan3 = taper_coef2;
taper2_scan4 = taper_coef2;
taper2_scan12 = taper_coef2;
taper2_scan6 = taper_coef2;
taper2_scan7 = taper_coef2;
taper2_scan8 = 0.00*ones(size(taper2_scan12));
taper_jump2 = [0,0,0,0,0,0,0,0];
taper_Nu2 = [taper2_scan12;taper2_scan12;taper2_scan3;taper2_scan4;taper2_scan5;taper2_scan6;taper2_scan7;taper2_scan8];


xlambda = 1.1698e-09*(1-0.035)*(1+0.05);
Nshot = 10;
Nund = 110;
Nsec = 115;
nslice = 5000;
lambdu = 3e-2;
phaseshifter = 1;
idump = 0;
zstop = 50;
constseed = 1;
comemnts = 'S2E simulation. two sections together';


logfile = [mainfold,'/scan_log'];

fidpara = fopen(logfile,'a+');
fprintf(fidpara,'---------------------------\n');
fprintf(fidpara,comemnts);
fprintf(fidpara,'\n');
fprintf(fidpara,'---------------------------\n\n\n');
fclose(fidpara);

distfilename = '../beam_core_match.dist';

for itaper_scan = 1:length(taper1_scan12)
    system('kinit -R');
    for ishot = 1:Nshot
        ssnum = 1;
        
        [~,dirQ] = system(['ls ',mainfold]);
        if isempty(dirQ)
            ssnum = 1;
        else
            while 1
                fileQ = strfind(dirQ,['s',num2str(ssnum),' ']);
                if ~isempty(fileQ)
                    ssnum = ssnum + 1;
                else
                    break;
                end
            end
        end
        
        while exist([mainfold,'/s',num2str(ssnum)],'dir')
            ssnum = ssnum + 1;
        end
        
        foldname = [mainfold,'/s',num2str(ssnum)];
        
        while 1
            [sub_bullet,sub_oak] = check_cluster2(1);
            if sub_bullet || sub_oak
                break;
            else
                pause(20);
            end
        end
        system(['mkdir ',foldname]);
        if constseed
            pr = primes(ishot*5988);
            ipseed = pr(end);
        else
            ipseed = ssnum*1121;
        end
        
        filename = [foldname,'/lclsTAP.lat'];
        aw = zeros((Nu1+Nu2)*Nund,3);
        for ii = 1:Nu1
            for jj = 1:Nund
                if (ii-1)*Nsec+jj == 1
                    aw(1,1) = aw0_1+taper_jump1(ii);
                    aw(1,2) = 1;
                    aw(1,3) = 10;
                else
                    if jj == 1
                        aw((ii-1)*Nund+1,:) = [aw((ii-1)*Nund,1)+taper_jump1(ii)+taper_Nu1(ii,itaper_scan)*lambdu*(Nsec-Nund+1),1,0];
                    else
                        aw((ii-1)*Nund+jj,:) = [aw((ii-1)*Nund+jj-1,1)+taper_Nu1(ii,itaper_scan)*lambdu,1,0];
                    end
                end
            end
            aw((ii-1)*Nund+1,3) = (Nsec-Nund);
        end
        aw(1,3) = 10;
        
        for ii = 1:Nu2
            for jj = 1:Nund
                if (ii-1)*Nsec+jj == 1
                    aw(Nu1*Nund+1,1) = aw0_2+taper_jump2(ii);
                    aw(Nu1*Nund+1,2) = 1;
                    aw(Nu1*Nund+1,3) = (Nsec-Nund);
                else
                    if jj == 1
                        aw(Nu1*Nund+(ii-1)*Nund+1,:) = [aw(Nu1*Nund+(ii-1)*Nund,1)+taper_jump2(ii)+taper_Nu2(ii,itaper_scan)*lambdu*(Nsec-Nund+1),1,0];
                    else
                        aw(Nu1*Nund+(ii-1)*Nund+jj,:) = [aw(Nu1*Nund+(ii-1)*Nund+jj-1,1)+taper_Nu2(ii,itaper_scan)*lambdu,1,0];
                    end
                end
            end
            aw(Nu1*Nund+(ii-1)*Nund+1,3) = (Nsec-Nund);
        end
        
        
        QF1 = 12.84; QF2 = -12.64;
        
        fid = fopen(filename,'w+');
        fprintf(fid, '? VERSION = 1.0\n');
        fprintf(fid, '? UNITLENGTH = %3.6E\n\n', lambdu);
        fprintf(fid, 'AW\t  %3.6E\t %d\t %d\n', aw');
        fprintf(fid,'\n\n\n');
        fprintf(fid,'QF\t  %3.4f\t %d\t %d\n',QF1,5,0);
        for ii = 1:(Nu1+Nu1+1)
            if mod(ii,2) > 0.1
                fprintf(fid,'QF\t  %3.4f\t %d\t %d\n',QF2,10,120);
            else
                fprintf(fid,'QF\t  %3.4f\t %d\t %d\n',QF1,10,120);
            end
        end
        
        
        fprintf(fid,'\n\n\n');
        fprintf(fid,'AD\t %3.6E\t %d\t %d\n',2.5,10,0);
        for ii = 1:Nu1
            for jj = 1:(Nsec-Nund)
                if jj == 1
                    AWD = aw((ii-1)*Nund+Nund,1)+taper_Nu1(ii,itaper_scan)*lambdu;
                    fprintf(fid,'AD\t %3.6E\t %d\t %d\n',AWD*phaseshifter,1,Nund);
                else
                    AWD = AWD+taper_Nu1(ii,itaper_scan)*lambdu;
                    fprintf(fid,'AD\t %3.6E\t %d\t %d\n',AWD*phaseshifter,1,0);
                end
            end 
        end
        
        for ii = 1:Nu2
            for jj = 1:(Nsec-Nund)
                if jj == 1
                    AWD = aw(Nu1*Nund+(ii-1)*Nund+Nund,1)+taper_Nu2(ii,itaper_scan)*lambdu;
                    fprintf(fid,'AD\t %3.6E\t %d\t %d\n',AWD*phaseshifter,1,Nund);
                else
                    AWD = AWD+taper_Nu2(ii,itaper_scan)*lambdu;
                    fprintf(fid,'AD\t %3.6E\t %d\t %d\n',AWD*phaseshifter,1,0);
                end
            end
        end
        fclose(fid);
        
        [A,Nline] = read_file('genesis.in');
        for ii = 1:Nline
            A{ii} = strrep(A{ii},'$zstop$',num2str(zstop));
            A{ii} = strrep(A{ii},'$distfile$',distfilename);
            A{ii} = strrep(A{ii},'$maginfile$','lclsTAP.lat');
            A{ii} = strrep(A{ii},'$outputfile$','genesis.out');
            A{ii} = strrep(A{ii},'$magoutfile$','magoutfile.lat');
            A{ii} = strrep(A{ii},'$ipseed$',num2str(ipseed));
            A{ii} = strrep(A{ii},'$nslice$',num2str(nslice));
            A{ii} = strrep(A{ii},'$idump$',num2str(idump));
            A{ii} = strrep(A{ii},'$xlamds$',num2str(xlambda,'%1.5e'));
        end
        filename2 = [foldname,'/genesis.in'];
        write_file(A,Nline,filename2);
        
        
        
        fidpara = fopen(logfile,'a+');
        fprintf(fidpara,'Scan Number:\t   %d\n',ssnum);
        fprintf(fidpara,'---------------------------\n');
        fprintf(fidpara,'Nu1\t   %d\n',Nu1);
        fprintf(fidpara,'Nu1\t   %d\n',Nu2);
        fprintf(fidpara,'Nsec\t   %d\n',Nsec);
        fprintf(fidpara,'Nund\t   %d\n',Nund);
        fprintf(fidpara,'aw0_1\t   %1.4f\n',aw0_1);
        fprintf(fidpara,'aw0_1\t   %1.4f\n',aw0_2);
        for ii = 1:Nu1
            fprintf(fidpara,'taper1_scan\t   %1.6f\n',taper_Nu1(ii,itaper_scan));
        end
        for ii = 1:Nu2
            fprintf(fidpara,'taper2_scan\t   %1.6f\n',taper_Nu2(ii,itaper_scan));
        end
        fprintf(fidpara,'phaseshifter\t   %1.4f\n',phaseshifter);
        fprintf(fidpara,'ipseed\t   %d\n',ipseed);
        
        fprintf(fidpara,'QF1\t   %1.4f\n',QF1);
        fprintf(fidpara,'QF2\t   %1.4f\n',QF2);
        
        fprintf(fidpara,'---------------------------\n\n\n');
        fclose(fidpara);
        
        
        fidpara2 = fopen([foldname,'/locallog'],'a+');
        fprintf(fidpara2,'%d\n',Nu1);
        fprintf(fidpara2,'%d\n',Nu2);
        fprintf(fidpara2,'%d\n',Nsec);
        fprintf(fidpara2,'%d\n',Nund);
        fprintf(fidpara2,'%1.4f\n',aw0_1);
        fprintf(fidpara2,'%1.4f\n',aw0_2);
        for ii = 1:Nu1
            fprintf(fidpara2,'%1.6f\n',taper_Nu1(ii,itaper_scan));
        end
        for ii = 1:Nu1
            fprintf(fidpara2,'%1.6f\n',taper_jump1(ii));
        end
        for ii = 1:Nu2
            fprintf(fidpara2,'%1.6f\n',taper_Nu2(ii,itaper_scan));
        end
        for ii = 1:Nu2
            fprintf(fidpara2,'%1.6f\n',taper_jump2(ii));
        end
        fprintf(fidpara2,'%1.4f\n',phaseshifter);
        fprintf(fidpara2,'%d\n',ipseed);
        fclose(fidpara2);
        
        
        timenow = clock;
        if sub_bullet
            disp([num2str(timenow(4),'%d'),':',num2str(timenow(5),'%d'),':',num2str(round(timenow(6)),'%d'),': submit jobs to bullet...'])
            disp(['ssnum = ',num2str(ssnum)]);
            [~,b] = bsub_bullet_local(foldname,128,'genesis.in');
            disp(b)
        end
        if sub_oak
            disp([num2str(timenow(4),'%d'),':',num2str(timenow(5),'%d'),':',num2str(round(timenow(6)),'%d'),': submit jobs to oak...'])
            disp(['ssnum = ',num2str(ssnum)]);
            [~,b] = bsub_oak_local(foldname,128,'genesis.in');
            disp(b)
        end
        pause(20);
        
        
    end
end




