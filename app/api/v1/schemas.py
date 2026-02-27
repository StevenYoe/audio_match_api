from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class ChatRequest(BaseModel):
    session_id: Optional[str] = Field(None, description="Unique identifier for the conversation session.")
    message: str = Field(..., description="The user's message.")

class SolutionProduct(BaseModel):
    id: str = Field(..., alias="product_id")
    name: str = Field(..., alias="product_name")
    category: str = Field(..., alias="product_category")
    price: float = Field(..., alias="product_price")
    image: Optional[str] = "⚡"

    class Config:
        populate_by_name = True

class RecommendedSolution(BaseModel):
    solution_id: str
    solution_title: str
    solution_description: str
    products: List[SolutionProduct]

class ChatResponse(BaseModel):
    session_id: str = Field(..., description="Unique identifier for the conversation session.")
    response: str = Field(..., description="The chatbot's response message.")
    recommendations: Optional[List[RecommendedSolution]] = Field(None, description="A list of recommended solutions and products, if any.")
    debug_info: Optional[Dict[str, Any]] = Field(None, description="Debugging information, only available in debug mode.")

class ProductResponse(BaseModel):
    id: str
    name: str
    category: str
    price: float
    description: Optional[str]
    image: Optional[str] = "⚡"
    brand: Optional[str] = None
    is_active: bool = True
