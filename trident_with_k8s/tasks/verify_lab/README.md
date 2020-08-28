# Verifying the Lab Environment

The objective for this first task is to familiarise yourself with the environment and validate that all pre-installed kubernetes objects are present and in a ready state.

Most tasks will be carried from a PuTTY console. Open the PuTTY console on the jumphost within the lab and connect to the kubernetes master node (RHEL3) as root@rhel3. The session is already set up for you in PuTTY and the password is `Netapp1!`

Our user root@rhel3 is considered a normal user (in kubernetes terms external to the k8s cluster). We get authenticated using certificates (as specified in the .kube/config file) and will by default have admin level access to everything within the cluster. Access can be further limited using Role Based Access Control (RBAC). RBAC uses the rbac.authorization.k8s.io API group that allows administrators to dynamically configure permission policies through the API server.  
For the purpose of this bootcamp we will rely on having admin level access.  

Each subsequent task will be run from its own directory from the GitHub repository fetched locally. There is a README file with instructions for each task.

Lastly, there are plenty of commands to type or alternatively copy & paste.
Most of the commands start with a '[root@rhel3 ~]#', usually followed by the results you would observe.

## A. Production Kubernetes Cluster

Let's start by confirming the version of Kubernetes installed. Either of the commands can be used to confirm that kubernetes 1.18 has been installed.

```bash
[root@rhel3 ~]# kubectl version
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:58:59Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:50:46Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
[root@rhel3 ~]# kubectl version --short
Client Version: v1.18.0
Server Version: v1.18.0
```

The production k8s cluster contains a single master node (rhel3) and three worker nodes ( rhel1, rhel2 and rhel4).
To verify the nodes:  
`kubectl get nodes -o wide`

Your output should be similar to below, all nodes with a "Ready" status with Kubernetes 1.18 installed.  

```bash
[root@rhel3 ~]# kubectl get nodes -o wide
NAME    STATUS   ROLES    AGE    VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                      KERNEL-VERSION          CONTAINER-RUNTIME
rhel1   Ready    <none>   316d   v1.18.0   192.168.0.61   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
rhel2   Ready    <none>   316d   v1.18.0   192.168.0.62   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
rhel3   Ready    master   316d   v1.18.0   192.168.0.63   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
rhel4   Ready    <none>   179m   v1.18.0   192.168.0.64   <none>        Red Hat Enterprise Linux Server 7.5 (Maipo)   3.10.0-862.el7.x86_64   docker://18.9.1
```

To verify your k8s cluster is ready for use:  

```bash
[root@rhel3 ~]# kubectl cluster-info
[root@rhel3 ~]# kubectl get componentstatus
```

Your output should be similar to below, Kubernetes master running at <https://192.168.0.63:6443> and all components with a "Healthy" status.  

```bash
[root@rhel3 ~]# kubectl cluster-info
Kubernetes master is running at https://192.168.0.63:6443
KubeDNS is running at https://192.168.0.63:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[root@rhel3 ~]# kubectl get componentstatus
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
```

To list all namespaces:  

```bash
[root@rhel3 ~]# kubectl get namespaces
```

The default and Kubernetes specific kube-* should be listed together with the additionally created namespaces for the Kubernetes dashboard, metallb load-balancer, monitoring for Prometheus & Grafana and Trident.  

```bash
[root@rhel3 ~]# kubectl get namespaces
NAME                   STATUS   AGE
default                Active   316d
kube-node-lease        Active   316d
kube-public            Active   316d
kube-system            Active   316d
kubernetes-dashboard   Active   3h31m
metallb-system         Active   3h43m
monitoring             Active   3h33m
trident                Active   3h33m
```

## B. Trident Operator

Trident 20.04 introduced a new way to manage its lifecycle: Operators.  
With Trident 20.04, there are new objects in the picture:

- Trident Operator, which will dynamically manage Trident's resources, automate setup, fix broken elements  
- Trident Provisioner, which is a Custom Resource, and is the object you will use to interact with the Trident Operator for specific tasks (upgrades, enable/disable Trident options, such as _debug_ mode, uninstall)  

You can visualize the *Operator* as being the *Control Tower*, and the *Provisioner* as being the *Mailbox* in which you post configuration requests.
Other operations, such as Backend management or viewing logs are currently still managed by Trident's own `Tridentctl`.

:mag:  
*A* **resource** *is an endpoint in the Kubernetes API that stores a collection of API objects of a certain kind; for example, the built-in pods resource contains a collection of Pod objects.*  
*A* **custom resource** *is an extension of the Kubernetes API that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.*  
:mag_right:  

To verify that the Trident Custom Resource Definitions have been installed:

```bash
[root@rhel3 ~]# kubectl get crd
NAME                                      CREATED AT
...
tridentbackends.trident.netapp.io         2020-07-21T08:01:28Z
tridentnodes.trident.netapp.io            2020-07-21T08:01:30Z
tridentprovisioners.trident.netapp.io     2020-07-21T08:00:50Z
tridentsnapshots.trident.netapp.io        2020-07-21T08:01:31Z
tridentstorageclasses.trident.netapp.io   2020-07-21T08:01:29Z
tridenttransactions.trident.netapp.io     2020-07-21T08:01:31Z
tridentversions.trident.netapp.io         2020-07-21T08:01:28Z
tridentvolumes.trident.netapp.io          2020-07-21T08:01:29Z
...
```

Next observe the status of the TridentProvisioner. The status should be _installed_ for the provisioner CRD:

```bash
[root@rhel3 ~]# kubectl get tprov -n trident
NAME      AGE
trident   9h
[root@rhel3 ~]# kubectl describe tprov trident -n trident
Name:         trident
Namespace:    trident
Labels:       <none>
Annotations:  <none>
API Version:  trident.netapp.io/v1
Kind:         TridentProvisioner
Metadata:
  Creation Timestamp:  2020-08-11T09:33:07Z
  Generation:          1
  Managed Fields:
    API Version:  trident.netapp.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:debug:
    Manager:      kubectl
    Operation:    Update
    Time:         2020-08-11T09:33:07Z
    API Version:  trident.netapp.io/v1
    Fields Type:  FieldsV1
    Manager:         trident-operator
    Operation:       Update
    Time:            2020-08-11T09:33:36Z
  Resource Version:  510810
  Self Link:         /apis/trident.netapp.io/v1/namespaces/trident/tridentprovisioners/trident
  UID:               f64faf13-89c6-4311-b457-abb3c25c9329
Spec:
  Debug:  true
Status:
  Current Installation Params:
    IPv6:               false
    Autosupport Image:  netapp/trident-autosupport:20.07.0
    Autosupport Proxy:
    Debug:              true
    Image Pull Secrets:
    Image Registry:       quay.io
    k8sTimeout:           30
    Kubelet Dir:          /var/lib/kubelet
    Log Format:           text
    Silence Autosupport:  false
    Trident Image:        netapp/trident:20.07.0
  Message:                Trident installed
  Status:                 Installed
  Version:                v20.07.0
Events:
  Type    Reason     Age                    From                        Message
  ----    ------     ----                   ----                        -------
  Normal  Installed  102s (x70 over 5h20m)  trident-operator.netapp.io  Trident installed
```

You can also confirm if the Trident install completed by taking a look at the pods that have been created. Confirm that the Trident Operator, Provisioner and a CSI driver per node (part of the daemonset) are all up & running:

```bash
[root@rhel3 ~]# kubectl get all -n trident
NAME                                    READY   STATUS    RESTARTS   AGE
pod/trident-csi-5vhfl                   2/2     Running   0          5h22m
pod/trident-csi-6gg8c                   2/2     Running   0          5h22m
pod/trident-csi-7bb4bfb84-6wg6z         6/6     Running   0          5h22m
pod/trident-csi-qxzj8                   2/2     Running   0          5h22m
pod/trident-csi-tjf7q                   2/2     Running   0          5h20m
pod/trident-operator-7f74ff5bb8-hw6hq   1/1     Running   0          5h22m

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
service/trident-csi   ClusterIP   10.101.210.100   <none>        34571/TCP,9220/TCP   5h22m

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                     AGE
daemonset.apps/trident-csi   4         4         4       4            4           kubernetes.io/arch=amd64,kubernetes.io/os=linux   5h22m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/trident-csi        1/1     1            1           5h22m
deployment.apps/trident-operator   1/1     1            1           5h22m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/trident-csi-7bb4bfb84         1         1         1       5h22m
replicaset.apps/trident-operator-7f74ff5bb8   1         1         1       5h22m
```

You can also use tridentctl to check the version of Trident installed:

```bash
[root@rhel3 ~]# tridentctl -n trident version
+----------------+----------------+
| SERVER VERSION | CLIENT VERSION |
+----------------+----------------+
| 20.07.0        | 20.07.0        |
+----------------+----------------+
```

Because of the CRD extension of the Kubernetes API we can also use kubectl to interact with Trident and for example check the version of Trident installed:

```bash
[root@rhel3 ~]# kubectl -n trident get tridentversions
NAME      VERSION
trident   20.07.0
```

To see what other kubectl commands can be used to interact with Trident, the supported API resources can be viewed in a single easy command:

```bash
[root@rhel3 ~]# kubectl api-resources --api-group=trident.netapp.io -o wide
```

## C. Backends and StorageClasses

Trident needs to know where to create volumes. This information sits in objects called backends. It basically contains:  

- The driver type (there are currently 10 different drivers available)
- How to connect to the driver (IP, login, password ...)
- Some default parameters

For additional information, please refer to the official NetApp Trident documentation on Read the Docs:

- <https://netapp-trident.readthedocs.io/en/latest/kubernetes/tridentctl-install.html#create-and-verify-your-first-backend>
- <https://netapp-trident.readthedocs.io/en/latest/kubernetes/operations/tasks/backends/index.html>

Once you have configured a backend, the end user will create Persistent Volume Claims (PVCs) against Storage Classes.  
A storage class contains the definition of what an app can expect in terms of storage, defined by some properties (access type, media, driver ...)

For additional information, please refer to:

- <https://netapp-trident.readthedocs.io/en/latest/kubernetes/concepts/objects.html#kubernetes-storageclass-objects>

Installing & configuring Trident as well as creating Kubernetes Storage Classes is what is expected to be done upfront by the k8s Admin and as such has already been done in this lab for you.

Next let's verify what backends have been pre-created for us.  

**Note:** Again we can use both kubectl and tridentctl to get the information.  

```bash
[root@rhel3 ~]# kubectl -n trident get tridentbackends
NAME        BACKEND               BACKEND UUID
tbe-cgx2q   ontap-block-rwo-eco   db6293a4-476e-479b-90e4-ab78372dfd04
tbe-dljs6   ontap-block-rwo       6ca0fb82-7c42-4319-a039-6d15fbdf0f3d
tbe-sh9gm   ontap-file-rwx        7b275998-e94f-4b88-b64c-5ff53ebd270e
tbe-zkwtj   ontap-file-rwx-eco    e6abe7bd-82fa-433c-a8d9-422a0b9dd635
[root@rhel3 ~]# tridentctl -n trident get backends
+---------------------+-------------------+--------------------------------------+--------+---------+
|        NAME         |  STORAGE DRIVER   |                 UUID                 | STATE  | VOLUMES |
+---------------------+-------------------+--------------------------------------+--------+---------+
| ontap-file-rwx      | ontap-nas         | 7b275998-e94f-4b88-b64c-5ff53ebd270e | online |       0 |
| ontap-file-rwx-eco  | ontap-nas-economy | e6abe7bd-82fa-433c-a8d9-422a0b9dd635 | online |       0 |
| ontap-block-rwo     | ontap-san         | 6ca0fb82-7c42-4319-a039-6d15fbdf0f3d | online |       0 |
| ontap-block-rwo-eco | ontap-san-economy | db6293a4-476e-479b-90e4-ab78372dfd04 | online |       0 |
+---------------------+-------------------+--------------------------------------+--------+---------+
```

We also need storage classes pointing to each backend:

```bash
[root@rhel3 ~]# kubectl get sc
NAME                    PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
sc-block-rwo            csi.trident.netapp.io   Delete          Immediate           false                  9h
sc-block-rwo-eco        csi.trident.netapp.io   Delete          Immediate           false                  9h
sc-file-rwx (default)   csi.trident.netapp.io   Delete          Immediate           true                   9h
sc-file-rwx-eco         csi.trident.netapp.io   Delete          Immediate           true                   9h
[root@rhel3 ~]# tridentctl -n trident get storageclasses
+------------------+
|       NAME       |
+------------------+
| sc-block-rwo-eco |
| sc-file-rwx      |
| sc-file-rwx-eco  |
| sc-block-rwo     |
+------------------+
```

At this point we can confirm that end-users are all set to create applications with persistent storage requirements in our lab environment :thumbsup:

## D. Prometheus & Grafana

Trident includes  metrics that can be integrated into Prometheus for an open-source monitoring solution. Grafana again is an open-source visualization software, allowing us to create a graph with many different metrics.  

Prometheus has been installed using the Helm prometheus-operator chart and exposed using the MetalLB load-balancer. For Prometheus to retrieve the metrics that Trident exposes, a ServiceMonitor has been created to watch the trident-csi service. Grafana in turn was setup by the Prometheus-operator, configured to use Prometheus as a data source and again exposed using the MetalLB load-balancer. Finally we have imported a custom dashboard for Trident into Grafana.  

To get the IP address for the Grafana service:  

```bash
[root@rhel3 ~]# kubectl -n monitoring get svc prom-operator-grafana
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
prom-operator-grafana   LoadBalancer   10.108.152.56   192.168.0.141   80:30707/TCP   7h21m
```

You can now access the Grafana GUI and pre-created Trident dashbaord from a browser on the jumphost at: <http://192.168.0.141/d/5ZhlSquZk/trident?orgId=1&refresh=1m> (username `admin` and password `prom-operator`.  

It's worth keeping Grafana open as you walk through the tasks in this bootcamp, as it is a good way of tracking the Persistent Volumes you have created.

## E. Kubernetes web-based UI

The Kubernetes dashboard has been pre-installed and configured. Please use below steps to gain access to the UI.

Access the k8s dashboard from a web browser at:  
<https://192.168.0.142/>.  

Click on **Advanced** in the 'Your connection is not private' window, followed by 'Proceed to 192.168.0.142 (unsafe)'.

Getting a Bearer Token  
Now we need to find token we can use to log in. Execute following command in the original terminal window:  
`kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')`

It should display something similar to below:
![Admin user token](../../../images/dashboard-token.jpg "Admin user token")

Copy the token and paste it into Enter token field on the login screen.
![Kubernetes Dashboard Sign in](../../../images/dashboard-sign-in.png "Kubernetes Dashboard Sign in")

For more information about the kuberenetes dashboard itself, please see:  
<https://github.com/kubernetes/dashboard>.

## F. What's next

Hopefully you are now more familiar with the lab environment and the Trident setup. You can move on to:  

- Your first task: [Deploy your first application using persistent file storage](../file_app)

or jump ahead to..

- Any of the tasks in the [Production Task list](/README.md#prod-k8s-cluster-tasks)

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
