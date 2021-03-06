function wave_designmatrixplot(cons, con_names)
% plots regressors as they would show up in SPM design matrix

figure('Color', 'white');
x = linspace(0, -6*60, 360);

for i = 1:numel(con_names)
    sp = subplot(1,numel(con_names),i); hold on;
    title(con_names{i}, 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'none');
    
    plot(cons(i,:),x, 'k-')
    xlim([-2,2])
    ylim([-360,0]);
    hline([-60:-60:-300], 'r-');
    
    yticks(-330:60:-30);
    yticklabels({'Wonline', 'Monline', 'W12', 'W21', 'M12', 'M21'});
    ytickangle(270);
    sp.FontSize = 14;
    sp.FontWeight = 'bold';
end