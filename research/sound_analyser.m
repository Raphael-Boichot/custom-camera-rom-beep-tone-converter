clc
clear
[y,Fs] = audioread('DMG_clean.ogg');
sample=1000;
sliding_freq=zeros(1,20);
ftime=[];
threshold=0.01;

T = 1/Fs;
len=length(y);
sample=1000;
vec=[];
inten=[];
data=[];
inten_peak=[];
pos=1;
write_enable=0;
for k=1:100:len-sample;
    s=y(k:k+sample,1);
    L=length(s);
    
    Y = fft(s(:,1));
    P2 = abs(Y/L);
    P1 = P2(1:round(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    %Define the frequency domain f and plot the single-sided amplitude spectrum P1. The amplitudes are not exactly at 0.7 and 1, as expected, because of the added noise. On average, longer signals produce better frequency approximations.
    f = Fs*(0:(L/2))/L;
    P1=P1(1:end-1);
    %P1=P1./(f');
    [val_peak,ind]=max(P1);
freq=f(ind);
sliding_freq=[sliding_freq,freq];
sliding_freq=sliding_freq(2:end);

if mean(abs(s))>threshold&&write_enable==1&&mean(sliding_freq)==ind;
data(pos)=ind;
write_enable=0;
end
if mean(abs(s))<threshold&&write_enable==0;
pos=pos+1;
write_enable=1;
end
%------------------------------------------------
 subplot(2,3,1)
 semilogx(f,P1);
 title('Amplitude Spectrum')
 xlabel('f (Hz)')
 ylabel('|P1(f)|')
 
ftime=[ftime,P1(1:100)];
if length(ftime)>1000;
    ftime=ftime(:,2:end);
end
subplot(2,3,2:3)
imagesc(sqrt(flipud(ftime)))
colormap bone
title(['Amplitude spectrum, main frequency=',num2str(freq)])

subplot(2,3,4)
plot(s)
title('Raw signal')
subplot(2,3,5:6)
inten=[inten;sum(abs(s))*max(P1)/std(P1)];
if length(inten)>1000;
    inten=inten(2:end);
end

semilogy(inten)
title('Signal to noise ratio')

drawnow
%----------------------------------------------------
end
