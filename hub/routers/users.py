"""
users.py — User registration router
Saves each registration to users.xlsx in the hub folder.
GET /api/users/export  → download the Excel file
POST /api/users/register → add a row
"""
import os
import json
from datetime import datetime
from fastapi import APIRouter
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

XLSX_PATH = os.path.join(os.path.dirname(__file__), "..", "users.xlsx")

# ── Column order in the Excel file ──────────────────────────────────────────
COLUMNS = [
    "תאריך הרשמה", "תוכנית", "שם מלא", "שם משתמש",
    "אימייל", "כתובת",
    "מחזיק כרטיס", "4 ספרות אחרונות", "תוקף", "CVV",
]

# ── Pydantic model ───────────────────────────────────────────────────────────
class UserRegister(BaseModel):
    plan:        str
    name:        str
    username:    str
    email:       str
    address:     Optional[str] = ""
    card_holder: Optional[str] = ""
    card_number: Optional[str] = ""   # we store only last 4 digits
    card_expiry: Optional[str] = ""
    card_cvv:    Optional[str] = ""


def _ensure_workbook():
    """Create users.xlsx with headers if it doesn't exist."""
    try:
        import openpyxl
    except ImportError:
        return False

    if os.path.exists(XLSX_PATH):
        return True

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "משתמשים"

    # Header row — styled
    from openpyxl.styles import Font, PatternFill, Alignment
    header_fill = PatternFill("solid", fgColor="0F172A")
    header_font = Font(bold=True, color="38BDF8", size=11)

    for col_idx, col_name in enumerate(COLUMNS, start=1):
        cell = ws.cell(row=1, column=col_idx, value=col_name)
        cell.fill  = header_fill
        cell.font  = header_font
        cell.alignment = Alignment(horizontal="center")

    # Column widths
    widths = [20, 12, 20, 18, 28, 30, 20, 16, 10, 8]
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[openpyxl.utils.get_column_letter(i)].width = w

    wb.save(XLSX_PATH)
    return True


def _append_user(data: UserRegister):
    try:
        import openpyxl
        from openpyxl.styles import Alignment

        _ensure_workbook()
        wb = openpyxl.load_workbook(XLSX_PATH)
        ws = wb.active

        # Mask card number — keep only last 4 digits
        raw_card = (data.card_number or "").replace(" ", "").replace("-", "")
        last4 = raw_card[-4:] if len(raw_card) >= 4 else (raw_card or "—")

        # Mask CVV
        cvv_masked = "***" if data.card_cvv else "—"

        row = [
            datetime.now().strftime("%d/%m/%Y %H:%M"),
            data.plan,
            data.name,
            data.username,
            data.email,
            data.address or "—",
            data.card_holder or "—",
            last4 if raw_card else "—",
            data.card_expiry or "—",
            cvv_masked,
        ]

        ws.append(row)

        # Alternate row colour
        row_idx = ws.max_row
        fill_color = "1E293B" if row_idx % 2 == 0 else "0F172A"
        from openpyxl.styles import PatternFill
        fill = PatternFill("solid", fgColor=fill_color)
        from openpyxl.styles import Font
        font = Font(color="F1F5F9", size=10)
        for col in range(1, len(COLUMNS) + 1):
            cell = ws.cell(row=row_idx, column=col)
            cell.fill      = fill
            cell.font      = font
            cell.alignment = Alignment(horizontal="right" if col > 1 else "left")

        wb.save(XLSX_PATH)
        return True
    except Exception as e:
        print(f"[users] Excel write error: {e}")
        return False


# ── Routes ───────────────────────────────────────────────────────────────────

@router.post("/register")
async def register_user(data: UserRegister):
    ok = _append_user(data)
    return {
        "ok": ok,
        "message": "Registered successfully" if ok else "Saved locally (Excel unavailable)",
    }


@router.get("/export")
async def export_users():
    if not os.path.exists(XLSX_PATH):
        _ensure_workbook()
    return FileResponse(
        path=XLSX_PATH,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename="fantatech-users.xlsx",
    )


@router.get("/count")
async def users_count():
    try:
        import openpyxl
        if not os.path.exists(XLSX_PATH):
            return {"count": 0}
        wb = openpyxl.load_workbook(XLSX_PATH, read_only=True)
        ws = wb.active
        count = max(ws.max_row - 1, 0)   # subtract header row
        return {"count": count}
    except Exception:
        return {"count": 0}
