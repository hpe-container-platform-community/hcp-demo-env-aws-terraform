### Overview

In this document we will create and run a simple pipeline.

### Pre-requisities

- You have installed Kubeflow as per the instructions [here](../README-KUBEFLOW.md)
- You have followed the instructions to create a Notebook [here](./HELLO-WORLD-NOTEBOOK.md)
- You have Python3 installed on your client machine.

### Instructions

#### Step 1 - Create a Pipeline

- Install the pipeline python SDK on your client machine:

```
pip3 install kfp --upgrade
```

(see [here](https://www.kubeflow.org/docs/pipelines/sdk/install-sdk/) for more information)

- Download the hello world example pipeline:

```
https://raw.githubusercontent.com/kubeflow/pipelines/master/samples/core/helloworld/hello_world.py
```

- Compile the hello world example pipeline

```
python3 hello_world.py
# hello_world.py.yaml is created
```


#### Step 2 - Upload the Pipeline

- In the Kubeflow UI, **click the menu button** on the top left.
- Click **Pipelines**
- On the top right, click **Upload Pipeline**
  - Select **Create a new pipeline**
  - Use **hello world** for **Pipeline Name** and **Pipeline Description**
  - Select **Upload a file**
    - Select the **hello_world.py.yaml** that you created in the above step (compile the hello world example pipeline)
  - Click **Create**
  
#### Step 3 - Run the Pipeline

- In the Kubeflow UI, **click Create Run** on the top right
  - Leave the default values and **click Start**
- You will notice you are in the Experiments section
  - Wait for the **Default** experiment to show, when it does click the arrow to **Expand it**
  - Wait for your **Run** to have a green tick next to it
  - Click the **Run Name** 
