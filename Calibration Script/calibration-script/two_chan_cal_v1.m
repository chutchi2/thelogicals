
%clear all   % homicidal clear!

more off

% Grab the current license and public.pem file from the Saturn box... 

printf("Transferring existing license and public key files from DUT\n");
system("sshpass -fdefaultpw scp root@192.168.2.10:/etc/satdsp/license.rdf ./tmp/license.rdf");

system("sshpass -fdefaultpw scp root@192.168.2.10:/etc/satdsp/public.pem ./tmp/public.pem");

% Grab the current satdsp_specific.xml file
printf("Transferring existing satdsp_specific.xml file from DUT\n");
system("sshpass -fdefaultpw scp root@192.168.2.10:/etc/satdsp/satdsp_specific.xml ./tmp/satdsp_specific.xml");


% Install an instrument mode license

printf("Transferring Instrument mode license and public key files to DUT\n");
system("sshpass -fdefaultpw scp instrument-mode-license.rdf root@192.168.2.10:/etc/satdsp/license.rdf");

system("sshpass -fdefaultpw scp instrument-mode-public.pem root@192.168.2.10:/etc/satdsp/public.pem");



% Install a new satdsp_specific.xml (turn quadrature tracking back on!)

%printf("Transferring Calibration Specific satdsp_specific.xml to DUT\n");
%system("sshpass -fdefaultpw scp cal_include.xml root@192.168.2.10:/etc/satdsp/satdsp_specific.xml");


% Install a zero cal file, just in case... 

printf("Transferring zero cal file to DUT\n");
system("sshpass -fdefaultpw scp zero_cal_file.mat root@192.168.2.10:/root/zero_cal_file.mat");

printf("Storing zero cal file to boot flash...\n");
system("sshpass -fdefaultpw ssh -l root 192.168.2.10 '/usr/bin/store_cal.sh /root/zero_cal_file.mat'");



% Stop SATDSP
printf("Stopping SATDSP...\n");
system("sshpass -fdefaultpw ssh -l root 192.168.2.10 'systemctl stop satdsp'");

% Stop SATDSP
printf("Starting DCERPC Service...\n");
system("sshpass -fdefaultpw ssh -l root 192.168.2.10 'systemctl start dcerpc'");



% Restart the AD9361 Controller
%printf("Restarting saturn_base... (pausing for 5 seconds)\n");
%system("sshpass -fdefaultpw ssh -l root 192.168.2.10 'systemctl restart rtlogic-saturn_base'");

% Restart SATDSP
printf("Starting SATDSP... (pausing for 5 seconds)\n");
system("sshpass -fdefaultpw ssh -l root 192.168.2.10 'systemctl start satdsp'");
pause(5)


server = struct("addr", "192.168.2.10", "port", 80);
siggen1 = struct("addr", "192.168.2.3", "port", 7777);
siggen2 = struct("addr", "192.168.2.4", "port", 7777);
cw_pwr = -10;
instrument = 'S1_DSP1';
ports = [1 2];
LO_f = [850e6:10e6:3000e6];
%amplifier_gain_db = [10 20 30 40 50];
amplifier_gain_db = [30];

[cal,gain,psd_f,traces]=two_chan_cw_cal(server,instrument,siggen1, ...
			siggen2, cw_pwr,ports,LO_f,amplifier_gain_db);

%cal.gain_db = cal.gain_db - (-25);
cal.gain_db = cal.gain_db - (-35);

% Build the final calibration file... 

f_if = 0:54/65:54;
f_if = f_if - 54/2;
IF_f = f_if .* 1e6;
gain_if_db = zeros(66,10);


fname=strcat("\"sn_",num2str(cal.sn),"_raw_cal.mat\"");

cal_loc = cal.cal_loc;
version = 2;
sn = cal.sn;
t = cal.t;
LO_f = cal.LO_f;
amplifier_gain_db = cal.amplifier_gain_db;
gain_db = cal.gain_db;

% Save the file of record
save("-v4", fname, "version", "cal_loc", "sn", "t", "LO_f", ...
		"IF_f", "amplifier_gain_db",  "gain_db",  "gain_if_db");

save("-v4", "cal.mat", "version", "cal_loc", "sn", "t", "LO_f", ...
		"IF_f", "amplifier_gain_db",  "gain_db",  "gain_if_db");



% Build the command to transfer the file... and transfer it!
%printf("Transferring the calibration file to the DUT...");
%system("sshpass -fdefaultpw scp cal.mat root@192.168.2.10:/root/cal.mat");

% write the cal file to boot flash
%printf("Writing the calibration file to the DUT boot flash...");
%system("sshpass -fdefaultpw ssh -l root 192.168.2.10 '/usr/bin/store_cal.sh /root/cal.mat'");

% Put the original license and public key files back on the DUT...

printf("Transferring original license and public key files to DUT\n");
system("sshpass -fdefaultpw scp ./tmp/license.rdf root@192.168.2.10:/etc/satdsp/license.rdf")

system("sshpass -fdefaultpw scp ./tmp/public.pem root@192.168.2.10:/etc/satdsp/public.pem")

% Put the original satdsp_specific.xml file back on the DUT
%printf("Transferring original satdsp_specific.xml file to DUT\n");
%system("sshpass -fdefaultpw scp ./tmp/satdsp_specific.xml root@192.168.2.10:/etc/satdsp/satdsp_specific.xml")

% Restarting SATDSP
printf("Restarting SATDSP... (pausing for 5 seconds)\n");
system("sshpass -fdefaultpw ssh -l root 192.168.2.10 'systemctl restart satdsp'");
pause(5);







