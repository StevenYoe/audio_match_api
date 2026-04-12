from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from app.core.dependencies import get_db
from app.services.database_service import DatabaseService
from app.services.import_service import ImportService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/products")
async def import_products(
    file: UploadFile = File(..., description="CSV or Excel file containing products data"),
    db: DatabaseService = Depends(get_db)
):
    """
    Import products from CSV or Excel file.
    
    Required columns:
    - mp_name (product name)
    - mp_category (e.g., Subwoofer, Head Unit, Speaker, Amplifier)
    - mp_price (numeric)
    
    Optional columns:
    - mp_brand
    - mp_description
    - mp_image
    - mp_solves_problem_id (UUID, links to a problem)
    - mp_is_active (TRUE/FALSE, default TRUE)
    """
    try:
        # Read file content
        content = await file.read()
        
        # Parse file
        import_service = ImportService()
        products = import_service.parse_file(content, file.filename, data_type="products")
        
        if not products:
            raise HTTPException(status_code=400, detail="No valid data found in file")
        
        # Insert into database
        inserted_count = await db.insert_products(products)
        
        return {
            "message": f"Successfully imported {inserted_count} products",
            "inserted_count": inserted_count,
            "total_rows": len(products)
        }
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error importing products: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to import products: {str(e)}")

@router.post("/problems")
async def import_problems(
    file: UploadFile = File(..., description="CSV or Excel file containing problems data"),
    db: DatabaseService = Depends(get_db)
):
    """
    Import customer problems from CSV or Excel file.
    
    Required columns:
    - mcp_problem_title (problem title)
    
    Optional columns:
    - mcp_description
    - mcp_recommended_approach (solution approach)
    - mcp_is_active (TRUE/FALSE, default TRUE)
    """
    try:
        # Read file content
        content = await file.read()
        
        # Parse file
        import_service = ImportService()
        problems = import_service.parse_file(content, file.filename, data_type="problems")
        
        if not problems:
            raise HTTPException(status_code=400, detail="No valid data found in file")
        
        # Insert into database
        inserted_count = await db.insert_problems(problems)
        
        return {
            "message": f"Successfully imported {inserted_count} problems",
            "inserted_count": inserted_count,
            "total_rows": len(problems)
        }
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error importing problems: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to import problems: {str(e)}")

@router.post("/auto-link")
async def auto_link_products_to_problems(
    db: DatabaseService = Depends(get_db)
):
    """
    Automatically link products to problems based on keyword matching.
    This is a helper endpoint to establish initial relationships.
    """
    try:
        from app.services.import_service import ImportService
        import_service = ImportService()
        
        linked_count = await import_service.auto_link_products_to_problems(db)
        
        return {
            "message": f"Successfully linked {linked_count} products to problems",
            "linked_count": linked_count
        }
        
    except Exception as e:
        logger.error(f"Error auto-linking products: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to auto-link: {str(e)}")
