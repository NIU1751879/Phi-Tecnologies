from datetime import datetime, time
from typing import List


class Session:
    """
    Represents a trading session with a name, start time, and end time.
    """

    def __init__(self, name: str, start: time, end: time):
        if start == end:
            raise ValueError("Start and end times cannot be the same.")
        self.name = name
        self.start = start
        self.end = end

    def is_open(self, dt: datetime) -> bool:
        """
        Check if the session is open at the given datetime.
        """
        t = dt.time()
        if self.start <= self.end:
            return self.start <= t < self.end
        # Handles sessions that span over midnight
        return t >= self.start or t < self.end

    def __repr__(self) -> str:
        return f"Session(name={self.name}, start={self.start}, end={self.end})"


class TradingSessions:
    """
    Manages multiple trading sessions and provides utility methods.
    """

    def __init__(self, sessions: List[Session]):
        self.sessions = sessions

    def get_open_sessions(self, dt: datetime) -> List[str]:
        """
        Get a list of names of sessions that are open at the given datetime.
        """
        return [session.name for session in self.sessions if session.is_open(dt)]

    def __repr__(self) -> str:
        return f"TradingSessions(sessions={self.sessions})"


# Predefined sessions (assumes datetime in UTC):
NY = Session("NY", time(13, 30), time(20, 0))       # 8:30–15:00 EST
EU = Session("EU", time(7, 0), time(15, 30))        # 9:00–17:30 CET
ASIA = Session("ASIA", time(0, 0), time(8, 30))     # 8:00–16:30 JST

# Example usage:
trading_sessions = TradingSessions([NY, EU, ASIA])
current_time = datetime.utcnow()
open_sessions = trading_sessions.get_open_sessions(current_time)
print(f"Open sessions at {current_time}: {open_sessions}")