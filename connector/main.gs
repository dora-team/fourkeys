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
 * @fileoverview Defines the community connector interfaces required by Data
 * Studio.
 */


/**
 * https://developers.google.com/datastudio/connector/reference#isadminuser
 *
 * @return {boolean} Returns if the effective user is an admin.
 */
function isAdminUser() {
  const userEmail = Session.getEffectiveUser().getEmail();
  // List of admin users are kept in script property
  let scriptProperties = PropertiesService.getScriptProperties();
  let admins = scriptProperties.getProperty("admins");
  admins = JSON.parse(admins);
  const response = admins.indexOf(userEmail) >= 0;
  return response;
}


/**
 * Return the secondary auth configuration required by the connector.
 *
 * Auth type is NONE because the connector uses only Google APIs and all
 * auth scopes required are listed in the oauthScopes property of the manifest
 * (appsscript.json). Users will be prompted to grant authorization for the
 * required scopes during the primary/initial auth flow initiated at the time of
 * installation.
 *
 * https://developers.google.com/datastudio/connector/reference#getauthtype
 *
 * @return {!Object} The auth configuration required by the connector.
 */
function getAuthType() {
  const cc = DataStudioApp.createCommunityConnector();
  return cc.newAuthTypeResponse().setAuthType(cc.AuthType.NONE).build();
}


/**
 * Return the config for selecting the Four Keys Project.
 *
 * https://developers.google.com/datastudio/connector/reference#getconfig
 *
 * @param {!Object} request The current config based on user selections.
 * @return {!Object} The connector configuration to show the user.
 */
function getConfig(request) {
  try {
    return getSteppedConfig(request.configParams).build();
  } catch(e) {
    console.error(e);
  }
}


/**
 * Return all of the fields representing the Four Keys schema.
 *
 * https://developers.google.com/datastudio/connector/reference#getschema
 *
 * @param {!Object} request The connector configuration. This contains the
 *     user provided values that define the configuration of the connector.
 * @return {!Array<!Object>} The list of fields for the Four Keys schema, in the
 *     format expected by Data Studio.
 */
function getSchema(request) {
  try {
    return getBqQueryConfig(request);
  } catch (e) {
    console.error(e);
  }
}


/**
 * Return the BigQuery query configuration for the selected Four Keys BigQuery
 * project.
 *
 * https://developers.google.com/datastudio/connector/reference#getdata
 * https://developers.google.com/datastudio/connector/advanced-services
 *
 * @param {!Object} request The data source configuration based on user
 *     selections, including which project and tables to use for the data query.
 * @return {!Object} The BigQuery query configuration.
 */

function getData(request) {
  try {
    return getBqQueryConfig(request);
  } catch (e) {
    console.error(e);
  }
}
