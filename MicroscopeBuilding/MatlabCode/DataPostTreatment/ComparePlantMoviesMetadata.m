%Comparer les fichiers de films et le fichier des metadata

clear all
close all

startingFolder = './Users/jacques/Desktop/Plants'; % Whatever.
folder = uigetdir(startingFolder);

filePattern = fullfile(folder, 'corr_*');
existing = dir(filePattern);
if isempty(existing)
else delete(strcat(existing.folder, '/', existing.name))
end

% Now get .dat files
filePattern = fullfile(folder, '*_s_*');
files = dir(filePattern);

filePattern = fullfile(folder, '*.txt');
metadata = dir(filePattern);
name=strcat(metadata.folder, '/', metadata.name)

fileID = fopen(name);
C = textscan(fileID,'%s %f %f %f');
fclose(fileID);
ListFromMetadata=string(C{1,1});
ListFromMetadata=regexprep(ListFromMetadata, '.$', '', 'lineanchors');
ListFromMetadata=regexprep(ListFromMetadata, '.$', '', 'lineanchors');

NewFiles=struct2cell(files);
names=string(cell2mat(NewFiles(1,:)'));
ListFromFolder=extractBetween(names, '_s_','.png');

for i=1:length(ListFromMetadata)
    A(i,:)= (ListFromMetadata(i)==ListFromFolder);
end

for j=1:length(ListFromFolder)
    B(j) = any(A(:,j));
end

ToRemove=find(B==false);
files(ToRemove)=[]

%Reconstitution du fichier de métadonnées
%Calcul du temps écoulé
%Ajout de nuit et jour
index=1;
decalage=0;
fileID = fopen(strcat(metadata.folder, '/corr_', metadata.name),'w');
fprintf(fileID,'%s\t %s\t %s\t %s\t %s\t %s\n','Index', 'Full Name', 'Time Scalar',  'Elapsed Time', 'Temperature', 'DayNight');

for k=1:length(files)
        Index(k) = k;
        FullName{k}= files(k).name;
%         FullName{index}= strcat(name(1,:));
        TimeStamp(k)=string(C{1,1}(k));
        Elapsed(k)= 24*3600*(str2num(cell2mat(C{1,1}(k)))-str2num(cell2mat(C{1,1}(1))));
        Temperature(k)=double(C{1,2}(k));
        if C{1,3}(k,1)<1
            DayNight(index)= "Night";
        else
            DayNight(index)= "Day";
        end
        fprintf(fileID,'%f\t %s\t  %s\t %f\t %f\t %s\n',Index(index), FullName{1,index}, TimeStamp(index),  Elapsed(index), Temperature(index), DayNight(index));
        
    index=index+1;
    
end

fclose(fileID);
