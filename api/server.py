#!/usr/bin/python3
import os, threading, subprocess, shlex, time, socket, traceback, json, sys, signal

AUGWORK_DIR = '/home/cha14ka/Desktop/cha14ka/prog/AugWorkstation'
active_users = {}
ports = []

def generate_port():
    for port in range(5901,5999):
        if port not in ports:
            ports.append(port)
            return port
    print({"error":"no ports available"})
    exit()

def start_docker(user):
    if not os.path.isdir(AUGWORK_DIR+'/home/'+user['name']):
        os.system(AUGWORK_DIR+'/api/install_home.sh '+user['name']+' '+user['password'])

    #subprocess.getoutput('''xrandr | grep \* | awk '{print $1}' ''').split('\n')
    user['process'] = subprocess.Popen(
        ['./start_docker.sh',user['name'],str(user['port']),user['resolution']],
        preexec_fn=os.setsid
    )

conn = None
while True:
    try:
        sock = socket.socket()
        sock.bind(('',5900))
        sock.listen(1)

        while True:
            conn, addr = sock.accept()
            print('Connected: ',addr)
            while True:
                data = conn.recv(1024)
                if not data:
                    print('Exit socket')
                    break
                
                print(data.decode())
                query = json.loads(data.decode())

                if query['method'] == 'exec':
                    exec(query['code'])

                if query['method'] == 'login':
                    query['login'] = query['login'].lower()
                    #if query['login'] == 'admin' and query['password'] == 'admin':
                    if True:
                        if query['login'] in active_users:
                            user = active_users[query['login']]
                            os.killpg(os.getpgid(user['process'].pid),signal.SIGTERM)
                            del ports[ports.index(user['port'])]
                            del active_users[query['login']]


                        active_users[query['login']] = {}
                        user = active_users[query['login']]

                        user['name'] = query['login']
                        user['resolution'] = query['resolution']
                        user['password'] = query['password']
                        user['port'] = generate_port()
                        user['thread'] = threading.Thread(target=start_docker,args=(user,))
                        user['thread'].start()

                        conn.send(json.dumps({'host':'cha14ka.tk','port':user['port'],'password':query['password']}).encode())
                        conn.send('\r\n'.encode())


            conn.close()
    except Exception as error:
        print(traceback.format_exc())
        if conn != None:
            conn.close()
        sock.close()
        if error == KeyboardInterrupt: 
            os.system('pkill -9 -f x11docker')
            sys.exit()