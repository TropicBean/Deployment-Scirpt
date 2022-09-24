# Deployment-Scirpt

The idea of this script is to make deployment for easier for the mmp team

The issue :

Currently we aren't able to deploy to multiple environments using Roundtable . On top of that , to import source using roundtable we need to check the program in first 
and then idividually pull our source in to each environment 
This is extremely time consuming and inefficient. So at the mmp team , we have started a model where we deploy our wip code to all the enivoronments , have it tested , and 
when it is signed off we check it in to the source control repository . 

1. No History - Due to the circumstances mentioned above , it leads to a scenario where we are in source control limbo for the duration of the sprint. This means we have no history of 
programs , which is tragic when someone overwrites someone elses changes accidentally. 

2. Prone to Human error - Since each person is doing their own development , they check their own version of the source out to their wips . And when they have tested their tasks they merge their 
changes back in to the shared wip folder . This is where overriding takes place. When a person does not take proper care in the merging process , this is likely to occur

3. No log - Commits to the shared wip folder are completely untracked , which means that if source goes missing you don't even know who to ask about it .

4. No automation -  When deploying from the shared wip folder , there is no automated way to perform this task. At mmp , we have a total of 6(soon to be 7) environments to deploy to after we 
have completed dev testing on a piece of code . Many team members make use of windows file explorer to complete this task . This is a manual process , of going folder by
folder and merging each source program in to the 4 dev environments (mmpfbp,mmpfbk,mmpprf, mmpkey) . If you work on , for example , 10 programs . This means you have to 
complete the merging process 10 x 4 = 40 individual merges .

5. Recompilation - In all of our environments , we have a layer of compiled code that lives on top of the uncompiled code . In our deployment process we only deploy to the 
uncompiled source layer. This means that the obsolete compiled source still lives on top of the new source . This requires a developer to recompile the top layer . Once again 
if you have changed 10 programs , this entails compiling each program individually . This process is repeated 6 envs x 10 programs = 60 Individual re-compilations. This process
is often considered so tedious that developers opt to just compile the enitre system . To give perspective , a system compile takes +-30 minutes . 4 x 30 = 120 minutes spent
on deployment .

With the help of git, I inted on enabling a developer to work in his own wip .When a developer is happy with the changes in his/her wip  .They run this script and it
handles all the problems mentioned above and automates some key actions . 
1. There will still be a main sprint wip repository . A developer will create a branch into their individual wip repo 
2. Developer will complete his/her development in their branh repo 
3. When the dev is happy with dev testing , they will merge their branch in to the shared sprint repo .
4. The sprint repo will automatically be deployed to all environments 
5. The deploy.sh script kicks in and takes over the deployment process 
  - Creates a log entry of the deployment (along with the commit id) 
  - Recompiles the source that is contained within the within the sprint wip repo(Will need to do investigation on .i files , thes will have cross refs)
  - Deploys the repo to the 2 dev envs(mmpfbk,mmpfbp) , 2 sys envs (mmpprf,mmpkey)
  - Copies code to 2 client environments using bung script 
  - Restarts all webspeed agents 
  - Performs a health check 
 
