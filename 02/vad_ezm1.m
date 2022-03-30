function [voiceseg,vsl,SF,NF]=vad_ezm1(x,wlen,inc,NIS)
    x=x(:);                                 % 把x转换成列数组
    maxsilence = 32;                        % 初始化
    minlen  = 5;    
    status  = 0;
    count   = 0;
    silence = 0;
    
    y=v_enframe(x,wlen,inc)';               % 分帧
    fn=size(y,2);                           % 帧数
    amp=sum(y.^2);                          % 求取短时平均能量
    zcr=zc2(y,fn);                          % 计算短时平均过零率

    ampth=mean(amp(1:NIS));                 % 计算初始无话段区间能量和过零率的平均值               
    zcrth=mean(zcr(1:NIS));
    amp2=8*ampth; amp1=50*ampth;             % 设置能量和过零率的阈值
    zcr2=20*zcrth;
    
    %开始端点检测
    xn=1;
    for n=1:fn
       switch status
       case {0,1}                           % 0 = 静音, 1 = 可能开始
          if amp(n) > amp1                  % 确信进入语音段
             x1(xn) = max(n-count(xn)-1,1);
             status  = 2;
             silence(xn) = 0;
             count(xn)   = count(xn) + 1;
          elseif amp(n) > amp2 | ...        % 可能处于语音段
                 zcr(n) > zcr2
             status = 1;
             count(xn)  = count(xn) + 1;
          else                              % 静音状态
             status  = 0;
             count(xn)   = 0;
             x1(xn)=0;
             x2(xn)=0;
          end
       case 2,                              % 2 = 语音段
          if amp(n) > amp2 & ...            % 保持在语音段
             zcr(n) > zcr2
             count(xn) = count(xn) + 1;
             silence(xn) = 0;
          else                              % 语音将结束
             silence(xn) = silence(xn)+1;
             if silence(xn) < maxsilence    % 静音还不够长，语音尚未结束
                count(xn)  = count(xn) + 1;
             elseif count(xn) < minlen      % 语音长度太短，认为是静音或噪声
                status  = 0;
                silence(xn) = 0;
                count(xn)   = 0;
             else                           % 语音结束
                status  = 3;
                x2(xn)=x1(xn)+count(xn);
             end
          end
       case 3,                              % 语音结束，为下一个语音准备
            status  = 0;          
            xn=xn+1; 
            count(xn)   = 0;
            silence(xn)=0;
            x1(xn)=0;
            x2(xn)=0;
       end
    end 
    
    el=length(x1);             
    if x1(el)==0, el=el-1; end              % 获得x1的实际长度
    if x2(el)==0                            % 如果x2最后一个值为0，对它设置为fn
        fprintf('Error: Not find endding point!\n');
        x2(el)=fn;
    end
    SF=zeros(1,fn);                         % 按x1和x2，对SF和NF赋值
    NF=ones(1,fn);
    for i=1 : el
        SF(x1(i):x2(i))=1;
        NF(x1(i):x2(i))=0;
    end
    speechIndex=find(SF==1);                % 计算voiceseg
    voiceseg=findSegment(speechIndex);
    vsl=length(voiceseg);

    frameTime_withPrefix=frame2time(fn, wlen, inc, 44100);
    figure(30);plot(frameTime_withPrefix,amp);xlabel('t/s');hold on;grid on;title('amp');
    line([0  frameTime_withPrefix(end)],[amp2 amp2],'color','k','LineStyle','-');
    line([0  frameTime_withPrefix(end)],[amp1 amp1],'color','k','LineStyle','--');
    for k=1 : vsl  % 画出起止点位置
        nx1=min(voiceseg(k).begin,length(frameTime_withPrefix)); nx2=min(voiceseg(k).end,length(frameTime_withPrefix));
        %nxl=voiceseg(k).duration;
        % fprintf('%4d   %4d   %4d   %4d\n',k,nx1,nx2,nxl);
        line([frameTime_withPrefix(nx1) frameTime_withPrefix(nx1)],[-1 20],'color','k','LineStyle','-');
        line([frameTime_withPrefix(nx2) frameTime_withPrefix(nx2)],[-1 20],'color','k','LineStyle','--');
    end

    figure(31);plot(frameTime_withPrefix,zcr);xlabel('t/s');hold on;grid on;title('zcr');
    line([0  frameTime_withPrefix(end)],[zcr2 zcr2],'color','k','LineStyle','-');
    for k=1 : vsl  % 画出起止点位置
        nx1=min(voiceseg(k).begin,length(frameTime_withPrefix)); nx2=min(voiceseg(k).end,length(frameTime_withPrefix));
        %nxl=voiceseg(k).duration;
        % fprintf('%4d   %4d   %4d   %4d\n',k,nx1,nx2,nxl);
        line([frameTime_withPrefix(nx1) frameTime_withPrefix(nx1)],[-1 100],'color','k','LineStyle','-');
        line([frameTime_withPrefix(nx2) frameTime_withPrefix(nx2)],[-1 100],'color','k','LineStyle','--');
    end

    % figure(31);plot((0:length(x)-1)/44100,zcr);xlabel('t/s');hold on;grid on;
    figure(20);plot((0:length(x)-1)/44100,x);xlabel('t/s');hold on;grid on;
    for k=1 : vsl  % 画出起止点位置
        nx1=min(voiceseg(k).begin,length(frameTime_withPrefix)); nx2=min(voiceseg(k).end,length(frameTime_withPrefix));
        %nxl=voiceseg(k).duration;
        % fprintf('%4d   %4d   %4d   %4d\n',k,nx1,nx2,nxl);
        line([frameTime_withPrefix(nx1) frameTime_withPrefix(nx1)],[-0.4 0.4],'color','k','LineStyle','-');
        line([frameTime_withPrefix(nx2) frameTime_withPrefix(nx2)],[-0.4 0.4],'color','k','LineStyle','--');
    end
    