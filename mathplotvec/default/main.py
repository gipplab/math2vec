# uncomment if gensim is installed

import gensim
import numpy as np
import matplotlib.pyplot as plt
from sklearn.manifold import TSNE



def applyColor(word_vector):
    classes = ['red','blue']
    class_vec = []
    for item in word_vector:
        if item.startswith('math') or item.startswith('Math'):
            class_vec.append(classes[0])
        else:
            class_vec.append(classes[1])

    print(class_vec)
    return class_vec


def display_TSNE(model, word, word_flag):
    arr = np.empty((0, 400), dtype='f')
    word_labels = []

    if word_flag:  # get close words word = string
        close_words = model.similar_by_word(word, topn=150)
    else:  # word = vector
        close_words = model.similar_by_vector(word, topn=150)

    # add the vector for each of the closest words to the array
    # arr = np.append(arr, np.array([model[word]]), axis=0)
    for wrd_score in close_words:
        wrd_vector = model[wrd_score[0]]
        word_labels.append(wrd_score[0])
        arr = np.append(arr, np.array([wrd_vector]), axis=0)

    # classes of tokens
    art = applyColor(word_labels)

    # find tsne coords for 2 dimensions
    tsne = TSNE(n_components=2, random_state=0)
    #tsne = TSNEVisualizer(decompose_by=150, random_state=0)

    np.set_printoptions(suppress=True)
    Y = tsne.fit_transform(arr)


    x_coords = Y[:, 0]
    y_coords = Y[:, 1]

    # display scatter plot
    plt.scatter(x_coords, y_coords, c=art)

    for label, x, y in zip(word_labels, x_coords, y_coords):
        plt.annotate(label, xy=(x, y), xytext=(0, 0), textcoords='offset points')
    #plt.xlim(x_coords.min() + 0.00005, x_coords.max() + 0.00005)
    #plt.ylim(y_coords.min() + 0.00005, y_coords.max() + 0.00005)

    # plt.grid(True)
    plt.show()







# load pre-trained word2vec embeddings
# model_path = "mssa1r.model"
model_path = 'C:\\Users\\terry\\Documents\\Datasets\\arxiv\\nptrain-dbow-400d-20w-05mc-05ns-50e-w2v.vector'
model = gensim.models.KeyedVectors.load_word2vec_format(model_path)
# model = gensim.models.KeyedVectors.load(model_path)

token = 'math-a'# japanese#9718217#n'

# testing word-vector
# print(model[token])
#token1 = model[token]

# get the words closest to a word
# print(model.similar_by_word(token, topn=100))

# get the words closest to a vector
# print('By vector: ', model.similar_by_vector(vector_anchor, topn=30))

display_TSNE(model, token, word_flag=True)