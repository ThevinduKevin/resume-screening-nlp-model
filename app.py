from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from fastapi import Query
import pickle
import docx
import PyPDF2
import re
import io
import time
import uvicorn
import logging

app = FastAPI(title="Resume Screening API", version="1.0")

# Load your existing models (same as Streamlit)
svc_model = None
tfidf = None
le = None
model_load_error = None

try:
    svc_model = pickle.load(open('clf.pkl', 'rb'))
    tfidf = pickle.load(open('tfidf.pkl', 'rb'))
    le = pickle.load(open('encoder.pkl', 'rb'))
    print("Models loaded successfully")
except Exception as e:
    model_load_error = str(e)
    print(f"CRITICAL ERROR: Failed to load models: {e}")

# YOUR EXISTING FUNCTIONS (unchanged)
def cleanResume(txt):
    cleanText = re.sub('http\S+\s', ' ', txt)
    cleanText = re.sub('RT|cc', ' ', cleanText)
    cleanText = re.sub('#\S+\s', ' ', cleanText)
    cleanText = re.sub('@\S+', '  ', cleanText)
    cleanText = re.sub('[%s]' % re.escape("""!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~"""), ' ', cleanText)
    cleanText = re.sub(r'[^\x00-\x7f]', ' ', cleanText)
    cleanText = re.sub('\s+', ' ', cleanText)
    return cleanText

def extract_text_from_pdf(file):
    pdf_reader = PyPDF2.PdfReader(file)
    text = ''
    for page in pdf_reader.pages:
        text += page.extract_text()
    return text

def extract_text_from_docx(file):
    doc = docx.Document(file)
    text = ''
    for paragraph in doc.paragraphs:
        text += paragraph.text + '\n'
    return text

def extract_text_from_txt(file):
    try:
        text = file.read().decode('utf-8')
    except UnicodeDecodeError:
        text = file.read().decode('latin-1')
    return text

def handle_file_upload(uploaded_file):
    file_extension = uploaded_file.filename.split('.')[-1].lower()
    file_content = uploaded_file.file.read()
    
    if file_extension == 'pdf':
        return extract_text_from_pdf(io.BytesIO(file_content))
    elif file_extension == 'docx':
        return extract_text_from_docx(io.BytesIO(file_content))
    elif file_extension == 'txt':
        return extract_text_from_txt(io.BytesIO(file_content))
    else:
        raise ValueError("Unsupported file type. Please upload PDF, DOCX, or TXT")

# YOUR EXISTING PREDICTION FUNCTION (unchanged)
def pred(input_resume):
    cleaned_text = cleanResume(input_resume)
    vectorized_text = tfidf.transform([cleaned_text])
    vectorized_text = vectorized_text.toarray()
    predicted_category = svc_model.predict(vectorized_text)
    predicted_category_name = le.inverse_transform(predicted_category)
    return predicted_category_name[0]

# API Endpoints
@app.post("/predict")
async def predict_resume(file: UploadFile = File(...)):
    """Upload resume file and get predicted category"""
    start_time = time.time()
    
    try:
        # Extract text from uploaded file
        resume_text = handle_file_upload(file)
        
        if model_load_error:
            raise HTTPException(status_code=500, detail=f"Model not loaded: {model_load_error}")
        
        # Predict category (your exact logic)
        category = pred(resume_text)
        processing_time = (time.time() - start_time) * 1000
        
        return {
            "category": category,
            "processing_time_ms": round(processing_time, 2),
            "message": "Resume analyzed successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

class TextRequest(BaseModel):
    resume_text: str

@app.post("/predict/text")
async def predict_resume_text(request: TextRequest):
    start_time = time.time()
    try:
        if model_load_error:
            raise HTTPException(status_code=500, detail=f"Model not loaded: {model_load_error}")

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
    if model_load_error:
        return {"status": "unhealthy", "error": model_load_error}
    return {"status": "healthy", "model": "loaded"}

@app.get("/ping")
async def ping():
    return {"status": "pong", "runtime": "aws-lambda"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
