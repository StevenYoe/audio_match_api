from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from app.api.v1 import schemas
from app.core.dependencies import get_db
from app.services.database_service import DatabaseService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/", response_model=List[schemas.ProductResponse])
async def get_products(
    category: Optional[str] = Query("all", description="Filter products by category. Use 'all' for no filter."),
    db: DatabaseService = Depends(get_db)
):
    """
    Get all active products with optional category filter.
    Default is 'all'.
    """
    try:
        raw_products = await db.get_products(category)
        products = []
        for p in raw_products:
            products.append({
                "id": str(p['mp_id']),
                "name": p['mp_name'],
                "category": p['mp_category'],
                "price": float(p['mp_price']),
                "description": p['mp_description'],
                "image": p.get('mp_image') or "⚡",
                "brand": p.get('mp_brand'),
                "is_active": p.get('mp_is_active', True)
            })
        return products
    except Exception as e:
        logger.error(f"Error fetching products: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error while fetching products.")
