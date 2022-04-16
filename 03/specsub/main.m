clear all;

[inAudio,fs]=audioread('100-˫11����񻶽�.mp3');
inAudio = inAudio(1190000:1550000,1); % ȡ��ͨ�� ��ǰ����
inAudio=inAudio+0.02*randn(size(inAudio)); % ������̬����

outAudio=specsub(inAudio,fs);  % �׼�������

figure(1);plot(inAudio);grid on;title("in");
figure(2);plot(outAudio);grid on;title("out");

infft = fft(inAudio);outfft = fft(outAudio);
figure(8);plot(abs(infft(1:fix(end/2))));grid on;title("in");
figure(9);plot(abs(outfft(1:fix(end/2))));grid on;title("out");