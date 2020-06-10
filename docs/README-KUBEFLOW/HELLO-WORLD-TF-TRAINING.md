### Overview

In this document we will create train a simple machine learning model using Tensorflow.

### Pre-requisities

- You have installed Kubeflow as per the instructions [here](../README-KUBEFLOW.md)
- Watch: [Understanding The Need for Deep Learning](https://www.youtube.com/watch?v=emTjHdAzwEs)
- Watch: [Understanding the Advantages of Deep Learning](https://www.youtube.com/watch?v=xU_bm9PhTAs)

### Instructions

These instructions are derived from [here](https://www.kubeflow.org/docs/components/training/tftraining/#running-the-mnist-example)

- Change into the terraform project directory:

```bash
wget https://raw.githubusercontent.com/kubeflow/tf-operator/master/examples/v1/mnist_with_summaries/tfevent-volume/tfevent-pv.yaml
wget https://raw.githubusercontent.com/kubeflow/tf-operator/master/examples/v1/mnist_with_summaries/tfevent-volume/tfevent-pvc.yaml
wget https://raw.githubusercontent.com/kubeflow/tf-operator/master/examples/v1/mnist_with_summaries/tf_job_mnist.yaml
```

- Verify the storage class name for MAPR

```bash
export KUBECONFIG=./generated/kubeflow_cluster.conf
kubectl get sc
```

Note that the MAPR CSI storage class is called `default`

- Update the event PV, change `storageClassName:` from `standard` to `default`

```bash
> cat tfevent-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: tfevent-volume
  labels:
    type: local
    app: tfjob
spec:
  capacity:
    storage: 10Gi
  storageClassName: default
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /tmp/data
```
- Update the event PVC, add the `storageClassName: default` to the spec:
  
```bash
> cat tfevent-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tfevent-volume
  namespace: kubeflow
  labels:
    type: local
    app: tfjob
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: default
```
- Apply the pv and pvc

```bash
kubectl apply -f tfevent-pv.yaml
kubectl apply -f tfevent-pvc.yaml
```

- Submit the TFJob

```bash
kubectl apply -f tf_job_mnist.yaml
```

- Check tf /train folder

```bash
kubectl -n kubeflow exec -it mnist-worker-0 /bin/bash
ls /train
```

- Monitor the job:

```
kubectl -n kubeflow get tfjob mnist -o yaml
```

