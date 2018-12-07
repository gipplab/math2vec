import smart_open
import csv
import json
import gensim

from scipy import spatial

from .translations import forward_trans as forward_translation


class DefinienIdentifier:
    # weights (semantic+distance must be 1)
    weight_semantic = 0.9
    weight_distance = 0.1
    weight_sentences = 0.8

    # what's the minimum distance to take the result for
    accuracy_threshold = 0.7

    w2v_topn = 100
    d2v_topn = 20

    infer_steps = 300

    semantic_combinations = [
        ['variable', 'math-a'],
        ['variable', 'math-x'],
        ['function', 'math-f']
    ]

    def __init__(self, w2v_path, d2v_path, gold_file):
        print('Init Word2Vec model...')
        self.word2vec = self.load_word2vec(w2v_path)
        print('Done. Init Doc2Vec model...')
        self.model = self.load_doc2vec_model(d2v_path)
        self.doc2vec = self.model.docvecs
        print('Done.')
        self.gold_standard = self.load_gold_standard(gold_file)

    # 4 methods for all approaches
    # CSV: [gold-id, title, identifier, result]
    def compute_simple_distances(self, filename="simple-distances.csv"):
        print('Perform simple distance computations.')
        results = self.generating_results(self.get_closest_word_vectors)
        print('Write results to CSV file %s' % filename)
        self.write_csv(results, filename)

    def compute_semantic_relations(self, filename="semantic-distances.csv"):
        print('Perform semantic evaluation computations.')
        results = self.generating_results(self.get_closest_semantic_vectors)
        print('Write results to CSV file %s' % filename)
        self.write_csv(results, filename)

    def compute_semantic_relations_with_distances_update(self, filename="semantic-distances-combined.csv"):
        print('Perform semantic computations with updated results by their distances.')
        results = self.generating_results(self.get_closest_distance_semantic_combined_vectors)
        print('Write results to CSV file %s' % filename)
        self.write_csv(results, filename)

    def generating_results(self, method):
        results = []
        for gold_entry in self.gold_standard:
            id = gold_entry['formula']['qID']
            title = gold_entry['formula']['title']
            for identifier in gold_entry['definitions']:
                try:
                    translated = forward_translation(identifier)
                    closest_vecs = method(translated)
                    is_first = True
                    for result in closest_vecs:
                        if is_first:
                            results.append([id, title, identifier, result[0]])
                            is_first = False
                        elif result[1] >= self.accuracy_threshold:
                            results.append([id, title, identifier, result[0]])
                except KeyError:
                    print(
                        "KeyError for identifier %s in Gold-ID %s. Skip it..." % (identifier, id)
                    )
                except Exception as err:
                    print("Unknown error raised: %s" % str(err))
        return results

    def get_enhanced_context_vectors(self, context, identifier):
        closest_docs = self.get_document_similarities(context)
        closest_vecs = self.get_closest_distance_semantic_combined_vectors(identifier)
        combined_results = []
        for word, distance in closest_vecs:
            # distance of each word to the sentences
            doc_dist = []
            word_vec = self.model.infer_vector(word, steps=self.infer_steps)
            for doc_id, distance in closest_docs:
                # cosine similarity between word_vec and doc_vec
                doc_dist.append(
                    1 - spatial.distance.cosine(word_vec, self.doc2vec[doc_id])
                )
            ewa = self.exponentially_weighted_average(doc_dist)
            combined_results.append((word, ewa))
        return sorted(combined_results, key=lambda result: result[1])

    def get_closest_distance_semantic_combined_vectors(self, identifier):
        results = self.get_closest_semantic_vectors(identifier)
        return self.update_semantic_via_distances(identifier, results)

    def get_closest_semantic_vectors(self, identifier):
        results = []
        for case in self.semantic_combinations:
            top_results = self.word2vec.wv.most_similar(
                positive=[case[0], identifier],
                negative=[case[1]],
                topn=100
            )
            results.append(top_results)
        return DefinienIdentifier.combine_semantic_vecs(results)

    def get_closest_word_vectors(self, identifier):
        return self.word2vec.most_similar(identifier, topn=self.w2v_topn)

    def update_semantic_via_distances(self, identifier, semantic_vectors):
        output = []
        for vector in semantic_vectors:
            distance = self.word2vec.similarity(vector[0], identifier)
            new_distance = self.weight_semantic*vector[1] + self.weight_distance*distance
            output.append((vector[0], new_distance))
        return sorted(output, key=lambda v: v[1])

    def get_document_similarities(self, document):
        text_arr = self.prepare_document(document)
        text_vec = self.model.infer_vector(text_arr)
        return self.doc2vec.most_similar([text_vec], topn=self.d2v_topn)

    @staticmethod
    def prepare_document(document):
        # TODO change this according to the current model
        return document.lower().split()

    @staticmethod
    def exponentially_weighted_average(vector, rho=0.7):
        # vector contains tuples (words, distances)
        sum = 0.0
        n = 0
        for dist in vector:
            # rho^n * distance
            sum = sum + ((rho ** n) * dist)
            n = n+1
        return sum * (1-rho)/(1-(rho ** len(vector)))

    @staticmethod
    def combine_semantic_vecs(vectors):
        # if a value appears multiple times, take the average distance
        words_dic = {}
        for vec in vectors:
            for v in vec: # v = ('word', <distance>)
                if v[0] in words_dic:
                    words_dic[v[0]].append(v[1])
                else:
                    words_dic[v[0]] = [v[1]]

        output = []
        for entry in words_dic:
            avg = sum(words_dic[entry]) / float(len(words_dic[entry]))
            output.append((entry, avg))

        # sorted by distances
        return sorted(output, key=lambda word: word[1])

    @staticmethod
    def load_word2vec(path):
        return gensim.models.KeyedVectors.load_word2vec_format(path, binary=False)

    @staticmethod
    def load_doc2vec_model(path):
        return gensim.models.Doc2Vec.load(path)

    @staticmethod
    def load_gold_standard(path):
        with open(path, 'r') as f:
            return json.load(f)

    @staticmethod
    def write_csv(data, file):
        outf = open(file, 'x')
        writer = csv.writer(outf)
        for row in data:
            writer.writerow(row)

    @staticmethod
    def read_document_corpus(fname, tokens_only=False):
        with smart_open.smart_open(fname, encoding="utf-8") as f:
            for i, line in enumerate(f):
                if tokens_only:
                    yield line.split()
                else:
                    yield gensim.models.doc2vec.TaggedDocument(line.split(), [i])


