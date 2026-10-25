"""
Convert the two CSV exports from PostgreSQL into one Excel file for Power BI.

Why: the Power BI service (browser) imports Excel files from the computer,
but not CSV files. Power BI Desktop, which reads CSV directly, does not run on macOS.

Run in the project folder:
    python3 csv_to_excel.py

Input:  exports/dashboard_daily.csv, exports/dashboard_summary.csv
Output: exports/danish_large_caps.xlsx (two sheets, each formatted as an Excel table)
"""
from pathlib import Path

import pandas as pd
from openpyxl.worksheet.table import Table, TableStyleInfo
from openpyxl.utils import get_column_letter

folder = Path("exports")
sheets = {
    "daily": pd.read_csv(folder / "dashboard_daily.csv", parse_dates=["trade_date"]),
    "summary": pd.read_csv(folder / "dashboard_summary.csv", parse_dates=["max_drawdown_date"]),
}
output = folder / "danish_large_caps.xlsx"

with pd.ExcelWriter(output, engine="openpyxl") as writer:
    for name, df in sheets.items():
        df.to_excel(writer, sheet_name=name, index=False)
        ws = writer.sheets[name]
        last_cell = f"{get_column_letter(df.shape[1])}{df.shape[0] + 1}"
        table = Table(displayName=name, ref=f"A1:{last_cell}")
        table.tableStyleInfo = TableStyleInfo(name="TableStyleMedium2", showRowStripes=True)
        ws.add_table(table)
        print(f"{name:8} {df.shape[0]:6} rows, {df.shape[1]} columns")

print(f"Saved {output.resolve()}")
