classdef PVLabAnalyzer_v0_1_9 < handle
    % PVLabAnalyzer - First-version lab-day importer and analysis dashboard
    %
    % Launch from MATLAB with:
    %   PVLabAnalyzer_v0_1_8
    %
    % The app scans a selected folder recursively for:
    %   * PV_Lab_Master_Log*.xlsx
    %   * *_Environment.xlsx
    %   * *_DC.xlsx or *_IV_*.xlsx
    %   * *_FRA_POT_*.xlsx / *_FRA_GAL_*.xlsx
    %   * corresponding *_PARAMS.xlsx files
    %
    % It then calculates DC metrics, K-K summary statistics, fitted-circuit
    % summaries, POT/GAL pair agreement, environment summaries and plots.
    %
    % v0.1.8 provenance hardening: explicit master selection, unique exact
    % filename matching, PS5/PS50 alias recognition, explicit environment-
    % workbook linking, and uploaded-copy parameter-file matching.
    % It does NOT silently resolve 20290914 date typos or incomplete run rows.
    %
    % v0.1.8 retains the v0.1.6 Frequency Range analysis and guarded
    % master-log write-back workflow, and adds a dedicated Operating Point
    % tab for bias-selection experiments.
    %
    % Operating Point analysis:
    %   * uses the master log's nominal operating-point labels
    %   * compares target vs actual settled DC bias
    %   * maps actual FRA points onto the day's measured I-V curve
    %   * normalises voltage by a nearby measured Voc and current by Isc
    %   * compares K-K and fitted parameters against operating point
    %   * detects when a run settles closer to a DIFFERENT nominal bias
    %   * only reports POT/GAL spectral agreement when the actual bias
    %     regions are genuinely comparable
    %
    % No automatic operating-point acceptance threshold is imposed.
    % Existing nonblank master-log cells are never silently overwritten.
    %
    % Version: 0.1.9 (2026-09-17)

    properties (Access = private)
        UIFigure
        ImportButton
        ExportButton
        ResearchButton
        UpdateMasterButton
        FolderLabel
        StatusLabel
        LabDayDropDown
        TabGroup

        % Dashboard
        DashboardTab
        KPIFiles
        KPIPairs
        KPIDC
        KPIEnv
        KPIWarnings
        FilesTable
        WarningsArea

        % DC
        DCTab
        DCDropDown
        IVAxes
        PVAxes
        DCMetricsTable

        % FRA
        FRATab
        PairDropDown
        NyquistAxes
        BodeMagAxes
        BodePhaseAxes
        PairMetricsTable

        % Sweep
        SweepTab
        POTSweepAxes
        GALSweepAxes
        SweepTable

        % Frequency range
        FrequencyTab
        FrequencyModeDropDown
        FrequencyMetricDropDown
        FrequencyNyquistAxes
        FrequencyBodeAxes
        FrequencyMetricAxes
        FrequencyDecisionArea
        FrequencySummaryTable

        % Operating point
        OperatingPointTab
        OperatingPointDropDown
        OperatingMetricDropDown
        OperatingNyquistAxes
        OperatingIVAxes
        OperatingTargetAxes
        OperatingMetricAxes
        OperatingDecisionArea
        OperatingSummaryTable

        % Environment
        EnvTab
        EnvDropDown
        TempAxes
        IrrAxes
        EnvSummaryTable

        Data
        RootFolder = ""
    end

    methods
        function app = PVLabAnalyzer_v0_1_9()
            app.Data = app.emptyData();
            app.buildUI();
        end
    end

    methods (Access = private)
        function data = emptyData(app) %#ok<MANU>
            data = struct();
            data.Files = table();
            data.Master = table();
            data.MasterPath = "";
            data.DC = struct([]);
            data.FRA = struct([]);
            data.Pairs = struct([]);
            data.Environments = struct([]);
            data.Warnings = strings(0,1);
        end

        function buildUI(app)
            app.UIFigure = uifigure('Name','PV Lab Analyzer v0.1.9', ...
                'Position',[80 60 1450 880], ...
                'Color',[0.97 0.97 0.97]);

            outer = uigridlayout(app.UIFigure,[2 1]);
            outer.RowHeight = {64,'1x'};
            outer.Padding = [12 10 12 10];
            outer.RowSpacing = 8;

            header = uigridlayout(outer,[1 9]);
            header.Layout.Row = 1;
            header.ColumnWidth = {150,130,145,160,'1x',70,130,145,175};
            header.ColumnSpacing = 10;
            header.Padding = [0 0 0 0];

            app.ImportButton = uibutton(header,'push', ...
                'Text','Import Lab Folder', ...
                'FontWeight','bold', ...
                'ButtonPushedFcn',@(src,event)app.importFolder());
            app.ImportButton.Layout.Column = 1;

            app.ExportButton = uibutton(header,'push', ...
                'Text','Export Summary', ...
                'Enable','off', ...
                'ButtonPushedFcn',@(src,event)app.exportSummary());
            app.ExportButton.Layout.Column = 2;

            app.UpdateMasterButton = uibutton(header,'push', ...
                'Text','Update Master Log', ...
                'Enable','off', ...
                'FontWeight','bold', ...
                'ButtonPushedFcn',@(src,event)app.updateMasterLog());
            app.UpdateMasterButton.Layout.Column = 3;

            app.ResearchButton = uibutton(header,'push', ...
                'Text','Build Research Dataset', ...
                'FontWeight','bold', ...
                'Enable','off', ...
                'ButtonPushedFcn',@(src,event)app.buildResearchDataset());
            app.ResearchButton.Layout.Column = 4;

            app.FolderLabel = uilabel(header, ...
                'Text','Select the top-level PV Impedance Project folder.', ...
                'Interpreter','none');
            app.FolderLabel.Layout.Column = 5;

            dayLabel = uilabel(header, ...
                'Text','Lab Day:', ...
                'HorizontalAlignment','right', ...
                'FontWeight','bold');
            dayLabel.Layout.Column = 6;

            app.LabDayDropDown = uidropdown(header, ...
                'Items',{'All'}, ...
                'Value','All', ...
                'Enable','off', ...
                'ValueChangedFcn',@(src,event)app.labDayChanged());
            app.LabDayDropDown.Layout.Column = 7;

            app.StatusLabel = uilabel(header, ...
                'Text','Ready', ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold');
            app.StatusLabel.Layout.Column = 8;

            versionLabel = uilabel(header, ...
                'Text','PV impedance workflow • v0.1.9', ...
                'HorizontalAlignment','right', ...
                'FontColor',[0.35 0.35 0.35]);
            versionLabel.Layout.Column = 9;

            app.TabGroup = uitabgroup(outer);
            app.TabGroup.Layout.Row = 2;

            app.buildDashboardTab();
            app.buildDCTab();
            app.buildFRATab();
            app.buildSweepTab();
            app.buildFrequencyTab();
            app.buildOperatingPointTab();
            app.buildEnvironmentTab();
        end

        function buildDashboardTab(app)
            app.DashboardTab = uitab(app.TabGroup,'Title','Dashboard');
            g = uigridlayout(app.DashboardTab,[3 5]);
            g.RowHeight = {74,'1x',180};
            g.ColumnWidth = {'1x','1x','1x','1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            app.KPIFiles = app.makeKPI(g,1,'Files','0');
            app.KPIPairs = app.makeKPI(g,2,'Matched POT/GAL pairs','0');
            app.KPIDC = app.makeKPI(g,3,'DC curves','0');
            app.KPIEnv = app.makeKPI(g,4,'Environment snapshots','0');
            app.KPIWarnings = app.makeKPI(g,5,'Review flags','0');

            app.FilesTable = uitable(g);
            app.FilesTable.Layout.Row = 2;
            app.FilesTable.Layout.Column = [1 5];
            app.FilesTable.ColumnName = {'File','Type','Date','Mode','OP','Repeat'};
            app.FilesTable.ColumnWidth = {430,130,100,80,80,80};
            app.FilesTable.RowName = {};

            warningPanel = uipanel(g,'Title','Automatic review notes');
            warningPanel.Layout.Row = 3;
            warningPanel.Layout.Column = [1 5];
            wg = uigridlayout(warningPanel,[1 1]);
            wg.Padding = [6 6 6 6];
            app.WarningsArea = uitextarea(wg,'Editable','off');
            app.WarningsArea.Value = {'No folder imported yet.'};
        end

        function label = makeKPI(app,parent,col,titleText,valueText) %#ok<INUSL>
            p = uipanel(parent,'BorderType','line','BackgroundColor',[1 1 1]);
            p.Layout.Row = 1;
            p.Layout.Column = col;
            pg = uigridlayout(p,[2 1]);
            pg.RowHeight = {25,'1x'};
            pg.Padding = [8 5 8 5];
            uilabel(pg,'Text',titleText,'FontColor',[0.35 0.35 0.35], ...
                'HorizontalAlignment','center');
            label = uilabel(pg,'Text',valueText,'FontSize',23,'FontWeight','bold', ...
                'HorizontalAlignment','center');
        end

        function buildDCTab(app)
            app.DCTab = uitab(app.TabGroup,'Title','DC Characterisation');
            g = uigridlayout(app.DCTab,[3 2]);
            g.RowHeight = {44,'1x',150};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            controls = uigridlayout(g,[1 3]);
            controls.Layout.Row = 1;
            controls.Layout.Column = [1 2];
            controls.ColumnWidth = {110,500,'1x'};
            controls.Padding = [0 0 0 0];
            uilabel(controls,'Text','DC dataset:','FontWeight','bold');
            app.DCDropDown = uidropdown(controls,'Items',{'No DC files'}, ...
                'ValueChangedFcn',@(src,event)app.updateDCView());
            app.DCDropDown.Layout.Column = 2;

            app.IVAxes = uiaxes(g);
            app.IVAxes.Layout.Row = 2;
            app.IVAxes.Layout.Column = 1;
            title(app.IVAxes,'I-V Curve');
            xlabel(app.IVAxes,'Voltage (V)');
            ylabel(app.IVAxes,'Current (A)');
            grid(app.IVAxes,'on');

            app.PVAxes = uiaxes(g);
            app.PVAxes.Layout.Row = 2;
            app.PVAxes.Layout.Column = 2;
            title(app.PVAxes,'P-V Curve');
            xlabel(app.PVAxes,'Voltage (V)');
            ylabel(app.PVAxes,'Power (W)');
            grid(app.PVAxes,'on');

            app.DCMetricsTable = uitable(g);
            app.DCMetricsTable.Layout.Row = 3;
            app.DCMetricsTable.Layout.Column = [1 2];
            app.DCMetricsTable.ColumnName = {'Metric','Value','Note'};
            app.DCMetricsTable.ColumnWidth = {180,160,'1x'};
            app.DCMetricsTable.RowName = {};
        end

        function buildFRATab(app)
            app.FRATab = uitab(app.TabGroup,'Title','FRA Pair Analysis');
            g = uigridlayout(app.FRATab,[3 2]);
            g.RowHeight = {44,'1x','1x'};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            controls = uigridlayout(g,[1 3]);
            controls.Layout.Row = 1;
            controls.Layout.Column = [1 2];
            controls.ColumnWidth = {110,650,'1x'};
            controls.Padding = [0 0 0 0];
            uilabel(controls,'Text','Matched pair:','FontWeight','bold');
            app.PairDropDown = uidropdown(controls,'Items',{'No matched pairs'}, ...
                'ValueChangedFcn',@(src,event)app.updateFRAView());
            app.PairDropDown.Layout.Column = 2;

            app.NyquistAxes = uiaxes(g);
            app.NyquistAxes.Layout.Row = 2;
            app.NyquistAxes.Layout.Column = 1;
            title(app.NyquistAxes,'Nyquist');
            xlabel(app.NyquistAxes,"Z' (Ω)");
            ylabel(app.NyquistAxes,"-Z'' (Ω)");
            grid(app.NyquistAxes,'on');

            app.BodeMagAxes = uiaxes(g);
            app.BodeMagAxes.Layout.Row = 2;
            app.BodeMagAxes.Layout.Column = 2;
            title(app.BodeMagAxes,'Bode Magnitude');
            xlabel(app.BodeMagAxes,'Frequency (Hz)');
            ylabel(app.BodeMagAxes,'|Z| (Ω)');
            set(app.BodeMagAxes,'XScale','log');
            grid(app.BodeMagAxes,'on');

            app.BodePhaseAxes = uiaxes(g);
            app.BodePhaseAxes.Layout.Row = 3;
            app.BodePhaseAxes.Layout.Column = 1;
            title(app.BodePhaseAxes,'Bode Phase');
            xlabel(app.BodePhaseAxes,'Frequency (Hz)');
            ylabel(app.BodePhaseAxes,'Phase (°)');
            set(app.BodePhaseAxes,'XScale','log');
            grid(app.BodePhaseAxes,'on');

            app.PairMetricsTable = uitable(g);
            app.PairMetricsTable.Layout.Row = 3;
            app.PairMetricsTable.Layout.Column = 2;
            app.PairMetricsTable.ColumnName = {'Metric','POT','GAL','Comparison'};
            app.PairMetricsTable.ColumnWidth = {180,130,130,'1x'};
            app.PairMetricsTable.RowName = {};
        end

        function buildSweepTab(app)
            app.SweepTab = uitab(app.TabGroup,'Title','Amplitude Sweep');
            g = uigridlayout(app.SweepTab,[2 2]);
            g.RowHeight = {'1x',250};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            app.POTSweepAxes = uiaxes(g);
            app.POTSweepAxes.Layout.Row = 1;
            app.POTSweepAxes.Layout.Column = 1;
            title(app.POTSweepAxes,'POT: K-K Error vs AC Amplitude');
            xlabel(app.POTSweepAxes,'AC amplitude (mV RMS)');
            ylabel(app.POTSweepAxes,"Mean |Error Z'| (%)");
            grid(app.POTSweepAxes,'on');

            app.GALSweepAxes = uiaxes(g);
            app.GALSweepAxes.Layout.Row = 1;
            app.GALSweepAxes.Layout.Column = 2;
            title(app.GALSweepAxes,'GAL: K-K Error vs AC Amplitude');
            xlabel(app.GALSweepAxes,'AC amplitude (mA RMS)');
            ylabel(app.GALSweepAxes,"Mean |Error Z'| (%)");
            grid(app.GALSweepAxes,'on');

            app.SweepTable = uitable(g);
            app.SweepTable.Layout.Row = 2;
            app.SweepTable.Layout.Column = [1 2];
            app.SweepTable.ColumnName = {'Date','Run ID','Mode','Repeat','Amplitude','Unit','K-K mean (%)', ...
                'Rs (Ω)','Rp/Rct (Ω)','CPE Y0','CPE n','Actual V (V)','Actual I (A)','ΔT (°C)'};
            app.SweepTable.ColumnWidth = {90,125,65,65,90,90,105,85,95,105,85,95,95,85};
            app.SweepTable.RowName = {};
        end


        function buildFrequencyTab(app)
            app.FrequencyTab = uitab(app.TabGroup,'Title','Frequency Range');
            g = uigridlayout(app.FrequencyTab,[4 2]);
            g.RowHeight = {48,'1x','1x',225};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            controls = uigridlayout(g,[1 6]);
            controls.Layout.Row = 1;
            controls.Layout.Column = [1 2];
            controls.ColumnWidth = {65,120,70,280,'1x',320};
            controls.Padding = [0 0 0 0];

            uilabel(controls,'Text','Mode:','FontWeight','bold');
            app.FrequencyModeDropDown = uidropdown(controls, ...
                'Items',{'POT'},'Value','POT', ...
                'ValueChangedFcn',@(src,event)app.updateFrequencyView());
            app.FrequencyModeDropDown.Layout.Column = 2;

            metricLabel = uilabel(controls,'Text','Metric:','FontWeight','bold');
            metricLabel.Layout.Column = 3;
            app.FrequencyMetricDropDown = uidropdown(controls, ...
                'Items',{'Mean |K-K Error Z''| (%)', ...
                         'Repeatability – mean complex Z diff (%)', ...
                         'Spectrum deviation from reference (%)', ...
                         'Mean parameter deviation from reference (%)', ...
                         'Rs (Ω)','Rp/Rct (Ω)','CPE Y0','CPE n'}, ...
                'Value','Mean |K-K Error Z''| (%)', ...
                'ValueChangedFcn',@(src,event)app.updateFrequencyMetricPlot());
            app.FrequencyMetricDropDown.Layout.Column = 4;

            hint = uilabel(controls, ...
                'Text','Reference = widest measured frequency span. No acceptance threshold is imposed.', ...
                'HorizontalAlignment','right', ...
                'FontColor',[0.35 0.35 0.35], ...
                'WordWrap','on');
            hint.Layout.Column = 6;

            app.FrequencyNyquistAxes = uiaxes(g);
            app.FrequencyNyquistAxes.Layout.Row = 2;
            app.FrequencyNyquistAxes.Layout.Column = 1;
            title(app.FrequencyNyquistAxes,'Frequency-range Nyquist Overlay');
            xlabel(app.FrequencyNyquistAxes,"Z' (Ω)");
            ylabel(app.FrequencyNyquistAxes,"-Z'' (Ω)");
            grid(app.FrequencyNyquistAxes,'on');

            app.FrequencyBodeAxes = uiaxes(g);
            app.FrequencyBodeAxes.Layout.Row = 2;
            app.FrequencyBodeAxes.Layout.Column = 2;
            title(app.FrequencyBodeAxes,'Frequency-range Bode Magnitude');
            xlabel(app.FrequencyBodeAxes,'Frequency (Hz)');
            ylabel(app.FrequencyBodeAxes,'|Z| (Ω)');
            set(app.FrequencyBodeAxes,'XScale','log');
            grid(app.FrequencyBodeAxes,'on');

            app.FrequencyMetricAxes = uiaxes(g);
            app.FrequencyMetricAxes.Layout.Row = 3;
            app.FrequencyMetricAxes.Layout.Column = 1;
            title(app.FrequencyMetricAxes,'Frequency-range metric');
            xlabel(app.FrequencyMetricAxes,'Lower frequency limit (Hz)');
            grid(app.FrequencyMetricAxes,'on');

            decisionPanel = uipanel(g,'Title','Decision support');
            decisionPanel.Layout.Row = 3;
            decisionPanel.Layout.Column = 2;
            dg = uigridlayout(decisionPanel,[1 1]);
            dg.Padding = [6 6 6 6];
            app.FrequencyDecisionArea = uitextarea(dg,'Editable','off');
            app.FrequencyDecisionArea.Value = {'Import a frequency-range experiment to compare candidates.'};

            app.FrequencySummaryTable = uitable(g);
            app.FrequencySummaryTable.Layout.Row = 4;
            app.FrequencySummaryTable.Layout.Column = [1 2];
            app.FrequencySummaryTable.ColumnName = { ...
                'Range','Repeats','Amplitude','Pts/dec','Mean points', ...
                'K-K mean (%)','K-K SD','Repeat Z diff (%)', ...
                'Rs mean','Rs CV (%)','Rp mean','Rp CV (%)', ...
                'Y0 mean','Y0 CV (%)','n mean','n SD', ...
                'Spectrum Δ ref (%)','Param Δ ref (%)','Reference'};
            app.FrequencySummaryTable.ColumnWidth = {180,65,100,70,80,90,75,105, ...
                85,85,85,85,95,85,80,75,105,100,75};
            app.FrequencySummaryTable.RowName = {};
        end


        function buildOperatingPointTab(app)
            app.OperatingPointTab = uitab(app.TabGroup,'Title','Operating Point');
            g = uigridlayout(app.OperatingPointTab,[5 2]);
            g.RowHeight = {48,'1x','1x',125,230};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            controls = uigridlayout(g,[1 6]);
            controls.Layout.Row = 1;
            controls.Layout.Column = [1 2];
            controls.ColumnWidth = {115,250,65,280,'1x',330};
            controls.Padding = [0 0 0 0];

            uilabel(controls,'Text','Operating point:','FontWeight','bold');
            app.OperatingPointDropDown = uidropdown(controls, ...
                'Items',{'All'},'Value','All', ...
                'ValueChangedFcn',@(src,event)app.updateOperatingPointView());
            app.OperatingPointDropDown.Layout.Column = 2;

            metricLabel = uilabel(controls,'Text','Metric:','FontWeight','bold');
            metricLabel.Layout.Column = 3;
            app.OperatingMetricDropDown = uidropdown(controls, ...
                'Items',{'Mean |K-K Error Z''| (%)', ...
                         'Rs (Ω)','Rp/Rct (Ω)','CPE Y0','CPE n', ...
                         'Target voltage error (% Voc)', ...
                         '|Actual current| / Isc (%)'}, ...
                'Value','Mean |K-K Error Z''| (%)', ...
                'ValueChangedFcn',@(src,event)app.updateOperatingMetricPlot());
            app.OperatingMetricDropDown.Layout.Column = 4;

            hint = uilabel(controls, ...
                'Text','Bias-region checks use actual settled V: which nominal target did the run really land closest to?', ...
                'HorizontalAlignment','right', ...
                'FontColor',[0.35 0.35 0.35], ...
                'WordWrap','on');
            hint.Layout.Column = 6;

            app.OperatingNyquistAxes = uiaxes(g);
            app.OperatingNyquistAxes.Layout.Row = 2;
            app.OperatingNyquistAxes.Layout.Column = 1;
            title(app.OperatingNyquistAxes,'Selected operating point: Nyquist');
            xlabel(app.OperatingNyquistAxes,"Z' (Ω)");
            ylabel(app.OperatingNyquistAxes,"-Z'' (Ω)");
            grid(app.OperatingNyquistAxes,'on');

            app.OperatingIVAxes = uiaxes(g);
            app.OperatingIVAxes.Layout.Row = 2;
            app.OperatingIVAxes.Layout.Column = 2;
            title(app.OperatingIVAxes,'Actual FRA bias points on measured I-V curve');
            xlabel(app.OperatingIVAxes,'Voltage (V)');
            ylabel(app.OperatingIVAxes,'|Current| (A)');
            grid(app.OperatingIVAxes,'on');

            app.OperatingTargetAxes = uiaxes(g);
            app.OperatingTargetAxes.Layout.Row = 3;
            app.OperatingTargetAxes.Layout.Column = 1;
            title(app.OperatingTargetAxes,'Target vs actual settled voltage');
            xlabel(app.OperatingTargetAxes,'Target panel voltage (V)');
            ylabel(app.OperatingTargetAxes,'Actual settled voltage (V)');
            grid(app.OperatingTargetAxes,'on');

            app.OperatingMetricAxes = uiaxes(g);
            app.OperatingMetricAxes.Layout.Row = 3;
            app.OperatingMetricAxes.Layout.Column = 2;
            title(app.OperatingMetricAxes,'Operating-point metric');
            xlabel(app.OperatingMetricAxes,'Actual V / measured Voc');
            grid(app.OperatingMetricAxes,'on');

            decisionPanel = uipanel(g,'Title','Operating-point decision support');
            decisionPanel.Layout.Row = 4;
            decisionPanel.Layout.Column = [1 2];
            dg = uigridlayout(decisionPanel,[1 1]);
            dg.Padding = [6 6 6 6];
            app.OperatingDecisionArea = uitextarea(dg,'Editable','off');
            app.OperatingDecisionArea.Value = {'Import an operating-point experiment to analyse the settled DC bias.'};

            app.OperatingSummaryTable = uitable(g);
            app.OperatingSummaryTable.Layout.Row = 5;
            app.OperatingSummaryTable.Layout.Column = [1 2];
            app.OperatingSummaryTable.ColumnName = { ...
                'Run ID','Nominal OP','Mode','Target V','Actual V','ΔV','V/Voc', ...
                'Target I','Actual I','|I|/Isc (%)','Closest target region', ...
                'K-K mean (%)','Rs','Rp/Rct','CPE Y0','CPE n','POT/GAL comparison'};
            app.OperatingSummaryTable.ColumnWidth = {120,160,60,80,80,75,75, ...
                80,80,95,170,90,80,85,95,75,230};
            app.OperatingSummaryTable.RowName = {};
        end

        function buildEnvironmentTab(app)
            app.EnvTab = uitab(app.TabGroup,'Title','Environment');
            g = uigridlayout(app.EnvTab,[3 2]);
            g.RowHeight = {44,'1x',180};
            g.ColumnWidth = {'1x','1x'};
            g.Padding = [12 12 12 12];
            g.RowSpacing = 10;
            g.ColumnSpacing = 10;

            controls = uigridlayout(g,[1 3]);
            controls.Layout.Row = 1;
            controls.Layout.Column = [1 2];
            controls.ColumnWidth = {140,500,'1x'};
            controls.Padding = [0 0 0 0];
            uilabel(controls,'Text','Environment ID:','FontWeight','bold');
            app.EnvDropDown = uidropdown(controls,'Items',{'No environment data'}, ...
                'ValueChangedFcn',@(src,event)app.updateEnvironmentView());
            app.EnvDropDown.Layout.Column = 2;

            app.TempAxes = uiaxes(g);
            app.TempAxes.Layout.Row = 2;
            app.TempAxes.Layout.Column = 1;
            title(app.TempAxes,'Panel Temperature Grid');

            app.IrrAxes = uiaxes(g);
            app.IrrAxes.Layout.Row = 2;
            app.IrrAxes.Layout.Column = 2;
            title(app.IrrAxes,'Panel Irradiance Grid');

            app.EnvSummaryTable = uitable(g);
            app.EnvSummaryTable.Layout.Row = 3;
            app.EnvSummaryTable.Layout.Column = [1 2];
            app.EnvSummaryTable.ColumnName = {'Metric','Value'};
            app.EnvSummaryTable.ColumnWidth = {260,'1x'};
            app.EnvSummaryTable.RowName = {};
        end

        function importFolder(app)
            folder = uigetdir(pwd,'Select the top-level PV Impedance Project folder');
            if isequal(folder,0)
                return;
            end

            app.RootFolder = string(folder);
            app.FolderLabel.Text = char(app.RootFolder);
            app.StatusLabel.Text = 'Importing...';
            app.ImportButton.Enable = 'off';
            drawnow;

            try
                app.Data = app.scanAndAnalyze(app.RootFolder);
                app.populateLabDayFilter();
                app.updateAllViews();
                app.ExportButton.Enable = 'on';
                app.ResearchButton.Enable = 'on';
                if strlength(app.Data.MasterPath) > 0
                    app.UpdateMasterButton.Enable = 'on';
                else
                    app.UpdateMasterButton.Enable = 'off';
                end
                day = app.selectedLabDay();
                if strcmpi(day,"All")
                    app.StatusLabel.Text = 'Imported • All days • v0.1.9';
                else
                    app.StatusLabel.Text = char("Imported • " + day + " • v0.1.9");
                end
            catch ME
                app.StatusLabel.Text = 'Import failed';
                app.ExportButton.Enable = 'off';
                app.ResearchButton.Enable = 'off';
                app.UpdateMasterButton.Enable = 'off';
                detail = ME.message;
                if ~isempty(ME.stack)
                    detail = sprintf('%s\n\nLocation: %s (line %d)', ...
                        ME.message, ME.stack(1).name, ME.stack(1).line);
                end
                uialert(app.UIFigure,detail,'Import error','Icon','error');
            end
            app.ImportButton.Enable = 'on';
        end

        function buildResearchDataset(app)
            % Explicit crosswalk-driven extraction; never updates master log.
            helper = 'PV_Research_Feature_Extractor_v0_1';
            if exist(helper,'file') ~= 2
                uialert(app.UIFigure, ...
                    ['Place PV_Research_Feature_Extractor_v0_1.m in the same ' ...
                     'MATLAB folder as this application.'], ...
                    'Missing research extractor','Icon','warning');
                return;
            end
            app.ResearchButton.Enable = 'off';
            app.StatusLabel.Text = 'Extracting research features...';
            drawnow;
            try
                result = PV_Research_Feature_Extractor_v0_1(char(app.RootFolder));
                if isfield(result,'Features')
                    app.StatusLabel.Text = sprintf('Research dataset: %d FRA runs', ...
                        height(result.Features));
                    uialert(app.UIFigure, ...
                        sprintf(['Feature extraction complete. %d runs; %d review items.\n' ...
                        'Output: %s'],height(result.Features),height(result.Audit), ...
                        char(result.OutputFolder)), ...
                        'Research dataset exported','Icon','info');
                else
                    app.StatusLabel.Text = 'Research extraction cancelled';
                end
            catch ME
                app.StatusLabel.Text = 'Research extraction failed';
                detail = ME.message;
                if ~isempty(ME.stack)
                    detail = sprintf('%s\nAt %s, line %d',ME.message, ...
                        ME.stack(1).name,ME.stack(1).line);
                end
                uialert(app.UIFigure,detail,'Research extraction error','Icon','error');
            end
            app.ResearchButton.Enable = 'on';
        end

        function populateLabDayFilter(app)
            dates = strings(0,1);
            if ~isempty(app.Data.Files) && any(strcmp(app.Data.Files.Properties.VariableNames,'Date'))
                d = string(app.Data.Files.Date);
                d(ismissing(d)) = "";
                dates = [dates; d(strlength(d)>0)]; %#ok<AGROW>
            end
            for k = 1:numel(app.Data.DC)
                if strlength(app.Data.DC(k).FileInfo.Date)>0
                    dates(end+1,1) = app.Data.DC(k).FileInfo.Date; %#ok<AGROW>
                end
            end
            for k = 1:numel(app.Data.FRA)
                if strlength(app.Data.FRA(k).FileInfo.Date)>0
                    dates(end+1,1) = app.Data.FRA(k).FileInfo.Date; %#ok<AGROW>
                end
            end
            for k = 1:numel(app.Data.Environments)
                tok = regexp(char(app.Data.Environments(k).ID),'^\d{8}','match','once');
                if ~isempty(tok), dates(end+1,1) = string(tok); end %#ok<AGROW>
            end
            dates = unique(dates(strlength(dates)>0));
            dates = sort(dates);
            items = [{'All'}, cellstr(dates(:).')];
            app.LabDayDropDown.Items = items;
            if ~isempty(dates)
                % Default to the newest lab day because that is normally the
                % dataset being reviewed immediately after a lab session.
                app.LabDayDropDown.Value = char(dates(end));
            else
                app.LabDayDropDown.Value = 'All';
            end
            app.LabDayDropDown.Enable = 'on';
        end

        function labDayChanged(app)
            if isempty(app.Data.Files), return; end
            app.updateAllViews();
            day = app.selectedLabDay();
            if strcmpi(day,"All")
                app.StatusLabel.Text = 'Imported • All days • v0.1.9';
            else
                app.StatusLabel.Text = char("Imported • " + day + " • v0.1.9");
            end
        end

        function day = selectedLabDay(app)
            day = "All";
            try
                day = string(app.LabDayDropDown.Value);
                if strlength(day)==0, day="All"; end
            catch
            end
        end

        function tf = datePassesFilter(app,dateValue)
            day = app.selectedLabDay();
            if strcmpi(day,"All")
                tf = true;
            else
                tf = strcmpi(string(dateValue),day);
            end
        end

        function idx = filteredDCIndices(app)
            idx = [];
            for k = 1:numel(app.Data.DC)
                if app.datePassesFilter(app.Data.DC(k).FileInfo.Date)
                    idx(end+1) = k; %#ok<AGROW>
                end
            end
        end

        function idx = filteredPairIndices(app)
            idx = [];
            for k = 1:numel(app.Data.Pairs)
                p = app.Data.Pairs(k);
                d = app.Data.FRA(p.PotIndex).FileInfo.Date;
                if app.datePassesFilter(d)
                    idx(end+1) = k; %#ok<AGROW>
                end
            end
        end

        function idx = filteredFRAIndices(app)
            idx = [];
            for k = 1:numel(app.Data.FRA)
                if app.datePassesFilter(app.Data.FRA(k).FileInfo.Date)
                    idx(end+1) = k; %#ok<AGROW>
                end
            end
        end

        function idx = filteredEnvironmentIndices(app)
            idx = [];
            day = app.selectedLabDay();
            for k = 1:numel(app.Data.Environments)
                id = string(app.Data.Environments(k).ID);
                if strcmpi(day,"All") || startsWith(id,day)
                    idx(end+1) = k; %#ok<AGROW>
                end
            end
        end

        function mask = filteredFileMask(app)
            if isempty(app.Data.Files)
                mask = false(0,1);
                return;
            end
            day = app.selectedLabDay();
            if strcmpi(day,"All")
                mask = true(height(app.Data.Files),1);
                return;
            end
            d = string(app.Data.Files.Date);
            d(ismissing(d)) = "";
            typ = string(app.Data.Files.Type);
            % Keep the project master log visible while showing only files
            % belonging to the selected lab day.
            mask = strcmpi(d,day) | strcmpi(typ,'Master Log');
        end

        function w = filteredWarnings(app)
            w = app.Data.Warnings;
            day = app.selectedLabDay();
            if strcmpi(day,"All") || isempty(w), return; end
            shortDay = extractAfter(day,2); % YYMMDD for old Day-1 filenames
            keep = false(size(w));
            for i = 1:numel(w)
                txt = string(w(i));
                hasAnyDate = ~isempty(regexp(char(txt),'\d{8}|\d{6}','once'));
                keep(i) = contains(txt,day) || contains(txt,shortDay) || ~hasAnyDate;
            end
            w = w(keep);
            if isempty(w), w = "No automatic review flags were generated for this lab day."; end
        end

        function data = scanAndAnalyze(app,root)
            data = app.emptyData();
            warnings = strings(0,1);

            listing = dir(fullfile(char(root),'**','*.xlsx'));
            if isempty(listing)
                error('No .xlsx files were found under the selected folder.');
            end
            listing = listing(~startsWith({listing.name},'~$'));
            backupMask = contains(upper(string({listing.name})),'_BACKUP_');
            listing = listing(~backupMask);

            n = numel(listing);
            rows = cell(n,7);
            fullPaths = strings(n,1);
            infos = repmat(app.blankFileInfo(),n,1);

            for k = 1:n
                p = string(fullfile(listing(k).folder,listing(k).name));
                fullPaths(k) = p;
                info = app.parseFilename(string(listing(k).name));
                infos(k) = info;
                rows(k,:) = {listing(k).name,info.Type,info.Date,info.Mode,info.OP,info.Repeat,p};
            end

            data.Files = cell2table(rows,'VariableNames', ...
                {'File','Type','Date','Mode','OP','Repeat','FullPath'});

            % Require explicit master selection when archived versions exist.
            % Previous revisions silently preferred PV_Lab_Master_Log.xlsx,
            % even when a newer edited workbook such as (6) was selected.
            masterMask = strcmpi(string(data.Files.Type),'Master Log');
            if any(masterMask)
                masterIdx = find(masterMask);
                masterNames = string(data.Files.File(masterIdx));
                if numel(masterIdx) > 1
                    [choice,ok] = listdlg('Name','PV master-log selection', ...
                        'PromptString','Select the AUTHORITATIVE master log:', ...
                        'ListString',cellstr(masterNames),'SelectionMode','single', ...
                        'InitialValue',numel(masterIdx),'ListSize',[520 240]);
                    if ~ok || isempty(choice)
                        error('Master log was not selected; import cancelled.');
                    end
                    chosenIdx = masterIdx(choice);
                else
                    chosenIdx = masterIdx(1);
                end
                masterFile = string(data.Files.FullPath{chosenIdx});
                data.MasterPath = masterFile;
                warnings(end+1) = "Selected master log: " + app.fileNameOnly(masterFile);
                try
                    data.Master = readtable(masterFile,'Sheet','Run Log','VariableNamingRule','preserve');
                catch
                    data.Master = readtable(masterFile,'VariableNamingRule','preserve');
                end
            else
                warnings(end+1) = "No master log found. AC amplitudes, run IDs and run-level temperatures may be unavailable.";
            end

            % Load all environment workbooks.
            envMask = strcmpi(string(data.Files.Type),'Environment');
            envFiles = string(data.Files.FullPath(envMask));
            envAll = struct([]);
            for k = 1:numel(envFiles)
                [envStruct,envWarnings] = app.loadEnvironmentWorkbook(envFiles(k));
                if ~isempty(envStruct)
                    if isempty(envAll)
                        envAll = envStruct;
                    else
                        envAll = [envAll envStruct]; %#ok<AGROW>
                    end
                end
                warnings = [warnings; envWarnings(:)]; %#ok<AGROW>
            end
            data.Environments = envAll;
            if ~isempty(envAll)
                allIDs = string({envAll.ID});
                uniqueIDs = unique(allIDs);
                for id = uniqueIDs
                    matches = find(strcmpi(allIDs,id));
                    if numel(matches) > 1
                        warnings(end+1) = "Multiple environment workbook versions contain " + ...
                            id + ". The referenced Environment File must uniquely resolve; " + ...
                            "ambiguous associations will be withheld.";
                    end
                end
            end

            % Load DC datasets.
            dcMask = strcmpi(string(data.Files.Type),'DC');
            dcFiles = string(data.Files.FullPath(dcMask));
            dcData = struct([]);
            for k = 1:numel(dcFiles)
                try
                    d = app.loadDCFile(dcFiles(k));
                    d.FileInfo = app.parseFilename(app.fileNameOnly(dcFiles(k)));
                    [d.MasterRow,d.MasterIndex] = app.matchMasterRow(data.Master,d.FileInfo,dcFiles(k));
                    d.Environment = app.environmentFromMaster(d.MasterRow,data.Environments);
                    if isempty(dcData)
                        dcData = d;
                    else
                        dcData(end+1) = d; %#ok<AGROW>
                    end
                    if ~d.HasVocCrossing
                        warnings(end+1) = "DC sweep did not cross I = 0: " + app.fileNameOnly(dcFiles(k));
                    end
                catch ME
                    warnings(end+1) = "Could not read DC file " + app.fileNameOnly(dcFiles(k)) + ": " + string(ME.message);
                end
            end
            data.DC = dcData;

            % Load FRA raw files and associated parameter exports.
            fraMask = strcmpi(string(data.Files.Type),'FRA Raw');
            fraFiles = string(data.Files.FullPath(fraMask));
            paramMask = strcmpi(string(data.Files.Type),'FRA Params');
            paramFiles = string(data.Files.FullPath(paramMask));

            fraData = struct([]);
            for k = 1:numel(fraFiles)
                try
                    f = app.loadFRAFile(fraFiles(k));
                    f.FileInfo = app.parseFilename(app.fileNameOnly(fraFiles(k)));
                    [f.MasterRow,f.MasterIndex] = app.matchMasterRow(data.Master,f.FileInfo,fraFiles(k));
                    f.Environment = app.environmentFromMaster(f.MasterRow,data.Environments);
                    f.Params = struct('Rs',NaN,'Rp',NaN,'Y0',NaN,'n',NaN,'HasData',false, ...
                        'FitZreal',[],'FitNegZimag',[]);
                    f.ParamSource = "";
                    paramPath = app.findParamFile(fraFiles(k),paramFiles);
                    if strlength(paramPath) > 0
                        f.Params = app.loadParamsFile(paramPath);
                        f.ParamFile = paramPath;
                        f.ParamSource = "PARAMS export";
                    else
                        f.ParamFile = "";
                    end

                    % Fill any missing circuit-fit values from the master log.
                    % This recovers Day-1 fits that were transcribed from Nova
                    % screenshots before separate _PARAMS exports were used.
                    masterParams = app.paramsFromMaster(f.MasterRow);
                    [f.Params,usedMaster] = app.mergeParams(f.Params,masterParams);
                    if usedMaster
                        if strlength(f.ParamSource)>0
                            f.ParamSource = f.ParamSource + " + master fallback";
                        else
                            f.ParamSource = "Master log";
                        end
                    end
                    if ~f.Params.HasData
                        warnings(end+1) = "No circuit parameters found for " + app.fileNameOnly(fraFiles(k));
                    end

                    f.Amplitude = app.masterNumeric(f.MasterRow,'AC Amplitude');
                    f.ACUnit = app.masterText(f.MasterRow,'AC Unit');
                    f.TargetV = app.masterNumeric(f.MasterRow,'Target Panel DC V (V)');
                    f.TargetI = app.masterNumeric(f.MasterRow,'Target Panel DC I (A)');
                    f.NovaApplyV = app.masterNumeric(f.MasterRow,'Nova Apply V (V)');
                    f.NovaApplyI = app.masterNumeric(f.MasterRow,'Nova Apply I (A)');
                    f.OperatingPoint = app.masterText(f.MasterRow,'Operating Point');
                    if strlength(f.OperatingPoint)==0
                        f.OperatingPoint = f.FileInfo.OP;
                    end
                    f.ActualV = app.masterNumeric(f.MasterRow,'Actual Settled DC V (V)');
                    f.ActualI = app.masterNumeric(f.MasterRow,'Actual Settled DC I (A)');
                    f.TempBefore = app.masterNumeric(f.MasterRow,'Centre Temp Before FRA (°C)');
                    f.TempAfter = app.masterNumeric(f.MasterRow,'Centre Temp After FRA (°C)');
                    f.DeltaT = app.masterNumeric(f.MasterRow,'ΔT During FRA (°C)');
                    f.RunID = app.masterText(f.MasterRow,'Run ID');
                    f.PointsPerDecade = app.masterNumeric(f.MasterRow,'Points/Decade');
                    if ~isfinite(f.PointsPerDecade)
                        f.PointsPerDecade = app.inferPointsPerDecade(f);
                    end
                    if isempty(fraData)
                        fraData = f;
                    else
                        fraData(end+1) = f; %#ok<AGROW>
                    end
                catch ME
                    warnings(end+1) = "Could not read FRA file " + app.fileNameOnly(fraFiles(k)) + ": " + string(ME.message);
                end
            end
            data.FRA = fraData;

            % Build matched POT/GAL pairs by token key.
            pairs = app.buildPairs(fraData);
            data.Pairs = pairs;
            for k = 1:numel(pairs)
                if ~pairs(k).FrequencyRangesMatch
                    warnings(end+1) = "Frequency range mismatch in " + pairs(k).Label;
                end
            end

            % Report unmatched FRA runs.
            if ~isempty(fraData)
                matched = false(1,numel(fraData));
                for k = 1:numel(pairs)
                    matched(pairs(k).PotIndex) = true;
                    matched(pairs(k).GalIndex) = true;
                end
                idx = find(~matched);
                for k = idx
                    warnings(end+1) = "Unmatched FRA run: " + app.fileNameOnly(fraData(k).Path);
                end
            end

            % Data-driven parameter anomaly check (review flag only).
            for mode = ["POT","GAL"]
                valsY = [];
                labelsY = strings(0,1);
                for k = 1:numel(fraData)
                    if strcmpi(fraData(k).FileInfo.Mode,mode) && fraData(k).Params.HasData && ...
                            isfinite(fraData(k).Params.Y0) && fraData(k).Params.Y0 > 0
                        valsY(end+1) = fraData(k).Params.Y0; %#ok<AGROW>
                        labelsY(end+1) = fraData(k).FileInfo.Repeat; %#ok<AGROW>
                    end
                end
                if numel(valsY) >= 3
                    spreadFactor = max(valsY)/min(valsY);
                    if spreadFactor > 10
                        warnings(end+1) = mode + " CPE Y0 spans " + compose('%.1fx',spreadFactor) + ...
                            " across repeats. Review fitting/export consistency.";
                    end
                end
            end

            if isempty(warnings)
                warnings = "No automatic review flags were generated.";
            end
            data.Warnings = unique(warnings,'stable');
        end

        function info = blankFileInfo(app) %#ok<MANU>
            info = struct('Type',"Other",'Date',"",'DUT',"",'State',"", ...
                'Mode',"",'OP',"",'Repeat',"",'Stem',"",'PairKey',"");
        end

        function info = parseFilename(app,fileName) %#ok<INUSL>
            info = app.blankFileInfo();
            [~,stem,~] = fileparts(char(fileName));
            s = string(stem);
            u = upper(s);
            info.Stem = s;

            % Classify the file, but do not return early: environment files
            % also carry dates that are useful for the Lab Day filter.
            if contains(u,'MASTER_LOG') && ~contains(u,'_BACKUP_') && ~contains(u,'AUDIT')
                info.Type = "Master Log";
            elseif contains(u,'ENVIRONMENT')
                info.Type = "Environment";
            elseif contains(u,'_FRA_') && endsWith(u,'_PARAMS')
                info.Type = "FRA Params";
            elseif contains(u,'_FRA_')
                info.Type = "FRA Raw";
            elseif contains(u,'_DC') || contains(u,'_IV_') || endsWith(u,'_IV')
                info.Type = "DC";
            else
                info.Type = "Other";
            end

            tok = split(u,'_');

            % Accept both the new YYYYMMDD convention and the older YYMMDD
            % Day-1 filenames. Internally everything is normalized to
            % YYYYMMDD so master-log matching and day filtering are stable.
            date8 = tok(~cellfun(@isempty,regexp(cellstr(tok),'^\d{8}$','once')));
            date6 = tok(~cellfun(@isempty,regexp(cellstr(tok),'^\d{6}$','once')));
            if ~isempty(date8)
                info.Date = date8(1);
            elseif ~isempty(date6)
                info.Date = "20" + date6(1);
            end

            if numel(tok) >= 2 && (~isempty(regexp(tok(1),'^\d{8}$','once')) || ...
                    ~isempty(regexp(tok(1),'^\d{6}$','once')))
                info.DUT = tok(2);
            end

            knownStates = ["HLT","PS","PS5","PS50","MM","SOIL","HS","REF"];
            idxState = find(ismember(tok,knownStates),1,'first');
            if ~isempty(idxState)
                info.State = tok(idxState);
                if ismember(info.State,["PS5","PS50"])
                    info.State = "PS50"; % filename aliases only; physical coverage still needs verification
                end
            end

            idxMode = find(ismember(tok,["POT","GAL"]),1,'first');
            if ~isempty(idxMode), info.Mode = tok(idxMode); end

            idxOP = find(~cellfun(@isempty,regexp(cellstr(tok),'^OP[A-Z0-9]+$','once')),1,'first');
            if ~isempty(idxOP), info.OP = tok(idxOP); end

            idxR = find(~cellfun(@isempty,regexp(cellstr(tok),'^R\d+$','once')),1,'first');
            if ~isempty(idxR), info.Repeat = tok(idxR); end

            keyParts = [info.Date info.DUT info.State info.OP info.Repeat];
            keyParts = keyParts(strlength(keyParts)>0);
            info.PairKey = strjoin(keyParts,'_');
        end

        function d = loadDCFile(app,path)
            T = readtable(path,'VariableNamingRule','preserve');
            names = string(T.Properties.VariableNames);
            vName = app.findHeader(names,["Corrected Potential (V)","Corrected Potential","Voltage (V)"]);
            iName = app.findHeader(names,["Corrected Current (A)","Corrected Current","Current (A)"]);
            pName = app.findHeader(names,["Corrected Power (W)","Corrected Power","Power (W)"]);
            if strlength(vName)==0 || strlength(iName)==0
                error('Corrected voltage/current columns were not found.');
            end
            V = app.numericColumn(T.(vName));
            I = app.numericColumn(T.(iName));
            good = isfinite(V) & isfinite(I);
            V = V(good); I = I(good);
            [V,ord] = sort(V);
            I = I(ord);
            if strlength(pName)>0
                Praw = app.numericColumn(T.(pName));
                Praw = Praw(good);
                Praw = Praw(ord);
                P = Praw;
            else
                P = V.*I;
            end

            % Isc by local linear extrapolation/interpolation near V = 0.
            nNear = min(20,numel(V));
            if nNear >= 2
                coeff = polyfit(V(1:nNear),I(1:nNear),1);
                Isc = polyval(coeff,0);
            else
                Isc = I(1);
            end

            % Voc from the first I=0 sign crossing.
            Voc = NaN; hasCross = false;
            idx = find(I(1:end-1).*I(2:end) <= 0,1,'first');
            if ~isempty(idx)
                v1 = V(idx); v2 = V(idx+1);
                i1 = I(idx); i2 = I(idx+1);
                if i2 ~= i1
                    Voc = v1 + (0-i1)*(v2-v1)/(i2-i1);
                else
                    Voc = mean([v1 v2]);
                end
                hasCross = true;
            end

            % Maximum positive generated power.
            Pcalc = V.*I;
            [Pmp,idxP] = max(Pcalc);
            Vmp = V(idxP); Imp = I(idxP);
            FF = NaN;
            if isfinite(Voc) && isfinite(Isc) && Voc ~= 0 && Isc ~= 0
                FF = Pmp/(Voc*Isc);
            end

            d = struct();
            d.Path = string(path);
            d.V = V; d.I = I; d.P = Pcalc;
            d.Voc = Voc; d.Isc = Isc; d.Vmp = Vmp; d.Imp = Imp; d.Pmp = Pmp; d.FillFactor = FF;
            d.HasVocCrossing = hasCross;
            d.Vmax = max(V); d.IatVmax = I(end);
            d.FileInfo = app.blankFileInfo();
            d.MasterRow = table();
            d.MasterIndex = NaN;
            d.Environment = struct([]);
        end

        function f = loadFRAFile(app,path)
            T = readtable(path,'VariableNamingRule','preserve');
            names = string(T.Properties.VariableNames);
            zRealName = app.findHeader(names,"Z' (Ω)");
            zImagName = app.findContainsHeader(names,"-Z''");
            magName = app.findHeader(names,"Z (Ω)");
            phaseName = app.findContainsHeader(names,"Phase");
            freqName = app.findContainsHeader(names,"Frequency");
            errName = app.findContainsHeader(names,"Error Z'");
            if strlength(zRealName)==0 || strlength(zImagName)==0 || strlength(freqName)==0
                error('Required FRA columns (Z'', -Z'''', Frequency) were not found.');
            end

            zr = app.numericColumn(T.(zRealName));
            ziNeg = app.numericColumn(T.(zImagName));
            freq = app.numericColumn(T.(freqName));
            good = isfinite(zr) & isfinite(ziNeg) & isfinite(freq) & freq>0;
            zr = zr(good); ziNeg = ziNeg(good); freq = freq(good);

            if strlength(magName)>0
                magAll = app.numericColumn(T.(magName)); mag = magAll(good);
            else
                mag = hypot(zr,ziNeg);
            end
            if strlength(phaseName)>0
                phAll = app.numericColumn(T.(phaseName)); phase = phAll(good);
            else
                phase = atan2d(-ziNeg,zr);
            end

            kk = NaN;
            if strlength(errName)>0
                erAll = app.numericColumn(T.(errName)); er = erAll(good);
                er = er(isfinite(er));
                if ~isempty(er), kk = mean(abs(er)); end
            end

            [freq,ord] = sort(freq,'descend');
            zr = zr(ord); ziNeg = ziNeg(ord); mag = mag(ord); phase = phase(ord);

            f = struct();
            f.Path = string(path);
            f.Frequency = freq;
            f.Zreal = zr;
            f.NegZimag = ziNeg;
            f.Magnitude = mag;
            f.Phase = phase;
            f.KKMeanAbs = kk;
            f.FreqStart = max(freq);
            f.FreqStop = min(freq);
            f.PointCount = numel(freq);
            f.PointsPerDecade = NaN;
            f.FileInfo = app.blankFileInfo();
            f.MasterRow = table();
            f.MasterIndex = NaN;
            f.Environment = struct([]);
            f.Params = struct();
            f.ParamFile = "";
            f.ParamSource = "";
            f.Amplitude = NaN;
            f.ACUnit = "";
            f.TargetV = NaN; f.TargetI = NaN;
            f.NovaApplyV = NaN; f.NovaApplyI = NaN;
            f.OperatingPoint = "";
            f.ActualV = NaN; f.ActualI = NaN;
            f.TempBefore = NaN; f.TempAfter = NaN; f.DeltaT = NaN;
            f.RunID = "";
        end

        function p = loadParamsFile(app,path)
            T = readtable(path,'VariableNamingRule','preserve');
            names = string(T.Properties.VariableNames);
            rsN = app.findContainsHeader(names,"Rs.R");
            rpN = app.findContainsHeader(names,"Rp.R");
            yN = app.findContainsHeader(names,"CPE.Y0");
            nN = app.findContainsHeader(names,"CPE.N");
            fitXN = app.findHeader(names,"Z' (Ω)");
            fitYN = app.findContainsHeader(names,"Fitted -Z''");

            p = struct('Rs',NaN,'Rp',NaN,'Y0',NaN,'n',NaN,'HasData',false, ...
                'FitZreal',[],'FitNegZimag',[]);
            if strlength(rsN)>0, p.Rs = app.firstFinite(T.(rsN)); end
            if strlength(rpN)>0, p.Rp = app.firstFinite(T.(rpN)); end
            if strlength(yN)>0, p.Y0 = app.firstFinite(T.(yN)); end
            if strlength(nN)>0, p.n = app.firstFinite(T.(nN)); end
            p.HasData = any(isfinite([p.Rs p.Rp p.Y0 p.n]));

            if strlength(fitXN)>0 && strlength(fitYN)>0
                x = app.numericColumn(T.(fitXN)); y = app.numericColumn(T.(fitYN));
                good = isfinite(x)&isfinite(y);
                p.FitZreal = x(good); p.FitNegZimag = y(good);
            end
        end

        function p = paramsFromMaster(app,row)
            p = struct('Rs',NaN,'Rp',NaN,'Y0',NaN,'n',NaN,'HasData',false, ...
                'FitZreal',[],'FitNegZimag',[]);
            if isempty(row), return; end
            p.Rs = app.masterNumeric(row,'Rs (Ω)');
            p.Rp = app.masterNumeric(row,'Rp / Rct (Ω)');
            p.Y0 = app.masterNumeric(row,'CPE Y0');
            if ~isfinite(p.Y0)
                p.Y0 = app.masterNumeric(row,'CPE Q / Y0');
            end
            p.n = app.masterNumeric(row,'CPE n');
            p.HasData = any(isfinite([p.Rs p.Rp p.Y0 p.n]));
        end

        function [out,usedFallback] = mergeParams(app,primary,fallback) %#ok<INUSL>
            out = primary;
            usedFallback = false;
            fields = {'Rs','Rp','Y0','n'};
            for ii = 1:numel(fields)
                nm = fields{ii};
                if (~isfield(out,nm) || ~isfinite(out.(nm))) && ...
                        isfield(fallback,nm) && isfinite(fallback.(nm))
                    out.(nm) = fallback.(nm);
                    usedFallback = true;
                end
            end
            if ~isfield(out,'FitZreal'), out.FitZreal = []; end
            if ~isfield(out,'FitNegZimag'), out.FitNegZimag = []; end
            out.HasData = any(isfinite([out.Rs out.Rp out.Y0 out.n]));
        end

        function [envs,warnings] = loadEnvironmentWorkbook(app,path)
            warnings = strings(0,1);
            envs = struct([]);
            try
                idx = readtable(path,'Sheet','Environment Index','VariableNamingRule','preserve');
            catch ME
                warnings(end+1) = "Environment workbook has no readable Environment Index: " + app.fileNameOnly(path) + " (" + string(ME.message) + ")";
                return;
            end
            if isempty(idx), return; end

            idName = app.findHeader(string(idx.Properties.VariableNames),"Environment ID");
            if strlength(idName)==0
                warnings(end+1) = "Environment Index is missing Environment ID in " + app.fileNameOnly(path);
                return;
            end

            sheets = string(sheetnames(path));
            for r = 1:height(idx)
                id = app.tableTextAt(idx,idName,r);
                if strlength(id)==0 || ismissing(id), continue; end
                % Only genuine environment IDs are data rows. This prevents
                % explanatory/note rows in the Environment Index from being
                % mistaken for an extra snapshot.
                if isempty(regexp(char(strtrim(id)),'^\d{8}-E\d{2,3}$','once'))
                    continue;
                end
                id = strtrim(id);
                e = struct();
                e.ID = id;
                e.Path = string(path);
                e.Date = app.tableTextByHeader(idx,'Date',r);
                e.Label = app.tableTextByHeader(idx,'Label',r);
                e.TempAvg = app.tableNumericByHeader(idx,'Temp Avg (°C)',r);
                e.TempMin = app.tableNumericByHeader(idx,'Temp Min (°C)',r);
                e.TempMax = app.tableNumericByHeader(idx,'Temp Max (°C)',r);
                e.TempRange = app.tableNumericByHeader(idx,'Temp Range (°C)',r);
                e.IrrAvg = app.tableNumericByHeader(idx,'Irradiance Avg (W/m²)',r);
                e.IrrMin = app.tableNumericByHeader(idx,'Irradiance Min (W/m²)',r);
                e.IrrMax = app.tableNumericByHeader(idx,'Irradiance Max (W/m²)',r);
                e.IrrRange = app.tableNumericByHeader(idx,'Irradiance Range (W/m²)',r);
                e.Variac = app.tableNumericByHeader(idx,'Variac',r);
                e.DistanceCm = app.tableNumericByHeader(idx,'Lamp–Panel Distance (cm)',r);
                if ~isfinite(e.DistanceCm)
                    e.DistanceCm = app.tableNumericByHeader(idx,'Lamp-Panel Distance (cm)',r);
                end
                if ~isfinite(e.DistanceCm)
                    e.DistanceCm = app.tableNumericByHeader(idx,'Distance (cm)',r);
                end
                e.Fan = app.tableTextByHeader(idx,'Fan',r);
                e.LinkedRunIDs = app.tableTextByHeader(idx,'Linked Run IDs',r);
                e.TempGrid = nan(3); e.IrrGrid = nan(3);

                sheetMatch = sheets(strcmpi(sheets,id));
                if isempty(sheetMatch)
                    % Fallback: search grid sheets for the ID in the session details.
                    candidates = sheets(~ismember(lower(sheets),["environment index","thermal transient"]));
                    for s = candidates'
                        try
                            block = readcell(path,'Sheet',s,'Range','A9:O11');
                            flat = string(block(:));
                            if any(strcmpi(strtrim(flat),id))
                                sheetMatch = s;
                                break;
                            end
                        catch
                        end
                    end
                end

                if ~isempty(sheetMatch)
                    try
                        e.TempGrid = readmatrix(path,'Sheet',sheetMatch(1),'Range','B4:D6');
                        e.IrrGrid = readmatrix(path,'Sheet',sheetMatch(1),'Range','J4:L6');
                    catch
                        warnings(end+1) = "Could not read 3x3 grids for " + id;
                    end
                else
                    warnings(end+1) = "No grid sheet matched Environment ID " + id;
                end

                if isempty(envs), envs = e; else, envs(end+1) = e; end %#ok<AGROW>
            end

            % Some appended September environment sheets are NOT entered in
            % the workbook's Environment Index. Read those grid sheets by
            % their exact tab names and flag the missing index provenance.
            gridTabs = sheets(~cellfun(@isempty,regexp(cellstr(sheets), ...
                '^\d{8}-E\d{2,3}$','once')));
            for tab = gridTabs'
                if ~isempty(envs) && any(arrayfun(@(x)strcmpi(x.ID,tab),envs))
                    continue;
                end
                e = struct();
                e.ID = tab;
                e.Path = string(path);
                e.Date = extractBefore(tab,9);
                e.Label = "Unindexed environment sheet";
                e.TempAvg = NaN; e.TempMin = NaN; e.TempMax = NaN; e.TempRange = NaN;
                e.IrrAvg = NaN; e.IrrMin = NaN; e.IrrMax = NaN; e.IrrRange = NaN;
                e.Variac = NaN; e.DistanceCm = NaN;
                e.Fan = ""; e.LinkedRunIDs = "";
                e.TempGrid = nan(3); e.IrrGrid = nan(3);
                try
                    e.TempGrid = readmatrix(path,'Sheet',tab,'Range','B4:D6');
                    e.IrrGrid = readmatrix(path,'Sheet',tab,'Range','J4:L6');
                    t = e.TempGrid(isfinite(e.TempGrid));
                    g = e.IrrGrid(isfinite(e.IrrGrid));
                    if ~isempty(t)
                        e.TempAvg = mean(t); e.TempMin = min(t);
                        e.TempMax = max(t); e.TempRange = max(t)-min(t);
                    end
                    if ~isempty(g)
                        e.IrrAvg = mean(g); e.IrrMin = min(g);
                        e.IrrMax = max(g); e.IrrRange = max(g)-min(g);
                    end
                    metadata = readcell(path,'Sheet',tab,'Range','A10:H13');
                    e.Variac = str2double(string(metadata{3,2}));
                    e.DistanceCm = str2double(string(metadata{4,2}));
                    e.Fan = strtrim(string(metadata{2,8}));
                    e.Label = strtrim(string(metadata{3,6}));
                    internalID = strtrim(string(metadata{2,2}));
                    if ~strcmpi(internalID,tab)
                        warnings(end+1) = "Sheet " + tab + ...
                            " has inconsistent internal Environment ID: " + internalID;
                    end
                catch ME
                    warnings(end+1) = "Unindexed environment sheet could not be fully read: " + ...
                        tab + " (" + string(ME.message) + ")";
                end
                if isempty(envs), envs = e; else, envs(end+1) = e; end %#ok<AGROW>
                warnings(end+1) = "Environment " + tab + ...
                    " is missing from the Environment Index; using sheet data provisionally.";
            end
        end

        function [row,rowIndex] = matchMasterRow(app,master,info,path)
            row = table();
            rowIndex = NaN;
            if isempty(master) || height(master)==0, return; end
            names = string(master.Properties.VariableNames);

            % First choice: exact/contains match on Data File Name.
            fileCol = app.findHeader(names,"Data File Name");
            stem = regexprep(app.fileNameOnly(path),'\.xlsx$','','ignorecase');
            if strlength(fileCol)>0
                vals = string(master.(fileCol));
                vals(ismissing(vals)) = "";
                valsStem = regexprep(vals,'\.xlsx$','', 'ignorecase');
                valsStem = regexprep(valsStem,'\(\d+\)$',''); % attachment-copy suffix
                stem = regexprep(stem,'\(\d+\)$','');
                idx = find(strcmpi(strtrim(valsStem),stem));
                if numel(idx) == 1
                    row = master(idx,:);
                    rowIndex = idx;
                    return;
                elseif numel(idx) > 1
                    % Duplicate log filenames: do NOT use an arbitrary first row.
                    return;
                end
            end

            % Fallback: filter by normalized date and measurement type/mode,
            % then use the R## token as the ordinal among same-mode runs.
            dateCol = app.findHeader(names,"Date");
            runCol = app.findHeader(names,"Run ID");
            stageCol = app.findHeader(names,"Test Stage");
            opCol = app.findHeader(names,"Operating Point");
            if strlength(stageCol)==0, return; end

            mask = true(height(master),1);
            if strlength(info.Date)>0
                md = strings(height(master),1);
                for r = 1:height(master)
                    if strlength(dateCol)>0
                        md(r) = app.masterDateString(app.tableValue(master,dateCol,r));
                    end
                    % Mixed Excel date columns can import inconsistently.
                    % Run ID is a reliable backup because it starts YYYYMMDD.
                    if strlength(md(r))==0 && strlength(runCol)>0
                        rid = app.tableTextAt(master,runCol,r);
                        tok = regexp(char(rid),'^\d{8}','match','once');
                        if ~isempty(tok), md(r) = string(tok); end
                    end
                end
                mask = mask & strcmp(md,info.Date);
            end

            stage = upper(string(master.(stageCol)));
            stage(ismissing(stage)) = "";
            if strcmpi(info.Type,'DC')
                mask = mask & (contains(stage,'DC') | contains(stage,'I-V') | contains(stage,'IV'));
            elseif strcmpi(info.Mode,'POT')
                mask = mask & contains(stage,'POT');
            elseif strcmpi(info.Mode,'GAL')
                mask = mask & contains(stage,'GAL');
            end

            if strlength(info.OP)>0 && strlength(opCol)>0 && ~strcmpi(info.Type,'DC')
                opVals = upper(string(master.(opCol)));
                opVals(ismissing(opVals)) = "";
                opMask = contains(opVals,upper(info.OP));
                % Only impose OP filtering if the master actually contains
                % usable OP labels for at least one candidate.
                if any(mask & opMask)
                    mask = mask & opMask;
                end
            end

            idx = find(mask);
            if isempty(idx), return; end

            timeCol = app.findHeader(names,"Start Time");
            if strlength(timeCol)>0 && numel(idx)>1
                try
                    t = app.sortableTimeColumn(master.(timeCol)(idx));
                    [~,o] = sort(t);
                    idx = idx(o);
                catch
                end
            end

            ordinal = 1;
            if strlength(info.Repeat)>0
                token = regexp(char(info.Repeat),'\d+','match','once');
                if ~isempty(token), ordinal = str2double(token); end
            end
            ordinal = max(1,min(ordinal,numel(idx)));
            rowIndex = idx(ordinal);
            row = master(rowIndex,:);
        end

        function env = environmentFromMaster(app,masterRow,envs)
            env = struct([]);
            if isempty(masterRow) || isempty(envs), return; end
            id = app.masterText(masterRow,'Environment ID');
            envName = app.masterText(masterRow,'Environment File');
            if strlength(id)==0, return; end
            candidates = find(arrayfun(@(e) strcmpi(e.ID,id),envs));
            if isempty(candidates), return; end
            if strlength(envName)>0
                named = candidates(arrayfun(@(k) ...
                    strcmpi(app.fileNameOnly(envs(k).Path),envName),candidates));
                if numel(named) == 1
                    env = envs(named);
                end
                % If a stated environment file is absent or ambiguous,
                % do NOT fall back to an arbitrary workbook revision.
                return;
            end
            if numel(candidates)==1
                env = envs(candidates);
            end
        end

        function paramPath = findParamFile(app,rawPath,paramFiles) %#ok<INUSL>
            paramPath = "";
            rawName = app.fileNameOnly(rawPath);
            rawStem = regexprep(rawName,'\.xlsx$','','ignorecase');
            rawStem = regexprep(rawStem,'\(\d+\)$','');
            target = rawStem + "_PARAMS";
            for p = paramFiles'
                pStem = regexprep(app.fileNameOnly(p),'\.xlsx$','','ignorecase');
                pStem = regexprep(pStem,'\(\d+\)$','');
                if strcmpi(pStem,target)
                    paramPath = p;
                    return;
                end
            end
        end

        function pairs = buildPairs(app,fra)
            pairs = struct([]);
            if isempty(fra), return; end
            keys = strings(1,numel(fra));
            for k = 1:numel(fra), keys(k) = fra(k).FileInfo.PairKey; end
            uniqueKeys = unique(keys(strlength(keys)>0),'stable');
            for key = uniqueKeys
                idx = find(strcmpi(keys,key));
                pot = idx(arrayfun(@(q)strcmpi(fra(q).FileInfo.Mode,'POT'),idx));
                gal = idx(arrayfun(@(q)strcmpi(fra(q).FileInfo.Mode,'GAL'),idx));
                if isempty(pot) || isempty(gal), continue; end
                pIdx = pot(1); gIdx = gal(1);
                p = struct();
                p.Key = key;
                p.PotIndex = pIdx;
                p.GalIndex = gIdx;
                p.Label = app.makePairLabel(fra(pIdx),fra(gIdx));
                p.FrequencyRangesMatch = abs(fra(pIdx).FreqStart-fra(gIdx).FreqStart) < 1e-9 && ...
                    abs(fra(pIdx).FreqStop-fra(gIdx).FreqStop) < 1e-9 && ...
                    fra(pIdx).PointCount == fra(gIdx).PointCount;
                [p.CommonFrequency,p.PotAligned,p.GalAligned] = app.alignPair(fra(pIdx),fra(gIdx));
                if isempty(p.CommonFrequency)
                    p.MeanRelComplexDiffPct = NaN;
                    p.RMSE = NaN;
                else
                    den = (abs(p.PotAligned)+abs(p.GalAligned))/2;
                    den(den<eps) = eps;
                    p.MeanRelComplexDiffPct = 100*mean(abs(p.PotAligned-p.GalAligned)./den);
                    p.RMSE = sqrt(mean(abs(p.PotAligned-p.GalAligned).^2));
                end
                p.RsDiffPct = app.symmetricPercentDiff(fra(pIdx).Params.Rs,fra(gIdx).Params.Rs);
                p.RpDiffPct = app.symmetricPercentDiff(fra(pIdx).Params.Rp,fra(gIdx).Params.Rp);
                p.NDiff = abs(fra(pIdx).Params.n-fra(gIdx).Params.n);
                if isfinite(fra(pIdx).Params.Y0) && isfinite(fra(gIdx).Params.Y0) && ...
                        fra(pIdx).Params.Y0>0 && fra(gIdx).Params.Y0>0
                    p.Y0Ratio = max(fra(pIdx).Params.Y0,fra(gIdx).Params.Y0) / ...
                        min(fra(pIdx).Params.Y0,fra(gIdx).Params.Y0);
                else
                    p.Y0Ratio = NaN;
                end
                if isempty(pairs), pairs = p; else, pairs(end+1)=p; end %#ok<AGROW>
            end
        end

        function label = makePairLabel(app,pot,gal) %#ok<INUSL>
            date = pot.FileInfo.Date; rep = pot.FileInfo.Repeat; op = pot.FileInfo.OP;
            aP = app.formatAmplitude(pot.Amplitude,pot.ACUnit);
            aG = app.formatAmplitude(gal.Amplitude,gal.ACUnit);
            label = strtrim(date + " " + op + " " + rep + " | POT " + aP + " | GAL " + aG);
        end

        function s = formatAmplitude(app,a,u) %#ok<INUSL>
            if ~isfinite(a)
                s = "?";
            elseif strlength(u)>0
                s = compose('%.4g',a) + " " + u;
            else
                s = compose('%.4g',a);
            end
        end

        function [fCommon,zp,zg] = alignPair(app,pot,gal) %#ok<INUSL>
            fp = pot.Frequency(:); fg = gal.Frequency(:);
            zp0 = pot.Zreal(:) - 1i*pot.NegZimag(:);
            zg0 = gal.Zreal(:) - 1i*gal.NegZimag(:);

            [common,ia,ib] = intersect(fp,fg,'stable');
            if numel(common) >= min(10,round(0.6*min(numel(fp),numel(fg))))
                fCommon = common; zp = zp0(ia); zg = zg0(ib); return;
            end

            lo = max(min(fp),min(fg));
            hi = min(max(fp),max(fg));
            if ~(hi>lo)
                fCommon=[]; zp=[]; zg=[]; return;
            end
            n = min(numel(fp),numel(fg));
            fCommon = logspace(log10(lo),log10(hi),n)';
            [fps,op] = sort(fp); zps = zp0(op);
            [fgs,og] = sort(fg); zgs = zg0(og);
            zp = interp1(log10(fps),zps,log10(fCommon),'linear');
            zg = interp1(log10(fgs),zgs,log10(fCommon),'linear');
            good = isfinite(zp)&isfinite(zg);
            fCommon=fCommon(good); zp=zp(good); zg=zg(good);
        end

        function d = symmetricPercentDiff(app,a,b) %#ok<INUSL>
            if ~isfinite(a) || ~isfinite(b)
                d = NaN; return;
            end
            den = (abs(a)+abs(b))/2;
            if den<eps, d=0; else, d=100*abs(a-b)/den; end
        end

        function updateAllViews(app)
            % Update each view independently. A display-only failure should
            % never invalidate a successful data import.
            viewWarnings = strings(0,1);

            try
                app.updateDashboard();
            catch ME
                viewWarnings(end+1,1) = "Dashboard display: " + string(ME.message); %#ok<AGROW>
            end

            try
                dcIdx = app.filteredDCIndices();
                if isempty(dcIdx)
                    app.DCDropDown.Items = {'No DC files for selected day'};
                    app.DCDropDown.Value = 'No DC files for selected day';
                    cla(app.IVAxes); cla(app.PVAxes); app.DCMetricsTable.Data = {};
                else
                    labels = arrayfun(@(ii)char(app.fileNameOnly(app.Data.DC(ii).Path)),dcIdx,'UniformOutput',false);
                    app.DCDropDown.Items = labels;
                    app.DCDropDown.Value = labels{1};
                    app.updateDCView();
                end
            catch ME
                viewWarnings(end+1,1) = "DC view: " + string(ME.message); %#ok<AGROW>
            end

            try
                pairIdx = app.filteredPairIndices();
                if isempty(pairIdx)
                    app.PairDropDown.Items = {'No matched pairs for selected day'};
                    app.PairDropDown.Value = 'No matched pairs for selected day';
                    cla(app.NyquistAxes); cla(app.BodeMagAxes); cla(app.BodePhaseAxes);
                    app.PairMetricsTable.Data = {};
                else
                    labels = arrayfun(@(ii)char(app.Data.Pairs(ii).Label),pairIdx,'UniformOutput',false);
                    app.PairDropDown.Items = labels;
                    app.PairDropDown.Value = labels{1};
                    app.updateFRAView();
                end
            catch ME
                viewWarnings(end+1,1) = "FRA pair view: " + string(ME.message); %#ok<AGROW>
            end

            try
                app.updateSweepView();
            catch ME
                viewWarnings(end+1,1) = "Amplitude sweep view: " + string(ME.message); %#ok<AGROW>
            end

            try
                app.updateFrequencyView();
            catch ME
                viewWarnings(end+1,1) = "Frequency range view: " + string(ME.message); %#ok<AGROW>
            end

            try
                app.updateOperatingPointView();
            catch ME
                viewWarnings(end+1,1) = "Operating point view: " + string(ME.message); %#ok<AGROW>
            end

            try
                envIdx = app.filteredEnvironmentIndices();
                if isempty(envIdx)
                    app.EnvDropDown.Items = {'No environment data for selected day'};
                    app.EnvDropDown.Value = 'No environment data for selected day';
                    cla(app.TempAxes); cla(app.IrrAxes); app.EnvSummaryTable.Data = {};
                else
                    ids = arrayfun(@(ii)char(app.Data.Environments(ii).ID),envIdx,'UniformOutput',false);
                    app.EnvDropDown.Items = ids;
                    app.EnvDropDown.Value = ids{1};
                    app.updateEnvironmentView();
                end
            catch ME
                viewWarnings(end+1,1) = "Environment view: " + string(ME.message); %#ok<AGROW>
            end

            if ~isempty(viewWarnings)
                app.Data.Warnings = [app.Data.Warnings; "DISPLAY COMPATIBILITY: " + viewWarnings];
                try
                    fw = app.filteredWarnings();
                    app.WarningsArea.Value = cellstr(fw);
                    app.KPIWarnings.Text = char(string(numel(fw)));
                catch
                end
                app.StatusLabel.Text = 'Imported (view warning)';
            end
        end

        function updateDashboard(app)
            fileMask = app.filteredFileMask();
            dcIdx = app.filteredDCIndices();
            pairIdx = app.filteredPairIndices();
            envIdx = app.filteredEnvironmentIndices();
            fw = app.filteredWarnings();

            app.KPIFiles.Text = char(string(sum(fileMask)));
            app.KPIPairs.Text = char(string(numel(pairIdx)));
            app.KPIDC.Text = char(string(numel(dcIdx)));
            app.KPIEnv.Text = char(string(numel(envIdx)));
            if numel(fw)==1 && contains(fw(1),"No automatic review flags")
                nWarn = 0;
            else
                nWarn = numel(fw);
            end
            app.KPIWarnings.Text = char(string(nWarn));

            if isempty(app.Data.Files) || ~any(fileMask)
                app.FilesTable.Data = {};
            else
                T = app.Data.Files(fileMask,{'File','Type','Date','Mode','OP','Repeat'});
                app.setUITableData(app.FilesTable, table2cell(T), 'Dashboard files');
            end
            app.WarningsArea.Value = cellstr(fw);
        end

        function updateDCView(app)
            if isempty(app.Data.DC), return; end
            selected = string(app.DCDropDown.Value);
            idx = [];
            for k = 1:numel(app.Data.DC)
                if strcmpi(app.fileNameOnly(app.Data.DC(k).Path),selected)
                    idx = k;
                    break;
                end
            end
            if isempty(idx), return; end
            d = app.Data.DC(idx);

            cla(app.IVAxes); hold(app.IVAxes,'on');
            plot(app.IVAxes,d.V,d.I,'LineWidth',1.5);
            yline(app.IVAxes,0,':');
            if isfinite(d.Voc), plot(app.IVAxes,d.Voc,0,'o','MarkerSize',7,'LineWidth',1.5); end
            plot(app.IVAxes,d.Vmp,d.Imp,'s','MarkerSize',7,'LineWidth',1.5);
            hold(app.IVAxes,'off'); grid(app.IVAxes,'on');
            title(app.IVAxes,"I-V: " + app.fileNameOnly(d.Path),'Interpreter','none');
            xlabel(app.IVAxes,'Voltage (V)'); ylabel(app.IVAxes,'Current (A)');

            cla(app.PVAxes); hold(app.PVAxes,'on');
            plot(app.PVAxes,d.V,d.P,'LineWidth',1.5);
            plot(app.PVAxes,d.Vmp,d.Pmp,'s','MarkerSize',7,'LineWidth',1.5);
            hold(app.PVAxes,'off'); grid(app.PVAxes,'on');
            title(app.PVAxes,'P-V'); xlabel(app.PVAxes,'Voltage (V)'); ylabel(app.PVAxes,'Power (W)');

            crossNote = "I=0 captured";
            if ~d.HasVocCrossing, crossNote = "No measured I=0 crossing"; end
            envText = app.envCompact(d.Environment);
            app.setUITableData(app.DCMetricsTable, {
                'Voc (V)', app.fmt(d.Voc,4), crossNote;
                'Isc (A)', app.fmt(d.Isc,4), 'Estimated at V = 0 from local low-voltage fit';
                'Vmp (V)', app.fmt(d.Vmp,4), 'Maximum of V×I';
                'Imp (A)', app.fmt(d.Imp,4), 'Maximum of V×I';
                'Pmp (W)', app.fmt(d.Pmp,4), 'Maximum generated power';
                'Fill factor', app.fmt(d.FillFactor,4), 'Pmp / (Voc×Isc)';
                'Environment', envText, 'Linked through master log';
                'Sweep endpoint', app.fmt(d.Vmax,4)+" V", "I = "+app.fmt(d.IatVmax,4)+" A";
                }, 'DC metrics');
        end

        function updateFRAView(app)
            if isempty(app.Data.Pairs), return; end
            selected = string(app.PairDropDown.Value);
            idx = [];
            for k = 1:numel(app.Data.Pairs)
                if strcmpi(string(app.Data.Pairs(k).Label),selected)
                    idx = k;
                    break;
                end
            end
            if isempty(idx), return; end
            pair = app.Data.Pairs(idx);
            pot = app.Data.FRA(pair.PotIndex);
            gal = app.Data.FRA(pair.GalIndex);

            cla(app.NyquistAxes); hold(app.NyquistAxes,'on');
            plot(app.NyquistAxes,pot.Zreal,pot.NegZimag,'-o','MarkerSize',3,'LineWidth',1.2,'DisplayName','POT');
            plot(app.NyquistAxes,gal.Zreal,gal.NegZimag,'-s','MarkerSize',3,'LineWidth',1.2,'DisplayName','GAL');
            if pot.Params.HasData && ~isempty(pot.Params.FitZreal)
                plot(app.NyquistAxes,pot.Params.FitZreal,pot.Params.FitNegZimag,'--','LineWidth',1,'DisplayName','POT fit');
            end
            if gal.Params.HasData && ~isempty(gal.Params.FitZreal)
                plot(app.NyquistAxes,gal.Params.FitZreal,gal.Params.FitNegZimag,'--','LineWidth',1,'DisplayName','GAL fit');
            end
            hold(app.NyquistAxes,'off'); axis(app.NyquistAxes,'tight'); grid(app.NyquistAxes,'on');
            legend(app.NyquistAxes,'Location','best');
            title(app.NyquistAxes,pair.Label,'Interpreter','none');
            xlabel(app.NyquistAxes,"Z' (Ω)"); ylabel(app.NyquistAxes,"-Z'' (Ω)");

            cla(app.BodeMagAxes); hold(app.BodeMagAxes,'on');
            semilogx(app.BodeMagAxes,pot.Frequency,pot.Magnitude,'LineWidth',1.4,'DisplayName','POT');
            semilogx(app.BodeMagAxes,gal.Frequency,gal.Magnitude,'LineWidth',1.4,'DisplayName','GAL');
            hold(app.BodeMagAxes,'off'); grid(app.BodeMagAxes,'on'); legend(app.BodeMagAxes,'Location','best');
            xlabel(app.BodeMagAxes,'Frequency (Hz)'); ylabel(app.BodeMagAxes,'|Z| (Ω)');

            cla(app.BodePhaseAxes); hold(app.BodePhaseAxes,'on');
            semilogx(app.BodePhaseAxes,pot.Frequency,pot.Phase,'LineWidth',1.4,'DisplayName','POT');
            semilogx(app.BodePhaseAxes,gal.Frequency,gal.Phase,'LineWidth',1.4,'DisplayName','GAL');
            hold(app.BodePhaseAxes,'off'); grid(app.BodePhaseAxes,'on'); legend(app.BodePhaseAxes,'Location','best');
            xlabel(app.BodePhaseAxes,'Frequency (Hz)'); ylabel(app.BodePhaseAxes,'Phase (°)');

            rangeP = app.fmt(pot.FreqStart,4)+" → "+app.fmt(pot.FreqStop,4)+" Hz";
            rangeG = app.fmt(gal.FreqStart,4)+" → "+app.fmt(gal.FreqStop,4)+" Hz";
            freqCmp = "Match"; if ~pair.FrequencyRangesMatch, freqCmp = "Mismatch"; end
            envP = app.envCompact(pot.Environment); envG = app.envCompact(gal.Environment);
            app.setUITableData(app.PairMetricsTable, {
                'AC amplitude',app.formatAmplitude(pot.Amplitude,pot.ACUnit),app.formatAmplitude(gal.Amplitude,gal.ACUnit),'';
                'Frequency range',rangeP,rangeG,freqCmp;
                "Mean |K-K Error Z'| (%)",app.fmt(pot.KKMeanAbs,4),app.fmt(gal.KKMeanAbs,4),'';
                'Rs (Ω)',app.fmt(pot.Params.Rs,6),app.fmt(gal.Params.Rs,6),app.fmt(pair.RsDiffPct,3)+" % diff";
                'Rp / Rct (Ω)',app.fmt(pot.Params.Rp,6),app.fmt(gal.Params.Rp,6),app.fmt(pair.RpDiffPct,3)+" % diff";
                'CPE Y0',app.fmtSci(pot.Params.Y0,5),app.fmtSci(gal.Params.Y0,5),"ratio "+app.fmt(pair.Y0Ratio,3)+"×";
                'CPE n',app.fmt(pot.Params.n,6),app.fmt(gal.Params.n,6),"|Δ| "+app.fmt(pair.NDiff,5);
                'Actual DC V (V)',app.fmt(pot.ActualV,4),app.fmt(gal.ActualV,4),'';
                'Actual DC I (A)',app.fmt(pot.ActualI,4),app.fmt(gal.ActualI,4),'';
                'Centre ΔT (°C)',app.fmt(pot.DeltaT,3),app.fmt(gal.DeltaT,3),'';
                'Environment',envP,envG,'';
                'Mean complex Z difference','—','—',app.fmt(pair.MeanRelComplexDiffPct,4)+" %";
                'Complex Z RMSE (Ω)','—','—',app.fmt(pair.RMSE,6);
                }, 'FRA pair metrics');
        end

        function updateSweepView(app)
            cla(app.POTSweepAxes); cla(app.GALSweepAxes);
            fraIdx = app.filteredFRAIndices();
            if isempty(fraIdx)
                app.SweepTable.Data = {};
                title(app.POTSweepAxes,'POT: no FRA data for selected day');
                title(app.GALSweepAxes,'GAL: no FRA data for selected day');
                return;
            end

            rows = cell(numel(fraIdx),14);
            pA=[]; pK=[]; pLab=strings(0,1);
            gA=[]; gK=[]; gLab=strings(0,1);
            day = app.selectedLabDay();

            for jj = 1:numel(fraIdx)
                k = fraIdx(jj);
                f = app.Data.FRA(k);
                rows(jj,:) = {f.FileInfo.Date,f.RunID,f.FileInfo.Mode,f.FileInfo.Repeat, ...
                    f.Amplitude,f.ACUnit,f.KKMeanAbs,f.Params.Rs,f.Params.Rp, ...
                    f.Params.Y0,f.Params.n,f.ActualV,f.ActualI,f.DeltaT};

                label = f.RunID;
                if strlength(label)==0
                    if strcmpi(day,"All")
                        label = f.FileInfo.Date + " " + f.FileInfo.Repeat;
                    else
                        label = f.FileInfo.Repeat;
                    end
                end

                if strcmpi(f.FileInfo.Mode,'POT') && isfinite(f.Amplitude) && isfinite(f.KKMeanAbs)
                    pA(end+1)=f.Amplitude; pK(end+1)=f.KKMeanAbs; pLab(end+1)=label; %#ok<AGROW>
                elseif strcmpi(f.FileInfo.Mode,'GAL') && isfinite(f.Amplitude) && isfinite(f.KKMeanAbs)
                    gA(end+1)=f.Amplitude; gK(end+1)=f.KKMeanAbs; gLab(end+1)=label; %#ok<AGROW>
                end
            end
            app.setUITableData(app.SweepTable, rows, 'Amplitude sweep');

            if strcmpi(day,"All")
                suffix = "All lab days";
            else
                suffix = day;
            end

            title(app.POTSweepAxes,"POT: K-K Error vs AC Amplitude — " + suffix,'Interpreter','none');
            xlabel(app.POTSweepAxes,'AC amplitude (mV RMS)');
            ylabel(app.POTSweepAxes,"Mean |Error Z'| (%)");
            grid(app.POTSweepAxes,'on');
            if ~isempty(pA)
                scatter(app.POTSweepAxes,pA,pK,55,'filled');
                for i=1:numel(pA)
                    text(app.POTSweepAxes,pA(i),pK(i),"  "+pLab(i),'VerticalAlignment','bottom','Interpreter','none');
                end
            end

            title(app.GALSweepAxes,"GAL: K-K Error vs AC Amplitude — " + suffix,'Interpreter','none');
            xlabel(app.GALSweepAxes,'AC amplitude (mA RMS)');
            ylabel(app.GALSweepAxes,"Mean |Error Z'| (%)");
            grid(app.GALSweepAxes,'on');
            if ~isempty(gA)
                scatter(app.GALSweepAxes,gA,gK,55,'filled');
                for i=1:numel(gA)
                    text(app.GALSweepAxes,gA(i),gK(i),"  "+gLab(i),'VerticalAlignment','bottom','Interpreter','none');
                end
            end
        end


        function updateFrequencyView(app)
            cla(app.FrequencyNyquistAxes);
            cla(app.FrequencyBodeAxes);
            cla(app.FrequencyMetricAxes);

            fraIdx = app.filteredFRAIndices();
            if isempty(fraIdx)
                app.FrequencySummaryTable.Data = {};
                app.FrequencyDecisionArea.Value = {'No FRA data are available for the selected lab day.'};
                title(app.FrequencyNyquistAxes,'No FRA data for selected day');
                title(app.FrequencyBodeAxes,'No FRA data for selected day');
                return;
            end

            modes = strings(0,1);
            for k = fraIdx
                m = upper(string(app.Data.FRA(k).FileInfo.Mode));
                if strlength(m)>0
                    modes(end+1,1) = m; %#ok<AGROW>
                end
            end
            modes = unique(modes,'stable');
            if isempty(modes)
                modes = "POT";
            end
            app.FrequencyModeDropDown.Items = cellstr(modes(:).');

            currentMode = upper(string(app.FrequencyModeDropDown.Value));
            if ~any(strcmpi(currentMode,modes))
                if any(strcmpi(modes,'POT'))
                    currentMode = "POT";
                else
                    currentMode = modes(1);
                end
                app.FrequencyModeDropDown.Value = char(currentMode);
            end

            modeIdx = [];
            for k = fraIdx
                if strcmpi(app.Data.FRA(k).FileInfo.Mode,currentMode)
                    modeIdx(end+1) = k; %#ok<AGROW>
                end
            end

            if isempty(modeIdx)
                app.FrequencySummaryTable.Data = {};
                app.FrequencyDecisionArea.Value = {'No FRA runs are available for the selected control mode.'};
                return;
            end

            groups = app.buildFrequencyGroups(modeIdx);
            if isempty(groups)
                app.FrequencySummaryTable.Data = {};
                app.FrequencyDecisionArea.Value = {'Could not construct frequency-range groups from the selected data.'};
                return;
            end

            % Spectral overlays: every individual repeat is shown.
            hold(app.FrequencyNyquistAxes,'on');
            hold(app.FrequencyBodeAxes,'on');
            for gi = 1:numel(groups)
                g = groups(gi);
                for jj = 1:numel(g.Indices)
                    f = app.Data.FRA(g.Indices(jj));
                    runLabel = f.RunID;
                    if strlength(runLabel)==0
                        runLabel = f.FileInfo.Repeat;
                    end
                    leg = g.ShortLabel + " | " + runLabel;
                    plot(app.FrequencyNyquistAxes,f.Zreal,f.NegZimag,'-o', ...
                        'MarkerSize',2.5,'LineWidth',1.1,'DisplayName',char(leg));
                    semilogx(app.FrequencyBodeAxes,f.Frequency,f.Magnitude,'LineWidth',1.2, ...
                        'DisplayName',char(leg));
                end
            end
            hold(app.FrequencyNyquistAxes,'off');
            hold(app.FrequencyBodeAxes,'off');
            grid(app.FrequencyNyquistAxes,'on');
            grid(app.FrequencyBodeAxes,'on');
            legend(app.FrequencyNyquistAxes,'Location','best','Interpreter','none');
            legend(app.FrequencyBodeAxes,'Location','best','Interpreter','none');
            title(app.FrequencyNyquistAxes,currentMode + " frequency-range Nyquist overlay",'Interpreter','none');
            title(app.FrequencyBodeAxes,currentMode + " frequency-range Bode magnitude",'Interpreter','none');
            xlabel(app.FrequencyNyquistAxes,"Z' (Ω)");
            ylabel(app.FrequencyNyquistAxes,"-Z'' (Ω)");
            xlabel(app.FrequencyBodeAxes,'Frequency (Hz)');
            ylabel(app.FrequencyBodeAxes,'|Z| (Ω)');
            set(app.FrequencyBodeAxes,'XScale','log');

            % Summary table.
            rows = cell(numel(groups),19);
            for gi = 1:numel(groups)
                g = groups(gi);
                refText = '';
                if g.IsReference, refText = 'YES'; end
                rows(gi,:) = {char(g.Label),g.N,char(app.formatAmplitude(g.Amplitude,g.ACUnit)), ...
                    g.PointsPerDecade,g.PointCountMean,g.KKMean,g.KKStd,g.RepeatabilityPct, ...
                    g.RsMean,g.RsCV,g.RpMean,g.RpCV,g.Y0Mean,g.Y0CV,g.NMean,g.NStd, ...
                    g.SpectrumRefDiffPct,g.ParamRefDiffPct,refText};
            end
            app.setUITableData(app.FrequencySummaryTable,rows,'Frequency range summary');

            app.updateFrequencyMetricPlot(groups);
            app.updateFrequencyDecisionSupport(groups,currentMode);
        end

        function groups = buildFrequencyGroups(app,fraIdx)
            groups = struct([]);
            if isempty(fraIdx), return; end

            keys = strings(numel(fraIdx),1);
            for ii = 1:numel(fraIdx)
                f = app.Data.FRA(fraIdx(ii));
                ppd = f.PointsPerDecade;
                if ~isfinite(ppd), ppd = app.inferPointsPerDecade(f); end
                amp = f.Amplitude;
                if ~isfinite(amp), amp = -999999; end
                keys(ii) = compose('%.12g|%.12g|%.8g|%.12g|%s', ...
                    f.FreqStart,f.FreqStop,ppd,amp,upper(string(f.ACUnit)));
            end

            u = unique(keys,'stable');
            for kk = 1:numel(u)
                local = find(strcmp(keys,u(kk)));
                idx = fraIdx(local);
                f0 = app.Data.FRA(idx(1));

                g = struct();
                g.Indices = idx;
                g.FreqStart = f0.FreqStart;
                g.FreqStop = f0.FreqStop;
                g.PointsPerDecade = f0.PointsPerDecade;
                if ~isfinite(g.PointsPerDecade)
                    g.PointsPerDecade = app.inferPointsPerDecade(f0);
                end
                g.Amplitude = f0.Amplitude;
                g.ACUnit = f0.ACUnit;
                g.N = numel(idx);
                g.ShortLabel = app.freqShortLabel(g.FreqStart,g.FreqStop);
                g.Label = g.ShortLabel + " | " + app.fmt(g.PointsPerDecade,3) + ...
                    " pt/dec | " + app.formatAmplitude(g.Amplitude,g.ACUnit);

                kkVals = arrayfun(@(i)app.Data.FRA(i).KKMeanAbs,idx);
                rsVals = arrayfun(@(i)app.Data.FRA(i).Params.Rs,idx);
                rpVals = arrayfun(@(i)app.Data.FRA(i).Params.Rp,idx);
                yVals  = arrayfun(@(i)app.Data.FRA(i).Params.Y0,idx);
                nVals  = arrayfun(@(i)app.Data.FRA(i).Params.n,idx);
                ptVals = arrayfun(@(i)app.Data.FRA(i).PointCount,idx);

                g.KKMean = app.meanFinite(kkVals);
                g.KKStd = app.stdFinite(kkVals);
                g.RsMean = app.meanFinite(rsVals);
                g.RsStd = app.stdFinite(rsVals);
                g.RsCV = app.cvFinite(rsVals);
                g.RpMean = app.meanFinite(rpVals);
                g.RpStd = app.stdFinite(rpVals);
                g.RpCV = app.cvFinite(rpVals);
                g.Y0Mean = app.meanFinite(yVals);
                g.Y0Std = app.stdFinite(yVals);
                g.Y0CV = app.cvFinite(yVals);
                g.NMean = app.meanFinite(nVals);
                g.NStd = app.stdFinite(nVals);
                g.PointCountMean = app.meanFinite(ptVals);
                g.RepeatabilityPct = app.frequencyRepeatability(idx);

                g.IsReference = false;
                g.SpectrumRefDiffPct = NaN;
                g.ParamRefDiffPct = NaN;

                if isempty(groups)
                    groups = g;
                else
                    groups(end+1) = g; %#ok<AGROW>
                end
            end

            % Reference is the widest measured span. If spans tie, prefer
            % the group with more frequency points.
            spans = arrayfun(@(g)log10(g.FreqStart/g.FreqStop),groups);
            maxSpan = max(spans);
            cand = find(abs(spans-maxSpan) < 1e-9);
            if numel(cand)>1
                [~,q] = max(arrayfun(@(j)groups(j).PointCountMean,cand));
                refIdx = cand(q);
            else
                refIdx = cand(1);
            end
            groups(refIdx).IsReference = true;

            % Compare each candidate with the full-band reference.
            ref = groups(refIdx);
            for gi = 1:numel(groups)
                if gi == refIdx
                    groups(gi).SpectrumRefDiffPct = 0;
                    groups(gi).ParamRefDiffPct = 0;
                    continue;
                end
                groups(gi).SpectrumRefDiffPct = ...
                    app.frequencyGroupSpectrumDifference(groups(gi).Indices,ref.Indices);

                diffs = [ ...
                    app.symmetricPercentDiff(groups(gi).RsMean,ref.RsMean), ...
                    app.symmetricPercentDiff(groups(gi).RpMean,ref.RpMean), ...
                    app.symmetricPercentDiff(groups(gi).Y0Mean,ref.Y0Mean), ...
                    app.symmetricPercentDiff(groups(gi).NMean,ref.NMean)];
                groups(gi).ParamRefDiffPct = app.meanFinite(diffs);
            end

            % Sort from widest to narrowest band for stable display.
            spans = arrayfun(@(g)log10(g.FreqStart/g.FreqStop),groups);
            [~,ord] = sort(spans,'descend');
            groups = groups(ord);
        end

        function updateFrequencyMetricPlot(app,groups)
            if nargin < 2 || isempty(groups)
                fraIdx = app.filteredFRAIndices();
                if isempty(fraIdx), return; end
                mode = upper(string(app.FrequencyModeDropDown.Value));
                idx = fraIdx(arrayfun(@(i)strcmpi(app.Data.FRA(i).FileInfo.Mode,mode),fraIdx));
                groups = app.buildFrequencyGroups(idx);
                if isempty(groups), return; end
            end

            metric = string(app.FrequencyMetricDropDown.Value);
            x = arrayfun(@(g)g.FreqStop,groups);
            y = nan(size(x)); e = nan(size(x));
            yLabel = metric;

            switch metric
                case "Mean |K-K Error Z'| (%)"
                    y = arrayfun(@(g)g.KKMean,groups);
                    e = arrayfun(@(g)g.KKStd,groups);
                case "Repeatability – mean complex Z diff (%)"
                    y = arrayfun(@(g)g.RepeatabilityPct,groups);
                    e(:) = NaN;
                case "Spectrum deviation from reference (%)"
                    y = arrayfun(@(g)g.SpectrumRefDiffPct,groups);
                    e(:) = NaN;
                case "Mean parameter deviation from reference (%)"
                    y = arrayfun(@(g)g.ParamRefDiffPct,groups);
                    e(:) = NaN;
                case "Rs (Ω)"
                    y = arrayfun(@(g)g.RsMean,groups);
                    e = arrayfun(@(g)g.RsStd,groups);
                case "Rp/Rct (Ω)"
                    y = arrayfun(@(g)g.RpMean,groups);
                    e = arrayfun(@(g)g.RpStd,groups);
                case "CPE Y0"
                    y = arrayfun(@(g)g.Y0Mean,groups);
                    e = arrayfun(@(g)g.Y0Std,groups);
                case "CPE n"
                    y = arrayfun(@(g)g.NMean,groups);
                    e = arrayfun(@(g)g.NStd,groups);
            end

            cla(app.FrequencyMetricAxes);
            good = isfinite(x) & isfinite(y) & x>0;
            if ~any(good)
                title(app.FrequencyMetricAxes,'Selected metric is unavailable');
                return;
            end

            xg = x(good); yg = y(good); eg = e(good);
            hold(app.FrequencyMetricAxes,'on');
            if any(isfinite(eg))
                eg(~isfinite(eg)) = 0;
                errorbar(app.FrequencyMetricAxes,xg,yg,eg,'o-','LineWidth',1.3,'MarkerSize',6);
            else
                plot(app.FrequencyMetricAxes,xg,yg,'o-','LineWidth',1.3,'MarkerSize',6);
            end
            hold(app.FrequencyMetricAxes,'off');
            set(app.FrequencyMetricAxes,'XScale','log');
            grid(app.FrequencyMetricAxes,'on');
            xlabel(app.FrequencyMetricAxes,'Lower frequency limit (Hz)');
            ylabel(app.FrequencyMetricAxes,char(yLabel),'Interpreter','none');
            title(app.FrequencyMetricAxes,char(metric + " vs lower frequency limit"),'Interpreter','none');

            gg = groups(good);
            for ii = 1:numel(xg)
                text(app.FrequencyMetricAxes,xg(ii),yg(ii),"  "+gg(ii).ShortLabel, ...
                    'VerticalAlignment','bottom','Interpreter','none');
            end
        end

        function updateFrequencyDecisionSupport(app,groups,mode)
            notes = strings(0,1);
            refIdx = find([groups.IsReference],1,'first');
            if isempty(refIdx)
                refIdx = 1;
            end
            ref = groups(refIdx);
            notes(end+1) = "Reference (widest measured span): " + ref.Label;

            amps = arrayfun(@(g)g.Amplitude,groups);
            finiteAmp = amps(isfinite(amps));
            if numel(unique(round(finiteAmp,9))) > 1
                notes(end+1) = "CAUTION: AC amplitude changes between frequency-range groups. Frequency is not the only changing variable.";
            end

            ppd = arrayfun(@(g)g.PointsPerDecade,groups);
            finitePPD = ppd(isfinite(ppd));
            if numel(unique(round(finitePPD,9))) > 1
                notes(end+1) = "CAUTION: points/decade changes between groups. Treat range and resolution as separate factors.";
            end

            fstart = arrayfun(@(g)g.FreqStart,groups);
            if numel(unique(round(fstart,6))) > 1
                notes(end+1) = "CAUTION: upper frequency limit also changes between groups.";
            end

            vals = arrayfun(@(g)g.KKMean,groups);
            good = isfinite(vals);
            if any(good)
                ids = find(good); [v,q] = min(vals(good)); best = ids(q);
                notes(end+1) = "Lowest mean K-K error: " + groups(best).Label + ...
                    " → " + app.fmt(v,4) + " %";
            end

            vals = arrayfun(@(g)g.RepeatabilityPct,groups);
            good = isfinite(vals);
            if any(good)
                ids = find(good); [v,q] = min(vals(good)); best = ids(q);
                notes(end+1) = "Best repeatability (lowest repeat-to-repeat complex Z difference): " + ...
                    groups(best).Label + " → " + app.fmt(v,4) + " %";
            end

            nonRef = find(~[groups.IsReference]);
            if ~isempty(nonRef)
                vals = arrayfun(@(g)g.SpectrumRefDiffPct,groups(nonRef));
                good = isfinite(vals);
                if any(good)
                    ids = nonRef(good); vv = vals(good); [v,q] = min(vv); best = ids(q);
                    notes(end+1) = "Closest shortened spectrum to the full-band reference: " + ...
                        groups(best).Label + " → " + app.fmt(v,4) + " % mean complex-Z difference";
                end

                vals = arrayfun(@(g)g.ParamRefDiffPct,groups(nonRef));
                good = isfinite(vals);
                if any(good)
                    ids = nonRef(good); vv = vals(good); [v,q] = min(vv); best = ids(q);
                    notes(end+1) = "Closest fitted parameters to the reference: " + ...
                        groups(best).Label + " → " + app.fmt(v,4) + " % mean parameter difference";
                end
            end

            notes(end+1) = "No automatic pass/fail threshold is applied. Freeze the final range only after considering K-K quality, repeatability, parameter stability and preservation of the diagnostic spectrum.";
            notes(end+1) = "Selected mode: " + mode + " | Lab day: " + app.selectedLabDay();

            app.FrequencyDecisionArea.Value = cellstr(notes);
        end

        function r = frequencyRepeatability(app,idx)
            vals = [];
            if numel(idx) < 2
                r = NaN;
                return;
            end
            for a = 1:numel(idx)-1
                for b = a+1:numel(idx)
                    d = app.fraComplexDifference(app.Data.FRA(idx(a)),app.Data.FRA(idx(b)));
                    if isfinite(d), vals(end+1) = d; end %#ok<AGROW>
                end
            end
            r = app.meanFinite(vals);
        end

        function d = frequencyGroupSpectrumDifference(app,idxA,idxB)
            vals = [];
            for a = 1:numel(idxA)
                for b = 1:numel(idxB)
                    d0 = app.fraComplexDifference(app.Data.FRA(idxA(a)),app.Data.FRA(idxB(b)));
                    if isfinite(d0), vals(end+1) = d0; end %#ok<AGROW>
                end
            end
            d = app.meanFinite(vals);
        end

        function d = fraComplexDifference(app,a,b)
            [~,za,zb] = app.alignTwoFRA(a,b);
            if isempty(za)
                d = NaN;
                return;
            end
            den = (abs(za)+abs(zb))/2;
            den(den<eps) = eps;
            d = 100*mean(abs(za-zb)./den);
        end

        function [fCommon,za,zb] = alignTwoFRA(app,a,b) %#ok<INUSL>
            fa = a.Frequency(:); fb = b.Frequency(:);
            za0 = a.Zreal(:) - 1i*a.NegZimag(:);
            zb0 = b.Zreal(:) - 1i*b.NegZimag(:);

            [common,ia,ib] = intersect(fa,fb,'stable');
            if numel(common) >= min(8,round(0.55*min(numel(fa),numel(fb))))
                fCommon = common; za = za0(ia); zb = zb0(ib);
                return;
            end

            lo = max(min(fa),min(fb));
            hi = min(max(fa),max(fb));
            if ~(hi>lo)
                fCommon=[]; za=[]; zb=[]; return;
            end
            n = min(numel(fa),numel(fb));
            fCommon = logspace(log10(lo),log10(hi),n)';
            [fas,oa] = sort(fa); zas = za0(oa);
            [fbs,ob] = sort(fb); zbs = zb0(ob);
            za = interp1(log10(fas),zas,log10(fCommon),'linear');
            zb = interp1(log10(fbs),zbs,log10(fCommon),'linear');
            good = isfinite(za)&isfinite(zb);
            fCommon=fCommon(good); za=za(good); zb=zb(good);
        end

        function ppd = inferPointsPerDecade(app,f) %#ok<INUSL>
            ppd = NaN;
            if f.FreqStart>f.FreqStop && f.FreqStop>0 && f.PointCount>1
                decades = log10(f.FreqStart/f.FreqStop);
                if decades>0
                    ppd = (f.PointCount-1)/decades;
                end
            end
        end

        function s = freqShortLabel(app,fStart,fStop)
            s = app.freqNumber(fStart) + " → " + app.freqNumber(fStop);
        end

        function s = freqNumber(app,x) %#ok<INUSL>
            if ~isfinite(x)
                s = "—";
            elseif x >= 1000
                s = compose('%.4g kHz',x/1000);
            else
                s = compose('%.4g Hz',x);
            end
        end

        function m = meanFinite(app,x) %#ok<INUSL>
            x = x(isfinite(x));
            if isempty(x), m=NaN; else, m=mean(x); end
        end

        function s = stdFinite(app,x) %#ok<INUSL>
            x = x(isfinite(x));
            if numel(x)<2, s=NaN; else, s=std(x,0); end
        end

        function cv = cvFinite(app,x)
            x = x(isfinite(x));
            if numel(x)<2
                cv = NaN;
                return;
            end
            mu = mean(x);
            if abs(mu)<eps
                cv = NaN;
            else
                cv = 100*std(x,0)/abs(mu);
            end
        end


        function updateOperatingPointView(app)
            cla(app.OperatingNyquistAxes);
            cla(app.OperatingIVAxes);
            cla(app.OperatingTargetAxes);
            cla(app.OperatingMetricAxes);

            fraIdx = app.filteredFRAIndices();
            if isempty(fraIdx)
                app.OperatingSummaryTable.Data = {};
                app.OperatingPointDropDown.Items = {'All'};
                app.OperatingPointDropDown.Value = 'All';
                app.OperatingDecisionArea.Value = {'No FRA data are available for the selected lab day.'};
                title(app.OperatingNyquistAxes,'No FRA data for selected day');
                title(app.OperatingIVAxes,'No FRA data for selected day');
                return;
            end

            groups = app.buildOperatingPointGroups(fraIdx);
            if isempty(groups)
                app.OperatingSummaryTable.Data = {};
                app.OperatingDecisionArea.Value = { ...
                    'No operating-point labels or target voltages were recovered from the master log.'};
                return;
            end

            labels = string({groups.Label});
            items = ["All" labels];
            app.OperatingPointDropDown.Items = cellstr(items);
            current = string(app.OperatingPointDropDown.Value);
            if ~any(strcmp(current,items))
                current = "All";
                app.OperatingPointDropDown.Value = 'All';
            end

            % Selected operating-point Nyquist overlay.
            if strcmpi(current,"All")
                selectedIdx = fraIdx;
            else
                gsel = find(strcmp(labels,current),1,'first');
                if isempty(gsel), selectedIdx=[]; else, selectedIdx=groups(gsel).Indices; end
            end

            hold(app.OperatingNyquistAxes,'on');
            for k = selectedIdx
                f = app.Data.FRA(k);
                op = app.fraOperatingPointLabel(f);
                run = f.RunID;
                if strlength(run)==0, run = f.FileInfo.Repeat; end
                leg = op + " | " + upper(string(f.FileInfo.Mode)) + " | " + run;
                plot(app.OperatingNyquistAxes,f.Zreal,f.NegZimag,'-o', ...
                    'MarkerSize',2.5,'LineWidth',1.1,'DisplayName',char(leg));
            end
            hold(app.OperatingNyquistAxes,'off');
            grid(app.OperatingNyquistAxes,'on');
            xlabel(app.OperatingNyquistAxes,"Z' (Ω)");
            ylabel(app.OperatingNyquistAxes,"-Z'' (Ω)");
            title(app.OperatingNyquistAxes,"Nyquist — " + current,'Interpreter','none');
            if ~isempty(selectedIdx)
                legend(app.OperatingNyquistAxes,'Location','best','Interpreter','none');
            end

            % Plot actual settled FRA biases on all measured I-V curves
            % from the selected lab day. This remains meaningful if a second
            % DC curve is taken before a later FRA pass.
            hold(app.OperatingIVAxes,'on');
            dcIdx = app.filteredDCIndices();
            for di = dcIdx
                dc = app.Data.DC(di);
                dcLabel = "I-V " + app.fileNameOnly(dc.Path);
                plot(app.OperatingIVAxes,dc.V,abs(dc.I),'LineWidth',1.35, ...
                    'DisplayName',char(dcLabel));
            end
            for k = fraIdx
                f = app.Data.FRA(k);
                if ~isfinite(f.ActualV) || ~isfinite(f.ActualI), continue; end
                op = app.fraOperatingPointLabel(f);
                leg = upper(string(f.FileInfo.Mode)) + " " + op + " actual";
                if strcmpi(f.FileInfo.Mode,'POT'), mk='o'; else, mk='s'; end
                plot(app.OperatingIVAxes,f.ActualV,abs(f.ActualI),mk, ...
                    'MarkerSize',7,'LineWidth',1.4,'DisplayName',char(leg));
            end
            hold(app.OperatingIVAxes,'off');
            grid(app.OperatingIVAxes,'on');
            xlabel(app.OperatingIVAxes,'Voltage (V)');
            ylabel(app.OperatingIVAxes,'|Current| (A)');
            title(app.OperatingIVAxes,'Actual FRA bias points on measured I-V curve');
            legend(app.OperatingIVAxes,'Location','best','Interpreter','none');

            % Target vs actual settled voltage.
            hold(app.OperatingTargetAxes,'on');
            pT=[]; pA=[]; gT=[]; gA=[]; allV=[];
            for k = fraIdx
                f = app.Data.FRA(k);
                tV = app.analysisTargetV(f);
                if ~isfinite(tV) || ~isfinite(f.ActualV), continue; end
                allV(end+1:end+2) = [tV f.ActualV]; %#ok<AGROW>
                if strcmpi(f.FileInfo.Mode,'POT')
                    pT(end+1)=tV; pA(end+1)=f.ActualV; %#ok<AGROW>
                elseif strcmpi(f.FileInfo.Mode,'GAL')
                    gT(end+1)=tV; gA(end+1)=f.ActualV; %#ok<AGROW>
                end
            end
            if ~isempty(allV)
                mn=min(allV); mx=max(allV); span=max(mx-mn,1);
                lo=max(0,mn-0.05*span); hi=mx+0.05*span;
                plot(app.OperatingTargetAxes,[lo hi],[lo hi],'--', ...
                    'LineWidth',1.0,'DisplayName','Actual = target');
            end
            if ~isempty(pT)
                plot(app.OperatingTargetAxes,pT,pA,'o','LineStyle','none', ...
                    'MarkerSize',7,'LineWidth',1.3,'DisplayName','POT');
            end
            if ~isempty(gT)
                plot(app.OperatingTargetAxes,gT,gA,'s','LineStyle','none', ...
                    'MarkerSize',7,'LineWidth',1.3,'DisplayName','GAL');
            end
            hold(app.OperatingTargetAxes,'off');
            grid(app.OperatingTargetAxes,'on');
            xlabel(app.OperatingTargetAxes,'Target panel voltage (V)');
            ylabel(app.OperatingTargetAxes,'Actual settled voltage (V)');
            title(app.OperatingTargetAxes,'Target vs actual settled voltage');
            if ~isempty(pT) || ~isempty(gT)
                legend(app.OperatingTargetAxes,'Location','best');
            end

            % Per-run summary table.
            rows = cell(numel(fraIdx),17);
            for jj = 1:numel(fraIdx)
                k = fraIdx(jj);
                f = app.Data.FRA(k);
                [voc,isc] = app.referenceDCMetricsForFRA(f);
                vNorm = NaN; iNorm = NaN;
                if isfinite(voc) && voc~=0 && isfinite(f.ActualV)
                    vNorm = f.ActualV/voc;
                end
                if isfinite(isc) && isc~=0 && isfinite(f.ActualI)
                    iNorm = 100*abs(f.ActualI)/abs(isc);
                end
                nearest = app.closestOperatingPointLabel(f.ActualV,groups);
                pairStatus = app.operatingPointPairStatus(app.fraOperatingPointLabel(f),groups);
                targetVUsed = app.analysisTargetV(f);

                rows(jj,:) = {f.RunID,app.fraOperatingPointLabel(f),upper(string(f.FileInfo.Mode)), ...
                    targetVUsed,f.ActualV,f.ActualV-targetVUsed,vNorm, ...
                    f.TargetI,f.ActualI,iNorm,nearest,f.KKMeanAbs, ...
                    f.Params.Rs,f.Params.Rp,f.Params.Y0,f.Params.n,pairStatus};
            end
            app.setUITableData(app.OperatingSummaryTable,rows,'Operating point summary');

            app.updateOperatingMetricPlot(groups);
            app.updateOperatingPointDecisionSupport(groups,fraIdx);
        end

        function groups = buildOperatingPointGroups(app,fraIdx)
            groups = struct([]);
            if isempty(fraIdx), return; end

            labels = strings(numel(fraIdx),1);
            for ii=1:numel(fraIdx)
                labels(ii) = app.fraOperatingPointLabel(app.Data.FRA(fraIdx(ii)));
            end
            usable = strlength(labels)>0;
            fraIdx = fraIdx(usable);
            labels = labels(usable);
            if isempty(fraIdx), return; end

            u = unique(labels,'stable');
            for j=1:numel(u)
                idx = fraIdx(strcmp(labels,u(j)));
                tV = arrayfun(@(k)app.analysisTargetV(app.Data.FRA(k)),idx);
                tI = arrayfun(@(k)app.Data.FRA(k).TargetI,idx);
                aV = arrayfun(@(k)app.Data.FRA(k).ActualV,idx);
                aI = arrayfun(@(k)app.Data.FRA(k).ActualI,idx);

                g = struct();
                g.Label = u(j);
                g.Indices = idx;
                g.TargetV = app.meanFinite(tV);
                g.TargetI = app.meanFinite(tI);
                g.ActualVMean = app.meanFinite(aV);
                g.ActualIMean = app.meanFinite(aI);
                g.PotIndices = idx(arrayfun(@(k)strcmpi(app.Data.FRA(k).FileInfo.Mode,'POT'),idx));
                g.GalIndices = idx(arrayfun(@(k)strcmpi(app.Data.FRA(k).FileInfo.Mode,'GAL'),idx));

                if isempty(groups), groups=g; else, groups(end+1)=g; end %#ok<AGROW>
            end

            sortV = arrayfun(@(g)g.TargetV,groups);
            sortV(~isfinite(sortV)) = -Inf;
            [~,ord] = sort(sortV,'descend');
            groups = groups(ord);
        end

        function label = fraOperatingPointLabel(app,f) %#ok<INUSL>
            label = strtrim(string(f.OperatingPoint));
            if strlength(label)==0
                label = strtrim(string(f.FileInfo.OP));
            end
            if ismissing(label), label=""; end
        end

        function label = closestOperatingPointLabel(app,actualV,groups) %#ok<INUSL>
            label = "";
            if ~isfinite(actualV) || isempty(groups), return; end
            targets = arrayfun(@(g)g.TargetV,groups);
            good = isfinite(targets);
            if ~any(good), return; end
            ids = find(good);
            [~,q] = min(abs(targets(good)-actualV));
            label = string(groups(ids(q)).Label);
        end

        function status = operatingPointPairStatus(app,opLabel,groups)
            status = "";
            gi = find(strcmp(string({groups.Label}),string(opLabel)),1,'first');
            if isempty(gi), return; end
            g = groups(gi);
            if isempty(g.PotIndices) || isempty(g.GalIndices)
                status = "POT/GAL pair incomplete";
                return;
            end

            potRegions = strings(0,1);
            for k=g.PotIndices
                potRegions(end+1) = app.closestOperatingPointLabel(app.Data.FRA(k).ActualV,groups); %#ok<AGROW>
            end
            galRegions = strings(0,1);
            for k=g.GalIndices
                galRegions(end+1) = app.closestOperatingPointLabel(app.Data.FRA(k).ActualV,groups); %#ok<AGROW>
            end

            nominal = string(g.Label);
            potOK = all(strcmp(potRegions,nominal));
            galOK = all(strcmp(galRegions,nominal));

            pV = app.meanFinite(arrayfun(@(k)app.Data.FRA(k).ActualV,g.PotIndices));
            gV = app.meanFinite(arrayfun(@(k)app.Data.FRA(k).ActualV,g.GalIndices));
            dv = abs(pV-gV);

            if ~(potOK && galOK)
                details = strings(0,1);
                if ~potOK
                    details(end+1) = "POT closest to " + strjoin(unique(potRegions),'/'); %#ok<AGROW>
                end
                if ~galOK
                    details(end+1) = "GAL closest to " + strjoin(unique(galRegions),'/'); %#ok<AGROW>
                end
                status = "OP mismatch; spectra not compared (" + strjoin(details,'; ') + ")";
                return;
            end

            diffs=[];
            for p=g.PotIndices
                for q=g.GalIndices
                    d=app.fraComplexDifference(app.Data.FRA(p),app.Data.FRA(q));
                    if isfinite(d), diffs(end+1)=d; end %#ok<AGROW>
                end
            end
            zDiff=app.meanFinite(diffs);
            if isfinite(zDiff)
                status = "Comparable bias; ΔV=" + app.fmt(dv,4) + ...
                    " V; mean complex-Z diff=" + app.fmt(zDiff,4) + " %";
            else
                status = "Comparable bias; ΔV=" + app.fmt(dv,4) + " V";
            end
        end


        function dc = operatingPointReferenceDC(app,fraIdx)
            dc = struct([]);
            if isempty(app.Data.DC), return; end

            day = app.selectedLabDay();
            candidates=[];
            for k=1:numel(app.Data.DC)
                if strcmpi(day,"All") || strcmpi(app.Data.DC(k).FileInfo.Date,day)
                    candidates(end+1)=k; %#ok<AGROW>
                end
            end
            if isempty(candidates), return; end

            fraRows=arrayfun(@(k)app.Data.FRA(k).MasterIndex,fraIdx);
            fraRows=fraRows(isfinite(fraRows));
            if ~isempty(fraRows)
                firstFra=min(fraRows);
                before=candidates(arrayfun(@(k)isfinite(app.Data.DC(k).MasterIndex) && ...
                    app.Data.DC(k).MasterIndex<firstFra,candidates));
                if ~isempty(before)
                    [~,q]=max(arrayfun(@(k)app.Data.DC(k).MasterIndex,before));
                    dc=app.Data.DC(before(q));
                    return;
                end
            end
            dc=app.Data.DC(candidates(1));
        end

        function [voc,isc] = referenceDCMetricsForFRA(app,f)
            voc=NaN; isc=NaN;
            if isempty(app.Data.DC), return; end
            date=string(f.FileInfo.Date);
            candidates=[];
            for k=1:numel(app.Data.DC)
                if strcmpi(app.Data.DC(k).FileInfo.Date,date)
                    candidates(end+1)=k; %#ok<AGROW>
                end
            end
            if isempty(candidates), return; end

            if isfinite(f.MasterIndex)
                before=candidates(arrayfun(@(k)isfinite(app.Data.DC(k).MasterIndex) && ...
                    app.Data.DC(k).MasterIndex<f.MasterIndex,candidates));
                if ~isempty(before)
                    [~,q]=max(arrayfun(@(k)app.Data.DC(k).MasterIndex,before));
                    d=app.Data.DC(before(q));
                    voc=d.Voc; isc=d.Isc;
                    return;
                end
            end

            d=app.Data.DC(candidates(1));
            voc=d.Voc; isc=d.Isc;
        end


        function v = analysisTargetV(app,f) %#ok<INUSL>
            % Return the physical panel target voltage used for analysis.
            % The master log itself is never changed here.
            %
            % The rig's Nova voltage command is /10 of panel voltage. If the
            % Target Panel DC V cell appears to contain that Nova command
            % instead (e.g. target 2.09 V, actual ~20.9 V), use 10x ONLY for
            % analysis and surface a warning in Decision Support.
            v = f.TargetV;
            if ~isfinite(v), return; end
            if isfinite(f.ActualV) && f.ActualV>0 && v>0
                rawErr = abs(f.ActualV-v);
                scaledErr = abs(f.ActualV-10*v);
                likelyScaleMix = (v < 0.5*f.ActualV) && (scaledErr < rawErr);
                if isfinite(f.NovaApplyV)
                    likelyScaleMix = likelyScaleMix && abs(f.NovaApplyV-v) <= max(0.02,0.02*abs(v));
                end
                if likelyScaleMix
                    v = 10*v;
                end
            end
        end

        function tf = hasTargetVoltageScaleWarning(app,f) %#ok<INUSL>
            tf = false;
            if ~isfinite(f.TargetV) || ~isfinite(f.ActualV) || f.TargetV<=0 || f.ActualV<=0
                return;
            end
            rawErr = abs(f.ActualV-f.TargetV);
            scaledErr = abs(f.ActualV-10*f.TargetV);
            tf = (f.TargetV < 0.5*f.ActualV) && (scaledErr < rawErr);
            if isfinite(f.NovaApplyV)
                tf = tf && abs(f.NovaApplyV-f.TargetV) <= max(0.02,0.02*abs(f.TargetV));
            end
        end

        function updateOperatingMetricPlot(app,groups)
            if nargin<2 || isempty(groups)
                fraIdx=app.filteredFRAIndices();
                groups=app.buildOperatingPointGroups(fraIdx);
                if isempty(groups), return; end
            end

            metric=string(app.OperatingMetricDropDown.Value);
            fraIdx=[groups.Indices];
            xP=[]; yP=[]; lP=strings(0,1);
            xG=[]; yG=[]; lG=strings(0,1);

            for k=fraIdx
                f=app.Data.FRA(k);
                [voc,isc]=app.referenceDCMetricsForFRA(f);
                if ~isfinite(voc) || voc==0 || ~isfinite(f.ActualV), continue; end
                x=f.ActualV/voc;

                switch metric
                    case "Mean |K-K Error Z'| (%)"
                        y=f.KKMeanAbs;
                    case "Rs (Ω)"
                        y=f.Params.Rs;
                    case "Rp/Rct (Ω)"
                        y=f.Params.Rp;
                    case "CPE Y0"
                        y=f.Params.Y0;
                    case "CPE n"
                        y=f.Params.n;
                    case "Target voltage error (% Voc)"
                        targetVUsed=app.analysisTargetV(f);
                        if isfinite(targetVUsed)
                            y=100*(f.ActualV-targetVUsed)/voc;
                        else
                            y=NaN;
                        end
                    case "|Actual current| / Isc (%)"
                        if isfinite(isc) && isc~=0 && isfinite(f.ActualI)
                            y=100*abs(f.ActualI)/abs(isc);
                        else
                            y=NaN;
                        end
                    otherwise
                        y=NaN;
                end
                if ~isfinite(y), continue; end

                label=app.fraOperatingPointLabel(f);
                if strcmpi(f.FileInfo.Mode,'POT')
                    xP(end+1)=x; yP(end+1)=y; lP(end+1)=label; %#ok<AGROW>
                elseif strcmpi(f.FileInfo.Mode,'GAL')
                    xG(end+1)=x; yG(end+1)=y; lG(end+1)=label; %#ok<AGROW>
                end
            end

            cla(app.OperatingMetricAxes);
            hold(app.OperatingMetricAxes,'on');
            if ~isempty(xP)
                [xP,ord]=sort(xP); yP=yP(ord); lP=lP(ord);
                plot(app.OperatingMetricAxes,xP,yP,'o-','LineWidth',1.2,'MarkerSize',7,'DisplayName','POT');
            end
            if ~isempty(xG)
                [xG,ord]=sort(xG); yG=yG(ord); lG=lG(ord);
                plot(app.OperatingMetricAxes,xG,yG,'s-','LineWidth',1.2,'MarkerSize',7,'DisplayName','GAL');
            end
            hold(app.OperatingMetricAxes,'off');
            grid(app.OperatingMetricAxes,'on');
            xlabel(app.OperatingMetricAxes,'Actual V / measured Voc');
            ylabel(app.OperatingMetricAxes,char(metric),'Interpreter','none');
            title(app.OperatingMetricAxes,char(metric + " vs actual normalised voltage"),'Interpreter','none');
            if ~isempty(xP) || ~isempty(xG)
                legend(app.OperatingMetricAxes,'Location','best');
            end

            hold(app.OperatingMetricAxes,'on');
            for ii=1:numel(xP)
                text(app.OperatingMetricAxes,xP(ii),yP(ii),"  "+lP(ii), ...
                    'VerticalAlignment','bottom','Interpreter','none');
            end
            for ii=1:numel(xG)
                text(app.OperatingMetricAxes,xG(ii),yG(ii),"  "+lG(ii), ...
                    'VerticalAlignment','top','Interpreter','none');
            end
            hold(app.OperatingMetricAxes,'off');
        end

        function updateOperatingPointDecisionSupport(app,groups,fraIdx)
            notes=strings(0,1);
            notes(end+1)="Operating-point analysis uses ACTUAL settled V/I from the master log, not only the nominal label.";

            for k=fraIdx
                f=app.Data.FRA(k);
                if app.hasTargetVoltageScaleWarning(f)
                    notes(end+1)="MASTER LOG CHECK: " + f.RunID + ...
                        " Target Panel DC V=" + app.fmt(f.TargetV,4) + ...
                        " V appears to contain the Nova /10 command. For analysis only, v0.1.8 is using " + ...
                        app.fmt(app.analysisTargetV(f),4) + " V. Correct the master log manually if confirmed.";
                end
            end

            for gi=1:numel(groups)
                g=groups(gi);
                pV=app.meanFinite(arrayfun(@(k)app.Data.FRA(k).ActualV,g.PotIndices));
                gV=app.meanFinite(arrayfun(@(k)app.Data.FRA(k).ActualV,g.GalIndices));
                if ~isempty(g.PotIndices) && ~isempty(g.GalIndices) && isfinite(pV) && isfinite(gV)
                    status=app.operatingPointPairStatus(g.Label,groups);
                    notes(end+1)=g.Label + ": POT actual V=" + app.fmt(pV,4) + ...
                        " V; GAL actual V=" + app.fmt(gV,4) + " V → " + status;
                end
            end

            errs=[]; ids=[];
            for k=fraIdx
                f=app.Data.FRA(k);
                targetVUsed=app.analysisTargetV(f);
                if isfinite(targetVUsed) && isfinite(f.ActualV)
                    errs(end+1)=abs(f.ActualV-targetVUsed); ids(end+1)=k; %#ok<AGROW>
                end
            end
            if ~isempty(errs)
                [mx,q]=max(errs); f=app.Data.FRA(ids(q));
                nearest=app.closestOperatingPointLabel(f.ActualV,groups);
                notes(end+1)="Largest target-voltage miss: " + f.RunID + " (" + ...
                    upper(string(f.FileInfo.Mode)) + ", nominal " + app.fraOperatingPointLabel(f) + ...
                    ") → |ΔV|=" + app.fmt(mx,4) + " V; actual V is closest to " + nearest + ".";
            end

            kk=arrayfun(@(k)app.Data.FRA(k).KKMeanAbs,fraIdx);
            good=isfinite(kk);
            if any(good)
                ids=fraIdx(good); vals=kk(good);
                [mn,q1]=min(vals); [mx,q2]=max(vals);
                notes(end+1)="K-K range across these FRA runs: " + app.fmt(mn,4) + ...
                    " % (" + app.Data.FRA(ids(q1)).RunID + ") to " + app.fmt(mx,4) + ...
                    " % (" + app.Data.FRA(ids(q2)).RunID + ").";
            end

            notes(end+1)="POT/GAL complex-Z differences are suppressed when either mode settles closest to a different nominal voltage region.";
            notes(end+1)="No automatic pass/fail threshold is imposed. Use this tab to decide whether a poor Nyquist spectrum reflects FRA quality, a mismatched DC operating point, or both.";

            app.OperatingDecisionArea.Value=cellstr(notes);
        end

        function updateEnvironmentView(app)
            if isempty(app.Data.Environments), return; end
            selected = string(app.EnvDropDown.Value);
            idx = [];
            for k = 1:numel(app.Data.Environments)
                if strcmpi(string(app.Data.Environments(k).ID),selected)
                    idx = k;
                    break;
                end
            end
            if isempty(idx), return; end
            e = app.Data.Environments(idx);

            app.plotGrid(app.TempAxes,e.TempGrid,'Temperature (°C)');
            app.plotGrid(app.IrrAxes,e.IrrGrid,'Irradiance (W/m²)');

            app.setUITableData(app.EnvSummaryTable, {
                'Environment ID',e.ID;
                'Label',e.Label;
                'Temperature average (°C)',app.fmt(e.TempAvg,3);
                'Temperature min / max (°C)',app.fmt(e.TempMin,3)+" / "+app.fmt(e.TempMax,3);
                'Temperature range (°C)',app.fmt(e.TempRange,3);
                'Irradiance average (W/m²)',app.fmt(e.IrrAvg,4);
                'Irradiance min / max (W/m²)',app.fmt(e.IrrMin,4)+" / "+app.fmt(e.IrrMax,4);
                'Irradiance range (W/m²)',app.fmt(e.IrrRange,4);
                'Variac',app.fmt(e.Variac,4);
                'Lamp–panel distance (cm)',app.fmt(e.DistanceCm,4);
                'Fan',e.Fan;
                'Linked Run IDs',e.LinkedRunIDs;
                'Workbook',app.fileNameOnly(e.Path);
                }, 'Environment summary');
        end

        function plotGrid(app,ax,M,cbarLabel) %#ok<INUSL>
            cla(ax);
            if isempty(M) || all(~isfinite(M),'all')
                title(ax,'No grid data'); return;
            end
            imagesc(ax,M);
            axis(ax,'image');
            ax.XTick = 1:3; ax.XTickLabel = {'Left','Centre','Right'};
            ax.YTick = 1:3; ax.YTickLabel = {'Top','Middle','Bottom'};
            cb = colorbar(ax); cb.Label.String = cbarLabel;
            for r=1:3
                for c=1:3
                    if isfinite(M(r,c))
                        text(ax,c,r,compose('%.1f',M(r,c)), ...
                            'HorizontalAlignment','center','FontWeight','bold','Color','k', ...
                            'BackgroundColor',[1 1 1]);
                    end
                end
            end
        end

        function updateMasterLog(app)
            if strlength(app.Data.MasterPath)==0 || isempty(app.Data.Master)
                uialert(app.UIFigure, ...
                    'No active PV_Lab_Master_Log.xlsx was found in the imported project.', ...
                    'Master log unavailable','Icon','warning');
                return;
            end

            proposals = app.buildMasterUpdateProposals();
            if isempty(proposals)
                uialert(app.UIFigure, ...
                    ['No blank derived-result cells can currently be filled. ' ...
                     'Make sure the DC/FRA files and *_PARAMS.xlsx files are inside the imported project folder.'], ...
                    'Nothing to update','Icon','info');
                return;
            end

            applyMask = strcmpi(string({proposals.Action}),'FILL');
            nFill = sum(applyMask);
            nSkip = numel(proposals)-nFill;

            proceed = app.showMasterUpdatePreview(proposals,nFill,nSkip);
            if ~proceed
                return;
            end

            if nFill==0
                uialert(app.UIFigure, ...
                    'All proposed values already exist or conflict with nonblank master-log cells. Nothing was changed.', ...
                    'Nothing written','Icon','info');
                return;
            end

            msg = sprintf(['v0.1.6 will fill %d blank derived-result cells in the active master log.\n\n' ...
                'It will NOT change Status, filenames, test settings, temperatures, amplitudes, or any nonblank conflicting values.\n\n' ...
                'An automatic timestamped backup will be created first.'],nFill);

            choice = uiconfirm(app.UIFigure,msg,'Apply master-log updates?', ...
                'Options',{'Apply + create backup','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2);
            if ~strcmp(choice,'Apply + create backup')
                return;
            end

            masterPath = char(app.Data.MasterPath);
            [masterFolder,masterStem,masterExt] = fileparts(masterPath);
            stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
            backupPath = fullfile(masterFolder,[masterStem '_BACKUP_' stamp masterExt]);

            app.StatusLabel.Text = 'Updating master...';
            drawnow;

            try
                copyfile(masterPath,backupPath);

                for k = find(applyMask)
                    p = proposals(k);
                    headerIndex = find(strcmp(app.Data.Master.Properties.VariableNames,p.Header),1,'first');
                    if isempty(headerIndex)
                        continue;
                    end
                    excelRow = p.MasterIndex + 1; % Excel row 1 is the table header
                    excelCol = app.excelColumnName(headerIndex);
                    address = sprintf('%s%d',excelCol,excelRow);

                    if isnumeric(p.Proposed) && isscalar(p.Proposed)
                        writematrix(double(p.Proposed),masterPath,'Sheet','Run Log','Range',address);
                    else
                        writecell({char(string(p.Proposed))},masterPath,'Sheet','Run Log','Range',address);
                    end
                end

                % Re-read the project so the dashboard immediately reflects
                % the values that were written to the master workbook.
                selectedDay = app.selectedLabDay();
                app.Data = app.scanAndAnalyze(app.RootFolder);
                app.populateLabDayFilter();
                if any(strcmp(app.LabDayDropDown.Items,char(selectedDay)))
                    app.LabDayDropDown.Value = char(selectedDay);
                end
                app.updateAllViews();
                app.UpdateMasterButton.Enable = 'on';
                app.ExportButton.Enable = 'on';
                app.StatusLabel.Text = sprintf('Master updated • %d cells • v0.1.9',nFill);

                uialert(app.UIFigure, ...
                    sprintf('Updated %d blank derived-result cells.\n\nBackup created:\n%s',nFill,backupPath), ...
                    'Master log updated','Icon','success');
            catch ME
                app.StatusLabel.Text = 'Master update failed';
                uialert(app.UIFigure, ...
                    sprintf('%s\n\nThe backup was created before writing whenever possible.',ME.message), ...
                    'Master update error','Icon','error');
            end
        end

        function proposals = buildMasterUpdateProposals(app)
            proposals = struct('MasterIndex',{},'RunID',{},'File',{},'Test',{}, ...
                'Header',{},'Existing',{},'Proposed',{},'Source',{},'Action',{});

            if isempty(app.Data.Master)
                return;
            end

            % DC-derived quantities belong on the DC row only.
            for k = 1:numel(app.Data.DC)
                d = app.Data.DC(k);
                if ~isfinite(d.MasterIndex), continue; end
                src = "Calculated from DC export";
                proposals = app.addMasterProposal(proposals,d.MasterIndex, ...
                    app.masterRunIDAt(d.MasterIndex),app.fileNameOnly(d.Path),"DC", ...
                    'Voc (V)',d.Voc,src);
                proposals = app.addMasterProposal(proposals,d.MasterIndex, ...
                    app.masterRunIDAt(d.MasterIndex),app.fileNameOnly(d.Path),"DC", ...
                    'Isc (A)',d.Isc,src);
                proposals = app.addMasterProposal(proposals,d.MasterIndex, ...
                    app.masterRunIDAt(d.MasterIndex),app.fileNameOnly(d.Path),"DC", ...
                    'Vmp (V)',d.Vmp,src);
                proposals = app.addMasterProposal(proposals,d.MasterIndex, ...
                    app.masterRunIDAt(d.MasterIndex),app.fileNameOnly(d.Path),"DC", ...
                    'Imp (A)',d.Imp,src);
                proposals = app.addMasterProposal(proposals,d.MasterIndex, ...
                    app.masterRunIDAt(d.MasterIndex),app.fileNameOnly(d.Path),"DC", ...
                    'Pmp (W)',d.Pmp,src);
            end

            % FRA-derived quantities belong on the corresponding FRA row.
            for k = 1:numel(app.Data.FRA)
                f = app.Data.FRA(k);
                if ~isfinite(f.MasterIndex), continue; end
                rid = app.masterRunIDAt(f.MasterIndex);
                file = app.fileNameOnly(f.Path);
                srcKK = "Calculated from FRA export";
                srcFit = "Nova parameter export";
                if strlength(f.ParamSource)>0
                    srcFit = f.ParamSource;
                end

                proposals = app.addMasterProposal(proposals,f.MasterIndex,rid,file,"FRA", ...
                    "Mean |K-K Error Z'| (%)",f.KKMeanAbs,srcKK);
                proposals = app.addMasterProposal(proposals,f.MasterIndex,rid,file,"FRA", ...
                    'Rs (Ω)',f.Params.Rs,srcFit);
                proposals = app.addMasterProposal(proposals,f.MasterIndex,rid,file,"FRA", ...
                    'Rp / Rct (Ω)',f.Params.Rp,srcFit);
                proposals = app.addMasterProposal(proposals,f.MasterIndex,rid,file,"FRA", ...
                    'CPE Y0',f.Params.Y0,srcFit);
                proposals = app.addMasterProposal(proposals,f.MasterIndex,rid,file,"FRA", ...
                    'CPE n',f.Params.n,srcFit);

                % Only write the fit-source dropdown when a separate Nova
                % parameter export was actually linked to the FRA run.
                if strlength(f.ParamFile)>0
                    proposals = app.addMasterProposal(proposals,f.MasterIndex,rid,file,"FRA", ...
                        'Circuit Fit Source',"Nova export","Linked *_PARAMS.xlsx");
                end
            end
        end

        function proposals = addMasterProposal(app,proposals,rowIndex,runID,file,test,header,proposed,source)
            if isnumeric(proposed)
                if isempty(proposed) || ~isscalar(proposed) || ~isfinite(proposed)
                    return;
                end
            else
                proposed = string(proposed);
                if ismissing(proposed) || strlength(strtrim(proposed))==0
                    return;
                end
            end

            actualHeader = app.findHeader(string(app.Data.Master.Properties.VariableNames),string(header));
            if strlength(actualHeader)==0
                return;
            end

            rawExisting = app.tableValue(app.Data.Master,actualHeader,rowIndex);
            existingText = app.valueToDisplay(rawExisting);
            blank = app.valueIsBlank(rawExisting);

            if isnumeric(proposed)
                proposedText = app.fmt(proposed,8);
            else
                proposedText = string(proposed);
            end

            action = "FILL";
            if ~blank
                if app.valuesEquivalent(rawExisting,proposed)
                    action = "SAME";
                else
                    action = "SKIP – existing value";
                end
            end

            p = struct();
            p.MasterIndex = rowIndex;
            p.RunID = string(runID);
            p.File = string(file);
            p.Test = string(test);
            p.Header = char(actualHeader);
            p.Existing = string(existingText);
            p.Proposed = proposed;
            p.Source = string(source);
            p.Action = string(action);

            if isempty(proposals)
                proposals = p;
            else
                proposals(end+1) = p; %#ok<AGROW>
            end
        end

        function proceed = showMasterUpdatePreview(app,proposals,nFill,nSkip)
            proceed = false;
            fig = uifigure('Name','Master Update Preview — v0.1.6', ...
                'Position',[160 120 1220 650]);
            fig.UserData = false;

            g = uigridlayout(fig,[3 1]);
            g.RowHeight = {58,'1x',50};
            g.Padding = [10 10 10 10];

            note = uilabel(g, ...
                'Text',sprintf(['Preview only — %d blank cells will be filled; %d existing/same values will be left unchanged. ' ...
                'Status and raw test settings are never modified.'],nFill,nSkip), ...
                'FontWeight','bold','WordWrap','on');
            note.Layout.Row = 1;

            tbl = uitable(g);
            tbl.Layout.Row = 2;
            tbl.ColumnName = {'Run ID','Test','File','Field','Existing','Proposed','Source','Action'};
            tbl.ColumnWidth = {120,70,280,190,110,110,180,130};
            tbl.RowName = {};
            rows = cell(numel(proposals),8);
            for k = 1:numel(proposals)
                p = proposals(k);
                rows(k,:) = {char(p.RunID),char(p.Test),char(p.File),char(string(p.Header)), ...
                    char(p.Existing),char(app.proposalDisplay(p.Proposed)),char(p.Source),char(p.Action)};
            end
            app.setUITableData(tbl,rows,'Master update preview');

            b = uigridlayout(g,[1 3]);
            b.Layout.Row = 3;
            b.ColumnWidth = {'1x',170,120};
            b.Padding = [0 0 0 0];
            uilabel(b,'Text','Only rows marked FILL will be written.');
            applyBtn = uibutton(b,'push','Text','Continue to Apply', ...
                'FontWeight','bold','ButtonPushedFcn',@(src,event)app.resumePreview(fig,true));
            applyBtn.Layout.Column = 2;
            cancelBtn = uibutton(b,'push','Text','Cancel', ...
                'ButtonPushedFcn',@(src,event)app.resumePreview(fig,false));
            cancelBtn.Layout.Column = 3;
            fig.CloseRequestFcn = @(src,event)app.resumePreview(fig,false);

            uiwait(fig);
            if isvalid(fig)
                proceed = logical(fig.UserData);
                delete(fig);
            end
        end

        function resumePreview(app,fig,value) %#ok<INUSL>
            if isempty(fig) || ~isvalid(fig), return; end
            fig.UserData = logical(value);
            uiresume(fig);
        end

        function rid = masterRunIDAt(app,rowIndex)
            rid = "";
            if isempty(app.Data.Master) || ~isfinite(rowIndex), return; end
            name = app.findHeader(string(app.Data.Master.Properties.VariableNames),"Run ID");
            if strlength(name)==0, return; end
            rid = app.tableTextAt(app.Data.Master,name,rowIndex);
        end

        function tf = valueIsBlank(app,v) %#ok<INUSL>
            tf = true;
            try
                while iscell(v) && numel(v)==1
                    v = v{1};
                end
                if isempty(v), return; end
                if isnumeric(v)
                    tf = ~isscalar(v) || ~isfinite(v);
                    return;
                end
                if isdatetime(v)
                    tf = isnat(v);
                    return;
                end
                s = strtrim(string(v));
                tf = ismissing(s) || strlength(s)==0 || strcmpi(s,"<missing>") || strcmpi(s,"NaN");
            catch
                tf = true;
            end
        end

        function s = valueToDisplay(app,v) %#ok<INUSL>
            s = "";
            try
                while iscell(v) && numel(v)==1
                    v = v{1};
                end
                if isempty(v), return; end
                if isnumeric(v)
                    if isscalar(v) && isfinite(v)
                        s = compose('%.8g',double(v));
                    end
                elseif isdatetime(v)
                    if ~isnat(v), s = string(v); end
                else
                    s = string(v);
                    if ismissing(s), s = ""; end
                end
            catch
                s = "";
            end
        end

        function tf = valuesEquivalent(app,existing,proposed) %#ok<INUSL>
            tf = false;
            try
                while iscell(existing) && numel(existing)==1
                    existing = existing{1};
                end
                if isnumeric(proposed)
                    if isnumeric(existing) && isscalar(existing) && isfinite(existing)
                        scale = max([1 abs(double(existing)) abs(double(proposed))]);
                        tf = abs(double(existing)-double(proposed)) <= 1e-7*scale;
                    else
                        e = str2double(string(existing));
                        if isfinite(e)
                            scale = max([1 abs(e) abs(double(proposed))]);
                            tf = abs(e-double(proposed)) <= 1e-7*scale;
                        end
                    end
                else
                    tf = strcmpi(strtrim(string(existing)),strtrim(string(proposed)));
                end
            catch
                tf = false;
            end
        end

        function s = proposalDisplay(app,v)
            if isnumeric(v)
                s = app.fmt(v,8);
            else
                s = string(v);
            end
        end

        function col = excelColumnName(app,n) %#ok<INUSL>
            col = '';
            while n > 0
                r = mod(n-1,26);
                col = [char(65+r) col]; %#ok<AGROW>
                n = floor((n-1)/26);
            end
        end

        function exportSummary(app)
            if isempty(app.Data.Files), return; end
            defaultName = 'PVLab_Analysis_Summary.xlsx';
            [file,path] = uiputfile('*.xlsx','Export analysis summary',fullfile(char(app.RootFolder),defaultName));
            if isequal(file,0), return; end
            out = fullfile(path,file);
            try
                if exist(out,'file'), delete(out); end

                % DC summary
                if ~isempty(app.Data.DC)
                    n=numel(app.Data.DC);
                    File=strings(n,1); Voc=nan(n,1); Isc=Voc; Vmp=Voc; Imp=Voc; Pmp=Voc; FF=Voc; Env=strings(n,1);
                    for k=1:n
                        d=app.Data.DC(k); File(k)=app.fileNameOnly(d.Path); Voc(k)=d.Voc; Isc(k)=d.Isc; Vmp(k)=d.Vmp; Imp(k)=d.Imp; Pmp(k)=d.Pmp; FF(k)=d.FillFactor;
                        if ~isempty(d.Environment), Env(k)=d.Environment.ID; end
                    end
                    writetable(table(File,Voc,Isc,Vmp,Imp,Pmp,FF,Env),out,'Sheet','DC');
                end

                % FRA summary
                if ~isempty(app.Data.FRA)
                    n=numel(app.Data.FRA);
                    File=strings(n,1); Mode=File; Repeat=File; RunID=File; Env=File; Unit=File;
                    Amp=nan(n,1); KK=Amp; Rs=Amp; Rp=Amp; Y0=Amp; CPE_n=Amp; ActualV=Amp; ActualI=Amp; DeltaT=Amp;
                    for k=1:n
                        f=app.Data.FRA(k); File(k)=app.fileNameOnly(f.Path); Mode(k)=f.FileInfo.Mode; Repeat(k)=f.FileInfo.Repeat; RunID(k)=f.RunID; Unit(k)=f.ACUnit;
                        Amp(k)=f.Amplitude; KK(k)=f.KKMeanAbs; Rs(k)=f.Params.Rs; Rp(k)=f.Params.Rp; Y0(k)=f.Params.Y0; CPE_n(k)=f.Params.n;
                        ActualV(k)=f.ActualV; ActualI(k)=f.ActualI; DeltaT(k)=f.DeltaT; if ~isempty(f.Environment), Env(k)=f.Environment.ID; end
                    end
                    writetable(table(File,RunID,Mode,Repeat,Amp,Unit,KK,Rs,Rp,Y0,CPE_n,ActualV,ActualI,DeltaT,Env),out,'Sheet','FRA');
                end

                % Pair summary
                if ~isempty(app.Data.Pairs)
                    n=numel(app.Data.Pairs); Label=strings(n,1); MeanZDiffPct=nan(n,1); RMSE=MeanZDiffPct; RsDiffPct=MeanZDiffPct; RpDiffPct=MeanZDiffPct; Y0Ratio=MeanZDiffPct; NDiff=MeanZDiffPct;
                    for k=1:n
                        p=app.Data.Pairs(k); Label(k)=p.Label; MeanZDiffPct(k)=p.MeanRelComplexDiffPct; RMSE(k)=p.RMSE; RsDiffPct(k)=p.RsDiffPct; RpDiffPct(k)=p.RpDiffPct; Y0Ratio(k)=p.Y0Ratio; NDiff(k)=p.NDiff;
                    end
                    writetable(table(Label,MeanZDiffPct,RMSE,RsDiffPct,RpDiffPct,Y0Ratio,NDiff),out,'Sheet','Pairs');
                end

                % Environment summary
                if ~isempty(app.Data.Environments)
                    n=numel(app.Data.Environments); EnvironmentID=strings(n,1); Label=EnvironmentID; Fan=EnvironmentID; LinkedRunIDs=EnvironmentID;
                    TempAvg=nan(n,1); TempMin=TempAvg; TempMax=TempAvg; TempRange=TempAvg; IrrAvg=TempAvg; IrrMin=TempAvg; IrrMax=TempAvg; IrrRange=TempAvg; Variac=TempAvg; DistanceCm=TempAvg;
                    for k=1:n
                        e=app.Data.Environments(k); EnvironmentID(k)=e.ID; Label(k)=e.Label; Fan(k)=e.Fan; LinkedRunIDs(k)=e.LinkedRunIDs;
                        TempAvg(k)=e.TempAvg; TempMin(k)=e.TempMin; TempMax(k)=e.TempMax; TempRange(k)=e.TempRange; IrrAvg(k)=e.IrrAvg; IrrMin(k)=e.IrrMin; IrrMax(k)=e.IrrMax; IrrRange(k)=e.IrrRange; Variac(k)=e.Variac;
                        if isfield(e,'DistanceCm'), DistanceCm(k)=e.DistanceCm; end
                    end
                    writetable(table(EnvironmentID,Label,TempAvg,TempMin,TempMax,TempRange,IrrAvg,IrrMin,IrrMax,IrrRange,Variac,DistanceCm,Fan,LinkedRunIDs),out,'Sheet','Environment');
                end

                % Current Operating Point view summary.
                try
                    fraIdx = app.filteredFRAIndices();
                    og = app.buildOperatingPointGroups(fraIdx);
                    if ~isempty(og) && ~isempty(fraIdx)
                        n=numel(fraIdx);
                        RunID=strings(n,1); NominalOP=RunID; Mode=RunID;
                        ClosestTargetRegion=RunID; PairComparison=RunID;
                        TargetV=nan(n,1); ActualV=TargetV; DeltaV=TargetV; VoverVoc=TargetV;
                        TargetI=TargetV; ActualI=TargetV; AbsIoverIscPct=TargetV;
                        KKMean=TargetV; Rs=TargetV; Rp_Rct=TargetV; CPE_Y0=TargetV; CPE_n=TargetV;
                        for jj=1:n
                            f=app.Data.FRA(fraIdx(jj));
                            [voc,isc]=app.referenceDCMetricsForFRA(f);
                            RunID(jj)=f.RunID;
                            NominalOP(jj)=app.fraOperatingPointLabel(f);
                            Mode(jj)=upper(string(f.FileInfo.Mode));
                            TargetV(jj)=app.analysisTargetV(f);
                            ActualV(jj)=f.ActualV;
                            DeltaV(jj)=f.ActualV-TargetV(jj);
                            if isfinite(voc) && voc~=0 && isfinite(f.ActualV)
                                VoverVoc(jj)=f.ActualV/voc;
                            end
                            TargetI(jj)=f.TargetI;
                            ActualI(jj)=f.ActualI;
                            if isfinite(isc) && isc~=0 && isfinite(f.ActualI)
                                AbsIoverIscPct(jj)=100*abs(f.ActualI)/abs(isc);
                            end
                            ClosestTargetRegion(jj)=app.closestOperatingPointLabel(f.ActualV,og);
                            KKMean(jj)=f.KKMeanAbs;
                            Rs(jj)=f.Params.Rs;
                            Rp_Rct(jj)=f.Params.Rp;
                            CPE_Y0(jj)=f.Params.Y0;
                            CPE_n(jj)=f.Params.n;
                            PairComparison(jj)=app.operatingPointPairStatus(app.fraOperatingPointLabel(f),og);
                        end
                        LabDay=repmat(app.selectedLabDay(),n,1);
                        writetable(table(LabDay,RunID,NominalOP,Mode,TargetV,ActualV,DeltaV,VoverVoc, ...
                            TargetI,ActualI,AbsIoverIscPct,ClosestTargetRegion,KKMean,Rs,Rp_Rct,CPE_Y0,CPE_n,PairComparison), ...
                            out,'Sheet','Operating Point Comparison');
                    end
                catch
                    % Supplemental operating-point export should not block
                    % the main analysis summary.
                end

                % Current Frequency Range view summary.
                try
                    fraIdx = app.filteredFRAIndices();
                    mode = upper(string(app.FrequencyModeDropDown.Value));
                    idx = fraIdx(arrayfun(@(i)strcmpi(app.Data.FRA(i).FileInfo.Mode,mode),fraIdx));
                    fg = app.buildFrequencyGroups(idx);
                    if ~isempty(fg)
                        n=numel(fg);
                        Range=strings(n,1); Amplitude=strings(n,1); Reference=false(n,1);
                        Repeats=nan(n,1); PointsPerDecade=Repeats; MeanPoints=Repeats;
                        KKMean=Repeats; KKStd=Repeats; RepeatZDiffPct=Repeats;
                        RsMean=Repeats; RsCV=Repeats; RpMean=Repeats; RpCV=Repeats;
                        Y0Mean=Repeats; Y0CV=Repeats; CPE_n_Mean=Repeats; CPE_n_SD=Repeats;
                        SpectrumRefDiffPct=Repeats; ParamRefDiffPct=Repeats;
                        for k=1:n
                            g0=fg(k); Range(k)=g0.Label; Repeats(k)=g0.N;
                            Amplitude(k)=app.formatAmplitude(g0.Amplitude,g0.ACUnit);
                            PointsPerDecade(k)=g0.PointsPerDecade; MeanPoints(k)=g0.PointCountMean;
                            KKMean(k)=g0.KKMean; KKStd(k)=g0.KKStd; RepeatZDiffPct(k)=g0.RepeatabilityPct;
                            RsMean(k)=g0.RsMean; RsCV(k)=g0.RsCV; RpMean(k)=g0.RpMean; RpCV(k)=g0.RpCV;
                            Y0Mean(k)=g0.Y0Mean; Y0CV(k)=g0.Y0CV; CPE_n_Mean(k)=g0.NMean; CPE_n_SD(k)=g0.NStd;
                            SpectrumRefDiffPct(k)=g0.SpectrumRefDiffPct; ParamRefDiffPct(k)=g0.ParamRefDiffPct;
                            Reference(k)=g0.IsReference;
                        end
                        LabDay=repmat(app.selectedLabDay(),n,1); Mode=repmat(mode,n,1);
                        writetable(table(LabDay,Mode,Range,Repeats,Amplitude,PointsPerDecade,MeanPoints, ...
                            KKMean,KKStd,RepeatZDiffPct,RsMean,RsCV,RpMean,RpCV,Y0Mean,Y0CV, ...
                            CPE_n_Mean,CPE_n_SD,SpectrumRefDiffPct,ParamRefDiffPct,Reference), ...
                            out,'Sheet','Frequency Comparison');
                    end
                catch
                    % Frequency comparison export is supplemental; do not
                    % block the rest of the analysis summary if unavailable.
                end

                writecell([{'Automatic review notes'}; cellstr(app.Data.Warnings)],out,'Sheet','Review','Range','A1');
                app.StatusLabel.Text = 'Summary exported';
                uialert(app.UIFigure,'Analysis summary exported successfully.','Export complete','Icon','success');
            catch ME
                uialert(app.UIFigure,ME.message,'Export error','Icon','error');
            end
        end

        % ---------- Small helpers ----------
        function name = findHeader(app,names,candidates) %#ok<INUSL>
            names = string(names); candidates = string(candidates); name = "";
            for c = candidates
                idx = find(strcmpi(strtrim(names),strtrim(c)),1,'first');
                if ~isempty(idx), name=names(idx); return; end
            end
        end

        function name = findContainsHeader(app,names,needle) %#ok<INUSL>
            names=string(names); needle=string(needle); name="";
            idx=find(contains(lower(names),lower(needle)),1,'first');
            if ~isempty(idx), name=names(idx); end
        end

        function x = numericColumn(app,v) %#ok<INUSL>
            if isnumeric(v)
                x = double(v);
            elseif iscell(v)
                x = nan(size(v));
                for k=1:numel(v)
                    if isnumeric(v{k}) && isscalar(v{k}), x(k)=double(v{k});
                    else, x(k)=str2double(string(v{k})); end
                end
            else
                x = str2double(string(v));
            end
            x = x(:);
        end

        function x = firstFinite(app,v)
            a=app.numericColumn(v); a=a(isfinite(a));
            if isempty(a), x=NaN; else, x=a(1); end
        end

        function value = masterNumeric(app,row,header)
            value = NaN;
            if isempty(row), return; end
            names=string(row.Properties.VariableNames); name=app.findHeader(names,string(header));
            if strlength(name)==0, return; end
            a=app.numericColumn(row.(name)); if ~isempty(a) && isfinite(a(1)), value=a(1); end
        end

        function value = masterText(app,row,header)
            value = "";
            if isempty(row), return; end
            names=string(row.Properties.VariableNames); name=app.findHeader(names,string(header));
            if strlength(name)==0, return; end
            v=row.(name);
            try
                value=string(v(1));
                if ismissing(value), value=""; end
            catch
                value="";
            end
        end

        function s = masterDateString(app,v) %#ok<INUSL>
            s = "";
            try
                % Unwrap scalar cell values produced by mixed-type Excel columns.
                while iscell(v) && numel(v)==1
                    v = v{1};
                end
                if isempty(v), return; end

                if isdatetime(v)
                    if ~isnat(v)
                        s = string(v,'yyyyMMdd');
                    end
                    return;
                end

                if isnumeric(v)
                    if ~isscalar(v) || ~isfinite(v), return; end
                    % Sometimes an already-normalized YYYYMMDD value arrives numeric.
                    if v >= 19000101 && v <= 29991231 && abs(v-round(v)) < eps(max(1,abs(v)))
                        s = compose('%.0f',v);
                    else
                        d = datetime(v,'ConvertFrom','excel');
                        s = string(d,'yyyyMMdd');
                    end
                    return;
                end

                txt = strtrim(string(v));
                if ismissing(txt) || strlength(txt)==0, return; end

                if ~isempty(regexp(char(txt),'^\d{8}$','once'))
                    s = txt;
                    return;
                elseif ~isempty(regexp(char(txt),'^\d{6}$','once'))
                    s = "20" + txt;
                    return;
                end

                fmts = ["yyyy-MM-dd","dd-MM-yyyy","MM/dd/yyyy","dd/MM/yyyy", ...
                    "yyyy/MM/dd","dd-MMM-yyyy","dd-MMM-uuuu","MMM dd, yyyy"];
                for f = fmts
                    try
                        d = datetime(txt,'InputFormat',f);
                        if ~isnat(d)
                            s = string(d,'yyyyMMdd');
                            return;
                        end
                    catch
                    end
                end

                % Final permissive attempt for locale-dependent Excel strings.
                try
                    d = datetime(txt);
                    if ~isnat(d), s = string(d,'yyyyMMdd'); end
                catch
                end
            catch
                s = "";
            end
        end

        function v = tableValue(app,T,name,row) %#ok<INUSL>
            try
                v = T.(name)(row);
            catch
                v = [];
            end
        end

        function t = sortableTimeColumn(app,v) %#ok<INUSL>
            n = numel(v);
            t = nan(n,1);
            for ii = 1:n
                try
                    x = v(ii);
                    if iscell(x), x = x{1}; end
                    if isduration(x)
                        t(ii) = seconds(x);
                    elseif isdatetime(x)
                        t(ii) = hour(x)*3600 + minute(x)*60 + second(x);
                    elseif isnumeric(x)
                        t(ii) = double(x);
                    else
                        txt = string(x);
                        try
                            d = duration(txt,'InputFormat','hh:mm:ss');
                            t(ii) = seconds(d);
                        catch
                            try
                                d = duration(txt,'InputFormat','hh:mm');
                                t(ii) = seconds(d);
                            catch
                            end
                        end
                    end
                catch
                end
            end
            t(~isfinite(t)) = inf;
        end

        function x = tableNumericByHeader(app,T,header,row)
            x=NaN; names=string(T.Properties.VariableNames); n=app.findHeader(names,string(header));
            if strlength(n)==0, return; end
            a=app.numericColumn(T.(n)(row)); if ~isempty(a)&&isfinite(a(1)),x=a(1);end
        end

        function s = tableTextByHeader(app,T,header,row)
            s=""; names=string(T.Properties.VariableNames); n=app.findHeader(names,string(header));
            if strlength(n)==0, return; end
            s=app.tableTextAt(T,n,row);
        end

        function s = tableTextAt(app,T,name,row) %#ok<INUSL>
            try
                v=T.(name)(row); s=string(v); if ismissing(s),s="";end
            catch
                s="";
            end
        end

        function s = fileNameOnly(app,path) %#ok<INUSL>
            [~,n,e]=fileparts(char(path)); s=string([n e]);
        end

        function setUITableData(app,tbl,C,tableName)
            % setUITableData - Release-tolerant uitable assignment.
            % Older MATLAB releases reject string/datetime/categorical
            % objects inside cell-array Data. Convert every displayed item
            % to a plain char vector, validate it, then assign. If the cell
            % representation is still rejected, try a table fallback.
            C = app.uiCell(C);

            bad = false(size(C));
            for ii = 1:numel(C)
                bad(ii) = ~(ischar(C{ii}) || isnumeric(C{ii}) || islogical(C{ii}));
            end
            if any(bad(:))
                idx = find(bad,1,'first');
                error('PVLabAnalyzer:UnsupportedUITableValue', ...
                    '%s contains an unsupported display value of class %s.', ...
                    tableName,class(C{idx}));
            end

            try
                tbl.Data = C;
            catch firstME
                % Fallback for releases that behave better with table Data.
                try
                    T = cell2table(C);
                    tbl.Data = T;
                catch
                    error('PVLabAnalyzer:UITableAssignmentFailed', ...
                        '%s could not be populated. MATLAB reported: %s', ...
                        tableName, firstME.message);
                end
            end
        end

        function C = uiCell(app,C) %#ok<INUSL>
            % Build maximally compatible uitable cell data. Some MATLAB
            % releases reject string, categorical, datetime, missing, or
            % other modern scalar types inside a cell-array Data property.
            % For display tables we therefore convert EVERY cell to a plain
            % character row vector. This is intentionally conservative.
            for ii = 1:numel(C)
                v = C{ii};
                try
                    if isempty(v)
                        C{ii} = '';
                    elseif ischar(v)
                        if size(v,1) <= 1
                            C{ii} = v;
                        else
                            C{ii} = strjoin(cellstr(v),' ');
                        end
                    elseif isnumeric(v)
                        if isscalar(v)
                            if isnan(double(v))
                                C{ii} = '';
                            else
                                C{ii} = sprintf('%.10g',double(v));
                            end
                        else
                            C{ii} = mat2str(v);
                        end
                    elseif islogical(v)
                        if isscalar(v)
                            if v, C{ii} = 'true'; else, C{ii} = 'false'; end
                        else
                            C{ii} = mat2str(v);
                        end
                    elseif iscell(v)
                        try
                            sv = string(v);
                            sv(ismissing(sv)) = "";
                            C{ii} = char(strjoin(sv(:).', ', '));
                        catch
                            C{ii} = '';
                        end
                    else
                        sv = string(v);
                        if isempty(sv) || all(ismissing(sv))
                            C{ii} = '';
                        else
                            sv(ismissing(sv)) = "";
                            C{ii} = char(strjoin(sv(:).', ', '));
                        end
                    end
                catch
                    C{ii} = '';
                end

                % Final guard: Data cells must be plain char for widest
                % compatibility.
                if ~ischar(C{ii})
                    try
                        C{ii} = char(string(C{ii}));
                    catch
                        C{ii} = '';
                    end
                end
                if size(C{ii},1) > 1
                    C{ii} = strjoin(cellstr(C{ii}),' ');
                end
                if isempty(C{ii}), C{ii} = ''; end
                C{ii} = reshape(C{ii},1,[]);
            end
        end

        function s = fmt(app,x,n) %#ok<INUSL>
            if ~isfinite(x), s="—"; else, s=string(sprintf(['%.' num2str(n) 'g'],x)); end
        end

        function s = fmtSci(app,x,n) %#ok<INUSL>
            if ~isfinite(x), s="—"; else, s=string(sprintf(['%.' num2str(n) 'e'],x)); end
        end

        function s = envCompact(app,e)
            if isempty(e), s="—"; return; end
            s = e.ID + " | Tavg " + app.fmt(e.TempAvg,4) + " °C | Gavg " + app.fmt(e.IrrAvg,4) + " W/m²";
        end
    end
end
