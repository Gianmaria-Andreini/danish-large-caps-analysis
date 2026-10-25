"""
Download daily prices and annual fundamentals for 8 large Danish companies
and the OMXC25 index from Yahoo Finance, and save them as CSV files ready
to import into PostgreSQL.

Run in the project folder:
    pip3 install yfinance pandas
    python3 download_data.py

Output (folder "data"): companies.csv, prices.csv, fundamentals.csv
"""
from pathlib import Path

import pandas as pd
import yfinance as yf

START = "2019-01-01"

COMPANIES = [
    # (Yahoo ticker, name, sector)
    ("NOVO-B.CO", "Novo Nordisk", "Healthcare"),
    ("MAERSK-B.CO", "A.P. Moller - Maersk", "Shipping & Logistics"),
    ("DSV.CO", "DSV", "Shipping & Logistics"),
    ("CARL-B.CO", "Carlsberg", "Consumer Staples"),
    ("PNDORA.CO", "Pandora", "Consumer Discretionary"),
    ("VWS.CO", "Vestas Wind Systems", "Energy & Utilities"),
    ("ORSTED.CO", "Orsted", "Energy & Utilities"),
    ("DANSKE.CO", "Danske Bank", "Financials"),
]
INDEX = ("^OMXC25", "OMX Copenhagen 25", "Index")

# Rows to take from Yahoo's annual income statement (first match wins)
FIELDS = {
    "revenue": ["Total Revenue", "Operating Revenue"],
    "ebit": ["EBIT", "Operating Income"],
    "net_income": ["Net Income", "Net Income Common Stockholders"],
    "diluted_shares": ["Diluted Average Shares", "Basic Average Shares"],
}

out = Path("data")
out.mkdir(exist_ok=True)


def first_row(statement, names):
    for name in names:
        if name in statement.index:
            return statement.loc[name]
    return None


# 1. Companies
companies = pd.DataFrame(COMPANIES + [INDEX], columns=["ticker", "name", "sector"])
companies.to_csv(out / "companies.csv", index=False)

# 2. Daily prices
price_frames = []
for ticker, name, _ in COMPANIES + [INDEX]:
    hist = yf.Ticker(ticker).history(start=START, auto_adjust=False, actions=False)
    if hist.empty:
        print(f"WARNING: no prices for {ticker} ({name})")
        continue
    hist = hist.reset_index()
    df = pd.DataFrame({
        "ticker": ticker,
        "trade_date": hist["Date"].dt.date,
        "open": hist["Open"].round(4),
        "high": hist["High"].round(4),
        "low": hist["Low"].round(4),
        "close": hist["Close"].round(4),
        "adj_close": hist["Adj Close"].round(4),
        "volume": hist["Volume"].astype("int64"),
    })
    price_frames.append(df)
    print(f"{ticker:12} {len(df):5} days  {df.trade_date.min()} -> {df.trade_date.max()}")

prices = pd.concat(price_frames, ignore_index=True)
prices.to_csv(out / "prices.csv", index=False)

# 3. Annual fundamentals (Yahoo usually has the last 4-5 fiscal years)
fund_rows = []
for ticker, name, _ in COMPANIES:
    t = yf.Ticker(ticker)
    stmt = t.income_stmt  # columns = fiscal year end dates
    try:
        currency = t.info.get("financialCurrency")
    except Exception:
        currency = None
    dividends = t.dividends
    div_by_year = dividends.groupby(dividends.index.year).sum() if not dividends.empty else {}

    if stmt is None or stmt.empty:
        print(f"WARNING: no income statement for {ticker} ({name})")
        continue
    for col in stmt.columns:
        row = {"ticker": ticker, "fiscal_year": col.year, "currency": currency}
        for field, names in FIELDS.items():
            series = first_row(stmt, names)
            value = series[col] if series is not None else None
            row[field] = None if pd.isna(value) else float(value)
        row["dividends_paid_per_share"] = float(div_by_year.get(col.year, 0.0))
        fund_rows.append(row)

fundamentals = pd.DataFrame(fund_rows).sort_values(["ticker", "fiscal_year"])
fundamentals.to_csv(out / "fundamentals.csv", index=False)

print(f"\nSaved {len(prices)} price rows and {len(fundamentals)} fundamental rows in {out.resolve()}")
print("Check: missing values per column in fundamentals:")
print(fundamentals.isna().sum())
