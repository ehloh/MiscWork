% Parse data from txt sheet (all subjects, dumped from server) to Matlab files 
clear all, close all hidden, clc

% Request 
req.dump_file= 'CIS (5).csv'; % All files dumped from SQL together (export as CSV) 
req.taskversion='v3_2'; 

for o=1:1 % Settings for this session batch 
    
    % Requested order of columns for overall (within-session) data matrix 
    req.sessions={'Learn', 'Choose', 'Rate'}; 
    req.d{1} = {'source'; 'outcome'; 'srcacc'; 'srcagree';  'truth'; 'info'; 'stim1'; 'choice';'rt'; 'trialnum'};
    req.d{2} = {'src1'; 'src2'; 'info'; 'choice1';'choice2';'rt1';'rt2'; 'chosrc'; 'chosrcRT'; 'stim1'; 'randx'}; 
    req.ratemat_prefix.ds={'q','src','rating','rt'};   % Data matrices + column specs for rating session 
    req.ratemat_prefix.dp={'q','rating','rt'};   
end 
for o=1:1 % Setup 
    
    % Where     
    w=pwd;   if strcmp(w(1), '/')==0;  where.where ='C:\Users\e.loh\Dropbox\SCRIPPS\3_ConfirmInfo\'; else where.where ='/Users/EleanorL/Dropbox/SCRIPPS/3_ConfirmInfo/'; end
    where.data=[where.where fs '3 Data' fs req.taskversion fs ];  cd(where.data)
    
    % Naming spex 
    for i=1:length(req.d); for ii=1:length(req.d{i}); eval(['req.col' num2str(i) '.' req.d{i}{ii} ' =ii;']); end; end  % Load requested columns 
    req.prefix_singlevar='log.'; 
    req.name='@@nm';   
    req.eq='@@='; 
    req.next='@#@';
    req.endall='@##@'; 
    req.obeq='\":';
    req.obnext=',\"';

    % Useful functions 
    fmat= @(mat, index)mat(index);  fstruc = @(struc, x)eval(['struc.' x]); 
    f_strfind1indx =  @(str, pat)strfind(str, pat):strfind(str, pat)+length(pat)-1 ;  % Assuming only 1 match 
    f_strfind1edge=  @(str, pat)[strfind(str, pat)-1 (strfind(str, pat)+length(pat))] ;  % Assuming only 1 match 

    % Files 
    r_all = importdata([where.data req.dump_file]);   r_log=cell(0,4);  r_warning=cell(0,3); r_snips= cell( size(r_all,1),1); 
    disp(['Master file name:         '  req.dump_file]), disp(['Where data saved:         '  where.data]), disp(['N files to parse:         '  num2str(length(r_all ) )])
    
end 

%% Parse SQL output to matlab 

% r_snips: (1) Raw code (2) Subject name (3) Session
for fn=1: size(r_all ,1)
    disp(['File #' num2str(fn) ' --------------'])
    wd.d=r_all{fn};
    
    % Cut into snips [wd.snips: string, code to execute, (header) variable name]
    wd.alldataposted = 1-isempty(strfind(wd.d, req.endall));
    if ~wd.alldataposted, 
        warning(['File #' num2str(fn) ' not entirely posted to sever!']),
        break
    else % Only parse if eveyrthing was posted ok.
        wd.d((strfind(wd.d, req.endall)-length(req.next)):end)=[];
        wd.sectstart= strfind(wd.d, req.name);
        wd.snips= cell(length(wd.sectstart),3) ; openvar wd.snips         
        for i=1:length(wd.sectstart)  % Splice string into segments 
            if i==length(wd.sectstart)
                wd.snips{i} = wd.d(wd.sectstart(i):end);
            else  wd.snips{i} = wd.d(wd.sectstart(i):wd.sectstart(i+1)-1);
            end
        end
          
        % Flag subject + session (assume in first few terms)
        r_snips{fn, 2}  =  fmat(strrep(wd.snips{cell2mat(cellfun(@(x)~isempty(strfind(x, 'subject')), wd.snips(1:5,1),'uniformoutput',0)),1}, req.name, ''),  length(req.eq)+strfind(strrep(wd.snips{cell2mat(cellfun(@(x)~isempty(strfind(x, 'subject')), wd.snips(1:5,1),'uniformoutput',0)),1}, req.name, ''), req.eq): length(strrep(wd.snips{cell2mat(cellfun(@(x)~isempty(strfind(x, 'subject')), wd.snips(1:5,1),'uniformoutput',0)),1}, req.name, '')) - length(req.next)); 
        r_snips{fn, 3}  =  fmat(strrep(wd.snips{cell2mat(cellfun(@(x)~isempty(strfind(x, 'session')), wd.snips(1:5,1),'uniformoutput',0)),1}, req.name, ''),  length(req.eq)+strfind(strrep(wd.snips{cell2mat(cellfun(@(x)~isempty(strfind(x, 'session')), wd.snips(1:5,1),'uniformoutput',0)),1}, req.name, ''), req.eq): length(strrep(wd.snips{cell2mat(cellfun(@(x)~isempty(strfind(x, 'session')), wd.snips(1:5,1),'uniformoutput',0)),1}, req.name, '')) - length(req.next)); 
        disp([r_snips{fn, 2} '  ' r_snips{fn, 3}])
        
        % Parse snips into generative code
        for sn=1:size(wd.snips,1) 
            wn.str=wd.snips{sn,1};
            wn.str(f_strfind1indx(wn.str, req.name))=[];  % Parse (remove indicator characters)
            wn.str(f_strfind1indx(wn.str, req.next))=[]; wn.str=[wn.str ';'];
            wn.str= [wn.str(1:fmat( f_strfind1edge(wn.str, req.eq),1)) '='  wn.str(fmat( f_strfind1edge(wn.str, req.eq),2):end)]; 
            
            if strcmp(wn.str(fmat(strfind(wn.str, '='),1)+1), '{')  % If Object, store in structure 
                wn.os = wn.str( strfind(wn.str, '=')+1:end);
                wn.os(strfind(wn.os, '\'))=[] ;  if strcmp(wn.os(end), ';')==1, wn.os(end)=[]; end 
                wn.doublecok=0;
                while wn.doublecok==0
                    wn.os= strrep( wn.os, '""', '"'); % Replace double inverted commas if necessary
                    if isempty(strfind(wn.os, '""'))==1
                        wn.doublecok=1;
                    end
                end
                %             wn.os= strrep( wn.os, '""', '"'); % Replace double inverted commas if necessary
                wn.os= strcat('''', wn.os, ''''); 
                wd.snips{sn,2}= [ req.prefix_singlevar wn.str( 1: strfind(wn.str, '=')-1) '=loadjson(' wn.os ')']; 
            else  % If not object/structure, figure out what sort of variable   
                 
                if length(strfind(wn.str, ','))<1   % Single variable  
                    if isempty( str2num(wn.str(fmat(f_strfind1edge(wn.str, '='),2):end-1))) % String
                        wd.snips{sn,2}=  strcat(req.prefix_singlevar, wn.str(1: fmat(f_strfind1edge(wn.str, '='),1)), ' ='  ,'''',  wn.str(fmat(f_strfind1edge(wn.str, '='),2):end-1), '''');
                    else  wd.snips{sn,2}= [req.prefix_singlevar wn.str];
                    end
                else % Main data matrix. Edit here if you want anything
                     % other than the standard data matrices.   
            
                    wd.snips{sn,2}  =  strcat(wn.str(1: fmat(f_strfind1edge(wn.str, '='),1)), ' ='  ,'{',  wn.str(fmat(f_strfind1edge(wn.str, '='),2):end-1), '};');
                    if strcmp(wn.str(1:2), 'd_')==0  &&  strcmp(wn.str(1:3), 'dp_')==0  && strcmp(wn.str(1:3), 'ds_')==0     % Acceptable data prefixes = don't prefix anything in the name 
                        wd.snips{sn,2}=  [req.prefix_singlevar wd.snips{sn,2}];  
                    end
                end   
            end
              
            
            
            
            wn.varname=  wd.snips{sn,2}(1:strfind(wd.snips{sn,2},'=')-1);
            if isempty(strfind( wn.varname, '.'))==0; wn.varname= wn.varname(1:strfind( wn.varname, '.')-1); end
            if sum(strcmp(wd.snips(:,3), wn.varname))==0;  wd.snips{sn,3} = strtrim(wn.varname); end
            wn=[];
        end
        
        % Execute generative code 
        for sn=1:size(wd.snips,1) 
            if isempty(wd.snips{sn,3})==0, eval(strcat(wd.snips{sn,3}, '=[];')); end  % Sub-object of log
            if isempty(strfind([wd.snips{sn,2} ';'], ',,'))==0;  % Empty values
                r_warning{size(r_warning,1)+1,1}=['Empty value: file' num2str(fn) ' line '  num2str(sn) '  ('  fmat(wd.snips{sn,2}, 1: strfind( wd.snips{sn,2}, '=')-1) ')'];
                r_warning(end,2:3) = {[wd.snips{sn,2} ';'] wd.snips}; 
                eval(strrep(strrep([wd.snips{sn,2} ';'], ',,', ', nan,'), ',,', ', nan,'))  % Nans are deleted 2x
            else    
                if ~isempty(strfind(wd.snips{sn,2}, 'loadjson'))
                    wd.snips{sn,2}  = strrep(wd.snips{sn,2},  '":","',  '":"undefined","');  % Deal with empty values    
                    
                    % Get rid of single-inverted commas (aside from start/end). They are reserved for the execution string (JSON)
                    wd.snips{sn,2}= strrep(wd.snips{sn,2}, '''', ''); 
                    wd.snips{sn,2} = [wd.snips{sn,2}(1:fmat(strfind(wd.snips{sn,2}, '('),1)) '''' wd.snips{sn,2}(fmat(strfind(wd.snips{sn,2}, '('),1)+1:end)]; 
                    wd.snips{sn,2} = [wd.snips{sn,2}(1:fmat(strfind(wd.snips{sn,2}, ')'),length(strfind(wd.snips{sn,2}, ')')))-1) '''' wd.snips{sn,2}(fmat(strfind(wd.snips{sn,2}, ')'),length(strfind(wd.snips{sn,2}, ')'))):end)]; 
                end 
                eval([wd.snips{sn,2} ';']) 
            end
            
             
            % If this is a data vector (prefix d_), clean
            if strcmp(wd.snips{sn,2}(1:2), 'd_')==1 || strcmp(wd.snips{sn,2}([1 3]), 'd_')==1
                eval(['wn.d=' wd.snips{sn,3} '(:);'])
                if sum( cellfun(@(x)isnumeric(x), wn.d))==length(wn.d)
                    if isempty(strfind(wd.snips{sn,3}, 'rt'))==0;  wn.empty=0;  else wn.empty=999;  end  % Empties are assumed to 999, unless it is an RT variable
                    wn.d = cell2mat(wn.d );
                    wn.d( wn.d==wn.empty)=nan;
                    wd.snips{sn,4} =  length(wn.d);
                else error('Data matrix is not numeric. Not sorted yet.');
                end
                eval([wd.snips{sn,3} '=wn.d;'])
            end
            wn=[];
        end
        
        % Fetch session settings + save
        wd.varnames = wd.snips(find(cellfun(@(x)~isempty(x), wd.snips(:,3)')),3); 
        wd.subject= fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.subject'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.subject'))),1),2}, '=')+2: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.subject'))),1),2})-1);
        if strcmp(wd.subject(1), 'A')==0;  wd.subject=['A' wd.subject]; end; % Append A if not there yet
        wd.session= str2double(wd.d(fmat(strfind(wd.d, 'session'),1)+7+length(req.eq)));
%         wd.taskversion= fmat( fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, '=')+1: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2})) , strfind(fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, '=')+1: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2})), 'v'):length(fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, '=')+1: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}))));
%         wd.taskversion= fmat( fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, '=')+1: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2})) , strfind(fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, '=')+1: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2})), 'v'):length(fmat(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, strfind(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.taskversion'))),1),2}, '=')+1: length(wd.snips{fmat(find(cellfun(@(x)~isempty(x), strfind(wd.snips(:,2), 'log.TaskVersion'))),1),2}))));
         
        % Alter data?
        if wd.session==1;   % disp('WARNING: S1 - Manual add on for things to figure out next');
        elseif wd.session==2;  % disp('WARNING: S2 - Manual add on for things to figure out next');
        elseif wd.session==3; %  disp('WARNING: S3 - Manual add on for things to figure out next');
        end
         
         % Assemble overall data matrix 
        col = []; data=[]; dtables=[]; 
        if isempty(strfind(r_snips{fn,3}, 'Rate')) 
             eval(['col=req.col' num2str(wd.session) ';']);  wd.d=[]; wd.whichvarsave= ones(length(wd.varnames),1);
            for sn = 1:length(req.d{wd.session})
                eval(['wn.d= d_' req.d{wd.session}{sn} ';'])
                data=[data wn.d];  % If you're crashing here your data vectors are probably of uneq length
            end 
            
            % Saving operations 
            wd.whichvarsave(find(cellfun(@(x)isempty(x), wd.snips(:,3))))=0; 
            wd.whichvarsave(find(cellfun(@(x)~isempty(strfind(x, 'd_')), wd.snips(:,3)))) =0; 
            wd.tabnames = wd.snips(find(cellfun(@(x)~isempty(strfind(x, 'd_')), wd.snips(:,3))),3);  % Assemble raw tables for saving 
            for t=1:length(wd.tabnames)
                eval(['dtables.'  wd.tabnames{t} '=' wd.tabnames{t} ';'])
            end  
            wd.varnames_save =  {'log','data', 'col','dtables'}; % Add here if you want to save more stuff  
            
        else  % Rating session: multiple data matrices 
            wd.dvars =  fieldnames(req.ratemat_prefix); wd.whichvarsave= ones(length(wd.varnames),1);  wd.tabnames =[]; 
            for v= 1:length(wd.dvars) 
                wv.cols = fstruc(req.ratemat_prefix, wd.dvars{v});  d= [];
                for vc=1:length(wv.cols)
                    eval(['wv.d{vc}= ' wd.dvars{v} '_' wv.cols{vc} ';'])  % For debugging
                    eval(['d = [d '  wd.dvars{v} '_' wv.cols{vc} '];']) 
                    
                    % Columns 
                    eval(['col'  wd.dvars{v} '.'  wv.cols{vc} ' = ' num2str(vc) ';'])
                    
                    % Raw data tables for saving 
                    wd.tabnames = [wd.tabnames ;  {[wd.dvars{v} '_'  wv.cols{vc} ]}];  
                end 
                eval([wd.dvars{v} '_data =d;'])
               
                % Which variables to be separately saved? 
                wd.whichvarsave(find(cellfun(@(x)~isempty(strfind(x, wd.dvars{v})),wd.varnames)))=0;    
                wv=[]; 
            end 
            
            % Saving operations
            for t=1:length(wd.tabnames) % Raw data tables for saving
                eval(['dtables.'  wd.tabnames{t} '=' wd.tabnames{t} ';'])
            end
            wd.varnames_save =  [wd.varnames(find(wd.whichvarsave)); 'dtables'; cellfun(@(x)[x '_data'], wd.dvars, 'UniformOutput',0); cellfun(@(x)['col' x], wd.dvars, 'UniformOutput',0)];
        end
        
        % Details for saving
        wd.log = log; log= log.log;  for i = 1:  sum(1-strcmp(fieldnames(wd.log), 'log')); eval(['log.'  char(fmat(fmat(fieldnames(wd.log), find(1-strcmp(fieldnames(wd.log), 'log'))),i)) '=wd.log.' char(fmat(fmat(fieldnames(wd.log), find(1-strcmp(fieldnames(wd.log), 'log'))),i)) ';']); end  % format log. variable properly
        log.parsefile.datapostok = wd.alldataposted; log.parsefile.snips= wd.snips; r_snips{fn}= wd.snips;
        if isdir([where.data wd.subject])==0;  mkdir([where.data fs wd.subject]); end
        wd.filename= [where.data fs wd.subject fs wd.subject '_' num2str(wd.session) req.sessions{wd.session} '.mat'];
        
        % Variables for saving
        if strcmp(w(1), '/')==0; wd.varnames_savestring = strjoin( cellfun(@(x)strcat('''', char(x), ''','), (wd.varnames_save(:))', 'UniformOutput',0));    else wd.varnames_savestring = strjoin(char(cellfun(@(x)strcat('''', char(x), ''','), (wd.varnames_save(:))', 'UniformOutput',0)), ' ' );     end  % Convert list of variables to save into an executable string. Proper inverted commas for using eval
        wd.varnames_savestring =wd.varnames_savestring(1:fmat(strfind(wd.varnames_savestring, ','), length(strfind(wd.varnames_savestring, ',')))-1);   % Remove last comma
        eval(['save(''' wd.filename ''', ' wd.varnames_savestring   ');'])  % WHAT is saved is determined above (Rating session vs others)
        %
        disp(['    ' wd.filename(fmat(strfind(wd.filename, fs),  length(strfind(wd.filename, fs)))+1:end)])  % Flag what file is
        if sum(strcmp(r_log(:,1), wd.subject))==0; wd.subnum= size(r_log,1)+1; r_log{wd.subnum, 1} =wd.subject;  else  wd.subnum= find(strcmp(r_log(:,1), wd.subject)); end
        r_log{wd.subnum, wd.session+1} =1;
        wd=[];
    end
end
disp([{'Subject' 's1' 's2' 's3'};  r_log])
disp('Warnings (to be manually corrected - see r_warning col 3):'), disp(r_warning(:,1)); 
disp('See r_snips for details of all parsed snips'); 


