from tools import computations

# paths:
base_path = "/home/truas/arxiv_andre_models/nptrain_round2/"
w2v_model_path = base_path + "nptrain-dbow-400d-20w-05mc-05ns-50e-w2v.vector"
d2v_model_path = base_path + "nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model"

gold_file = "gold.json"

csvdata = computations.DefinienIdentifier.read_csv("extraction.csv")


# evaluator = computations.DefinienIdentifier(w2v_model_path, d2v_model_path, gold_file)

# evaluator.get_closest_word_vectors()
# evaluator.get_closest_semantic_vectors()
# evaluator.get_closest_distance_semantic_combined_vectors()

# /home/truas/arxiv_andre_models/np_train_181213/
# nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model                           nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model.wv.vectors.npy
# nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model.docvecs.vectors_docs.npy  nptrain-dbow-400d-25w-10mc-05ns-30e-w2v.vector
# nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model.trainables.syn1neg.npy
base_p = "/home/truas/arxiv_andre_models/np_train_181213/"
w2v_p = base_p + "nptrain-dbow-400d-25w-10mc-05ns-30e-w2v.vector"

"/home/truas/arxiv_andre_models/train-lowercase-25gb/train-raw-lower-combined-d2v.model"
"/home/truas/programs/Word2Vec_Ruas/files/input/train-raw-lower-combined.txt"