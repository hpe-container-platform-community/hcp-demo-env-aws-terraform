import os

GLOBAL_SETTINGS = {
"BASE_URL" : 'https://127.0.0.1:8080',
"CONFIG_URL" : "/api/v1/config/",
"LOCK_URL" : "/api/v1/lock/",
"UPGRADE_URL" : "/api/v1/upgrade/",
"DATACONN_URL" : "/api/v1/dataconn/",
"TESTDATACONN_URL" : "/api/v1/testdataconn/",
"JOB_URL" : "/api/v1/job/",
"CLUSTER_URL" : "/api/v1/cluster/",
"ROLE_URL" : "/api/v1/role/",
"USER_URL" : "/api/v1/user/",
"TENANT_URL" : "/api/v1/tenant/",
"BLUEDATA_BASE_PATH" : "/srv/bluedata/",
"RESULTS_BASE_PATH" : "/results/",
"LOGIN_URL" : "/api/v1/login",
"LOGOUT_URL" : "/api/v1/logout",
"LICENSE_URL"  : "/api/v1/license/",
"FLAVOR_URL" : "/api/v1/flavor/",
"BDS_USER" : "demo.user",
"BDS_ADMIN" : "admin",
"BDS_MEMBER_ROLE" : "Member",
"BDS_TENANT_ADMIN_ROLE" : "Admin",
"BDS_SITE_ADMIN_ROLE" : "Site Admin",
"BDS_DEFAULT_TENANT" : "Demo Tenant",
"BDS_ADMIN_TENANT" : "Site Admin",
"BDS_PASSWORD" : "admin123",
"BDS_SESSION_TAG" : "X-BDS-SESSION",
"COMMON_LABEL_PARAM" : "?label",
"COMMON_QUOTA_PARAM" : "?quota",
"USER_PARAM" : "?user",
"STATS_URL" : "/api/v1/stats/",
"TENANT_PARAM" : "?tenant",
"DCO_URL" : "/api/v1/dataconn/",
"CATALOG_URL" : "/api/v1/catalog/",
"RESOURCE_CONFIG_URL" : "/api/v1/install?install_reconfig",
"HTTPFS_USER" : "httpfs",
"BDS_TENANT_NAME" : "Demo Tenant",
"BDS_TENANT_ADMIN" : "admin",
"BDS_TENANT_ADMIN_PASSWORD" : "admin123"
}

def get_setting(key):
    env_name = "BD_SETTING_" + key
    env_val = os.environ.get(env_name)
    if env_val is None:
        return GLOBAL_SETTINGS[key]
    else:
        return env_val