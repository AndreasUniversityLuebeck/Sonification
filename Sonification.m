%% Set defaults
InitializePsychSound(1);
dev = PsychPortAudio('GetDevices');

% do not open a PTB screen, just use the Matlab screen
B = get(0, 'ScreenSize');
%% Fill buffer version

% Device 6, playback only, default latency class, 48 Khz, 2 channels
% (stereo mode)
DevNo = 6;
Freq = 48000;
pahandle = PsychPortAudio('Open', DevNo, 1, 1, Freq, 2);

[x, y, Buttons] = GetMouse;
Sound = MakeBeep(x, 1, Freq);
PsychPortAudio('FillBuffer', pahandle, [Sound; Sound] * 0.5);
PsychPortAudio('Start', pahandle, 0);
oldx = x; oldy = y;

while ~any(Buttons)
    [x, y, Buttons] = GetMouse;
    if abs(x - oldx) > 5 || abs(y - oldy) > 5
        Sound = MakeBeep(abs(y), 1, Freq);
        % Weighting factor for each channel: when mouse is moved to the
        % left side, increase volume for left speaker and decrease volume
        % for right speaker and vice versa.
        Factor = [(x / (B(3)) - 1) * -1, x / B(3)];

        PsychPortAudio('Stop', pahandle, 0);
        PsychPortAudio('FillBuffer', pahandle, ...
           [Sound * Factor(1); Sound * Factor(2)]);
        PsychPortAudio('Start', pahandle, 0);
        oldx = x; oldy = y;
    end
end
PsychPortAudio('Stop', pahandle, 0);
PsychPortAudio('Close', pahandle);
%% Streaming refill buffer version
Freq = 48000;
% Device 6, playback only, default latency class, 48 Khz, 2 channels
% (stereo mode)
pahandle = PsychPortAudio('Open', 6, 1, 1, Freq, 2);

% keep hardware in "hot" mode
PsychPortAudio('RunMode', pahandle, 1); 

[x, y, Buttons] = GetMouse;
Sound = MakeBeep(x, 1, Freq);
Buffer = PsychPortAudio('CreateBuffer', [], [Sound; Sound] * 0.5);
PsychPortAudio('FillBuffer', pahandle, Buffer);
PsychPortAudio('Start', pahandle, 0);
oldx = x; oldy = y;

while ~any(Buttons)
    [x, y, Buttons] = GetMouse;
    if abs(x - oldx) > 5 || abs(y - oldy) > 5
        Sound = MakeBeep(abs(y), 1, Freq);
        % Weighting factor for each channel: when mouse is moved to the
        % left side, increase volume for left speaker and decrease volume
        % for right speaker and vice versa.
        Factor = [(x / (B(3)) - 1) * -1, x / B(3)];

        Buffer = PsychPortAudio('CreateBuffer', [], [Sound * Factor(1); Sound * Factor(2)]);
        %PsychPortAudio('Stop', pahandle, 0);
        PsychPortAudio('FillBuffer', pahandle, ...
           Buffer, 1, 0);
        %PsychPortAudio('Start', pahandle, 0);
        oldx = x; oldy = y;
    end
end
PsychPortAudio('Stop', pahandle, 0);
PsychPortAudio('Close', pahandle);
%% Refill buffer version
Freq = 48000;
pahandle = PsychPortAudio('Open', 6, 1, 1, Freq, 2);
PsychPortAudio('RunMode', pahandle, 1); % keep hardware in "hot" mode

[x, y, Buttons] = GetMouse;
Sound = MakeBeep(x, 1, Freq);
Buffer = PsychPortAudio('CreateBuffer', [], [Sound; Sound] * 0.5);
BufferHandle = PsychPortAudio('FillBuffer', pahandle, Buffer);
PsychPortAudio('Start', pahandle, 0);
oldx = x; oldy = y;

while ~any(Buttons)
    [x, y, Buttons] = GetMouse;
    if abs(x - oldx) > 5 || abs(y - oldy) > 5
        Sound = MakeBeep(abs(y), 1, Freq);
        % Weighting factor for each channel: when mouse is moved to the
        % left side, increase volume for left speaker and decrease volume
        % for right speaker and vice versa.
        Factor = [(x / (B(3)) - 1) * -1, x / B(3)];

        PsychPortAudio('RefillBuffer', pahandle, BufferHandle, ...
            [Sound * Factor(1); Sound * Factor(2)], 0);

        oldx = x; oldy = y;
    end
end
PsychPortAudio('Stop', pahandle, 0);
PsychPortAudio('Close', pahandle);

%% pure Matlab + GetMouse
B = get(0, 'ScreenSize');

frameLength = 1024;
SamplingRate = 44100;
deviceWriter = audioDeviceWriter('SampleRate', SamplingRate);
reverb = reverberator('SampleRate', SamplingRate, 'PreDelay', 0, ...
    'WetDryMix', 0.2);
[x, ~, Buttons] = GetMouse;
while ~any(Buttons)
    [x, y, Buttons] = GetMouse;
    
    Sound = MakeBeep(abs(x), frameLength/SamplingRate, SamplingRate)';
    Sound = Sound * y / B(4);
    reverbSignal = reverb(Sound);
    deviceWriter(reverbSignal);
end
release(deviceWriter);
release(reverb);

