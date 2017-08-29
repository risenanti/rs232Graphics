A = imread('LadyBird.bmp');%fopen('Untitled.bmp', 'rb');

s1 = serial('COM5' ,'BaudRate',19200, 'OutputBufferSize',155000, 'DataBits',8)
s1.StopBits = 2;
s1.Terminator = '';

fopen(s1);
for j=1 : 200
for i=1 :200
fwrite(s1,A(j,i));
end
end
%fprintf(s1,'______________________________');
%fprintf(s1,'_');
fclose(s1);
%delete(s1);
%delete(arr);
%delete(file);
%11110
