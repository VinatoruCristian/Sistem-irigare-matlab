clear;
te=0.001;
fe=1/te;
t=0:te:0.5;
x=sin(2*pi*100*t)+sin(2*pi*300*t);
y=x+3*randn(size(t));
subplot(3,1,1)
plot(t,x,t,y)
title('Semnal original cu zgomot')
legend('Semnal','Zgomot')

Y=fft(y);
Pyy=Y.*conj(Y);
s=length(Pyy);
f=fe*(0:s/2-1)/s;
subplot(3,1,2)
plot(f,Pyy(1:(s-1)/2));
title('Analiza spectrala')

indici=Pyy>1000;
Pyycurat=Pyy.*indici;
yy=indici.*y;
yfiltrat=ifft(yy);
subplot(3,1,3)
plot(t,yfiltrat);
title('Semnal filtrat')