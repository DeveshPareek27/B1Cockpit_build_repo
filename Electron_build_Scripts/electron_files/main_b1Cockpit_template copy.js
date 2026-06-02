// Import necessary libraries.
const express = require('express');
const http = require('http');
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
const server = http.createServer(app);
// const uiPath = path.join(__dirname, "UI", "dist");
const uiPath = path.join(scriptFilePath, "projects", "ENT_B1_Cockpit", "webapp");

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
        fs : require("fs"),
        excelJS: require('exceljs'),
        yoPilot: require('yo-pilot')
    },
    projectDir: scriptFilePath,
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        },
        writeToFile: {
            level: 'trace',
            metrics: false,
            filePath: '',
            handler: function (settings) {
                return function (msg) {
                    const logDir = path.join('.', 'log_flows');
                    if (!fs.existsSync(logDir)) {
                        fs.mkdirSync(logDir, { recursive: true });
                    }
                    const dateStr = new Date().toISOString().split('T')[0];
                    if (settings.filePath === undefined || settings.filePath === '') {
                        settings.filePath = path.join(logDir, `log_${dateStr}.txt`);
                    }
                    fs.appendFileSync(
                        settings.filePath,
                        new Date().toString() + ' -- ' + msg.msg + '\n'
                    );
                }
            }
        }
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
        mainWindow.loadURL(`http://localhost:${PORT}`);
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

// Start the Express server
server.listen(PORT, () => {
    console.log(`UI running at http://localhost:${PORT}/`);
    console.log(`Node-RED running at http://localhost:${PORT}/red`);
});

// Start Node-RED
RED.start();
