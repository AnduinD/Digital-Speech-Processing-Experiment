w=rectwin(69);%hamming(),  生成窗函数

figure(1);title('窗函数');
subplot(2,1,1);plot(w);xlabel('Samp/n');ylabel('Amp'); %画窗的时域波形
w1=fft(w,65536);w2=w1/(max(w1));w3=20*log10(abs(w2));
wx=2*(0:65535)/65536; %对频率做归一化到[0,2]双边
subplot(2,1,2);plot(wx,w3);axis([0,1,-100,0]);xlabel('f/fs');ylabel('Amp/dB') % 画窗的频域波形 取单边



%读一段语音信号进来
[orgAudioData,fs]=audioread('test.wav');
orgAudioData = orgAudioData(1:80000);
orgAudioData = detrend(orgAudioData,0); %去除直流分量
dt = 1/fs; %原始音频的最小时间间隔
%画它的时域波形
figure(2);plot(orgAudioData);grid;title('原始信号时域特性');xlabel('t/s');ylabel('volume');

% 分帧
chunk = length(w);% 帧长(同窗长)
stride = fix(length(w)/2); % 偏移量
[orgframeDict,frameNum] = split_frame(orgAudioData,w,stride);
frameTime = dt*(0:length(w)-1); %生成分帧内时间轴
frameOffTime =  (dt*stride)*(0:frameNum-1) ; %生成分帧每帧头的时间轴

%画出分帧、加窗后的时域波形
figure(3);
subplot(4,1,1);plot(orgframeDict(1,:));grid on;ylim([-0.002,0.002]);title('分帧加窗后波形');
subplot(4,1,2);plot(orgframeDict(2,:));grid on;ylim([-0.002,0.002]);
subplot(4,1,3);plot(orgframeDict(3,:));grid on;ylim([-0.002,0.002]);
subplot(4,1,4);plot(orgframeDict(4,:));grid on;ylim([-0.002,0.002]);


% 计算短时谱
[stftSpectrum,stftFreq]=stft(orgAudioData,fs,'Window',w,'OverlapLength',chunk-stride);
stftSpectrum = stftSpectrum(fix(chunk+1)/2:end,:)';
stftFreq= stftFreq(fix(chunk+1)/2:end);

%画出加窗后前几帧的短时谱
figure(4);
subplot(4,1,1);plot(stftFreq,abs(stftSpectrum(1,:)));xlabel('f/Hz');grid on;title('短时谱');
subplot(4,1,2);plot(stftFreq,abs(stftSpectrum(2,:)));xlabel('f/Hz');grid on;
subplot(4,1,3);plot(stftFreq,abs(stftSpectrum(3,:)));xlabel('f/Hz');grid on;
subplot(4,1,4);plot(stftFreq,abs(stftSpectrum(4,:)));xlabel('f/Hz');grid on;


% 求短时能量
stPower = zeros(1,frameNum);
for i = 1:frameNum
    stPower(i) = sum(orgframeDict(i,:)*orgframeDict(i,:)');
end
figure(6);plot(frameOffTime,stPower);xlabel('t/s');grid on;title('短时能量');


% 求短时平均幅度
stAvgAmp = zeros(1,frameNum);
for i = 1:frameNum
    stAvgAmp(i) = sum(abs(orgframeDict(i,:))'.*w);
end
figure(7);plot(frameOffTime,stAvgAmp);xlabel('t/s');grid on;title('短时平均幅度');

% 求短时平均过零率
stOverZero = zeros(1,frameNum);
for i=1:frameNum
    for j = 1:chunk-1
        if(orgframeDict(i,j)<=0 && orgframeDict(i,j+1)>0 )
            stOverZero(i) = stOverZero(i)+1;% 累加过0次数
        end
    end
end
figure(8);plot(frameOffTime,stOverZero);xlabel('t/s');grid on;title('短时平均过零率');
