// Import necessary libraries.
const express = require('express');
const http = require('http');
const https = require('https');
const net = require('net');
const RED = require('node-red');
const { app: electronApp, BrowserWindow } = require('electron');
const fs = require('fs');
const path = require('path');
// const dotenv = require('dotenv');

// Configrations
const parentDirPath = path.resolve(__dirname, "../../../Config");
const userDirectory = path.resolve("./")
var dirPath = electronApp.isPackaged ? parentDirPath : __dirname;
// var dirPath =  electronApp.isPackaged ? parentDirPath : __dirname;
const CONFIG_FILE_NAME = 'config_flow.json';
const CERTS_FILE_NAME = 'private_and_certificate.pem'


// Load configuration
const configDirPath = path.join(dirPath, CONFIG_FILE_NAME);

if (!fs.existsSync(configDirPath)) {
    console.error(`Error: Configuration file missing -> ${configDirPath}`);
    process.exit(1);
}
const readConfig = fs.readFileSync(configDirPath, 'utf-8');
const config = JSON.parse(readConfig);
const PORT = config.port || '3000';
const appEditable = config['api-editable'] || false;



// HTTPS config
const  httpsEnabled = config.https || false;

if(httpsEnabled){
    var certsPath = path.join("..", "Config", "Certs", CERTS_FILE_NAME);
    console.log(certsPath);
    // var certsPath = path.join(".", 'Certs', CERTS_FILE_NAME);
    if (!fs.existsSync(certsPath)) {
        console.error(`Error: Configuration file missing -> ${certsPath}`);
        process.exit(1);
    }
}

// Load TLS credentials if HTTPS is enabled
let tlsOptions = null;

if (httpsEnabled) {

    try {
        tlsOptions = {
            key: fs.readFileSync(certsPath, 'utf-8'),
            cert: fs.readFileSync(certsPath, 'utf-8')
        };
        console.log('HTTPS mode enabled. PEM blocks extracted successfully.');
        // console.log(tlsOptions);
    } catch (err) {
        console.error('Error loading TLS certificates:', err.message);
        process.exit(1);
    }
}

// creaate or delete debug directory
const debugDir = path.join(dirPath, 'debug');
const flowJsonPath = path.join(__dirname, 'flow.json'); // path for the asr folder
const flowJsonTargetPath = path.join(debugDir, 'flow.json'); //path where we write the flowApp file file



const appB1ScriptPath = path.resolve(__dirname, '../../');
const scriptFilePath = appB1ScriptPath;


// Helper function to copy a file or folder if it exists and target doesn't exist
const copyToDebug = (sourcePath, targetPath) => {
    // copy the contetn from the directory
    if (!fs.existsSync(targetPath) && fs.existsSync(sourcePath)) {
        const stats = fs.statSync(sourcePath);
        if (stats.isDirectory()) {
            fs.mkdirSync(targetPath, { recursive: true });
            const entries = fs.readdirSync(sourcePath, { withFileTypes: true });

            for (const entry of entries) {
                const src = path.join(sourcePath, entry.name);
                const dest = path.join(targetPath, entry.name);
                copyToDebug(src, dest);
            }

            console.log(`Copied folder: ${path.basename(sourcePath)} to debug directory.`);
        }
    }

    //  copy the content from files
    if (!fs.existsSync(targetPath) && fs.existsSync(sourcePath)) {
        const data = fs.readFileSync(sourcePath, 'utf-8');
        fs.writeFileSync(targetPath, data, 'utf-8');
        console.log(`Copied ${path.basename(targetPath)} to debug directory.`);
    }
};



// for the debug directory
if (appEditable) {
    if (!fs.existsSync(debugDir)) {
        fs.mkdirSync(debugDir);
        console.log(`Created debug directory: ${debugDir}`);
        // Attempt to copy the flow files
        copyToDebug(flowJsonPath, flowJsonTargetPath);
    }
}
else {
    // Delete 'debug' directory if it exists
    if (fs.existsSync(debugDir)) {
        fs.rmSync(debugDir, { recursive: true, force: true });
        console.log(`Deleted debug directory: ${debugDir}`);
    }
}


const app = express();

// Create HTTP or HTTPS server based on config
console.log("on to the server creation step");
let server;
let tcpServer;
let redirectServer;

if (httpsEnabled) {
    try {
        server = https.createServer(tlsOptions, app);
        console.log('HTTPS server created successfully.');

        // Handle TLS client errors gracefully
        server.on('tlsClientError', (err, socket) => {
            // Quietly destroy to prevent unhandled TLS connection reset crashes
            socket.destroy();
        });

        // Create plain HTTP redirect server
        redirectServer = http.createServer((req, res) => {
            const hostHeader = req.headers.host || `localhost:${PORT}`;
            res.writeHead(301, { "Location": `https://${hostHeader}${req.url}` });
            res.end();
        });

        redirectServer.on('clientError', (err, socket) => {
            socket.destroy();
        });

        // Create the multiplexing TCP server
        tcpServer = net.createServer((socket) => {
            socket.once('data', (data) => {
                socket.pause();
                const firstByte = data[0];

                if (firstByte === 22) {
                    // TLS ClientHello (HTTPS)
                    server.emit('connection', socket);
                } else {
                    // Plain HTTP
                    redirectServer.emit('connection', socket);
                }

                socket.unshift(data);
                socket.resume();
            });

            socket.on('error', (err) => {
                socket.destroy();
            });
        });

        tcpServer.on('error', (err) => {
            console.error('TCP Server error:', err.message);
        });

    } catch (err) {
        console.error('Failed to create HTTPS server:', err.message);
        process.exit(1);
    }
} else {
    server = http.createServer(app);
}
// const uiPath = path.join(__dirname, "UI", "dist");
const uiPath = path.join(scriptFilePath, "projects", "ENT_B1_Cockpit", "webapp");

console.log("server created");

var flowFilePath = appEditable ? flowJsonTargetPath : flowJsonPath; //the path from the flow file we read.

// Serve your UI (static files or routes)
if (fs.existsSync(uiPath) && fs.statSync(uiPath).isDirectory()) {
    console.log("Serving UI from:", uiPath);
    app.use(express.static(uiPath));

    app.get("/", (req, res) => {
        res.sendFile("index.html", { root: uiPath });
    });

} else {
    console.error("Error: UI path does not exist ->", uiPath);
}

// Create Node-RED settings object
const settings = {
    uiPort: PORT,
    userDir: userDirectory,//dirPath + '\\',
    sep: path.sep,
    flowFile: flowFilePath,
    ui: { path: "/" },
    httpAdminRoot: "/red",
    httpNodeRoot: "/",
    webSocketNodePort: PORT + 1,
    credentialSecret: "devesh",

    // HTTPS for Node-RED (editor + API routes)
    ...(httpsEnabled ? {
        https: tlsOptions
    } : {}),

    externalModules: {
        autoInstall: false
    },
    flowFilePretty: true,
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            password: "$2a$08$QmlKUtjJTNfcAxH06BJSS.fh56za1BCQOz6p//AZ8ASBQGjcaj7Jm",
            permissions: "*"
        }]
    },
    functionGlobalContext: {
        superagent: require("superagent"),
        ssh2: require("ssh2"),
        winrm: require('nodejs-winrm'),
        crypto: require("crypto"),
        fs: require("fs"),
        excelJS: require('exceljs'),
        yoPilot: require('yo-pilot')
    },
    projectDir: scriptFilePath,
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
        // writeToFile: {
        //     level: 'trace',
        //     metrics: false,
        //     filePath: '',
        //     handler: function (settings) {
        //         return function (msg) {
        //             const logDir = path.join('.', 'log_flows');
        //             if (!fs.existsSync(logDir)) {
        //                 fs.mkdirSync(logDir, { recursive: true });
        //             }
        //             const dateStr = new Date().toISOString().split('T')[0];
        //             if (settings.filePath === undefined || settings.filePath === '') {
        //                 settings.filePath = path.join(logDir, `log_${dateStr}.txt`);
        //             }
        //             fs.appendFileSync(
        //                 settings.filePath,
        //                 new Date().toString() + ' -- ' + msg.msg + '\n'
        //             );
        //         }
        //     }
        // }
    },
    functionExternalModules: true
};


// Electron Window
let mainWindow = null;
function createWindow() {
    mainWindow = new BrowserWindow({
        width: 800,
        height: 600,
        webPreferences: {
            nodeIntegration: true,
            devTools: false
        }
    });

    setTimeout(() => {
        const protocol = httpsEnabled ? 'https' : 'http';
        mainWindow.loadURL(`${protocol}://localhost:${PORT}`);
        mainWindow.on('closed', () => {
            mainWindow = null;
        });
    }, 500);


}

electronApp.whenReady().then(() => {
    createWindow();
    electronApp.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

electronApp.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        electronApp.quit();
    }
});

// Initialise Node-RED with the settings
RED.init(server, settings);

// Serve the Node-RED editor and HTTP nodes
if (appEditable === false) {
    settings.httpAdminRoot = false
}
if (appEditable) {
    app.use(settings.httpAdminRoot, RED.httpAdmin);
}
app.use(settings.httpNodeRoot, RED.httpNode);

// Start the server (multiplexed TCP server if HTTPS enabled, otherwise HTTP server)
const protocol = httpsEnabled ? 'https' : 'http';
const listenServer = httpsEnabled ? tcpServer : server;
listenServer.listen(PORT, () => {
    console.log(`UI running at ${protocol}://localhost:${PORT}/`);
    console.log(`Node-RED running at ${protocol}://localhost:${PORT}/red`);
    if (httpsEnabled) {
        console.log(`HTTP traffic is automatically redirected to HTTPS on the same port.`);
    }
});

// Start Node-RED
RED.start();
