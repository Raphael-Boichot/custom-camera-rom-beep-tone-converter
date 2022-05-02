function [freq]=FFT_findmax(s,Fs,f_list)
L=length(s);
Y = fft(s(:,1));

if not(length(Y)==1)
    P2 = abs(Y/L);
    P1 = P2(1:round(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    %Define the frequency domain f and plot the single-sided amplitude spectrum P1. The amplitudes are not exactly at 0.7 and 1, as expected, because of the added noise. On average, longer signals produce better frequency approximations.
    f = Fs*(0:(L/2))/L;
    P1=P1(1:end-1);
    %frequency filter
    for i=1:1:length(f)
        if f(i)>(f_list(end)+10)||f(i)<(f_list(1)-10);%frequency filter to remove voices for example
            P1(i)=0;
        end
    end
    %second harmonic remover
    %         [val_peak_1,ind_1]=max(P1);
    %         P_temp=P1;
    %         P_temp(ind_1)=0;
    %         [val_peak_2,ind_2]=max(P_temp);
    %         if ind_1>ind_2
    %             P1=P_temp;
    %         end
    
    %         plot(f,P1)
    %         drawnow
    [val_peak,ind]=max(P1);
    freq=f(ind);
else
    disp('FFT crash');
    freq=1e9;
end