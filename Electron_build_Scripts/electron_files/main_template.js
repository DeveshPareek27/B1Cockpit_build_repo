// Import necessary libraries.
const { app, BrowserWindow } = require('electron');
const { fork } = require('child_process');
const path = require('path');
const express = require('express');
const fs = require('fs');
const { createProxyMiddleware } = require('http-proxy-middleware');
const dotenv = require('dotenv');



//Configrations
const PORT = 5000;
const CONFIG_FILE_NAME = 'config_flow.json';
const UI5_FOLDER = path.join(__dirname, 'UI', 'dist');
const CONFIG_PARENT_PATH = path.resolve(__dirname, '../../../Config');
var dirPath =  app.isPackaged ? CONFIG_PARENT_PATH : __dirname; // it indicates the user directory for the node-red
const envData = dotenv.config(); //just ot load module and ignore the modeule not used error

// debug info
// console.log("User DIrectory Path:", dirPath);
// console.log("app Packaged:", app.isPackaged);
// console.log("Resource path:", process.resourcesPath);
// console.log("App path:", app.getAppPath());


// Ensure config directory exists and is valid
if (!fs.existsSync(dirPath) || !fs.statSync(dirPath).isDirectory()) {
    console.error(`Error: Invalid directory -> ${dirPath}`);
    process.exit(1);
}


// Load configuration
const configPath = path.join(dirPath, CONFIG_FILE_NAME);
if (!fs.existsSync(configPath)) {
    console.error(`Error: Configuration file missing -> ${configPath}`);
    process.exit(1);
}
const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
const uiPort = config.UI_PORT || '8000';
const apiPort = config.API_PORT || '1800';
const adminPort = config.ADMIN_PORT || '18000';
const appEditable = config.API_EDITABLE;


// creaate or delete debug directory
const debugDir = path.join(dirPath, 'debug');

const flowJsonPath = path.join(__dirname, 'flow.json'); // path for the asr folder 
const flowAppJsonPath = path.join(__dirname, 'flow_AppManagement.json'); // path for the asr folder 

const flowJsonTargetPath = path.join(debugDir, 'flow.json'); //path where we write the flow file
const flowAppJsonTargetPath = path.join(debugDir, 'flow_AppManagement.json'); //path where we write the flowApp file file

if (appEditable) {
    // Create 'debug' directory if it doesn't exist
    if (!fs.existsSync(debugDir)) {
        fs.mkdirSync(debugDir);
        console.log(`Created debug directory: ${debugDir}`);


        // Helper to copy a file if it exists and target doesn't exist
        const copyToDebug = (sourcePath, targetPath) => {
            if (!fs.existsSync(targetPath) && fs.existsSync(sourcePath)) {
                const data = fs.readFileSync(sourcePath, 'utf-8');
                fs.writeFileSync(targetPath, data, 'utf-8');
                console.log(`Copied ${path.basename(targetPath)} to debug directory.`);
            }
        };

        // Attempt to copy the files
        copyToDebug(flowJsonPath, flowJsonTargetPath);
        copyToDebug(flowAppJsonPath, flowAppJsonTargetPath);
    }

    
} else {
    // Delete 'debug' directory if it exists
    if (fs.existsSync(debugDir)) {
        fs.rmSync(debugDir, { recursive: true, force: true });
        console.log(`Deleted debug directory: ${debugDir}`);
    }
}


// Start Express status server
const statusServer = express();
statusServer.get('/', (_, res) => res.send('Node-RED instances are running.'));
statusServer.listen(PORT, () => console.log(`Status server running at http://localhost:${PORT}`));


// the path from the flow file we read
var flowFilePath = appEditable ? flowJsonTargetPath :  flowJsonPath;
var adminFlowFile =  appEditable ? flowAppJsonTargetPath : flowAppJsonPath;

// Start Node-RED instances
console.log('Starting Node-RED instances...');
const nodeRed1 = fork(path.join(__dirname, 'server1.js'), [apiPort, flowFilePath, dirPath, 'Ecomm', appEditable]);
const nodeRed2 = fork(path.join(__dirname, 'server1.js'), [adminPort, adminFlowFile, dirPath, 'admin', appEditable]);


// Start UI5 server
startUI5Server(uiPort, UI5_FOLDER);
console.log("Ecomm UI Started...");

// Electron Window
let mainWindow = null;
function createWindow() {
    mainWindow = new BrowserWindow({
        width: 800,
        height: 600,
        webPreferences: {
            nodeIntegration: true
        }
    });

    setTimeout(() => {
       mainWindow.loadURL(`http://localhost:${uiPort}`);
        mainWindow.on('closed', () => {
            mainWindow = null;
        });
    }, 500);

    
}

app.whenReady().then(() => {
    createWindow();
    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        nodeRed1.kill();
        nodeRed2.kill();
        app.quit();
    }
});

// UI5 Server Function
function startUI5Server(port, filePath) {
    const app = express();

    const apiProxy = createProxyMiddleware('/api', {
        target: `:${1800}`,
        changeOrigin: true,
        pathRewrite: { '^/': '' },
        router: (req) => `http://${req.headers.host.split(':')[0]}:1800`,
        onProxyReq: (proxyReq, req, res) => {
            console.log(`Proxying request: ${req.method} ${req.url}`);
        },
    });

    app.use(apiProxy);
    app.use(express.static(filePath, { extensions: ['html', 'htm'] }));

    app.get('*', (req, res) => {
        res.sendFile(path.join(filePath, 'index.html'));
    });

    app.listen(port, () => {
        console.log(`SAPUI5 app running at http://localhost:${port}`);
    });
}


