# Upgrade from Search Guard FLX 1.x.x to 2.0.0

Search Guard 2.0.0 is not backwards compatible with previous versions. If you want to upgrade from version 1.x.x to 2.0.0, you will need to follow some additional steps. However, the upgrade process will differ for environments with and without the Multi-Tenancy feature enabled. It is strongly recommended that you read the entire page and clarify all doubts before starting the upgrade.

## How to check if Multi-Tenancy is enabled
To verify if Multi-Tenancy is enabled, please check the Kibana configuration file and the existence of indices dedicated to each tenant.
(For future information, please refer to the [documentation](https://docs.search-guard.com/latest/kibana-multi-tenancy)).

## Upgrading environments with disabled Multi-Tenancy 
The upgrade procedure for environments with disabled Multi-Tenancy is straightforward, but if you are using Kibana, it may be necessary to change the Kibana users' roles. Search Guard provides predefined roles for users who are authorized to access the Kibana interface, such as `SGS_KIBANA_USER`, `SGS_KIBANA_USER_NO_GLOBAL_TENANT`, `SGS_KIBANA_USER_NO_DEFAULT_TENANT`. However, if Multi-Tenancy is not enabled, users with these roles cannot access the Kibana user interface when Search Guard is upgraded to version 2.0.0. Instead, the system administrator should assign or map the `SGS_KIBANA_USER_NO_MT` role to users accessing Kibana.

Roles can be customized by editing the ```.Values.common.rolesmapping``` value in Helm charts.

## Upgrading environments with enabled Multi-Tenancy


> **VERY IMPORTANT FOR DATA SAFETY**                                                    
> 
> Before starting Search Guard's upgrade from version 1.x.x to a newer version along with Search Guard 2.0.0, you need to back up your whole cluster. Furthermore, it is strongly advised that the upgrade procedure is tested first in a test environment containing a copy of the production cluster. If everything goes well, repeat the same procedure for the production cluster. The upgrade procedure can only be performed when an upgraded environment works with installed Search Guard 1.4.0 or 1.6.0 for Elasticsearch 8.7.x.
> ### Troubleshooting
> In case of any issues, if the cluster encounters problems, the administrator should consider reverting to the previously backed-up version.
> ### Disable automatic sgctl confguration update
> During the update, sgctl should be turned off. Make sure the parameter `.Values.common.update_sgconfig_on_change` is set to false.
> ```
> common:
>  update_sgconfig_on_change: false
> ```
> ### Cluster Restoration 
> If needed, the administrator should restore the cluster to the version from which the upgrade was initiated. A full backup is necessary before the upgrade due to the impossibility of downgrading Elasticsearch.

### Multi-Tenancy feature

Search Guard 2.0.0 contains a new Multi-Tenancy feature implementation. This implementation is not backwards compatible, and its behaviour might differ slightly from that used in Search Guard 1.x.x. Therefore, the system administrator is advised to familiarize themselves with the [limitations](https://docs.search-guard.com/latest/kibana-multi-tenancy#limitations-of-multi-tenancy-implementation-in-for-flx-v200-and-higher) related to the new implementation. Furthermore, the implementation of the new Multi-Tenancy feature does not support private tenants.

### Upgrading steps
The upgrade procedure should first be carried out in the test environment, which is a copy of the production cluster. Once this test is accomplished successfully, you can upgrade the production environment.

1. Backup.\
   Preparing a backup is crucial due to Elasticsearch's inability to downgrade the cluster node. Therefore, if the upgrade procedure is not accomplished, you will need backups to restore the cluster to its previous version. Please use the following [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) to create the cluster backup. Additionally, the system administrator should follow [Search Guard backup and restore guidance](https://docs.search-guard.com/latest/search-guard-index-maintenance#backup-and-restore) to perform the backup of the Search Guard configuration. It is also worth testing if the created backups can be restored.

2. Upgrade Search Guard to version 1.4.0 or 1.6.0 and Elasticsearch to version 8.7.1 using helm upgrade

    The example Helm charts values for Search Guard 1.6.0 and Elasticsearch 8.7.1 
    ```yml
    common:
      elkversion: "8.7.1"
      sgctl_version: "1.6.0"
      sgkibanaversion: "1.6.0-flx"
      sgversion: "1.6.0-flx"
    ```



    
3. Stop Kibana\
    The Kibana should not work during further steps related to the upgrade.

    Use the following command to stop the Kibana pod(s)
    ```
    kubectl -n <namespace> scale sts -l role=kibana --replicas=0
    ```
    and verify if the kibana pod was removed.

    Edit helm charts values yaml and set the number of replicas to `0` and activate `sgctl` pod and execute `helm upgrade`

    ```yml
    kibana:
      replicas: 0  
    common:
      sgctl_cli: true
      update_sgconfig_on_change: false
    ```
  
4. Upgrade Search Guard and the Elasticsearch\
   Before performing the current step, you must review the Elasticsearch documentation for the proper version and check which additional steps and measures are required to upgrade Elasticsearch. Then, you can upgrade Elasticsearch and Search Guard on your cluster node. The upgrade procedure is described in the [Search Guard upgrade guide](https://docs.search-guard.com/latest/upgrading#upgrading-elasticsearch-and-search-guard).
   
   For the helm charts edit the `.Values.common` attributes. The following parameters needs to be set up during the upgrade:
    `.Values.common.kibana.replicas` with value `0`
    `.Values.common.sgctl_cli`  with `true`
    `.Values.common.update_sgconfig_on_change` with `false`
    
   The example below shows values for Elasticsearch 8.12.2 and Search Guard 2.0.0 FLX. Other available versions can be checked [here] (https://docs.search-guard.com/latest/search-guard-versions)
   ```yml
   common:
     elkversion: "8.12.2"
     sgctl_version: "2.0.0"
     sgkibanaversion: "2.0.0-flx"
     sgversion: "2.0.0-flx"
     sgctl_cli: true
     update_sgconfig_on_change: false
   kibana:
     replicas: 0
   ```   
   
5. Adjust Multi-Tenancy configuration

   The Multi-Tenancy configuration for version 2.0.0 includes changes regarding how the configuration is stored. 
   Instead of using the `kibana.yml` file, the configuration has been moved to the `sg_frontend_multi_tenancy.yml` file.
   
   Example configuration:
   ```
   common:  
    frontend_multi_tenancy:
      enabled: true
      server_user: kibanaserver
      global_tenant_enabled : true   
   ``` 

   If the `.Values.common.frontend_multi_tenancy` parameter was not set in the Helm charts, the setup process will be handled by the Helm charts.

   However, if the `.Values.common.frontend_multi_tenancy` value was set, it is necessary to modify it according to the definition described on the page: [https://docs.search-guard.com/latest/kibana-multi-tenancy#multi-tenancy-configuration](https://docs.search-guard.com/latest/kibana-multi-tenancy#multi-tenancy-configuration).
   Make sure that the following values are still set in the `helm values`:
   
   ```yml
   kibana:
     replicas: 0  
   common:
     sgctl_cli: true
     update_sgconfig_on_change: false
   ```
     
   Run the helm upgrade command and wait for the upgrade process to complete. Then execute the following command to access the POD that will provide access to sgctl.sh:
   ```
   kubectl -n <namespace> exec  $(kubectl -n <namespace> get pod -l role=sgctl-cli  -o jsonpath='{.items[0].metadata.name}') -it bash
   ```
   
   After gaining access to the POD, run the following command to update only the contents of the sg_frontend_multi_tenancy.yml file:
   
   ```
   /usr/share/sg/sgctl/sgctl.sh update-config \
     -h $DISCOVERY_SERVICE  \
     --key /sgcerts/key.pem \
     --cert /sgcerts/crt.pem \
     --ca-cert /sgcerts/root-ca.pem \
     /sgconfig/sg_frontend_multi_tenancy.yml
   ```   
6. Migrate frontend data\
   The data structures used by the Multi-Tenancy implementation in SearchGuard 1.x.x and 2.0.0 are distinct. Therefore, running a data migration process is necessary to move Kibana Saved Objects (entities like data views and dashboards stored by Kibana in Elasticsearch). To conduct the data migration process, you need an up-to-date version of the `sgctl` tool. To carry out the data migration process, execute the command `sgctl special start-mt-data-migration-from-8.7`. The command execution should be above a few minutes, depending on the number of tenants defined in your environment and the volume of data stored in the Kibana indices. You can check the status of the data migration process using the command `sgctl special get-mt-data-migration-state-from-8.7`. The administrator must successfully execute data migration before proceeding with further upgrade steps. It is important to note that the system administrator should not run the data migration process in parallel, and the Kibana should be shut down during this process. Please note that Multi-Tenancy is disabled by default in the Search Guard 2.0.0 or newer. The command used for data migration will enable the Multi-Tenancy if needed.
   
   When the parameter `.Values.common.sgctl_cli` is set to `true`, a pod will be created from which the `sgctl` command will be accessible.
   To access `sgctl` from within the pod, execute the following command:
   ```
   kubectl -n <namespace> exec  $(kubectl -n <namespace> get pod -l role=sgctl-cli  -o jsonpath='{.items[0].metadata.name}') -it bash
   ```
   
   An example of using the command sgctl special get-mt-data-migration-state-from-8.7 is provided below:
   ```
   /usr/share/sg/sgctl/sgctl.sh special start-mt-data-migration-from-8.7 \
     -h $DISCOVERY_SERVICE  \
     --key /sgcerts/key.pem \
     --cert /sgcerts/crt.pem \
     --ca-cert /sgcerts/root-ca.pem 
   ```

7. Read-only access to tenants\
    When you grant read-only access to some tenants for some users, these users may encounter an error popup when they start accessing the tenant without the write privilege. In such a case, please evaluate whether using the Kibana telemetry is appropriate for your company. If you decide to turn off telemetry, you can do so by setting the value of attribute `.Values.kibana.config` in Helm Charts
    ```yml
    telemetry:
      enabled: false
      optIn: false
      allowChangingOptInStatus: false
    ```
    
8. Verify Kibana users' role assignment\
    The role names intended for use in a Multi-Tenancy-enabled environment have not been modified between the 1.x.x and 2.0.0 versions of Search Guard. However, the role definitions were changed. Therefore, if you are using custom roles that allow users to access Kibana, you should upgrade your role definitions. Each user needs access to at least one tenant. Otherwise, the user lacking any tenant access cannot log into Kibana. This is especially important in the context of private tenant removal or when you deprive users of global tenant access. The privilege of accessing the global tenant can be revoked by disabling the global tenant in the Multi-Tenancy configuration file (`sg_frontend_multi_tenancy.yml`) or when you do not assign to your users a role, which grants access to the global tenant. The build-in role `SGS_KIBANA_USER` allows the global tenant access, whereas the role `SGS_KIBANA_USER_NO_GLOBAL_TENANT` does not.

9. Start Kibana

    When the new Kibana version is started, the Kibana carries out data migration of its saved objects.
    
    ```
    kubectl -n <namespace> scale sts -l role=kibana --replicas=<number of replicas>   
    ```
    and restore previous the number of kibana replicas in Helm values:
    ```yml
    kibana:
      replicas: <number of replicas>   
    ```    
    
10. Upgrade verification\
    The upgrade procedure is almost complete. Please verify if your environment behaves correctly and all required features are available, check if other plugins work correctly, and integrate with external systems. You should also confirm that all required Kibana Saved Objects have been migrated correctly and that the Kibana user interface contains all required tenants, spaces, dashboards, etc. The test should be executed with users' accounts with various permission levels to access tenants.

***

Please take into consideration that Kibana in version 8.8.0 or newer uses some additional indices. You may need to adjust your backup strategy accordingly. Some indices used by the Kibana are listed below
* `.kibana` 
* `.kibana_analytics`
* `.kibana_ingest`
* `.kibana_security_solution`
* `.kibana_alerting_cases`

Official Kibana [documentation](https://www.elastic.co/guide/en/kibana/current/saved-object-migrations.html)