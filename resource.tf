/******************************************
  Get the organization
 *****************************************/
locals {
  org_id = data.google_organization.organization.org_id
}

data "google_organization" "organization" {
  domain = var.domain
}

data "google_client_openid_userinfo" "client_identity" {
}

####### Level 0 - Environment Folder Lookup (from env_code) #######

data "google_active_folder" "env_folder" {
  display_name = local.actual_env_code
  parent       = data.google_organization.organization.id
}

####### DYNAMIC FOLDER HIERARCHY LOOKUP #######
## Fetches folders recursively level by level ##

data "google_folders" "level_1_children" {
  parent_id = data.google_active_folder.env_folder.name
}

data "google_folders" "level_2_children" {
  parent_id = local.level_1_folder_id != null ? local.level_1_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_3_children" {
  parent_id = local.level_2_folder_id != null ? local.level_2_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_4_children" {
  parent_id = local.level_3_folder_id != null ? local.level_3_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_5_children" {
  parent_id = local.level_4_folder_id != null ? local.level_4_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_6_children" {
  parent_id = local.level_5_folder_id != null ? local.level_5_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_7_children" {
  parent_id = local.level_6_folder_id != null ? local.level_6_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_8_children" {
  parent_id = local.level_7_folder_id != null ? local.level_7_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_9_children" {
  parent_id = local.level_8_folder_id != null ? local.level_8_folder_id : data.google_active_folder.env_folder.name
}

data "google_folders" "level_10_children" {
  parent_id = local.level_9_folder_id != null ? local.level_9_folder_id : data.google_active_folder.env_folder.name
}
