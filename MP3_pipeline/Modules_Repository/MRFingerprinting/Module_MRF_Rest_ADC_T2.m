function [files_in,files_out,opt] = Module_MRF_Rest_ADC_T2(files_in,files_out,opt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialize the module's parameters with default values

if isempty(opt)
    
    %   % define every option needed to run this module
    % --> module_option(1,:) = field names
    % --> module_option(2,:) = defaults values
    module_option(:,1)   = {'dictionary_folder_filename',  'Dictionary Folder'};
    module_option(:,2)   = {'combUsed', 'Post/Pre'};
    module_option(:,3)   = {'indivNorm', 'Yes'};
    module_option(:,4)   = {'finalNorm', 'Yes'};
    module_option(:,5)   = {'prefix',           'MRF_Rest_'};
    module_option(:,6)   = {'method',           'ClassicMRF'};
    module_option(:,7)   = {'filtered',         'No'};
    
    module_option(:,8)   = {'RefInput',         1};
    module_option(:,9)   = {'InputToReshape',   1};
    module_option(:,10)   = {'Table_in',         table()};
    module_option(:,11)   = {'Table_out',        table()};
    module_option(:,12)   = {'folder',           table()};
    module_option(:,13)  = {'OutputSequenceName','AllName'};
    module_option(:,14)  = {'Params',           'Vf'};
    module_option(:,15)  = {'K',                50};
    module_option(:,16)  = {'Lw',               0};
    module_option(:,17)  = {'cstrS',            'd'};
    module_option(:,18)  = {'cstrG',            'd'};
    module_option(:,19)  = {'RelErr', 0.05};
    
    opt.Module_settings  = psom_struct_defaults(struct(),module_option(1,:),module_option(2,:));
    
    
    %% list of everything displayed to the user associated to their 'type'
    % --> user_parameter(1,:) = user_parameter_list
    % --> user_parameter(2,:) = user_parameter_type
    % --> user_parameter(3,:) = parameter_default
    % --> user_parameter(4,:) = psom_parameter_list
    % --> user_parameter(5,:) = Scans_input_DOF : Degrees of Freedom for the user to choose the scan
    % --> user_parameter(6,:) = IsInputMandatoryOrOptional : If none, the input is set as Optional.
    % --> user_parameter(7,:) = Help : text data which describe the parameter (it
    % will be display to help the user)
    user_parameter(:,1)   = {'Description','Text','','','','',...
        {
        'The MRF method is based on the paper : Ma, Dan, et al. "Magnetic resonance fingerprinting." Nature (2013)'
        'The regression method is based on the paper : Boux, Fabien, et al. [work in progress]'
        ''
        'Prerequisite:'
        '      - Put your dictionary files (pre and post simulated scans and/or MSME) in the ''data/dictionaries'' folder'
        '      - (or) Put your ''DICO.mat'' dictionary file ratio between the post and pre simulated scans in the ''data/dictionaries'' folder'
        '      - (or performing the regression method) Put your ''MODEL.mat'' model file'
        ''
        'The dictionaries are designed with the Mrvox simulation tool'
        'Dictionary is updated with T2 from the T2 map and restricted for ADC'
        }'};
    
    user_parameter(:,2)   = {'Select the MGEFIDSE Pre scan','1Scan','','',{'SequenceName'}, '',''};
    user_parameter(:,3)   = {'Select the MGEFIDSE Post scan','1Scan','','',{'SequenceName'}, '',''};
    user_parameter(:,4)   = {'Select the MSME scan','1Scan','','',{'SequenceName'}, '',''};
    user_parameter(:,5)   = {'Select the sequence combination to use', 'cell', {'Post/Pre','Pre-Post','MSME-Post/Pre','MSME-Pre-Post'}, 'combUsed', '','Mandatory', 'Combination of signals to use'};
    user_parameter(:,6)   = {'Normalize each signals', 'cell', {'Yes', 'No'}, 'indivNorm', '','Optional', 'Do you want to normalize (N2) each signal before concatenation? NB: MGEFIDSE are not normalized in case of Ratio'};
    user_parameter(:,7)   = {'Normalize final signal', 'cell', {'Yes', 'No'}, 'finalNorm', '','Optional', 'Do you want to normalize (N2) the final concatenation before MRF?'};
    
    s               = split(mfilename('fullpath'),'MP3_pipeline',1);
    folder_files	= dir(fullfile(s{1}, 'data/dictionaries/'));
    folder_files    = folder_files([folder_files.isdir]);
    opt.Module_settings.folder = fullfile(s{1}, 'data/dictionaries/');
    if isempty(folder_files), folder_files(1).name = ' '; end
    user_parameter(:,8)   = {'   .Dictionary folder','cell', {folder_files.name}, 'dictionary_folder_filename','','Mandatory',...
        {'Select the folder containing dico files (.json), ratio dico file (.mat) and/or model file (.mat)'}};
    
    user_parameter(:,9)   = {'   .Prefix','char', '', 'prefix', '', '',...
        {'Choose a prefix for your output maps'
        'WARNING: If selecting "R", make sure that the prefix does not contain any "R", as in "MRF"'
        }'};
    user_parameter(:,17)   = {'   .Smooth?','cell', {'Yes','No'}, 'filtered', '', '',...
        {'Select ''Yes'' to smooth the signals  (recommanded ''No'')'}};
    user_parameter(:,10)   = {'   .Parameters','check', ...
        {'Vf', 'VSI', 'R', 'SO2', 'DH2O', 'B0theta', 'khi', 'Hct', 'T2'},...
        'Params', '', '',...
        {'Select the parameters considered in the model (default ''Vf'')'
        'WARNING: If selecting "R", make sure that the prefix does not contain any "R", as in "MRF"'
        }'};
    user_parameter(:,11)   = {'   .Method','cell', {'ClassicMRF', 'RegressionMRF'}, 'method', '', '',...
        { 'Choose:'
        '	- ''ClassicMRF'' to use the Dan Ma method'
        '	- ''RegressionMRF'' to use the regression method'
        }'};
    user_parameter(:,12)   = {'   .Model settings (if the regression method is chosen)','Text','','','','',...
        {'Recommanded:'
        'K = 50'
        'Lw = 0'
        'cstr = ''d''.'
        }'};
    user_parameter(:,13)   = {'       .Number of regions','numeric','','K','','',...
        {'Recommanded: K = 50'
        'If K is -1, an automatic tuning of the parameter is performed using BIC (time-consuming)'
        }'};
    user_parameter(:,14)  = {'       .Number of additional unsupervised parameter','numeric','','Lw','','',...
        {'Recommanded: Kw = 0'
        'If Lw is -1, an automatic tuning of the parameter is performed using BIC (time-consuming)'
        }'};
    user_parameter(:,15)  = {'       .Model constraint on Sigma','cell',{'i*','i','d*','d',' '},'cstrS','','',...
        {'''d'' = diagonal'
        '''i'' = isotropic'
        '''*'' = equal for all K regions'
        }'};
    user_parameter(:,16)  = {'       .Model constraint on Gamma','cell',{'i*','i','d*','d',' '},'cstrG','','',...
        {'''d'' = diagonal'
        '''i'' = isotropic'
        '''*'' = equal for all K regions'
        }'};
    user_parameter(:,17)   = {'Select the T2 map to use for dico pre-processing','1Scan','','',{'SequenceName'}, 'Mandatory','If dico generated without T2, an exponential will be applied based on this map'};
    user_parameter(:,18)   = {'Select the scans to use for ADC reduction','1Scan','','',{'SequenceName'}, 'Mandatory','The dico will be restricted on the ADC dimension for each point'};
    user_parameter(:,19)   = {'Relative error tolerated on prior input value','numeric','','RelErr','','','Tolerance on the restriction'};
    
    VariableNames = {'Names_Display', 'Type', 'Default', 'PSOM_Fields', 'Scans_Input_DOF', 'IsInputMandatoryOrOptional','Help'};
    opt.table = table(user_parameter(1,:)', user_parameter(2,:)', user_parameter(3,:)', user_parameter(4,:)', user_parameter(5,:)', user_parameter(6,:)', user_parameter(7,:)', 'VariableNames', VariableNames);
    %%
    % So for no input file is selected and therefore no output
    % The output file will be generated automatically when the input file
    % will be selected by the user
    files_in.In1    = {''};
    files_out.In1   = {''};
    return
    
end
%%%%%%%%

if isempty(files_out)
    
    opt.Params = opt.Params(cell2mat(opt.Params(:,2)),1);
    
    opt.Table_out = opt.Table_in(1,:);
    
    for i = 1:numel(opt.Params)
        opt.Table_out(i,:) = opt.Table_out(1,:);
        opt.Table_out(i,:).Path = categorical(cellstr([opt.folder_out, filesep]));
        if strcmp(opt.OutputSequenceName, 'AllName')
            opt.Table_out.SequenceName(i) = categorical(cellstr([char(opt.prefix), char(opt.Params{i})]));
        elseif strcmp(opt.OutputSequenceName, 'Extension')
            opt.Table_out.SequenceName(i) = categorical(cellstr([char(opt.Table_out.SequenceName(i)), opt.Params{i}]));
        end
        opt.Table_out.Filename(i) = categorical(cellstr([char(opt.Table_out.Patient(i)), '_', char(opt.Table_out.Tp(i)), '_', char(opt.Table_out.SequenceName(i))]));
        opt.Table_out.IsRaw(i) = categorical(cellstr('0'));
        files_out.In1{i} = [char(opt.Table_out.Path(i)), char(opt.Table_out.Filename(i)) '.nii'];
    end
    
    if strcmp(opt.method,'RegressionMRF')
        nb = i;
        
        for i = 1:numel(opt.Params)
            opt.Table_out(nb+i,:) = opt.Table_out(1,:);
            
            opt.Table_out.Filename(nb+i) =  categorical(cellstr([char(opt.Table_out.Patient(i)), '_', char(opt.Table_out.Tp(i)), '_', char(opt.Table_out.SequenceName(i)) '_confidence']));
            opt.Table_out.SequenceName(nb+i) = categorical(cellstr([char(opt.prefix), char(opt.Params{i}), '_confidence']));
            
            files_out.In2{i} = [char(opt.Table_out.Path(nb+i)), char(opt.Table_out.Filename(nb+i)) '.nii'];
        end
    end
end


%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('MRF_MultiSeq:brick','Bad syntax, type ''help %s'' for more info.',mfilename)
end

%% If the test flag is true, stop here !

if opt.flag_test == 1
    return
end
[Status, Message, Wrong_File] = Check_files(files_in);
if ~Status
    error('Problem with the input file : %s \n%s', Wrong_File, Message)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.finalNorm = strcmp(opt.finalNorm, 'Yes');

% Read json files and create ratio dictionary
opt.dictionary_folder_filename = fullfile(opt.folder, opt.dictionary_folder_filename);

d = dir(opt.dictionary_folder_filename);
if contains(opt.combUsed, 'Pre')
    opt.dictionary_pre_filename     = d(contains({d.name}, 'PRE_'));
    if ~isempty(opt.dictionary_pre_filename)
        opt.dictionary_pre_filename     = opt.dictionary_pre_filename.name;
    end
    opt.dictionary_post_filename    = d(contains({d.name}, 'POST_'));
    if ~isempty(opt.dictionary_post_filename)
        opt.dictionary_post_filename    = opt.dictionary_post_filename.name;
    end
end

if contains(opt.combUsed, 'MSME')
    opt.dictionary_MSME_filename    = d(contains({d.name}, 'MSME'));
    if ~isempty(opt.dictionary_MSME_filename)
        opt.dictionary_MSME_filename    = opt.dictionary_MSME_filename.name;
    end
end
dico_filename   = [opt.dictionary_folder_filename filesep 'DICO.mat'];
model_filename  = [opt.dictionary_folder_filename filesep 'MODEL.mat'];


if (strcmp(opt.method, 'RegressionMRF') && ~exist(model_filename,'file')) || strcmp(opt.method, 'ClassicMRF')
    
    % If, dico exists, load it, else, create it and save it
    if exist(dico_filename,'file')
        load(dico_filename)
    else
        switch opt.combUsed
            case {'Post/Pre', 'Pre-Post'}
                %                 Pre     = loadjson([opt.dictionary_folder_filename filesep opt.dictionary_pre_filename]);
                %                 Post    = loadjson([opt.dictionary_folder_filename filesep opt.dictionary_post_filename]);
                
                Pre     = ReadJson([opt.dictionary_folder_filename filesep opt.dictionary_pre_filename]);
                Pre.MRSignals = reshape(Pre.MRSignals.x_ArrayData_(:,1) + 1i*Pre.MRSignals.x_ArrayData_(:,2),...
                    [Pre.MRSignals.x_ArraySize_(1), Pre.MRSignals.x_ArraySize_(2)]);
                
                Post     = ReadJson([opt.dictionary_folder_filename filesep opt.dictionary_post_filename]);
                Post.MRSignals = reshape(Post.MRSignals.x_ArrayData_(:,1) + 1i*Post.MRSignals.x_ArrayData_(:,2),...
                    [Post.MRSignals.x_ArraySize_(1), Post.MRSignals.x_ArraySize_(2)]);
                
                Dico.MRSignals{1}       = abs(Pre.MRSignals);
                Dico.MRSignals{2}       = abs(Post.MRSignals);
                Dico.Tacq               = Pre.Sequence.Tacq;
                Dico.Parameters.Par     = ReplaceNaNCell(Pre.Parameters.Par); % Parameters used to simulate X signals
                Dico.Parameters.Labels  = Pre.Parameters.Labels;
                clear Pre Post
                save(dico_filename,'Dico')
            case {'MSME-Post/Pre','MSME-Pre-Post'}
                %                 Pre     = loadjson([opt.dictionary_folder_filename filesep opt.dictionary_pre_filename]);
                %                 Post    = loadjson([opt.dictionary_folder_filename filesep opt.dictionary_post_filename]);
                
                Pre     = ReadJson([opt.dictionary_folder_filename filesep opt.dictionary_pre_filename]);
                Pre.MRSignals = reshape(Pre.MRSignals.x_ArrayData_(:,1) + 1i*Pre.MRSignals.x_ArrayData_(:,2),...
                    [Pre.MRSignals.x_ArraySize_(1), Pre.MRSignals.x_ArraySize_(2)]);
                
                Post     = ReadJson([opt.dictionary_folder_filename filesep opt.dictionary_pre_filename]);
                Post.MRSignals = reshape(Post.MRSignals.x_ArrayData_(:,1) + 1i*Post.MRSignals.x_ArrayData_(:,2),...
                    [Post.MRSignals.x_ArraySize_(1), Post.MRSignals.x_ArraySize_(2)]);
                
                %                 MSME    = loadjson([opt.dictionary_folder_filename filesep opt.dictionary_MSME_filename]);
                
                MSME     = ReadJson([opt.dictionary_folder_filename filesep opt.dictionary_pre_filename]);
                MSME.MRSignals = reshape(MSME.MRSignals.x_ArrayData_(:,1) + 1i*MSME.MRSignals.x_ArrayData_(:,2),...
                    [MSME.MRSignals.x_ArraySize_(1), MSME.MRSignals.x_ArraySize_(2)]);
                
                Dico.MRSignals{1}       = abs(Pre.MRSignals);
                Dico.MRSignals{2}       = abs(Post.MRSignals);
                Dico.MRSignals{3}       = abs(MSME.MRSignals);
                Dico.Tacq{1}            = Pre.Sequence.Tacq;
                Dico.Tacq{2}            = MSME.Sequence.Tacq;
                Dico.Parameters.Par     = ReplaceNaNCell(Pre.Parameters.Par); % Parameters used to simulate X signals
                Dico.Parameters.Labels  = Pre.Parameters.Labels;
                clear Pre Post MSME
                save(dico_filename,'Dico')
        end
    end
end

% After loading or creating the 'raw' dico, operations are still needed to
% adapt to the combination of sequences

switch opt.combUsed
    case 'Post/Pre'
        % Generate ratio signals from scans (and TODO: ROI if given)
        % TODO: what if In1 is the post and In2 the pre scan
        Xobs            = niftiread(files_in.In2{1}) ./ niftiread(files_in.In1{1});
        json_filename   = split(files_in.In2{1},'.');
        json_filename{2} = '.json';
        Obs             = ReadJson([json_filename{1} json_filename{2}]);
        
        % If necessary smooth observations
        if strcmp(opt.filtered, 'Yes') == 1
            p = 2;
            for x = 1:size(Xobs,1); for y = 1:size(Xobs,2); for z = 1:size(Xobs,3)
                        signal = squeeze(Xobs(x,y,z,:));
                        signal = filter(ones(1, p)/p, 1, [signal(1); signal; signal(end)]);
                        %     	Xobs(x,y,z,:) = conv(signal, gaussian_window, 'valid');
                        Xobs(x,y,z,:) = signal(2:end-1);
                    end; end; end
        end
        Xobs        = permute(Xobs, [1 2 4 3]);
        
        % Reformat dico (not needed if MODEL is already computed)
        if strcmp(opt.method, 'ClassicMRF') || ~exist(model_filename,'file')
            tmp = nan(size(Dico.MRSignals{1},1), length(Obs.EchoTime.value'));
            if size(Xobs,3) ~= size(Dico.MRSignals{1},2)
                warning('Sizes of scans and dictionary MR signals are differents: dictionary MR signals reshaped')
                for i = 1:size(Dico.MRSignals{1},1)
                    tmp(i,:) = interp1(Dico.Tacq(1:size(Dico.MRSignals{1},2)), Dico.MRSignals{2}(i,:)./Dico.MRSignals{1}(i,:), Obs.EchoTime.value'*1e-3);
                end
            else
                tmp = Dico.MRSignals{2}./Dico.MRSignals{1};
            end
            Dico.MRSignals = tmp;
            Dico.Tacq   = Obs.EchoTime.value'*1e-3;
            %remove row containning nan values
            nn = ~any(isnan(Dico.MRSignals),2);
            Dico.MRSignals = Dico.MRSignals(nn,:);
            Dico.Parameters.Par = Dico.Parameters.Par(nn,:);
%             Tmp{1}      = Dico;
        end
        
        %         if strcmp(opt.indivNorm, 'Yes') % Normalize nifti signals
        %             for x = 1:size(XobsPre,1); for y = 1:size(XobsPre,2); for z = 1:size(XobsPre,3)
        %                 XobsPre(x,y,z,:) = XobsPre(x,y,z,:)./(sqrt(sum(XobsPre(x,y,z,:).^2)));
        %                 XobsPost(x,y,z,:) = XobsPost(x,y,z,:)./(sqrt(sum(XobsPost(x,y,z,:).^2)));
        %             end; end; end
        %         end
        %         timeDim         = find(size(XobsPre)==length(Obs.EchoTime.value));
        %         Xobs            = cat(timeDim, XobsPre, XobsPost);
        %         Xobs            = permute(Xobs, [1 2 4 3]);
        
    case 'Pre-Post'
        XobsPre             = niftiread(files_in.In1{1});
        XobsPost            = niftiread(files_in.In2{1});
        json_filename       = split(files_in.In2{1},'.');
        json_filename{2}    = '.json';
        Obs                 = ReadJson([json_filename{1} json_filename{2}]);
        
        % If necessary smooth observations
        if strcmp(opt.filtered, 'Yes') == 1
            p = 2;
            for x = 1:size(XobsPre,1); for y = 1:size(XobsPre,2); for z = 1:size(XobsPre,3)
                        % Pre
                        signalPre = squeeze(XobsPre(x,y,z,:));
                        signalPre = filter(ones(1, p)/p, 1, [signalPre(1); signalPre; signalPre(end)]);
                        XobsPre(x,y,z,:) = signalPre(2:end-1);MyPipeline
                        % Post
                        signalPost = squeeze(XobsPost(x,y,z,:));
                        signalPost = filter(ones(1, p)/p, 1, [signalPost(1); signalPost; signalPost(end)]);
                        XobsPost(x,y,z,:) = signalPost(2:end-1);
                    end; end; end
        end
        
        if strcmp(opt.indivNorm, 'Yes') % Normalize nifti signals
            for x = 1:size(XobsPre,1); for y = 1:size(XobsPre,2); for z = 1:size(XobsPre,3)
                        XobsPre(x,y,z,:) = XobsPre(x,y,z,:)./(sqrt(sum(XobsPre(x,y,z,:).^2)));
                        XobsPost(x,y,z,:) = XobsPost(x,y,z,:)./(sqrt(sum(XobsPost(x,y,z,:).^2)));
                    end; end; end
        end
        timeDim         = 4;%find(size(XobsPre)==length(Obs.EchoTime.value));
        Xobs            = cat(timeDim, XobsPre, XobsPost);
        Xobs            = permute(Xobs, [1 2 4 3]);
        XobsPre         = permute(XobsPre, [1 2 4 3]);
        
        % Reformat dico (not needed if MODEL is already computed)
        if strcmp(opt.method, 'ClassicMRF') || ~exist(model_filename,'file')
            tmpPre = nan(size(Dico.MRSignals{1},1), length(Obs.EchoTime.value'));
            tmpPost = nan(size(Dico.MRSignals{1},1), length(Obs.EchoTime.value'));
            if size(XobsPre,3) ~= size(Dico.MRSignals{1},2)
                warning('Sizes of scans and dictionary MR signals are differents: dictionary MR signals reshaped')
                for i = 1:size(Dico.MRSignals{1},1)
                    tmpPre(i,:) = interp1(Dico.Tacq(1:size(Dico.MRSignals{1},2)), Dico.MRSignals{1}(i,:), Obs.EchoTime.value'*1e-3);
                    if strcmp(opt.indivNorm, 'Yes') % Normalize dico
                        tmpPre(i,:) = tmpPre(i,:)./(sqrt(sum(tmpPre(i,:).^2)));
                    end 
                    tmpPost(i,:) = interp1(Dico.Tacq(1:size(Dico.MRSignals{1},2)), Dico.MRSignals{2}(i,:), Obs.EchoTime.value'*1e-3);
                    if strcmp(opt.indivNorm, 'Yes') % Normalize dico
                        tmpPost(i,:) = tmpPost(i,:)./(sqrt(sum(tmpPost(i,:).^2)));
                    end
                end
                tmp = cat(2, tmpPre, tmpPost);
            else
                tmp = cat(2, Dico.MRSignals{1}, Dico.MRSignals{2});
            end
            
            Dico.MRSignals      = tmp;
            clear tmp;
            Dico.Tacq           = Obs.EchoTime.value'*1e-3;
            %remove row containning nan values
            nn                  = ~any(isnan(Dico.MRSignals),2);
            Dico.MRSignals      = Dico.MRSignals(nn,:);
            Dico.Parameters.Par = Dico.Parameters.Par(nn,:);
            %Tmp{1}              = Dico;
        end
        %end
        
    case 'MSME-Pre-Post'
        XobsPre             = niftiread(files_in.In1{1});
        XobsPost            = niftiread(files_in.In2{1});
        XobsMSME            = niftiread(files_in.In3{1});
        json_filename       = split(files_in.In2{1},'.');
        json_filename{2}    = '.json';
        Obs                 = ReadJson([json_filename{1} json_filename{2}]);
        
        % If necessary smooth observations
        if strcmp(opt.filtered, 'Yes') == 1
            p = 2;
            for x = 1:size(XobsPre,1); for y = 1:size(XobsPre,2); for z = 1:size(XobsPre,3)
                        % Pre
                        signalPre = squeeze(XobsPre(x,y,z,:));
                        signalPre = filter(ones(1, p)/p, 1, [signalPre(1); signalPre; signalPre(end)]);
                        XobsPre(x,y,z,:) = signalPre(2:end-1);
                        % Post
                        signalPost = squeeze(XobsPost(x,y,z,:));
                        signalPost = filter(ones(1, p)/p, 1, [signalPost(1); signalPost; signalPost(end)]);
                        XobsPost(x,y,z,:) = signalPost(2:end-1);
                        % MSME
                        signalMSME = squeeze(XobsMSME(x,y,z,:));
                        signalMSME = filter(ones(1, p)/p, 1, [signalMSME(1); signalMSME; signalMSME(end)]);
                        XobsMSME(x,y,z,:) = signalMSME(2:end-1);
                    end; end; end
        end
        if strcmp(opt.indivNorm, 'Yes') % Normalize nifti signals
            for x = 1:size(XobsPre,1); for y = 1:size(XobsPre,2); for z = 1:size(XobsPre,3)
                        XobsPre(x,y,z,:) = XobsPre(x,y,z,:)./(sqrt(sum(XobsPre(x,y,z,:).^2)));
                        XobsPost(x,y,z,:) = XobsPost(x,y,z,:)./(sqrt(sum(XobsPost(x,y,z,:).^2)));
                        XobsMSME(x,y,z,:) = XobsMSME(x,y,z,:)./(sqrt(sum(XobsMSME(x,y,z,:).^2)));
                    end; end; end
        end
        timeDim         = 4;%find(size(XobsPre)==length(Obs.EchoTime.value));
        Xobs            = cat(timeDim, XobsMSME, XobsPre, XobsPost);
        Xobs            = permute(Xobs, [1 2 4 3]);
        XobsPre         = permute(XobsPre, [1 2 4 3]);
        
        % Reformat dico (not needed if MODEL is already computed)
        if strcmp(opt.method, 'ClassicMRF') || ~exist(model_filename,'file')
            tmpPre = nan(size(Dico.MRSignals{1},1), length(Obs.EchoTime.value'));
            tmpPost = nan(size(Dico.MRSignals{1},1), length(Obs.EchoTime.value'));
            
            if size(XobsPre,length(size(XobsPre))) ~= size(Dico.MRSignals{1},2)
                warning('Sizes of scans and dictionary MR signals are differents: dictionary MR signals reshaped')
                for i = 1:size(Dico.MRSignals{1},1)
                    tmpPre(i,:) = interp1(Dico.Tacq{1}(1:size(Dico.MRSignals{1},2)), Dico.MRSignals{1}(i,:), Obs.EchoTime.value'*1e-3);
                    tmpPost(i,:) = interp1(Dico.Tacq{1}(1:size(Dico.MRSignals{1},2)), Dico.MRSignals{2}(i,:), Obs.EchoTime.value'*1e-3);
                end
            end
            if strcmp(opt.indivNorm, 'Yes') % Normalize dico
                for i = 1:size(Dico.MRSignals{1},1)
                    tmpPre(i,:) = tmpPre(i,:)./(sqrt(sum(tmpPre(i,:).^2)));
                    tmpPost(i,:) = tmpPost(i,:)./(sqrt(sum(tmpPost(i,:).^2)));
                    Dico.MRSignals{3}(i,:) = Dico.MRSignals{3}(i,:)./(sqrt(sum(Dico.MRSignals{3}(i,:).^2)));
                end
            end
            tmp                 = cat(2, Dico.MRSignals{3}, tmpPre, tmpPost);
            Dico.MRSignals      = tmp;
            Dico.Tacq           = Obs.EchoTime.value'*1e-3;
            %remove row containning nan values
            nn                  = ~any(isnan(Dico.MRSignals),2);
            Dico.MRSignals      = Dico.MRSignals(nn,:);
            Dico.Parameters.Par = Dico.Parameters.Par(nn,:);
            %             Tmp{1}              = Dico;
        end
        
    case 'MSME-Post/Pre'
        Xobs                = niftiread(files_in.In2{1}) ./ niftiread(files_in.In1{1});
        XobsMSME            = niftiread(files_in.In3{1});
        json_filename       = split(files_in.In2{1},'.');
        json_filename{2}    = '.json';
        Obs                 = ReadJson([json_filename{1} json_filename{2}]);
        
        % If necessary smooth observations
        if strcmp(opt.filtered, 'Yes') == 1
            p = 2;
            for x = 1:size(Xobs,1); for y = 1:size(Xobs,2); for z = 1:size(Xobs,3)
                        % Ratio
                        signal = squeeze(Xobs(x,y,z,:));
                        signal = filter(ones(1, p)/p, 1, [signal(1); signal; signal(end)]);
                        Xobs(x,y,z,:) = signal(2:end-1);
                        % MSME
                        signalMSME = squeeze(XobsMSME(x,y,z,:));
                        signalMSME = filter(ones(1, p)/p, 1, [signalMSME(1); signalMSME; signalMSME(end)]);
                        XobsMSME(x,y,z,:) = signalMSME(2:end-1);
                    end; end; end
        end
        
        if strcmp(opt.indivNorm, 'Yes') % Normalize nifti signals
            for x = 1:size(XobsPre,1); for y = 1:size(XobsPre,2); for z = 1:size(XobsPre,3)
                        XobsMSME(x,y,z,:) = XobsMSME(x,y,z,:)./(sqrt(sum(XobsMSME(x,y,z,:).^2)));
                    end; end; end
        end
        timeDim         = find(size(Xobs)==length(Obs.EchoTime.value));
        XobsRatio       = Xobs; % create copy for dimension
        Xobs            = cat(timeDim, XobsMSME, Xobs);
        Xobs            = permute(Xobs, [1 2 4 3]);
        
        
        % Reformat dico (not needed if MODEL is already computed)
        if strcmp(opt.method, 'ClassicMRF') || ~exist(model_filename,'file')
            tmp = nan(size(Dico.MRSignals{1},1), length(Obs.EchoTime.value'));
            if size(XobsPre,length(size(XobsRatio))) ~= size(Dico.MRSignals{1},2)
                warning('Sizes of scans and dictionary MR signals are differents: dictionary MR signals reshaped')
                for i = 1:size(Dico.MRSignals{1},1)
                    tmp(i,:) = interp1(Dico.Tacq(1:size(Dico.MRSignals{1},2)), Dico.MRSignals{2}(i,:)./Dico.MRSignals{1}(i,:), Obs.EchoTime.value'*1e-3);
                end
            end
            if strcmp(opt.indivNorm, 'Yes') % Normalize dico
                for i = 1:size(Dico.MRSignals{1},1)
                    Dico.MRSignals{3}(i,:) = Dico.MRSignals{3}(i,:)./(sqrt(sum(Dico.MRSignals{3}(i,:).^2)));
                end
            end
            tmp                 = cat(2, Dico.MRSignals{3}, tmp);
            Dico.MRSignals      = tmp;
            Dico.Tacq           = Obs.EchoTime.value'*1e-3;
            %remove row containning nan values
            nn                  = ~any(isnan(Dico.MRSignals),2);
            Dico.MRSignals      = Dico.MRSignals(nn,:);
            Dico.Parameters.Par = Dico.Parameters.Par(nn,:);
            %             Tmp{1}              = Dico;
        end
        
end %end switch

%% Iteration on T2 values
T2Path              = files_in.In4;
T2Map               = niftiread(T2Path{1});
T2Map               = round(T2Map);
%T2Values            = unique(T2Map(T2Map>0)); % get unique values (rounded to limit iterations)
colT2               = find(contains(cellfun(@char, Dico.Parameters.Labels, 'UniformOutput', 0), 'T2'));
minDicoT2           = min(Dico.Parameters.Par(:,colT2))*1e3; % min of the dico
maxDicoT2           = max(Dico.Parameters.Par(:,colT2))*1e3; % max of the dico
T2Map(T2Map*(1+opt.RelErr) < minDicoT2) = nan;
T2Map(T2Map*(1-opt.RelErr) > maxDicoT2) = nan;
T2Values            = unique(T2Map(T2Map>0)); % get unique values (rounded to limit iterations)

ADCPath             = files_in.In5;
ADCMap              = niftiread(ADCPath{1});
ADCValues           = round(ADCMap); % units in µm2/s
colADC              = find(contains(cellfun(@char, Dico.Parameters.Labels, 'UniformOutput', 0), 'DH2O'));
minDicoADC          = min(Dico.Parameters.Par(:,colADC))*1e12; % min of the dico
maxDicoADC          = max(Dico.Parameters.Par(:,colADC))*1e12; % max of the dico
ADCValues(ADCValues*(1+opt.RelErr) < minDicoADC) = nan;
ADCValues(ADCValues*(1-opt.RelErr) > maxDicoADC) = nan;

nanMap = isnan(ADCValues) | isnan(T2Map);

% Remove values outside the dico (with error range)
%[nanRow, nanCol, nanSl] = ind2sub(size(ADCValues), [find(ADCValues < minDicoADC* (1-opt.RelErr)); find(ADCValues > maxDicoADC *(1+opt.RelErr))]); % Get coordinates of points that will not fit the dico
%ADCValues               = ADCValues(minADC * (1-opt.RelErr) <= ADCValues);
%ADCValues               = ADCValues(ADCValues <= maxADC *(1+opt.RelErr));

if nnz(isnan(nanMap))
    warning('%i voxels will not be evaluated as their T2 or ADC value falls outside the dictionary range', nnz(isnan(nanMap)))
    %ADCValues(nanRow, nanCol, nanSl) = NaN; %marche pas
%     for i = 1:numel(nanRow)
%         ADCValues(nanRow(i), nanCol(i), nanSl(i)) = NaN;
%     end
end
check=0;
%% Dico Restriction
for v=1:numel(T2Values)
    
    if isnan(T2Values(v)) %If value at this iteration is nan, don't consider it
        continue
    end
        
    [row, col, sl] = ind2sub(size(T2Map), find(T2Map == T2Values(v))); % Get coordinates of voxels considered at this iteration
    
     % remove dico entries out of tolerated range
    toRemoveInf     = Dico.Parameters.Par(:,colT2)*1e3 <= T2Values(v)*(1-opt.RelErr);
    toRemoveSup     = Dico.Parameters.Par(:,colT2)*1e3 >= T2Values(v)*(1+opt.RelErr);
    toKeep          = ~(toRemoveInf + toRemoveSup);

    if isempty(toKeep)
        warning('T2 value %i could not be evaluated as restricted dico is empty\n', T2Values(v))
    end

    % Copying the restricted dico
    T2Rest.MRSignals = Dico.MRSignals(toKeep, :);
    T2Rest.Parameters.Par = Dico.Parameters.Par(toKeep, :);
    T2Rest.Parameters.Labels = Dico.Parameters.Labels;    
    
    %% Iteration on ADC values
    for Vox = 1:numel(row)
        Tmp{1} = T2Rest;
        locADC = ADCValues(row(Vox), col(Vox), sl(Vox));
        if isnan(locADC)
            %fprintf('Local ADC was nan\n')
            continue
        end
        check = check+1;
        % Remove dico entries where ADC does not match that of current
        % voxel
        %keptValuesInf  = find(Dico.Parameters.Par(:,colNb)*1e12 <= locADC*(1+opt.RelErr));
        %keptValuesSup  = find(locADC*(1-opt.RelErr) <= Dico.Parameters.Par(keptValuesInf,colNb)*1e12); 
        
        toRemoveInf     = Tmp{1}.Parameters.Par(:,colADC)*1e12 <= locADC*(1-opt.RelErr);
        toRemoveSup     = Tmp{1}.Parameters.Par(:,colADC)*1e12 >= locADC*(1+opt.RelErr);
        toKeep          = ~(toRemoveInf + toRemoveSup);
        
        if isempty(toKeep)
            warning('No Dico entry for double restriction T2 = %i and ADC = %i', T2Values(v),locADC)
        end
        
        Tmp{1}.MRSignals = Tmp{1}.MRSignals(toKeep, :);
        Tmp{1}.Parameters.Par = Tmp{1}.Parameters.Par(toKeep, :);
%         Tmp{1}.MRSignals = Tmp{1}.MRSignals(keptValuesSup, :);
%         Tmp{1}.Parameters.Par = Dico.Parameters.Par(keptValuesSup, :);
        Tmp{1}.Parameters.Labels = Tmp{1}.Parameters.Labels;
        
        localXobs = Xobs(row(Vox), col(Vox),: , sl(Vox)); %Xobs : X, Y, Time, Z
        
        %% Compute MRF/regression
        switch opt.method
            case 'ClassicMRF'
                % TODO: find something nicer than this permute trick
                Estimation  = AnalyzeMRImages_Chunk(localXobs,Tmp,opt.method, [], [], [], opt.finalNorm);
                Map.Y       = permute(Estimation.GridSearch.Y, [1 2 4 3]);
                
            case 'RegressionMRF'
                %Compute the learing only one time per dictionar
                if exist(model_filename,'file')
                    load(model_filename,'Parameters','labels');
                    Estimation = AnalyzeMRImages(Xobs, [], opt.method, Parameters);
                    
                    Tmp{1}.Parameters.Labels = labels;
                else
                    count = 1;
                    
                    for z = 1:length(Dico.Parameters.Labels)
                        tmp = split(Dico.Parameters.Labels{z},'.',2);
                        if any(strcmp(tmp{end}, opt.Params))
                            params.Par(:,count)     = Tmp{1}.Parameters.Par(:,z);
                            params.Labels{count}    = Tmp{1}.Parameters.Labels{z};
                            count = count +1;
                        end
                    end
                    Tmp{1}.Parameters = params;
                    
                    % Parameters of the regression
                    clear Parameters
                    if opt.K >= 0,  Parameters.K = opt.K; end
                    if opt.Lw >= 0, Parameters.Lw = opt.Lw; end
                    if strcmp(opt.cstrS,' '), opt.cstrS = ''; end
                    if strcmp(opt.cstrG,' '), opt.cstrG = ''; end
                    Parameters.cstr.Sigma   = opt.cstrS;
                    Parameters.cstr.Gammat  = opt.cstrG;
                    Parameters.cstr.Gammaw  = '';
                    
                    [Estimation, Parameters] = AnalyzeMRImages(Xobs, Tmp, opt.method, Parameters);
                    
                    labels      = Tmp{1}.Parameters.Labels;
                    save(model_filename,'Parameters', 'labels')
                end
                
                Map.Y   = permute(Estimation.Regression.Y, [1 2 4 3]);
                Map.Std	= permute(Estimation.Regression.Cov, [1 2 4 3]).^.5;
        end
        %% Extract maps (and modify unit if necessary)
        count = 1;
        for k = 1:length(Tmp{1}.Parameters.Labels)
            tmp = split(Tmp{1}.Parameters.Labels{k},'.',2);
            if any(strcmp(tmp{end}, opt.Params))
                
                Labels{count} = tmp{end};
                
                j = 1;
                switch tmp{end}
                    %If the ression method is performed, extract also the confidence maps
                    case {'Vf', 'SO2'} %convert to percent
                        %for j = 1:numel(row)
                            MapStruct{count}(row(Vox), col(Vox), sl(Vox))     = 100*Map.Y(j,:,:,k);
                            if strcmp(opt.method, 'RegressionMRF')
                                StdStruct{count}(row(Vox), col(Vox), sl(Vox)) = 100*Map.Std(j,:,:,k);
                            end
                        %end
                    case {'VSI', 'R'} % convert m to µm
                        %for j = 1:numel(row)
                            MapStruct{count}(row(Vox), col(Vox), sl(Vox))     = 1e6*Map.Y(j,:,:,k);
                            if strcmp(opt.method, 'RegressionMRF')
                                StdStruct{count}(row(Vox), col(Vox), sl(Vox))	= 1e6*Map.Std(j,:,:,k);
                            end
                        %end
                    case 'T2' % convert s to ms
                        %for j = 1:numel(row)
                            MapStruct{count}(row(Vox), col(Vox), sl(Vox))     = 1e3*Map.Y(j,:,:,k);
                            if strcmp(opt.method, 'RegressionMRF')
                                StdStruct{count}(row(Vox), col(Vox), sl(Vox))	= 1e6*Map.Std(j,:,:,k);
                            end
                        %end
                    otherwise
                        %for j = 1:numel(row)
                            MapStruct{count}(row(Vox), col(Vox), sl(Vox)) 	= Map.Y(j,:,:,k);
                            if strcmp(opt.method, 'RegressionMRF')
                                StdStruct{count}(row(Vox), col(Vox), sl(Vox)) = 100*Map.Std(j,:,:,k);
                            end
                        %end
                end   % end switch tmp
                count   = count +1;
            end %end if any
        end % end for k in labels
    end % end for loop on ADC
end % end for loop on T2

%% Ensure output dimension is correct
if any(size(MapStruct{1}) ~= size(T2Map))
    [s1, s2, s3] = size(T2Map);
    for i = 1:numel(MapStruct)
        MapStruct{i}(s1, s2, s3) = 0;
    end
end

%% Put NaN where out of the dico
for i = 1:numel(MapStruct)
    MapStruct{i}(nanMap)= nan;
    %MapStruct{i}(ADCValues*(1+opt.RelErr) < minDicoADC) = nan;
    %MapStruct{i}(ADCValues*(1-opt.RelErr) > maxDicoADC) = nan;
%     for j = i:numel(nanRow)
%         MapStruct{i}(nanRow(j), nanCol(j), nanSl(j)) = nan;
%     end
end

%% Json processing
[path, name, ~] = fileparts(files_in.In1{1});
jsonfile = [path, '/', name, '.json'];
J       = ReadJson(jsonfile);
J       = KeepModuleHistory(J, struct('files_in',files_in, 'files_out', files_out, 'opt', opt, 'ExecutionDate', datestr(datetime('now'))), mfilename);

% Reoriented and save nifti maps
% nifti_header = spm_vol(files_in.In1{1});
info = niftiinfo(files_in.In1{1});
info.Filemoddate = char(datetime('now'));

for i = 1:length(files_out.In1)
    
    for j = 1:numel(Labels)
        
        if contains(files_out.In1{i},Labels{j})
            [path, name, ~] = fileparts(files_out.In1{i});
            WriteJson(J, [path, '/', name, '.json'])
            
            info.Filename = files_out.In1{i};
            info.ImageSize = size(MapStruct{j});
            info.PixelDimensions = info.PixelDimensions(1:length(size(MapStruct{j})));
            info.Datatype = class(MapStruct{j});
            niftiwrite(MapStruct{j}, files_out.In1{i}, info);
            
            
            if strcmp(opt.method, 'RegressionMRF')
                [path, name, ~] = fileparts(files_out.In2{i});
                WriteJson(J, [path, '/', name, '.json'])
                
                info.Filename = files_out.In2{i};
                info.ImageSize = size(StdStruct{j});
                info.PixelDimensions = info.PixelDimensions(1:length(size(StdStruct{j})));
                info.Datatype = class(StdStruct{j});
                niftiwrite(StdStruct{j}, files_out.In2{i}, info);
            end
        end
    end
end

