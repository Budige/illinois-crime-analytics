"""
Configuration Management for Illinois Crime Analytics

Author: Rakesh Budige
Date: January 2025
Purpose: Centralized configuration using environment variables

Note: This started as a simple config file but grew as I added
database connection management and file path handling.
"""

import os
from pathlib import Path
from typing import Dict, Any
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """
    Application configuration loaded from environment variables.
    
    Uses .env file for local development and environment variables
    in production. Follows 12-factor app configuration principles.
    """
    
    # Project paths
    BASE_DIR = Path(__file__).parent.parent
    DATA_DIR = BASE_DIR / "data"
    RAW_DATA_DIR = DATA_DIR / "raw"
    PROCESSED_DATA_DIR = DATA_DIR / "processed"
    SAMPLE_DATA_DIR = DATA_DIR / "sample"
    OUTPUT_DIR = BASE_DIR / "outputs"
    
    # Database configuration
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = int(os.getenv("DB_PORT", "5432"))
    DB_NAME = os.getenv("DB_NAME", "illinois_crime")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    
    # Database connection string
    @classmethod
    def get_database_url(cls) -> str:
        """
        Construct PostgreSQL connection string.
        
        Returns:
            str: PostgreSQL connection URL
        """
        return (
            f"postgresql://{cls.DB_USER}:{cls.DB_PASSWORD}@"
            f"{cls.DB_HOST}:{cls.DB_PORT}/{cls.DB_NAME}"
        )
    
    # Data source configuration
    DATA_SOURCE_URL = "https://ilucr.nibrs.com/"  # Illinois State Police I-UCR
    DATA_SOURCE_NAME = "Illinois State Police Uniform Crime Reporting"
    
    # Analysis parameters
    ARIMA_ORDER = (2, 1, 2)  # (p, d, q) parameters for ARIMA model
    FORECAST_PERIODS = 12  # Number of months to forecast
    
    # Logging configuration
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # TODO: Add configuration for API keys when implementing live data fetching
    # TODO: Add email notification settings for automated reports
    
    @classmethod
    def validate(cls) -> bool:
        """
        Validate that required configuration is present.
        
        Returns:
            bool: True if configuration is valid
            
        Raises:
            ValueError: If required config is missing
        """
        required_dirs = [
            cls.DATA_DIR,
            cls.RAW_DATA_DIR,
            cls.PROCESSED_DATA_DIR,
            cls.OUTPUT_DIR
        ]
        
        for directory in required_dirs:
            if not directory.exists():
                directory.mkdir(parents=True, exist_ok=True)
        
        return True


# Create global config instance
config = Config()

# Validate configuration on import
config.validate()


if __name__ == "__main__":
    print(f"Base Directory: {config.BASE_DIR}")
    print(f"Data Directory: {config.DATA_DIR}")
    print(f"Database URL: {config.get_database_url()}")
    print(f"Data Source: {config.DATA_SOURCE_URL}")
