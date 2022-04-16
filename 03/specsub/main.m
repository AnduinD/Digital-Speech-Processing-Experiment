clear all;

[inAudio,fs]=audioread('100-双11购物狂欢节.mp3');
inAudio = inAudio(1190000:1550000,1); % 取单通道 带前导段
inAudio=inAudio+0.02*randn(size(inAudio)); % 叠加正态噪声

outAudio=specsub(inAudio,fs);  % 谱减法处理

figure(1);plot(inAudio);grid on;title("in");
figure(2);plot(outAudio);grid on;title("out");

infft = fft(inAudio);outfft = fft(outAudio);
figure(8);plot(abs(infft(1:fix(end/2))));grid on;title("in");
figure(9);plot(abs(outfft(1:fix(end/2))));grid on;title("out");