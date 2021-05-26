# PeCaX
Personalized Cancer and Network Explorer (PeCaX) is a tool for identifying patient specific cancer mechanisms by providing a complete mutational profile from variants to networks. It employs ClinVAP to perform clinical variant annotation which focuses on processing, filtering and prioritization of the variants to find the disrupted genes that are involved in carcinogenesis and to identify actionable variants from the mutational landscape of a patient. In addition it creates networks showing the connections between the driver genes and the genes in their neighbourhood and automatically performs pathway enrichment analysis using pathway resources (SBML4j). Its interactive visualisation (BioGraphVisart) supports easy network exploration and patient similarity (node overlap) and a merged network graph of two patient-specific networks can be calculated.

Please refer this document for implementation of the application. Documentation of the pipeline is available at [Wiki page](https://github.com/MirjamFi/PeCaX/wiki).

## Usage with Docker
Requirements: Docker Engine release 1.13.0+, Compose release 1.10.0+.

Please make sure that you have 55 GB of physical empty space on your Docker Disk Image, and ports 3030, 3000, 8529 are not being used by another application. For setting up an initial network database (see below) the port 8080 will be used, unless otherwise configured.

To run the pipeline for the first time, please follow the steps given below.

1. Clone the Git repository via:

    `git clone https://github.com/MirjamFi/PeCaX.git`

2. For human genome assembly GRCh37, use: 
    
	`docker-compose up vep_files_GRCh37`
    
   To free up space, remove the downloaded image:
   
   	`docker rmi bilges/clinvap_file_deploy:vP_GRCh37`

   If your analysis requires GRCh38, use: 
   
    `docker-compose up vep_files_GRCh38`
    
  To free up space, remove the downloaded image:
  
   	`docker rmi bilges/clinvap_file_deploy:vP_GRCh38`
   	
  The assemblies can be served in parallel and need to be downloaded only once as long as the volume `pecax-docker_clinvap_downloads` is not removed.

3. Start PeCaX services via

	docker-compose up pecax

   Make sure to create a network database as described below before starting PeCaX for the first time.


## Exit:

    Ctrl+c

    docker-compose down

## In Browser of your choice open localhost:3030

### We recommend using full screen to enjoy the full experience.


## Information about docker volumes

PeCaX uses several volumes to store data and work files. They are briefly described here:

- sbml4j_neo4j_vol: used to store the knowledge graph and created networks.
- The local folder ./neo4j_data is used by the temporary services "sbml4j_db_setup" and "sbml4j_db_backup" to setup and backup the network database respectively. See instructions below for details
- The local folder ./scripts is used by the temporary service "sbml4j_db_setup" to store the script "db_setup.sh" for setting up the sbml4j-database volume
- arangodb_data_container: database directory to store the collection data (username, jobid, json, network uuids)
- arangodb_apps_data_container: apps directory to store any extensions

## Initializing a network database for use with PeCaX

The networks are stored in a docker volume and are thus persisted between individual PeCaX sessions.
If you however delete or prune your docker volumes, while the service is not running, the network volume will be deleted and you will have to rerun

```bash
./sbml4j_setup.sh -s pecax-base
```

This will use the network database that has been previously saved (see below) and resides in the local subfolder "db_backups" with the names pecax-base-neo4j.dump and pecax-base-system.dump for the actual network database and systems database respectively.

For generating a database refer to section "Creating a network database" below.

## Backing up the network database

For your previous networks to be available after a prune or delete of the volumes you have to save a backup of the network database.
You can do this with

```bash
./sbml4j_setup.sh -b my-backup
```

This will create two files named *my-backup-neo4j.dump* and *my-backup-system.dump* in the local sub-folder *db_backups*.

## Creating a network database

### Preparation

#### Accessibilty of the SBML4J Service in the PeCaX ecosystem

For security reasons the SBML4j service is not exposed to the host machine, so to be able to directly interact with SBML4j you will need to temporarily change the docker-compose.yaml file.
In the service block "sbml4j" you need to change 

	expose: 
	    - "8080"

to

	ports:
	    - "8080:8080"

Once you are finished with creating and setting up your desired network database you are advised to revert this change.

#### Initialize the docker volumes needed using the probided script
To intialize the volumes used for the network database and the SBML4j service use the sbml4j\_setup script.

Inside the main 'Pecax-docker' directory run

> ./sbml4j\_setup.sh -i

to install all prerequisits for the SBML4J service and it's database.

#### Communicating with the SBML4J service

The following instructions provide examples for the communication with the REST interface of SBML4j using curl and python.
Alternatively you can use a tool of your choice to issue GET and POST http requests to the SBML4j service, like Postman.
You can find the API definition for initialising the requests in your tool of choice at https://github.com/kohlbacherlab/sbml4j-compose/api_doc/sbml4j.yaml

Please note, that file-names, argument values and UUIDs used are only exemplary and need to replaced with the actual values from your installation.
Also note, that the '\' character in the examples below is used to signify line breaks to make the blocks more readable and might need to be removed before executing the snippets, depending on your system.

To use the python code examples you need to install the 'pysbml4j' python package:

> pip install pysbml4j

Then use it in your python environment of choice with:

```python
import pysbml4j

client = pysbml4j.Sbml4j()
```

If you are not running the service on you local system, you need to configure pysbml4j accordingly:

```python
import pysbml4j
from pysbml4j import Configuration

client = pysbml4j.Sbml4j(Configuration("http://mysbml4jhost:8080"))
```

We will need to store uuids of pathways created from the uploaded SBML models.
In the python examples below we will use the following list variable for this:

```python
pathwayUUIDs = []
```

For more details see the pysbml4j documentation at https://github.com/kohlbacherlab/pysbml4j .


### 1. Selecting a source

The demo version of PeCaX accesible at https://pecax.informatik.uni-tuebingen.de uses a selection of 61 pathway maps from the KEGG pathway database.
If you want to recreate this version of PeCaX in your local environment, follow steps 2 and 3 below to download and translate the KEGG pathways used.
If you want to use different source models head over to https://github.com/kohlbacherlab/sbml4j to learn about the necessary details to look for when using SBML models with SBML4J for non-metabolic network-mappings.


### 2. Get the KEGG pathway files
Listing 1 shows the pathway identifiers of the KEGG pathways used in this publication.
KEGG provides their own markup language files for their pathways.
You can download these kgml files directly from their website (kegg.jp) or through their API.
Make sure you understand the license requirements before starting the download (see https://www.kegg.jp/kegg/rest/ for details).
TODO: Is KPWD in a good enough state to be linked here?


### 3. Translate pathway files
In order for SBML4j to be able to process the KEGG pathway models they need to be translated to the SBML format.
We used the KEGGtranslator version 2.5 for this.
Please find KEGGtranslator here: (http://www.cogsys.cs.uni-tuebingen.de/software/KEGGtranslator/).
We used the following command line options for translating the pathway maps:

	--format SBML_CORE_AND_QUAL 
	--remove-white-gene-nodes TRUE 
	--autocomplete-reactions TRUE 
	--gene-names FIRST_NAME 
	--add-layout-extension FALSE 
	--use-groups-extension FALSE 
	--remove-pathway-references TRUE

TODO: Can I link to my KEGGtranslator docker container and provide instructions to run it?

### 4. Upload models to SBML4j
By issuing a POST request to the '/sbml' endpoint one or multiple SBML formatted xml files can be uploaded to SBML4j.
For best performance we recommend uploading the model files one by one or in small chunks of 5 models or less.
Choose the same organism, source and version parameters for all pathway maps to ensure proper integration in the next step.
For details on the RESTful interface visit https://app.swaggerhub.com/apis-docs/tiede/sbml4j/1.1.7

An exemplary curl command for uploading SBML models to a local service is shown below:
```bash
curl -v \
     -F files=@/absolute/path/to/sbml/model/file1.xml \
     -F files=@/absolute/path/to/sbml/model/file2.xml \
     -F "organism"="hsa" \
     -F "source"="KEGG" \
     -F "version"="97.0" \ 
     -o response.file \
   http://localhost:8080/sbml4j/sbml
```
We redirect the response of the service here into the file 'response.file' using the '-o' option.
This file will then contain a json-formatted response containing basic information about the uploaded model(s).
Be sure to at least save the provided 'uuid' (or 'UUID') for each model as we will need those later.

Using the pysbml4j package uploading SBML models with python is as easy as:

```python
resp = client.uploadSBML([/absolute/path/to/sbml/model/file1.xml, /absolute/path/to/sbml/model/file2.xml], "hsa", "KEGG", "97.0")
print("The UUID of pathway in file1.xml is {}, of file2.xml it is {}".format(resp[0].get("uuid"), resp[1].get("uuid")))
pathwayUUIDs.add(resp[0].get("uuid"))
pathwayUUIDs.add(resp[1].get("uuid"))
```

### 5. Create pathway collection
A network mapping always refers to one pathway instance in the database.
In order to build network mappings for multiple KEGG pathways we combine all entities, relations and reactions in a collection pathway element which can be used subsequently to generate network mappings.
The enpoint /pathwayCollection accepts a POST request with a JSON formatted body containing the elements: name, description and sourcePathwayUUIDs.
Name and description are used as pathwayIdString and pathwayDescription respectively.
The field sourcePathwayUUIDs has to be an array of character strings, each string being one UUID of a pathway that shall be added to the collection element.

```bash
curl -v
     -H "Content-Type: application/json" \
     -d '{"name":"BMC_Collection", \
          "description":"This is the Collection for the BMC Publication", \
          "sourcePathwayUUIDs":["909520db-8ca9-40df-bffe-af9e48e93c48","9d959b42-f1da-4061-960b-4b58e1ba3c16"]}' \
     -o response.pwcoll \
   http://localhost:8080/sbml4j/pathwayCollection 
```

A simple python call can look something like this:
```python
collUUID = client.createPathwayCollection("KEGG61-97.0", "Collection pathway for all 61 KEGG pathways", pathwayUUIDs)
collUUID = collUUID[1:-1]
print(collUUID)
```
The endpoint returns the UUID of the created collection pathway, which can be used in the following calls to create the network mappings.
TODO: Unfortunately it returns it as a quoted string, which need to be trimmed for the actual UUID to be used further.

### 6. Create network mappings 
To create the network mappings from a pathway a POST request to the /mapping endpoint has to be issued.
The UUID of the pathway is part of the URL as can be seen here:

```bash
curl -v \
     -d "mappingType="PATHWAYMAPPING" \
     -d "networkName"="PWM-KEGG-BMC" \
     -o response.mapping \
   http://localhost:8080/sbml4j/mapping/b6da7dc5-4dc4-4991-85c0-5ab75e2bf929
```

TODO: Does this work with getting the uuid from the response in python? 
```python
resp = client.mapPathway(collUUID, "PPI", "PWM-KEGG_BMC")
print("The created mapping has the uuid: {}".format(resp.get("uuid")))
```


The last part of the url (b6da7dc5-4dc4-4991-85c0-5ab75e2bf929) is the collUUID generated in the previous step. Be sure to fill in the UUID of your installation when creating the pathway collection.
The UUIDs are generated by SBML4j and will differ every time you run this procedure.

The artifical mapping type 'PATHWAYMAPPING' can be used to not restrict the elements or relations being mapped and will map every entity, relation and reaction into a network mapping instance.
Such a network mapping has been used for PeCaX to allow the most broad view on the network context of the genes of interest.

### 7. Prepare the Drugbank csv file
You can find the drugtarget information used in PeCaX here: https://go.drugbank.com/releases/latest#protein-identifiers
You will need a free account on drugbank.ca to gain access to this file, which is released under the 'Creative Common’s Attribution-NonCommercial 4.0 International License.'
You will have to agree to these terms and conditions to continue with the next steps described here.
We used the 'Drug target identifiers' file for all drug groups to get a broad view on available and possible drugs and the genes and geneproducts they target.
In order to reproduce the results found in the publication two preprocessing steps need to be performed:
  1. Filter out all rows that are not targeting genes in Humans (column 'Species').
  2. Consolidate rows with the same 'ID' into one row, combining the elements in the 'Drug IDs' of all those rows into one.

We leave it up to the reader to perform these steps.
TODO: Ask Mirjam if we can use her script here and provide the user with it.

### 8. Add the Drugbank csv file to the network mappings
Using the csv upload functionality of SBML4j arbitrary data can be annotated onto network nodes.
A POST request to the /networks/{UUID}/csv endpoint will read in the provided csv file in the form data, find the row for matching the gene symbol and add all remaining rows as annotation on this node (or multiple nodes if applicable, i.e. if no node with the exact gene symbol can be found, all secondary gene names will be searched for the given symbol which can result in multiple nodes being annotated with the data from one row).
The endpoint additionally expects a 'type' parameter, giving a character string describing the type of annotation that is added, in our example the term 'Drugtarget' is used, as the csv marks every genesymbol given as a drug target for the provided list of 'Drug IDs'.
The nodes therefore will get the additional Boolean annotation of 'Drugtarget=true' if they are annotated by this step.
In addition all additional columns with content from the csv file get annotated on said node(s). 
Please note, that since there can be multiple Drugs targeting the same gene or gene-product, the annotation-names will include a numbering scheme in addition to the column names given in the csv file.
Make sure to set the 'networkName' to "PeCaX-Base" (case-sensitive).
SBML4j for PeCaX is configured to use the network with this name as basis for calculating the networks by default.
If you want to use a different name, make sure to also change the appropriate config parameter in the 'docker-compose.yaml' file.

You can use the curl command to upload a csv file and annotate the created network mapping with the contained data:
```bash
curl -v
     -F upload=@drugbank_data.csv
     -F "type"="Drugtarget"
     -F "networkName"="PeCaX-Base"
     -o response.drugbank
   http://localhost:8080/sbml4j/networks/a68645cb-f3bb-49d3-b05f-7f6f05debba3/csv
```

The python package also offers this functionality:
```python
net = client.getNetworkByName("PWM-KEGG-BMC")
net.addCsvData("/absolute/path/to/drugbank_data.csv", "Drugtarget", 
               networkName="PeCaX-Base")
```

Now your installation of PeCaX should contain the same base network-database that can be found in the demo-version at 

> https://pecax.informatik.uni-tuebingen.de




### 9. Save the network database to reset your networks in PeCaX in the future
Use the provided script to backup the database: 

```
./sbml4j_setup.sh -b pecax_base
```

This will create two '.dump' files in the **db_backups** folder containing the database backup you just created.

### 10. Restoring the state of the database
You can revert your database back to the previously saved state by using:

```
./sbml4j_setup.sh -s pecax_base 
```
### Post-Steps
  1. For security reason it is advised to reset the port setting for the sbml4j service as described above.
  2. Make sure to backup your database dumps at a save location for later reference.

### KEGG Pathway Maps used in the demo version
Here is a list of the KEGG pathway maps used in the PeCaX publication.
The KEGG Release used is: 97.0+/02-16, Feb 21.

- hsa03320 PPAR signaling pathway
- hsa04010 MAPK signaling pathway
- hsa04012 ErbB signaling pathway
- hsa04014 Ras signaling pathway
- hsa04015 Rap1 signaling pathway
- hsa04020 Calcium signaling pathway
- hsa04022 cGMP-PKG signaling pathway
- hsa04024 cAMP signaling pathway
- hsa04060 Cytokine-cytokine receptor interaction
- hsa04064 NF-kappa B signaling pathway
- hsa04066 HIF-1 signaling pathway
- hsa04068 FoxO signaling pathway
- hsa04070 Phosphatidylinositol signaling system
- hsa04071 Sphingolipid signaling pathway
- hsa04072 Phospholipase D signaling pathway
- hsa04080 Neuroactive ligand-receptor interaction
- hsa04110 Cell cycle
- hsa04115 p53 signaling pathway
- hsa04150 mTOR signaling pathway
- hsa04151 PI3K-Akt signaling pathway
- hsa04152 AMPK signaling pathway
- hsa04210 Apoptosis
- hsa04218 Cellular senescence
- hsa04310 Wnt signaling pathway
- hsa04330 Notch signaling pathway
- hsa04340 Hedgehog signaling pathway
- hsa04350 TGF-beta signaling pathway
- hsa04370 VEGF signaling pathway
- hsa04371 Apelin signaling pathway
- hsa04390 Hippo signaling pathway
- hsa04510 Focal adhesion
- hsa04512 ECM-receptor interaction
- hsa04520 Adherens junction
- hsa04630 JAK-STAT signaling pathway
- hsa04915 Estrogen signaling pathway
- hsa05200 Pathways in cancer
- hsa05202 Transcriptional misregulation in cancer
- hsa05203 Viral carcinogenesis
- hsa05204 Chemical carcinogenesis
- hsa05205 Proteoglycans in cancer
- hsa05206 MicroRNAs in cancer
- hsa05210 Colorectal cancer
- hsa05211 Renal cell carcinoma
- hsa05212 Pancreatic cancer
- hsa05213 Endometrial cancer
- hsa05214 Glioma
- hsa05215 Prostate cancer
- hsa05216 Thyroid cancer
- hsa05217 Basal cell carcinoma
- hsa05218 Melanoma
- hsa05219 Bladder cancer
- hsa05220 Chronic myeloid leukemia
- hsa05221 Acute myeloid leukemia
- hsa05222 Small cell lung cancer
- hsa05223 Non-small cell lung cancer
- hsa05224 Breast cancer
- hsa05225 Hepatocellular carcinoma
- hsa05226 Gastric cancer
- hsa05230 Central carbon metabolism in cancer
- hsa05231 Choline metabolism in cancer
- hsa05235 PD-L1 expression and PD-1 checkpoint pathway in cancer
