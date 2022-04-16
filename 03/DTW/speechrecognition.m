function [result] = speechrecognition(testnum)

%����ο�ģ��Ĳ���
for i=0:9
    fname=sprintf('./data/train/%d.wav',i);
    x=audioread(fname);  %����ο�ģ��
    [x1, x2]=vad(x);  %˫���޶˵���
    m=mfcc(x);  %����Mel����ϵ��
    m=m(x1-2:x2-4,:);
    ref(i+1).mfcc=m;
end

%�������ģ��Ĳ���
fname=sprintf('./data/test/%d.wav',testnum);
x=audioread(fname);
[x1, x2]=vad(x);  %˫���޶˵���
m=mfcc(x);
m=m(x1-2:x2-4,:); % ��ȡ������
test_mfcc=m;  % �������յ�mel��

%����ģ��ƥ��
dist=zeros(10,1);
for j=0:9
  dist(j+1)=dtw(test_mfcc,ref(j+1).mfcc);  % �������������ÿ��ģ����dtwֵ
end

figure(2);plot((0:1:9),dist);grid on;title("dtw");
[d,j]=min(dist);   % ƥ��dtw��С��ģ�壨����������ģ�

figure(11);plot(test_mfcc);grid on;title("test");
figure(12);plot(ref(j).mfcc);grid on;title("template")

result = j-1;

