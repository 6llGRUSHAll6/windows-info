import psutil
import time
from datetime import timedelta

boot_time = psutil.boot_time()
uptime = timedelta(seconds=(time.time() - boot_time))
days = uptime.days
hours, remainder = divmod(uptime.seconds, 3600)
minutes, seconds = divmod(remainder, 60)
uptime_str = f"{days}d {hours}h {minutes}m"
print(f"Uptime:     {uptime_str}")
