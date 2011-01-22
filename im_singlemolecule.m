
%%                  im_singlemolecule.m  Multi Channel
% Alistair Boettiger                                  Date Begund: 01/21/11
% Levine Lab, UC Berkeley                        Version Complete:  
% Functionally complete                             Last Modified: 01/21/11
% 
% 
%
%%  Important Notes:
% % This version written for Mac.  To impliment in PC just change directory
% paths from using '/' to using '\'.  
%
% 
% % Load these default parameters into your file directory the first time
% you run so that system does not give data upload errors.  
%
% pars = {'','','','',' ',' '}; save singlemolecule_pars0 pars 
% 
%
%



%% Overview:
%
%  This code uses DNA staining to associate cytoplasmic domains with the
%  nearest nucleus.  High reslolution 
%
%
%% Required subroutines
% fxn_nuc_seg.m  -- segmentation filter, identifies all nuclei
% fxn_nuc_reg.m -- expands nuclei to assign all regions of embryo to one
% nuclei or another.
%
%
% 
%% Updates: 
%   Each step now has independent defaults (better in practice) 
%   03/05/10 Rewrite code to use diff of gaussians and absolute intensities
%       to ID nascent transcripts.  
%   Rewrite code to use nuclei cell mask and both nascent transcripts and
%         cytoplasmic transcripts to determine regions.  03/02/10  
%   First exon to nascent comparison version developed: 
%         im_singlemolecule.m 12/02/09
%   multichannel edition developed 08/10/09
%   Fixed bug in step 2 to enable histequalization and background
%   subtraction
% 07/27/10 changed Gaussian filter to use difference of Gaussian filtered
% images rather than a single mexican hat (6x speedup). 
% 08/07/10 moved to GIT version management


function varargout = im_singlemolecule(varargin)
% IM_SINGLEMOLECULE M-file for im_singlemolecule.fig
%      IM_SINGLEMOLECULE, by itself, launches the GUI
%
%      IM_SINGLEMOLECULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IM_SINGLEMOLECULE.M with the given input arguments.
%
%      IM_SINGLEMOLECULE('Property','Value',...) creates a new IM_SINGLEMOLECULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before im_singlemolecule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to im_singlemolecule_OpeningFcn via varargin.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help im_singlemolecule
% Last Modified by GUIDE v2.5 21-Jan-2011 18:33:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @im_singlemolecule_OpeningFcn, ...
                   'gui_OutputFcn',  @im_singlemolecule_OutputFcn, ...
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


% --- Executes just before im_singlemolecule is made visible.
function im_singlemolecule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to im_singlemolecule (see VARARGIN)
   handles.output = hObject; % Choose default command line output for im_nucdots_v5
  
   
   
   
  % Some initial setup 
      % Folder to save .mat data files in.  
    handles.fdata = '/Users/alistair/Documents/Berkeley/Levine_Lab/ImageProcessing/';
  
  
   handles.dotdata = zeros(1,1000);  % storage array for FACs measured
   handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels

    

    
    
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes im_singlemolecule wait for user response (see UIRESUME)
% uiwait(handles.figure1);







%=========================================================================%
%                          Primary Analysis Section                       %      
%=========================================================================%
% % All of the functional processing script is in this function
function run_Callback(hObject, eventdata, handles)
step = handles.step;

% Step 0: Load Data into script
if step == 0;
    disp('running...'); tic
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    [handles] = imload(hObject, eventdata, handles); % load new embryo
    toc
end

% Step 1: Max Project nuclear channel at 1024  1024 resoultion
if step == 1; 
    disp('running step 1...'); tic
    handles.mRNAchn1 = str2double(get(handles.in1,'String'));
    handles.mRNAchn2 = str2double(get(handles.in2,'String'));
    handles.NUCchn =  str2double(get(handles.in3,'String'));
    NucBlur = str2double(get(handles.in4,'String')); 
    
    nc = handles.NUCchn;
    
    [h,w] = size(handles.Im{1,1}{1});
    m = 1024/h;
    
    Zs = length(handles.Im); 
    nuc = uint16(zeros(1024,1024,nc)); 
    for i=1:Zs
        nuc(:,:,i) = imresize(handles.Im{1,i}{nc},m); % 2
    end
    In = max(nuc,[],3); % perform max project
    In = uint8(  255*(1-double(In)./2^16)); % convert to uint8
    figure(1); clf; subplot(1,2,1); imshow(In);
    In = imclose(In,strel('disk',NucBlur));
    figure(1);subplot(1,2,2); imshow(In);
    
    handles.Zs = Zs;
    handles.In = In; 
    
    guidata(hObject, handles);  % update GUI data with new handles
    toc
end


% Step 2: Nuclear Threshold
if step == 2;
% load appropriate data
    disp('running step 2...'); tic
    FiltSize = str2double(get(handles.in1,'String'));  % 
    FiltStr = str2double(get(handles.in2,'String'));
    sigmaE = str2double(get(handles.in3,'String'));
    sigmaI = str2double(get(handles.in4,'String'));
    PercP = str2double(get(handles.in5,'String'));
    minN = str2double(get(handles.in6,'String'));   
    I = handles.In; 
    
  % get threshold image 'bw' and nuclei centroids 'cent'  
    [handles.bw,handles.cent] = fxn_nuc_seg(I,FiltSize,FiltStr,sigmaE,sigmaI,PercP,minN);
   
 % Save data values  
 %      handles.output = hObject; guidata(hObject, handles);   
     guidata(hObject, handles);  % update GUI data with new handles 
    toc;
end
 
% Step 3: Get Region for each Nuclei
if step == 3;   
    Mthink = str2double(get(handles.in1,'String'));  % 
    Mthin = str2double(get(handles.in2,'String'));
    Imnn = str2double(get(handles.in3,'String'));
    [H1,Nuc_overlay,conn_map,cell_bords] = fxn_nuc_reg(handles.In,handles.bw,Mthink,Mthin,Imnn);  

    
    figure(1); clf; imshow(In); hold on; plot(cell_bords);
    
    

    [h,w] = size(H1);

    Cell_bnd = false(h,w);
    Cell_bnd(cell_bords) = 1;
    % figure(5); clf; imshow(Cell_bnd);   
    Cell_bnd2 = imresize(Cell_bnd,2);  
    
    handles.H2 = imresize(H1,2,'nearest');
    handles.Cell_bnd2 = Cell_bnd2; 
    guidata(hObject, handles);  % update GUI data with new handles  
end



 
  % Step 4: Identify and count nascent transcripts 
 if step == 4   

    alphaE =   str2double(get(handles.in1,'String')); % alphaE = .955; %
    sigmaE =str2double(get(handles.in2,'String')); %    sigmaE = 2; %
    alphaI =str2double(get(handles.in3,'String')); %   alphaI = .98; % 
    min_int  = str2double(get(handles.in4,'String')); %   min_int  = .07; % 
    FiltSize = str2double(get(handles.in5,'String')); %   FiltSize = 20;% 
    min_size = str2double(get(handles.in6,'String')); %  min_size = 15; % 
    sigmaI = 1.25*sigmaE;
   
    % Build the Gaussian Filter   
    Ex = fspecial('gaussian',FiltSize,sigmaE); % excitatory gaussian
    Ix = fspecial('gaussian',FiltSize,sigmaI); % inhibitory gaussian
   
    DotData = cell(1,Zs); 
   for i=1:Zs
     DotData{i} = dotfinder(I2,alphaE,alphaI,Ex,Ix,min_int,min_size);
   end
   handles.DotData = DotData;
    guidata(hObject, handles);  % update GUI data with new handles  
    
 end


%========================================================================%
 %  end of functional processing script
 % The rest of this code is GUI manipulations







% --- Executes on button press in VarButton.
function VarButton_Callback(hObject, eventdata, handles)



% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %
%                        File managining scripts                          %  
% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %
% This function sets up the new steps with the appropriate input labels and
% defalut label parameters

function setup(hObject,eventdata,handles)
 if handles.step == 0; 
       load([handles.fdata, 'singlemolecule_pars0']); % pars = {'1','2','3','',' ',' '}; save([handles.fdata,'singlemolecule_pars0'], 'pars' );
        set(handles.in1label,'String',' ');
        set(handles.in1,'String', pars(1));
        set(handles.in2label,'String',' ');
        set(handles.in2,'String', pars(2));
       set(handles.in3label,'String',' ');
        set(handles.in3,'String', pars(3));
        set(handles.in4label,'String',' ');
        set(handles.in4,'String', pars(4));
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars(5));
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars(6));
            set(handles.VarButtonName,'String','');
%         % For aesthetics, grey out input 5 and 6
%         set(handles.in5label,'String',' '); 
%         set(handles.in5,'String',' ');
%         set(handles.in5,'BackgroundColor',[.7 .7 .7]); 
%         set(handles.in6label,'String',' '); 
%         set(handles.in6,'String',' ');
%         set(handles.in6,'BackgroundColor',[.7 .7 .7]);        
        dir = {
       'File should be a multichannel .tif image. Indicate which channel';
             '(1-3) contains mRNA and which contains nuclei. ';
             'Leave entry blank if no channel data.'; 
             'Also choose a file name to export data to.'} ;
        set(handles.directions,'String',dir); 
 end
  if handles.step == 1; 
       load singlemolecule_pars1; % pars = {'1','2','3','4',' ',' '}; save([handles.fdata,'singlemolecule_pars1'], 'pars' );
        set(handles.in1label,'String','mRNA 2 channel');
        set(handles.in1,'String', pars(1));
        set(handles.in2label,'String','mRNA 1 channel');
        set(handles.in2,'String', pars(2));
       set(handles.in3label,'String','Nuclei channel');
        set(handles.in3,'String', pars(3));
        set(handles.in4label,'String','Nuclear Blur');
        set(handles.in4,'String', pars(4));
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars(5));
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars(6));
            set(handles.VarButtonName,'String',''); 
        dir = {
       'Use imclose to homoginize nuclei before',...
       ' applying difference of Gaussian filter'} ;
        set(handles.directions,'String',dir); 
 end
 
 
 
   if handles.step == 2; 
       load singlemolecule_pars2; %pars = {'70','.999','40','37','99','10'};  save([handles.fdata,'singlemolecule_pars2'], 'pars' );
        set(handles.in1label,'String','min Nuc size'); % number of pixels in filter (linear dimension of a square)
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','Filter Strength'); % width of Gaussian in pixels
        set(handles.in2,'String',pars{2});
        set(handles.in3label,'String','Excitation Width');
        set(handles.in3,'String',pars{3}); 
        set(handles.in4label,'String','Inhibition Width');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String','Percent fused');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String','Erode fused');
        set(handles.in6,'String', pars{6});  
       dir = {
        'Step 1: Nuclear Threshold convert to binary image without losing or fusing nuclei';
        'Nuclear threshold chose a number from 0 to 1.';  
        'Optional filters, choose 1 to use the indicated filter or 0 to skip filter';
        'Evening filter requires an region diameter to sue in background subtraction'}; 
        set(handles.directions,'String',dir);
  end      
  if handles.step == 3;  % nuclei segmentation
     load singlemolecule_pars3; % pars = {'45','3','2','','','',''};  save([handles.fdata,'singlemolecule_pars3'], 'pars' );
        set(handles.in1label,'String','thicken nuclei'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','thin boundaries');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','erode'); 
        set(handles.in3,'String', pars{3});
        set(handles.in4label,'String',' ');
        set(handles.in4,'String', pars{4}); 
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars{5}); 
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars{6});  
                dir = {'Step 2: Map nuclear region';
    'nuclei expand until they collide.  Borders are assigned to different nuclei'} ;
        set(handles.directions,'String',dir); 
  end
  
  
  
  if handles.step == 4;
     load singlemolecule_pars4; % pars = {'.955','2','.98','07','20','10'}; save([handles.fdata,'singlemolecule_pars4'], 'pars' );
               set(handles.in1label,'String','\alpha_E'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','\sigma_E');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','\alpha_I'); 
        set(handles.in3,'String', pars{3}); 
        set(handles.in4label,'String','min intensity');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String','Filter Size');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String','min dot size');
        set(handles.in6,'String', pars{6});
        set(handles.VarButtonName,'String','Manual Reg Select');
   dir = {'Step 5: identify and count nascent transcripts of mRNA1.';
         'Uses Difference of Gaussian Filter \alpha_E*exp(-x^2/\sigma_E) - alpha_I*exp(-x^2/\sigma_I)'};
  set(handles.directions,'String',dir); 
  end
  
  


  
%   if handles.step == 9 
%           expname = get(handles.froot,'String');
%         set(handles.in1label,'String','Save name');
%         set(handles.in1,'String',expname);
%             set(handles.in2label,'String', 'Flip Horizontal?');
%         set(handles.in2,'String', '0');
%         set(handles.in3label,'String','Flip Vertical?');
%         set(handles.in3,'String', '0');
%         dir = {'Step 9: Data Export'; 'Choose an export filename and save data';
%         'images and all data from step 8 are saved'};
%     set(handles.directions,'String',dir);  
%   end
  
 
  
guidata(hObject, handles); % update GUI data with new labels





% --- Executes on button press in savePars.
function savePars_Callback(hObject, eventdata, handles)
   % record the values of the 6 input boxes for the step now showing
     p1 = get(handles.in1,'String');  
     p2 = get(handles.in2,'String');  
     p3 = get(handles.in3,'String');  
     p4 = get(handles.in4,'String');  
     p5 = get(handles.in5,'String');  
     p6 = get(handles.in6,'String');  
     pars = {p1, p2, p3, p4, p5, p6}; % cell array of strings
  % Export parameters 
     stp_label = get(handles.stepnum,'String');     
     savelabel = ['nucdot_exon_pars',stp_label];  
     % labeled as nucdot_parsi.mat where "i" is the step number 
     save(savelabel, 'pars');        % export values



% ----------------------STEP CONTROLS----------------------- %
% interfaces to main analysis code 
% --- Executes on button press in nextstep.
function nextstep_Callback(hObject, eventdata, handles)
handles.step = handles.step + 1; % forward 1 step
 set(handles.stepnum,'String', handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels

% --- Executes on button press in back.
function back_Callback(hObject, eventdata, handles)
handles.step = handles.step-1; % go back a step
 set(handles.stepnum,'String',handles.step); % Change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles); % update GUI data with new handles
    setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels
% -------------------------------------------------------- %


% --- Executes on button press in LoadNext.
function LoadNext_Callback(hObject, eventdata, handles)
    embn = str2num(handles.emb) + 1;  % update embryo number
    if embn<10
        emb = ['0',num2str(embn)];
    else
        emb = num2str(embn);
    end
    set(handles.embin,'String',emb); % update emb number field in GUI 
    handles.emb = emb; % update emb number in handles structure
[handles] = imload(hObject, eventdata, handles); % load new embryo
guidata(hObject, handles); % save for access by other functions


        %========== change source images ================%
function [handles] = imload(hObject, eventdata, handles)
handles.fin = get(handles.source,'String'); % folder
handles.fname = get(handles.froot,'String'); % embryo name
handles.emb = get(handles.embin,'String'); % embryo number

filename = [handles.fin,'/',handles.fname];
% load images
    jacquestiffread([filename,'.lsm']);
    handles.Im = loadlsm([filename,'.mat'],1);    
    
    Zs = length(handles.Im);
    [h,w] = size(handles.Im{1,1}{1});
    
    
    % display image stack at 512x512 resolution
    m = 512/h; 
    for j=1:Zs
            I = uint16(zeros(512,512,3));
            I(:,:,1) = imresize(handles.Im{1,j}{1},m);
            I(:,:,2) = imresize(handles.Im{1,j}{2},m);
            I(:,:,3) = imresize(handles.Im{1,j}{3},m);
            figure(1); clf; imshow(I); pause(.001); 
    end
    
    handles.output = hObject; 
    guidata(hObject,handles);% pause(.1);
    disp('image loaded'); 
        %====================================================%



% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %



% Automatically return the program to step 0 if the image source directory,
% file name, or image number are changed.  

function froot_Callback(hObject, eventdata, handles)
 handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels


function embin_Callback(hObject, eventdata, handles)
 handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels



function source_Callback(hObject, eventdata, handles)
 handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels


% Open file browser to select source folder 
function SourceBrowse_Callback(hObject, eventdata, handles)
 sourcefile = uigetdir; % prompts user to select directory
  set(handles.source,'String',sourcefile);





%% GUI Interface Setup
% The rest of this code just sets up the GUI interface


% --- Outputs from this function are returned to the command line.
function varargout = im_singlemolecule_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function embin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function source_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function froot_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function in2_Callback(hObject, eventdata, handles)
function in2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function in3_Callback(hObject, eventdata, handles)
function in3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function in1_Callback(hObject, eventdata, handles)
function in1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function in5_Callback(hObject, eventdata, handles)
function in5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function in6_Callback(hObject, eventdata, handles)
function in6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function in4_Callback(hObject, eventdata, handles)
function in4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function fout_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function fout_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)