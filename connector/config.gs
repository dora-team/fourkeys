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
 * @fileoverview Config to help user find and select a Four Keys enabled project.
 */


/** @const {string} Config ID for GCP Org. **/
const ORG = 'org';
/** @const {string} Config ID for GCP Project. **/
const PROJECT_ID = 'projectId';


/**
 * Returns the connector config that helps a user find and select a Four Keys Project
 * This is a stepped config that updates based on user selections.
 * https://developers.google.com/datastudio/connector/stepped-configuration
 * @param {!Object|undefined} configParams The current connector configuration.
 * @return {!Object} The updated connector onfiguration to show the user.
 */
function getSteppedConfig(configParams) {
  let config = DataStudioApp.createCommunityConnector().getConfig();

  // Step 1 - GCP organization selection.
  const orgs = cloud.getGcpOrgs();
  config = buildGcpOrgConfig(config, orgs);
  const orgId = getSelectedOrgId(configParams, orgs);

  // Step 2 - Four Keys Project Selection
  const projects = cloud.getFourKeysProjects(orgId);
  console.log(projects);
  console.log(config);
  config = buildProjectsConfig(config, projects);

  console.log(configParams);

  // Step 3 - Show summary of configuration.
  const projectId = configParams && configParams[PROJECT_ID];

  console.log(orgId);
  console.log("This is the projectId that matters");
  console.log(projectId);

  if (orgId && projectId) {
    config.newInfo()
        .setId('projectId')
        .setText('Cloud Project ID: ' + projectId);
  }

  if (!isConfigComplete(configParams, orgId, projectId)) {
    config.setIsSteppedConfig(true);
  }

  return config;
}


/**
 * Returns whether the given connector config is complete.
 * A config is complete when all questions for a decision path are answered.
 * @param {!Object|undefined} configParams The current connector configuration.
 * @param {string|undefined} orgId Selected org or undefined if not configured.
 * @param {string|undefined} projectId Google Cloud Project ID
 * @return {boolean} Returns true if the config is complete, false otherwise.
 */
function isConfigComplete(configParams, orgId, projectId) {
  if (configParams === undefined) {
    return false;
  }
  if (orgId && projectId) {
    return true;
  }
  return false;
}


/**
 * Returns the ID of the GCP org selected by the user.
 * @param {!Object|undefined} configParams The current connector configuration.
 * @param {!Array} orgs The list of GCP orgs for the user.
 * @return {string|undefined} The ID of the GCP org selected by the user or
 *     undefined if no org has been selected.
 */
function getSelectedOrgId(configParams, orgs) {
  if (orgs && orgs.length === 1) {
    return orgs[0].id;
  } else if (configParams) {
    return configParams[ORG];
  }
  return undefined;
}


/**
 * Build and return the config for GCP org selection.
 * If the user belongs to 'No Organization' don't show any GCP org config.
 * @param {!Object<!Config>} config The current connector config to update.
 * @param {!Array} orgs The list of GCP orgs for the user.
 * @return {!Array<!Object>} The config with the GCP org selector.
 */
function buildGcpOrgConfig(config, orgs) {
  if (orgs.length === 1 && orgs[0].id !== cloud.NO_ORG_ID) {
    config.newInfo().setId(ORG).setText('Organization: ' + orgs[0].name);
  } else if (orgs.length > 1) {
    const orgConfig = config.newSelectSingle();
    orgs.forEach(org => {
      orgConfig.addOption(
          config.newOptionBuilder().setLabel(org.name).setValue(org.id));
    });
    orgConfig.setId(ORG)
        .setName('Organization')
        .setHelpText('Select a GCP organization.')
        .setIsDynamic(true);
  }
  return config;
}

/**
 * Build and return the config dataset.
 * @param {!Object<!Config>} config The current connector config to update.
 * @param {!Array} projects The list of projects for the user.
 * @return {!Array<!Object>} The config with the GCP org selector.
 */
function buildProjectsConfig(config, projects) {
  const projectsConfig = config.newSelectSingle();
  projects.forEach(project => {
    projectsConfig.addOption(
        config.newOptionBuilder().setLabel(project.projectId)
            .setValue(project.projectId));
  });
  projectsConfig.setId(PROJECT_ID)
      .setName('Projects')
      .setHelpText('Select a project.')
      .setIsDynamic(true);
  return config;
}
