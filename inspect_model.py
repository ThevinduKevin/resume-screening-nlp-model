import pickle
import sys

try:
    with open('clf.pkl', 'rb') as f:
        model = pickle.load(f)
    print(f"Model Type: {type(model)}")
    print(f"Model Params: {model.get_params()}")
    
    with open('tfidf.pkl', 'rb') as f:
        tfidf = pickle.load(f)
    print(f"TF-IDF Vocabulary Size: {len(tfidf.vocabulary_)}")
    print(f"TF-IDF Params: {tfidf.get_params()}")
    
except Exception as e:
    print(f"Error: {e}")
