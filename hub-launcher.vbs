Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = "C:\Users\My laptop\Desktop\smarthome-hub\hub"
oShell.Run """C:\Python314\python.exe"" -m uvicorn main:app --host 0.0.0.0 --port 8080", 0, False
