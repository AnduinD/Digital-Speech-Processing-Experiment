clc; close all;

frameWin=rectwin(899);%  生成窗函数

w1=fft(frameWin,65536);w2=w1/(max(w1));w3=20*log10(abs(w2));
wx=2*(0:65535)/65536; %对频率做归一化到[0,2]双边
%figure(1);title('窗函数');
%subplot(2,1,1);plot(w);xlabel('Samp/n');ylabel('Amp'); %画窗的时域波形
% subplot(2,1,2);plot(wx,w3);axis([0,1,-100,0]);xlabel('f/fs');ylabel('Amp/dB') % 画窗的频域波形 取单边



%读一段语音信号进来
[Audio,fs]=audioread('100-双11购物狂欢节.mp3');

% orgAudioData = sin((0:5000*2*pi/80000:5000*2*pi))';
orgAudioData = Audio(1000000:2000000,1); % 取单通道
orgAudioData_withPrefix = Audio(1190000:1550000,1); % 取单通道 带前导段
% orgAudioData = orgAudioData(1:80000);
orgAudioData = detrend(orgAudioData,0); %去除直流分量
orgAudioData_withPrefix = detrend(orgAudioData_withPrefix,0);
dt = 1/fs; %原始音频的最小时间间隔
%画它的时域波形
%figure(2);plot(orgAudioData);grid;title('原始信号时域特性');xlabel('t/s');ylabel('volume');

% 分帧
chunk = length(frameWin);% 帧长(同窗长)
stride = fix(length(frameWin)/2); % 偏移量
frameNum = fix((length(orgAudioData)-chunk+stride)/stride); % 计算总帧数 
orgFrameDict = zeros(frameNum,chunk);         % 初始化仅分帧截断的数组
mdfFrameDict = zeros(frameNum,chunk);         % 初始化分帧加窗后的数组
frameOffDict = 1+stride*(0:(frameNum-1));   % 计算每一帧帧头的偏移量
for i = (1:min(6,frameNum))
    frameBegin = frameOffDict(i); % 取出当前帧的帧头位置
    frameTmp = orgAudioData(frameBegin:frameBegin+chunk-1);   % 数据分帧
    orgFrameDict(i,:) = frameTmp; 
    frameTmp = frameTmp .* frameWin;  % 数据加窗
    mdfFrameDict(i,:) = frameTmp; 
end
frameTime = 1000*dt*(0:length(frameWin)-1); %生成分帧内时间轴 换算成ms
frameOffTime =  (dt*stride)*(0:frameNum-1) ; %生成分帧每帧头的时间轴

% %画出分帧、加窗后的时域波形
% figure(3);
% subplot(4,1,1);plot(orgFrameDict(1,:));grid on;title('分帧加窗后波形');
% subplot(4,1,2);plot(orgFrameDict(2,:));grid on;
% subplot(4,1,3);plot(orgFrameDict(3,:));grid on;
% subplot(4,1,4);plot(orgFrameDict(4,:));grid on;


% 计算短时谱
[stftSpectrum,stftFreq]=stft(orgAudioData,fs,'Window',frameWin,'OverlapLength',chunk-stride,'FrequencyRange','onesided');
stftSpectrum = stftSpectrum';
% stftSpectrum = stftSpectrum(fix(chunk+1)/2:end,:)';
% stftFreq= stftFreq(fix(chunk+1)/2:end);
% 
% %画出加窗后前几帧的短时谱
% figure(4);
% subplot(4,1,1);plot(stftFreq(1:fix(length(stftFreq)/6)),abs(stftSpectrum(1,1:fix(length(stftFreq)/6))));xlabel('f/Hz');grid on;title('短时谱');
% subplot(4,1,2);plot(stftFreq(1:fix(length(stftFreq)/6)),abs(stftSpectrum(2,1:fix(length(stftFreq)/6))));xlabel('f/Hz');grid on;
% subplot(4,1,3);plot(stftFreq(1:fix(length(stftFreq)/6)),abs(stftSpectrum(3,1:fix(length(stftFreq)/6))));xlabel('f/Hz');grid on;
% subplot(4,1,4);plot(stftFreq(1:fix(length(stftFreq)/6)),abs(stftSpectrum(4,1:fix(length(stftFreq)/6))));xlabel('f/Hz');grid on;
% 
% %画出加窗后前几帧的短时谱
% figure(4);
% 
% subplot(4,1,1);plot(stftFreq(1:end),abs(stftSpectrum(1,1:end)));xlabel('f/Hz');grid on;title('短时谱');
% subplot(4,1,2);plot(stftFreq(1:end),abs(stftSpectrum(2,1:end)));xlabel('f/Hz');grid on;
% subplot(4,1,3);plot(stftFreq(1:end),abs(stftSpectrum(3,1:end)));xlabel('f/Hz');grid on;
% subplot(4,1,4);plot(stftFreq(1:end),abs(stftSpectrum(4,1:end)));xlabel('f/Hz');grid on;



%  求短时自相关函数
stACF = zeros(size(orgFrameDict));
% for i = 1:min(6,frameNum)
%     for j = 1:chunk  % 手写自相关
%         stACF(i,j) = sum(orgFrameDict(i,1:end-j+1).*orgFrameDict(i,j:end));
%     end
% end
for i = 1:min(6,frameNum)
    tmp = xcorr(orgFrameDict(i,:));  % 用库函数做自相关
    stACF(i,:) = tmp(chunk:end);
end
figure(7);
subplot(4,1,1);plot(frameTime,stACF(1,:));xlabel('t/ms');grid on;title('短时自相关函数');
subplot(4,1,2);plot(frameTime,stACF(2,:));xlabel('t/ms');grid on;
subplot(4,1,3);plot(frameTime,stACF(3,:));xlabel('t/ms');grid on;
subplot(4,1,4);plot(frameTime,stACF(4,:));xlabel('t/ms');grid on;


%  求修正的短时自相关函数
stACF2 = zeros(size(orgFrameDict));
for i = 1:min(6,frameNum)-2
    for j = 1:chunk % j为滞后数+1
        w1 = rectwin(chunk);
        w2 = rectwin(chunk+j-1); % 变长窗
        frameTmp1 = orgAudioData(frameOffDict(i):frameOffDict(i)+chunk-1).*w1;
        frameTmp2 = orgAudioData(frameOffDict(i):frameOffDict(i)+chunk-1+j-1).*w2;
        frameTmp2 = frameTmp2(j:end);
        stACF2(i,j) = sum(frameTmp1.*frameTmp2);
    end
end
figure(8);
subplot(4,1,1);plot(frameTime,stACF2(1,:));xlabel('t/ms');grid on;title('修正的短时自相关函数');
subplot(4,1,2);plot(frameTime,stACF2(2,:));xlabel('t/ms');grid on;
subplot(4,1,3);plot(frameTime,stACF2(3,:));xlabel('t/ms');grid on;
subplot(4,1,4);plot(frameTime,stACF2(4,:));xlabel('t/ms');grid on;




% 求短时平均幅度差
stAMDF = zeros(size(orgFrameDict));
for i = 1:min(6,frameNum)
    for j = 1:chunk
        stAMDF(i,j) = sum(abs(orgFrameDict(i,1:end-j+1)-orgFrameDict(i,j:end)));
    end
end
figure(9);
subplot(4,1,1);plot(frameTime,stAMDF(1,:));xlabel('t/ms');grid on;title('短时平均幅度差');
subplot(4,1,2);plot(frameTime,stAMDF(2,:));xlabel('t/ms');grid on;
subplot(4,1,3);plot(frameTime,stAMDF(3,:));xlabel('t/ms');grid on;
subplot(4,1,4);plot(frameTime,stAMDF(4,:));xlabel('t/ms');grid on;

% 求修正后的短时平均幅度差
stAMDF2 = zeros(size(orgFrameDict));
for i = 1:min(6,frameNum)
    for j = 1:chunk
        w1 = rectwin(chunk);
        w2 = rectwin(chunk+j-1); % 变长窗
        frameTmp1 = orgAudioData(frameOffDict(i):frameOffDict(i)+chunk-1).*w1;
        frameTmp2 = orgAudioData(frameOffDict(i):frameOffDict(i)+chunk-1+j-1).*w2;
        frameTmp2 = frameTmp2(j:end);
        stAMDF2(i,j) = sum(abs(frameTmp1-frameTmp2));
    end
end
figure(10);
subplot(4,1,1);plot(frameTime,stAMDF2(1,:));xlabel('t/ms');grid on;title('修正的短时平均幅度差');
subplot(4,1,2);plot(frameTime,stAMDF2(2,:));xlabel('t/ms');grid on;
subplot(4,1,3);plot(frameTime,stAMDF2(3,:));xlabel('t/ms');grid on;
subplot(4,1,4);plot(frameTime,stAMDF2(4,:));xlabel('t/ms');grid on;

 
%  语音端点检测？ 两级判决法
[voiceseg,vsl,SF,NF]=vad_ezm1(orgAudioData_withPrefix,chunk,stride,fix(63000/stride+1));  % 端点检测
% frameTime_withPrefix=frame2time(frameNum, chunk, stride, fs);
% figure(20);
% plot((0:length(orgAudioData_withPrefix)-1)*dt,orgAudioData_withPrefix);xlabel('t/s');hold on;grid on;
% for k=1 : vsl  % 画出起止点位置
%     nx1=min(voiceseg(k).begin,length(frameTime_withPrefix)); nx2=min(voiceseg(k).end,length(frameTime_withPrefix));
%     %nxl=voiceseg(k).duration;
%     % fprintf('%4d   %4d   %4d   %4d\n',k,nx1,nx2,nxl);
%     line([frameTime_withPrefix(nx1) frameTime_withPrefix(nx1)],[-0.4 0.4],'color','k','LineStyle','-');
%     line([frameTime_withPrefix(nx2) frameTime_withPrefix(nx2)],[-0.4 0.4],'color','k','LineStyle','--');
% end