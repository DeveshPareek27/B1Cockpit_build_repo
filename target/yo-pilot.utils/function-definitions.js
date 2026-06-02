const wrapResponse=(response)=>{
    return {functionResults: response};
}

const functionDefinitions = function (client){
    return {
        loadServicesStateCount : async ()=>{
            return wrapResponse(await client.get('/B1_SERVICES?count=Y'));
        },

        loadAllServicesCompleteDetails : async ({serviceCode=null})=>{
           return wrapResponse(await client.get(`/B1_SERVICES${serviceCode ? `?ServiceCode=${serviceCode}` : ''}`));
        },

        setSchemaType : async ({ schema, type })=>{
           return wrapResponse(await client.post('/B1_COMPANIES-DEFINE_ROLE', { SCHEMA: schema, TYPE: type }));
        },

        serviceAction : async ({ serviceGroupInstance, action })=> {
           return wrapResponse(await client.post(`/B1_SERVICES-${action.toUpperCase()}?UI_SOURCE=AI_CALL`, { "ServiceGroup": serviceGroupInstance }));
        },

        loadCompaniesDetails: async ()=> {
           return wrapResponse(await client.get(`/B1_COMPANIES`));
        },

        loadDiskAndMemorySizesForSchema: async ({dbName})=>{
           return wrapResponse(await client.get(`/diskAndMemorySizesForSchema?dbName=${dbName}`));
        },

        loadMemorySizesofAllSchemas: async ()=> {
           return wrapResponse(await client.get(`/memorySizes`));
        },
        
        loadDiskSizessofAllSchemas: async ()=> {
           return wrapResponse(await client.get(`/diskSizes`));
        },

        loadOpenSessionAllSchemas: async ()=> {
           return wrapResponse(await client.get(`/openDBConns`));
        },

        loadBlockedTransactionsAllSchemas: async ()=> {
           return wrapResponse(await client.get(`/BLOCKED_TRANSACTIONS?countPerSchema=Y&count=Y`));
        },

        loadCopyCompanyJobs : async ()=>{
         return wrapResponse(await client.get(`/COPY_COMPANY_JOBS`))
        }
        //define functions here in this object
    }
    
}

module.exports = functionDefinitions;
// export default functionDefinitions;