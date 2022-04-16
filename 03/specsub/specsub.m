function out = specsub(x,fs)

len = floor(20*fs/1000);   % 帧长
if rem(len,2) == 1, len=len+1; end;
PERC = 50;     % 帧移
len1 = floor(len*PERC/100);
len2 = len-len1; 

Thres = 3;      % VAD threshold in dB SNRseg 
beta = 0.005;
G = 0.9;

win = hamming(len); % 生成汉明窗
winGain = len2/sum(win); % 窗内增益

% 估计噪声幅度
nFFT = 2*2^nextpow2(len);
noise_mean = zeros(nFFT,1);
j=1;
for k = 1:10
   noise_mean = noise_mean+abs(fft(win.*x(j:j+len-1),nFFT));
   j = j+len;
end
noise_mu = noise_mean/5;

k = 1;
img = sqrt(-1);
x_old = zeros(len1,1);
Nframes = floor(length(x)/len2)-1;
xfinal = zeros(Nframes*len2,1);

rand_plot_n = fix(Nframes/3)+randi(100); % 随机挑一帧画谱减前后的频谱

%=========================    Start Processing   ===============================
for n = 1:Nframes 
    insign = win.*x(k:k+len-1);      % W加窗
    spec = fft(insign,nFFT);         % 计算窗内的短时频谱
    sig = abs(spec);                 % 得到频域幅度谱
    theta = angle(spec);             % 得到相位谱
    SNRseg = 10*log10(norm(sig,2)^2/norm(noise_mu,2)^2); % 估计信噪比
    alpha = berouti1(SNRseg);   % 计算谱减因子
    sub_speech = sig - alpha*noise_mu;
    diffw = sub_speech - beta*noise_mu;     % 当纯净信号小于噪声信号的功率时
    z = find(diffw <0);  % 查找有无过零幅度
    if~isempty(z) % beta过减处理
        sub_speech(z) = beta*noise_mu(z);   % 用估计出来的噪声信号表示下限值
    end
    if (SNRseg < Thres)   % 估计新的噪声谱
        noise_temp = G*noise_mu+(1-G)*sig;    % 平滑处理噪声功率谱
        noise_mu = noise_temp;                   % 新的噪声幅度谱
    end

    
    sub_speech(nFFT/2+2:nFFT) = flipud(sub_speech(2:nFFT/2));% 幅度谱对称扩展
    x_phase = (sub_speech).*(cos(theta)+img*(sin(theta))); % 生成输出信号复数谱

    if(n == rand_plot_n)
        figure(4);plot(abs(spec(1:end/2)));title("org");grid on;
        figure(5);plot(abs(sub_speech(1:end/2)));title("specsub");grid on;
    end

    xi = real(ifft(x_phase)); %输出信号谱反变换
    xfinal(k:k+len2-1)=x_old+xi(1:len1); %信号帧的滑动叠加
    x_old = xi(1+len1:len);
    k = k+len2;
end

out = winGain*xfinal;


function a = berouti1(SNR)  
% 幅度谱输入时 对谱减因子的估算
if SNR >= -5.0 & SNR <= 20
	a = 3-SNR*2/20;
else
    if SNR < -5.0
        a = 4;
    end
    if SNR > 20
        a = 1;
    end
end

function a = berouti(SNR)
% 功率谱输入时 对谱减因子的估算
if SNR >= -5.0 & SNR <= 20
	a = 4-SNR*3/20; 
else
    if SNR < -5.0
        a = 5;
    end
    if SNR > 20
        a = 1;
    end
end