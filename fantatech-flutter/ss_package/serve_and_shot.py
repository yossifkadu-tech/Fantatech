import http.server, os, sys, threading, time, subprocess, signal

webdir = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\build\web"
ssdir  = r"C:\Users\My laptop\Desktop\smarthome-hub\fantatech-flutter\ss_package"
os.chdir(webdir)

httpd = http.server.HTTPServer(('', 9292), http.server.SimpleHTTPRequestHandler)
t = threading.Thread(target=httpd.serve_forever, daemon=True)
t.start()
print('Server on 9292', flush=True)
time.sleep(3)

# Run playwright
result = subprocess.run(['node', os.path.join(ssdir, 'ss_new.js')], capture_output=True, text=True)
print(result.stdout)
if result.returncode != 0:
    print('ERR:', result.stderr[:400])
else:
    print('Screenshot done!')
httpd.shutdown()
