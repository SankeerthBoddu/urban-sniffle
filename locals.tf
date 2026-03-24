locals {
  ##### Convert and flatten the list of APIs to activate into a set for uniqueness
  services = toset(flatten(var.activate_apis))

  ##### Get the first project factory module output if it exists, otherwise null
  project_factory_output = length(module.project-factory) > 0 ? module.project-factory[0] : null

  ##### Determine the notification topic based on domain and environment code
  ##### uses different topics for test (siroot.net) vs production environments (citi.com)
  obs_notification_topic = (
    var.domain == "siroot.net" ? "test-notification-topic" :
    var.domain == "citi.com" && var.env_code == "se" ? "pst-se-alert-notification-netcool" :
    var.domain == "citi.com" && var.env_code == "np" ? "pst-np-alert-notification-netcool" :
    var.domain == "citi.com" && var.env_code == "pd" ? "pst-pd-alert-notification-netcool" :
    null
  )

  ##### Standard required labels for all GCP resources
  required_labels = {
    project_label             = var.project_label
    project_owner             = var.project_owner
    sector                    = var.sector
    app_id                    = var.application_id
    application_id            = var.application_id
    request_id                = var.request_id
    platform_environment      = var.platform_environment
    env_code                  = var.env_code
    central_obs_mc_prj_id     = var.obs_monitoring_project_id == null || var.obs_monitoring_project_id == "NA" ? "none" : lower(var.obs_monitoring_project_id)
    central_processing_prj_id = var.obs_notification_project_id == null || var.obs_notification_project_id == "NA" ? "none" : lower(var.obs_notification_project_id)
    host_network_prj_id       = var.network_hosting_project_id == null || var.network_hosting_project_id == "NA" ? "none" : lower(var.network_hosting_project_id)
  }

  ##### Sanitize var.labels: convert "NA" to "none"
  sanitized_var_labels = {
    for key, value in var.labels : key => value == "NA" ? "none" : value
  }

  ##### Merge required labels with any additional custom labels
  labels = merge(local.required_labels, local.sanitized_var_labels)

  ##### Map environment codes to their corresponding folder names in GCP organization
  env_code_mapping = {
    "bt" = "fldr-bootstrap"
    "cm" = "fldr-common"
    "np" = "fldr-non-production"
    "pd" = "fldr-production"
    "st" = "fldr-securitytesting"
    "se" = "fldr-service-engineering"
  }

  ##### Resolve the actual folder name from the environment code
  actual_env_code = lookup(local.env_code_mapping, var.env_code, null)

  ##### DYNAMIC FOLDER PATH RESOLUTION & CREATION LOGIC
  # This block implements a robust, sequential folder path resolution.
  # It correctly identifies existing folders and separates the logic for what needs to be created
  # from where the project will ultimately be placed, avoiding cyclic dependencies.

  # 1. Normalize the input path and split it into segments.
  usecase_path_normalized = trimprefix(trimsuffix(var.usecase_fldr, "/"), "/")
  path_segments           = local.usecase_path_normalized != "" ? split("/", local.usecase_path_normalized) : []
  path_depth              = length(local.path_segments)
  path_depth_valid        = local.path_depth <= var.max_folder_depth ? true : tobool("ERROR: usecase_fldr '${var.usecase_fldr}' has depth ${local.path_depth} which exceeds max_folder_depth of ${var.max_folder_depth}")

  # 2. Sequentially find existing folders, level by level explicitly connecting parent scopes.
  level_1_target_name = local.path_depth >= 1 ? "${var.folder_prefix}-${local.path_segments[0]}" : ""
  level_1_matches     = [for f in data.google_folders.level_1_children.folders : f if f.display_name == local.level_1_target_name]
  level_1_folder_id   = length(local.level_1_matches) > 0 ? local.level_1_matches[0].name : null

  level_2_target_name = local.path_depth >= 2 ? "${var.folder_prefix}-${local.path_segments[1]}" : ""
  level_2_matches     = [for f in data.google_folders.level_2_children.folders : f if f.display_name == local.level_2_target_name && local.level_1_folder_id != null]
  level_2_folder_id   = length(local.level_2_matches) > 0 ? local.level_2_matches[0].name : null

  level_3_target_name = local.path_depth >= 3 ? "${var.folder_prefix}-${local.path_segments[2]}" : ""
  level_3_matches     = [for f in data.google_folders.level_3_children.folders : f if f.display_name == local.level_3_target_name && local.level_2_folder_id != null]
  level_3_folder_id   = length(local.level_3_matches) > 0 ? local.level_3_matches[0].name : null

  level_4_target_name = local.path_depth >= 4 ? "${var.folder_prefix}-${local.path_segments[3]}" : ""
  level_4_matches     = [for f in data.google_folders.level_4_children.folders : f if f.display_name == local.level_4_target_name && local.level_3_folder_id != null]
  level_4_folder_id   = length(local.level_4_matches) > 0 ? local.level_4_matches[0].name : null

  level_5_target_name = local.path_depth >= 5 ? "${var.folder_prefix}-${local.path_segments[4]}" : ""
  level_5_matches     = [for f in data.google_folders.level_5_children.folders : f if f.display_name == local.level_5_target_name && local.level_4_folder_id != null]
  level_5_folder_id   = length(local.level_5_matches) > 0 ? local.level_5_matches[0].name : null

  level_6_target_name = local.path_depth >= 6 ? "${var.folder_prefix}-${local.path_segments[5]}" : ""
  level_6_matches     = [for f in data.google_folders.level_6_children.folders : f if f.display_name == local.level_6_target_name && local.level_5_folder_id != null]
  level_6_folder_id   = length(local.level_6_matches) > 0 ? local.level_6_matches[0].name : null

  level_7_target_name = local.path_depth >= 7 ? "${var.folder_prefix}-${local.path_segments[6]}" : ""
  level_7_matches     = [for f in data.google_folders.level_7_children.folders : f if f.display_name == local.level_7_target_name && local.level_6_folder_id != null]
  level_7_folder_id   = length(local.level_7_matches) > 0 ? local.level_7_matches[0].name : null

  level_8_target_name = local.path_depth >= 8 ? "${var.folder_prefix}-${local.path_segments[7]}" : ""
  level_8_matches     = [for f in data.google_folders.level_8_children.folders : f if f.display_name == local.level_8_target_name && local.level_7_folder_id != null]
  level_8_folder_id   = length(local.level_8_matches) > 0 ? local.level_8_matches[0].name : null

  level_9_target_name = local.path_depth >= 9 ? "${var.folder_prefix}-${local.path_segments[8]}" : ""
  level_9_matches     = [for f in data.google_folders.level_9_children.folders : f if f.display_name == local.level_9_target_name && local.level_8_folder_id != null]
  level_9_folder_id   = length(local.level_9_matches) > 0 ? local.level_9_matches[0].name : null

  level_10_target_name = local.path_depth >= 10 ? "${var.folder_prefix}-${local.path_segments[9]}" : ""
  level_10_matches     = [for f in data.google_folders.level_10_children.folders : f if f.display_name == local.level_10_target_name && local.level_9_folder_id != null]
  level_10_folder_id   = length(local.level_10_matches) > 0 ? local.level_10_matches[0].name : null

  # 4. Determine the last level in the path that was successfully found.
  last_existing_level = (
    local.level_10_folder_id != null ? 10 :
    local.level_9_folder_id != null ? 9 :
    local.level_8_folder_id != null ? 8 :
    local.level_7_folder_id != null ? 7 :
    local.level_6_folder_id != null ? 6 :
    local.level_5_folder_id != null ? 5 :
    local.level_4_folder_id != null ? 4 :
    local.level_3_folder_id != null ? 3 :
    local.level_2_folder_id != null ? 2 :
    local.level_1_folder_id != null ? 1 :
    0
  )

  # 5. Identify the PARENT for folder creation. This is the ID of the deepest existing folder found.
  creation_parent_folder_id = (
    local.last_existing_level == 10 ? local.level_10_folder_id :
    local.last_existing_level == 9  ? local.level_9_folder_id :
    local.last_existing_level == 8  ? local.level_8_folder_id :
    local.last_existing_level == 7  ? local.level_7_folder_id :
    local.last_existing_level == 6  ? local.level_6_folder_id :
    local.last_existing_level == 5  ? local.level_5_folder_id :
    local.last_existing_level == 4  ? local.level_4_folder_id :
    local.last_existing_level == 3  ? local.level_3_folder_id :
    local.last_existing_level == 2  ? local.level_2_folder_id :
    local.last_existing_level == 1  ? local.level_1_folder_id :
    data.google_active_folder.env_folder.name
  )

  # 6. Prepare the path of ONLY the folders that need to be created.
  remaining_segments   = slice(local.path_segments, local.last_existing_level, local.path_depth)
  folder_creation_path = length(local.remaining_segments) > 0 ? join("/", [for segment in local.remaining_segments : "${var.folder_prefix}-${segment}"]) : ""
  needs_folder_creation = length(local.remaining_segments) > 0

  # 7. Determine the FINAL folder ID where the project will be placed.
  #    Uses "level_0", "level_1"... syntax to match terraform module map keys.
  resolved_folder_id = !local.needs_folder_creation ? local.creation_parent_folder_id : (
    module.project-factory[0].created_folders.folders_created["level_${tostring(length(local.remaining_segments) - 1)}"]
  )
}
