#### Python datetime formatted
from datetime import datetime
now = datetime.now()

#### Formatted to respect file names rules

# print(now.strftime("%a_%d-%m-%Y_%H-%M"))

print(now.strftime("%Y-%m-%d_%H-%M-%S"))