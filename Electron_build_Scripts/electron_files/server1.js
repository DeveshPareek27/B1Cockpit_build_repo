const RED = require('node-red');
const http = require('http');
const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();



// Configrations
const PORT = process.argv[2] || 1891;
const fileName = process.argv[3] || 'flow.json';
const pdest = process.argv[4] || __dirname;
const adminUI = process.argv[5] || null;
const editable = process.argv[6] == "false" ? false : true;


// Debug info
// console.log("Editor UI enabled:", editable);
// console.log("Starting Node-RED instance...");
// console.log("Port:", PORT);
// console.log("Flow file:", fileName);
// console.log("User directory:", pdest);

// Validate the directory
if (!fs.existsSync(pdest) && !fs.statSync(pdest).isDirectory()) {
    console.error("Error: User directory does not exist ->", pdest);
    process.exit(1);
}






const server = http.createServer(app);

(async () => {
    let yoPilot = null;
    try {
        // Try to import yo-pilot dynamically
        yoPilot = (await import('yo-pilot')).default;
        console.log("✅ yo-pilot module loaded.");
    } catch (err) {
        if (err.code === 'ERR_MODULE_NOT_FOUND' || err.message.includes("Cannot find module 'yo-pilot'")) {
            console.warn("⚠️ Warning: 'yo-pilot' module not found. Continuing without it.");
        } else {
            console.error("❌ Error loading 'yo-pilot':", err);
        }
    }

    const settings = {
        uiPort: PORT,
        userDir: pdest + '\\',
        sep: path.sep,
        flowFile: fileName,
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
            yoPilot: yoPilot
        },
        functionExternalModules: true
    };


    // Serve Admin UI if enabled
    if (adminUI === "admin") {
        const uiPath = path.join(__dirname, "API", "ENT_RED_CustomNodes", "ENT_App_Common", "webapp_AppManagement");

        if (fs.existsSync(uiPath) && fs.statSync(uiPath).isDirectory()) {
            console.log("Serving Admin UI from:", uiPath);
            app.use(express.static(uiPath));

            app.get("/admin", (req, res) => {
                res.sendFile("index.html", { root: uiPath });
            });
        } else {
            console.error("Error: Admin UI path does not exist ->", uiPath);
        }
    }

    // * make it false so we can't access this in browser when the app is not accessible to browser.
    if (editable === false) {
        settings.httpAdminRoot = false;
    } else {
        console.log("Editor UI is enabled (editable = true)");
    }


    // Initialize Node-RED
    RED.init(server, settings);
    if (editable) {
        app.use(settings.httpAdminRoot, RED.httpAdmin);
    }
    app.use(settings.httpNodeRoot, RED.httpNode);

    // ✅ Start Inspector on Port 9229


    server.listen(PORT, () => {
        console.log(`Node-RED started on http://localhost:${PORT}`);
    });

    RED.start();

})();

// inspector.open(9229, '0.0.0.0', true);
// console.log('Debugger listening on ws://0.0.0.0:9229/');