function [result] = speechrecognition(testnum)

%计算参考模板的参数
for i=0:9
    fname=sprintf('./data/train/%d.wav',i);
    x=audioread(fname);  %读入参考模板
    [x1, x2]=vad(x);  %双门限端点检测
    m=mfcc(x);  %计算Mel倒谱系数
    m=m(x1-2:x2-4,:);
    ref(i+1).mfcc=m;
end

%计算测试模板的参数
fname=sprintf('./data/test/%d.wav',testnum);
x=audioread(fname);
[x1, x2]=vad(x);  %双门限端点检测
m=mfcc(x);
m=m(x1-2:x2-4,:); % 截取语音段
test_mfcc=m;  % 生成最终的mel谱

%进行模板匹配
dist=zeros(10,1);
for j=0:9
  dist(j+1)=dtw(test_mfcc,ref(j+1).mfcc);  % 计算待测语音和每个模板间的dtw值
end

figure(2);plot((0:1:9),dist);grid on;title("dtw");
[d,j]=min(dist);   % 匹配dtw最小的模板（即距离最近的）

figure(11);plot(test_mfcc);grid on;title("test");
figure(12);plot(ref(j).mfcc);grid on;title("template")

result = j-1;

