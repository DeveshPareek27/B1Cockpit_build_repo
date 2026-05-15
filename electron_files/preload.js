const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("api", {
    startProcess: (command, cwd) => ipcRenderer.send("start-process", { command, cwd }),
    onLogMessage: (callback) => ipcRenderer.on("log-message", (event, message) => callback(message)),
    invoke: (channel, data) => ipcRenderer.invoke("validate-port", { channel, data   }),
    updateJson: (channel, data) => ipcRenderer.invoke("update-json", { channel, data   })
});
