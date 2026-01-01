from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
import pickle
import docx
import PyPDF2
import re
import io
import time
import uvicorn
import logging

# Define Request Model for JSON body parsing
class ResumeTextRequest(BaseModel):
    resume_text: str

app = FastAPI(title="Resume Screening API", version="1.0")

# Load models
try:
    svc_model = pickle.load(open('clf.pkl', 'rb'))
    tfidf = pickle.load(open('tfidf.pkl', 'rb'))
    le = pickle.load(open('encoder.pkl', 'rb'))
except FileNotFoundError:
    print("Error: Model files not found. Check S3 download in user_data.")

def cleanResume(txt):
    cleanText = re.sub('http\S+\s', ' ', txt)
    cleanText = re.sub('RT|cc', ' ', cleanText)
    cleanText = re.sub('#\S+\s', ' ', cleanText)
    cleanText = re.sub('@\S+', '  ', cleanText)
    cleanText = re.sub('[%s]' % re.escape("""!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~"""), ' ', cleanText)
    cleanText = re.sub(r'[^\x00-\x7f]', ' ', cleanText)
    cleanText = re.sub('\s+', ' ', cleanText)
    return cleanText

def pred(input_resume):
    cleaned_text = cleanResume(input_resume)
    vectorized_text = tfidf.transform([cleaned_text])
    vectorized_text = vectorized_text.toarray()
    predicted_category = svc_model.predict(vectorized_text)
    predicted_category_name = le.inverse_transform(predicted_category)
    return predicted_category_name[0]

@app.post("/predict/text")
async def predict_resume_text(request: ResumeTextRequest):
    """Direct text input fixed for Locust JSON compatibility"""
    start_time = time.time()
    try:
        category = pred(request.resume_text)
        processing_time = (time.time() - start_time) * 1000
        return {
            "category": category,
            "processing_time_ms": round(processing_time, 2),
            "message": "Text analyzed successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model": "loaded"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)