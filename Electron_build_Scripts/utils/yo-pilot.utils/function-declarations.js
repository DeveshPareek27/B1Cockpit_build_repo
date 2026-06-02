const functionDeclarations = function (z) {
  return [
    {
      name: "loadBlockedTransactionsAllSchemas",
      description: `return the count blocked transactions as per schema/db/companies`
    },
    {
      name: "loadOpenSessionAllSchemas",
      description: `return the count of open sessions as per schemas/db/companies
      example output:
        {
        "DEV2_WTA_NEOSPERIENCE": {
            "OPEN_DB_CONN": 65
          }
        }
      `
    },
    {
      name: "loadMemorySizesofAllSchemas",
      description: `loads memory size of companies present in the system
          example output: {
              "DEV2_WTA_NEOSPERIENCE": {
                  "MEMORY_SIZE": 0.76
              },
              "DEV_WTA_NEOSPERIENCE": {
                  "MEMORY_SIZE": 0.11
              }
          }`,
    },
    {
      name: "loadDiskSizessofAllSchemas",
      description: `loads disk size of companies present in the system
          example output: {
              "DEV_NOVALCA": {
                  "DISK_SIZE": 17.03
                  },
              "DEV2_WTA_NEOSPERIENCE": {
                  "DISK_SIZE": 7.03
                  }
              }`,
    },
    {
      name: "setSchemaType",
      description: "Update or modify the type of schema, db or company",
      schema: z.object({
        schema: z.string().describe("Name of a schema/dbName(dbName of company)"),
        type: z.string().describe("type of schema/db which can be `TEST`, `PROD`, `DEMO` or `DEV`.")
      }).describe("Update the schema/db/company type")
    },
    {
      name: "serviceAction",
      schema: z.object({
        serviceGroupInstance: z.string().describe("Name of a Service Group Instance, it is service group and server location joined with @ eg. if ServiceGroup has valid a value ServiceGroupInstance = ServiceGroup@SLD_ServerLocation else ServiceGroupInstance = ServiceCode@SLD_ServerLocation,\n          if user is not provided exact information instantly load all service and show matching services to user and always ask for confirmation before restart"),
        action: z.string().describe("type of actions which can be `START`, `STOP` or `RESTART`.")
      }).describe("perform action in services according to service group, if user is not provided exact information, always load all service and show matching services to user and ask confirmation")
    },
    {
      name: "loadDiskAndMemorySizesForSchema",
      description: `return JSON object containing information about disk and memory of company/schema/db with help dbName or schema
              example output: {
                "MEMORY_SIZE": 0,
                "DISK_SIZE": 1.53
                }`,
        schema: z.object({
            dbName: z.string().describe("name of schema/dbName/companies dbName")
            }).describe("return size of disk and memory with the help of companies dbName")
    },
    {
      name: "loadServicesStateCount",
      description: `return JSON object containing count information about online services, services with warnings, and available servers.
              example output: {
                    "online": 10,
                    "warnings": 3, //warnings also can be offline services as well
                    "servers": 1,
                    "totalCount": 12
                }`,
    },
    {
      name: "loadCompaniesDetails",
      description: `return list of objects containing details about a company or db or schema
              example output: [{
                  "dbName": "SBODemoIT_COPY1", // it refers to schema or db
                  "cmpName": "zTEST *31-01-2025* OEC Computers IT 9.0",
                  "versStr": "1000260",
                  "LOC": "Italy",
                  "cmpType": "TEST", // if typeSts is unconfirmed then it's a suggested type of the company otherwise it's a actual type
                  "IS_DELETED_FROM_HANA": "N",
                  "B1_COMPANY": "Y",
                  "typeSts": "0. UNCONFIRMED - 1" // this is used to group the companies according to status, also tells if a company is unconfirmed.
          }]
          You can view more details by navigating displayed as a clickable link make sure it include in all response:  to <a href="/#/CompaniesStatus" target="_self" style="#5a5ae0:blue;text-decoration:underline">Companies Status</a>.`,
    },
    {
      name : "loadCopyCompanyJobs",
      description : `Retrieve information about all copy copmany jobs
      Example Output:
      [{
          "JOB_ID": "05a1cfe8-7737-45e9-9c89-bf466000e470",
          "JOB_NAME": "Test_Copy_Com_fun",
          "BASE_SCHEMA": "BI_ENTITEC_DEV_COPY",
          "TARGET_SCHEMA": "BI_ENTITEC_DEV_TEST_COPY",
          "FREQUENCY": "D",
          "START_ON": "2025-02-12 11:27:03",
          "END_ON": "2025-02-12 11:45:17",
          "SCHEDULED": "Y",
          "JOB_TYPE": "COPY_COMPANY",
          "CONFIGURATION": "{\"BASE_SCHEMA_NAME\":\"zTEST *11-01-2025* *BI ENTITEC*\",\"BaseSchemaType\":\"TEST\",\"TARGET_SCHEMA_NAME\":\"zTEST *$$DATE_DDMMYYYY$$* $$BASE_COMP_NAME$$\",\"TargetSchemaType\":\"TEST\",\"MaxRetryCount\":1,\"RetryInterval\":10,\"OPERATION_TYPE\":\"FULL\",\"OPERATION_PATH\":\"$$PATH_EXP_IMP$$/$$BASE_COMP_NAME$$/Export_$$YYYYMMDD_HHMMSS$$\",\"Export_Import_Type\":\"EXP_IMP-REPLACE\",\"Attach_Path_Remap_Existing_Documents\":\"N\",\"Custom_SQL_Queries\":[],\"NOTIFY\":{\"USER_TYPE\":[\"MULTI_CHOICE_LIST\"],\"USER_LIST\":[\"62ba1086-6082-45c0-a567-de748dd1774c\"],\"EMAIL_LIST\":[]},\"UserName\":\"manager\",\"Password\":\"1234\",\"JOB_NAME\":\"Test_Copy_Com_fun\",\"JOB_TYPE\":\"COPY_COMPANY\",\"TARGET_SCHEMA\":\"BI_ENTITEC_DEV_TEST_COPY\",\"BASE_SCHEMA\":\"BI_ENTITEC_DEV_COPY\",\"External_Schema_Deps\":[],\"WordPath\":\"\\\\\\\\hanab1hdev20\\\\SAP_PATHS\\\\ATTACHMENTS\\\\SBODEMOIT2222\\\\Bitmapss\\\\\",\"ExcelPath\":\"\\\\\\\\hanab1hdev20\\\\SAP_PATHS\\\\ATTACHMENTS\\\\SBODEMOIT2222\\\\Excel\\\\Excel\",\"BitmapPath\":\"\\\\\\\\hanab1hdev20\\\\SAP_PATHS\\\\ATTACHMENTS\\\\SBODEMOIT2222\\\\Attachments\\\\\",\"AttachPath\":\"\\\\\\\\hanab1hdev20\\\\SAP_PATHS\\\\ATTACHMENTS\\\\SBODEMOIT2222\\\\Attachmens\",\"ExtPath\":\"\\\\\\\\hanab1hdev20\\\\SAP_PATHS\\\\ATTACHMENTS\\\\SBODEMOIT2222\\\\Attachments\\\\\",\"XmlPath\":\"\\\\\\\\hanab1hdev20\\\\SAP_PATHS\\\\ATTACHMENTS\\\\SBODEMOIT2222\\\\XML\\\\\"}",
          "STATUS": "A",
          "LOG_STATUS": "E",
          "LOG_STARTED_ON": "2025-02-12 11:37:09"
      }]
      You can view more details by navigating displayed as a clickable link make sure it include in all response:  to <a href="/#/CreateJob" target="_self" style="color:#5a5ae0;text-decoration:underline">Copy Copmany </a>.`,
    },
    {
      name: "loadAllServicesCompleteDetails",
      description: `Retrieve information about all services, if service code not provided load all services and check for asked details in the result.
      Example output: 
      [{
          "ServerVisualOrder": 1,
          "SLD_ServerLocation": "hanab1hdev20", // Location of server where service residing
          "VisualOrder": 0,
          "ServiceCode": "HANA_IndexServer", // unique id of a service
          "ServiceName": "HANA DB - Index Server", // Service Name
          "ServiceInstance": "HANA_IndexServer@hanab1hdev20",
          "STATUS": "Online", // current status of service
          "ServiceGroup": "",
          "EXTRA_INFO": "\n                                Code - 0\n                                \n                                stdout -  \n                                    Process Name = sapinit\npid = 7597\nState = S (sleeping)\nuptime = 4days 09:50:22\npid start time = Sun Jan 26 04:01:37 2025\n\n                                \n                                    ",
          "SLD_AccessURL": "NDB@hanab1hdev20:30013", // url to access service within the network
          "DependsOnInstance": "",
          "ServiceGroupInstance": "HANA_IndexServer@hanab1hdev20", // can be used for perfoming action on service like Restart, start, start.
          "OSCanRestart": "Y",
          "CREATED_ON": "2025-01-30T12:52:00.000Z",
          "STATUS_INFO": {
          "Actual_Info": "{\n\n"Status": "Online",\n\n"Code": "Custom Check",\n\n"Message": "HANA DB - Index Server"\n}",
          "Formal_Info": "{\n\n"Status": "Online",\n\n"Code": "0",\n\n"Message": "\n                                    \n                                      sapinit.service - LSB: Start the sapstartsrv\n     Loaded: loaded (/etc/init.d/sapinit; generated)\n     Active: active (exited) since Sun 2025-01-26 03:32:40 CET; 4 days ago\n       Docs: man:systemd-sysv-generator(8)\n    Process: 2401 ExecStart=/etc/init.d/sapinit start (code=exited, status=0/SUCCESS)\n\nNotice: journal has been rotated since unit was started, output may be incomplete.\n\n                                \n                                    \n                                    "\n}"
          },
          "SubServices": []
      }]
        You can view more details by navigating displayed as a clickable link make sure it include in all response:  to <a href="/#/ServiceStatus" target="_self" style="color:#5a5ae0;text-decoration:underline">Service Status</a>.`,
      schema: z.object({
        serviceCode: z.string().optional().describe("ServiceCode is a unique id for a service type this not a service name, service code can be provided user or can be found by fetching all services")
      }).describe("With the help of this parameter it can specific type of service, if service code not provided it will load all services and check for asked details in the result")
    },
  ].reduce((oFnDec, item)=>{ oFnDec[item.name] = item; return oFnDec}, {});
};

module.exports = functionDeclarations;
// export default functionDeclarations;