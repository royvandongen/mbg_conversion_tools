#!/bin/bash

# Set the directory where your folders are located
# Change this to the location name, example SHB-01
source_dir="Input/SHB-01"

# Set the name of the main CSV file and MDP CSV file
main_csv_file="main_folder_info.csv"
mdp_csv_file="mdp_folder_info.csv"

# Initialize the CSV files
> "$main_csv_file"
> "$mdp_csv_file"

# Define variables for headers
main_csv_header="Original Directory Name,Road Name,Dutch Postal Code,Address Number,Address Extension,Room Number,Formatted Value"
mdp_csv_header="Original Directory Name,City Name,Handhole Name,Distribution Point,MDAC Number,Formatted Value"

# Add the headers to the CSV files
echo "$main_csv_header" >> "$main_csv_file"
echo "$mdp_csv_header" >> "$mdp_csv_file"

# Define a function to add a row to the CSV files
add_row_to_csv() {
    echo "$1" >> "$2"
}

# Define a function to generate the formatted value
generate_formatted_value() {
    postal_code="$1"
    address_number="$2"
    address_extension="$3"
    room_number="$4"
    
    formatted_value=""
    
    # Add postal code, address number, address extension, and room number with "-" characters
    formatted_value="$postal_code-$address_number-$address_extension-$room_number"
    
    echo "$formatted_value"
}

# Function to process MDP folders with "handhole_name"
process_mdp_folder_with_handhole() {
    folder_name_with_mdp="$1"
    
    # Remove the "MDP_" prefix
    folder_name="${folder_name_with_mdp#MDP_}"
    
    # Remove spaces from the folder name
    folder_name="${folder_name// /}"
    
    # Debugging
    echo "Processing MDP folder with handhole_name: $folder_name"

    # Extract the fields using regular expressions
    if [[ $folder_name =~ ^([A-Z]{3}-[0-9]{2})([A-Z]{2}[0-9]+)(_?[A-Za-z0-9]*)?\.([0-9]+)$ ]]; then
        echo "Regex matched: $folder_name"
        city_name="${BASH_REMATCH[1]}"
        handhole_name="${BASH_REMATCH[2]}"
        distribution_point="${BASH_REMATCH[3]}"
        mdac_number="${BASH_REMATCH[4]}"
        
        # Remove underscores from the beginning of the address extension
        address_extension="${distribution_point#_}"
        
        # Remove underscores from the distribution point
        distribution_point="${distribution_point//_/}"
        
        # Generate the formatted value
        formatted_value="$city_name-$handhole_name-$distribution_point-$mdac_number"

        # Extract the folder name from the path
        folder_name_only=$(basename "$folder_path")

        # Store the extracted fields and the formatted value in the MDP CSV file
        echo "$folder_name_only,$city_name,$handhole_name,$distribution_point,$mdac_number,$formatted_value" >> "$mdp_csv_file"
    else
        echo "Regex didn't match: $folder_name"
    fi
}


# Function to process MDP folders without "handhole_name"
process_mdp_folder_without_handhole() {
    folder_name_with_mdp="$1"
    
    # Remove the "MDP_" prefix
    folder_name="${folder_name_with_mdp#MDP_}"
    
    # Remove spaces from the folder name
    folder_name="${folder_name// /}"
    
    # Debugging
    echo "Processing MDP folder without handhole_name: $folder_name"

    # Extract the fields using regular expressions
    if [[ $folder_name =~ ^([A-Z]{3}-[0-9]{2})_([A-Za-z0-9]+)\.([0-9]+)$ ]]; then
        echo "Regex matched: $folder_name"
        city_name="${BASH_REMATCH[1]}"
        distribution_point="${BASH_REMATCH[2]}"
        handholeplaceholder=""
        mdac_number="${BASH_REMATCH[3]}"

        # Remove underscores from the distribution point
        distribution_point="${distribution_point//_/}"
        
        # Generate the formatted value
        formatted_value="$city_name--$distribution_point-$mdac_number"

        # Extract the folder name from the path
        folder_name_only=$(basename "$folder_path")

        # Store the extracted fields and the formatted value in the MDP CSV file
        echo "$folder_name_only,$city_name,$distribution_point,$handholeplaceholder,$mdac_number,$formatted_value" >> "$mdp_csv_file"
    else
        echo "Regex didn't match: $folder_name"
    fi
}

# Function to process non-MDP folders
process_main_folder() {
    folder_name="$1"

    folder_name_cleaned=$(echo "$folder_name" | tr -d ' ' | tr -s '_' '_')
        
    # Extract the Dutch postal code (4 numbers followed by 2 letters), address number, address extension, and room number
    if [[ $folder_name_cleaned =~ ^(.+)_([0-9]{4}[A-Za-z]{2})([0-9]+)(_([a-zA-Z]+))?(\.([0-9a-zA-Z]+))?$ ]]; then
        road_name="${BASH_REMATCH[1]}"
        postal_code="${BASH_REMATCH[2]}"
        address_number="${BASH_REMATCH[3]}"
        address_extension="${BASH_REMATCH[5]}"
        room_number="${BASH_REMATCH[7]}"
            
        # Convert address extension to uppercase using tr
        address_extension=$(echo "$address_extension" | tr '[:lower:]' '[:upper:]')
            
        # Generate the formatted value
        formatted_value=$(generate_formatted_value "$postal_code" "$address_number" "$address_extension" "$room_number")
            
        # Extract the folder name from the path
        folder_name_only=$(basename "$folder_path")
            
        # Store the components in the main CSV file with the extracted folder name and the formatted value
        add_row_to_csv "$folder_name_only,$road_name,$postal_code,$address_number,$address_extension,$room_number,$formatted_value" "$main_csv_file"
    else
        # If the folder name doesn't match the expected format, store it as is in the main CSV file with an empty formatted value
        add_row_to_csv "$folder_name_cleaned,," "$main_csv_file"
    fi
}

# Iterate through folders in the source directory
for folder_path in "$source_dir"/*/; do
    folder_name=$(basename "$folder_path")
    
    # Check if the folder name starts with "MDP_"
    if [[ $folder_name == MDP_* ]]; then
        # Check if the folder name contains "HH" to determine which MDP function to call
        if [[ $folder_name =~ HH ]]; then
            process_mdp_folder_with_handhole "$folder_name"
        else
            process_mdp_folder_without_handhole "$folder_name"
        fi
    else
        # Call the function to process non-MDP folders
        process_main_folder "$folder_name"
    fi
done
