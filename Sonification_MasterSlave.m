%% Init
% Setup defaults:
PsychDefaultSetup(2);

% Define control keys:
KbName('UnifyKeyNames');
ESCAPE = KbName('ESCAPE');

% Perform basic initialization of the sound driver:
InitializePsychSound;

% Number of physical channels to use on the real soundcard:
nrchannels = 2;

% Open and start physical sound card for playback (1) in master mode (8) = (1+8),
% with low-latency and high timing precision (1), with auto-selected default []
% samplingRate for device, to consume and output mixed sound from slaves to
% 'nrchannels' physical output channels:
pamaster = PsychPortAudio('Open', [], 1 + 8, 1, [], nrchannels);

% Retrieve auto-selected samplingRate:
status = PsychPortAudio('GetStatus', pamaster);
SamplingRate = status.SampleRate;

ScreenID = max(Screen('Screens'));
[ScreenWidth, ScreenHeight] = Screen(ScreenID, 'WindowSize');
SetMouse(ScreenWidth/2, ScreenHeight/2);

% Start master, wait (1) for start, return sound onset time in startTime.
% Slaves can be independently controlled in their timing, volume, content thereafter:
startTime = PsychPortAudio('Start', pamaster, [], [], 1);

% Create slave device 
paSlave1 = PsychPortAudio('OpenSlave', pamaster, 1, 2);
paSlave2 = PsychPortAudio('OpenSlave', pamaster, 1, 2);


% Start tone
FreqRange = [200, 1000];
y = mean(FreqRange) * 0.5;
Sound = MakeBeep(y, 0.1, SamplingRate);
PsychPortAudio('FillBuffer', paSlave1, [Sound; Sound]); 
PsychPortAudio('FillBuffer', paSlave2, zeros(2, length(Sound))); 

% Start playback with infinite (0) repetition of the 1 second sound signal,
% at time startTime + 1 second:
PsychPortAudio('Start', paSlave1, 0, startTime + 1);
PsychPortAudio('Start', paSlave2, 0, startTime + 1);
%PsychPortAudio('Volume', CurrentVol);


Buttons = zeros(1, 3); n = 1;
Oldx = ScreenWidth / 2; Oldy = ScreenHeight / 2;
%% Run loop
while ~any(Buttons)
    [KeyIsDown, ~, KeyInfo] = KbCheck;

    if KeyIsDown
        if find(KeyInfo) == ESCAPE
            break;
        end
    end

    [x, y, Buttons] = GetMouse;
    if x ~= Oldx || y ~= Oldy
        Oldx = x; Oldy = y;
        %disp(['PosX: ', num2str(x), ', PosY: ', num2str(y), ', Freq: ', num2str(CurrentFreq)]);
    
        CurrentFreq = round(FreqRange(1) + y / ScreenHeight * (FreqRange(2) - FreqRange(1)));
        CurrentVol  = [(x / (ScreenWidth) - 1) * -1, x / ScreenWidth];
    
        %wavedur = 1 / CurrentFreq;
        Sound = MakeBeep(CurrentFreq, 0.1, SamplingRate);
        OutputTone = [Sound; Sound] .* CurrentVol';
        
        if n == 1
            % Sine tone, freq Hz:
            PsychPortAudio('FillBuffer', paSlave2, OutputTone, 1, 0); %0.5 * sin(support));

%             PsychPortAudio('Start', paSlave2, 0);
%             WaitSecs('YieldSecs', 0.050);
%             PsychPortAudio('Stop', paSlave1);
            n = 2;
        else
            % Sine tone, freq Hz:
            PsychPortAudio('FillBuffer', paSlave1, OutputTone, 1, 0); %0.5 * sin(support));

%             PsychPortAudio('Start', paSlave1, 0);
%             WaitSecs('YieldSecs', 0.050);
%             PsychPortAudio('Stop', paSlave2);
           
            n = 1;
        end
    end
end

PsychPortAudio('Stop', paSlave1);
PsychPortAudio('Stop', paSlave2);
PsychPortAudio('Close');

% That's it. Everything stopped and silent. Close all devices, release all
% ressources, shutdown the driver:
PsychPortAudio('Close');
fprintf('Finished. Bye!\n');