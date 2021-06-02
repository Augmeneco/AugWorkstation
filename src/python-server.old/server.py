#!/usr/bin/python3
import os, threading, subprocess, shlex, time, socket, traceback, json, sys, signal, hashlib

AUGWORK_DIR = '/home/cha14ka/Desktop/cha14ka/prog/AugWorkstation'
SHA256_SALT = 'augworksalt'
active_users = {}
ports = []

if not os.path.exists('users_data.json'):
    os.system('echo {} > users_data.json')

users_data = json.loads(open('users_data.json','r').read())

def generate_port():
    for port in range(5901,5999):
        if port not in ports:
            ports.append(port)
            return port
    print('Нет свободных портов')
    exit()

def start_docker(user):
    if not os.path.isdir(AUGWORK_DIR+'/home/'+user['name']):
        os.system(AUGWORK_DIR+'/api/install_home.sh '+user['name']+' '+user['password'])

    user['process'] = subprocess.Popen(
        ['./start_docker.sh',user['name'],str(user['port']),user['resolution']],
        preexec_fn=os.setsid
    )

if sys.argv[1] == 'useradd':
    login = sys.argv[2]
    password = sys.argv[3]
    if login in users_data:
        print('Этот пользователь уже существует. Вы можете сменить пароль ему командой changepass')
        exit()
        
    users_data[login] = {
        'password':hashlib.sha256((password+SHA256_SALT).encode()).hexdigest()
    }
    open('users_data.json','w').write(json.dumps(users_data))
    print('Пользователь '+login+' был успешно добавлен')
    exit()
    
    
    
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