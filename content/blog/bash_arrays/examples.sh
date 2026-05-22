#!/usr/bin/env bash

# =============================================================================
# BASH ARRAYS - COMPREHENSIVE EXAMPLES
# =============================================================================

# -----------------------------------------------------------------------------
# 1. DECLARING ARRAYS
# -----------------------------------------------------------------------------

# Declare and assign inline
array1=("apple" "banana" "cherry")

# Declare empty array first, then assign elements
declare -a array2
array2[0]="first"
array2[1]="second"
array2[2]="third"

# Declare from a string with IFS (Input Field Separator)
string="car, bus, bike"
IFS=', ' read -r -a array3 <<< "${string}"

# Declare from command output — use glob instead of ls to avoid parsing issues
# shellcheck disable=SC2034  # array4 used as demonstration example
mapfile -t array4 < <(printf '%s\n' /tmp/*) || true

# Declare associative array (key-value pairs, bash 4+)
declare -A assoc
assoc["name"]="Krzysztof"
assoc["role"]="DevOps"
assoc["location"]="Poland"

echo "=== 1. DECLARING ARRAYS ==="
echo "Inline array:       ${array1[0]}, ${array1[1]}, ${array1[2]}"
echo "Index assigned:     ${array2[0]}, ${array2[1]}, ${array2[2]}"
echo "From string:        ${array3[0]}, ${array3[1]}, ${array3[2]}"
echo "From command:       ${array4[0]} (${#array4[@]} entries)"
echo "Associative:        name=${assoc["name"]}, role=${assoc["role"]}"
echo ""

# -----------------------------------------------------------------------------
# 2. ACCESSING ELEMENTS
# -----------------------------------------------------------------------------

fruits=("apple" "banana" "cherry" "date" "elderberry")

echo "=== 2. ACCESSING ELEMENTS ==="
echo "Array:              ${fruits[*]}"
echo "First element:      ${fruits[0]}"
echo "Last element:       ${fruits[-1]}"         # negative index from end
echo "Second to last:     ${fruits[-2]}"
echo "All elements:       ${fruits[*]}"
echo "Array length:       ${#fruits[@]}"
echo "Length of element:  ${#fruits[0]}"          # length of "apple" = 5
echo ""

# -----------------------------------------------------------------------------
# 3. SLICING
# -----------------------------------------------------------------------------

echo "=== 3. SLICING ==="
echo "Array:              ${fruits[*]}"
echo "From index 1:       ${fruits[*]:1}"         # all elements from index 1
echo "From index 1, 2:    ${fruits[*]:1:2}"       # 2 elements starting at index 1
echo "Last 2 elements:    ${fruits[*]: -2}"        # last 2 elements (space before - is required)
echo ""

# -----------------------------------------------------------------------------
# 4. ITERATING
# -----------------------------------------------------------------------------

echo "=== 4. ITERATING ==="
echo "Array:              ${fruits[*]}"

# Iterate over values
echo "-- values --"
for element in "${fruits[@]}"
do
    echo "  ${element}"
done

# Iterate over indexes
echo "-- indexes --"
for index in "${!fruits[@]}"
do
    echo "  ${index}: ${fruits[${index}]}"
done

# Iterate over associative array
echo "-- associative array --"
for key in "${!assoc[@]}"
do
    echo "  ${key}: ${assoc[${key}]}"
done

# C-style for loop
echo "-- c-style loop --"
for (( i=0; i<${#fruits[@]}; i++ ))
do
    echo "  ${i}: ${fruits[${i}]}"
done
echo ""

# -----------------------------------------------------------------------------
# 5. MODIFYING ARRAYS
# -----------------------------------------------------------------------------

echo "=== 5. MODIFYING ARRAYS ==="

colors=("red" "green" "blue")
echo "Original:           ${colors[*]}"

# Append single element
colors+=("yellow")
echo "After append:       ${colors[*]}"

# Append multiple elements
colors+=("purple" "orange")
echo "After multi-append: ${colors[*]}"

# Modify element by index
colors[0]="crimson"
echo "After modify [0]:   ${colors[*]}"

# Insert at specific index (shift elements manually)
colors=("${colors[@]:0:2}" "white" "${colors[@]:2}")
echo "After insert at 2:  ${colors[*]}"
echo ""

# -----------------------------------------------------------------------------
# 6. REMOVING ELEMENTS
# -----------------------------------------------------------------------------

echo "=== 6. REMOVING ELEMENTS ==="

animals=("cat" "dog" "bird" "fish" "rabbit")
echo "Original:           ${animals[*]}"

# Remove element by index (leaves a gap)
unset 'animals[2]'
echo "After unset [2]:    ${animals[*]}"
echo "Indexes now:        ${!animals[*]}"          # notice index 2 is missing

# Re-index array after unset (remove gaps)
animals=("${animals[@]}")
echo "After re-index:     ${animals[*]}"
echo "Indexes now:        ${!animals[*]}"

# Remove element by value — use mapfile and grep to avoid word splitting
target="dog"
mapfile -t animals < <(printf '%s\n' "${animals[@]}" | grep -v "^${target}$") || true
echo "After remove '${target}': ${animals[*]}"

# Remove last element
unset 'animals[-1]'
echo "After remove last:  ${animals[*]}"

# Clear entire array
temp_array=("a" "b" "c")
unset temp_array
if [[ ${#temp_array[@]} -eq 0 ]]; then
    echo "After unset array:  empty"
fi
echo ""

# -----------------------------------------------------------------------------
# 7. SEARCHING AND FILTERING
# -----------------------------------------------------------------------------

echo "=== 7. SEARCHING AND FILTERING ==="

services=("nginx" "docker" "mongod" "postgres" "redis")
echo "Array:              ${services[*]}"

# Check if value exists in array
search="docker"
found=false
for item in "${services[@]}"; do
    if [[ "${item}" == "${search}" ]]; then
        found=true
        break
    fi
done
echo "Contains '${search}': ${found}"

# Find index of element
target="mongod"
for i in "${!services[@]}"; do
    if [[ "${services[${i}]}" == "${target}" ]]; then
        echo "Index of '${target}': ${i}"
        break
    fi
done

# Filter array — keep only elements matching a pattern
filtered=()
for item in "${services[@]}"; do
    if [[ "${item}" == *"o"* ]]; then      # elements containing "o"
        filtered+=("${item}")
    fi
done
echo "Filtered (with 'o'): ${filtered[*]}"
echo ""

# -----------------------------------------------------------------------------
# 8. SORTING
# -----------------------------------------------------------------------------

echo "=== 8. SORTING ==="

unsorted=("banana" "apple" "cherry" "date" "elderberry")
echo "Unsorted:           ${unsorted[*]}"

# Sort ascending — use mapfile to avoid word splitting
mapfile -t sorted < <(printf '%s\n' "${unsorted[@]}" | sort) || true
echo "Sorted asc:         ${sorted[*]}"

# Sort descending
mapfile -t sorted_desc < <(printf '%s\n' "${unsorted[@]}" | sort -r) || true
echo "Sorted desc:        ${sorted_desc[*]}"

# Sort numerically
numbers=(10 3 25 7 1 100 42)
echo "Unsorted numeric:   ${numbers[*]}"
mapfile -t sorted_num < <(printf '%s\n' "${numbers[@]}" | sort -n) || true
echo "Sorted numeric:     ${sorted_num[*]}"
echo ""

# -----------------------------------------------------------------------------
# 9. ARRAY OPERATIONS
# -----------------------------------------------------------------------------

echo "=== 9. ARRAY OPERATIONS ==="

arr1=("a" "b" "c")
arr2=("d" "e" "f")
echo "arr1:               ${arr1[*]}"
echo "arr2:               ${arr2[*]}"

# Merge two arrays
merged=("${arr1[@]}" "${arr2[@]}")
echo "Merged:             ${merged[*]}"

# Copy an array
original=("x" "y" "z")
copy=("${original[@]}")
copy[0]="modified"
echo "Original:           ${original[*]}"
echo "Copy (modified):    ${copy[*]}"

# Reverse an array
reversed=()
for (( i=${#original[@]}-1; i>=0; i-- )); do
    reversed+=("${original[${i}]}")
done
echo "Reversed:           ${reversed[*]}"

# Remove duplicates — use mapfile to avoid word splitting
with_dupes=("a" "b" "a" "c" "b" "d")
mapfile -t unique < <(printf '%s\n' "${with_dupes[@]}" | sort -u) || true
echo "Unique:             ${unique[*]}"
echo ""

# -----------------------------------------------------------------------------
# 10. STRING MANIPULATION ON ARRAY ELEMENTS
# -----------------------------------------------------------------------------

echo "=== 10. STRING MANIPULATION ==="

envs=("dev_service" "staging_service" "prod_service")
echo "Array:              ${envs[*]}"

# Uppercase all elements — use mapfile to avoid word splitting
mapfile -t upper < <(printf '%s\n' "${envs[@]}" | tr '[:lower:]' '[:upper:]') || true
echo "Uppercase:          ${upper[*]}"

# Replace substring in all elements
replaced=("${envs[@]/_service/}")
echo "Remove '_service':  ${replaced[*]}"

# Add prefix to all elements
prefixed=("${envs[@]/#/aws_}")
echo "Add prefix 'aws_':  ${prefixed[*]}"

# Add suffix to all elements
suffixed=("${envs[@]/%/_v2}")
echo "Add suffix '_v2':   ${suffixed[*]}"
echo ""

# -----------------------------------------------------------------------------
# 11. PASSING ARRAYS TO FUNCTIONS
# -----------------------------------------------------------------------------

echo "=== 11. PASSING TO FUNCTIONS ==="

print_array() {
    local varname
    varname="${1}"
    local -n arr
    arr="${varname}"              # nameref — reference to the original array
    echo "  Length: ${#arr[@]}"
    for item in "${arr[@]}"; do
        echo "  - ${item}"
    done
}

sum_array() {
    local varname
    varname="${1}"
    local -n nums
    nums="${varname}"
    local total
    total=0
    for n in "${nums[@]}"; do
        total=$(( total + n ))
    done
    echo "  Sum: ${total}"
}

# shellcheck disable=SC2034  # passed by name to print_array
my_array=("terraform" "ansible" "docker")
# shellcheck disable=SC2034  # passed by name to sum_array
my_numbers=(1 2 3 4 5)
echo "my_array:           ${my_array[*]}"
echo "my_numbers:         ${my_numbers[*]}"

echo "String array:"
print_array my_array

echo "Number array:"
sum_array my_numbers
echo ""

# -----------------------------------------------------------------------------
# 12. RETURNING ARRAYS FROM FUNCTIONS
# -----------------------------------------------------------------------------

echo "=== 12. RETURNING FROM FUNCTIONS ==="

get_running_services() {
    local varname
    varname="${1}"
    local -n result
    result="${varname}"           # nameref to store result in caller's variable
    # shellcheck disable=SC2034  # result written via nameref to caller's variable
    result=("nginx" "docker" "sshd")   # simulated — replace with: $(systemctl list-units ...)
}

# shellcheck disable=SC2034  # written to by get_running_services via nameref
declare -a running
get_running_services running
echo "Running services:   ${running[*]}"
echo ""