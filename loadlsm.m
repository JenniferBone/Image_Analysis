
%%                                  loadlsm.m
% Jacques Bothma                                Date shared: 01/13/11
% now Alistair Boettiger
% Levine Lab                                    Last Modified: 01/13/11


function stack = loadlsm(name,N);
 

load(name)

global TIF;



stack=[];

filetemp= fopen(Datas.filename,'r','l');

for i=1:Datas.LSM_info.DimensionZ
    

TIF = Datas.([ 'Stack' num2str(N)]).(['Image' num2str(i)]).TIF;
IMG = Datas.([ 'Stack' num2str(N)]).(['Image' num2str(i)]).IMG;
TIF.file=filetemp;

TIF.StripCnt = 1;

            %read the image channels
            for c = 1:TIF.SamplesPerPixel
                IMG.data{c} = read_plane(0, IMG.width, IMG.height, c);
            end

            
                stack{1,i} = IMG.data;  % = orderfields(IMG);
%                img_read = img_read + 1;
            



end

fclose(TIF.file)

end



%% ===========================================================================

function plane = read_plane(offset, width, height, plane_nb)

global TIF;


%return an empty array if the sample format has zero bits
if ( TIF.BitsPerSample(plane_nb) == 0 )
    plane=[];
    return;
end

%fprintf('reading plane %i size %i %i\n', plane_nb, width, height);

%determine the type needed to store the pixel values:
switch( TIF.SampleFormat )
    case 1
        classname = sprintf('uint%i', TIF.BitsPerSample(plane_nb));
    case 2
        classname = sprintf('int%i', TIF.BitsPerSample(plane_nb));
    case 3
        if ( TIF.BitsPerSample(plane_nb) == 32 )
            classname = 'single';
        else
            classname = 'double';
        end
    otherwise
        error('unsuported TIFF sample format %i', TIF.SampleFormat);
end

% Preallocate a matrix to hold the sample data:
try
    plane = zeros(width, height, classname);
catch
    %compatibility with older matlab versions:
    eval(['plane = ', classname, '(zeros(width, height));']);
end

% Read the strips and concatenate them:
line = 1;
while ( TIF.StripCnt <= TIF.StripNumber )

    strip = read_strip(offset, width, plane_nb, TIF.StripCnt, classname);
    TIF.StripCnt = TIF.StripCnt + 1;
    % copy the strip onto the data
%    plane(:, line:(line+size(strip,2)-1)) = strip;
plane=strip;

    line = line + size(strip,2);
    if ( line > height )
        break;
    end

end

% Extract valid part of data if needed
if ~all(size(plane) == [width height]),
    plane = plane(1:width, 1:height);
    warning('tiffread2:Crop','Cropping data: found more bytes than needed');
end

% transpose the image (otherwise display is rotated in matlab)
%plane = plane';

end


%% ================== sub-functions to read a strip ===================

function strip = read_strip(offset, width, plane_nb, stripCnt, classname)

global TIF;

%fprintf('reading strip at position %i\n',TIF.StripOffsets(stripCnt) + offset);
StripLength = TIF.StripByteCounts(stripCnt) ./ TIF.BytesPerSample(plane_nb);

%fprintf( 'reading strip %i\n', stripCnt);
status = fseek(TIF.file, TIF.StripOffsets(stripCnt) + offset, 'bof');
if status == -1
    error('invalid file offset (error on fseek)');
end

classnameconv = ([classname '=>' classname]); %read from type to type

bytes = fread( TIF.file, StripLength, classnameconv, TIF.BOS );

if any( length(bytes) ~= StripLength )
    error('End of file reached unexpectedly.');
end

strip = reshape(bytes,width,StripLength / width);

end
