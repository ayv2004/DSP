function [ofdm_frames_modulated_serial,P,zeros_required]=ofdm(qam_stream,N,L,on_off_vector,trainMode,training_seq,Lt,Ld)

%------------------------------------------------------------------------%
%commenting the following parts out as the following values are going to
%passed as an arguement to the function

%N=1024;
%L=100; %length of the cyclic prefix
symbols_frame=((N/2)-1); %this is the number of QAM symbols that can be present in a frame
%------------------------------------------------------------------------%

%if QAM stream is a row vector, convert that into a column vector
[nr,nc]=size(qam_stream);
if (nr==1)
    qam_stream=qam_stream.'; %the .' operator only transposes without conjugation
end
%------------------------------------------------------------------------%
if (trainMode=='Y')||(trainMode=='y')
    %In this case the QAM stream input is the trainblock sequence of QAM
    %characters. It needs to be replicated 100 times and put into
    %qam_stream
    qam_stream_buffer=qam_stream;
    qam_stream=repmat(qam_stream_buffer,100,1);
    
end

%before proceeding with anything else, lets process the vector with
%adaptive on-off loading.

data_index=1;
frequency_index=1;
qam_stream_buffer=[];
while (data_index<=length(qam_stream))
    if (on_off_vector(frequency_index)==1)
        %not a great way to do it, but I am too left wing to care
        qam_stream_buffer=[qam_stream_buffer;qam_stream(data_index)];
        data_index=data_index+1;
    else
        qam_stream_buffer=[qam_stream_buffer;0];
        %disp('I am here');
    end
    frequency_index=frequency_index+1;
    if (frequency_index==N/2)
        frequency_index=1;
    end
end
qam_stream=qam_stream_buffer;


    






%The following code checks whether the function has been called with a
%cyclic prefix length of more than or equal to the number of data elements
%that can be in a packet!
if L>=(N/2)-1
    fprintf('ERROR!! Increase the size of N or decrease the size of L to continue!\n');
    ofdm_frames_modulated_serial=NaN;
    return;
end
%------------------------------------------------------------------------%


%generation of the IFFT matrix
k=[0:1:(N-1)]'; 
ifft_matrix=zeros(N,N);
for j=0:1:N-1
    ifft_matrix(:,j+1)=exp(1i*j*2*pi*k/N);
end
%------------------------------------------------------------------------%




%--------------------Check the number of frames required------------------
%----Also ensure that the data can shaped into that many frames-----------
%----------If not, append zeros at the end of the QAM stream--------------
frames_required=ceil(length(qam_stream)/((N/2)-1));
P=frames_required;   %the variable P is used here as it was the term used in the exercise document
ofdm_frames=zeros(N,P); %each column of ofdm_frame represents a frame of the OFDM data
if frames_required*((N/2)-1)~=(length(qam_stream))
    zeros_required=(frames_required*((N/2)-1))-(length(qam_stream));
    fprintf('!!!!!Warning!!!!!\n')
    fprintf('Some zeros will be appended at the end of the QAM stream to make proper frames\n');
    fprintf('Total number of zeros appended = %f\n',zeros_required);
    dummy_zeros=zeros(zeros_required,1);
    qam_stream=[qam_stream;dummy_zeros];
else
    zeros_required=0;
end

%------------------------------------------------------------------------

%------------------------------------------------------------------------

%This above piece of code ensures that the data is shaped in such a way
%that the following part becomes oblivious of it.

conjugate_qam_symbols=zeros(symbols_frame,1);
for j=1:1:P
    ofdm_frames(2:N/2,j)=qam_stream((j-1)*symbols_frame+1:j*symbols_frame);
    conjugate_qam_symbol=conj(qam_stream((j-1)*symbols_frame+1:j*symbols_frame));
    ofdm_frames((N/2)+2:end,j)=flipud(conjugate_qam_symbol);
end




%--------------generating the modulated matrix---------------------------%
ofdm_frames_modulated=ifft(ofdm_frames);
%ofdm_frames_modulated=ifft_matrix*ofdm_frames;
%--------------modelling the receiver------------------------------------%
%fft_matrix=inv(ifft_matrix);
%ofdm_frames_demoluated=(fft_matrix*ofdm_frames_modulated);
%------------------------------------------------------------------------%


%Cyclic pre-fix is addded here
ofdm_frames_modulated_with_prefix=zeros(N+L,P);
if L>0
    %the last L elements of each frame are t be repeated at the beginning
    %of every frame
    for i=1:P
        ofdm_frames_modulated_with_prefix(1:L,i)=ofdm_frames_modulated(end-L+1:end,i);
        ofdm_frames_modulated_with_prefix(L+1:end,i)=ofdm_frames_modulated(:,i);
    end
    ofdm_frames_modulated=ofdm_frames_modulated_with_prefix;
end

    
    


%the following part converts the parallel frames into a long serial form
ofdm_frames_modulated_serial=zeros((N+L)*P,1);
for i=1:P
    ofdm_frames_modulated_serial((i-1)*(N+L)+1:i*(N+L))=ofdm_frames_modulated(:,i);
end

%Because of the mirroring operation, all the OFDM frames should just have
%real parts and no imaginary parts
ofdm_frames_modulated_serial=real(ofdm_frames_modulated_serial);
end










    


    
    
 