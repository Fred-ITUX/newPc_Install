#### Python datetime formatted
from datetime import datetime
now = datetime.now()


#### Unix style
# echo -e "$(date +%a\ %b\ %d\ %Y\ %H:%M:%S)"

 

# print(now.strftime("%A, %d/%m/%Y | %H:%M"))
print(now.strftime("%a %b %d %Y %H:%M:%S"))

