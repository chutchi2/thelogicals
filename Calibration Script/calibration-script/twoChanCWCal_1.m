%controls sig gen and power meter to run calibration
function[cal,gain,psd_f,traces]=twoChanCWCal(server,instrument,siggen1,siggen2,cwPwr,ports,LO_f,amplifierGainDB)

%cwPwr is a power reading
pkg load sockets

pwrDB = -10;
%pwrDB = -25;

% connects to the signal generator and opens
%%
%%
% add actual IP address * TODO *
%SG1 = visa('agilent','TCPIP::10.50.228.107::INSTR');
%SG2 = visa('agilent','TCPIP::10.50.228.107::INSTR');
%fopen(SG1);
%fopen(SG2);

sataddr = server.addr
powerDBMat = [];

%set up sockets, shall we use socket for satdsp?
% 
siggenS1=socket
siggenS2=socket
connect(siggenS1,siggen1);
connect(siggenS2,siggen2);

send(siggenS1,"*IDN?\n")
char(recv(siggenS1,100))

send(siggenS2,"*IDN?\n")
char(recv(siggenS2,100))


% query the serial number and create directory to save data
% csv output for easy parsing
cal.sn=sscanf(':FORMat:DATA? ! Query','%i');

cal.t=time;
cal.cal_loc=1; %COS
cal.LO_f=LO_f;
cal.amplifierGainDB=amplifierGainDB;

%create work directory
mkdir(sprintf('cw_cal_%i',cal.sn)); % attach calibration to serial number
% formats output
fprintf(siggenS1, 'MMEMory:STORe:DATA "cw_cal_%i","CSV Formatted Data","Trace","Displayed",-1');

%[reply status]=urlread([ sataddr '/sparql'],'get',{'format','csv','query'," \
%	prefix :<http://www.sat.com/2014/db#> \
%	select * where{ \
%		<#current> :serial ?s . \
%	}"});
%[a b c d]=regexp(reply,'\d+'); % input numbers
%cal.sn=sscanf(d{1},'%i');    %first match


%set up the spectrum
%duration=0.003;
duration=0.005;
%rbw=60e6/256;
rbw=60e6/4096;

% bw - bandwidth 
% cf => calibration frequency?
% duration
% attenuation
% rbw - resolution band width
% vbw
% window
% prints to system the instrument serial number, durationm rbw, frequency

% new scpi query for instrument data, instrument, duration, rbw, frequency
% set the siggen1 
fprintf(siggenS1,'*RST');%Reset the function generator
fprintf(siggenS1,'FUNCtion SINusoid');%Select waveshape
fprintf(siggenS1,' [:SENSe]:BANDwidth|BWIDth[:RESolution] 54e6 ');%Set the bandwidth
%May also be INFinity, as when using oscilloscope or DMM
fprintf(siggenS1,'FREQuency: 850e6');%Set the frequency to 850MHz
fprintf(siggenS1, ' :CAPTure[1]:DURAtion:TIME .005')
%fprintf(SG1,'VOLTage 1');%Set the amplitude to 1 Vpp
fprintf(siggenS1,'OUTPut ON');%Turn on the instrument output

%[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
%	prefix :<http://www.sat.com/2011/measure#>\
%	insert data{\
%		<#%s> :bw \"54e6\";:cf \".8e9\";:duration %f;:attenuation 0 .\
%		<#_11a> :rbw %f;:vbw %f;:window <#flattop> .\
%	}",instrument,duration,rbw,1/duration)})
tracesCh1=[];
gainCh1=[];
tracesCh2=[];
gainCh2=[];

% DC OFFSET
offset=1.0e6;

%for p=ports

	%%printf("Pausing... Install inject cable on port #%d\n",p);
	%%yes_or_no();
  %fprintf('SOURce

	%% Prime by setting to port #1...
  sprintf(siggenS1, ':SENS1:CORR:COLL:METH:SOLT1 1');
  
	%[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
	%	prefix :<http://www.sat.com/2011/measure#>\
	%	insert data{\
	%			<#%s> :port <#RX1> .\
	%		}",instrument)});
			
			
	for g=amplifierGainDB
  %% Set gain and DC offset tracking...
  dc_offset = fprintf(siggenS1, ':DIGital:DATA:IOFFset 0');
  %dc_tracking = 
  attenuation = fprintf(siggenS1, 'INP:ATT 0');
  


	%	[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
	%		prefix :<http://www.sat.com/2011/measure#>\
	%		insert data{\
	%			<#s> :gain %i;:attenuation 0;:dc_tracking 1;:dc_offset 0 .\
	%		}",g)});

        % adjusting gain g in a loop
        % #%s compared to #s?????

		_gainCh1=[];
		_gainCh2=[];

		pwrDB = -10-g;
		%pwrDB = -25-g;	% Set up the power at the ADC so that it's roughly constant...
							%  Gain goes up... Power goes down... 
		powerDBMat = [powerDBMmat; pwrDB]

		
		% Set up both Signal Generators
		send(siggenS1,sprintf(":FREQ %f Hz\n", LO_f(1)));  % Set starting frequency...
		send(siggenS1,sprintf(":POW:LEV:IMM:AMPL %f dBm\n", pwrDB));

		send(siggenS2,sprintf(":FREQ %f Hz\n", LO_f(1)));  % Set starting frequency...
		send(siggenS2,sprintf(":POW:LEV:IMM:AMPL %f dBm\n", pwrDB));

				
		for f=LO_f
			%%ff=min(cwPwr.freq(end),f);% so no need to extrapolate
			%%pwr=interp1(cwPwr.freq,10.^(cwPwr.pwrDB/10),ff);
			
			pwr = 10^(pwrDB/10);
			
			send(siggenS1,sprintf(":FREQ %f Hz\n",f));
			send(siggenS2,sprintf(":FREQ %f Hz\n",f));
			

			% Sample Port #1
      %% what is being sampled? What needs to be documented??
      
			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :port <#RX1> .\
				}",instrument)});

            % SPARQl selects R1 port
            % reads from port 1

			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :cf \"%f\";:command :acquire,:get_spectrum .\
				}",instrument,f+offset)});

            % f is set in
				
			%load spectrum data to directory

			spectrum=sprintf('cw_cal_%i/dump.mat',cal.sn);
			urlwrite(sprintf('%s/r/_11a',sataddr),spectrum);%URI should not be hard-coded
			psd=load(spectrum);
			traces_ch1=[traces_ch1 psd.x];
			psd_f=psd.f;			% all f are the same
			_g1=max(psd.x)*rbw/pwr; 
			_g1 = _g1;
			_gainCh1=[_gainCh1;_g1];
			
			% Sample Port 2
			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :port <#RX2> .\
				}",instrument)});

            % select channel 2
            % what info is being sampled from channel 2?

			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :cf \"%f\";:command :acquire,:get_spectrum .\
				}",instrument,f+offset)});

            % adjust the offset


			% load spectrum
			spectrum=sprintf('cw_cal_%i/dump.mat',cal.sn);
			urlwrite(sprintf('%s/r/_11a',sataddr),spectrum);%URI should not be hard-coded
			psd=load(spectrum);
			traces_ch2=[traces_ch2 psd.x];
			psd_f=psd.f;			% all f are the same
			_g2=max(psd.x)*rbw/pwr; 
			_g2 = _g2;
			_gainCh2=[_gainCh2;_g2];
			
			
			
			
		end

		gainCh1=[gainCh1 (_gainCh1)];
		gainCh2=[gainCh2 (_gainCh2)];
	end

%end


% Safe both signal generators
send(siggenS1,sprintf(":POW:LEV:IMM:AMPL -99 dBm\n"));
send(siggenS1,":OUTPUT OFF\n");

send(siggenS2,sprintf(":POW:LEV:IMM:AMPL -99 dBm\n"));
send(siggenS2,":OUTPUT OFF\n");


disconnect(siggenS1);
disconnect(siggenS2);

%do some padding if only one port calibrated
if(length(ports)==1)
	if(ports==1)
		gain=[gain ones(size(gain))];
	else
		gain=[ones(size(gain)) gain];
	end
end
cal.gainDB=[10*log10(gainCh1) 10*log10(gainCh2)];

% do this manually... pull out power to get insertion loss... 
% We will unplug it then...

	
