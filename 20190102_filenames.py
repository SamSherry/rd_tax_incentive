
# coding: utf-8

# In[1]:

# Install necessary modules, set working directory
import os
import sys
import pandas as pd
import numpy as np
import openpyxl
import xlrd
from xlrd import open_workbook, cellname
MY_DIR = '/media/sf_Shared/'
sys.path.append(MY_DIR)


# In[ ]:

# Program to read names of all files in a folder and output the filenames and file paths to a file
os.chdir('C:\\Users\\Sam\\Documents\\Research\\Data\\SNL\\SNL Resource and Reserve Information')
contentsFile = open('contents.txt', 'w')
for folderName, subfolders, filenames in os.walk('C:\\Users\\Sam\\Documents\\Research\\Data\\SNL\\SNL Resource and Reserve Information'):
    print folderName
    contentsFile.write(folderName + '\n')
    for subfolder in subfolders:
        print (folderName + ': ' + subfolder)
        contentsFile.write(folderName + ': ' + subfolder + '\n')
    for filename in filenames:
        print (folderName + ': ' + filename)
        contentsFile.write(folderName + ': ' + filename + '\n')
    print('')
contentsFile.close()


# In[6]:

# Read contents file
contents = pd.read_excel(MY_DIR + 'contents.xlsx')


# In[7]:

contents.info()


# In[8]:

contents.head()


# In[9]:

# Extract filenames
filename = pd.Series(contents['FILENAME'], name='File Name').str.split(':').str[-1]


# In[10]:

filename


# In[13]:

# Concatenate
new_contents = pd.concat([contents,filename],axis=1)
new_contents


# In[14]:

new_contents.to_excel('/media/sf_Shared/new_contents.xlsx')


# In[ ]:



