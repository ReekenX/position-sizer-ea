# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Position Sizer Expert Advisor (EA) for MetaTrader 5, developed by EarnForex.com. It's a risk management tool that automatically calculates position sizes based on risk tolerance, account parameters, and various trading settings.

## Important Rules

- **NEVER modify anything in the MQL4 folder** - MT4 support is deprecated and we don't care about it anymore
- **Only modify `.mq5` and `.mqh` files** - Do not modify `.ex5` or any other file types
- **Most modifications will happen in these two files:**
  - `MQL5/Experts/Position Sizer/Position Sizer.mq5` - Main EA entry point
  - `MQL5/Experts/Position Sizer/Position Sizer.mqh` - Panel implementation and core logic

## Development Commands

### Building and Compilation

MetaTrader uses MQL5 language which is compiled within the MetaTrader platform itself:

- **Files**: Located in `MQL5/Experts/Position Sizer/`
- Compilation is done through MetaTrader's built-in MetaEditor
- The main source file is `Position Sizer.mq5`
- Compiled output: `Position Sizer.ex5`

### Testing

- Testing is performed through MetaTrader's Strategy Tester
- No external unit testing framework is available for MQL code
- Manual testing on demo accounts is recommended before live deployment

### MQL5 Documentation

For MQL5 language reference, trading functions, and technical documentation, use: https://www.mql5.com/en/docs/trading

## High-Level Architecture

### Core Components

1. **Main Entry File** (`Position Sizer.mq5`)
   - Main EA entry point with input parameters and initialization
   - Contains custom variables for trading logic (e.g., `CustomTPMultiplier`, `CustomEquityGoal`, `CustomWebCommandDomain`)

2. **Panel Implementation** (`Position Sizer.mqh`)
   - `CPositionSizeCalculator` class: Main panel UI and calculation logic
   - Manages multiple tabs: Main, Risk, Margin, Swaps, Trading
   - Handles line objects for Entry, Stop Loss, Take Profit levels
   - Implements position size calculations based on risk parameters

3. **Trading Module** (`Position Sizer Trading.mqh`)
   - Contains trade execution logic
   - Manages order placement, modification, and closing
   - Handles multiple take-profit levels
   - Implements trailing stop and break-even functionality

4. **Supporting Files**
   - `Defines.mqh`: Constants, enumerations, and global definitions
   - `errordescription.mqh`: Error code descriptions
   - `Translations/`: Multi-language support files

### Key Features

- **Risk-based position sizing**: Calculates lot size based on account risk percentage or fixed monetary risk
- **Multiple take-profit levels**: Supports splitting positions across multiple TP targets
- **ATR-based SL/TP**: Can set stops and targets using Average True Range
- **Portfolio risk management**: Tracks current and potential portfolio exposure
- **Web integration**: Custom web command functionality for external integrations
- **Scaling logic**: Custom position scaling based on price movements

### Custom Modifications

The codebase includes custom modifications from the original EarnForex version:
- Custom equity goal setting (Press 'G' to set TP)
- Web command integration for external systems
- Position scaling logic with `AlreadyScaled` and `AlreadyUpdatedSL` flags
- Price-based position cancellation (`CancelAtPrice`)
- Custom trade signal handling

### Important Notes

- The EA uses visual line objects on the chart for interactive parameter adjustment
- Settings are persisted to disk using INI files
- The panel can be minimized/maximized and remembers its state
- Supports both instant and pending order types
- Includes comprehensive margin and swap calculations