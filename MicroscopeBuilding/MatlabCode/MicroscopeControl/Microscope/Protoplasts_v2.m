function varargout = Protoplasts_v2(varargin)
% PROTOPLASTS_V2 MATLAB code for Protoplasts_v2.fig
%      PROTOPLASTS_V2, by itself, creates a new PROTOPLASTS_V2 or raises the existing
%      singleton*.
%
%      H = PROTOPLASTS_V2 returns the handle to a new PROTOPLASTS_V2 or the handle to
%      the existing singleton*.
%
%      PROTOPLASTS_V2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROTOPLASTS_V2.M with the given input arguments.
%
%      PROTOPLASTS_V2('Property','Value',...) creates a new PROTOPLASTS_V2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Protoplasts_v2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Protoplasts_v2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Protoplasts_v2

% Last Modified by GUIDE v2.5 06-Apr-2018 14:50:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Protoplasts_v2_OpeningFcn, ...
                   'gui_OutputFcn',  @Protoplasts_v2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Protoplasts_v2 is made visible.
function Protoplasts_v2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Protoplasts_v2 (see VARARGIN)


%Initialize the MM Core
import mmcorej.*;
mmc = CMMCore;
mmc.loadSystemConfiguration ('./Protoplasts2.cfg');
pause(1);
handles.mmc=mmc;
% mmc.setProperty("Camera","Binning",'1x1 (0)')
mmc.setProperty("Camera","PixelType",'8bit RGBA')
mmc.setProperty("Camera","Exposure",20);
% mmc.setProperty("Camera","Frame Rate",10.0058);
% mmc.setProperty("Camera","Pixel Clock",96.000);

%Initialize Arduino
comport=instrfindall;
delete(comport);
board=arduino();
handles.board=board;
handles.light_status=0;
writePWMDutyCycle(board,'D2',0);
handles.temperature_address=scanI2CBus(board);
handles.dev = i2cdev(board,char(handles.temperature_address(1)));

% Choose default command line output for Protoplasts_v2
handles.output = hObject;

% Update handles structure
set(handles.slider_movie, 'Visible', 'off')
guidata(hObject, handles);

% UIWAIT makes Protoplasts_v2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Protoplasts_v2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in push_connect.
function push_connect_Callback(hObject, eventdata, handles)
% hObject    handle to push_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%board=getappdata(hObject.Parent,'board');
power=get(handles.edit_power, 'String');
handles.power=str2num(power);
writePWMDutyCycle(handles.board,'D2',handles.power);
handles.light_status=1;
set(handles.push_connect,'BackgroundColor','green'); 
guidata(hObject, handles);

% --- Executes on button press in push_disconnect.
function push_disconnect_Callback(hObject, eventdata, handles)
% hObject    handle to push_disconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.power=0;
writePWMDutyCycle(handles.board,'D2',handles.power);
handles.light_status=0;
set(handles.push_connect,'BackgroundColor',[0.94 0.94 0.94]); 

guidata(hObject, handles);


% --- Executes on button press in push_live.
function push_live_Callback(hObject, eventdata, handles)
% hObject    handle to push_live (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.tmr = timer('ExecutionMode', 'FixedRate','Period', 1, 'TimerFcn', {@timer_live_Callback, handles.mmc, handles.board, handles, hObject})
    disp(handles.tmr);
    handles.live_status=1;
    set(handles.push_live,'BackgroundColor','green'); 
    start(handles.tmr);
    disp("Live mode started");
    guidata(hObject, handles);
    
% --- Executes on button press in push_stoplive.
function push_stoplive_Callback(hObject, eventdata, handles)
% hObject    handle to push_stoplive (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    stop(handles.tmr);
    delete(handles.tmr);
    handles.live_status=0;
    set(handles.push_live,'BackgroundColor',[0.94 0.94 0.94]); 
    disp("Live mode ended");
    guidata(hObject, handles);

function edit_delay_Callback(hObject, eventdata, handles)
% hObject    handle to edit_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delay=get(handles.edit_delay, 'string');
handles.delay=str2double(delay);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_delay_CreateFcn(hObject, ~, handles)
% hObject    handle to edit_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_acq.
function push_acq_Callback(hObject, eventdata, handles)
% hObject    handle to push_acq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 if handles.live_status==1
    stop(handles.tmr)
    delete(timerfind);
 end
handles.acq_status=1;
set(handles.push_acq,'BackgroundColor','green');
delay=get(handles.edit_delay, 'string');
handles.tmra = timer('ExecutionMode', 'FixedRate','Period', str2double(delay), 'TimerFcn', {@timer_acq_Callback, handles.mmc, handles.board, handles, hObject});
start(handles.tmra);
disp("Acquisition started");
% set(handles.slider_movie, 'Visible', 'on')
% set(handles.text_frame, 'Visible', 'on')
% set(handles.text_slidermin, 'Visible', 'on')
% set(handles.text_slidermax, 'Visible', 'on')
% set(handles.slider_movie, 'max',  handles.slider_max)
% set(handles.slider_movie, 'min', 1)
% set(handles.slider_movie, 'value', handles.slider_max)
% set(handles.text_slidermax, 'value', handles.slider_max)

guidata(hObject, handles);


% --- Executes on button press in push_stop_acq.
function push_stop_acq_Callback(hObject, eventdata, handles)
% hObject    handle to push_stop_acq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.tmra);
delete(timerfind);
handles.acq_status=0;
set(handles.push_acq,'BackgroundColor',[0.94 0.94 0.94]); 

% if handles.acq_status==1
%     stop(handles.tmr)
%     handles.acq_status=0;
% else
%     handles.acq_status=0;
% end
disp("Acquisition ended");
guidata(hObject, handles);

 
function edit_filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.filename=get(handles.edit_filename, 'string');
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in button_BW.
function button_BW_Callback(hObject, eventdata, handles)
% hObject    handle to button_BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button_BW

function timer_live_Callback(~, ~, mmc, board, handles, hObject)
    mmc.snapImage();
    img4 = mmc.getImage();  % returned as a 1D array of signed integers in row-major order
    width = mmc.getImageWidth();
    height = mmc.getImageHeight();
        if mmc.getBytesPerPixel == 2
            pixelType = 'uint16';
        else
            pixelType = 'uint8';
        end
    img4 = typecast(img4, pixelType);      % pixels must be interpreted as unsigned integers
    img4Red = reshape(img4(1:4:length(img4)),width, height); % image should be interpreted as a 2D array
    img4Green = reshape(img4(2:4:length(img4)),width, height); % image should be interpreted as a 2D array
    img4Blue = reshape(img4(3:4:length(img4)),width, height); % image should be interpreted as a 2D array
    img = cat(3, img4Red, img4Green, img4Blue);
    img = imrotate(img,-90,'bilinear');
    imshow(img, 'Parent', handles.axes1, 'InitialMagnification',20);
    %Affichage histogramme
    [yRed, x] = imhist(img4Red);
    [yGreen, x] = imhist(img4Green);
    [yBlue, x] = imhist(img4Blue);
    plot(handles.axes_divers,x, yRed, 'Red', x, yGreen, 'Green', x, yBlue, 'Blue');
    xlim(handles.axes_divers,[0 255])
    xlabel(handles.axes_divers,'Intensité');
    ylabel(handles.axes_divers,'Nombre de pixels');
    %Affichage Temperature
    tempC=ConvertTemperature(handles.dev);
    set(handles.text_celsius, 'String', strcat(num2str(tempC),' °C'));
    


function timer_acq_Callback(~, ~, mmc, board, handles, hObject)
    handles = guidata(hObject);
    handles.slider_max=1;
    %Mesure de l'intensité du fond sans LED
        writePWMDutyCycle(handles.board,'D2',0);
        mmc.snapImage();
        bgd = mmc.getImage();  % returned as a 1D array of signed integers in row-major order
        width = mmc.getImageWidth();
        height = mmc.getImageHeight();
            if mmc.getBytesPerPixel == 2
                pixelType = 'uint16';
            else
                pixelType = 'uint8';
            end
        bgd = typecast(bgd, pixelType);      % pixels must be interpreted as unsigned integers
        bgd4Red = reshape(bgd(1:4:length(bgd)),width, height); % image should be interpreted as a 2D array
        bgd4Green = reshape(bgd(2:4:length(bgd)),width, height); % image should be interpreted as a 2D array
        bgd4Blue = reshape(bgd(3:4:length(bgd)),width, height); % image should be interpreted as a 2D array
        %bgd = cat(3, bgd4Red, bgd4Green, bgd4Blue);
        mean_bgd=(1/3)*(mean2(bgd4Red)+mean2(bgd4Green)+mean2(bgd4Blue));
    
    %Acquisition de l'image
        power=get(handles.edit_power, 'String');
        handles.power=str2num(power);
        writePWMDutyCycle(handles.board,'D2',handles.power);
        mmc.snapImage();
        img4 = mmc.getImage();  % returned as a 1D array of signed integers in row-major order
        width = mmc.getImageWidth();
        height = mmc.getImageHeight();
            if mmc.getBytesPerPixel == 2
                pixelType = 'uint16';
            else
                pixelType = 'uint8';
            end
        img4 = typecast(img4, pixelType);      % pixels must be interpreted as unsigned integers
        img4Red = reshape(img4(1:4:length(img4)),width, height); % image should be interpreted as a 2D array
        img4Green = reshape(img4(2:4:length(img4)),width, height); % image should be interpreted as a 2D array
        img4Blue = reshape(img4(3:4:length(img4)),width, height); % image should be interpreted as a 2D array
        img = cat(3, img4Red, img4Green, img4Blue);
        mean_img=(1/3)*(mean2(img4Red)+mean2(img4Green)+mean2(img4Blue));
        handles.image=img;
        writePWMDutyCycle(handles.board,'D2',0);
        img = imrotate(img,-90,'bilinear');
        imshow(img, 'Parent', handles.axes1, 'InitialMagnification',20);
        
    %Récupération de l'horaire et date d'acquisition 
        time=SplitTimeString(now);
        set(handles.text_last, 'String', strcat('Dernière acquisition : ', datestr(datetime('now'))));
        
    %Sauvegarde des fichiers
        filename=strcat(get(handles.edit_filename, 'string'),'_', time,'.png');
        imwrite(img,char(filename));
        img = imresize(img,0.4);
        filename=strcat(get(handles.edit_filename, 'string'),'_s_',time,'.png');
        imwrite(img,char(filename));
        
    %Enregistrement de la température et de la luminosité
        tempC=ConvertTemperature(handles.dev);
        set(handles.text_celsius, 'String', strcat(num2str(tempC),' °C'));
        handles.metadata=strcat(get(handles.edit_filename, 'string'),'.txt');
        handles.recordtemperature = fopen(handles.metadata,'a+');
        %fprintf(handles.recordtemperature,'%6s %12s\n','TimeStamp','Temperature(°C^)');
        fprintf(handles.recordtemperature,'%f\t %f\t %f\t %f\n',time,tempC,mean_bgd,mean_img);
        fclose(handles.recordtemperature);
        
    %Affichage de la température et du ratio d'intensité lumineuse
        temperature_array=dlmread(handles.metadata);
        dim_array=size(temperature_array);
        handles.slider_max=dim_array(1);
        temperature_vector_array(:,:)=datevec(temperature_array(:,1));
        temperature_array(:,1)=etime(temperature_vector_array(:,:),temperature_vector_array(1,:));
        plot(handles.axes_celsius,temperature_array(:,1)/60,temperature_array(:,2));
        xlabel(handles.axes_celsius,'min');
        ylabel(handles.axes_celsius,'Température (°C)');
        set(handles.text_ratio, 'String', strcat('I/Ibgd = ', num2str(mean_img/mean_bgd)));
  guidata(hObject, handles);
      

function edit_power_Callback(hObject, eventdata, handles)
% hObject    handle to edit_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_power as text
%        str2double(get(hObject,'String')) returns contents of edit_power as a double
power=get(handles.edit_power, 'string');
handles.power=str2num(power);
if handles.light_status==1
    writePWMDutyCycle(handles.board,'D2',handles.power);
else
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_power_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider_movie_Callback(hObject, eventdata, handles)
% hObject    handle to slider_movie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    handles.frame=get(handles.slider_movie, 'value');
    handles.frame=round(handles.frame);
    file_array=dlmread(handles.metadata);
    name=strcat(get(handles.edit_filename, 'string'),'_', num2str(file_array(handles.frame,1),'.png'));
    img=imread(name);
    imshow(img, 'Parent', handles.axes1, 'InitialMagnification',40);
    



% --- Executes during object creation, after setting all properties.
function slider_movie_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_movie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
