# Workflow

1) Getting arXMLiv dataset ([here](#arxmliv))
2) Processing it via planetext ([here](#planetext))
3) Post-Processing via custom procedures ([here](#post-processing))

## arXMLiv
Download [arXMLiv 08.2018](https://sigmathling.kwarc.info/resources/arxmliv-dataset-082018/) (requires [git lfs](https://git-lfs.github.com/)) and extract the `html` files.

## PlaneText
We use [PlaneText](https://kmcs.nii.ac.jp/planetext/en/) for processing the `html` files from arXMLiv. We customizes the code a little bit. The original sources can be found on [KMCS-NII](https://github.com/KMCS-NII/planetext). Our customized version can be found under [planetext](/planetext).

Our version of PlaneText
a) do not substitute MathML inner elements
b) do not create `xhtml` or `html` files

For processing arXMLiv:
``` bash
# navigate to the planetext directory
./bin/planetext arxmliv.yaml <path to html files> -O <output path>
```

The process may stop or crash for a subset of files. In that case you can use [`missing.sh`](missing.sh) to copy not yet processed files to another directory and repead the conversion process for the subset of the files. Before you do so, change the paths in `missing.sh`
``` bash
DIRIN="no_problems_raw"
DIRPROC="no_problems_txt"
DIROUT="no_problems_tmp"
```

Another problem that appears are empty or files without meanings. PlaneText will than generate empty annotation files and maybe even empty text files. To identify those files in advance (before post processing) we created the [`broken.sh`](broken.sh). Similar to [`missing.sh`](missing.sh) one may have to modify the paths in `broken.sh` also.

## Post-Processing
The folder [post](/post) contain a java project to post process the files generated by PlaneText. We split the text into sentences (one line per sentence) and replace all math-tokens by their [LLaMaPuN](https://kwarc.info/systems/llamapun/) (Language and Mathematics Processing and Understanding) representation. You have to specify the in- and output directory.
