'''
Created on Oct 26, 2018

@author: terry
'''
import os
import nltk
import re
import inflection
import string

from nltk.stem.lancaster import LancasterStemmer
from nltk.corpus import stopwords
from stop_words import get_stop_words
#from pattern.text.en import singularize

nltk.download('punkt')
nltk.download('stopwords')
nltk.download('averaged_perceptron_tagger')

#some definitions
en_stop = get_stop_words('en') # list of stopwords/english PyPi
stopWords = set(stopwords.words('english')) # list of stopwords/english NLTK


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
keep_noun = ['NN','NNS','NNP','NNPS']
keep_adj = ['JJ','JJR','JJS']
remove_punct_map = dict.fromkeys(map(ord, string.punctuation)) #dictionary to remove punctuation
#===============================================================================
# Document Reading/Writing
#===============================================================================
def cleanText(fname, input_file_abs, output_path):
    ops = open(output_path+'/'+fname,'w', encoding='utf-8') #file where we are writing (same name it was read)
    with open(input_file_abs, 'r', encoding='utf-8') as fin:
        for lines in fin.readlines():
            if not lines.strip():continue #skip blanklines
            words = str(lines) #stream into string
            words = words.split()
            words = applyPOStag(words) #POS-tagger via NLTK
            words = removePunctuation(words) #removes punctuation - even attached to words
            #words = makeLowerCase_notags(words) # makeLowerCase_tags(words) if applyPOS(words) is executed
            words = makeLowerCase_tags(words) # makeLowerCase_notags(words) if applyPOS(words) is NOT executed
            words = chainNouns(words)   
            words = chainAdjectiveNouns(words) 
            words = removeLastRepWord(words)                   
            words = removeStopWords(words) #get rid of stop words 
            words = removePluras(words)
            if not words:continue #in case after all pre-processing cleans all words we skip this sentence
            words = removeTags(words)
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
        if(word.startswith('math-')):
            no_tag_words.append(word)
        else:
            n_word,n_tag = words[index+1]
            if(n_word.startswith('math-')):continue #prevents a non math token to be put together with future math token
            no_tag_words.append(glueNounsAdjective(word, tag, n_word, n_tag))
            
    last_word,last_tag = words[-1] # we need to have the last word regardless of the outcome
    no_tag_words.append(last_word)
    return(no_tag_words)    
#concatenate words that share a common POS_TAG in keep_tags - only working for 2 consecutive words

def glueNounsAdjective(current_word, current_tag, next_word, next_tag):
    if((current_tag in keep_tags) and (next_tag in keep_tags)):
        new_token = current_word +'_'+ next_word
    else:
        new_token = current_word
    return (new_token)
#returns one single token composed by Noun-Adjective (any owrder) based on their tags

def chainNouns(words):
    i = 0
    nouns_words = []
    noun_chain = []
    while (i < len(words)-1):
        curr_word,curr_tag = words[i]
        if(curr_word.startswith('math-')):
            noun_token = appendTokenChain(noun_chain)
            nouns_words.append((noun_token,curr_tag))  #in case there is any word that precedes math-
            noun_chain.clear() #begin a new chain of nouns           
            nouns_words.append((curr_word,curr_tag))
            i+=1
        elif(curr_tag in keep_noun):
            noun_chain.append(curr_word)
            next_word, next_tag = words[i+1] #let's take a look on the next token
            i+=1
            if(next_tag in keep_noun): #the next token is a noun, we can proceed
                continue 
            else:
                noun_token = appendTokenChain(noun_chain)
                noun_chain.clear() #begin a new chain of nouns
                nouns_words.append((noun_token,curr_tag))  #the first tag is maintained 
        else:
            nouns_words.append((curr_word,curr_tag))#if 
            i+=1
    nouns_words.append(words[-1])
    return(nouns_words)
#checks for noun-tokens and put them together as in nouns+
#if the next token is not a noun we break the chain

def chainAdjectiveNouns(words):
    i = 0
    adj_noun_words = []
    adj_noun_chain = []
    noun_flag = False
    
    while (i < len(words)-1):
        curr_word,curr_tag = words[i] 
        if(curr_word.startswith('math-')):
            noun_token = appendTokenChain(adj_noun_chain)
            adj_noun_words.append((noun_token,keep_noun[0])) #in case there is any word that precedes math-
            adj_noun_chain.clear() #begin a new chain of tokens           
            adj_noun_words.append((curr_word,curr_tag))
            i+=1
        else:
            if((curr_tag in keep_adj) and not(noun_flag)):
                adj_noun_chain.append(curr_word)
                next_word, next_tag = words[i+1] #let's take a look on the next token
                i+=1
                if(next_tag in keep_adj): continue #in case next token is adj  we will merge it
                if(next_tag in keep_noun): noun_flag = True #if the next is a noun, only nouns will be allowed from now on
            elif(curr_tag in keep_noun and noun_flag):
                adj_noun_chain.append(curr_word)
                next_word, next_tag = words[i+1] #let's take a look on the next token
                i+=1
                if(next_tag in keep_noun): 
                    continue
                else:
                    noun_token = appendTokenChain(adj_noun_chain)
                    adj_noun_chain.clear() #begin a new chain of nouns
                    adj_noun_words.append((noun_token,keep_noun[0]))  #the first tag is maintained
            else: #not adj or noun we can add the current word
                adj_noun_words.append((curr_word,curr_tag))#if 
                i+=1
    adj_noun_words.append(words[-1])
    return(adj_noun_words)
 #it will merge ADJ*NOUNS+ tokens - it keeps Noun-tg for these new tokens
          
def appendTokenChain(words):
    token =""
    for word in words:
        if not word: continue
        token+= word + '_'
    return(token[:-1])
#put together tokens that are in the same list

def removeTags(words):
    new_words = []
    for word,tags in words:
        if word is None: continue #in case there is any trash in the word-list
        new_words.append(word)
    return(new_words)
#remove tag from words

def applyPOStag(words):
    tagged_words = nltk.pos_tag(words) #uses the Penn Treebank Tag Set.
    return (tagged_words)
#apply POS tag via NLTK to list of words

def tokenizeWords(sentence):
    return(nltk.word_tokenize(sentence))
#tokenize words - makes POS_Tagger mor efficient

def makeLowerCase_tags(words):
    lower_case = []
    for word,tag in words:
        if(word.startswith('math-')):
            lower_case.append((word,tag))
        else:
            lower_case.append((word.lower(),tag))
    return(lower_case)
#everything in lower case from string - considering POS tags

def makeLowerCase_notags(words):
    lower_case = []
    for word in words:
        if(word.startswith('math-')):
            lower_case.append(word)
        else:
            lower_case.append(word.lower())
    return(lower_case)
#everything in lower case from string

def removePluras(words):
    singles=[]
    for word,tag in words:
        if(word.startswith('math-')):
            singles.append((word,tag))
        else:
            singles.append((inflection.singularize(word),tag)) #using inflection library
            #singles.append((singularize(word),tag)) #using pattern.en
    return (singles)
#gets rid of plurals

def removeStopWords(words):
    no_sw_words = [(w,t) for (w,t) in words if not w in stopWords] #using NLTK stopwords list
    #no_sw_words = [(w,t) for (w,t) in words if not w in en_stop] #using PyPl stopwords list
    return(no_sw_words)
#removes stopwords from list of words

def removePunctuation(words):
    tokens = []
    for word,tag in words:
        if(word.startswith('math-')):
            tokens.append((word,tag))
        else:
            w = word.translate(remove_punct_map)
            tokens.append((w,tag))
    return (tokens)
#removes punctuation - most efficieent - lookptable

def removeLastRepWord(words):
    last_index = -1
    bef_last_index = -2
    before_last,notused_tag = words[bef_last_index]
    last_word,notused_tag = words[last_index]
    temp_word = before_last.split('_')
    if(last_word == temp_word[last_index]): 
        return (words[:last_index])
    else:
        return (words)
#in case the last word is already part of some concatenation of ADJ*NOUN+ or NOUN+
    

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
# Not Used: 2018-12-04
#===============================================================================
def cleanStringPunctuation(words):
    tokens = []
    for word,tag in words:
        if(word.startswith('math-')):
            tokens.append((word,tag))
        else:
            clean_word = word.translate({ord(c): None for c in '()[]{}\'\".;:,!@#$'})
            if(clean_word): 
                tokens.append((clean_word,tag)) #only keep valid items
            else:
                continue # we don't want a empty space in the list
    return(tokens)
#returns a list of clean tokens - gets rid of anything between ' ' by  replacing for None
#it also removes the entry for that empty token in our list
#this is more customizable the way you want - slower

def applyStemmer(words):
    st = LancasterStemmer()
    ste_words = []
    for word,tag in words:
        if(word.startswith('math-')):
            ste_words.append((word,tag))
        else:
            ste_words.append((st.stem(word),tag))
    return (ste_words)
 #Applies Lancaster Stemmer to list of words   - lowercase words
 
def removeASCIItrash(words):
    cwords = words.encode('ascii', 'ignore').decode("utf-8")
    return (cwords)
#removing unwanted chars/trash from sentences as strings




#List of NLTK POS tags
'''
TAGs on NLTK POS :
CC coordinating conjunction
CD cardinal digit
DT determiner
EX existential there (like: there is ... think of it like there exists)
FW foreign word
IN preposition/subordinating conjunction
JJ adjective big
JJR adjective, comparative bigger
JJS adjective, superlative biggest
LS list marker 1)
MD modal could, will
NN noun, singular desk
NNS noun plural desks
NNP proper noun, singular Harrison
NNPS proper noun, plural Americans
PDT predeterminer all the kids
POS possessive ending parent's
PRP personal pronoun I, he, she
PRP $ possessive pronoun my, his, hers
RB adverb very, silently,
RBR adverb, comparative better
RBS adverb, superlative best
RP particle give up
TO, to go to the store.
UH interjection, errrrrrrm
VB verb, base form take
VBD verb, past tense took
VBG verb, gerund/present participle taking
VBN verb, past participle taken
VBP verb, sing. present, non-3d take
VBZ verb, 3rd person sing. present takes
WDT wh-determiner which
WP wh-pronoun who, what
WP$ possessive wh-pronoun whose
WRB wh-abverb where, when
'''