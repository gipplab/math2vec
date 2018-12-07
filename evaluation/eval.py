from tools import computations

# paths:
base_path = "/home/truas/arxiv_andre_models/nptrain_round2/"
w2v_model_path = base_path + "nptrain-dbow-400d-20w-05mc-05ns-50e-w2v.vector"
d2v_model_path = base_path + "nptrain-dbow-400d-25w-10mc-05ns-30e-d2v.model"

gold_file = "gold.json"

evaluator = computations.DefinienIdentifier(w2v_model_path, d2v_model_path, gold_file)

evaluator.get_closest_word_vectors()
evaluator.get_closest_semantic_vectors()
evaluator.get_closest_distance_semantic_combined_vectors()