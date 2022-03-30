function [frameDict,frameNum]=split_frame(x,frameWin,frameInc)
    xLen=length(x);          % 取数据长度
    frameLen = length(frameWin); %取出窗长（也即分帧长度）
    if (nargin < 3)             % 如果只有两个参数，设帧inc=帧长
       frameInc = frameLen;
    end
    frameNum = fix((xLen-frameLen+frameInc)/frameInc); % 计算总帧数 
    frameDict = zeros(frameNum,frameLen);         % 初始化最终返回的分帧数组
    frameOffDict = 1+frameInc*(0:(frameNum-1));   % 计算每一帧帧头的偏移量
    for i = (1:frameNum)
      frameBegin = frameOffDict(i); % 取出当前帧的帧头位置
      frameTmp = x(frameBegin:frameBegin+frameLen-1);   % 对数据分帧
      frameTmp = frameTmp .* frameWin;  % 对分帧后的数据加窗
      frameDict(i,:) = frameTmp;
    end
end

    