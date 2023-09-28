#!/bin/bash

# Set the input CSV file path
csv_file="main_folder_info.csv"
mdp_csv_file="mdp_folder_info.csv"

# Set the input directory containing the original folders
# Change this to the location name, example: SHB-01
input_dir="Input/SHB-01"

# Set the base output directory
# Change this to the location name, example: SHB-01
output_base_dir="Output/SHB-01"

# Function to detect and rename file extensions
detect_and_rename_extensions() {
    input_dir="/path/to/input_directory"

    for file_path in "$input_dir"/*; do
        if [ -f "$file_path" ]; then
            mime_type=$(file -b --mime-type "$file_path")

            if [[ $mime_type == "image/png" ]]; then
                mv "$file_path" "${file_path%.}.${file_path##*.}.png"
                echo "Renamed $file_path to ${file_path%.}.${file_path##*.}.png"
            elif [[ $mime_type == "image/jpeg" ]]; then
                mv "$file_path" "${file_path%.}.${file_path##*.}.jpg"
                echo "Renamed $file_path to ${file_path%.}.${file_path##*.}.jpg"
            else
                echo "Skipping $file_path (unknown mime type: $mime_type)"
            fi
        fi
    done
}

# Check if the CSV file exists
if [ ! -f "$csv_file" ]; then
    echo "CSV file not found: $csv_file"
    exit 1
fi
# Check if the CSV file exists
if [ ! -f "$mdp_csv_file" ]; then
    echo "MDP CSV file not found: $mdp_csv_file"
    exit 1
fi

# Create the base output directory if it doesn't exist
mkdir -p "$output_base_dir"

# Read the CSV file line by line, skipping the header
header_skipped=false
while IFS=, read -r original_dir_name _ _ _ _ _ formatted_value; do
    # Check if the row has valid data
    if [ -n "$original_dir_name" ] && [ "$formatted_value" != "Formatted Value" ]; then
        # Create the output directory path based on the formatted value
        output_dir="$output_base_dir/Klanten/$formatted_value"

        # Create the output directory if it doesn't exist
        mkdir -p "$output_dir"

        # Copy the contents of the source directory to the output directory
        cp -r "$input_dir/$original_dir_name"/* "$output_dir/"

        # Convert uppercase file extensions to lowercase in the output directory
        find "$output_dir" -type f -iname "*.*" -exec sh -c '
            for file do
                lowercase_ext=$(echo "${file##*.}" | tr "[:upper:]" "[:lower:]")
                mv "$file" "${file%.*}.$lowercase_ext"
            done
        ' sh {} +

        # Check if files have no extensions and set an appropriate extension based on MIME type
        find "$output_dir" -type f ! -name "*.*" -exec sh -c '
            for file do
                mime_type=$(file -b --mime-type "$file")
                case "$mime_type" in
                    application/pdf)
                        ext="pdf"
                        ;;
                    image/jpeg)
                        ext="jpg"
                        ;;
                    # Add more MIME type cases here as needed
                    *)
                        ext="unknown"
                        ;;
                esac
                mv "$file" "${file%}.$ext"
            done
        ' sh {} +
    fi

    # Set header_skipped to true after processing the header line
    if [ "$formatted_value" == "Formatted Value" ]; then
        header_skipped=true
    fi
done < "$csv_file"

# Check if the header was not found in the CSV file
if [ "$header_skipped" == "false" ]; then
    echo "Header not found in CSV file."
fi


# Read the CSV mdp file line by line, skipping the header
header_mdp_skipped=false
while IFS=, read -r original_dir_name _ _ _ _ formatted_value; do
    # Check if the row has valid data
    if [ -n "$original_dir_name" ] && [ "$formatted_value" != "Formatted Value" ]; then
        # Create the output directory path based on the formatted value
        output_dir="$output_base_dir/Accesspoints/$formatted_value"

        # Create the output directory if it doesn't exist
        mkdir -p "$output_dir"

        # Copy the contents of the source directory to the output directory
        cp -r "$input_dir/$original_dir_name"/* "$output_dir/"

        # Convert uppercase file extensions to lowercase in the output directory
        find "$output_dir" -type f -iname "*.*" -exec sh -c '
            for file do
                lowercase_ext=$(echo "${file##*.}" | tr "[:upper:]" "[:lower:]")
                mv "$file" "${file%.*}.$lowercase_ext"
            done
        ' sh {} +

        # Check if files have no extensions and set an appropriate extension based on MIME type
        find "$output_dir" -type f ! -name "*.*" -exec sh -c '
            for file do
                mime_type=$(file -b --mime-type "$file")
                case "$mime_type" in
                    image/png)
                        ext="png"
                        ;;
                    image/jpeg)
                        ext="jpg"
                        ;;
                    application/json)
                        ext="exporterror.txt"
                        echo "The input file linked to : $file was an export error. Please remove the source files, or try re-downloading the file"
                        rm "$file"  # Remove files with MIME type application/json
                        ;;
                    # Add more MIME type cases here as needed
                    *)
                        ext="unknown"
                        ;;
                esac
                if [ "$ext" != "exporterror.txt" ]; then
                    mv "$file" "${file%}.$ext"
                fi
            done
        ' sh {} +
    fi

    # Set header_skipped to true after processing the header line
    if [ "$formatted_value" == "Formatted Value" ]; then
        header_mdp_skipped=true
    fi
done < "$mdp_csv_file"

# Check if the header was not found in the CSV file
if [ "$header_mdp_skipped" == "false" ]; then
    echo "Header not found in MDP CSV file."
fi
