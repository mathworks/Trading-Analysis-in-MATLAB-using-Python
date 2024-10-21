classdef Algo_Trading < matlab.task.LiveTask
    properties(Access = private, Transient)
        EditFieldLabel matlab.ui.control.Label
        EditField matlab.ui.control.NumericEditField
        EditFieldLabel1 matlab.ui.control.Label
        EditField1 matlab.ui.control.NumericEditField
        EditFieldLabel2 matlab.ui.control.Label
        EditField2 matlab.ui.control.NumericEditField
        DropDownLabel matlab.ui.control.Label
        DropDown matlab.ui.control.DropDown
    end
    
    properties(Dependent)
        State
        Summary
    end
    
    methods(Access = protected)
        function setup(task)
            createComponents(task);
        end
    end
    
    methods
        function createComponents(task)
            grid = uigridlayout(task.LayoutManager);
            grid.RowHeight = repmat({'fit'}, 1, 4);
            grid.ColumnWidth = repmat({'fit'}, 1, 2);
            
            % Create EditFieldLabel
            task.EditFieldLabel = uilabel(grid, 'Text', 'Initial Price ($)');
            task.EditFieldLabel.Layout.Row = 1;
            task.EditFieldLabel.Layout.Column = 1;
            
            % Create EditField
            task.EditField = uieditfield(grid, 'numeric');
            task.EditField.Value = 144;
            task.EditField.UserData.sourceLiveControlData.valueType = 'double';
            task.EditField.Layout.Row = 1;
            task.EditField.Layout.Column = 2;
            
            % Create EditFieldLabel1
            task.EditFieldLabel1 = uilabel(grid, 'Text', 'Volatility');
            task.EditFieldLabel1.Layout.Row = 2;
            task.EditFieldLabel1.Layout.Column = 1;
            
            % Create EditField1
            task.EditField1 = uieditfield(grid, 'numeric');
            task.EditField1.Value = 0.05;
            task.EditField1.UserData.sourceLiveControlData.valueType = 'double';
            task.EditField1.Layout.Row = 2;
            task.EditField1.Layout.Column = 2;
            
            % Create EditFieldLabel2
            task.EditFieldLabel2 = uilabel(grid, 'Text', 'Drift');
            task.EditFieldLabel2.Layout.Row = 3;
            task.EditFieldLabel2.Layout.Column = 1;
            
            % Create EditField2
            task.EditField2 = uieditfield(grid, 'numeric');
            task.EditField2.Value = 0.0005;
            task.EditField2.UserData.sourceLiveControlData.valueType = 'double';
            task.EditField2.Layout.Row = 3;
            task.EditField2.Layout.Column = 2;
            
            % Create DropDownLabel
            task.DropDownLabel = uilabel(grid, 'Text', 'Strategy');
            task.DropDownLabel.Layout.Row = 4;
            task.DropDownLabel.Layout.Column = 1;
            
            % Create DropDown
            task.DropDown = uidropdown(grid);
            task.DropDown.Items = {'Momentum' 'Mean Reversion' 'SMA'};
            task.DropDown.ItemsData = {'Momentum' 'Mean Reversion' 'SMA'};
            task.DropDown.Value = 'SMA';
            task.DropDown.Layout.Row = 4;
            task.DropDown.Layout.Column = 2;
        end
        
        function [code,outputs] = generateCode(task)
            outputs = {};
            codeTemplate = ["% Parameters"
                "numDays = 252;"
                "InitialPrice = " + task.extractValue(task.EditField) + ";"
                "Volatility = " + task.extractValue(task.EditField1) + ";"
                "Drift = " + task.extractValue(task.EditField2) + ";"
                "OpenVolatility = 0.01;"
                ""
                "% Generate dates excluding weekends"
                "startDate = datetime(2023,1,1);"
                "endDate = startDate + caldays(365);"
                "allDates = startDate:endDate;"
                "tradingDates = allDates(~(weekday(allDates) == 1 | weekday(allDates) == 7));"
                "tradingDates = tradingDates(1:numDays);"
                ""
                "rng(""default"");"
                "openPrices = zeros(numDays, 1);"
                "closePrices = zeros(numDays, 1);"
                "openPrices(1) = InitialPrice;"
                "closePrices(1) = InitialPrice * (1 + Drift + Volatility * randn());"
                ""
                "for t = 2:numDays"
                "    openPrices(t) = closePrices(t-1) * (1 + OpenVolatility * randn());"
                "    closePrices(t) = openPrices(t) * (1 + Drift + Volatility * randn());"
                "end"
                ""
                "stockData = table(tradingDates', openPrices, closePrices, ..."
                "                  'VariableNames', {'Date', 'Open', 'Close'});"
                ""
                "dis_pd = py.pandas.DataFrame(stockData);"
                "%Trading Strategy selection"
                "TradingStrategy = " + task.extractValue(task.DropDown) + ";"
                "if contains('Momentum',TradingStrategy)"
                "    PnL_dis = py.trading_fnx.momentum(dis_pd);"
                "elseif contains('Mean Reversion',TradingStrategy)"
                "    PnL_dis = py.trading_fnx.mean_rev(dis_pd);"
                "else"
                "    PnL_dis = py.trading_fnx.sma(dis_pd);"
                "end"
                "PnL_distable = table(PnL_dis);"
                "plot(PnL_distable.Date,table2array(PnL_distable(:,4))); grid on; xlabel('Date'); ylabel('PnL ($)'); title(strcat(""PnL - "",TradingStrategy,' Trading'));"
                "disp(strcat('Max PnL ($): ',string(max(table2array(PnL_distable(:,4))))))"
                "disp(strcat('Min PnL ($): ',string(min(table2array(PnL_distable(:,4))))))"
                "disp(strcat('Average PnL ($): ',string(mean(table2array(PnL_distable(:,4))))))"
                "disp(strcat('Cumulative PnL ($): ',string(sum(table2array(PnL_distable(:,4))))))"
                "disp(strcat('Sharpe Ratio: ',string(sqrt(252)*mean(table2array(PnL_distable(:,4)))/std(table2array(PnL_distable(:,4))))))"
                "disp(strcat('Average Trade ($): ',string(sum(table2array(PnL_distable(:,4)))/sum(table2array(PnL_distable(:,5))))))"
                "clear Drift InitialPrice OpenVolatility PnL_dis PnL_distable TradingStrategy Volatility allDates closePrices dis_pd endDate numDays openPrices startDate stockData t tradingDates;"];
            code = join(string(codeTemplate), newline);
        end
        
        function summary = get.Summary(~)
            summary = "";
        end
        
        function state = get.State(task)
            state = struct;
            state.EditField = task.EditField.Value;
            state.EditField1 = task.EditField1.Value;
            state.EditField2 = task.EditField2.Value;
            state.DropDown = task.DropDown.Value;
        end
        
        function set.State(task, state)
            task.EditField.Value = state.EditField;
            task.EditField1.Value = state.EditField1;
            task.EditField2.Value = state.EditField2;
            task.DropDown.Value = state.DropDown;
        end
        
        function reset(task)
            task.EditField.Value = 100;
            task.EditField1.Value = 0.05;
            task.EditField2.Value = 0.0005;
            task.DropDown.Value = 'SMA';
        end
    end
    
    
    
    methods(Access = private)
        function out = extractValue(~, widget)
            value = widget.Value;
            type = class(value);
            
            if isfield(widget.UserData, 'sourceLiveControlData')
                type = widget.UserData.sourceLiveControlData.valueType;
            end
            
            switch (type)
                case "string"
                    out = append('"', replace(value, '"', '""'), '"');
                case "double"
                    out = string(value);
                case "char"
                    out = append("'", replace(value, "'", "''"), "'");
                otherwise
                    out = value;
            end
        end
    end
end