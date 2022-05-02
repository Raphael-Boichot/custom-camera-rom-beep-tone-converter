%Written by Raphaël BOICHOT 2022-04-12
%syntax example: sound_to_image('./sounds/DMG_clean.ogg',10) targets file DMG.ogg and a scaling factor of 10
%code written for GNU Octave/Matlab
%Code made to translate sound files from https://github.com/HerrZatacke/custom-camera-rom
function []=sound_to_image(audio_file,scaling_factor)
try
pkg load image %added for GNU Octave compatibility
end
f_list=[818 916 1014 1145 1211 1342 1440 1505 1571 1636 1767 1931 2127 2258 2422 2520 3437];%list of frequencies
[y,Fs] = audioread(audio_file);%y is raw data, Fs the sampling rate
y=y(:,1);%in case it's stereo, it's mono now
frame_per_tone=2;%In Game boy frame
GB_frequency=59.727500569606;%Internal freq in Hz
tone_per_packet=33;%protocol used, special tone then 32 tones to transmit one tile (2 tones per byte)
tone_len_seconds=frame_per_tone/GB_frequency;
packet_len_seconds=tone_per_packet*tone_len_seconds;
packet_len_tips=round(packet_len_seconds*Fs);
tone_len_tips=round(tone_len_seconds*Fs);
sample=1000;%size of the sample used for FFT, must be lower than tone_len_tips
file_len=length(y);%total recording length
frequence=[];%some inits
k=1;%some inits now
tile=0;
last_good_known_address=0;
data=[];
missing_tiles=0;
error_code=0;
shift=200; %manual adjustemnt for centering the FFT window on tone
while tile<225;%to avoid buffer overflow
    
    if k<(file_len-packet_len_tips-sample);%in case tiles are missing
        k=k+10;%we slide along the record, jumping by small steps to find a 3437 Hz tone
        s=y(k:k+sample,1);%taking a small sample
        %     figure(1)
        %     plot(s)
        [freq]=FFT_findmax(s,Fs,f_list);%Get the most intense frequency
        %     frequence=[frequence,freq];%Store it for plotting
        %     plot(frequence)%Store it for plotting
        %     drawnow%Force output for debug
        distance=abs(f_list-freq);%the minimum indicates the position of freq in f_list
        [val_min,ind]=min(distance);%get the position in the vector and the residual
        if ind==17&&val_min<10;%allows a tolerance of +- 10Hz on 3437 Hz, a new tile is detected !
            
            %             %error correction algorithm
            %             %basically the code runs open loop it it does not detect tone
            %             %17 at the good address. At this step, the code
            %             comes back to the first tile missed but not
            %             further if there are several missing consecutively
            if tile==0||tile==1;%error could be sometimes high on tile 1 for no reason 
                %but tile as 1 is not included into the image we basically 
                %don't give a shit of this one
                 last_good_known_address=k;%force the code to start reading on the mandatory first 17tone
            else
                error=k-last_good_known_address-packet_len_tips;
                if error>1000% There is an error, next 17th tone is afrther than expected
                    error_code=1;
                    disp('Error detected, rewinding to the last estimated 17th tone')
                    missing_tiles=1+floor(error/packet_len_tips);%estimates how many tiles are missing
                    disp([num2str(missing_tiles),' tile(s) missing'])
                    last_good_known_address=k;%store this address for later as the code will rewinf the audio file
                    k=last_good_known_address-missing_tiles*packet_len_tips;%rewind to the first missing tile.
                    %if one tile is missing, the code just re-read the
                    %area with estimated good address, the code is the same
                    %if more than one tile is missing, the code re-read
                    %several chunks in open loop and the code needs a
                    %second part
                else
                    last_good_known_address=k;%no problem, continue
                end
            end
            %             %end of error correction algorithm
            
            tile=tile+1;
            disp(['Tile #',num2str(tile),' detected, searching for data...'])
            k=k+tone_len_tips+sample+shift;%jump a bit after the beginning of the first data tone, it's a purely manual setting
            for i=1:1:32
                s=y(k-round(sample/2):k+round(sample/2));%taking a small sample at the center of the tone
                [freq]=FFT_findmax(s,Fs,f_list);%Get the most intense frequency
                distance=abs(f_list-freq);%the minimum indicates the position of freq in f_list
                [val_min,ind]=min(distance);%get the position in the vector and the residual
                data=[data,ind];
                %plot(s(1:end-1))
                %drawnow
                k=k+tone_len_tips;%jump to the center of the next tone
            end
            
            %error correction algorithm, read the file in open loop without
            %searching for tone 17 if more than one time was missing (first
            %tile corrected before
            missing_tiles=missing_tiles-1;%the first tile was fixed in the upper part of the code
            while missing_tiles>0% the code enters an open loop reading of several tiles
                disp('Continuing open loop reading...')
                tile=tile+1;%forcing a tile even without 17th tone
                disp(['Tile #',num2str(tile),' detected, searching for data...'])
                k=last_good_known_address-missing_tiles*packet_len_tips;%seeking for the n+1 tile missing data stream
                
                for i=1:1:32%here the code is totally open loop
                    s=y(k-round(sample/2)-shift:k+round(sample/2)-shift);%taking a small sample at the center of the tone
                    [freq]=FFT_findmax(s,Fs,f_list);%Get the most intense frequency
                    distance=abs(f_list-freq);%the minimum indicates the position of freq in f_list
                    [val_min,ind]=min(distance);%get the position in the vector and the residual
                    data=[data,ind];
                    %                     plot(s(1:end-1))
                    %                     drawnow
                    k=k+tone_len_tips;%jump to the center of the next tone
                end
                missing_tiles=missing_tiles-1;
            end
            %end of error correction algorithm
            k=k-2*tone_len_tips;%jump back a little to find beginning of tone 17
        end
    else
        tile=255;
        disp('Code break due to missing tiles')
    end
end
data=data(33:end);%gets rid og the first "test frequency tile"
pos=1;
recovered_data=zeros(1,224*16);%pre-allocate in case there are not enough tiles
for k=1:1:length(data)/2
    recovered_data(k)=16*(data(pos)-1)+(data(pos+1)-1);%converts 4 bits to 8 bits
    pos=pos+2;
end

output=decode(recovered_data);%Game Boy tile format to pixels
image_file=(output==1)*90+(output==2)*180+(output==3)*255;%2bbp level to colors
image_file=imresize(image_file,scaling_factor,'nearest');%upscaling with nearest neighbor
imwrite(uint8(image_file),'Image.png')
imshow(imread('Image.png'))%plot image
if error_code==0;disp('No error detected, image is probably pixel perfect');end;
if error_code==1;
    disp('The code has corrected some errors, image may not be pixel perfect');
    disp('Increasing the sound volume at maximum on Game Boy and putting the microphone close to the speaker may fix this');
end;