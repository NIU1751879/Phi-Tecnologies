from datetime import datetime
import pandas as pd
from typing import List, Optional, Union

class DateFeatures:
    """
    A class to extract and manipulate date/time features from a pandas Series of datetime objects.
    """

    def __init__(self, dates: Union[pd.Series, List[datetime], List[str]]):
        """
        Initialize the DateFeatures object with a pandas Series of datetime objects.

        Args:
            dates (Union[pd.Series, List[datetime], List[str]]): A pandas Series, list of datetime objects, 
                or list of strings representing dates.
        """
        self.dates = self._validate_and_convert_dates(dates)

    @staticmethod
    def _validate_and_convert_dates(dates: Union[pd.Series, List[datetime], List[str]]) -> pd.Series:
        """
        Validate and convert input dates to a pandas Series of datetime objects.

        Args:
            dates (Union[pd.Series, List[datetime], List[str]]): Input dates to validate and convert.

        Returns:
            pd.Series: A pandas Series of datetime objects.

        Raises:
            ValueError: If the input cannot be converted to datetime.
        """
        try:
            return pd.to_datetime(dates)
        except Exception as e:
            raise ValueError(f"Invalid input for dates. Ensure it can be converted to datetime. Error: {e}")

    def week_of_year(self) -> pd.Series:
        """
        Get the ISO week number of the year for each date.

        Returns:
            pd.Series: A pandas Series containing the week numbers.
        """
        return self.dates.dt.isocalendar().week

    def day_of_week(self) -> pd.Series:
        """
        Get the day of the week for each date (Monday=0, Sunday=6).

        Returns:
            pd.Series: A pandas Series containing the day of the week.
        """
        return self.dates.dt.dayofweek

    def month(self) -> pd.Series:
        """
        Get the month of the year for each date.

        Returns:
            pd.Series: A pandas Series containing the month numbers.
        """
        return self.dates.dt.month

    def quarter(self) -> pd.Series:
        """
        Get the quarter of the year for each date.

        Returns:
            pd.Series: A pandas Series containing the quarter numbers.
        """
        return self.dates.dt.quarter

    def hour_range(self, bins: Optional[List[int]] = None, labels: Optional[List[str]] = None) -> pd.Series:
        """
        Bin the hours of the day into specified ranges.

        Args:
            bins (Optional[List[int]]): A list of bin edges for the hour ranges. Defaults to 6 even bins (0-4, 4-8, ...).
            labels (Optional[List[str]]): A list of labels for the bins. Defaults to auto-generated labels.

        Returns:
            pd.Series: A pandas Series containing the binned hour ranges.

        Raises:
            ValueError: If bins and labels are incompatible.
        """
        if bins is None:
            bins = list(range(0, 25, 4))  # Default bins: [0, 4, 8, 12, 16, 20, 24]
        if labels is None:
            labels = [f"{bins[i]}-{bins[i+1]}" for i in range(len(bins) - 1)]
        elif len(labels) != len(bins) - 1:
            raise ValueError("The number of labels must be one less than the number of bins.")
        
        return pd.cut(self.dates.dt.hour, bins=bins, labels=labels, right=False)

    def summary(self) -> pd.DataFrame:
        """
        Generate a summary DataFrame with all extracted features.

        Returns:
            pd.DataFrame: A DataFrame containing all extracted date/time features.
        """
        return pd.DataFrame({
            "date": self.dates,
            "week_of_year": self.week_of_year(),
            "day_of_week": self.day_of_week(),
            "month": self.month(),
            "quarter": self.quarter(),
        })