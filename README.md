# custom-camera-rom-beep-tone-converter
An experimental beep tone to image converter for the [Game Boy Camera rom project](https://github.com/HerrZatacke/custom-camera-rom). The code features a [Fast Fourier Transform](https://en.wikipedia.org/wiki/Fast_Fourier_transform) to recover binary data from the soundfile. It is able to cancel interferences with other frequencies and to read damaged soundfiles as soon as the recording level is sufficiently high.

Simple to use: 
* Record a sound file of the tone generator feature (at 44100 Hz and mono, ideally). Best results were obtained with a webcam microphone placed against the console speaker and [Audacity](https://www.audacityteam.org/). 
* Run the code with [GNU Octave](https://www.gnu.org/software/octave/index) or Matlab by pointing at your audio file.
* Enjoy your image transmitted by sound !

Mobile phone recordings gave very bad results due to some active noise reduction algorithm and probably some other quirks to elucidate. Ogg format is recommended.
