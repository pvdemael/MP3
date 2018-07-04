function [files_in,files_out,opt] = Module_ClusteringGMM(files_in,files_out,opt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% Initialize the module's parameters with default values 
if isempty(opt)
%  
%     %%   % define every option needed to run this module
%     % --> module_option(1,:) = field names
%     % --> module_option(2,:) = defaults values
    module_option(:,1)   = {'folder_out',''};
    module_option(:,2)   = {'flag_test',true};
    %module_option(:,4)   = {'OutputSequenceName','Prefix'};
    module_option(:,3)   = {'SlopeHeuristic', 'No'};
    module_option(:,4)   = {'NbClusters','5'};
    module_option(:,5)   = {'Normalization_mode', 'None'};
    module_option(:,6)   = {'Clip', 'No'};
    module_option(:,7)   = {'output_cluster_Name','Clust_GMM'};
    module_option(:,8)   = {'AutomaticJobsCreation', 'No'};
    module_option(:,9)   = {'RefInput',2};
    module_option(:,10)   = {'InputToReshape',2};
    module_option(:,11)   = {'Table_in', table()};
    module_option(:,12)   = {'Table_out', table()};
    opt.Module_settings = psom_struct_defaults(struct(),module_option(1,:),module_option(2,:));
%   
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
    'Gaussian Mixture Model Clustering'
    }'};

    user_parameter(:,2)   = {'Input Scans','XScan','','', {'SequenceName'},'Mandatory',...
         'The scans on which the clustering will be performed.'};
    user_parameter(:,3)   = {'ROI','1ROI','','',{'SequenceName'},'Mandatory',...
         'This ROI will select the pixels to apply the module to.'};
    user_parameter(:,4)   = {'Parameters','','','','','',''};
    user_parameter(:,5)   = {'   .Slope Heuristic','cell',{'No', 'Yes'},'SlopeHeuristic','','',...
        'This option allows to determine the optimal number of clusters of your data. Several models are tested, from 1 to a certain number of clusters (The following parameter) and the best one is chosen.'};
    user_parameter(:,6)   = {'   .Number of clusters','char','','NbClusters','','',...
        'Number of clusters in which will be sorted the data. If the slope heuristic parameter is set to ''yes'', this number will represent the maximum number of clusters that will be tested by the algorithm.'};
    user_parameter(:,7)   = {'   .Normalization Mode','cell',{'None', 'Patient by Patient', 'All Database'},'Normalization_mode','','',...
        'This module will create one cluster type of file for each input scan. '};
    user_parameter(:,8)   = {'   .Clip','cell',{'No', 'Yes'},'Clip','','',...
        'This module will create one cluster type of file for each input scan. '};
    user_parameter(:,9)   = {'   .Name of the resulting cluster','char','','output_cluster_Name','','',...
        'This module will create one cluster type of file for each input scan. '};


    VariableNames = {'Names_Display', 'Type', 'Default', 'PSOM_Fields', 'Scans_Input_DOF', 'IsInputMandatoryOrOptional', 'Help'};
    opt.table = table(user_parameter(1,:)', user_parameter(2,:)', user_parameter(3,:)', user_parameter(4,:)', user_parameter(5,:)', user_parameter(6,:)', user_parameter(7,:)', 'VariableNames', VariableNames);
%%
    
    % So for no input file is selected and therefore no output
    % The output file will be generated automatically when the input file
    % will be selected by the user
    files_in = {''};
    files_out = {''};
    return
  
end
%%%%%%%%


% if strcmp(files_out, '')
%     [Path_In2, Name_In2, ~] = fileparts(files_in.In2{1});
%     tags2 = opt.Table_in(opt.Table_in.Path == [Path_In2, filesep],:);
%     tags2 = tags2(tags2.Filename == Name_In2,:);
%     assert(size(tags2, 1) == 1);
%     tags_out_In2 = tags2;
%     tags_out_In2.IsRaw = categorical(0);
%     tags_out_In2.Path = categorical(cellstr([opt.folder_out, filesep]));
%     tags_out_In2.SequenceName = categorical(cellstr([opt.output_filename_ext, char(tags_out_In2.SequenceName)]));
%     tags_out_In2.Filename = categorical(cellstr([char(tags_out_In2.Patient), '_', char(tags_out_In2.Tp), '_', char(tags_out_In2.SequenceName)]));
%     f_out = [char(tags_out_In2.Path), char(tags_out_In2.Patient), '_', char(tags_out_In2.Tp), '_', char(tags_out_In2.SequenceName), '.nii'];
%     files_out.In2{1} = f_out;
%     opt.Table_out = tags_out_In2;
%     if isfield(files_in, 'In3')
%         for i=1:length(files_in.In3)
%             if ~isempty(files_in.In3{i})
%                 [Path_In3, Name_In3, ~] = fileparts(files_in.In3{i});
%                 tags3 = opt.Table_in(opt.Table_in.Path == [Path_In3, filesep],:);
%                 tags3 = tags3(tags3.Filename == Name_In3,:);
%                 assert(size(tags3, 1) == 1);
%                 tags_out_In3 = tags3;
%                 tags_out_In3.IsRaw = categorical(0);
%                 tags_out_In3.SequenceName = categorical(cellstr([opt.output_filename_ext, char(tags_out_In3.SequenceName)]));
%                 if tags_out_In3.Type == 'Scan'
%                     tags_out_In3.Path = categorical(cellstr([opt.folder_out, filesep]));
%                     f_out = [char(tags_out_In3.Path), char(tags_out_In3.Patient), '-', char(tags_out_In3.Tp), '-', char(tags_out_In3.SequenceName), '.nii'];
%                      tags_out_In3.Filename = categorical(cellstr([char(tags_out_In3.Patient), '-', char(tags_out_In3.Tp), '-', char(tags_out_In3.SequenceName)]));
%                 else
%                     f_out = [char(tags_out_In3.Path), char(tags_out_In3.Patient), '-', char(tags_out_In3.Tp), '-ROI-', char(tags_out_In3.SequenceName), '.nii'];
%                     tags_out_In3.Filename = categorical(cellstr([char(tags_out_In3.Patient), '-', char(tags_out_In3.Tp), '-ROI-', char(tags_out_In3.SequenceName)]));
%                 end
%                 files_out.In3{i} = f_out;
%                 opt.Table_out = [opt.Table_out ; tags_out_In3];
%             end
%         end
%     end
% end
Tag1 = 'Patient';
Tag2 = 'Tp';
Table_out = table();
if strcmp(files_out, '')
    databScans = opt.Table_in(opt.Table_in.Type == categorical(cellstr('Scan')),:);
    databROIs = opt.Table_in(opt.Table_in.Type == categorical(cellstr('ROI')),:);
    UTag1 = unique(databScans.(Tag1));
    UTag2 = unique(databScans.(Tag2));
    out_file = {};
    in_files = {};
    Tailles = [];
    for i=1:length(UTag1)
        for j=1:length(UTag2)
            datab = databScans(databScans.(Tag1) == UTag1(i),:);
            datab = datab(datab.(Tag2) == UTag2(j),:);
            Tailles = [Tailles size(datab,1)];
        end
    end
    MaxTaille = max(Tailles);
    TailleBin = Tailles == MaxTaille;
    ind = 0;
    
    for i=1:length(UTag1)
        for j=1:length(UTag2)
            ind = ind+1;
            if TailleBin(ind)
                DbRois = databROIs(databROIs.(Tag1) == UTag1(i),:);
                DbRois = DbRois(DbRois.(Tag2) == UTag2(j),:);
                if size(DbRois, 1) == 0
                    continue
                end
                datab = databScans(databScans.(Tag1) == UTag1(i),:);
                datab = datab(datab.(Tag2) == UTag2(j),:);
%                 fi = cell(size(datab,1),1);
%                 for k=1:size(datab,1)
%                     fi{k} = [char(datab.Path(k)), char(datab.Patient(k)), '_', char(datab.Tp(k)), '_', char(datab.SequenceName(k)), '.nii'];
%                 end
%                 in_files = [in_files ; fi];
                tags = databScans(1,:);
                tags.Patient = UTag1(i);
                tags.Tp = UTag2(j);
                tags.Type = categorical(cellstr('Cluster'));
                tags.IsRaw = categorical(1);
                Cluster_path = opt.folder_out; % strrep(opt.folder_out, 'Derived_data', 'ROI_data');
                tags.Path = categorical(cellstr([Cluster_path, filesep]));
                tags.SequenceName = categorical(cellstr([opt.output_cluster_Name]));
                tags.Filename = categorical(cellstr([char(tags.Patient), '_', char(tags.Tp), '_', char(tags.SequenceName)]));
                f_out = [char(tags.Path), char(tags.Patient), '_', char(tags.Tp), '_', char(tags.SequenceName), '.nii'];
                out_file = [out_file ; {f_out}];
                Table_out = [Table_out ; tags];
            end
        end
    end
    files_out.In1 = out_file;
    opt.Table_out = Table_out;
end


% 
% if strcmp(files_out, '')
%     for i=1:length(files_in.In2)
%         ROI = files_in.In2{i};
%         [Path_In, Name_In, ~] = fileparts(ROI);
%         tags = opt.Table_in(opt.Table_in.Path == [Path_In, filesep],:);
%         tags = tags(tags.Filename == Name_In,:);
%         assert(size(tags, 1) == 1);
%         tags_out = tags;
%         tags_out.Type = categorical(cellstr('Cluster'));
%         tags_out.IsRaw = categorical(0);
%         Cluster_path = opt.folder_out; % strrep(opt.folder_out, 'Derived_data', 'ROI_data');
%         tags_out.Path = categorical(cellstr([Cluster_path, filesep]));
%         tags_out.SequenceName = categorical(cellstr([opt.output_cluster_Name]));
%         tags_out.Filename = categorical(cellstr([char(tags_out.Patient), '_', char(tags_out.Tp), '_', char(tags_out.SequenceName)]));
%         f_out = [char(tags_out.Path), char(tags_out.Patient), '_', char(tags_out.Tp), '_', char(tags_out.SequenceName), '.nii'];
%         files_out.In2{i} = f_out;
%         opt.Table_out = [opt.Table_out ; tags_out];
%     end
%     
% end



%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('Module_Coreg_Est:brick','Bad syntax, type ''help %s'' for more info.',mfilename)
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

% FixedImInfo = niftiinfo(files_in.In1{1});
% [path, name, ~] = fileparts(files_in.In1{1});
% FixedImJsonfile = [path, filesep, name, '.json'];
% fid = fopen(FixedImJsonfile, 'r');
% raw = fread(fid, inf, 'uint8=>char');
% fclose(fid);
% %raw = reshape(raw, 1,length(raw));
% FixedImJSON = jsondecode(raw);


databScans = opt.Table_in(opt.Table_in.Type == categorical(cellstr('Scan')),:);
databROIs = opt.Table_in(opt.Table_in.Type == categorical(cellstr('ROI')),:);
UTag1 = unique(databScans.(Tag1));
UTag2 = unique(databScans.(Tag2));
in_files = {};
roi_files = {};
for i=1:length(UTag1)
    for j=1:length(UTag2)
        DbRois = databROIs(databROIs.(Tag1) == UTag1(i),:);
        DbRois = DbRois(DbRois.(Tag2) == UTag2(j),:);
        if size(DbRois, 1) == 0
            continue
        end
        roi = [char(DbRois.Path(1)), char(DbRois.Filename(1)), '.nii'];
        datab = databScans(databScans.(Tag1) == UTag1(i),:);
        datab = datab(datab.(Tag2) == UTag2(j),:);
        fi = cell(size(datab,1),1);
        for k=1:size(datab,1)
            fi{k} = [char(datab.Path(k)), char(datab.Filename(k)), '.nii'];
        end
        in_files = [in_files ; {fi}];
        roi_files = [roi_files ; {roi}];
    end
end









% ROI_nifti_header = spm_vol(files_in.In2{1});
% ROI = read_volume(ROI_nifti_header, ROI_nifti_header, 0, 'axial');
% NbVox = int64(sum(sum(sum(ROI))));
% Data = zeros(NbVox, length(files_in.In1));
All_Data = {};
ROI_nifti_header = cell(length(roi_files),1);
ROI = cell(length(roi_files),1);


for i=1:length(roi_files)
    roi_filename = roi_files{i};
    Files = in_files{i};
    ROI_nifti_header{i} = spm_vol(roi_filename);
    ROI{i} = read_volume(ROI_nifti_header{i}, ROI_nifti_header{i}, 0, 'axial');
    NbVox = int64(sum(sum(sum(ROI{i}))));
    Data = zeros(NbVox, length(Files));
    for j=1:length(Files)
        nifti_header = spm_vol(Files{j});
        ROI_NaN = ROI{i};
        ROI_NaN(ROI_NaN == 0) = NaN;
        input{j} = read_volume(nifti_header, ROI_nifti_header{i}, 0, 'axial').*ROI_NaN;
        Vec = mean(input{j},4);
        Vec(isnan(Vec)) = [];
        Data(:,j) = Vec.';
    end
    All_Data = [All_Data, {Data}];
end

Clust_Data_In = [];
for i=1:length(All_Data)
    Clust_Data_In = [Clust_Data_In ; All_Data{i}];
end


if strcmp(opt.Normalization_mode, 'All database')
%     Mean = nanmean(Data);
%     STD = nanstd(Data);
    Clust_Data_In = (Clust_Data_In-nanmean(Clust_Data_In))./nanstd(Clust_Data_In);
%     for i=1:numel(All_Pameter_list)
%         para_name = char(All_Pameter_list(i));
%         para_name = clean_variable_name(para_name);
%         eval(['tmp_mean = nanmean(data_in_table.' para_name ');']);
%         eval(['tmp_std = nanstd(data_in_table.' para_name ');']);
%         eval(['data_in_table.' para_name '=(data_in_table.' para_name ' - tmp_mean )/ tmp_std;']);
%     end
end





options = statset ( 'maxiter', 1000);
if strcmp(opt.SlopeHeuristic, 'Yes')
    
    % L'heuristique de pente utilise le coefficient directeur de le
    % regression lin�aire de la vraisemblance en fonction du
    % nombre de classes du modele. Afin d'avoir une regression
    % significative, on effectue cette regression sur au minimum 5 points.
    % Il faut donc calculer la vraisemblance sur 5 classes de plus que la
    % derni�re � tester.
    ptsheurist = str2double(opt.NbClusters) + 5;
    
    
    %Vecteur pour stocker la logvraisemblance
    loglike = zeros(1,ptsheurist);
    
    %On stocke les modeles calcules pour ne pas avoir a les recalculer une
    %fois le nombre de classes optimal trouve.
    modeles = cell(1,ptsheurist);
    
    parfor kk=1:ptsheurist
        
        %L'option "Replicate,10" signifie que l'on va calculer 10 fois le
        %modele en modifiant l'initialisation. Le modele renvoye est celui
        %de plus grande vraisemblance.
        modeles{kk} = fitgmdist( Clust_Data_In, kk, 'Options', options, 'Regularize', 1e-5, 'Replicates', 10);
        
        loglike(kk) = -modeles{kk}.NegativeLogLikelihood;
        
        %La ligne suivante permet uniquement de suivre l'avancement du
        %calcul des modeles
        disp(strcat('Modele_', num2str(kk)))
    end
    NbCartes = size(Clust_Data_In,2);
    
    %Le vecteur alpha contient les coefficients directeurs des regresions
    %lineaires de la logvraisemblance en fonction du nombre de classes du
    %modele. Sa ieme composante contient le coefficient directeur de la
    %regression lineaire de la log vraisemblance en fonction du nombre de
    %classes du modele en ne prenant pas en compte les i-1 premiers points.
    alpha = zeros(str2double(opt.NbClusters),2);
    
    %Le vecteur eqbic contient pour chaque valeur alpha l'equivalent BIC
    %applique a chaque valeur de la log vraisemblance. On obtient donc une
    %matrice ou chaque ligne correspond a l'equivalent BIC applique en
    %chaque valeur de la log vraisemblance pour une valeur de alpha. On
    %passe ainsi d'une ligne a l'autre en modifiant alpha. Dans l'optique
    %de tracer les courbes uniquement a partir du point i, la matrice est initialisee a la valeur NaN.
    eqbic = NaN(str2double(opt.NbClusters),length(loglike));
    
    %Le vecteur eqbic2 est similaire au vecteur eqbic mais avec un autre
    %critere.
    eqbic2 = NaN(str2double(opt.NbClusters),length(loglike));
    
    for j = 1:str2double(opt.NbClusters)
        %La regression lineaire
        alpha(j,:) = polyfit(j:ptsheurist,loglike(j:end),1);
        for i=j:length(loglike)
            %eqbic2(j,i) = 2*alpha(j,1)*(i-1+NbCartes*i+(1+NbCartes)*NbCartes/2*i)-loglike(i);
            eqbic(j,i) = 2*alpha(j,1)*i-loglike(i);
        end
    end
    %figure
    %plot(eqbic2.')
    figure
    plot(eqbic.')
    [~,I] = nanmin(eqbic,2);  %Pour chacune des courbes de l'eqbic, l'indice pour lequel le minimum est atteint est considere comme etant le nombre optimal de clusters
    figure
    plot(0:10,0:10,'r')
    hold on
    plot(I,'b')
    k = 0;
    % On vient de tracer le nombre de clusters optimal pour chaque courbe,
    % donc pour chaque coefficient directeur, donc pour chaque point i
    % debut de la regression lineaire. Le nombre de classes optimal global
    % est le point k minimum pour lequel f(k) = k, soit l'intersection de
    % la courbe tracee et de le bissectrice du plan.
    for i=1:length(I)
        if I(i) == i && k == 0
            k = i;
        end
    end
    
    if k == 0
        warndlg('Cannot find an optimal number of cluster, try again and test higher numbers of clusters','Cannot find a number of clusters');
        return
    end
    gmfit = modeles{k};
else
    gmfit = fitgmdist( Clust_Data_In, str2double(opt.NbClusters), 'Options', options, 'Regularize', 1e-5, 'Replicates',1);
    k = str2double(opt.NbClusters);    
end



ClusteredVox = cluster(gmfit, Clust_Data_In);
ind = 1;
for i=1:length(All_Data)
    Cluster = ROI{i};
    ROI_Clust = logical(ROI{i});
    Cluster(ROI_Clust) = ClusteredVox(ind:ind+size(All_Data{i},1)-1);
    ind = ind+size(All_Data{i},1);
    
    ROI_cluster_header = ROI_nifti_header{i};
    % On a fait le même traitement sur les files_out (tout début du code) que sur l'ouverture des ROI. Il y a donc tout à penser que l'ordre des fichiers correspondra.
    ROI_cluster_header.fname = files_out.In1{i}; 
    ROI_cluster_header = rmfield(ROI_cluster_header, 'pinfo');
    ROI_cluster_header = rmfield(ROI_cluster_header, 'private');

    Cluster = write_volume(Cluster,ROI_nifti_header{i}, 'axial');
    Out = spm_write_vol(ROI_cluster_header, Cluster);
end


% data_in_table.cluster(isnan(data_in_table.cluster)) = size(handles.color_RGB,1);
% 
% Couleurs = handles.color_RGB;
% Cartes = nominal(data_in_table.Properties.VarNames(8:end-1));
% 
% % A partir du classement des pixels, on calcule les statistiques du
% % clustering
% [MoyCartesTranches, ProbTranches, MoyCartesVolume, ProbVolume, Ecart_Type_Global, Sign, MoyGlobal] = AnalyseClusterGMM(data_in_table);
% 
% ROI = char(unique(data_in_table.VOI));
% 
% %On cree 2 strutures que l'on va sauvegarder avec chaque uvascroi. Ces
% %structures contiennent les informations et les statistiques du clustering.
% Informations = struct('Couleurs',Couleurs,'Cartes', Cartes , 'Modele', gmfit, 'Sign', Sign,'ROI',ROI);
% Statistiques = struct('MoyCartesTranches', MoyCartesTranches , 'ProbTranches', ProbTranches , 'MoyCartesVolume', MoyCartesVolume , 'ProbVolume', ProbVolume, 'Ecart_Type_Global', Ecart_Type_Global,'MoyGlobal', MoyGlobal);
% % IA_patient_list = {handles.MIA_data.database.name};
% NomDossier = [];
% for i = 1:length(Informations.Cartes)
%     NomDossier = [NomDossier '_' char(Informations.Cartes(i))];
% end
% NomDossier2 = [num2str(length(Informations.Cartes)) 'Cartes' filesep NomDossier];
% logbook = {};
% answer = inputdlg('Comment voulez vous nommer ce clustering ?', 'Choix du nom du clustering', 1,{strcat(num2str(k),'C_',NomDossier)});
% if ~exist(strcat(handles.MIA_data.database(1).path,NomDossier2), 'dir')
%     mkdir(strcat(handles.MIA_data.database(1).path,NomDossier2));
% end
% save([strcat( handles.MIA_data.database(1).path,NomDossier2), filesep,answer{1} '-clusterGMM.mat'],'Informations', 'Statistiques');





