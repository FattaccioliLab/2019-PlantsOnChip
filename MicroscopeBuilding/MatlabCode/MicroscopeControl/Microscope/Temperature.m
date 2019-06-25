clear all

a=arduino()
address=scanI2CBus(a)
dev = i2cdev(a,char(address(1)))
i=1
for i=1:1:100
    temp=bitand(readRegister(dev,'05','uint16'),hex2dec('0fff'));
    tempC(i)=double(temp)/16;
    pause(0.1)
end

mean(tempC)
std(tempC)

plot(tempC,'r*')
ylim([20 40])

