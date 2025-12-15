import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, LSTM, Conv1D, MaxPooling1D, Embedding, Dropout
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import pickle

#CONFIGURATION
VOCAB_SIZE = 5000   # Max unique words to learn
MAX_LENGTH = 100    # Max length of a sentence
EMBEDDING_DIM = 100 

print("1. Loading Data from CSV...")

#LOAD DATASET
try:
    # Read your specific file
    data = pd.read_csv('call_transcript_cleaned.csv')
    
    # 1. Get the conversations (Input)
    texts = data['TEXT'].astype(str).tolist()
    
    # 2. Get the labels (Output: 0=Legit, 1=Scam)
    labels = data['CATEGORY'].values

    print(f"   Successfully loaded {len(texts)} rows of data.")

except FileNotFoundError:
    print("ERROR: Could not find 'call_transcript_cleaned.csv'.")
    print(" Make sure the file is in the 'backend_api' folder!")
    exit()

#TEXT PREPROCESSING
print("2. Tokenizing Text...")
tokenizer = Tokenizer(num_words=VOCAB_SIZE, oov_token="<OOV>")
tokenizer.fit_on_texts(texts)
sequences = tokenizer.texts_to_sequences(texts)
padded_sequences = pad_sequences(sequences, maxlen=MAX_LENGTH, padding='post', truncating='post')

# Save the Tokenizer (Critical for app.py to understand new words)
with open('tokenizer.pickle', 'wb') as handle:
    pickle.dump(tokenizer, handle, protocol=pickle.HIGHEST_PROTOCOL)
print("   Tokenizer saved.")

#BUILD CNN-LSTM MODEL
print("3. Building AI Model...")
model = Sequential([
    Embedding(VOCAB_SIZE, EMBEDDING_DIM, input_length=MAX_LENGTH),
    
    # CNN Layer (Finds keywords like 'password', 'urgent')
    Conv1D(filters=128, kernel_size=5, activation='relu'),
    MaxPooling1D(pool_size=2),
    
    # LSTM Layer (Understands context/sentences)
    LSTM(64),
    Dropout(0.2), # Helps prevent overfitting since dataset is small
    
    # Output Layer
    Dense(1, activation='sigmoid')
])

model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])

#TRAIN MODEL
print("4. Training Model (this might take 10-20 seconds)...")
# Using epochs=10 because the dataset is small (358 rows)
model.fit(padded_sequences, labels, epochs=10, verbose=1)

#SAVE MODEL
model.save('scam_detector_model.h5')
print("\n✅ SUCCESS: Model saved as 'scam_detector_model.h5'")
print("   You can now restart app.py to use this new brain!")