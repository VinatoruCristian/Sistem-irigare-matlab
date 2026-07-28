close all; clear all; 

Fs = 10000;           
Fpass = [1000 3000];   
Fstop = [4000 5000];   
Rp = 3;                
Rs = 25;
T = 1/Fs;

wp = 2*pi*Fpass;     
ws = 2*pi*Fstop;

Wp = 2/T*tan(wp*T/2);
Ws = 2/T*tan(ws*T/2);

[n,Wn]=buttord(Wp,Ws,Rp,Rs,'s');
[z,p,k] = buttap(n);
[num,den]=zp2tf(z,p,k);

Wo=sqrt(Wn(1)*Wn(2));
Bw=Wn(2)-Wn(1);
[numt,dent]=lp2bp(num,den,Wo,Bw);

[bz,az]=bilinear(numt,dent,Fs);
freqz(bz,az);