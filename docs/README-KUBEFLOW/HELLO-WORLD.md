### Overview

In this document we will create a Kubeflow notebook server and run a simple Tensorflow Hello World example.

### Pre-requisities

- You have installed Kubeflow as per the instructions [here](https://github.com/bluedata-community/bluedata-demo-env-aws-terraform/blob/master/docs/README-KUBEFLOW.md)

### Instructions

Note details coming soon ...

```
from __future__ import print_function

import tensorflow as tf

# Hello World - using Tensorflow

hello = tf.constant('Hello, TensorFlow!')

# Start Tensorflow session
sess = tf.Session()

print(sess.run(hello))
```
