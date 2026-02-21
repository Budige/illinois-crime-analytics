"""
ARIMA Time-Series Forecasting for Crime Data

Author: Rakesh Budige
Date: January 2025
Purpose: Forecast future crime incidents using ARIMA models

This module implements ARIMA (AutoRegressive Integrated Moving Average)
forecasting for crime time series data. Started simple, evolved to include
confidence intervals and model evaluation.
"""

import logging
from typing import Tuple, Optional, Dict
from pathlib import Path

import pandas as pd
import numpy as np
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tools.sm_exceptions import ConvergenceWarning
import warnings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Suppress convergence warnings (we'll handle them)
warnings.simplefilter('ignore', ConvergenceWarning)


class CrimeForecastModel:
    """
    ARIMA-based crime forecasting model.
    
    Implements time-series forecasting for crime incidents with
    configurable ARIMA parameters and confidence interval estimation.
    
    Attributes:
        order (Tuple[int, int, int]): ARIMA (p, d, q) parameters
        model: Fitted ARIMA model (None until fit() is called)
    """
    
    def __init__(self, order: Tuple[int, int, int] = (2, 1, 2)):
        """
        Initialize ARIMA forecasting model.
        
        Args:
            order: ARIMA (p, d, q) parameters
                p: autoregressive order
                d: differencing order  
                q: moving average order
        """
        self.order = order
        self.model = None
        self._fitted_values = None
        
        logger.info(f"Initialized CrimeForecastModel with order {order}")
    
    def fit(self, data: pd.Series) -> 'CrimeForecastModel':
        """
        Fit ARIMA model to time series data.
        
        Args:
            data: Time series data (pd.Series with DatetimeIndex)
            
        Returns:
            self: Fitted model instance
            
        Raises:
            ValueError: If data is insufficient for model order
        """
        # Validate input
        if len(data) < sum(self.order) + 10:
            raise ValueError(
                f"Insufficient data points. Need at least {sum(self.order) + 10}, "
                f"got {len(data)}"
            )
        
        logger.info(f"Fitting ARIMA{self.order} on {len(data)} observations")
        
        # TODO: Add auto-selection of ARIMA parameters (p, d, q)
        # TODO: Consider SARIMA for seasonal patterns
        
        try:
            # Fit ARIMA model
            self.model = ARIMA(data, order=self.order)
            self.model = self.model.fit()
            
            # Store fitted values for evaluation
            self._fitted_values = self.model.fittedvalues
            
            # Debug: Check if model converged properly
            # print(f"DEBUG: AIC={self.model.aic}, BIC={self.model.bic}")
            
            logger.info(f"Model fitted successfully. AIC: {self.model.aic:.2f}")
            
        except Exception as e:
            logger.error(f"Failed to fit model: {str(e)}")
            # NOTE: Sometimes convergence fails with certain parameter combinations
            # Try adjusting order or use more data if this happens
            raise
        
        return self
    
    def predict(
        self, 
        periods: int = 12,
        confidence_level: float = 0.95
    ) -> Tuple[pd.Series, pd.DataFrame]:
        """
        Generate forecasts with confidence intervals.
        
        Args:
            periods: Number of periods to forecast
            confidence_level: Confidence level for intervals (0-1)
            
        Returns:
            Tuple of:
                - Forecast values (pd.Series)
                - Confidence intervals (pd.DataFrame with 'lower' and 'upper')
                
        Raises:
            RuntimeError: If model hasn't been fitted
        """
        if self.model is None:
            raise RuntimeError("Model must be fitted before prediction")
        
        logger.info(f"Generating {periods}-period forecast")
        
        # Get forecast with confidence intervals
        forecast_result = self.model.forecast(steps=periods)
        forecast = self.model.get_forecast(steps=periods)
        confidence_int = forecast.conf_int(alpha=1-confidence_level)
        
        # Create forecast series with future dates
        last_date = self.model.data.dates[-1]
        future_dates = pd.date_range(
            start=last_date + pd.DateOffset(months=1),
            periods=periods,
            freq='MS'
        )
        
        forecast_series = pd.Series(forecast_result, index=future_dates)
        confidence_df = pd.DataFrame({
            'lower': confidence_int.iloc[:, 0].values,
            'upper': confidence_int.iloc[:, 1].values
        }, index=future_dates)
        
        return forecast_series, confidence_df
    
    def evaluate(self, actual: pd.Series) -> Dict[str, float]:
        """
        Evaluate model performance on historical data.
        
        Args:
            actual: Actual values for comparison
            
        Returns:
            Dictionary of evaluation metrics (MAPE, RMSE, MAE)
        """
        if self._fitted_values is None:
            raise RuntimeError("Model must be fitted before evaluation")
        
        # Align actual and fitted values
        aligned_actual = actual[self._fitted_values.index]
        
        # Calculate metrics
        errors = aligned_actual - self._fitted_values
        abs_errors = np.abs(errors)
        pct_errors = np.abs((aligned_actual - self._fitted_values) / aligned_actual) * 100
        
        metrics = {
            'mape': np.mean(pct_errors[np.isfinite(pct_errors)]),  # Mean Absolute Percentage Error
            'rmse': np.sqrt(np.mean(errors ** 2)),  # Root Mean Squared Error
            'mae': np.mean(abs_errors)  # Mean Absolute Error
        }
        
        logger.info(
            f"Model Performance - MAPE: {metrics['mape']:.2f}%, "
            f"RMSE: {metrics['rmse']:.2f}, MAE: {metrics['mae']:.2f}"
        )
        
        return metrics
    
    # TODO: Add SARIMA support for seasonality
    # TODO: Implement automatic parameter selection (auto_arima)
    # TODO: Add cross-validation for robust performance estimation


def forecast_county_crime(
    county_name: str,
    data_path: Path,
    periods: int = 12,
    save_output: bool = True
) -> Tuple[pd.Series, pd.DataFrame, Dict[str, float]]:
    """
    Convenience function to forecast crime for a specific county.
    
    Args:
        county_name: Name of Illinois county
        data_path: Path to processed crime data CSV
        periods: Number of months to forecast
        save_output: Whether to save forecast to file
        
    Returns:
        Tuple of (forecast, confidence_intervals, metrics)
    """
    logger.info(f"Forecasting crime for {county_name}")
    
    # Load data
    df = pd.read_csv(data_path)
    df['incident_date'] = pd.to_datetime(df['incident_date'])
    
    # Filter by county and aggregate by month
    county_data = df[df['county_name'] == county_name].copy()
    monthly = county_data.groupby('incident_date')['incident_count'].sum()
    monthly = monthly.sort_index()
    
    # Fit model
    model = CrimeForecastModel(order=(2, 1, 2))
    model.fit(monthly)
    
    # Generate forecast
    forecast, conf_int = model.predict(periods=periods)
    
    # Evaluate
    metrics = model.evaluate(monthly)
    
    # Save if requested
    if save_output:
        output_dir = data_path.parent.parent / 'outputs' / 'models'
        output_dir.mkdir(parents=True, exist_ok=True)
        
        forecast_df = pd.DataFrame({
            'date': forecast.index,
            'forecast': forecast.values,
            'lower_bound': conf_int['lower'].values,
            'upper_bound': conf_int['upper'].values
        })
        
        output_file = output_dir / f'{county_name}_forecast.csv'
        forecast_df.to_csv(output_file, index=False)
        logger.info(f"Forecast saved to {output_file}")
    
    return forecast, conf_int, metrics


if __name__ == "__main__":
    # Example usage
    from src.config import config
    
    # Test forecasting on Cook County
    data_file = config.PROCESSED_DATA_DIR / 'crime_cleaned.csv'
    
    if data_file.exists():
        forecast, conf_int, metrics = forecast_county_crime(
            county_name='Cook',
            data_path=data_file,
            periods=12,
            save_output=True
        )
        
        print(f"\n{'='*60}")
        print(f"COOK COUNTY 12-MONTH FORECAST")
        print(f"{'='*60}")
        print(f"\nModel Performance:")
        print(f"  MAPE: {metrics['mape']:.2f}%")
        print(f"  RMSE: {metrics['rmse']:.2f}")
        print(f"  MAE: {metrics['mae']:.2f}")
        print(f"\nForecast Preview (first 3 months):")
        print(forecast.head(3))
    else:
        print(f"Data file not found: {data_file}")
        print("Run data processing pipeline first.")
