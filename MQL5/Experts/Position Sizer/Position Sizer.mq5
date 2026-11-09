//+------------------------------------------------------------------+
//|                                               Position Sizer.mq5 |
//|                                  Copyright © 2026, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-expert-advisors/Position-Sizer/"
#property icon      "EF-Icon-64x64px.ico"
#define VERSION "3.16b"
#property version VERSION

#include "Translations\English.mqh"
//#include "Translations\Arabic.mqh"
//#include "Translations\Chinese.mqh"
//#include "Translations\ChineseTraditional.mqh" // Contributed by fxchess.
//#include "Translations\Japanese.mqh" // Contributed by Satoru Hoshino.
//#include "Translations\Portuguese.mqh" // Contributed by Matheus Sevaroli.
//#include "Translations\Russian.mqh"
//#include "Translations\Spanish.mqh"
//#include "Translations\Ukrainian.mqh"

#property description DESCRIPTION_LINE_1
#property description DESCRIPTION_LINE_2
#property description DESCRIPTION_LINE_3
#property description DESCRIPTION_LINE_4

#include "Position Sizer.mqh"
#include "Position Sizer Trading.mqh"
#include "TesterSupport.mqh"

// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;
string PanelCaption = "";
string PanelCaptionBase = "";

// Custom variables:
double CustomTPMultiplier = 2;
string CustomTradeSignal = "NONE";
datetime CustomCurrentBarIndex = 0;
input double CustomEquityGoal = 0; // Close all trades when equity reaches this (0 = disabled)
input int CustomSafeTicks = 10; // Ticks to add to the safe SL
input bool CustomWebFetchingEnabled = false; // Enable web command fetching?
input string CustomWebCommandDomain = "https://www.example.org"; // URL to the web command domain (no slash)
input bool CustomOCOEnabled = true; // Cancel opposite pending orders when one side gets filled (OCO)
input int CustomCBSwing = 3; // Continuation breakout: swing candles on each side (1-5)
input int CustomCBSessionStartHour = 8; // Continuation breakout: London session start (London time)
input int CustomCBSessionEndHour = 17; // Continuation breakout: London session end (London time)
input int CustomCBServerGMTWinter = 2; // Continuation breakout: broker server GMT offset in winter
input bool CustomCBServerUSDST = true; // Continuation breakout: broker shifts +1h on US DST dates
bool CustomWebRequestInProgress = false;
bool CBEnabled = false;
double CBSLDistance = 0;
double CBRRR = 0;
double CBLots = 0;
double CBLevelHigh = 0;
double CBLevelLow = 0;
bool CBHighTaken = true;
bool CBLowTaken = true;
datetime CBLastLevelBar = 0;
datetime CBBuyFailBar = 0;
datetime CBSellFailBar = 0;
long CBSessionMinute = -1;
bool CBInSession = false;
CTrade CBTrade;

input group INPUT_GROUP_DESCRIPTION_COMPACTNESS
input(name=INPUT_DESCRIPTION_ShowMainLineLabels) bool ShowMainLineLabels = true; // ShowMainLineLabels: Show point distance for TP/SL near lines?
input(name=INPUT_DESCRIPTION_ShowAdditionalSLLabel) bool ShowAdditionalSLLabel = false; // ShowAdditionalSLLabel: Show SL $/% label?
input(name=INPUT_DESCRIPTION_ShowAdditionalTPLabel) bool ShowAdditionalTPLabel = false; // ShowAdditionalTPLabel: Show TP $/% + R/R label?
input(name=INPUT_DESCRIPTION_ShowAdditionalEntryLabel) bool ShowAdditionalEntryLabel = false; // ShowAdditionalEntryLabel: Show Position Size label?
input(name=INPUT_DESCRIPTION_DrawTextAsBackground) bool DrawTextAsBackground = false; // DrawTextAsBackground: Draw label objects as background?
input(name=INPUT_DESCRIPTION_HideAccSize) bool HideAccSize = false; // HideAccSize: Hide account size?
input(name=INPUT_DESCRIPTION_HideMoneyAndPointsValues) bool HideMoneyAndPointsValues = false; // HideMoneyAndPointsValues: Hide money and points values?
input(name=INPUT_DESCRIPTION_ShowPointValue) bool ShowPointValue = false; // ShowPointValue: Show point value?
input(name=INPUT_DESCRIPTION_ShowMaxPSButton) bool ShowMaxPSButton = false; // ShowMaxPSButton: Show Max Position Size button?
input(name=INPUT_DESCRIPTION_StartPanelMinimized) bool StartPanelMinimized = false; // StartPanelMinimized: Start the panel minimized?
input(name=INPUT_DESCRIPTION_ShowATROptions) bool ShowATROptions = false; // ShowATROptions: If true, SL and TP can be set via ATR.
input(name=INPUT_DESCRIPTION_ShowMaxParametersOnTrading) bool ShowMaxParametersOnTrading = true; // Show max parameters on Trading tab?
input(name=INPUT_DESCRIPTION_ShowFusesOnTrading) bool ShowFusesOnTrading = true; // Show trading "fuses" on Trading tab?
input(name=INPUT_DESCRIPTION_ShowCheckboxesOnTrading) bool ShowCheckboxesOnTrading = true; // Show checkboxes on Trading tab?
input(name=INPUT_DESCRIPTION_HideEntryLineOnInstant) bool HideEntryLineOnInstant = false; // Hide Entry line for Instant orders?
input(name=INPUT_DESCRIPTION_ShowAdditionalMarginSettings) bool ShowAdditionalMarginSettings = false; // Show additional margin settings/info?
input(name=INPUT_DESCRIPTION_AdditionalTradeButtons) ADDITIONAL_TRADE_BUTTONS AdditionalTradeButtons = ADDITIONAL_TRADE_BUTTONS_NONE; // Additional Trade buttons:
input group INPUT_GROUP_DESCRIPTION_FONTS
input(name=INPUT_DESCRIPTION_sl_label_font_color) color sl_label_font_color = clrGreen; // SL Label Color
input(name=INPUT_DESCRIPTION_tp_label_font_color) color tp_label_font_color = clrGoldenrod; // TP Label Color
input(name=INPUT_DESCRIPTION_sp_label_font_color) color sp_label_font_color = clrPurple; // Stop Price Label Color
input(name=INPUT_DESCRIPTION_entry_label_font_color) color entry_label_font_color = clrBlue; // Entry Label Font Color
input(name=INPUT_DESCRIPTION_font_size) uint font_size = 13; // Labels Font Size
input(name=INPUT_DESCRIPTION_font_face) string font_face = "Courier"; // Labels Font Face
input group INPUT_GROUP_DESCRIPTION_LINES
input(name=INPUT_DESCRIPTION_entry_line_color) color entry_line_color = clrBlue; // Entry Line Color
input(name=INPUT_DESCRIPTION_stoploss_line_color) color stoploss_line_color = clrGreen; // Stop-Loss Line Color
input(name=INPUT_DESCRIPTION_takeprofit_line_color) color takeprofit_line_color = clrGoldenrod; // Take-Profit Line Color
input(name=INPUT_DESCRIPTION_stopprice_line_color) color stopprice_line_color = clrPurple; // Stop Price Line Color
input(name=INPUT_DESCRIPTION_be_line_color) color be_line_color = clrNONE; // BE Line Color
input(name=INPUT_DESCRIPTION_entry_line_style) ENUM_LINE_STYLE entry_line_style = STYLE_SOLID; // Entry Line Style
input(name=INPUT_DESCRIPTION_stoploss_line_style) ENUM_LINE_STYLE stoploss_line_style = STYLE_SOLID; // Stop-Loss Line Style
input(name=INPUT_DESCRIPTION_takeprofit_line_style) ENUM_LINE_STYLE takeprofit_line_style = STYLE_SOLID; // Take-Profit Line Style
input(name=INPUT_DESCRIPTION_stopprice_line_style) ENUM_LINE_STYLE stopprice_line_style = STYLE_DOT; // Stop Price Line Style
input(name=INPUT_DESCRIPTION_be_line_style) ENUM_LINE_STYLE be_line_style = STYLE_DOT; // BE Line Style
input(name=INPUT_DESCRIPTION_entry_line_width) uint entry_line_width = 1; // Entry Line Width
input(name=INPUT_DESCRIPTION_stoploss_line_width) uint stoploss_line_width = 1; // Stop-Loss Line Width
input(name=INPUT_DESCRIPTION_takeprofit_line_width) uint takeprofit_line_width = 1; // Take-Profit Line Width
input(name=INPUT_DESCRIPTION_stopprice_line_width) uint stopprice_line_width = 1; // Stop Price Line Width
input(name=INPUT_DESCRIPTION_be_line_width) uint be_line_width = 1; // BE Line Width
input group INPUT_GROUP_DESCRIPTION_DEFAULTS
input(name=INPUT_DESCRIPTION_DefaultTradeDirection) TRADE_DIRECTION DefaultTradeDirection = Long; // TradeDirection: Default trade direction.
input(name=INPUT_DESCRIPTION_DefaultSL) int DefaultSL = 0; // SL: Default stop-loss value, in points.
input(name=INPUT_DESCRIPTION_DefaultTP) int DefaultTP = 0; // TP: Default take-profit value, in points.
input(name=INPUT_DESCRIPTION_DefaultStopLimitDistance) int DefaultStopLimitDistance = 0; // Default stop-limit price distance, in points.
input(name=INPUT_DESCRIPTION_DefaultTakeProfitsNumber) int DefaultTakeProfitsNumber = 1; // TakeProfitsNumber: More than 1 target to split trades.
input(name=INPUT_DESCRIPTION_DefaultEntryType) ENTRY_TYPE DefaultEntryType = Instant; // EntryType: Instant, Pending, or StopLimit.
input(name=INPUT_DESCRIPTION_DefaultShowLines) bool DefaultShowLines = true; // ShowLines: Show the lines by default?
input(name=INPUT_DESCRIPTION_DefaultLinesSelected) bool DefaultLinesSelected = true; // LinesSelected: SL/TP (Entry in Pending) lines selected.
input(name=INPUT_DESCRIPTION_DefaultATRPeriod) int DefaultATRPeriod = 14; // ATRPeriod: Default ATR period.
input(name=INPUT_DESCRIPTION_DefaultATRMultiplierSL) double DefaultATRMultiplierSL = 0; // ATRMultiplierSL: Default ATR multiplier for SL.
input(name=INPUT_DESCRIPTION_DefaultATRMultiplierTP) double DefaultATRMultiplierTP = 0; // ATRMultiplierTP: Default ATR multiplier for TP.
input(name=INPUT_DESCRIPTION_DefaultATRTimeframe) ENUM_TIMEFRAMES DefaultATRTimeframe = PERIOD_CURRENT; // ATRTimeframe: Default timeframe for ATR.
input(name=INPUT_DESCRIPTION_DefaultSpreadAdjustmentSL) bool DefaultSpreadAdjustmentSL = false; // SpreadAdjustmentSL: Adjust SL by Spread value.
input(name=INPUT_DESCRIPTION_DefaultSpreadAdjustmentTP) bool DefaultSpreadAdjustmentTP = false; // SpreadAdjustmentTP: Adjust TP by Spread value.
input(name=INPUT_DESCRIPTION_DefaultCommission) double DefaultCommission = 0; // Commission: Default one-way commission per 1 lot.
input(name=INPUT_DESCRIPTION_DefaultCommissionType) COMMISSION_TYPE DefaultCommissionType = COMMISSION_CURRENCY; // CommissionType: Default commission type.
input(name=INPUT_DESCRIPTION_AutoCommission) bool AutoCommission = true; // AutoCommission: Get commission rules from the broker's server?
input(name=INPUT_DESCRIPTION_DefaultAccountButton) ACCOUNT_BUTTON DefaultAccountButton = Balance; // AccountButton: Balance/Equity/Balance-CPR
input(name=INPUT_DESCRIPTION_DefaultRisk) double DefaultRisk = 1; // Risk: Initial risk tolerance in percentage points
input(name=INPUT_DESCRIPTION_DefaultMoneyRisk) double DefaultMoneyRisk = 0; // MoneyRisk: If > 0, money risk tolerance in currency.
input(name=INPUT_DESCRIPTION_DefaultPositionSize) double DefaultPositionSize = 0; // PositionSize: If > 0, position size in lots.
input(name=INPUT_DESCRIPTION_DefaultIncludeOrders) INCLUDE_ORDERS DefaultIncludeOrders = INCLUDE_ORDERS_ALL; // IncludeOrders: Include which orders for portfolio risk?
input(name=INPUT_DESCRIPTION_DefaultIgnoreOrdersWithoutSL) bool DefaultIgnoreOrdersWithoutSL = false; // IgnoreOrdersWithoutSL: Ignore orders w/o SL in portfolio risk.
input(name=INPUT_DESCRIPTION_DefaultIgnoreOrdersWithoutTP) bool DefaultIgnoreOrdersWithoutTP = false; // IgnoreOrdersWithoutTP: Ignore orders w/o TP in portfolio risk.
input(name=INPUT_DESCRIPTION_DefaultIncludeSymbols) INCLUDE_SYMBOLS DefaultIncludeSymbols = INCLUDE_SYMBOLS_ALL; // IncludeSymbols: Include trades in which symbols for portfolio risk?
input(name=INPUT_DESCRIPTION_DefaultIncludeDirections) INCLUDE_DIRECTIONS DefaultIncludeDirections = INCLUDE_DIRECTIONS_ALL; // IncludeDirections: Include which directions for portfolio risk?
input(name=INPUT_DESCRIPTION_DefaultCustomLeverage) double DefaultCustomLeverage = 0; // CustomLeverage: Default custom leverage for Margin tab.
input(name=INPUT_DESCRIPTION_DefaultMagicNumber) int DefaultMagicNumber = 2022052714; // MagicNumber: Default magic number for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultCommentary) string DefaultCommentary = ""; // Commentary: Default order comment for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultCommentAutoSuffix) bool DefaultCommentAutoSuffix = false; // AutoSuffix: Automatic suffix for order comment in Trading tab.
input(name=INPUT_DESCRIPTION_DefaultCommentBalance) bool DefaultCommentBalance = false; // CommentBalance: Add current balance in front of order comment?
input(name=INPUT_DESCRIPTION_DefaultDisableTradingWhenLinesAreHidden) bool DefaultDisableTradingWhenLinesAreHidden = false; // DisableTradingWhenLinesAreHidden: for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxSlippage) int DefaultMaxSlippage = 0; // MaxSlippage: Maximum slippage for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxSpread) int DefaultMaxSpread = 0; // MaxSpread: Maximum spread for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxEntrySLDistance) int DefaultMaxEntrySLDistance = 0; // MaxEntrySLDistance: Maximum entry/SL distance for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMinEntrySLDistance) int DefaultMinEntrySLDistance = 0; // MinEntrySLDistance: Minimum entry/SL distance for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxRiskPercentage) double DefaultMaxRiskPercentage = 0; // MaxRiskPercentage: Maximum risk % for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxMarginPerc) double DefaultMaxMarginPerc = 0; // MaxMarginPerc: Maximum margin % for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxPositionSizeTotal) double DefaultMaxPositionSizeTotal = 0; // Maximum position size total for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultMaxPositionSizePerSymbol) double DefaultMaxPositionSizePerSymbol = 0; // Maximum position size per symbol for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultSubtractOPV) bool DefaultSubtractOPV = false; // SubtractOPV: Subtract open positions volume (Trading tab).
input(name=INPUT_DESCRIPTION_DefaultSubtractPOV) bool DefaultSubtractPOV = false; // SubtractPOV: Subtract pending orders volume (Trading tab).
input(name=INPUT_DESCRIPTION_DefaultDoNotApplyStopLoss) bool DefaultDoNotApplyStopLoss = false; // DoNotApplyStopLoss: Don't apply SL for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultDoNotApplyTakeProfit) bool DefaultDoNotApplyTakeProfit = false; // DoNotApplyTakeProfit: Don't apply TP for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultAskForConfirmation) bool DefaultAskForConfirmation = true; // AskForConfirmation: Ask for confirmation for Trading tab.
input(name=INPUT_DESCRIPTION_DefaultPanelPositionX) int DefaultPanelPositionX = 0; // PanelPositionX: Panel's X coordinate.
input(name=INPUT_DESCRIPTION_DefaultPanelPositionY) int DefaultPanelPositionY = 15; // PanelPositionY: Panel's Y coordinate.
input(name=INPUT_DESCRIPTION_DefaultPanelPositionCorner) ENUM_BASE_CORNER DefaultPanelPositionCorner = CORNER_LEFT_UPPER; // PanelPositionCorner: Panel's corner.
input(name=INPUT_DESCRIPTION_DefaultTPLockedOnSL) bool DefaultTPLockedOnSL = false; // TPLockedOnSL: Lock TP to (multiplied) SL distance.
input(name=INPUT_DESCRIPTION_DefaultTrailingStop) int DefaultTrailingStop = 0; // TrailingStop: For the Trading tab.
input(name=INPUT_DESCRIPTION_DefaultBreakEven) int DefaultBreakEven = 0; // BreakEven: For the Trading tab.
input(name=INPUT_DESCRIPTION_DefaultExpiryMinutes) int DefaultExpiryMinutes = 0; // ExpiryMinutes: Pending order expiration in minutes. Min = 2.
input(name=INPUT_DESCRIPTION_DefaultMaxNumberOfTradesTotal) int DefaultMaxNumberOfTradesTotal = 0; // MaxNumberOfTradesTotal: For the Trading tab. 0 - no limit.
input(name=INPUT_DESCRIPTION_DefaultMaxNumberOfTradesPerSymbol) int DefaultMaxNumberOfTradesPerSymbol = 0; // MaxNumberOfTradesPerSymbol: For the Trading tab. 0 - no limit.
input(name=INPUT_DESCRIPTION_DefaultMaxRiskTotal) double DefaultMaxRiskTotal = 0; // MaxRiskTotal: For the Trading tab. 0 - no limit.
input(name=INPUT_DESCRIPTION_DefaultMaxRiskPerSymbol) double DefaultMaxRiskPerSymbol = 0; // MaxRiskPerSymbol: For the Trading tab. 0 - no limit.
input(name=INPUT_DESCRIPTION_DefaultMaxMarginPercTotal) double DefaultMaxMarginPercTotal = 0; // MaxMarginPercTotal: For the Trading tab. 0 - no limit.
input(name=INPUT_DESCRIPTION_DefaultMaxMarginPercPerSymbol) double DefaultMaxMarginPercPerSymbol = 0; // MaxMarginPercPerSymbol: For the Trading tab. 0 - no limit.
input(name=INPUT_DESCRIPTION_DefaultSLDistanceInPoints) bool DefaultSLDistanceInPoints = false; // SLDistanceInPoints: SL distance in points instead of a level.
input(name=INPUT_DESCRIPTION_DefaultTPDistanceInPoints) bool DefaultTPDistanceInPoints = false; // TPDistanceInPoints: TP distance in points instead of a level.
input(name=INPUT_DESCRIPTION_DefaultStopLimitDistanceInPoints) bool DefaultStopLimitDistanceInPoints = false; // StopLimitDistanceInPoints: Stop-limit price distance in points.
input(name=INPUT_DESCRIPTION_DefaultMarginUtilizationBase) MARGIN_UTILIZATION_BASE DefaultMarginUtilizationBase = MUB_BALANCE; // Margin utilization base.
input(name=INPUT_DESCRIPTION_DefaultMUBStartingBalance) double DefaultMUBStartingBalance = 0; // Starting balance for margin utilization base.
input group INPUT_GROUP_DESCRIPTION_KEYBOARD_SHORTCUTS
input string ____ = INPUT_DESCRIPTION_____;
input(name=INPUT_DESCRIPTION_TradeHotKey) string TradeHotKey = "Shift+T"; // TradeHotKey: Execute a trade.
input(name=INPUT_DESCRIPTION_SwitchOrderTypeHotKey) string SwitchOrderTypeHotKey = "O"; // SwitchOrderTypeHotKey: Switch order type.
input(name=INPUT_DESCRIPTION_SwitchEntryDirectionHotKey) string SwitchEntryDirectionHotKey = "TAB"; // SwitchEntryDirectionHotKey: Switch entry direction.
input(name=INPUT_DESCRIPTION_SwitchHideShowLinesHotKey) string SwitchHideShowLinesHotKey = "H"; // SwitchHideShowLinesHotKey: Switch Hide/Show lines.
input(name=INPUT_DESCRIPTION_SetStopLossHotKey) string SetStopLossHotKey = "S"; // SetStopLossHotKey: Set SL to where mouse pointer is.
input(name=INPUT_DESCRIPTION_SetTakeProfitHotKey) string SetTakeProfitHotKey = "P"; // SetTakeProfitHotKey: Set TP to where mouse pointer is.
input(name=INPUT_DESCRIPTION_SetEntryHotKey) string SetEntryHotKey = "E"; // SetEntryHotKey: Set Entry to where mouse pointer is.
input(name=INPUT_DESCRIPTION_MinimizeMaximizeHotkey) string MinimizeMaximizeHotkey = "`"; // MinimizeMaximizeHotkey: Minimize/maximize the panel.
input(name=INPUT_DESCRIPTION_SwitchSLPointsLevelHotKey) string SwitchSLPointsLevelHotKey = "Shift+S"; // SwitchSLPointsLevelHotKey: Switch SL between points and level.
input(name=INPUT_DESCRIPTION_SwitchTPPointsLevelHotKey) string SwitchTPPointsLevelHotKey = "Shift+P"; // SwitchTPPointsLevelHotKey: Switch TP between points and level.
input(name=INPUT_DESCRIPTION_SwitchStopLimitPointsLevelHotKey) string SwitchStopLimitPointsLevelHotKey = "Shift+L"; // SwitchStopLimitPointsLevelHotKey: Switch stop-limit price between points and level.
input string SetTPGoalHotKey = "Shift+G"; // SetTPGoalHotKey: Set TP to this equity.
input string ContinuationBreakoutHotKey = "Shift+E"; // ContinuationBreakoutHotKey: Start/stop the continuation breakout strategy.
input string FindClosestSLHotKey = "Shift+O"; // FindClosestSLHotKey: Match SL to the closest high/low.
input group INPUT_GROUP_DESCRIPTION_MISCELLANEOUS
input(name=INPUT_DESCRIPTION_TP_Multiplier) double TP_Multiplier = 1; // TP Multiplier for SL value (for take-profit button).
input(name=INPUT_DESCRIPTION_UseCommissionToSetTPDistance) bool UseCommissionToSetTPDistance = false; // UseCommissionToSetTPDistance: For TP button.
input(name=INPUT_DESCRIPTION_ShowSpread) SHOW_SPREAD ShowSpread = No; // ShowSpread: Show current spread in points or as an SL ratio.
input(name=INPUT_DESCRIPTION_AdditionalFunds) double AdditionalFunds = 0; // AdditionalFunds: Added to account balance for risk calculation.
input(name=INPUT_DESCRIPTION_CustomBalance) double CustomBalance = 0; // CustomBalance: Overrides AdditionalFunds value.
input(name=INPUT_DESCRIPTION_ATRCandle) CANDLE_NUMBER ATRCandle = Current_Candle; // ATRCandle: Candle to get ATR value from.
input(name=INPUT_DESCRIPTION_CalculateUnadjustedPositionSize) bool CalculateUnadjustedPositionSize = false; // CalculateUnadjustedPositionSize: Ignore broker's restrictions.
input(name=INPUT_DESCRIPTION_SurpassBrokerMaxPositionSize) bool SurpassBrokerMaxPositionSize = false; // Surpass Broker Max Position Size with multiple trades.
input(name=INPUT_DESCRIPTION_RoundDown) bool RoundDown = true; // RoundDown: Position size and potential reward are rounded down.
input(name=INPUT_DESCRIPTION_QuickRisk1) double QuickRisk1 = 0; // QuickRisk1: First quick risk button, in percentage points.
input(name=INPUT_DESCRIPTION_QuickRisk2) double QuickRisk2 = 0; // QuickRisk2: Second quick risk button, in percentage points.
input(name=INPUT_DESCRIPTION_ObjectPrefix) string ObjectPrefix = "PS_"; // ObjectPrefix: To prevent confusion with other indicators/EAs.
input(name=INPUT_DESCRIPTION_SymbolChange) SYMBOL_CHART_CHANGE_REACTION SymbolChange = SYMBOL_CHART_CHANGE_EACH_OWN; // SymbolChange: What to do with the panel on chart symbol change?
input(name=INPUT_DESCRIPTION_DisableStopLimit) bool DisableStopLimit = false; // DisableStopLimit: If true, Stop Limit will be skipped.
input(name=INPUT_DESCRIPTION_TradeSymbol) string TradeSymbol = ""; // TradeSymbol: If non-empty, this symbol will be traded.
input(name=INPUT_DESCRIPTION_DisableTradingSounds) bool DisableTradingSounds = false; // DisableTradingSounds: If true, no sound for trading actions.
input(name=INPUT_DESCRIPTION_IgnoreMarketExecutionMode) bool IgnoreMarketExecutionMode = true; // IgnoreMarketExecutionMode: If true, ignore Market execution.
input(name=INPUT_DESCRIPTION_MarketModeApplySLTPAfterAllTradesExecuted) bool MarketModeApplySLTPAfterAllTradesExecuted = false; // Market Mode: Apply SL/TP after all trades executed.
input(name=INPUT_DESCRIPTION_DarkMode) bool DarkMode = false; // DarkMode: Enable dark mode for a less bright panel.
input(name=INPUT_DESCRIPTION_AutoDetectDarkMode) bool AutoDetectDarkMode = false; // AutoDetectDarkMode: Dark/light mode will be autodetected.
input(name=INPUT_DESCRIPTION_SettingsFile) string SettingsFile = ""; // SettingsFile: Custom settings file from \Files\PS_Settings\
input(name=INPUT_DESCRIPTION_PrefillAdditionalTPsBasedOnMain) bool PrefillAdditionalTPsBasedOnMain = true; // Prefill additional TPs based on Main?
input(name=INPUT_DESCRIPTION_AskBeforeClosing) bool AskBeforeClosing = false; // Ask for confirmation before closing the panel?
input(name=INPUT_DESCRIPTION_CapMaxPositionSizeBasedOnMargin) bool CapMaxPositionSizeBasedOnMargin = false; // Cap position size based on available margin?
input(name=INPUT_DESCRIPTION_LessRestrictiveMaxLimits) bool LessRestrictiveMaxLimits = false; // Allow smaller trades when trading limits are exceeded?
input(name=INPUT_DESCRIPTION_LongButtonColor) color LongButtonColor = CONTROLS_BUTTON_COLOR_BG; // Long Button Color
input(name=INPUT_DESCRIPTION_ShortButtonColor) color ShortButtonColor = CONTROLS_BUTTON_COLOR_BG; // Short Button Color
input(name=INPUT_DESCRIPTION_TradeButtonColor) color TradeButtonColor = CONTROLS_BUTTON_COLOR_BG; // Trade Button Color
input(name=INPUT_DESCRIPTION_DoNotDeleteLinesLabels) bool DoNotDeleteLinesLabels = false; // Do Not Delete Lines/Labels on deinitialization?
input(name=INPUT_DESCRIPTION_ConvertToPendingIfMaxMinEntrySLFails) bool ConvertToPendingIfMaxMinEntrySLFails = false; // Convert instant to pending if Max/Min Entry/SL distance fails?

CPositionSizeCalculator* ExtDialog;

// Global variables:
bool Dont_Move_the_Panel_to_Default_Corner_X_Y = true;
ulong LastRecalculationTime = 0;
bool StopLossLineIsBeingMoved = false;
bool TakeProfitLineIsBeingMoved[]; // Separate for each TP.
bool StopPriceLineIsBeingMoved = false;
bool AdditionalTPLineMoved = false;
int DeinitializationReason = -1;
string OldSymbol = "";
int OldTakeProfitsNumber = -1;
string SymbolForTrading;
int Mouse_Last_X = 0, Mouse_Last_Y = 0; // For SL/TP hotkeys.
color LongButtonColorAdjusted, ShortButtonColorAdjusted, TradeButtonColorAdjusted; // Based on the DarkMode setting.
bool DetectedColorMode;
HotkeyDef Hotkeys[HK_COUNT];

int OnInit()
{
    if (AutoDetectDarkMode) DetectedColorMode = DetectDarkMode();
    else DetectedColorMode = DarkMode;
    
    if (DetectedColorMode)
    {
        CONTROLS_EDIT_COLOR_ENABLE  = DARKMODE_EDIT_BG_COLOR;
        CONTROLS_EDIT_COLOR_DISABLE = 0x999999;
        CONTROLS_BUTTON_COLOR_ENABLE  = DARKMODE_BUTTON_BG_COLOR;
        CONTROLS_BUTTON_COLOR_DISABLE = 0x919999;
    }
    else
    {
        CONTROLS_EDIT_COLOR_ENABLE  = C'255,255,255';
        CONTROLS_EDIT_COLOR_DISABLE = C'221,221,211';
        CONTROLS_BUTTON_COLOR_ENABLE  = C'200,200,200';
        CONTROLS_BUTTON_COLOR_DISABLE = C'224,224,224';
    }
    if (LongButtonColor == CONTROLS_BUTTON_COLOR_BG) // Default color is used.
    {
        if (DetectedColorMode) LongButtonColorAdjusted = DARKMODE_BUTTON_BG_COLOR;
        else LongButtonColorAdjusted = CONTROLS_BUTTON_COLOR_BG;
    }
    else
    {
        LongButtonColorAdjusted = LongButtonColor;
    }
    if (ShortButtonColor == CONTROLS_BUTTON_COLOR_BG) // Default color is used.
    {
        if (DetectedColorMode) ShortButtonColorAdjusted = DARKMODE_BUTTON_BG_COLOR;
        else ShortButtonColorAdjusted = CONTROLS_BUTTON_COLOR_BG;
    }
    else
    {
        ShortButtonColorAdjusted = ShortButtonColor;
    }
    if (TradeButtonColor == CONTROLS_BUTTON_COLOR_BG) // Default color is used.
    {
        if (DetectedColorMode) TradeButtonColorAdjusted = DARKMODE_BUTTON_BG_COLOR;
        else TradeButtonColorAdjusted = CONTROLS_BUTTON_COLOR_BG;
    }
    else
    {
        TradeButtonColorAdjusted = TradeButtonColor;
    }
    
    TickSize = -1;

    if (DeinitializationReason != REASON_CHARTCHANGE) ExtDialog = new CPositionSizeCalculator; // Create the panel only if it is not a symbol/timeframe change.
    else OldTakeProfitsNumber = sets.TakeProfitsNumber; // Will be used to resize the panel if needed when switching symbols in some modes.

    MathSrand(GetTickCount() + 293029); // Used by CreateInstanceId() in Dialog.mqh (standard library). Keep the second number unique across other panel indicators/EAs.
    
    if (SettingsFile != "") // Load a custom settings file if given via input parameters.
    {
        ExtDialog.SetFileName(SettingsFile);
    }

    Dont_Move_the_Panel_to_Default_Corner_X_Y = true;
    
    PanelCaptionBase = "Position Sizer (ver. " + VERSION + ")";

    // Symbol changed.
    if ((DeinitializationReason == REASON_CHARTCHANGE) && (OldSymbol != _Symbol))
    {
        ObjectsDeleteAll(0, ObjectPrefix, -1, OBJ_HLINE); // All lines should be deleted, so that they could be recreated at new sets. values.
        if (SymbolChange == SYMBOL_CHART_CHANGE_EACH_OWN)
        {
            ExtDialog.SaveSettingsOnDisk(OldSymbol); // Save old symbol's settings.
        }
        ExtDialog.UpdateFileName(); // Update the filename.

        // Reset everything.
        OutputPointValue = ""; OutputSwapsType = TRANSLATION_LABEL_UNKNOWN; SwapsTripleDay = "?";
        OutputSwapsDailyLongLot = "?"; OutputSwapsDailyShortLot = "?"; OutputSwapsDailyLongPS = "?"; OutputSwapsDailyShortPS = "?";
        OutputSwapsYearlyLongLot = "?"; OutputSwapsYearlyShortLot = "?"; OutputSwapsYearlyLongPS = "?"; OutputSwapsYearlyShortPS = "?";
        OutputSwapsCurrencyDailyLot = ""; OutputSwapsCurrencyDailyPS = ""; OutputSwapsCurrencyYearlyLot = ""; OutputSwapsCurrencyYearlyPS = "";
        WarnedAboutZeroUnitCost = 0;

        if (SymbolChange == SYMBOL_CHART_CHANGE_HARD_RESET)
        {
            // Lines are treated as a part of the panel.
            if (DefaultLinesSelected) LinesSelectedStatus = 1; // Flip lines to selected.
            else LinesSelectedStatus = 2; // Flip lines to unselected.
        }
    }

    bool is_InitControlsValues_required = false;
    // Normal attempt to load settings fails (attempted in not chart change case and in chart case with 'each pair own settings' case
    if ((((DeinitializationReason != REASON_CHARTCHANGE) || ((DeinitializationReason == REASON_CHARTCHANGE) && (OldSymbol != _Symbol) && (SymbolChange == SYMBOL_CHART_CHANGE_EACH_OWN))) && (!ExtDialog.LoadSettingsFromDisk())) 
    // OR chart change with hard_reset configured and with symbol change.
      || ((DeinitializationReason == REASON_CHARTCHANGE) && (SymbolChange == SYMBOL_CHART_CHANGE_HARD_RESET) && (OldSymbol != _Symbol)))
    {
        sets.TradeDirection = DefaultTradeDirection;
        sets.EntryLevel = EntryLevel;
        sets.StopLossLevel = StopLossLevel;
        sets.TakeProfitLevel = TakeProfitLevel; // Optional
        sets.TPMultiplier = TP_Multiplier;
        sets.TakeProfitsNumber = DefaultTakeProfitsNumber;
        if (sets.TakeProfitsNumber < 1) sets.TakeProfitsNumber = 1; // At least one TP.
        ArrayResize(sets.TP, sets.TakeProfitsNumber);
        ArrayResize(sets.TPShare, sets.TakeProfitsNumber);
        ArrayResize(TakeProfitLineIsBeingMoved, sets.TakeProfitsNumber);
        ArrayInitialize(sets.TP, 0);
        ArrayInitialize(sets.TPShare, 100 / sets.TakeProfitsNumber);
        ArrayResize(sets.WasSelectedAdditionalTakeProfitLine, sets.TakeProfitsNumber - 1); // -1 because the flag for the main TP is saved elsewhere.
        sets.StopPriceLevel = StopPriceLevel; // Optional
        sets.ATRPeriod = DefaultATRPeriod;
        sets.ATRMultiplierSL = DefaultATRMultiplierSL;
        sets.ATRMultiplierTP = DefaultATRMultiplierTP;
        sets.ATRTimeframe = DefaultATRTimeframe;
        sets.EntryType = DefaultEntryType; // If Instant, Entry level will be updated to current Ask/Bid price automatically; if Pending, Entry level will remain intact and StopLevel warning will be issued if needed.
        sets.Risk = DefaultRisk; // Risk tolerance in percentage points
        sets.MoneyRisk = DefaultMoneyRisk; // Risk tolerance in account currency
        if (DefaultMoneyRisk > 0) sets.UseMoneyInsteadOfPercentage = true;
        else sets.UseMoneyInsteadOfPercentage = false;
        if (DefaultPositionSize > 0)
        {
            sets.RiskFromPositionSize = true;
            sets.PositionSize = DefaultPositionSize;
            OutputPositionSize = DefaultPositionSize;
        }
        else sets.RiskFromPositionSize = false;
        sets.CommissionPerLot = DefaultCommission; // Commission charged per lot (one side) in account currency or %.
        sets.CommissionType = DefaultCommissionType;
        sets.CustomBalance = CustomBalance;
        sets.RiskFromPositionSize = false;
        sets.AccountButton = DefaultAccountButton;
        sets.IncludeOrders = DefaultIncludeOrders; // Will portfolio risk calculation include all orders?
        sets.IgnoreOrdersWithoutSL = DefaultIgnoreOrdersWithoutSL; // If true, portfolio risk calculation will skip orders without stop-loss.
        sets.IgnoreOrdersWithoutTP = DefaultIgnoreOrdersWithoutTP; // If true, portfolio risk calculation will skip orders without take-profit.
        sets.IncludeSymbols = DefaultIncludeSymbols; // Include all symbols in portfolio risk calculation?
        sets.IncludeDirections = DefaultIncludeDirections; // Include all trade directions in portfolio risk calculation?
        sets.HideAccSize = HideAccSize; // If true, account size line will not be shown.
        sets.ShowLines = DefaultShowLines;
        sets.SelectedTab = MainTab;
        sets.CustomLeverage = DefaultCustomLeverage;
        sets.MagicNumber = DefaultMagicNumber;
        sets.Commentary = DefaultCommentary;
        sets.CommentAutoSuffix = DefaultCommentAutoSuffix;
        sets.DisableTradingWhenLinesAreHidden = DefaultDisableTradingWhenLinesAreHidden;
        if (sets.TakeProfitsNumber > 1)
        {
            for (int i = 0; i < sets.TakeProfitsNumber; i++)
            {
                sets.TP[i] = TakeProfitLevel;
                sets.TPShare[i] = 100 / sets.TakeProfitsNumber;
            }
        }
        sets.MaxSlippage = DefaultMaxSlippage;
        sets.MaxSpread = DefaultMaxSpread;
        sets.MaxEntrySLDistance = DefaultMaxEntrySLDistance;
        sets.MinEntrySLDistance = DefaultMinEntrySLDistance;
        sets.MaxRiskPercentage = DefaultMaxRiskPercentage;
        sets.MaxMarginPerc = DefaultMaxMarginPerc;
        sets.MaxPositionSizeTotal = DefaultMaxPositionSizeTotal;
        sets.MaxPositionSizePerSymbol = DefaultMaxPositionSizePerSymbol;
        if ((sets.MaxPositionSizeTotal < sets.MaxPositionSizePerSymbol) && (sets.MaxPositionSizeTotal != 0)) sets.MaxPositionSizeTotal = sets.MaxPositionSizePerSymbol;
        sets.StopLoss = 0;
        sets.TakeProfit = 0;
        sets.StopLimit = 0;
        sets.SubtractPendingOrders = DefaultSubtractPOV;
        sets.SubtractPositions = DefaultSubtractOPV;
        sets.DoNotApplyStopLoss = DefaultDoNotApplyStopLoss;
        sets.DoNotApplyTakeProfit = DefaultDoNotApplyTakeProfit;
        sets.AskForConfirmation = DefaultAskForConfirmation;
        sets.WasSelectedEntryLine = false;
        sets.WasSelectedStopLossLine  = false;
        sets.WasSelectedTakeProfitLine = false;
        sets.WasSelectedStopPriceLine = false;
        sets.TPLockedOnSL = DefaultTPLockedOnSL;
        sets.TrailingStopPoints = DefaultTrailingStop;
        sets.BreakEvenPoints = DefaultBreakEven;
        sets.ExpiryMinutes = DefaultExpiryMinutes;
        if ((sets.ExpiryMinutes != 0) && (sets.ExpiryMinutes < 2)) sets.ExpiryMinutes = 0;
        sets.MaxNumberOfTradesTotal = DefaultMaxNumberOfTradesTotal;
        sets.MaxNumberOfTradesPerSymbol = DefaultMaxNumberOfTradesPerSymbol;
        if ((sets.MaxNumberOfTradesTotal < sets.MaxNumberOfTradesPerSymbol) && (sets.MaxNumberOfTradesTotal != 0)) sets.MaxNumberOfTradesTotal = sets.MaxNumberOfTradesPerSymbol;
        sets.MaxRiskTotal = DefaultMaxRiskTotal;
        sets.MaxRiskPerSymbol = DefaultMaxRiskPerSymbol;
        if ((sets.MaxRiskTotal < sets.MaxRiskPerSymbol) && (sets.MaxRiskTotal != 0)) sets.MaxRiskTotal = sets.MaxRiskPerSymbol;
        sets.MaxMarginPercTotal = DefaultMaxMarginPercTotal;
        sets.MaxMarginPercPerSymbol = DefaultMaxMarginPercPerSymbol;
        if ((sets.MaxMarginPercTotal < sets.MaxMarginPercPerSymbol) && (sets.MaxMarginPercTotal != 0)) sets.MaxMarginPercTotal = sets.MaxMarginPercPerSymbol;
        // Because it is the first load:
        Dont_Move_the_Panel_to_Default_Corner_X_Y = false;
        sets.ShareVolumeMode = Decreasing;
        sets.SLDistanceInPoints = DefaultSLDistanceInPoints;
        sets.TPDistanceInPoints = DefaultTPDistanceInPoints;
        sets.StopLimitDistanceInPoints = DefaultStopLimitDistanceInPoints;
        sets.LastAdditionalTPScheme = ADDITIONAL_TP_SCHEME_OUTWARD;
        sets.MarginUtilizationBase = DefaultMarginUtilizationBase;
        sets.MUBStartingBalance = DefaultMUBStartingBalance;
        if (DeinitializationReason == REASON_CHARTCHANGE) is_InitControlsValues_required = true;
    }
    if (sets.TakeProfitsNumber < 1) // Read an old settings file with absent or bogus TakeProfitNumber parameter
    {
        sets.TakeProfitsNumber = 1; // At least one TP.
        ArrayResize(sets.TP, sets.TakeProfitsNumber);
        ArrayResize(sets.TPShare, sets.TakeProfitsNumber);
        ArrayResize(TakeProfitLineIsBeingMoved, sets.TakeProfitsNumber);
        ArrayInitialize(sets.TP, 0);
        ArrayInitialize(sets.TPShare, 100 / sets.TakeProfitsNumber);
        ArrayResize(sets.WasSelectedAdditionalTakeProfitLine, sets.TakeProfitsNumber - 1); // -1 because the flag for the main TP is saved elsewhere.
    }

    if (DeinitializationReason != REASON_CHARTCHANGE)
    {
        if (!ExtDialog.Create(0, "Position Sizer (ver. " + VERSION + ")", 0, DefaultPanelPositionX, DefaultPanelPositionY)) return INIT_FAILED;
        ExtDialog.Run();

        // No ini file - move the panel according to the inputs.
        if (!FileIsExist(ExtDialog.IniFileName() + ExtDialog.IniFileExt()))
        {
            Dont_Move_the_Panel_to_Default_Corner_X_Y = false;
        }
        ExtDialog.IniFileLoad();

        // If a hotkey is given, break up the string to check for hotkey presses in OnChartEvent().
        SetupHotkey(TradeHotKey,                Hotkeys[HK_Trade]);
        SetupHotkey(SwitchEntryDirectionHotKey, Hotkeys[HK_SwitchEntryDirection]);
        SetupHotkey(SwitchOrderTypeHotKey,      Hotkeys[HK_SwitchOrderType]);
        SetupHotkey(SwitchHideShowLinesHotKey,  Hotkeys[HK_SwitchHideShowLines]);
        SetupHotkey(SetStopLossHotKey,          Hotkeys[HK_SetStopLoss]);
        SetupHotkey(SetTakeProfitHotKey,        Hotkeys[HK_SetTakeProfit]);
        SetupHotkey(SetEntryHotKey,             Hotkeys[HK_SetEntry]);
        SetupHotkey(SwitchSLPointsLevelHotKey,  Hotkeys[HK_SwitchSLPointsLevel]);
        SetupHotkey(SwitchTPPointsLevelHotKey,  Hotkeys[HK_SwitchTPPointsLevel]);
        SetupHotkey(SwitchStopLimitPointsLevelHotKey, Hotkeys[HK_SwitchStopLimitPointsLevel]);
        SetupHotkey(MinimizeMaximizeHotkey,     Hotkeys[HK_MinimizeMaximize]);
        SetupHotkey(SetTPGoalHotKey,            Hotkeys[HK_SetTPGoal]);
        SetupHotkey(ContinuationBreakoutHotKey, Hotkeys[HK_ContinuationBreakout]);
        SetupHotkey(FindClosestSLHotKey,        Hotkeys[HK_FindClosestSL]);
    }
    else if (OldSymbol != _Symbol)
    {
        if (SymbolChange == SYMBOL_CHART_CHANGE_HARD_RESET) // Reset Entry, SL, and all TPs if it was a symbol change and a hard reset is required.
        {
            sets.EntryLevel = 0;
            sets.StopLossLevel = 0;
            sets.StopLoss = 0;
            sets.TakeProfitLevel = 0;
            sets.TakeProfit = 0;
            for (int i = 0; i < sets.TakeProfitsNumber; i++)
            {
                sets.TP[i] = 0;
            }
            sets.StopPriceLevel = 0;
            sets.StopLimit = 0;
            Dont_Move_the_Panel_to_Default_Corner_X_Y = false;
        }
    }    

    if (TradeSymbol != "") SymbolForTrading = TradeSymbol;
    else SymbolForTrading = _Symbol;

    // Avoid re-initialization on timeframe change and on symbol change with the 'keep panel' setting.
    if ((DeinitializationReason != REASON_CHARTCHANGE) || ((DeinitializationReason == REASON_CHARTCHANGE) && (OldSymbol != _Symbol) && ((SymbolChange == SYMBOL_CHART_CHANGE_HARD_RESET) || (SymbolChange == SYMBOL_CHART_CHANGE_EACH_OWN))))
    {
        Initialization();
        if (DeinitializationReason == REASON_CHARTCHANGE) // Do not run if it is not the symbol change because 'CPositionSizeCalculator::Create()' takes care of that in other cases.
        {
            // Remove extra empty space on the panel when going from a panel with more TPs to a panel with fewer TPs.
            if (sets.TakeProfitsNumber < OldTakeProfitsNumber)
            {
                int NewTakeProfitsNumber = sets.TakeProfitsNumber;
                sets.TakeProfitsNumber = OldTakeProfitsNumber; // Used and decremented inside OnClickBtnTakeProfitsNumberRemove().
                while (sets.TakeProfitsNumber > NewTakeProfitsNumber)
                {
                    ExtDialog.OnClickBtnTakeProfitsNumberRemove();
                }
            }
            else
            {
                // Create necessary panel elements if newly loaded symbol has more TPs.
                int NewTakeProfitsNumber = sets.TakeProfitsNumber;
                sets.TakeProfitsNumber = OldTakeProfitsNumber; // It will be increased inside OnClickBtnTakeProfitsNumberAdd().
                while (sets.TakeProfitsNumber < NewTakeProfitsNumber)
                {
                    ExtDialog.OnClickBtnTakeProfitsNumberAdd();
                }
            }
        }
    }

    // Moved this down to let the additional TP controls get created before actually trying to hide them.
    if ((DeinitializationReason == REASON_CHARTCHANGE) && (OldSymbol != _Symbol) && (SymbolChange == SYMBOL_CHART_CHANGE_EACH_OWN)) // Load the INI file if it was a symbol change and a each symbol has its own settings.
    {
        ExtDialog.IniFileLoad();
    }
    
    // Brings panel on top of other objects without actual maximization of the panel.
    ExtDialog.HideShowMaximize();
    if (!Dont_Move_the_Panel_to_Default_Corner_X_Y)
    {
        int new_x = DefaultPanelPositionX, new_y = DefaultPanelPositionY;
        int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        int chart_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        int panel_width = ExtDialog.Width();
        int panel_height = ExtDialog.Height();

        // Invert coordinate if necessary.
        if (DefaultPanelPositionCorner == CORNER_LEFT_LOWER)
        {
            new_y = chart_height - panel_height - new_y;
        }
        else if (DefaultPanelPositionCorner == CORNER_RIGHT_UPPER)
        {
            new_x = chart_width - panel_width - new_x;
        }
        else if (DefaultPanelPositionCorner == CORNER_RIGHT_LOWER)
        {
            new_x = chart_width - panel_width - new_x;
            new_y = chart_height - panel_height - new_y;
        }

        ExtDialog.remember_left = new_x;
        ExtDialog.remember_top = new_y;
        ExtDialog.Move(new_x, new_y);
        ExtDialog.FixatePanelPosition(); // Remember the panel's new position for the INI file.
    }

    if ((StartPanelMinimized) && (!ExtDialog.IsMinimized()) && (!Dont_Move_the_Panel_to_Default_Corner_X_Y)) // Minimize only if needs minimization. We check Dont_Move_the_Panel_to_Default_Corner_X_Y to make sure we didn't load an INI-file. An INI-file already contains a more preferred state for the panel.
    {
        // No access to the minmax button, no way to edit the chart height.
        // Dummy variables for passing as references.
        long lparam = 0;
        double dparam = 0;
        string sparam = "";
        // Increasing the height of the panel beyond that of the chart will trigger its minimization.
        ExtDialog.Height((int)ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS) + 1);
        // Call the chart event processing function.
        ExtDialog.ChartEvent(CHARTEVENT_CHART_CHANGE, lparam, dparam, sparam);
    }

    if (!(bool)MQLInfoInteger(MQL_VISUAL_MODE))
    {
        if (!EventSetTimer(1)) Print(TRANSLATION_MESSAGE_ERROR_SETTING_TIMER + ": ", GetLastError());
    }

    if (ShowATROptions) ExtDialog.InitATR();

    if (DetectedColorMode)
    {
        int total = ObjectsTotal(ChartID());
        for (int i = 0; i < total; i++)
        {
            string obj_name = ObjectName(ChartID(), i);
            if (StringSubstr(obj_name, 0, StringLen(ExtDialog.Name())) != ExtDialog.Name()) continue; // Skip non-panel objects.
            if (obj_name == ExtDialog.Name() + "Back")
            {
                
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_BG_DARK_COLOR);
            }
            if (obj_name == ExtDialog.Name() + "Caption")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_BG_DARK_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_CONTROL_BORDER_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_BG_DARK_COLOR);
            }
            else if (obj_name == ExtDialog.Name() + "ClientBack")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_MAIN_AREA_BORDER_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_MAIN_AREA_BG_COLOR);
            }
            else if (obj_name == ExtDialog.Name() + "m_BtnEntry") // Long/Short
            {
                if (sets.TradeDirection == Long)
                {
                    ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, LongButtonColorAdjusted);
                }
                else if (sets.TradeDirection == Short)
                {
                    ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, ShortButtonColorAdjusted);
                }
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_CONTROL_BORDER_COLOR);
            }
            else if ((obj_name == ExtDialog.Name() + "m_BtnMainTrade") || (obj_name == ExtDialog.Name() + "m_BtnTrade") || (obj_name == ExtDialog.Name() + "m_OutsideTradeButton")) // Any of the Trade buttons (Main tab, Trading tab, outside).
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, TradeButtonColorAdjusted);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_CONTROL_BORDER_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(ExtDialog.Name() + "m_Edt")) == ExtDialog.Name() + "m_Edt")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_EDIT_BG_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_CONTROL_BORDER_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(ExtDialog.Name() + "m_Btn")) == ExtDialog.Name() + "m_Btn")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_BUTTON_BG_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_CONTROL_BORDER_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(ExtDialog.Name() + "m_Chk")) == ExtDialog.Name() + "m_Chk")
            {
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_TEXT_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_MAIN_AREA_BG_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_MAIN_AREA_BG_COLOR);
            }
            else if (StringSubstr(obj_name, 0, StringLen(ExtDialog.Name() + "m_Rgp")) == ExtDialog.Name() + "m_Rgp")
            {
                if (ObjectGetInteger(ChartID(), obj_name, OBJPROP_TYPE) == OBJ_RECTANGLE_LABEL) ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_MAIN_AREA_BG_COLOR);
                else ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_TEXT_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BGCOLOR, DARKMODE_MAIN_AREA_BG_COLOR);
                ObjectSetInteger(ChartID(), obj_name, OBJPROP_BORDER_COLOR, DARKMODE_MAIN_AREA_BG_COLOR);
            }
            else
            {
                if (obj_name == ExtDialog.Name() + "m_LblURL") ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, 0x224400);
                else ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, DARKMODE_TEXT_COLOR);
            }
        }
    }

    // If symbol change with a reset was enacted.
    if (is_InitControlsValues_required) ExtDialog.InitControlsValues();

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    DeinitializationReason = reason; // Remember reason to avoid recreating the panel in the OnInit() if it is not deleted here.
    
    EventKillTimer();

    // The strategy state does not survive a reload, so leave no orphaned breakout orders behind.
    if ((CBEnabled) && (reason != REASON_CHARTCHANGE))
    {
        CBEnabled = false;
        CBDeleteAllPending();
        Comment("");
    }

    if (reason == REASON_TEMPLATE) sets.TemplateChanged = true; // Will be used to select lines according to the DefaultLinesSelected input parameter.

    if ((reason == REASON_CLOSE) || (reason == REASON_REMOVE) || (reason == REASON_CHARTCLOSE) || (reason == REASON_PROGRAM))
    {
        if (!DoNotDeleteLinesLabels) ObjectsDeleteAll(0, ObjectPrefix); // Delete all lines if platform was closed.
        if ((reason == REASON_REMOVE) || (reason == REASON_PROGRAM))
        {
            if (SettingsFile == "") ExtDialog.DeleteSettingsFile();
            if (!FileDelete(ExtDialog.IniFileName() + ExtDialog.IniFileExt())) Print(TRANSLATION_MESSAGE_FAILED_DELETE_INI + ": ", GetLastError());
        }
    }
    
    // It is deinitialization due to input parameters change - save current parameters values (that are also changed via panel) to global variables.
    if (reason == REASON_PARAMETERS) GlobalVariableSet("PS-" + IntegerToString(ChartID()) + "-Parameters", 1);

    if ((reason != REASON_CHARTCHANGE) && (reason != REASON_REMOVE) && (reason != REASON_PROGRAM))
    {
        ExtDialog.SaveSettingsOnDisk();
        ExtDialog.IniFileSave();
    } 

    if (reason == REASON_CHARTCHANGE)
    {
        OldSymbol = _Symbol;
    }
    else
    {
        if (!DoNotDeleteLinesLabels)
        {
            ObjectDelete(0, ObjectPrefix + "StopLossLabel");
            ObjectsDeleteAll(0, ObjectPrefix + "TakeProfitLabel", -1, OBJ_LABEL);
            ObjectDelete(0, ObjectPrefix + "StopPriceLabel");
            ObjectsDeleteAll(0, ObjectPrefix + "TPAdditionalLabel", -1, OBJ_LABEL);
            ObjectDelete(0, ObjectPrefix + "SLAdditionalLabel");
            ObjectDelete(0, ObjectPrefix + "EntryAdditionalLabel");
        }
        ExtDialog.Destroy();
        delete ExtDialog;
    }
    
    if (!DoNotDeleteLinesLabels) ObjectsDeleteAll(0, ObjectPrefix + "BE"); // Delete all BE lines and labels.
    
    ChartRedraw();
}

void OnTick()
{
    // Strategy Tester (visual mode) support:
    if ((bool)MQLInfoInteger(MQL_VISUAL_MODE))
    {
        ListenToChartEvents(ExtDialog.Name()); // Synthesizes panel events from the raw chart objects because the tester doesn't deliver them.
        ExtDialog.UpdateStrategyTesterTrades(); // Updates the outside Close buttons and removes those of the trades that no longer exist.
    }

    ExtDialog.RefreshValues();

    if (sets.TrailingStopPoints > 0) DoTrailingStop();

    DoFetchWebCommands();
    DoWaitConfirmationBar();
    DoCloseAllOnEquityReach();
    DoContinuationBreakout();
}

void DoCancelAutoTrade()
{
    CustomTradeSignal = "NONE";
    ExtDialog.m_BtnOrderOnNextBar.Text(" ");
}

void DoWaitConfirmationBar()
{
    // No trade signal, so we don't need to trade
    if (CustomTradeSignal != "BUY" && CustomTradeSignal != "SELL") return;

    // Ensure this function is called once per bar
    if (CustomCurrentBarIndex == iTime(NULL, Period(), 0)) {
        return;
    }
    CustomCurrentBarIndex = iTime(NULL, Period(), 0);

    // Check if confirmation bar received
    bool isBuyBar = iClose(NULL, Period(), 1) > iOpen(NULL, Period(), 1);
    bool shouldBuy = CustomTradeSignal == "BUY" && sets.TradeDirection == Long && isBuyBar;
    bool shouldSell = CustomTradeSignal == "SELL" && sets.TradeDirection == Short && !isBuyBar;
    if (!shouldBuy && !shouldSell) {
        return;
    }

    Print("Confirmation bar received for ", CustomTradeSignal);

    DoTrade();

    CustomTradeSignal = "NONE";
    ExtDialog.m_BtnOrderOnNextBar.Text(" ");
}

void DoSetTPToEquityGoal()
{
    // Find maximum major multiplier (eg. 1:3 RRR, 1:4 RRR, etc)
    CustomTPMultiplier = 0;
    for (int i = 0; i < 30; i++) {
        ExtDialog.OnClickBtnTakeProfitsNumberAdd();
        ExtDialog.RefreshValues();

        if (CustomEquityGoal < sets.TPLinePrice) {
            break;
        }
    }

    // Pullback by one major multiplier
    ExtDialog.OnClickBtnTakeProfitsNumberMinus();
    ExtDialog.RefreshValues();

    // Figure out the minimum minor multiplier needed to
    // reach the target equity goal (eg. 1:3.1 RRR, 1:3.2 RRR, etc)
    for (int i = 1; i < 11; i++) {
        ExtDialog.OnClickBtnTakeProfitsNumberAdd(true);
        ExtDialog.RefreshValues();

        if (CustomEquityGoal < sets.TPLinePrice) {
            break;
        }
    }

    // Small chance that there are some rounding issues around the target
    // equity goal. So, we add one more minor multiplier.
    ExtDialog.OnClickBtnTakeProfitsNumberAdd(true);
}

void DoMax5PipsEntry()
{
    // Check if SL is bigger than 50 ticks
    double fullPriceRange = MathAbs(sets.EntryLevel - sets.StopLossLevel);
    if (fullPriceRange / _Point < 50) {
        Print("SL is smaller than 50 ticks, nothing to adjust: ", fullPriceRange / _Point);
        return;
    }

    // Set max 5 pips SL
    if (sets.TradeDirection == Long) {
        ExtDialog.m_EdtSL.Text(DoubleToString(sets.EntryLevel - (50 * _Point), _Digits));
    } else {
        ExtDialog.m_EdtSL.Text(DoubleToString(sets.EntryLevel + (50 * _Point), _Digits));
    }
    ExtDialog.OnEndEditEdtSL();
    ExtDialog.RefreshValues();

    Print("SL is bigger than 50 ticks, making limit order: ", fullPriceRange / _Point);
}

void DoSafe5PipsEntry()
{
    // Check if SL is bigger than 50 ticks
    double fullPriceRange = MathAbs(sets.EntryLevel - sets.StopLossLevel);
    if (fullPriceRange / _Point < 50) {
        Print("Will make market order as SL is smaller than 50 ticks: ", fullPriceRange / _Point);
        return;
    }

    Print("Will make limit order as SL is bigger than 50 ticks: ", fullPriceRange / _Point);

    sets.EntryType = Pending;

    // Set max 5 pips SL
    if (sets.TradeDirection == Long) {
        ExtDialog.m_EdtEntryLevel.Text(DoubleToString(sets.StopLossLevel + (50 * _Point), _Digits));
    } else {
        ExtDialog.m_EdtEntryLevel.Text(DoubleToString(sets.StopLossLevel - (50 * _Point), _Digits));
    }
    ExtDialog.OnEndEditEdtEntryLevel();
    ExtDialog.RefreshValues();
}

void DoSnapSL()
{
    if (sets.TradeDirection == Long) {
        double newSL = -1;
        double minDiff = 999999999;
        // Bar 0 is the bar in progress, so its current low/high is included too
        for (int i = 0; i < 50; i++) {
            // Check if current SL is above the tested bar
            if (iLow(NULL, Period(), i) <= sets.StopLossLevel) {
                continue;
            }

            // Check distance between current SL and tested bar low
            double diff = MathAbs((iLow(NULL, Period(), i) - sets.StopLossLevel) / _Point);
            if (diff < minDiff) {
                minDiff = diff;
                newSL = iLow(NULL, Period(), i);
            }
        }

        // Update SL to the closest low
        if (newSL != -1) {
            ExtDialog.m_EdtSL.Text(DoubleToString(newSL, _Digits));
            ExtDialog.OnEndEditEdtSL();
        }
    }

    if (sets.TradeDirection == Short) {
        double newSL = -1;
        double minDiff = 999999999;
        // Bar 0 is the bar in progress, so its current low/high is included too
        for (int i = 0; i < 50; i++) {
            // Check if current SL is above the tested bar
            if (sets.StopLossLevel <= iHigh(NULL, Period(), i)) {
                continue;
            }

            // Check distance between current SL and tested bar high
            double diff = MathAbs((sets.StopLossLevel - iHigh(NULL, Period(), i)) / _Point);
            if (diff < minDiff) {
                minDiff = diff;
                newSL = iHigh(NULL, Period(), i);
            }
        }

        // Update SL to the closest high
        if (newSL != -1) {
            ExtDialog.m_EdtSL.Text(DoubleToString(newSL, _Digits));
            ExtDialog.OnEndEditEdtSL();
        }
    }
}

void DoSnapEntry()
{
    double newEntry = -1;
    double minDiff = 999999999;
    for (int i = 1; i <= 50; i++) {
        // High is an edge only if the previous bar high is lower
        double high = iHigh(NULL, Period(), i);
        if (iHigh(NULL, Period(), i + 1) < high) {
            double diff = MathAbs((high - sets.EntryLevel) / _Point);
            if (diff < minDiff) {
                minDiff = diff;
                newEntry = high;
            }
        }

        // Low is an edge only if the previous bar low is higher
        double low = iLow(NULL, Period(), i);
        if (iLow(NULL, Period(), i + 1) > low) {
            double diff = MathAbs((low - sets.EntryLevel) / _Point);
            if (diff < minDiff) {
                minDiff = diff;
                newEntry = low;
            }
        }
    }

    // Update Entry to the closest high/low edge
    if (newEntry > 0) {
        ExtDialog.m_EdtEntryLevel.Text(DoubleToString(newEntry, _Digits));
        ExtDialog.OnEndEditEdtEntryLevel();
    }
}

void Do80PercentPullbackEntry()
{
    sets.EntryType = Instant;

    // Make safe SL 20% smaller
    if (sets.TradeDirection == Long)
    {
        double fullPriceRange = sets.EntryLevel - sets.StopLossLevel;
        double smallerSLPrice = sets.StopLossLevel + (fullPriceRange * 0.2);

        ExtDialog.m_EdtSL.Text(DoubleToString(smallerSLPrice, _Digits));
        ExtDialog.OnEndEditEdtSL();
    }
    else if (sets.TradeDirection == Short)
    {
        double fullPriceRange = sets.StopLossLevel - sets.EntryLevel;
        double smallerSLPrice = sets.StopLossLevel - (fullPriceRange * 0.2);

        ExtDialog.m_EdtSL.Text(DoubleToString(smallerSLPrice, _Digits));
        ExtDialog.OnEndEditEdtSL();
    }

    // Go for 1:2 RRR to figure pips needed for BE
    for (int i = 0; i < 10; i++) {
        ExtDialog.OnClickBtnTakeProfitsNumberMinus();
    }
    ExtDialog.OnClickBtnTakeProfitsNumberAdd();
    ExtDialog.RefreshValues();

    // Set BE on 1:2 RRR
    ExtDialog.m_EdtBreakEvenPoints.Text(ExtDialog.m_EdtTP.Text());
    ExtDialog.OnEndEditEdtBreakEvenPoints();

    // Set TP for 1:3 RRR
    ExtDialog.OnClickBtnTakeProfitsNumberAdd();
    ExtDialog.RefreshValues();
}

void DoHalfPipSmallerPullbackEntry()
{
    sets.EntryType = Pending;

    // Make safe SL 0.5 pip smaller
    if (sets.TradeDirection == Long)
    {
        double smallerEntryPrice = iClose(NULL, Period(), 1) - (_Point * 5);

        ExtDialog.m_EdtEntryLevel.Text(DoubleToString(smallerEntryPrice, _Digits));
        ExtDialog.OnEndEditEdtEntryLevel();
    }
    else if (sets.TradeDirection == Short)
    {
        double smallerEntryPrice = iClose(NULL, Period(), 1) + (_Point * 5);

        ExtDialog.m_EdtEntryLevel.Text(DoubleToString(smallerEntryPrice, _Digits));
        ExtDialog.OnEndEditEdtEntryLevel();
    }

    ExtDialog.RefreshValues();
}

// Continuation breakout: a buy stop rests at the latest swing high and a sell stop at the latest swing low,
// during the London session only. SL distance, RRR and position size are taken from the panel when it starts.
void DoToggleContinuationBreakout()
{
    if (CBEnabled)
    {
        CBEnabled = false;
        CBDeleteAllPending();
        Comment("");
        Print("Continuation breakout stopped. Its pending orders were deleted.");
        return;
    }

    if ((CustomCBSwing < 1) || (CustomCBSwing > 5))
    {
        Print("Continuation breakout not started: swing candles must be 1-5.");
        return;
    }

    ExtDialog.RefreshValues();
    CBSLDistance = MathAbs(sets.EntryLevel - sets.StopLossLevel);
    CBRRR = CustomTPMultiplier;
    CBLots = OutputPositionSize;
    if ((CBSLDistance <= 0) || (CBRRR <= 0) || (CBLots <= 0))
    {
        Print("Continuation breakout not started: the panel needs an SL, RRR and position size.");
        return;
    }

    CBSeedLevels();
    CBLastLevelBar = iTime(_Symbol, _Period, 0);
    CBSessionMinute = -1;
    CBInSession = false;
    CBBuyFailBar = 0;
    CBSellFailBar = 0;
    CBEnabled = true;

    string info = "Continuation breakout ON | SL " + DoubleToString(CBSLDistance / _Point, 0) + " points | 1:" + DoubleToString(CBRRR, 1) + " RRR | " + DoubleToString(CBLots, 2) + " lots";
    Comment(info);
    Print(info);
}

void DoContinuationBreakout()
{
    if (!CBEnabled) return;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // Price traded through a live level: that breakout is used up.
    if ((CBLevelHigh > 0) && (!CBHighTaken) && (bid >= CBLevelHigh)) CBHighTaken = true;
    if ((CBLevelLow > 0) && (!CBLowTaken) && (bid <= CBLevelLow)) CBLowTaken = true;

    // A chart candle just completed: it may confirm a new swing.
    datetime bar = iTime(_Symbol, _Period, 0);
    if (bar != CBLastLevelBar)
    {
        CBLastLevelBar = bar;
        int mid = CustomCBSwing + 1;
        if (CBIsSwingHigh(mid)) { CBLevelHigh = iHigh(_Symbol, _Period, mid); CBHighTaken = false; }
        if (CBIsSwingLow(mid)) { CBLevelLow = iLow(_Symbol, _Period, mid); CBLowTaken = false; }
    }

    // Session: close the breakout positions on the first tick after it ends.
    long minute = (long)(TimeCurrent() / 60);
    if (minute != CBSessionMinute)
    {
        CBSessionMinute = minute;
        bool wasInSession = CBInSession;
        CBInSession = CBIsInSession(TimeCurrent());
        if (wasInSession && !CBInSession) CBCloseAllPositions();
    }

    bool armLong = CBInSession && !CBHighTaken && (CBLevelHigh > 0) && (ask < CBLevelHigh);
    bool armShort = CBInSession && !CBLowTaken && (CBLevelLow > 0) && (bid > CBLevelLow);
    if (armLong) CBArmPending(ORDER_TYPE_BUY_STOP, CBLevelHigh); else CBDeletePending(ORDER_TYPE_BUY_STOP);
    if (armShort) CBArmPending(ORDER_TYPE_SELL_STOP, CBLevelLow); else CBDeletePending(ORDER_TYPE_SELL_STOP);
}

// A fill uses up its level. With OCO on, the opposite order is cancelled, so its level is used up too.
void CBOnDealAdd(const ulong deal)
{
    if (!CBEnabled) return;
    if (!HistoryDealSelect(deal)) return;
    if (HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol) return;
    if ((sets.MagicNumber != 0) && (HistoryDealGetInteger(deal, DEAL_MAGIC) != sets.MagicNumber)) return;
    if (HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_IN) return;
    if (StringFind(HistoryDealGetString(deal, DEAL_COMMENT), "CB ") != 0) return;

    if (HistoryDealGetInteger(deal, DEAL_TYPE) == DEAL_TYPE_BUY) CBHighTaken = true;
    else CBLowTaken = true;
    if (CustomOCOEnabled)
    {
        CBHighTaken = true;
        CBLowTaken = true;
    }
}

// The candle at shift mid is a swing high if its high is above the highs of CustomCBSwing candles on each side.
bool CBIsSwingHigh(const int mid)
{
    double midHigh = iHigh(_Symbol, _Period, mid);
    if (midHigh == 0) return false;
    for (int s = mid - CustomCBSwing; s <= mid + CustomCBSwing; s++)
    {
        if (s == mid) continue;
        if (iHigh(_Symbol, _Period, s) >= midHigh) return false;
    }
    return true;
}

bool CBIsSwingLow(const int mid)
{
    double midLow = iLow(_Symbol, _Period, mid);
    if (midLow == 0) return false;
    for (int s = mid - CustomCBSwing; s <= mid + CustomCBSwing; s++)
    {
        if (s == mid) continue;
        if (iLow(_Symbol, _Period, s) <= midLow) return false;
    }
    return true;
}

// On start, pick up the most recent confirmed swings, unless price has already traded through them.
void CBSeedLevels()
{
    CBLevelHigh = 0;
    CBLevelLow = 0;
    CBHighTaken = true;
    CBLowTaken = true;
    for (int mid = CustomCBSwing + 1; mid < 200; mid++)
    {
        if (CBLevelHigh == 0 && CBIsSwingHigh(mid))
        {
            CBLevelHigh = iHigh(_Symbol, _Period, mid);
            CBHighTaken = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, mid, 0)) >= CBLevelHigh;
        }
        if (CBLevelLow == 0 && CBIsSwingLow(mid))
        {
            CBLevelLow = iLow(_Symbol, _Period, mid);
            CBLowTaken = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, mid, 0)) <= CBLevelLow;
        }
        if (CBLevelHigh > 0 && CBLevelLow > 0) break;
    }
}

bool CBIsOwnOrder()
{
    if (OrderGetString(ORDER_SYMBOL) != _Symbol) return false;
    if ((sets.MagicNumber != 0) && (OrderGetInteger(ORDER_MAGIC) != sets.MagicNumber)) return false;
    return StringFind(OrderGetString(ORDER_COMMENT), "CB ") == 0;
}

// Pending stop order of one side; 0 when none.
ulong CBFindPending(const ENUM_ORDER_TYPE type)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong t = OrderGetTicket(i);
        if (t == 0) continue;
        if (!CBIsOwnOrder()) continue;
        if ((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) == type) return t;
    }
    return 0;
}

void CBDeletePending(const ENUM_ORDER_TYPE type)
{
    ulong t = CBFindPending(type);
    if (t != 0) CBTrade.OrderDelete(t);
}

void CBDeleteAllPending()
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong t = OrderGetTicket(i);
        if (t == 0) continue;
        if (CBIsOwnOrder()) CBTrade.OrderDelete(t);
    }
}

void CBCloseAllPositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong t = PositionGetTicket(i);
        if (t == 0) continue;
        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if ((sets.MagicNumber != 0) && (PositionGetInteger(POSITION_MAGIC) != sets.MagicNumber)) continue;
        if (StringFind(PositionGetString(POSITION_COMMENT), "CB ") != 0) continue;
        CBTrade.PositionClose(t);
    }
}

// Place the stop order at the level, or move it there if it already rests elsewhere.
// A rejected order is retried on the next bar, not on every tick.
void CBArmPending(const ENUM_ORDER_TYPE type, const double level)
{
    bool isBuy = (type == ORDER_TYPE_BUY_STOP);
    datetime bar = iTime(_Symbol, _Period, 0);
    if ((isBuy ? CBBuyFailBar : CBSellFailBar) == bar) return;

    double price = NormalizeDouble(level, _Digits);
    double sl = NormalizeDouble(isBuy ? price - CBSLDistance : price + CBSLDistance, _Digits);
    double tp = NormalizeDouble(isBuy ? price + CBSLDistance * CBRRR : price - CBSLDistance * CBRRR, _Digits);
    CBTrade.SetExpertMagicNumber(sets.MagicNumber);

    bool ok = true;
    ulong t = CBFindPending(type);
    if (t != 0)
    {
        if (MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - price) > _Point / 2) ok = CBTrade.OrderModify(t, price, sl, tp, ORDER_TIME_GTC, 0);
    }
    else if (isBuy) ok = CBTrade.BuyStop(CBLots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "CB Long");
    else ok = CBTrade.SellStop(CBLots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "CB Short");

    if (ok) return;
    Print("Continuation breakout: ", (isBuy ? "buy" : "sell"), " stop at ", price, " rejected: ", CBTrade.ResultRetcodeDescription(), ". Retrying next bar.");
    if (isBuy) CBBuyFailBar = bar;
    else CBSellFailBar = bar;
}

// Server time to London time, for the session filter.
int CBNthWeekday(const int year, const int month, const int weekday, const int n)
{
    MqlDateTime d;
    ZeroMemory(d);
    d.year = year;
    d.mon = month;
    d.day = 1;
    MqlDateTime f;
    TimeToStruct(StructToTime(d), f);
    int day = 1 + (weekday - f.day_of_week + 7) % 7;
    if (n > 0) return day + (n - 1) * 7;
    int dim = (month == 2) ? (((year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0))) ? 29 : 28)
              : ((month == 4) || (month == 6) || (month == 9) || (month == 11)) ? 30 : 31;
    while (day + 7 <= dim) day += 7;
    return day;
}

// US DST: 2nd Sunday of March to 1st Sunday of November.
bool CBIsUSDST(const datetime t)
{
    MqlDateTime d;
    TimeToStruct(t, d);
    if ((d.mon < 3) || (d.mon > 11)) return false;
    if ((d.mon > 3) && (d.mon < 11)) return true;
    if (d.mon == 3) return d.day >= CBNthWeekday(d.year, 3, 0, 2);
    return d.day < CBNthWeekday(d.year, 11, 0, 1);
}

// UK DST: last Sunday of March to last Sunday of October (01:00 UTC).
bool CBIsUKDST(const datetime utc)
{
    MqlDateTime d;
    TimeToStruct(utc, d);
    if ((d.mon < 3) || (d.mon > 10)) return false;
    if ((d.mon > 3) && (d.mon < 10)) return true;
    int s = CBNthWeekday(d.year, d.mon, 0, -1);
    if (d.mon == 3) return (d.day > s) || ((d.day == s) && (d.hour >= 1));
    return (d.day < s) || ((d.day == s) && (d.hour < 1));
}

bool CBIsInSession(const datetime server)
{
    int offset = CustomCBServerGMTWinter + ((CustomCBServerUSDST && CBIsUSDST(server)) ? 1 : 0);
    datetime utc = server - offset * 3600;
    MqlDateTime d;
    TimeToStruct(utc + (CBIsUKDST(utc) ? 3600 : 0), d);
    if ((d.day_of_week == 0) || (d.day_of_week == 6)) return false;
    int mins = d.hour * 60 + d.min;
    return (mins >= CustomCBSessionStartHour * 60) && (mins < CustomCBSessionEndHour * 60);
}

void DoFetchWebCommands()
{
    if (CustomWebRequestInProgress) return;
    if (!CustomWebFetchingEnabled) return;

    CustomWebRequestInProgress = true;

    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    int currentHour = timeStruct.hour;
    int currentSecond = timeStruct.sec;

    if (currentSecond % 10 != 0 || CustomWebCommandDomain == "https://www.example.org") {
        CustomWebRequestInProgress = false;
        return;
    }

    string headers;
    char data[], result[];

    ResetLastError();

    // NOTE: Enable this URL in Tools → Options → Expert Advisors
    WebRequest("GET", CustomWebCommandDomain + "/get", NULL, NULL, 3000, data, 0, result, headers);

    if (CharArrayToString(result, 0, 5) == "RESET") {
        CustomTradeSignal = "NONE";
        ExtDialog.m_BtnOrderOnNextBar.Text(" ");

        WebRequest("GET", CustomWebCommandDomain + "/set/HOLD", NULL, NULL, 3000, data, 0, result, headers);

        Print("RESET command received");
    } else if (CharArrayToString(result, 0, 3) == "BUY") {
        sets.TradeDirection = Long;
        sets.EntryType = Instant;
        ExtDialog.m_EdtSL.Text(DoubleToString(iLow(NULL, Period(), 1) - (100 * _Point), _Digits));
        ExtDialog.OnEndEditEdtSL();

        // Only trade London session
        datetime currentTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(currentTime, timeStruct);
        int currentHour = timeStruct.hour;
        int currentSecond = timeStruct.sec;
        if (currentHour >= 10 && currentHour < 19) {
            CustomTradeSignal = "NONE";
            ExtDialog.OnClickBtnOrderOnNextBar();
        }

        WebRequest("GET", CustomWebCommandDomain + "/set/HOLD", NULL, NULL, 3000, data, 0, result, headers);

        Print("BUY command received");
    } else if (CharArrayToString(result, 0, 4) == "SELL") {
        sets.TradeDirection = Short;
        sets.EntryType = Instant;
        ExtDialog.m_EdtSL.Text(DoubleToString(iLow(NULL, Period(), 1) + (100 * _Point), _Digits));
        ExtDialog.OnEndEditEdtSL();

        // Only trade London session
        datetime currentTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(currentTime, timeStruct);
        int currentHour = timeStruct.hour;
        int currentSecond = timeStruct.sec;
        if (currentHour >= 10 && currentHour < 19) {
            CustomTradeSignal = "NONE";
            ExtDialog.OnClickBtnOrderOnNextBar();
        }

        WebRequest("GET", CustomWebCommandDomain + "/set/HOLD", NULL, NULL, 3000, data, 0, result, headers);

        Print("SELL command received");
    } else if (CharArrayToString(result, 0, 4) == "HOLD") {
        // Disabled because very noisy
        // Print("HOLD command received");
    } else {
        // Disabled because HTTP requests sometimes return empty
        // Print("Unknown command received: ", CharArrayToString(result));
    }

    CustomWebRequestInProgress = false;
}

void DoCloseAllOnEquityReach()
{
    if (CustomEquityGoal <= 0) return;
    // Buffer for slippage on close so realized equity still meets the goal.
    if (AccountInfoDouble(ACCOUNT_EQUITY) < CustomEquityGoal + 5.0) return;

    int total = PositionsTotal();
    if (total == 0) return;

    Print("Equity reached goal: ", AccountInfoDouble(ACCOUNT_EQUITY), " >= ", CustomEquityGoal, ". Closing all positions.");

    CTrade trade;
    for (int i = total - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            trade.PositionClose(ticket, 3);
        }
    }

    // Also delete pending orders
    int orders = OrdersTotal();
    for (int i = orders - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0)
        {
            trade.OrderDelete(ticket);
        }
    }
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_MOUSE_MOVE)
    {
        Mouse_Last_X = (int)lparam;
        Mouse_Last_Y = (int)dparam;
        if (((uint)sparam & 1) == 1) // While left mouse button is down.
        {
            if ((sets.SLDistanceInPoints) || ((ShowATROptions) && (sets.ATRMultiplierSL > 0)))
            {
                double current_line_price = NormalizeDouble(ObjectGetDouble(ChartID(), ObjectPrefix + "StopLossLine", OBJPROP_PRICE, 0), _Digits);
                if (MathAbs(current_line_price - tStopLossLevel) > _Point / 2.0) // != for doubles.
                {
                    StopLossLineIsBeingMoved = true;
                }
                else StopLossLineIsBeingMoved = false;
            }
            if ((sets.StopLimitDistanceInPoints) && (sets.EntryType == StopLimit))
            {
                double current_sp_line_price = NormalizeDouble(ObjectGetDouble(ChartID(), ObjectPrefix + "StopPriceLine", OBJPROP_PRICE, 0), _Digits);
                if (MathAbs(current_sp_line_price - tStopPriceLevel) > _Point / 2.0) // != for doubles.
                {
                    StopPriceLineIsBeingMoved = true;
                }
                else StopPriceLineIsBeingMoved = false;
            }
            if ((sets.TPDistanceInPoints) || ((ShowATROptions) && (sets.ATRMultiplierTP > 0)))
            {
                ArrayInitialize(TakeProfitLineIsBeingMoved, false);
                double current_line_price = NormalizeDouble(ObjectGetDouble(ChartID(), ObjectPrefix + "TakeProfitLine", OBJPROP_PRICE, 0), _Digits);
                if (MathAbs(current_line_price - tTakeProfitLevel) > _Point / 2.0) // != for doubles.
                {
                    TakeProfitLineIsBeingMoved[0] = true;
                }
                // Additional take-profits.
                else
                {
                    for (int i = 1; i < sets.TakeProfitsNumber; i++) // Will fire only if sets.TakeProfitsNumber > 1.
                    {
                        if (sets.TP[i] != 0) // With zero points TP, keep the TP lines at zero level - as with the main TP level.
                        {
                            current_line_price = NormalizeDouble(ObjectGetDouble(ChartID(), ObjectPrefix + "TakeProfitLine" + IntegerToString(i), OBJPROP_PRICE, 0), _Digits);
                            if (MathAbs(current_line_price - sets.TP[i]) > _Point / 2.0) // != for doubles.
                            {
                                TakeProfitLineIsBeingMoved[i] = true;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    // Clicks on objects that cannot be processed via the class Event Map.
    if (id == CHARTEVENT_OBJECT_CLICK) 
    {
        // Strategy Tester (visual mode) support - the outside Close buttons and their corner switch:
        if ((bool)MQLInfoInteger(MQL_VISUAL_MODE))
        {
            if (StringFind(sparam, "m_BtnOutsideCloseButtonsSwitchButton") >= 0)
            {
                ExtDialog.ProcessOutsideCloseButtonsSwitchClick();
                return;
            }
            else if (StringFind(sparam, "m_BtnOutsideClose") >= 0)
            {
                int start_pos = StringFind(sparam, "m_BtnOutsideClose") + StringLen("m_BtnOutsideClose");
                ExtDialog.ProcessOutsideCloseButtonClick((ulong)StringToInteger(StringSubstr(sparam, start_pos)));
                return;
            }
        }
        // This cannot be done using the panel's event handler because the outside trade button isn't added to its list of controls.
        if (sparam == ExtDialog.Name() + "m_OutsideTradeButton")
        {
            ExtDialog.m_OutsideTradeButton.Pressed(false);
            DoTrade();
        }
        // Setting flags to mark Edit controls as being edited to avoid changing their values during that process:
        else if (sparam == ExtDialog.Name() + "m_EdtPosSize")
        {
            ExtDialog.OnClickEdtPosSize();
        }
        else if (sparam == ExtDialog.Name() + "m_EdtEntryLevel")
        {
            ExtDialog.OnClickEdtEntryLevel();
        }
        else if (sparam == ExtDialog.Name() + "m_EdtSL")
        {
            ExtDialog.OnClickEdtSL();
        }
        else if (sparam == ExtDialog.Name() + "m_EdtTP")
        {
            ExtDialog.OnClickEdtTP();
        }
        else if (sparam == ExtDialog.Name() + "m_EdtAccount")
        {
            ExtDialog.OnClickEdtAccount();
        }
        else if (sparam == ExtDialog.Name() + "m_EdtRiskPIn")
        {
            ExtDialog.OnClickEdtRiskPIn();
        }
        else if (sparam == ExtDialog.Name() + "m_EdtRiskMIn")
        {
            ExtDialog.OnClickEdtRiskMIn();
        }
        else if (StringSubstr(sparam, 0, StringLen(ExtDialog.Name() + "m_EdtAdditionalTPEdits")) == ExtDialog.Name() + "m_EdtAdditionalTPEdits")
        {
            int i = (int)StringToInteger(StringSubstr(sparam, StringLen(ExtDialog.Name() + "m_EdtAdditionalTPEdits"))) - 1;
            ExtDialog.OnClickAdditionalTPEdit(i);
        }
        else if (sparam == ExtDialog.Name() + "m_EdtTradingTPEdit1") // Needed only for the main TP as others aren't updated unless their lines are being moved, which means that the Edits aren't in focus at that time.
        {
            ExtDialog.OnClickEdtTradingTPEdit1();
        }
    }

    if (id == CHARTEVENT_CLICK) // Avoid "sticking" of xxxLineIsBeingMoved variables.
    {
        StopLossLineIsBeingMoved = false;
        StopPriceLineIsBeingMoved = false;
        ArrayInitialize(TakeProfitLineIsBeingMoved, false);
    }

    // Remember the panel's location to have the same location for minimized and maximized states.
    if ((id == CHARTEVENT_CUSTOM + ON_DRAG_END) && (lparam == -1))
    {
        ExtDialog.remember_top = ExtDialog.Top();
        ExtDialog.remember_left = ExtDialog.Left();
    }

    // Catch multiple TP fields.
    if (sets.TakeProfitsNumber > 1)
    {
        if (id == CHARTEVENT_OBJECT_ENDEDIT)
        //if (id == CHARTEVENT_CUSTOM + ON_END_EDIT)
        {
            // Additional take-profit field #N on Main tab.
            if (StringSubstr(sparam, 0, StringLen(ExtDialog.Name() + "m_EdtAdditionalTPEdits")) == ExtDialog.Name() + "m_EdtAdditionalTPEdits")
            {
                int i = (int)StringToInteger(StringSubstr(sparam, StringLen(ExtDialog.Name() + "m_EdtAdditionalTPEdits"))) - 1;
                ExtDialog.UpdateAdditionalTPEdit(i);
            }
            // Take-profit field #N on Trading tab.
            else if (StringSubstr(sparam, 0, StringLen(ExtDialog.Name() + "m_EdtTradingTPEdit")) == ExtDialog.Name() + "m_EdtTradingTPEdit")
            {
                int i = (int)StringToInteger(StringSubstr(sparam, StringLen(ExtDialog.Name() + "m_EdtTradingTPEdit"))) - 1;
                ExtDialog.UpdateTradingTPEdit(i);
            }
            // Take-profit share field #N on Trading tab.
            else if (StringSubstr(sparam, 0, StringLen(ExtDialog.Name() + "m_EdtTradingTPShareEdit")) == ExtDialog.Name() + "m_EdtTradingTPShareEdit")
            {
                int i = (int)StringToInteger(StringSubstr(sparam, StringLen(ExtDialog.Name() + "m_EdtTradingTPShareEdit"))) - 1;
                ExtDialog.UpdateTradingTPShareEdit(i);
            }
        }
        else if (id == CHARTEVENT_CUSTOM + ON_CLICK)
        {
            // Additional take-profit increase button #N on Main tab.
            if (StringSubstr(sparam, 0, StringLen(ExtDialog.Name() + "m_BtnAdditionalTPButtonsIncrease")) == ExtDialog.Name() + "m_BtnAdditionalTPButtonsIncrease")
            {
                int i = (int)StringToInteger(StringSubstr(sparam, StringLen(ExtDialog.Name() + "m_BtnAdditionalTPButtonsIncrease"))) - 1;
                ExtDialog.ProcessAdditionalTPButtonsIncrease(i);
            }
            // Additional take-profit decrease button #N on Main tab.
            else if (StringSubstr(sparam, 0, StringLen(ExtDialog.Name() + "m_BtnAdditionalTPButtonsDecrease")) == ExtDialog.Name() + "m_BtnAdditionalTPButtonsDecrease")
            {
                int i = (int)StringToInteger(StringSubstr(sparam, StringLen(ExtDialog.Name() + "m_BtnAdditionalTPButtonsDecrease"))) - 1;
                ExtDialog.ProcessAdditionalTPButtonsDecrease(i);
            }
            // Because there is a bug that keeps a control's Id() = -1 if it is created after the panel is initialized. So, it cannot be processed with the panel's event processor.
            else if (sparam == ExtDialog.Name() + "m_BtnTakeProfitsNumberRemove")
            {
                ExtDialog.OnClickBtnTakeProfitsNumberRemove();
            }
            else if (sparam == ExtDialog.Name() + "m_BtnTPsInward")
            {
                ExtDialog.OnClickBtnTPsInward();
            }
            else if (sparam == ExtDialog.Name() + "m_BtnTPsOutward")
            {
                ExtDialog.OnClickBtnTPsOutward();
            }
            else if (sparam == ExtDialog.Name() + "m_BtnTradingTPShare")
            {
                ExtDialog.OnClickBtnTradingTPShare();
            }
        }
    }

    if (id == CHARTEVENT_KEYDOWN)
    {
        short key = (short)lparam;
        if (key < 65 || (key > 90 && key < 97) || key > 122) // Not a capital or normal letter.
        {
            // Get Unicode key value.
            key = TranslateKey((int)lparam);
            // In case of failure, use raw value.
            if (key == -1) key = (short)lparam;
        }

        // Trade direction:
        if (HotkeyPressed(Hotkeys[HK_SwitchEntryDirection], key))
        {
            SwitchEntryDirection();
        }
        // Order type:
        else if (HotkeyPressed(Hotkeys[HK_SwitchOrderType], key))
        {
            ExtDialog.OnClickBtnOrderType();
            ChartRedraw();
        }
        // Hide/Show lines:
        else if (HotkeyPressed(Hotkeys[HK_SwitchHideShowLines], key))
        {
            ExtDialog.OnClickBtnLines();
            ChartRedraw();
        }  
        // Trade:
        else if (HotkeyPressed(Hotkeys[HK_Trade], key))
        {
            DoTrade(); 
        }
        // Set stop-loss:
        else if (HotkeyPressed(Hotkeys[HK_SetStopLoss], key))
        {
            // Capture point price location.
            int subwindow;
            double price;
            datetime time; // Dummy.
            ChartXYToTimePrice(ChartID(), Mouse_Last_X, Mouse_Last_Y, subwindow, time, price);
            // If valid, move the SL line there.
            if ((subwindow == 0) && (price > 0))
            {
                if (TickSize > 0) price = NormalizeDouble(MathRound(price / TickSize) * TickSize, _Digits);
                ObjectSetDouble(ChartID(), ObjectPrefix + "StopLossLine", OBJPROP_PRICE, price);
                if ((sets.SLDistanceInPoints) || (ShowATROptions)) ExtDialog.UpdateFixedSL();
                ExtDialog.RefreshValues();
                DoSnapSL();
                ChartRedraw();
            }
        }
        // Set take-profit:
        else if (HotkeyPressed(Hotkeys[HK_SetTakeProfit], key))
        {
            // Capture point price location.
            int subwindow;
            double price;
            datetime time; // Dummy.
            ChartXYToTimePrice(ChartID(), Mouse_Last_X, Mouse_Last_Y, subwindow, time, price);
            // If valid, move the TP line there.
            if ((subwindow == 0) && (price > 0))
            {
                // If "TP locked on SL" mode was on, turn it off.
                if (sets.TPLockedOnSL)
                {
                    sets.TPLockedOnSL = false;
                    ObjectSetInteger(ChartID(), ObjectPrefix + "TakeProfitLine", OBJPROP_SELECTABLE, true);
                    ObjectSetInteger(ChartID(), ObjectPrefix + "TakeProfitLine", OBJPROP_SELECTED, sets.WasSelectedTakeProfitLine);
                    ExtDialog.ResetChkTPLockedOnSL();
                }
                if (TickSize > 0) price = NormalizeDouble(MathRound(price / TickSize) * TickSize, _Digits);
                ObjectSetDouble(ChartID(), ObjectPrefix + "TakeProfitLine", OBJPROP_PRICE, price);
                if (sets.ShowLines) ObjectSetInteger(ChartID(), ObjectPrefix + "TakeProfitLine", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
                if ((sets.TPDistanceInPoints) || (ShowATROptions)) ExtDialog.UpdateFixedTP();
                ExtDialog.ShowTPRelatedEdits();
                ExtDialog.RefreshValues();
                if ((PrefillAdditionalTPsBasedOnMain) && (sets.TakeProfitsNumber > 1))
                {
                    ExtDialog.DoPrefillAdditionalTPsBasedOnMain();
                }
                ExtDialog.HideShowMaximize();
                ExtDialog.MoveAndResize();
            }
        }
        // Set entry:
        else if (HotkeyPressed(Hotkeys[HK_SetEntry], key))
        {
            // Capture point price location.
            int subwindow;
            double price;
            datetime time; // Dummy.
            ChartXYToTimePrice(ChartID(), Mouse_Last_X, Mouse_Last_Y, subwindow, time, price);
            // If valid, move the Entry line there and switch from Instant to Pending if necessary.
            if ((subwindow == 0) && (price > 0))
            {
                if (TickSize > 0) price = NormalizeDouble(MathRound(price / TickSize) * TickSize, _Digits);
                ObjectSetDouble(ChartID(), ObjectPrefix + "EntryLine", OBJPROP_PRICE, price);
                if (sets.EntryType == Instant)
                {
                    ExtDialog.OnClickBtnOrderType(); // Includes RefreshValues().
                }
                else ExtDialog.RefreshValues();
                DoSnapEntry();
                ChartRedraw();
            }
        }
        // Minimize/maximize:
        else if (HotkeyPressed(Hotkeys[HK_MinimizeMaximize], key))
        {
            ExtDialog.EmulateMinMaxClick();
        }
        // Switch SL between points and level:
        else if (HotkeyPressed(Hotkeys[HK_SwitchSLPointsLevel], key))
        {
            if (sets.SLDistanceInPoints) sets.SLDistanceInPoints = false; // If was in points, set to level.
            else
            {
                sets.SLDistanceInPoints = true; // If was in level, set to points.
                sets.StopLoss = (int)MathRound(MathAbs(sets.StopLossLevel - sets.EntryLevel) / _Point);
            }
            ExtDialog.UpdateSLLabelText(); // The label's (or button's) text differs between the level and points modes.
            ExtDialog.RefreshValues();
        }
        // Switch TP between points and level:
        else if (HotkeyPressed(Hotkeys[HK_SwitchTPPointsLevel], key))
        {
            if (sets.TPDistanceInPoints) sets.TPDistanceInPoints = false; // If was in points, set to level.
            else
            {
                sets.TPDistanceInPoints = true; // If was in level, set to points.
                if (sets.TakeProfitLevel != 0) sets.TakeProfit = (int)MathRound(MathAbs(sets.TakeProfitLevel - sets.EntryLevel) / _Point);
                // Additional take-profits.
                if (sets.TakeProfitsNumber > 1)
                {
                    for (int i = 1; i < sets.TakeProfitsNumber; i++)
                    {
                        if (sets.TP[i] != 0) // With zero points TP, keep the TP lines at zero level - as with the main TP level.
                        {
                            if (sets.TP[i] != 0) ExtDialog.AdditionalTPEdits[i - 1].Text(DoubleToString(MathAbs(MathRound((sets.TP[i] - sets.EntryLevel) / _Point)), 0));
                        }
                    }
                }
            }
            ExtDialog.RefreshValues();
        }
        else if (HotkeyPressed(Hotkeys[HK_SetTPGoal], key))
        {
            DoSetTPToEquityGoal();
        }
        else if (HotkeyPressed(Hotkeys[HK_ContinuationBreakout], key))
        {
            DoToggleContinuationBreakout();
        }
        else if (HotkeyPressed(Hotkeys[HK_FindClosestSL], key))
        {
            if (CustomSafeTicks > 0) {
                if (sets.TradeDirection == Long) {
                    ExtDialog.m_EdtSL.Text(DoubleToString(sets.StopLossLevel - (CustomSafeTicks * _Point), _Digits));
                    ExtDialog.OnEndEditEdtSL();
                }
                else {
                    ExtDialog.m_EdtSL.Text(DoubleToString(sets.StopLossLevel + (CustomSafeTicks * _Point), _Digits));
                    ExtDialog.OnEndEditEdtSL();
                }
            }
        }
        // Switch stop-limit price between points and level:
        else if (HotkeyPressed(Hotkeys[HK_SwitchStopLimitPointsLevel], key))
        {
            if (sets.StopLimitDistanceInPoints) sets.StopLimitDistanceInPoints = false; // If was in points, set to level.
            else
            {
                sets.StopLimitDistanceInPoints = true; // If was in level, set to points.
                sets.StopLimit = (int)MathRound(MathAbs(sets.StopPriceLevel - sets.EntryLevel) / _Point);
            }
            ExtDialog.RefreshValues();
        }
    }

    // Call Panel's event handler only if it is not a CHARTEVENT_CHART_CHANGE - workaround for minimization bug on chart switch.
    if (id != CHARTEVENT_CHART_CHANGE)
    {
        ExtDialog.OnEvent(id, lparam, dparam, sparam);
        if (id >= CHARTEVENT_CUSTOM) ChartRedraw();
    }

    // Recalculate on chart changes, clicks, and certain object dragging.
    if ((id == CHARTEVENT_CLICK) || (id == CHARTEVENT_CHART_CHANGE) ||
            ((id == CHARTEVENT_OBJECT_DRAG) && ((sparam == ObjectPrefix + "EntryLine") || (sparam == ObjectPrefix + "StopLossLine") || (StringFind(sparam, ObjectPrefix + "TakeProfitLine") != -1) || (sparam == ObjectPrefix + "StopPriceLine"))))
    {
        if (id == CHARTEVENT_OBJECT_DRAG)
        {
            // Moving lines when fixed SL/TP distance is enabled. Should set a new fixed SL/TP distance.
            if ((sets.SLDistanceInPoints) || (sets.TPDistanceInPoints) || (sets.StopLimitDistanceInPoints) || (ShowATROptions))
            {
                if (sparam == ObjectPrefix + "StopLossLine") ExtDialog.UpdateFixedSL();
                else if (sparam == ObjectPrefix + "TakeProfitLine") ExtDialog.UpdateFixedTP();
                else if ((sets.StopLimitDistanceInPoints) && (sparam == ObjectPrefix + "StopPriceLine")) ExtDialog.UpdateFixedStopLimit();
                else if ((sets.TakeProfitsNumber > 1) && (StringFind(sparam, ObjectPrefix + "TakeProfitLine") != -1))
                {
                    int len = StringLen(ObjectPrefix + "TakeProfitLine");
                    int i = (int)StringToInteger(StringSubstr(sparam, len));
                    if (i >= 1) ExtDialog.UpdateAdditionalFixedTP(i); // Prevents accessing AdditionalTPEdits[] at -1 if a stray object with a similar name is found.
                }
            }
            // Update required for additional TP fields on the Trading panel.
            if ((!sets.TPDistanceInPoints) && (sets.TakeProfitsNumber > 1) && (StringFind(sparam, ObjectPrefix + "TakeProfitLine") != -1))
            {
                AdditionalTPLineMoved = true; // Will refresh the .Text of the Trading panel's respective TP Edit in DisplayValues().
            }
        }

        if (sparam == ObjectPrefix + "StopLossLine") StopLossLineIsBeingMoved = false; // In any case ending moving state for the stop-loss line.
        if (sparam == ObjectPrefix + "StopPriceLine") StopPriceLineIsBeingMoved = false; // In any case ending moving state for the stop price line.
        if (StringFind(sparam, ObjectPrefix + "TakeProfitLine") != -1) ArrayInitialize(TakeProfitLineIsBeingMoved, false); // In any case ending moving state for the take-profit line.

        if (id == CHARTEVENT_CHART_CHANGE) ChartWidth = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        else ExtDialog.RefreshValues();

        static bool prev_chart_on_top = false;
        // If this is an active chart, make sure the panel is visible (not behind the chart's borders). For inactive chart, this will work poorly, because inactive charts get minimized by MetaTrader.
        if (ChartGetInteger(ChartID(), CHART_BRING_TO_TOP))
        {
            if (ExtDialog.Top() < 0) ExtDialog.Move(ExtDialog.Left(), 0);
            int chart_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
            if (ExtDialog.Top() > chart_height) ExtDialog.Move(ExtDialog.Left(), chart_height - ExtDialog.Height());
            int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            if (ExtDialog.Left() > chart_width) ExtDialog.Move(chart_width - ExtDialog.Width(), ExtDialog.Top());
            // If chart was brought on top, refresh values to move labels.
            if ((prev_chart_on_top == false) && ((ShowMainLineLabels) || (ShowAdditionalEntryLabel) || (ShowAdditionalTPLabel) || (ShowAdditionalSLLabel))) ExtDialog.RefreshValues();
        }
        // Remember if the chart is on top or is minimized.
        prev_chart_on_top = ChartGetInteger(ChartID(), CHART_BRING_TO_TOP);
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//| Trade event handler                                              |
//+------------------------------------------------------------------+
void OnTrade()
{
    ExtDialog.RefreshValues();
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Trade transaction handler                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
    if (trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
    DoCancelOppositeOrders(trans.deal);
    CBOnDealAdd(trans.deal);
}

// One-cancels-other: once a deal opens a position, delete pending orders of the opposite direction on this symbol.
void DoCancelOppositeOrders(const ulong deal)
{
    if (!CustomOCOEnabled) return;
    if (!HistoryDealSelect(deal)) return;
    if (HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol) return;
    if ((sets.MagicNumber != 0) && (HistoryDealGetInteger(deal, DEAL_MAGIC) != sets.MagicNumber)) return;

    ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
    if ((entry != DEAL_ENTRY_IN) && (entry != DEAL_ENTRY_INOUT)) return;

    ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
    if ((deal_type != DEAL_TYPE_BUY) && (deal_type != DEAL_TYPE_SELL)) return;
    bool filled_buy = (deal_type == DEAL_TYPE_BUY);

    CTrade trade;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket == 0) continue;
        if (OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
        if ((sets.MagicNumber != 0) && (OrderGetInteger(ORDER_MAGIC) != sets.MagicNumber)) continue;

        ENUM_ORDER_TYPE order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
        bool is_sell_pending = (order_type == ORDER_TYPE_SELL_STOP) || (order_type == ORDER_TYPE_SELL_LIMIT) || (order_type == ORDER_TYPE_SELL_STOP_LIMIT);
        bool is_buy_pending = (order_type == ORDER_TYPE_BUY_STOP) || (order_type == ORDER_TYPE_BUY_LIMIT) || (order_type == ORDER_TYPE_BUY_STOP_LIMIT);
        if ((filled_buy && !is_sell_pending) || (!filled_buy && !is_buy_pending)) continue;

        if (trade.OrderDelete(ticket)) Print("OCO: ", (filled_buy ? "Buy" : "Sell"), " filled. Cancelled opposite pending order #", ticket, ".");
        else Print("OCO: Failed to cancel pending order #", ticket, ". Error: ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
    /**
     * Release resource 50ms to prevent freeze
     * when change symbols or close Position Sizer
     * */
    if (GetTickCount64() - LastRecalculationTime < 50) return; 
    ExtDialog.CheckAndRestoreLines(); // Check if any lines should be restored.
    if (GetTickCount64() - LastRecalculationTime < 1000) return; // Do not recalculate on timer if less than 1 second passed.
    ExtDialog.RefreshValues();
    ChartRedraw();
}

// true = dark mode
// false = light mode
bool DetectDarkMode()
{
    string theme = TerminalInfoString(TERMINAL_COLORTHEME_NAME);
    if (theme == "Dark") return true;
    if (theme == "Light") return false;
    // "System":
    color window_color = (color)TerminalInfoInteger(THEME_COLOR_WINDOW);
    if (window_color == clrWhite) return false;
    return true;
}
//+------------------------------------------------------------------+
