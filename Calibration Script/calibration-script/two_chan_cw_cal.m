%controls sig gen and power meter to run calibration
function[cal,gain,psd_f,traces]=two_chan_cw_cal(server,instrument,siggen1,siggen2,cw_pwr,ports,LO_f,amplifier_gain_db)

%cw_pwr is a power reading
pkg load sockets

pwr_db = -10;
%pwr_db = -25;

sataddr = server.addr
power_db_mat = [];

%set up sockets, shall we use socket for satdsp?
siggen_s1=socket
siggen_s2=socket
connect(siggen_s1,siggen1);
connect(siggen_s2,siggen2);

send(siggen_s1,"*IDN?\n")
char(recv(siggen_s1,100))

send(siggen_s2,"*IDN?\n")
char(recv(siggen_s2,100))


%query the serial number and create directory to save data
%csv output for easy parsing
[reply status]=urlread([ sataddr '/sparql'],'get',{'format','csv','query'," \
	prefix :<http://www.sat.com/2014/db#> \
	select * where{ \
		<#current> :serial ?s . \
	}"});
[a b c d]=regexp(reply,'\d+'); % input numbers
cal.sn=sscanf(d{1},'%i');    %first match
cal.t=time;
cal.cal_loc=1; %COS
cal.LO_f=LO_f;
cal.amplifier_gain_db=amplifier_gain_db;
%create work directory
mkdir(sprintf('cw_cal_%i',cal.sn)); % attach calibration to serial number

%set up the spectrum
%duration=0.003;
duration=0.005;
%rbw=60e6/256;
rbw=60e6/4096;

% bw
% cf - calibration frequency
% duration
% attenuation
% rbw
% vbw
% window
% prints to system the instrument serial number, durationm rbw, frequency

[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
	prefix :<http://www.sat.com/2011/measure#>\
	insert data{\
		<#%s> :bw \"54e6\";:cf \".8e9\";:duration %f;:attenuation 0 .\
		<#_11a> :rbw %f;:vbw %f;:window <#flattop> .\
	}",instrument,duration,rbw,1/duration)})
traces_ch1=[];
gain_ch_1=[];
traces_ch2=[];
gain_ch_2=[];

% DC OFFSET
offset=1.0e6;

%for p=ports

	%%printf("Pausing... Install inject cable on port #%d\n",p);
	%%yes_or_no();

	%% Prime by setting to port #1...
	[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
		prefix :<http://www.sat.com/2011/measure#>\
		insert data{\
				<#%s> :port <#RX1> .\
			}",instrument)});
			
			
	for g=amplifier_gain_db

		%% Set gain and DC offset tracking...
		[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
			prefix :<http://www.sat.com/2011/measure#>\
			insert data{\
				<#s> :gain %i;:attenuation 0;:dc_tracking 1;:dc_offset 0 .\
			}",g)});

        % adjusting gain g in a loop
        % #%s compared to #s?????

		_gain_ch_1=[];
		_gain_ch_2=[];

		pwr_db = -10-g;
		%pwr_db = -25-g;	% Set up the power at the ADC so that it's roughly constant...
							%  Gain goes up... Power goes down... 
		power_db_mat = [power_db_mat; pwr_db] 	

		
		% Set up both Signal Generators
		send(siggen_s1,sprintf(":FREQ %f Hz\n", LO_f(1)));  % Set starting frequency... 
		send(siggen_s1,sprintf(":POW:LEV:IMM:AMPL %f dBm\n", pwr_db));

		send(siggen_s2,sprintf(":FREQ %f Hz\n", LO_f(1)));  % Set starting frequency... 
		send(siggen_s2,sprintf(":POW:LEV:IMM:AMPL %f dBm\n", pwr_db));

				
		for f=LO_f
			%%ff=min(cw_pwr.freq(end),f);% so no need to extrapolate
			%%pwr=interp1(cw_pwr.freq,10.^(cw_pwr.pwr_db/10),ff);	
			
			pwr = 10^(pwr_db/10);
			
			send(siggen_s1,sprintf(":FREQ %f Hz\n",f));
			send(siggen_s2,sprintf(":FREQ %f Hz\n",f));
			

			% Sample Port #1
			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :port <#RX1> .\
				}",instrument)});

            % SPARQl selects R1 port

			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :cf \"%f\";:command :acquire,:get_spectrum .\
				}",instrument,f+offset)});

            % f is set in
				
			%load spectrum
			spectrum=sprintf('cw_cal_%i/dump.mat',cal.sn);
			urlwrite(sprintf('%s/r/_11a',sataddr),spectrum);%URI should not be hard-coded
			psd=load(spectrum);
			traces_ch1=[traces_ch1 psd.x];
			psd_f=psd.f;			% all f are the same
			_g1=max(psd.x)*rbw/pwr; 
			_g1 = _g1;
			_gain_ch_1=[_gain_ch_1;_g1];
			
			% Sample Port 2
			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :port <#RX2> .\
				}",instrument)});

            % select channel 2

			[reply status]=urlread([sataddr '/sparql'],'get',{'query',sprintf("\
				prefix :<http://www.sat.com/2011/measure#>\
				insert data{\
					<#%s> :cf \"%f\";:command :acquire,:get_spectrum .\
				}",instrument,f+offset)});

            % adjust the offset


			%load spectrum
			spectrum=sprintf('cw_cal_%i/dump.mat',cal.sn);
			urlwrite(sprintf('%s/r/_11a',sataddr),spectrum);%URI should not be hard-coded
			psd=load(spectrum);
			traces_ch2=[traces_ch2 psd.x];
			psd_f=psd.f;			% all f are the same
			_g2=max(psd.x)*rbw/pwr; 
			_g2 = _g2;
			_gain_ch_2=[_gain_ch_2;_g2];
			
			
			
			
		end
		% Not a fan of the underscored variables... /jw
        % UPDATE TO COME

		gain_ch_1=[gain_ch_1 (_gain_ch_1)];
		gain_ch_2=[gain_ch_2 (_gain_ch_2)];
	end

%end


% Safe both signal generators
send(siggen_s1,sprintf(":POW:LEV:IMM:AMPL -99 dBm\n"));
send(siggen_s1,":OUTPUT OFF\n");

send(siggen_s2,sprintf(":POW:LEV:IMM:AMPL -99 dBm\n"));
send(siggen_s2,":OUTPUT OFF\n");


disconnect(siggen_s1);
disconnect(siggen_s2);

%do some padding if only one port calibrated
if(length(ports)==1)
	if(ports==1)
		gain=[gain ones(size(gain))];
	else
		gain=[ones(size(gain)) gain];
	end
end
cal.gain_db=[10*log10(gain_ch_1) 10*log10(gain_ch_2)];

% do this manually... pull out power to get insertion loss... 
% We will unplug it then...

	
