const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, BorderStyle, WidthType, ShadingType,
  PageNumber, Header, Footer, LevelFormat, PageBreak, HeadingLevel
} = require('docx');
const fs = require('fs');

const ORANGE = 'FF6B00';
const DARK   = '1A1A2E';
const BLUE   = '1D75BD';
const GREEN  = '1B5E20';
const RED    = 'B71C1C';
const LGRAY  = 'F7F7F7';
const MGRAY  = 'E0E0E0';
const WHITE  = 'FFFFFF';
const WARN   = 'FFF8E1';
const WARNB  = 'F9A825';
const INFOB  = 'E3F2FD';
const INFOC  = '1565C0';
const SUCCB  = 'E8F5E9';
const SUCCC  = '2E7D32';

const b  = (c=MGRAY) => ({ style: BorderStyle.SINGLE, size: 1, color: c });
const bs = (c=MGRAY) => ({ top: b(c), bottom: b(c), left: b(c), right: b(c) });
const nb = () => ({ style: BorderStyle.NONE, size: 0, color: WHITE });
const nbs = () => ({ top: nb(), bottom: nb(), left: nb(), right: nb() });

// ─── Helpers ────────────────────────────────────────────────────────────────

function sp(before=120, after=0) {
  return new Paragraph({ spacing:{before,after}, children:[new TextRun('')] });
}

function h1(text) {
  return new Paragraph({
    spacing: { before:400, after:120 },
    border: { bottom: { style: BorderStyle.SINGLE, size:10, color:ORANGE, space:6 } },
    children: [new TextRun({ text, bold:true, size:44, color:ORANGE, font:'Arial' })]
  });
}

function h2(text) {
  return new Paragraph({
    spacing: { before:280, after:80 },
    children: [new TextRun({ text, bold:true, size:30, color:DARK, font:'Arial' })]
  });
}

function h3(text) {
  return new Paragraph({
    spacing: { before:200, after:60 },
    children: [new TextRun({ text, bold:true, size:24, color:BLUE, font:'Arial' })]
  });
}

function body(text, color=DARK) {
  return new Paragraph({
    alignment: AlignmentType.RIGHT,
    spacing: { before:60, after:40 },
    children: [new TextRun({ text, size:21, font:'Arial', color })]
  });
}

function bullet(text, bold=false) {
  return new Paragraph({
    alignment: AlignmentType.RIGHT,
    spacing: { before:40, after:40 },
    numbering: { reference:'bullets', level:0 },
    children: [new TextRun({ text, size:21, font:'Arial', color:DARK, bold })]
  });
}

function numbered(text) {
  return new Paragraph({
    alignment: AlignmentType.RIGHT,
    spacing: { before:50, after:50 },
    numbering: { reference:'steps', level:0 },
    children: [new TextRun({ text, size:21, font:'Arial', color:DARK })]
  });
}

// Code block
function code(lines) {
  return new Table({
    width: { size:9026, type:WidthType.DXA },
    columnWidths: [9026],
    rows: [new TableRow({ children: [new TableCell({
      width: { size:9026, type:WidthType.DXA },
      borders: bs('333333'),
      shading: { fill:'1E1E1E', type:ShadingType.CLEAR },
      margins: { top:120, bottom:120, left:200, right:200 },
      children: lines.map(l => new Paragraph({
        alignment: AlignmentType.LEFT,
        spacing: { before:30, after:30 },
        children: [new TextRun({ text:l, size:19, font:'Courier New', color:'E0E0E0' })]
      }))
    })]})],
  });
}

// Warning box
function warn(title, lines) {
  return new Table({
    width:{ size:9026, type:WidthType.DXA },
    columnWidths:[400,8626],
    rows:[new TableRow({ children:[
      new TableCell({
        width:{size:400,type:WidthType.DXA},
        borders: bs(WARNB),
        shading:{ fill:WARNB, type:ShadingType.CLEAR },
        margins:{top:120,bottom:120,left:80,right:80},
        children:[new Paragraph({ alignment:AlignmentType.CENTER,
          children:[new TextRun({text:'!', bold:true, size:36, color:WHITE, font:'Arial'})] })]
      }),
      new TableCell({
        width:{size:8626,type:WidthType.DXA},
        borders: bs(WARNB),
        shading:{ fill:WARN, type:ShadingType.CLEAR },
        margins:{top:100,bottom:100,left:160,right:160},
        children:[
          new Paragraph({ alignment:AlignmentType.RIGHT,
            children:[new TextRun({text:title, bold:true, size:22, color:'7B4800', font:'Arial'})] }),
          ...lines.map(l=>new Paragraph({ alignment:AlignmentType.RIGHT,
            spacing:{before:30},
            children:[new TextRun({text:l, size:20, font:'Arial', color:'5D4037'})] }))
        ]
      })
    ]})]
  });
}

// Info box
function info(title, lines) {
  return new Table({
    width:{ size:9026, type:WidthType.DXA },
    columnWidths:[400,8626],
    rows:[new TableRow({ children:[
      new TableCell({
        width:{size:400,type:WidthType.DXA},
        borders: bs(INFOC),
        shading:{ fill:INFOC, type:ShadingType.CLEAR },
        margins:{top:120,bottom:120,left:80,right:80},
        children:[new Paragraph({ alignment:AlignmentType.CENTER,
          children:[new TextRun({text:'i', bold:true, size:32, color:WHITE, font:'Arial'})] })]
      }),
      new TableCell({
        width:{size:8626,type:WidthType.DXA},
        borders: bs(INFOC),
        shading:{ fill:INFOB, type:ShadingType.CLEAR },
        margins:{top:100,bottom:100,left:160,right:160},
        children:[
          new Paragraph({ alignment:AlignmentType.RIGHT,
            children:[new TextRun({text:title, bold:true, size:22, color:INFOC, font:'Arial'})] }),
          ...lines.map(l=>new Paragraph({ alignment:AlignmentType.RIGHT,
            spacing:{before:30},
            children:[new TextRun({text:l, size:20, font:'Arial', color:'1A237E'})] }))
        ]
      })
    ]})]
  });
}

// Success box
function success(title, lines) {
  return new Table({
    width:{ size:9026, type:WidthType.DXA },
    columnWidths:[400,8626],
    rows:[new TableRow({ children:[
      new TableCell({
        width:{size:400,type:WidthType.DXA},
        borders: bs(SUCCC),
        shading:{ fill:SUCCC, type:ShadingType.CLEAR },
        margins:{top:120,bottom:120,left:80,right:80},
        children:[new Paragraph({ alignment:AlignmentType.CENTER,
          children:[new TextRun({text:'OK', bold:true, size:22, color:WHITE, font:'Arial'})] })]
      }),
      new TableCell({
        width:{size:8626,type:WidthType.DXA},
        borders: bs(SUCCC),
        shading:{ fill:SUCCB, type:ShadingType.CLEAR },
        margins:{top:100,bottom:100,left:160,right:160},
        children:[
          new Paragraph({ alignment:AlignmentType.RIGHT,
            children:[new TextRun({text:title, bold:true, size:22, color:GREEN, font:'Arial'})] }),
          ...lines.map(l=>new Paragraph({ alignment:AlignmentType.RIGHT,
            spacing:{before:30},
            children:[new TextRun({text:l, size:20, font:'Arial', color:'1B5E20'})] }))
        ]
      })
    ]})]
  });
}

// Step header (numbered section)
function stepHeader(num, title, sub) {
  return new Table({
    width:{ size:9026, type:WidthType.DXA },
    columnWidths:[900,8126],
    rows:[new TableRow({ children:[
      new TableCell({
        width:{size:900,type:WidthType.DXA},
        borders: nbs(),
        shading:{ fill:ORANGE, type:ShadingType.CLEAR },
        margins:{top:140,bottom:140,left:120,right:120},
        children:[
          new Paragraph({ alignment:AlignmentType.CENTER,
            children:[new TextRun({text:`0${num}`, bold:true, size:48, color:WHITE, font:'Arial'})] }),
        ]
      }),
      new TableCell({
        width:{size:8126,type:WidthType.DXA},
        borders: nbs(),
        shading:{ fill:'FFF3E0', type:ShadingType.CLEAR },
        margins:{top:120,bottom:120,left:180,right:180},
        children:[
          new Paragraph({ alignment:AlignmentType.RIGHT,
            children:[new TextRun({text:title, bold:true, size:34, color:ORANGE, font:'Arial'})] }),
          new Paragraph({ alignment:AlignmentType.RIGHT, spacing:{before:40},
            children:[new TextRun({text:sub, size:20, color:'666666', font:'Arial'})] }),
        ]
      })
    ]})]
  });
}

// Simple 2-col table
function simpleTable(cols, rows) {
  const totalW = cols.reduce((s,c)=>s+c.w,0);
  return new Table({
    width:{ size:totalW, type:WidthType.DXA },
    columnWidths: cols.map(c=>c.w),
    rows:[
      new TableRow({ tableHeader:true, children: cols.map(c=>
        new TableCell({
          width:{size:c.w,type:WidthType.DXA}, borders:bs(MGRAY),
          shading:{fill:DARK,type:ShadingType.CLEAR},
          margins:{top:90,bottom:90,left:130,right:130},
          children:[new Paragraph({ alignment:AlignmentType.CENTER,
            children:[new TextRun({text:c.label, bold:true, size:20, color:WHITE, font:'Arial'})] })]
        })
      )}),
      ...rows.map((r,ri)=>new TableRow({ children: r.map((cell,ci)=>
        new TableCell({
          width:{size:cols[ci].w,type:WidthType.DXA}, borders:bs(MGRAY),
          shading:{fill: ri%2===0?WHITE:LGRAY, type:ShadingType.CLEAR},
          margins:{top:80,bottom:80,left:130,right:130},
          children:[new Paragraph({ alignment: ci===0?AlignmentType.RIGHT:AlignmentType.CENTER,
            children:[new TextRun({text:cell, size:20, font:'Arial', color:DARK})] })]
        })
      )}))
    ]
  });
}

// Checklist table
function checklist(items) {
  return new Table({
    width:{size:9026,type:WidthType.DXA},
    columnWidths:[700,8326],
    rows: items.map((item,i)=>new TableRow({ children:[
      new TableCell({
        width:{size:700,type:WidthType.DXA}, borders:bs(MGRAY),
        shading:{fill: i%2===0?WHITE:LGRAY, type:ShadingType.CLEAR},
        margins:{top:80,bottom:80,left:100,right:100},
        children:[new Paragraph({ alignment:AlignmentType.CENTER,
          children:[new TextRun({text:'[ ]', size:20, font:'Courier New', color:'888888'})] })]
      }),
      new TableCell({
        width:{size:8326,type:WidthType.DXA}, borders:bs(MGRAY),
        shading:{fill: i%2===0?WHITE:LGRAY, type:ShadingType.CLEAR},
        margins:{top:80,bottom:80,left:160,right:160},
        children:[new Paragraph({ alignment:AlignmentType.RIGHT,
          children:[new TextRun({text:item, size:20, font:'Arial', color:DARK})] })]
      })
    ]}))
  });
}

// =============================================================================

const doc = new Document({
  styles: {
    default: { document: { run: { font:'Arial', size:22 } } },
    paragraphStyles: [
      { id:'Heading1', name:'Heading 1', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{ size:44, bold:true, font:'Arial', color:ORANGE },
        paragraph:{ spacing:{before:400,after:120}, outlineLevel:0 } },
      { id:'Heading2', name:'Heading 2', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{ size:30, bold:true, font:'Arial', color:DARK },
        paragraph:{ spacing:{before:280,after:80}, outlineLevel:1 } },
    ]
  },
  numbering: {
    config: [
      { reference:'bullets', levels:[{ level:0, format:LevelFormat.BULLET, text:'•',
          alignment:AlignmentType.RIGHT,
          style:{ paragraph:{ indent:{left:560,hanging:280} } } }] },
      { reference:'steps', levels:[{ level:0, format:LevelFormat.DECIMAL, text:'%1.',
          alignment:AlignmentType.RIGHT,
          style:{ paragraph:{ indent:{left:560,hanging:280} } } }] },
      { reference:'steps2', levels:[{ level:0, format:LevelFormat.DECIMAL, text:'%1.',
          alignment:AlignmentType.RIGHT,
          style:{ paragraph:{ indent:{left:560,hanging:280} } } }] },
      { reference:'steps3', levels:[{ level:0, format:LevelFormat.DECIMAL, text:'%1.',
          alignment:AlignmentType.RIGHT,
          style:{ paragraph:{ indent:{left:560,hanging:280} } } }] },
      { reference:'steps4', levels:[{ level:0, format:LevelFormat.DECIMAL, text:'%1.',
          alignment:AlignmentType.RIGHT,
          style:{ paragraph:{ indent:{left:560,hanging:280} } } }] },
      { reference:'steps5', levels:[{ level:0, format:LevelFormat.DECIMAL, text:'%1.',
          alignment:AlignmentType.RIGHT,
          style:{ paragraph:{ indent:{left:560,hanging:280} } } }] },
    ]
  },
  sections: [{
    properties: {
      page: {
        size:{ width:11906, height:16838 },
        margin:{ top:1100, bottom:1100, left:1200, right:1200 }
      }
    },
    headers: { default: new Header({ children:[
      new Paragraph({
        alignment: AlignmentType.LEFT,
        border:{ bottom:{ style:BorderStyle.SINGLE, size:4, color:ORANGE, space:4 } },
        children:[
          new TextRun({ text:'Fanta', bold:true, size:20, color:DARK, font:'Arial' }),
          new TextRun({ text:'Tech', bold:true, size:20, color:ORANGE, font:'Arial' }),
          new TextRun({ text:'   |   מדריך התקנה — Smart Home', size:18, color:'999999', font:'Arial' }),
        ]
      })
    ]})},
    footers: { default: new Footer({ children:[
      new Paragraph({
        alignment: AlignmentType.CENTER,
        border:{ top:{ style:BorderStyle.SINGLE, size:2, color:MGRAY, space:4 } },
        children:[
          new TextRun({ text:'FantaTech Smart Home  |  עמוד ', size:17, color:'AAAAAA', font:'Arial' }),
          new TextRun({ children:[PageNumber.CURRENT], size:17, color:'AAAAAA', font:'Arial' }),
        ]
      })
    ]})},

    children: [

      // ─── COVER ────────────────────────────────────────────────────────────
      sp(500),
      new Paragraph({ alignment:AlignmentType.CENTER, children:[
        new TextRun({ text:'FantaTech', bold:true, size:88, color:ORANGE, font:'Arial' })
      ]}),
      new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:60}, children:[
        new TextRun({ text:'Smart Home', bold:true, size:52, color:DARK, font:'Arial' })
      ]}),
      sp(60),
      new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:60,after:40}, children:[
        new TextRun({ text:'מדריך התקנה מלא', size:32, color:'555555', font:'Arial' })
      ]}),
      new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:20,after:0}, children:[
        new TextRun({ text:'גרסה 2.15.0  |  יוני 2026', size:22, color:'AAAAAA', font:'Arial' })
      ]}),
      sp(200),

      // cover info table
      new Table({
        width:{size:7000,type:WidthType.DXA}, columnWidths:[3500,3500],
        rows:[new TableRow({ children:[
          new TableCell({
            width:{size:3500,type:WidthType.DXA}, borders:bs(ORANGE),
            shading:{fill:'FFF3E0',type:ShadingType.CLEAR},
            margins:{top:160,bottom:160,left:200,right:200},
            children:[
              new Paragraph({ alignment:AlignmentType.CENTER, children:[
                new TextRun({text:'5', bold:true, size:56, color:ORANGE, font:'Arial'})
              ]}),
              new Paragraph({ alignment:AlignmentType.CENTER, children:[
                new TextRun({text:'שלבי התקנה', size:22, color:DARK, font:'Arial'})
              ]}),
            ]
          }),
          new TableCell({
            width:{size:3500,type:WidthType.DXA}, borders:bs(BLUE),
            shading:{fill:INFOB,type:ShadingType.CLEAR},
            margins:{top:160,bottom:160,left:200,right:200},
            children:[
              new Paragraph({ alignment:AlignmentType.CENTER, children:[
                new TextRun({text:'~3', bold:true, size:56, color:BLUE, font:'Arial'})
              ]}),
              new Paragraph({ alignment:AlignmentType.CENTER, children:[
                new TextRun({text:'שעות התקנה', size:22, color:DARK, font:'Arial'})
              ]}),
            ]
          }),
        ]})]
      }),
      sp(120),

      // cover steps list
      new Table({
        width:{size:7000,type:WidthType.DXA}, columnWidths:[700,6300],
        rows:[
          ['01','Raspberry Pi + Home Assistant OS'],
          ['02','מפסקים חכמים — Shelly'],
          ['03','חיישני Zigbee (דלת, תנועה)'],
          ['04','מצלמות ONVIF'],
          ['05','FantaTech — חיבור ל-Home Assistant'],
        ].map(([num,label],i)=>new TableRow({ children:[
          new TableCell({
            width:{size:700,type:WidthType.DXA}, borders:bs(MGRAY),
            shading:{fill:i%2===0?WHITE:LGRAY,type:ShadingType.CLEAR},
            margins:{top:80,bottom:80,left:80,right:80},
            children:[new Paragraph({ alignment:AlignmentType.CENTER, children:[
              new TextRun({text:num,bold:true,size:20,color:ORANGE,font:'Arial'})
            ]})]
          }),
          new TableCell({
            width:{size:6300,type:WidthType.DXA}, borders:bs(MGRAY),
            shading:{fill:i%2===0?WHITE:LGRAY,type:ShadingType.CLEAR},
            margins:{top:80,bottom:80,left:160,right:160},
            children:[new Paragraph({ alignment:AlignmentType.RIGHT, children:[
              new TextRun({text:label,size:21,font:'Arial',color:DARK})
            ]})]
          }),
        ]}))
      }),

      // PAGE BREAK
      new Paragraph({ children:[new PageBreak()] }),

      // ─── STEP 1 ───────────────────────────────────────────────────────────
      stepHeader(1, 'Raspberry Pi + Home Assistant OS', 'הכנה, צריבה והפעלה ראשונה'),
      sp(120),

      h2('ציוד נדרש'),
      simpleTable(
        [{label:'פריט',w:4000},{label:'דגם / הערה',w:3500},{label:'זמינות',w:1526}],
        [
          ['Raspberry Pi 4','Model B — 4GB RAM','KSP / Ivory'],
          ['כרטיס microSD','SanDisk Extreme 64GB A2','KSP / Amazon'],
          ['ספק כוח','Official Raspberry Pi USB-C 5.1V 3A','KSP'],
          ['כבל רשת','CAT5E לפחות','כל חנות'],
          ['מחשב עם דפדפן','לצריבה ולהגדרה ראשונה','—'],
        ]
      ),
      sp(120),

      h2('הורדת תוכנת צריבה'),
      numbered('כנס ל-raspberrypi.com/software'),
      numbered('הורד והתקן: Raspberry Pi Imager (Windows / Mac)'),
      sp(80),

      h2('צריבת Home Assistant OS'),
      numbered('פתח Raspberry Pi Imager'),
      numbered('לחץ "Choose OS"'),
      code([
        'Other specific purpose OS',
        '  -> Home Assistants and Home Automation',
        '     -> Home Assistant OS (64-bit)',
      ]),
      numbered('לחץ "Choose Storage" — בחר כרטיס SD'),
      numbered('לחץ Write — המתן ~5 דקות'),
      sp(80),

      warn('שים לב', [
        'כרטיס SD יימחק לחלוטין תוך כדי הצריבה',
        'אל תנתק את הכרטיס באמצע התהליך',
      ]),
      sp(100),

      h2('הפעלה ראשונה'),
      numbered('הכנס את כרטיס ה-SD ל-Raspberry Pi'),
      numbered('חבר כבל רשת מהPi לנתב הביתי'),
      numbered('חבר ספק כוח — נורה אדומה ועליה ירוקה מהבהבת'),
      numbered('המתן 5-8 דקות (HA מתקין בפעם הראשונה)'),
      numbered('פתח דפדפן במחשב:'),
      code(['http://homeassistant.local:8123']),
      sp(80),

      info('לא מוצא?', [
        'נסה לפתוח את ממשק הנתב (192.168.1.1 או 192.168.0.1)',
        'חפש מכשיר בשם "homeassistant" ← קח את ה-IP שלו',
        'הזן ישירות: http://192.168.1.XXX:8123',
      ]),
      sp(100),

      h2('אשף הגדרה ראשונית'),
      numbered('Create Account — שם, שם משתמש, סיסמה חזקה'),
      numbered('Home Location — עיר (תל אביב / ירושלים)'),
      numbered('Privacy Settings — השאר ברירת מחדל'),
      numbered('Finish — אתה בתוך HA!'),
      sp(80),

      success('שלב 1 הושלם', [
        'Home Assistant עובד על ה-Raspberry Pi שלך',
        'כתובת: http://homeassistant.local:8123',
        'HA מתעדכן אוטומטית — לא צריך לעשות כלום נוסף',
      ]),

      new Paragraph({ children:[new PageBreak()] }),

      // ─── STEP 2 ───────────────────────────────────────────────────────────
      stepHeader(2, 'מפסקים חכמים — Shelly', 'חיבור חשמלי + הגדרת WiFi + חיבור ל-HA'),
      sp(100),

      warn('אזהרת בטיחות — חשמל 220V', [
        'יש לנתק את המפסק בלוח החשמל לפני כל עבודה',
        'השתמש במולטימטר לוודא שאין מתח לפני נגיעה בחוטים',
        'אם אין ניסיון — פנה לחשמלאי מוסמך',
      ]),
      sp(120),

      h2('חיבור חשמלי — Shelly 1PM'),
      body('פתח את קופסת המפסק הקיימת. תמצא 3-4 חוטים:'),
      sp(60),
      simpleTable(
        [{label:'מסוף Shelly',w:2000},{label:'חוט',w:3000},{label:'צבע נפוץ',w:2000},{label:'מה זה',w:2026}],
        [
          ['L  (פאזה)','חוט פאזה','חום / אדום / שחור','מתח 220V'],
          ['N  (ניטראל)','חוט ניטראל','כחול','אפס'],
          ['O  (פלט)','לנורה','—','מחובר לנורה'],
          ['SW (מפסק)','מפסק ידני','—','אופציונלי'],
        ]
      ),
      sp(80),
      info('Shelly 2PM — 2 ערוצים', [
        'יש O1 ו-O2 לשני מעגלי תאורה נפרדים',
        'L ו-N מחוברים פעם אחת לשניהם',
      ]),
      sp(120),

      h2('הגדרת WiFi ל-Shelly'),
      numbered('הדלק חשמל — Shelly יצור רשת WiFi בשם "shellyXXXXXX"'),
      numbered('מהטלפון — התחבר לרשת "shellyXXXXXX"'),
      numbered('פתח דפדפן בטלפון:'),
      code(['192.168.33.1']),
      numbered('Internet & Security → WiFi Mode → Join Existing Network'),
      numbered('בחר את רשת הבית שלך ← הזן סיסמה'),
      numbered('Save — Shelly מתחבר לרשת'),
      numbered('מצא את ה-IP של Shelly בנתב (192.168.1.XXX)'),
      sp(80),

      h2('חיבור ל-Home Assistant'),
      numbered('HA → Settings → Devices & Services'),
      numbered('Shelly מופיע אוטומטית בחלק "Discovered"'),
      numbered('לחץ Configure → Add'),
      numbered('תן שם ברור: "אור סלון" / "תאורת מטבח" וכו\''),
      sp(80),

      info('לא מוצא את Shelly?', [
        'Settings → Integrations → Add Integration → חפש "Shelly"',
        'הזן IP ידנית של מכשיר ה-Shelly',
      ]),
      sp(80),

      h2('בדיקה'),
      numbered('HA → Dashboard → מצא את "אור סלון"'),
      numbered('לחץ Toggle — האור צריך להגיב מיידית'),
      numbered('חזור עם הדגמות כנ"ל לכל מפסק נוסף'),
      sp(80),

      success('שלב 2 הושלם', [
        'כל מפסקי Shelly מחוברים ל-HA',
        'שליטה מלאה מקומית — ללא ענן',
        'גם אם האינטרנט נפל — הכל עובד',
      ]),

      new Paragraph({ children:[new PageBreak()] }),

      // ─── STEP 3 ───────────────────────────────────────────────────────────
      stepHeader(3, 'חיישני Zigbee', 'Zigbee2MQTT + חיישני דלת + חיישן תנועה'),
      sp(100),

      h2('ציוד נדרש'),
      simpleTable(
        [{label:'פריט',w:3000},{label:'דגם',w:3500},{label:'מחיר',w:2526}],
        [
          ['מתאם Zigbee USB','Sonoff Zigbee 3.0 USB Dongle Plus','80 ₪'],
          ['חיישן דלת/חלון','Aqara Door & Window Sensor P2','65 ₪ / יחידה'],
          ['חיישן תנועה','IKEA TRADFRI Motion Sensor','55 ₪'],
        ]
      ),
      sp(120),

      h2('התקנת Zigbee2MQTT ב-HA'),
      numbered('HA → Settings → Add-ons'),
      numbered('לחץ "+ Add-on Store" (פינה ימנית תחתונה)'),
      numbered('חפש: Zigbee2MQTT → Install'),
      numbered('לאחר התקנה → Start'),
      numbered('פתח Web UI'),
      sp(60),
      info('הגדרת port (אם נדרש)', [
        'Configuration → serial → port → /dev/ttyUSB0',
        'אם לא עובד נסה: /dev/ttyACM0',
      ]),
      sp(120),

      h2('חיבור חיישן Aqara'),
      numbered('ב-Zigbee2MQTT Web UI: לחץ "Permit join: All" — כפתור ירוק'),
      numbered('פתח מארז החיישן (מטבע קטן בחריץ)'),
      numbered('לחץ על כפתור Reset קטן 5 שניות — LED מהבהב'),
      numbered('תוך 30 שניות החיישן מופיע ב-Zigbee2MQTT'),
      numbered('לחץ עליו → שנה שם: "דלת כניסה" / "חלון מטבח"'),
      numbered('כבה "Permit join" — לאבטחה'),
      sp(80),

      h2('יצירת Automation — התראה בפתיחת דלת'),
      numbered('HA → Settings → Automations → + Create Automation'),
      numbered('Trigger: Device → בחר חיישן הדלת → "Door opened"'),
      numbered('Action: Notify → שלח התראה לטלפון'),
      numbered('Save — בדוק: פתח דלת ← טלפון מרעיד'),
      sp(80),

      success('שלב 3 הושלם', [
        'חיישנים מחוברים ב-Zigbee — ללא WiFi, ללא ענן',
        'Zigbee צורך פחות חשמל מ-WiFi',
        'טווח של 10-15 מטר, מחדר לחדר',
      ]),

      new Paragraph({ children:[new PageBreak()] }),

      // ─── STEP 4 ───────────────────────────────────────────────────────────
      stepHeader(4, 'מצלמות ONVIF', 'התקנה, חיבור לרשת וצפייה בFantaTech'),
      sp(100),

      h2('מצלמות מומלצות'),
      simpleTable(
        [{label:'דגם',w:3000},{label:'רזולוציה',w:1400},{label:'חיבור',w:1400},{label:'מחיר',w:1500},{label:'הערה',w:1726}],
        [
          ['Reolink RLC-810A','4K','PoE','320 ₪','מומלץ — חוץ'],
          ['Reolink RLC-810WA','4K','WiFi','350 ₪','מומלץ — חוץ WiFi'],
          ['TP-Link Tapo C310','3MP','WiFi','180 ₪','מחיר טוב'],
          ['Hikvision DS-2CD1143G2','4MP','PoE','250 ₪','מקצועי'],
        ]
      ),
      sp(100),

      h2('חיבור לרשת'),
      h3('מצלמת WiFi'),
      numbered('חבר מצלמה לחשמל'),
      numbered('הורד אפליקציית Reolink / Tapo לטלפון'),
      numbered('הוסף מכשיר — עקב אחרי האשף לחיבור WiFi'),
      numbered('מצא IP ב: נתב → Connected Devices'),
      sp(60),
      h3('מצלמת PoE'),
      numbered('חבר כבל RJ45 ישירות מהמצלמה ל-PoE Switch / NVR'),
      numbered('מצא IP בנתב'),
      sp(100),

      h2('הגדרת ONVIF במצלמה'),
      numbered('פתח דפדפן ← הזן IP של המצלמה'),
      numbered('כנס עם: admin / הסיסמה שהגדרת'),
      numbered('Configuration → Network → Advanced → ONVIF'),
      numbered('וודא ש-ONVIF מופעל (Enable)'),
      numbered('שמור שם משתמש + סיסמה — תצטרך אותם בFantaTech'),
      sp(100),

      h2('הוספת מצלמה לFantaTech'),
      numbered('פתח FantaTech → לשונית מצלמות'),
      numbered('לחץ + (הוסף מצלמה)'),
      numbered('בחר: ONVIF'),
      code([
        'IP:       192.168.1.XXX',
        'Port:     80  (או 8080 לחלק מהמצלמות)',
        'Username: admin',
        'Password: [הסיסמה שהגדרת]',
      ]),
      numbered('לחץ "חבר" — הזרם מופיע מיידית'),
      sp(80),

      info('מצלמת RTSP ישירה', [
        'אם ONVIF לא עובד — נסה RTSP ישיר:',
        'rtsp://admin:סיסמה@192.168.1.XXX:554/stream1',
      ]),
      sp(80),

      success('שלב 4 הושלם', [
        'מצלמות חיות בFantaTech — ללא שרתי ענן',
        'הקלטות נשמרות ב-Raspberry Pi / NAS מקומי',
        'צפייה מחוץ לבית עובדת דרך Tailscale / VPN',
      ]),

      new Paragraph({ children:[new PageBreak()] }),

      // ─── STEP 5 ───────────────────────────────────────────────────────────
      stepHeader(5, 'FantaTech — חיבור ל-Home Assistant', 'Token, חיבור, ייבוא מכשירים'),
      sp(100),

      h2('יצירת Token ב-HA'),
      numbered('ב-Home Assistant — לחץ על שמך (פינה שמאלית תחתונה)'),
      numbered('גלול למטה: Long-Lived Access Tokens'),
      numbered('לחץ "Create Token"'),
      numbered('שם: FantaTech ← לחץ OK'),
      sp(60),
      warn('חשוב מאוד', [
        'ה-Token מוצג פעם אחת בלבד — העתק אותו מיד',
        'אם לא העתקת — מחק ותייצר Token חדש',
        'אל תשלח Token בWATSAPP / מייל / צ\'אט',
      ]),
      sp(100),

      h2('חיבור FantaTech ל-HA'),
      numbered('פתח אפליקציית FantaTech'),
      numbered('לחץ על פרופיל (אייקון אדם — ימין תחתון)'),
      numbered('לחץ "שערים" (Gateways)'),
      numbered('לחץ + הוסף שער'),
      numbered('בחר: Home Assistant'),
      code([
        'IP Address:  192.168.1.XXX   (IP של הRaspberry Pi)',
        'Port:        8123',
        'Token:       [הדבק את ה-Token שיצרת]',
      ]),
      numbered('לחץ "התחבר"'),
      numbered('כל המכשירים מ-HA מיובאים אוטומטית!'),
      sp(100),

      h2('מצא את IP של הRaspberry Pi'),
      body('אם לא ידוע לך ה-IP:'),
      bullet('נסה: http://homeassistant.local:8123 (ה-IP יופיע בכתובת)'),
      bullet('פתח ממשק נתב (192.168.1.1) → Connected Devices → חפש "homeassistant"'),
      bullet('HA → Settings → System → Network → IPv4 Address'),
      sp(100),

      h2('הגדרת מכשירים בFantaTech'),
      numbered('לשונית "מכשירים" → תראה את כל המכשירים מ-HA'),
      numbered('גרור מכשיר לחדר: לחץ על המכשיר → "הוסף לחדר"'),
      numbered('שנה שם ואייקון לפי הצורך'),
      numbered('הוסף מצלמות כפי שהסברנו בשלב 4'),
      sp(80),

      success('שלב 5 הושלם — המערכת חיה!', [
        'כל מפסקי Shelly ניתנים לשליטה מהאפליקציה',
        'חיישנים שולחים התראות בזמן אמת',
        'מצלמות בשידור חי',
        'עובד גם מחוץ לבית דרך הרשת הביתית',
      ]),

      new Paragraph({ children:[new PageBreak()] }),

      // ─── FINAL CHECKLIST ─────────────────────────────────────────────────
      h1('רשימת בדיקות — לפני מסירה ללקוח'),
      sp(80),

      h2('בדיקות מפסקים'),
      checklist([
        'כל מפסקי Shelly מופיעים ב-HA',
        'כיבוי/הדלקה מהאפליקציה — תגובה תוך שנייה',
        'מפסק ידני עדיין עובד (SW מחובר)',
        'Shelly 1PM — ניטור אנרגיה מציג נתונים',
      ]),
      sp(100),

      h2('בדיקות חיישנים'),
      checklist([
        'חיישן דלת — פתח/סגור ← HA מקבל עדכון',
        'חיישן תנועה — הניף יד ← תגובה תוך 2 שניות',
        'התראה לטלפון בפתיחת דלת עובדת',
      ]),
      sp(100),

      h2('בדיקות מצלמות'),
      checklist([
        'כל המצלמות מציגות תמונה חיה',
        'לחיצה על מצלמה פותחת מסך מלא',
        'מצלמה עובדת מחוץ לבית (רשת 4G)',
      ]),
      sp(100),

      h2('בדיקת עמידות'),
      checklist([
        'נתק אינטרנט — Shelly ממשיך לעבוד מקומית',
        'כבה ידנית ואתחל את הPi — HA עולה תוך 2 דקות',
        'UPS — שלוף חשמל מהשקע — Pi ממשיך לרוץ',
      ]),
      sp(100),

      h2('בדיקת אפליקציה'),
      checklist([
        'כניסה / יציאה — אחרי יציאה מוצג מסך כניסה',
        'כל המכשירים בלשונית הנכונה',
        'שינוי שם חדר עובד',
        'ממשק RTL (עברית) תקין',
      ]),
      sp(160),

      // ─── TROUBLESHOOTING ─────────────────────────────────────────────────
      h1('תיקון תקלות נפוצות'),
      sp(80),

      simpleTable(
        [{label:'תקלה',w:3500},{label:'סיבה',w:2500},{label:'פתרון',w:3026}],
        [
          ['HA לא נטען בדפדפן','Pi לא סיים אתחול','המתן עוד 3 דקות, רענן'],
          ['Shelly לא מופיע ב-HA','HA ו-Shelly ברשתות שונות','וודא שניהם באותה WiFi'],
          ['Shelly לא מגיב','IP השתנה','הגדר IP קבוע בנתב'],
          ['חיישן Zigbee לא מתחבר','מחוץ לטווח','הקרב ל-USB Dongle בזמן pairing'],
          ['מצלמה לא מציגה תמונה','סיסמה שגויה','בדוק user/pass ב-ONVIF settings'],
          ['Token לא עובד','Token פג / שגוי','צור Token חדש ב-HA'],
          ['אפליקציה מתנתקת','IP של Pi השתנה','הגדר IP קבוע לPi בנתב'],
        ]
      ),
      sp(160),

      // final box
      new Table({
        width:{size:9026,type:WidthType.DXA}, columnWidths:[9026],
        rows:[new TableRow({ children:[new TableCell({
          width:{size:9026,type:WidthType.DXA},
          borders: bs(ORANGE),
          shading:{ fill:'FFF3E0', type:ShadingType.CLEAR },
          margins:{top:200,bottom:200,left:240,right:240},
          children:[
            new Paragraph({ alignment:AlignmentType.CENTER, children:[
              new TextRun({text:'FantaTech', bold:true, size:28, font:'Arial', color:ORANGE}),
              new TextRun({text:'  —  מערכת חכמה ללא ענן, ללא תלות, ללא הגבלות', size:24, font:'Arial', color:DARK}),
            ]}),
            sp(60),
            new Paragraph({ alignment:AlignmentType.CENTER, children:[
              new TextRun({text:'הלקוח שלך שולט בבית שלו — לתמיד', size:22, font:'Arial', color:'666666', italics:true}),
            ]}),
          ]
        })]})],
      }),

    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('FantaTech_Installation_Guide.docx', buf);
  console.log('Done: FantaTech_Installation_Guide.docx');
}).catch(e => { console.error(e); process.exit(1); });
