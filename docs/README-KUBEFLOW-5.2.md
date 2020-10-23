1. Deploy K8S Cluster with AD/LDAP with Spark Operator enabled.  On the authentication tab, copy platform settings, then use:

 - User Attribute: CN
 - Group Attribute: member

2. Start WebTerm in K8S cluster deployed at step 3 (or create AIML/Tenant and launch WebTerm)
3. In WebTerm, run 'hcp-addon picasso', prompt will be changed to '(app-root)bash-4.2#'
4. Edit `/templates/picasso-install-responsefile-template.txt`. Add `INSTALL_KUBEFLOW=yes` in the file
5. Run `cd /usr/local/bin ; ./startscript --install`
startscript is launched, but you don't see any output in the webterm.
In order to see the log,
- login to k8s master node
- run `kubectl logs <picasso-bootstrap-pod-name> -n hpecp-bootstrap -f`
(example:  `kubectl logs hpecp-bootstrap-picasso-549bb4c8cc-sc8gn -n hpecp-bootstrap -f`)
6. after startscript is done, run `exit` to exit bootstrap pod.
7. In WebTerm, run `kubectl get pods -A`. You can see kubeflow pods is created. It takes a while.
8. Once KF pods are up, go to HCP UI and click on KF dashboard url, use external user/pwd to login

