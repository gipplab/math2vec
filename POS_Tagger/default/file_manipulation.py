'''
Created on Oct 26, 2018

@author: terry
'''
import os
import nltk
import re

from nltk.stem.lancaster import LancasterStemmer

from stop_words import get_stop_words
en_stop = get_stop_words('en') # list of stopwords/english

'''
Important TAGS to keep/combine
JJ adjective big
JJR adjective, comparative bigger
JJS adjective, superlative biggest

NN noun, singular desk
NNS noun plural desks
NNP proper noun, singular Harrison
NNPS proper noun, plural Americans

'''
keep_tags = ['JJ','JJR','JJS','NN','NNS','NNP','NNPS']

#===============================================================================
# Folder manipulation
#===============================================================================
def doclist_multifolder(folder_name):
    input_file_list = []
    for roots, dir, files in os.walk(folder_name):
        for file in files:
            file_uri = os.path.join(roots, file)
            file_uri = file_uri.replace("\\","/") #uncoment if running on windows           
            if file_uri.endswith('txt'): input_file_list.append(file_uri)
    return input_file_list
#creates list of documents in many folders

def fname_splitter(docslist):
    fnames = []
    for doc in docslist:
        blocks = doc.split('/')
        fnames.append(blocks[len(blocks)-1])
    return(fnames)
#getting the filenames from uri of whatever documents were processed in the input folder   

#===============================================================================
# Document Reading/Writing
#===============================================================================
def cleanText(fname, input_file_abs, output_path):
    ops = open(output_path+'/'+fname,'w', encoding='utf-8') #file where we are writing (same name it was read)
    with open(input_file_abs, 'r', encoding='utf-8') as fin:
        for lines in fin.readlines():
            if not lines.strip():continue #skip blanklines
            
            words = str(lines) #stream into string
            words = tokenizeWords(words) #tokenize things for tagger
            words = applyPOStag(words) #POS-tagger via NLTK  
            words = makeLowerCase(words)
            words = removeStopWords(words) #get rid of stop words     
            words = cleanStringPunctuation(words) #remove punctuation and weird chars
            
            if not words:continue #in case after all pre-processing cleans all words we skip this sentence
            words = concatenateTAG(words)
            outputFile(words, ops)
        ops.close()
        fin.close()
#reads file line by line and clean it


def outputFile(text, writer):  
    if text:
        for words in text:
            writer.write(str(words) + ' ')
        writer.write('\n')
    else:
        #print('Empty line !!!')
        pass # nothing to save
#writes sentence into a file

#===============================================================================
# Filter and Manipulation of Strings
#===============================================================================
def concatenateTAG(words):
    no_tag_words = []
    
    if(len(words)==1):return ([i[0] for i in words]) # in case there is one element in the doc-sentence
    
    for index, word_tag in enumerate(words[:-1]):
        word,tag = word_tag #unpack word and tag
        
        n_word,n_tag = words[index+1]
        if((tag in keep_tags) and (n_tag in keep_tags)):
            no_tag_words.append(word +'_'+n_word)
        else:
            no_tag_words.append(word)
            
    last_word,last_tag = words[-1] # we need to have the last word regardless of the outcome
    no_tag_words.append(last_word)
    return(no_tag_words)    
#concatenate words that share a common POS_TAG in keep_tags - only working for 2 consecutive words

def applyPOStag(words):
    tagged_words = nltk.pos_tag(words) #uses the Penn Treebank Tag Set.
    return (tagged_words)
#apply POS tag via NLTK to list of words

def tokenizeWords(sentence):
    return(nltk.word_tokenize(sentence))
#tokenize words - makes POS_Tagger mor efficient

def makeLowerCase(words):
    lower_case = []
    for word,tag in words:
        if(word.startswith('math')):
            lower_case.append((word,tag))
        else:
            lower_case.append((word.lower(),tag))
    return(lower_case)
#everything in lower case from string

def removeStopWords(words):
    #no_sw_words = [i for i in words[:] if not i in en_stop] #Simple - use this if you do not have tags
    no_sw_words = [(w,t) for (w,t) in words if not w in en_stop] #tagged_words
    return(no_sw_words)
#removes stopwords from list of words

def cleanStringPunctuation(words):
    tokens = []
    for word,tag in words:
        clean_word = word.translate({ord(c): None for c in '()[]{}\'\".;:,!@#$'})
        if(clean_word): 
            tokens.append((clean_word,tag)) #only keep valid items
        else:
            continue # we don't want a empty space in the list
    return(tokens)
#returns a list of clean tokens - gets rid of anything between ' ' by  replacing for None
#it also removes the entry for that empty token in our list

#===============================================================================
# Not Used: 2018-12-04
#===============================================================================
def applyStemmer(words):
    st = LancasterStemmer()
    ste_words = []
    for word,tag in words:
        if(word.startswith('math')):
            ste_words.append((word,tag))
        else:
            ste_words.append((st.stem(word),tag))
    return (ste_words)
 #Applies Lancaster Stemmer to list of words   - lowercase words
 
def removeASCIItrash(words):
    cwords = words.encode('ascii', 'ignore').decode("utf-8")
    return (cwords)
#removing unwanted chars/trash from sentences as strings