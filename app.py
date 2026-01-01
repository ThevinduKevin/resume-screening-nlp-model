from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import re
import time
import uvicorn

# MUST match the JSON structure from Locust
class ResumeRequest(BaseModel):
    resume_text: str

app = FastAPI()

# Global model variables
svc_model = None
tfidf = None
le = None

@app.on_event("startup")
def load_models():
    global svc_model, tfidf, le
    try:
        svc_model = pickle.load(open('clf.pkl', 'rb'))
        tfidf = pickle.load(open('tfidf.pkl', 'rb'))
        le = pickle.load(open('encoder.pkl', 'rb'))
        print("Models loaded successfully")
    except Exception as e:
        print(f"FAILED TO LOAD MODELS: {e}")

@app.get("/health")
async def health():
    if svc_model is None:
        raise HTTPException(status_code=503, detail="Models not loaded")
    return {"status": "healthy"}

@app.post("/predict/text")
async def predict_text(request: ResumeRequest):
    start_time = time.time()
    try:
        # Your cleaning and prediction logic here
        cleaned = re.sub(r'\s+', ' ', request.resume_text) # Simplified example
        vectorized = tfidf.transform([cleaned]).toarray()
        prediction = svc_model.predict(vectorized)
        category = le.inverse_transform(prediction)[0]
        
        return {
            "category": category,
            "processing_time_ms": round((time.time() - start_time) * 1000, 2)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)