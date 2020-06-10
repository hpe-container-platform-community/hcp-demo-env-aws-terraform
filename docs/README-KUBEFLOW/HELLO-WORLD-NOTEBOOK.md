### Overview

In this document we will create a Kubeflow notebook server and run a simple Tensorflow Hello World example.

### Pre-requisities

- You have installed Kubeflow as per the instructions [here](../README-KUBEFLOW.md)

### Instructions

- In the **Quick shortcuts** on the left hand tile:
  - Click **Create a new Notebook server**
  - Provide a name, e.g. **helloworld** (name should be lowercase)
  - Click **Finish**
  - Wait about 5 minutes
- When the **Connect** button is enabled, Click it!
  - In the Notebook window:
    - Click **New**
    - Click **Python 3**
    - Paste in the Code below
    - Click **Run**
    - It should output `b'Hello, TensorFlow!'`
    
```
from __future__ import print_function

import tensorflow as tf

# Hello World - using Tensorflow

hello = tf.constant('Hello, TensorFlow!')

# Start Tensorflow session
sess = tf.Session()

print(sess.run(hello))
```

- Now save the notebook:
  - Click **File** then **Save As**
  - Give it a name, e.g. **HelloWorldTF**
  - Click **Save**
- Navigate back to the browser tab with the KubeFlow interface
  - Click **Home** from the menu
  - **Reload** the browser window and you should see your notebook in the section **Recent Notebooks**

