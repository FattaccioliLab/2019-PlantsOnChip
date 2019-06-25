function res=SplitTimeString(a)
    time=num2str(a);
    t = strsplit(time,'.');
    t = string(t);

    L=length(t{2});

    switch L
        case 2
            t(2)=strcat(t(2),"00");
        case 3
            t(2)=strcat(t(2),"0");
        otherwise
    end

    res=strcat(t(1),".",t(2));
end
