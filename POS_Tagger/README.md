# POS_Tagger
===============

Generic POS Tagger for text documents.
Folder used to read/write should be in the same level at 'default' package

	python3 postagger.py --input <input-folder-location> --output <output--folder-location>

- Requires the following libraries:
  - `nltk`
  - `stop_words`
  - `inflection`
  
UPDATES:
==========
[2018-12-22]
1. Stopwords considering NLTK. The one from PyPl is still na option, no clear difference about
2. Concatenation of NOUNS working
 2.a. Has to be done before ADJ chains for more sound results
3. removeLastRepWord(word) in case this is part of a previous concatenation
 3.a. Important to removePunctuation first
4. Concatenation of ADJ*NOUN+ is not working for consecutive adjectives - To Do 

[2018-12-20]
1. Implemented NOUNS+ concatenation
2. Better punctuation removal
3. Holy Grail `math-<?>`


[2018-12-17]
1. Fixed all filters to ignore `math-<?>` tokens. It also does not concatenate `math-<?>` tokens

[2018-12-14]
1. Added one extra filter option to just lowercase words without any tag
2. cleanText calls all the filter-functions comment and/or uncomment the ones desired

[2018-12-07]
1. removePlurals() using `inflection`
2. Included all POS tags from NLTK in the end od `file_manipulation.py`
3. Simple refactoring
4. Fixed relative imports from default. package

[2018-12-04]
1. Major changes in the code to work with (word,pos_tag)
2. All functions (major) refactor
3. Concatenate words with NOUNS and ADJECTIVE tags in nltk.pos_tag()

[2018-11-29]
1. makeLowerCase and applyStemmer ignore words beginning with <math->

[2018-11-28]
1. Several pre-processing functions implemented
2. NLTK tagger working
3. General refactorings

[2018-11-14]
1. cleanString implemented to get rid of specific chars

[2018-10-29]
1. Reading/writing files - line-by-line, 
2. Text clean and stopwords removal
3. POS tagger using NLTK prototype

[2018-10-26]
1. Project creation
2. File/Folder structure implementation
3. Command line arguments added

