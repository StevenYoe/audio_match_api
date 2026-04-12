import pandas as pd
import io
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class ImportService:
    """Service for parsing CSV/Excel files and importing data into the database."""
    
    REQUIRED_PRODUCT_COLUMNS = ["mp_name", "mp_category", "mp_price"]
    REQUIRED_PROBLEM_COLUMNS = ["mcp_problem_title"]
    
    PRODUCT_COLUMNS_MAPPING = {
        "mp_name": "mp_name",
        "mp_category": "mp_category",
        "mp_brand": "mp_brand",
        "mp_price": "mp_price",
        "mp_description": "mp_description",
        "mp_image": "mp_image",
        "mp_solves_problem_id": "mp_solves_problem_id",
        "mp_is_active": "mp_is_active",
        # Allow common aliases
        "name": "mp_name",
        "category": "mp_category",
        "brand": "mp_brand",
        "price": "mp_price",
        "description": "mp_description",
        "image": "mp_image",
        "problem_id": "mp_solves_problem_id",
        "active": "mp_is_active",
    }
    
    PROBLEM_COLUMNS_MAPPING = {
        "mcp_problem_title": "mcp_problem_title",
        "mcp_description": "mcp_description",
        "mcp_recommended_approach": "mcp_recommended_approach",
        "mcp_is_active": "mcp_is_active",
        # Allow common aliases
        "title": "mcp_problem_title",
        "problem_title": "mcp_problem_title",
        "description": "mcp_description",
        "recommended_approach": "mcp_recommended_approach",
        "solution": "mcp_recommended_approach",
        "active": "mcp_is_active",
        "is_active": "mcp_is_active",
    }
    
    def parse_file(self, file_content: bytes, filename: str, data_type: str) -> List[Dict[str, Any]]:
        """
        Parse CSV or Excel file and return list of dictionaries.
        
        Args:
            file_content: Raw file content in bytes
            filename: Original filename (to detect format)
            data_type: "products" or "problems"
            
        Returns:
            List of dictionaries ready for database insertion
        """
        try:
            # Detect file format based on extension
            if filename.endswith('.csv'):
                df = pd.read_csv(io.BytesIO(file_content))
            elif filename.endswith(('.xlsx', '.xls')):
                df = pd.read_excel(io.BytesIO(file_content))
            else:
                # Try CSV by default
                df = pd.read_csv(io.BytesIO(file_content))
            
            # Normalize column names (strip whitespace, lowercase for matching)
            df.columns = df.columns.str.strip()
            
            # Validate and map columns
            if data_type == "products":
                return self._process_products(df)
            elif data_type == "problems":
                return self._process_problems(df)
            else:
                raise ValueError(f"Unsupported data type: {data_type}")
                
        except pd.errors.EmptyDataError:
            raise ValueError("File is empty")
        except Exception as e:
            raise ValueError(f"Error parsing file: {str(e)}")
    
    def _process_products(self, df: pd.DataFrame) -> List[Dict[str, Any]]:
        """Process and validate product data."""
        # Map columns
        df = self._map_columns(df, self.PRODUCT_COLUMNS_MAPPING)
        
        # Check required columns
        missing_cols = set(self.REQUIRED_PRODUCT_COLUMNS) - set(df.columns)
        if missing_cols:
            raise ValueError(f"Missing required columns: {', '.join(missing_cols)}")
        
        # Drop rows with missing required values
        df = df.dropna(subset=self.REQUIRED_PRODUCT_COLUMNS)
        
        # Convert price to numeric
        df['mp_price'] = pd.to_numeric(df['mp_price'], errors='coerce')
        df = df.dropna(subset=['mp_price'])
        
        # Convert boolean fields
        if 'mp_is_active' in df.columns:
            df['mp_is_active'] = df['mp_is_active'].apply(self._parse_boolean)
        else:
            df['mp_is_active'] = True
        
        # Convert to list of dicts
        products = []
        for _, row in df.iterrows():
            product = {
                'mp_name': str(row['mp_name']).strip(),
                'mp_category': str(row['mp_category']).strip(),
                'mp_brand': str(row.get('mp_brand', '')).strip() if pd.notna(row.get('mp_brand')) else None,
                'mp_price': float(row['mp_price']),
                'mp_description': str(row.get('mp_description', '')).strip() if pd.notna(row.get('mp_description')) else None,
                'mp_image': str(row.get('mp_image', '')).strip() if pd.notna(row.get('mp_image')) else None,
                'mp_solves_problem_id': str(row['mp_solves_problem_id']).strip() if pd.notna(row.get('mp_solves_problem_id')) else None,
                'mp_is_active': bool(row.get('mp_is_active', True)),
            }
            products.append(product)
        
        return products
    
    def _process_problems(self, df: pd.DataFrame) -> List[Dict[str, Any]]:
        """Process and validate problem data."""
        # Map columns
        df = self._map_columns(df, self.PROBLEM_COLUMNS_MAPPING)
        
        # Check required columns
        missing_cols = set(self.REQUIRED_PROBLEM_COLUMNS) - set(df.columns)
        if missing_cols:
            raise ValueError(f"Missing required columns: {', '.join(missing_cols)}")
        
        # Drop rows with missing required values
        df = df.dropna(subset=self.REQUIRED_PROBLEM_COLUMNS)
        
        # Convert boolean fields
        if 'mcp_is_active' in df.columns:
            df['mcp_is_active'] = df['mcp_is_active'].apply(self._parse_boolean)
        else:
            df['mcp_is_active'] = True
        
        # Convert to list of dicts
        problems = []
        for _, row in df.iterrows():
            problem = {
                'mcp_problem_title': str(row['mcp_problem_title']).strip(),
                'mcp_description': str(row.get('mcp_description', '')).strip() if pd.notna(row.get('mcp_description')) else None,
                'mcp_recommended_approach': str(row.get('mcp_recommended_approach', '')).strip() if pd.notna(row.get('mcp_recommended_approach')) else None,
                'mcp_is_active': bool(row.get('mcp_is_active', True)),
            }
            problems.append(problem)
        
        return problems
    
    def _map_columns(self, df: pd.DataFrame, column_mapping: Dict[str, str]) -> pd.DataFrame:
        """Map column names to standard format."""
        rename_dict = {}
        for col in df.columns:
            col_lower = col.lower()
            if col_lower in column_mapping:
                rename_dict[col] = column_mapping[col_lower]
        
        df = df.rename(columns=rename_dict)
        return df
    
    def _parse_boolean(self, value) -> bool:
        """Parse boolean values from various formats."""
        if isinstance(value, bool):
            return value
        if isinstance(value, (int, float)):
            return bool(value)
        if isinstance(value, str):
            return value.strip().lower() in ['true', '1', 'yes', 'y', 't']
        return False
    
    async def auto_link_products_to_problems(self, db) -> int:
        """
        Automatically link products to problems based on keyword matching.
        This is a helper function to establish initial relationships.
        
        Returns:
            Number of products linked
        """
        try:
            # Get all problems
            problems_query = "SELECT mcp_id, mcp_problem_title, mcp_description FROM sales.master_customer_problems WHERE mcp_is_active = TRUE"
            problems = await db.fetch(problems_query)
            
            if not problems:
                return 0
            
            # Build keyword map from problems
            problem_keywords = {}
            for prob in problems:
                title = prob.get('mcp_problem_title', '').lower()
                desc = prob.get('mcp_description', '').lower()
                keywords = set(title.split() + desc.split())
                # Remove common stop words
                stop_words = {'yang', 'dan', 'atau', 'dengan', 'untuk', 'pada', 'dalam', 'adalah', 'ini', 'itu', 'tidak', 'kurang', 'sangat'}
                keywords = keywords - stop_words
                problem_keywords[str(prob['mcp_id'])] = keywords
            
            # Get all unlinked products
            products_query = "SELECT mp_id, mp_name, mp_category, mp_description FROM sales.master_products WHERE mp_solves_problem_id IS NULL AND mp_is_active = TRUE"
            products = await db.fetch(products_query)
            
            if not products:
                return 0
            
            # Match products to problems
            linked_count = 0
            for prod in products:
                product_text = f"{prod['mp_name']} {prod.get('mp_category', '')} {prod.get('mp_description', '')}".lower()
                product_words = set(product_text.split())
                
                # Find best matching problem
                best_match = None
                best_score = 0
                
                for prob_id, keywords in problem_keywords.items():
                    # Count matching keywords
                    matches = len(keywords & product_words)
                    if matches > best_score:
                        best_score = matches
                        best_match = prob_id
                
                # Link if there's a match
                if best_match and best_score >= 2:  # At least 2 keyword matches
                    update_query = "UPDATE sales.master_products SET mp_solves_problem_id = $1 WHERE mp_id = $2"
                    await db.execute(update_query, best_match, str(prod['mp_id']))
                    linked_count += 1
            
            return linked_count
            
        except Exception as e:
            logger.error(f"Error in auto_link_products_to_problems: {e}")
            raise
