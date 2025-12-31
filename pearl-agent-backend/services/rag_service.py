import numpy as np
from sentence_transformers import SentenceTransformer  #type: ignore
import faiss


class SimpleRAG:
    def __init__(self):
        self.model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Hardcoded learning resources (for demo)
        self.resources = [
            {"type": "course", "title": "Python for Backend Development", "url": "#", "tags": ["python", "backend"]},
            {"type": "course", "title": "RESTful API Design", "url": "#", "tags": ["rest", "api"]},
            {"type": "course", "title": "SQL Fundamentals", "url": "#", "tags": ["sql", "database"]},
            {"type": "taiken", "title": "Django Project Setup", "url": "#", "tags": ["django", "python"]},
            {"type": "taiken", "title": "FastAPI CRUD Operations", "url": "#", "tags": ["fastapi", "python"]},
            {"type": "article", "title": "Git Best Practices", "url": "#", "tags": ["git", "version-control"]},
            {"type": "article", "title": "Docker for Beginners", "url": "#", "tags": ["docker", "devops"]},
        ]
        
        # Create embeddings
        texts = [f"{r['title']} {' '.join(r['tags'])}" for r in self.resources]
        self.embeddings = self.model.encode(texts)
        
        # Build FAISS index
        self.index = faiss.IndexFlatL2(self.embeddings.shape[1])
        self.index.add(self.embeddings.astype('float32'))
    
    def retrieve(self, query: str, top_k: int = 3):
        query_embedding = self.model.encode([query])
        distances, indices = self.index.search(query_embedding.astype('float32'), top_k)
        
        results = []
        for idx, dist in zip(indices[0], distances[0]):
            resource = self.resources[idx].copy()
            resource['relevance_score'] = float(1 / (1 + dist))
            results.append(resource)
        
        return results


# Initialize globally
rag = SimpleRAG()
