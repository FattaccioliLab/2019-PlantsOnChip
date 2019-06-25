function tempC = ConvertTemperature(dev)
 temp=bitand(readRegister(dev,'05','uint16'),hex2dec('0fff'));
 tempC=double(temp)/16;
end
