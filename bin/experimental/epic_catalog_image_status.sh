#!/bin/bash

hpecp catalog list --query "[*].[_links.self.href,label.name,state]"
