/*
    Created By: Chandra Shekhar Vedi
    Purpose: This javaScript file is used to move all the project resources and 
            required framework resources to the dist folder

*/
const fs = require('fs');
const path = require('path');
const yaml = require('yaml');

function copyFilesAndFolders(sourceDir, targetDir, excludedItems = []) {
    // Check if the source directory exists
    if (!fs.existsSync(sourceDir)) {
        console.error(`Source directory "${sourceDir}" does not exist.`);
        return;
    }

    // Check if the target directory exists, if not, create it
    if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
        console.log(`Created target directory "${targetDir}".`);
    }

    // Get all items in the source directory
    const items = fs.readdirSync(sourceDir);

    items.forEach(item => {
        const sourcePath = path.join(sourceDir, item);
        const targetPath = path.join(targetDir, item);

        // // Check if the item is in the important or force copy list
        // if (importantAndForceCopyItems.includes(item)) {
        //     console.log(`Copying item "${item}" regardless.`);
        //     copyItem(sourcePath, targetPath);
        //     return;
        // }

        // Check if the item is in the excluded list
        let sItemPath = sourceDir + "/" + item;
        if (excludedItems.includes(sItemPath)) {
            console.log(`Skipping item "${item}" as it's in the excluded list.`);
            return;
        }

        // Check if the item is a directory
        if (fs.statSync(sourcePath).isDirectory()) {
            // If it's a directory, recursively copy its contents
            copyFilesAndFolders(sourcePath, targetPath, excludedItems);
            return;
        }

        // Otherwise, proceed with regular copy
        copyItem(sourcePath, targetPath);
    });
}

function copyItem(sourcePath, targetPath) {
    // If it's a file, copy it to the target directory
    fs.copyFileSync(sourcePath, targetPath);
    console.log(`Copied file "${sourcePath}" to "${targetPath}".`);
}

function copyFrameworkResources(sourceDir, targetDir, aLibraryFiles, aRequiredFiles) {
    // Join the both array of file paths
    let aFilesToCopy = aLibraryFiles.concat(aRequiredFiles);
    aFilesToCopy.forEach(sSrcPath => {
        let sTarget = sSrcPath.replace(sourceDir, targetDir);
        // Parse the target file path and check of the directory is created or not
        let oTargetInfo = path.parse(sTarget);
        // Check if the target directory exists, if not, create it
        if (!fs.existsSync(oTargetInfo.dir)) {
            fs.mkdirSync(oTargetInfo.dir, { recursive: true });
            console.log(`Created target directory "${targetDir}".`);
        }
        let oSourceInfo = path.parse(sSrcPath);
        if (fs.existsSync(oSourceInfo.dir) && fs.statSync(sSrcPath).isDirectory()) {
            copyFilesAndFolders(sSrcPath, sTarget);
        }else {
            if (fs.existsSync(oSourceInfo.dir)) {
                copyItem(sSrcPath, sTarget);
            }
            
        }
        
        
    });
}

function deleteFolderRecursive(directory) {
    if (fs.existsSync(directory)) {
        fs.readdirSync(directory).forEach(file => {
            const curPath = path.join(directory, file);
            if (fs.lstatSync(curPath).isDirectory()) {
                // Recursive call for directories
                deleteFolderRecursive(curPath);
            } else {
                // Delete file
                fs.unlinkSync(curPath);
                // console.log(`Deleted file: ${curPath}`);
            }
        });
        // After deleting all files, delete the directory itself
        fs.rmdirSync(directory);
        // console.log(`Deleted directory: ${directory}`);
    } else {
        console.error(`Directory "${directory}" does not exist.`);
    }
}

// Example usage:
const sourceDirectory = './www';
const targetDirectory = './dist';
const excludedItems = [
    './www/controller',
    './www/controls',
    './www/dbapi',
    './www/fragments',
    './www/dbapi',
    './www/util',
    './www/view',
    './www/Component-dbg.js',
    './www/Component-preload.js.map',
    './www/Component.js',
    './www/Component.js.map',
    './www/test-resources'];

// Copy framework resources
const ui5yamlfile = fs.readFileSync('./ui5.yaml', 'utf8');
const config = yaml.parse(ui5yamlfile);
let aReqLibraries = [];
let aReqThemeLibraries = [];
var aUi5Libs = config.framework.libraries;
aUi5Libs.forEach(element => {
    if (!element.name.includes('themelib')) {
        element.name = element.name.replace(/\./g, "/");
        aReqLibraries.push(element.name);
    }else {
        var sThemeLib = element.name.replace("_", "/").split("/")[1];
        aReqThemeLibraries.push(sThemeLib);
        // If need High contrast black and white theme files as well then uncomment
        // aReqThemeLibraries.push(sThemeLib + "_hcb");
        // aReqThemeLibraries.push(sThemeLib + "_hcw");
        
        if (sThemeLib.includes('belize')) {
            aReqThemeLibraries.push(sThemeLib + "_plus");
        }else {
            aReqThemeLibraries.push(sThemeLib + "_dark");
        }
        
        
    }
});
// these lilibraries are required by the framework even if not included in the ui5.yaml file
if (aReqLibraries.length) {
    aReqLibraries.push("sap/ui/layout");
    aReqLibraries.push("sap/ui/unified");
}

// Now create the path for all the required theme files and some other misc files
let aReqFrameworkFiles = [];
for (let i = 0; i < aReqLibraries.length; i++) {
    const libElement = aReqLibraries[i];
    for (let k = 0; k < aReqThemeLibraries.length; k++) {
        const themeElement = aReqThemeLibraries[k];
        if(libElement.includes('core')){
            aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/themes/${themeElement}/fonts`);
            aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/themes/${themeElement}/library.css`);
        }else {
            aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/themes/${themeElement}/library.css`);
        }
    }
    if (libElement.includes('core')) {
        aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/date`);
        aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/cldr`);
        aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/themes/base/fonts`);
    }
    aReqFrameworkFiles.push(`${sourceDirectory}/resources/${libElement}/messagebundle_en.properties`);
}

// Files use to initialize the UI5 framework
const forceCopyItems = [
    './www/resources/sap-ui-custom.js', 
    './www/resources/ui5loader.js', 
    './www/resources/ui5loader-autoconfig.js',
    './www/resources/sap/ui/export/provider/DataProviderBase.js',
    './www/resources/sap/ui/export/js/XLSXBuilder.js',
    './www/resources/sap/ui/export/js/libs/JSZip3.js',
    './www/resources/sap/ui/model/type/DateTime.js',
    './www/resources/sap/ui/model/type/Float.js',
    './www/resources/sap/ui/table/ColumnMenu.js',
    './www/resources/sap/ui/table/AnalyticalColumnMenu.js',
    './www/resources/sap/ui/table/menus/LegacyColumnMenuAdapter.js',
    './www/resources/sap/ui/unified/MenuTextFieldItem.js',
    './www/resources/sap/ui/codeeditor/CodeEditor.js'
];

// Call function to Copy project resources
copyFilesAndFolders(sourceDirectory, targetDirectory, excludedItems);

// Call function to copy framework resources
copyFrameworkResources(sourceDirectory, targetDirectory, aReqFrameworkFiles, forceCopyItems);

/*
    After the process is completed remove the source directory (optional)
    If you want to delete the www directory please uncomment the below line.
*/
// deleteFolderRecursive(sourceDirectory);
