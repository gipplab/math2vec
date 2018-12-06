import logging
import os.path
import sys
import multiprocessing
import argparse
import gensim
import numpy
import json
import csv
from scipy import spatial

from gensim.corpora import WikiCorpus
from gensim.models import Word2Vec
from gensim.models.word2vec import LineSentence
from gensim.models.keyedvectors import KeyedVectors

from tools import translations as trans

# paths:
base_path = "/home/truas/arxiv_andre_models/nptrain_round2/"
w2v_model_path = base_path + "nptrain-dbow-400d-20w-05mc-05ns-50e-w2v.vector"
d2v_model_path = base_path + "nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model"

gold_file = "gold.json"
csv_file  = "results.csv"

threshold = 0.7


def start(threshold, gold_file, w2v_model):
    # load goldi
    with open(gold_file, 'r') as f:
        data = json.load(f)

    # load w2v model (may take a while)
    word2vec = gensim.models.KeyedVectors.load_word2vec_format(w2v_model, binary=False)

    # go through all gold entries
    for gold_entry in data:
        id = gold_entry['formula']['qID']
        title = gold_entry['formula']['title']

        word2vec.wv.most_similar(
            positive=['variable', 'math-f'],
            negative=['math-a'],
            topn=50
        )
        # TODO

    return None


def write_csv(data):
    file = open(csv_file, 'x')
    writer = csv.writer(file)
    for row in data:
        writer.writerow(row)



#test = [['alpha', 'beta'],[1,2]]
#write_csv(test)
