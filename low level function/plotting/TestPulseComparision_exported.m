classdef TestPulseComparision_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MortgageCalculatorUIFigure    matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        StartReferenceEditFieldLabel  matlab.ui.control.Label
        StartReferenceEditField       matlab.ui.control.NumericEditField
        EndReferenceEditFieldLabel    matlab.ui.control.Label
        EndReferenceEditField         matlab.ui.control.NumericEditField
        StartTargetEditFieldLabel     matlab.ui.control.Label
        EndTargetEditFieldLabel       matlab.ui.control.Label
        StartTargetEditField          matlab.ui.control.NumericEditField
        EndTargetEditField            matlab.ui.control.NumericEditField
        RightPanel                    matlab.ui.container.Panel
        PrincipalInterestUIAxes       matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        TP % Description
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
           
           app.TP =load('temp.mat', "temp");
           
            app.StartReferenceEditField.Limits = ...
                [1 size(app.TP.temp,1)];
            
            app.EndReferenceEditField.Limits = ...
                [2 size(app.TP.temp,1)];
            
            app.StartTargetEditField.Limits =  ...        
            [2 size(app.TP.temp,1)];
            
            app.EndTargetEditField.Limits = ...
                [2 size(app.TP.temp,1)];
      
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.MortgageCalculatorUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {316, 316};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {222, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Value changed function: StartTargetEditField
        function StartTargetEditFieldValueChanged(app, event)
            value = app.StartTargetEditField.Value;
            plot(app.PrincipalInterestUIAxes, ...
                (1:size(app.TP ,2)),...
                mean(app.TP(app.StartReferenceEditField.Value...
                :app.EndReferenceEditField.Value,:)), ...
                (1:size(app.TP ,2)),...
                mean(app.TP (value:app.EndTargetEditField.Value,:)));
      
            legend(app.PrincipalInterestUIAxes,{'Reference','Target'},...
                'Location','Best')            
            
        end

        % Value changed function: EndTargetEditField
        function EndTargetEditFieldValueChanged(app, event)
            value = app.EndTargetEditField.Value;
            plot(app.PrincipalInterestUIAxes, ...
                (1:size(app.TP ,2)),...
                mean(app.TP(app.StartReferenceEditField.Value...
                :app.EndReferenceEditField.Value,:)), ...
                (1:size(app.TP ,2)),...
                mean(app.TP (app.StartTargetEditField.Value:value,:)));
            legend(app.PrincipalInterestUIAxes,{'Reference','Target'},...
                'Location','Best')   
        end

        % Value changed function: EndReferenceEditField
        function EndReferenceEditFieldValueChanged(app, event)
            value = app.EndReferenceEditField.Value;
            plot(app.PrincipalInterestUIAxes, ...
                (1:size(app.TP ,2)),...
                mean(app.TP(app.StartReferenceEditField.Value...
                           :value,:)), ...
                (1:size(app.TP ,2)),...
                mean(app.TP (app.StartTargetEditField.Value:...
                          app.EndTargetEditField.Value,:)));
            legend(app.PrincipalInterestUIAxes,{'Reference','Target'},...
                'Location','Best')  
        end

        % Value changed function: StartReferenceEditField
        function StartReferenceEditFieldValueChanged(app, event)
            value = app.StartReferenceEditField.Value;
             plot(app.PrincipalInterestUIAxes,...
                 (1:size(app.TP ,2)),...
                mean(app.TP(value:app.EndReferenceEditField.Value)), ...
                (1:size(app.TP ,2)),...
                mean(app.TP (app.StartTargetEditField.Value:...
                          app.EndTargetEditField.Value,:)));
            legend(app.PrincipalInterestUIAxes,{'Reference','Target'},...
                'Location','Best')   
            
            
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create GridLayout
            app.GridLayout = uigridlayout(app.MortgageCalculatorUIFigure);
            app.GridLayout.ColumnWidth = {222, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.Scrollable = 'on';

            % Create StartReferenceEditFieldLabel
            app.StartReferenceEditFieldLabel = uilabel(app.LeftPanel);
            app.StartReferenceEditFieldLabel.HorizontalAlignment = 'right';
            app.StartReferenceEditFieldLabel.Position = [6 230 90 22];
            app.StartReferenceEditFieldLabel.Text = 'Start Reference';

            % Create StartReferenceEditField
            app.StartReferenceEditField = uieditfield(app.LeftPanel, 'numeric');
            app.StartReferenceEditField.Limits = [0 300];
            app.StartReferenceEditField.ValueDisplayFormat = '%8.f';
            app.StartReferenceEditField.ValueChangedFcn = createCallbackFcn(app, @StartReferenceEditFieldValueChanged, true);
            app.StartReferenceEditField.Position = [111 230 100 22];
            app.StartReferenceEditField.Value = 1;

            % Create EndReferenceEditFieldLabel
            app.EndReferenceEditFieldLabel = uilabel(app.LeftPanel);
            app.EndReferenceEditFieldLabel.HorizontalAlignment = 'right';
            app.EndReferenceEditFieldLabel.Position = [8 197 88 22];
            app.EndReferenceEditFieldLabel.Text = 'End Reference';

            % Create EndReferenceEditField
            app.EndReferenceEditField = uieditfield(app.LeftPanel, 'numeric');
            app.EndReferenceEditField.Limits = [1 300];
            app.EndReferenceEditField.ValueChangedFcn = createCallbackFcn(app, @EndReferenceEditFieldValueChanged, true);
            app.EndReferenceEditField.Position = [111 197 100 22];
            app.EndReferenceEditField.Value = 5;

            % Create StartTargetEditFieldLabel
            app.StartTargetEditFieldLabel = uilabel(app.LeftPanel);
            app.StartTargetEditFieldLabel.HorizontalAlignment = 'right';
            app.StartTargetEditFieldLabel.Position = [27 112 67 22];
            app.StartTargetEditFieldLabel.Text = 'Start Target';

            % Create EndTargetEditFieldLabel
            app.EndTargetEditFieldLabel = uilabel(app.LeftPanel);
            app.EndTargetEditFieldLabel.HorizontalAlignment = 'right';
            app.EndTargetEditFieldLabel.Position = [6 79 88 22];
            app.EndTargetEditFieldLabel.Text = 'End Target';

            % Create StartTargetEditField
            app.StartTargetEditField = uieditfield(app.LeftPanel, 'numeric');
            app.StartTargetEditField.Limits = [0 300];
            app.StartTargetEditField.ValueDisplayFormat = '%8.f';
            app.StartTargetEditField.ValueChangedFcn = createCallbackFcn(app, @StartTargetEditFieldValueChanged, true);
            app.StartTargetEditField.Position = [109 112 100 22];
            app.StartTargetEditField.Value = 6;

            % Create EndTargetEditField
            app.EndTargetEditField = uieditfield(app.LeftPanel, 'numeric');
            app.EndTargetEditField.Limits = [6 300];
            app.EndTargetEditField.ValueChangedFcn = createCallbackFcn(app, @EndTargetEditFieldValueChanged, true);
            app.EndTargetEditField.Position = [109 79 100 22];
            app.EndTargetEditField.Value = 20;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.Scrollable = 'on';

            % Create PrincipalInterestUIAxes
            app.PrincipalInterestUIAxes = uiaxes(app.RightPanel);
            title(app.PrincipalInterestUIAxes, 'Visual Test Pulse Comparision')
            xlabel(app.PrincipalInterestUIAxes, 'Samples')
            ylabel(app.PrincipalInterestUIAxes, 'Voltage')
            app.PrincipalInterestUIAxes.XTick = [];
            app.PrincipalInterestUIAxes.YTick = [];
            app.PrincipalInterestUIAxes.YTickLabel = '';
            app.PrincipalInterestUIAxes.Position = [1 8 424 300];

            % Show the figure after all components are created
            app.MortgageCalculatorUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TestPulseComparision_exported

            % Create UIFigure and components
            createComponents(app)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MortgageCalculatorUIFigure)
        end
    end
end