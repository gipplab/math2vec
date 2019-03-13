# uncomment if gensim is installed

import gensim
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
from sklearn.manifold import TSNE

colors = sns.color_palette("Paired")

def applyColor(word_vector):
    classes = [colors[5], colors[1]]
    class_vec = []
    for item in word_vector:
        if item.startswith('math'):
            class_vec.append(classes[0])
        else:
            class_vec.append(classes[1])

    # print(class_vec)
    return class_vec


def display_TSNE(model, word, word_flag, topn=150, show_all_name=False, add_vectors=None):
    arr = np.empty((0, 400), dtype='f')
    word_labels = []

    if word_flag:  # get close words word = string
        close_words = model.similar_by_word(word, topn)
    else:  # word = vector
        close_words = model.similar_by_vector(word, topn)

    # add the vector for each of the closest words to the array
    # arr = np.append(arr, np.array([model[word]]), axis=0)
    for wrd_score in close_words:
        wrd_vector = model[wrd_score[0]]
        word_labels.append(wrd_score[0])
        arr = np.append(arr, np.array([wrd_vector]), axis=0)

    if add_vectors:
        for w in add_vectors:
            if w not in word_labels:
                wrd_vector = model[w]
                word_labels.append(w)
                arr = np.append(arr, np.array([wrd_vector]), axis=0)

    # classes of tokens
    art = applyColor(word_labels)

    interesting_words = {
        "math-f",
        "math-a",
        "math-mu",
        "function",
        "variable",
        "eq",
        "eq1",
        "1",
        "math-",
        "math-im",
        "math-re",
        "math--sigma",
        "math-cos",
        "math-sinh",
        "math-and",
        "imaginary"
    }

    if not show_all_name:
        for idx, w in enumerate(word_labels):
            if w == "math-mu":
                word_labels[idx] = "$\mu$"
            elif w == "math-f":
                word_labels[idx] = "$f$"
            elif w == "math-a":
                word_labels[idx] = "$a$"
            elif w not in interesting_words: #and not w.startswith("math"):
                word_labels[idx] = ""

    # find tsne coords for 2 dimensions
    tsne = TSNE(n_components=2, random_state=0, perplexity=8, n_iter=1000, n_iter_without_progress=500)
    #tsne = TSNEVisualizer(decompose_by=150, random_state=0)

    np.set_printoptions(suppress=True)
    Y = tsne.fit_transform(arr)


    x_coords = Y[:, 0]
    y_coords = Y[:, 1]

    # display scatter plot
    plt.scatter(x_coords, y_coords, c=art, s=0.7)

    for label, x, y in zip(word_labels, x_coords, y_coords):
        plt.annotate(label, xy=(x, y), xytext=(0, 0), textcoords='offset points')
    #plt.xlim(x_coords.min() + 0.00005, x_coords.max() + 0.00005)
    #plt.ylim(y_coords.min() + 0.00005, y_coords.max() + 0.00005)

    # plt.grid(True)
    # plt.savefig("test.svg")

    # plt.xlim(-15, 15)
    # plt.ylim(-12, 12)

    # plt.title("t-SNE plot of 700 closest vectors to the identifier $f$.")
    plt.xlabel('t-SNE x-axes')
    plt.ylabel('t-SNE y-axes')

    word_legend_label = mpatches.Patch(color=colors[1], label='Word tokens')
    math_legend_label = mpatches.Patch(color=colors[5], label='Math tokens')

    plt.legend(handles=[word_legend_label, math_legend_label])

    # plt.savefig("closest-f.svg")
    plt.show()


# load pre-trained word2vec embeddings
# model_path = "mssa1r.model"
# model_path = 'C:\\Users\\terry\\Documents\\Datasets\\arxiv\\nptrain-dbow-400d-20w-05mc-05ns-50e-w2v.vector'
# model = gensim.models.KeyedVectors.load_word2vec_format(model_path)
# model = gensim.models.KeyedVectors.load(model_path)

# token = 'math-a'

# testing word-vector
# print(model[token])
#token1 = model[token]

# get the words closest to a word
# print(model.similar_by_word(token, topn=100))

# get the words closest to a vector
# print('By vector: ', model.similar_by_vector(vector_anchor, topn=30))

# display_TSNE(model, token, word_flag=True)


# x1 = 'variable'
# x2 = 'math-a'
# x4 = 'math-f'
# x3 = ''
# x11 = model[x1]
# x22 = model[x2]
# x44 = model[x4]
#
# RX = x11 - x22 + x44

# get the words closest to a word
# print(model.similar_by_word(token, topn=100))

# get the words closest to a vector
# print('By vector: ', model.similar_by_vector(vector_anchor, topn=30))

# display_TSNE(model, RX, word_flag=False)