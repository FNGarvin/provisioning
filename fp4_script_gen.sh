#!/bin/bash

# 1. Create the 'addons' directory if it doesn't exist
mkdir -p addons

# 2. Find all relevant files in the current directory and the 'addons' subdirectory
find . -type f -name '*nunchaku*int4*.sh' \
    \( -path './addons/*' -o -name '*nunchaku*int4*.sh' \) \
    -print0 | 
    
# 3. Process each file
while IFS= read -r -d $'\0' FILE; do
    # Calculate the new filename by substituting 'int4' with 'fp4'
    NEW_FILE="${FILE/int4/fp4}"
    
    # Use sed to perform the in-file substitution (int4 -> fp4) and output to the new file
    sed 's/int4/fp4/g' "$FILE" > "$NEW_FILE"
    
    echo "Created $NEW_FILE"
done

#END OF fp4_generator.sh
