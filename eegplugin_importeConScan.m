function ver = eegplugin_importeConScan(fig, trystrs, catchstrs)

    ver = 'eConScanimport1.0';
    if nargin < 3
        error('eegplugin_importeConScan requires 3 arguments');
    end

    % add folder to path
    % -----------------------
    if ~exist('pop_importeConScan')
        p = which('eegplugin_importeConScan');
        p = p(1:findstr(p,'eegplugin_importeConScan.m')-1);
        addpath(p);
    end

    % find import data menu
    % ---------------------
    menu = findobj(fig, 'tag', 'import data');
    
    % menu callbacks
    % --------------
    comcnt = [ trystrs.no_check 'EEG = pop_importeConScan;' catchstrs.new_and_hist ];
    
    % create menus
    % ------------
    uimenu( menu, 'label', 'From eConScan .bdf file', 'callback', comcnt, 'separator', 'on');

end

