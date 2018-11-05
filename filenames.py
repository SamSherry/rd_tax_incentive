import os
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
