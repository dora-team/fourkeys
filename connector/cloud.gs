/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/**
 * @fileoverview Helpers to interact with GCP APIs to retrieve and
 * find Four Keys tables.
 */


/**
 * Cloud API services namespace.
 * @const {!Object}
 */
const cloud = {};
/** @const {!Object} **/
cloud.datacatalogApi = {};
/** @const {!Object} **/
cloud.cloudresourcemanagerApi = {};
/** @const {!Object} **/
cloud.util = {};


/** @const {string} **/
cloud.ORG_CACHE_KEY = 'orgs';

/** @const {string} **/
cloud.PROJECTS_CACHE_KEY = 'projects';

/** @const {number} **/
cloud.ORG_CACHE_EXPIRY_IN_SECONDS = 120;

/** @const {string} **/
cloud.ORG_ACTIVE_STATUS = 'ACTIVE';

/** @const {string} **/
cloud.ORG_ID_PREFIX = 'organizations/';

/** @const {string} **/
cloud.TABLE_CACHE_KEY = 'tables_';

/** @const {number} **/
cloud.TABLE_CACHE_EXPIRE_IN_SECONDS = 300;

/**
 * The ID for No Organization.
 * @const {string}
 */
cloud.NO_ORG_ID = 'NO_ORG';


/**
 * No organization representation.
 * @const {!Object}
 **/
cloud.NO_ORG = {
  name: 'No Organization',
  id: cloud.NO_ORG_ID,
  status: cloud.ORG_ACTIVE_STATUS,
};


/**
 * The following defines the Data Catalog query that will find datasets named
 * "four_keys"
 * @const {string}
 */
cloud.FOUR_KEYS_DATA_CATALOG_QUERY = [
  'type=dataset',
  'system=bigquery',
  'name:four_keys',
].join(' ');



/**
 * The maximum number of search results to fetch from a Data Catalog search
 * query.
 * @const {number}
 */
cloud.datacatalogApi.MAX_SEARCH_RESULTS = 500;


/**
 * Returns the list of GCP organizations the authorized users belongs to.
 * @return {!Array<!Object>} A list of objects representing orgs, where each org
 *     has a name, id and status property.
 */
cloud.getGcpOrgs = () => {
  let gcpOrgs = CacheService.getUserCache().get(cloud.ORG_CACHE_KEY);
  if (gcpOrgs != null) {
    return JSON.parse(gcpOrgs);
  }

  const orgs = cloud.cloudresourcemanagerApi.orgSearch();
  if (orgs) {
    gcpOrgs = orgs.filter(org => {
                    return org.lifecycleState === cloud.ORG_ACTIVE_STATUS;
                  })
                  .map(org => {
                    return {
                      name: org.displayName,
                      id: org.name.replace(cloud.ORG_ID_PREFIX, ''),
                      status: org.lifecycleState,
                    };
                  });
  } else {
    gcpOrgs = [cloud.NO_ORG];
  }
  CacheService.getUserCache().put(
      cloud.ORG_CACHE_KEY, JSON.stringify(gcpOrgs),
      cloud.ORG_CACHE_EXPIRY_IN_SECONDS);
  return gcpOrgs;
};


/**
 * Returns the list of active GCP projects the authorized user has access to.
 * @return {!Array<!Object>} A list of project_ids
 */
cloud.getNoOrgProjects = () => {
  let gcpProjects = CacheService.getUserCache().get(cloud.PROJECTS_CACHE_KEY);
  if (gcpProjects != null) {
    return JSON.parse(gcpProjects);
  }

  const projects = cloud.cloudresourcemanagerApi.projectList();

  gcpProjects = [];

  if (projects) {
    projects.forEach((project) => {
      gcpProjects.push(project.projectId);
    });
  }

  return gcpProjects;
};


/**
 * Returns the list of Projects with a four_keys dataset that the
 * authorized user has access to.
 * @param {string} orgId The organization ID to ensure is included in the scope
 *     of the search.
 * @return {!Array<!Object>} A list of Objects representing GCP Projects, where
 *     each project has a name and a linkedResource to the four_keys BQ dataset
 */


cloud.getFourKeysProjects = (orgId) => {
  const cacheKey = cloud.TABLE_CACHE_KEY + orgId;
  let dataset = CacheService.getUserCache().get(cacheKey);
  if (dataset != null) {
    return JSON.parse(dataset);
  }
  if (orgId === cloud.NO_ORG_ID) {
    orgId = '';
  }

  const searchCatalogResults = cloud.datacatalogApi.catalogSearch(
      orgId, cloud.FOUR_KEYS_DATA_CATALOG_QUERY);

  const projects = searchCatalogResults.map(result => {
    return {
      projectId: result.linkedResource.split("/")[4],
      linkedResource: result.linkedResource
    };
  });

  CacheService.getUserCache().put(cacheKey, JSON.stringify(projects));
  return projects;
};



/**
 * Uses the Cloud Resource Manageer API to search for the organization resources
 * visible to the authorized user. See
 * https://cloud.google.com/resource-manager/reference/rest/v1/organizations/search.
 * @return {!Array<!Object>} A list of orgs.
 */
cloud.cloudresourcemanagerApi.orgSearch = () => {
  const url =
      'https://cloudresourcemanager.googleapis.com/v1/organizations:search';
  const options = {
    method: 'post',
    headers: {Authorization: 'Bearer ' + ScriptApp.getOAuthToken()},
  };
  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());
  return result.organizations;
};


/**
 * Uses the Cloud Resource Manageer API to search for the projects
 * visible to the authorized user. See
 * https://cloud.google.com/resource-manager/reference/rest/v1/projects.
 * @return {!Array<!Object>} A list of projects.
 */
cloud.cloudresourcemanagerApi.projectList = () => {
  const url =
      'https://cloudresourcemanager.googleapis.com/v1/projects?filter=lifecycleState%3DACTIVE';
  const options = {
    method: 'get',
    headers: {Authorization: 'Bearer ' + ScriptApp.getOAuthToken()},
  };
  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());
  return result.projects;
};


/**
 * Uses the Data Catalog API to look up the table by tableResource
 * @param {string} tableResource
 * @return {string} BigQuery Table.
 */
cloud.getTableByEntry = (tableResource) => {
  const url = 'https://datacatalog.googleapis.com/v1/entries:' +
      'lookup?linkedResource=' + tableResource;
  const options = {
    method: 'get',
    headers: {Authorization: 'Bearer ' + ScriptApp.getOAuthToken()},
    contentType: 'application/json',
  };
  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());
  return result;
};


/**
 * Uses the Data Catalog API to search for the four_keys datasets visible to the authorized user.
 * Based on the search syntax as defined
 * in https://cloud.google.com/data-catalog/docs/how-to/search-reference
 * @param {string} orgId The GCP org ID to include in the scope of the search.
 * @param {string} query The Data Catalog search query to execute.
 * @return {!Array<!Object>} List of matching search results.
 */
cloud.datacatalogApi.catalogSearch = (orgId, query) => {
  if (orgId === ''){
    scopeJSON = {includeProjectIds: cloud.getNoOrgProjects()};
  }
  else{
    scopeJSON = {includeOrgIds: [orgId]};
  }

  const url = 'https://datacatalog.googleapis.com/v1beta1/catalog:search';
  const search = {
    scope: scopeJSON,
    query: query,
    pageSize: cloud.datacatalogApi.MAX_SEARCH_RESULTS,
  };

  const options = {
    method: 'post',
    headers: {Authorization: 'Bearer ' + ScriptApp.getOAuthToken()},
    contentType: 'application/json',
    payload: JSON.stringify(search),
  };
  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());
  return result.results || [];
};
