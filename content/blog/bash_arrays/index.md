+++
title = "Bash Arrays — Comprehensive Guide"
description = "A comprehensive guide to working with arrays in Bash — declaring, accessing, iterating, modifying, sorting, filtering, and passing arrays to functions"
date = "2026-05-22T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["Bash"]
tags = ["bash", "shell", "scripting", "devops"]
+++

Arrays are one of the most useful data structures in Bash. They allow storing multiple values in a single variable, iterating over lists, and building more structured scripts. This post covers the most common array operations with practical examples — all verified against shellcheck.

[Download example script](examples.sh)

## Declaring Arrays

There are several ways to declare arrays in Bash.

**Inline declaration:**

```bash
array=("apple" "banana" "cherry")
```

**Declare empty first, then assign by index:**

```bash
declare -a array
array[0]="first"
array[1]="second"
array[2]="third"
```

**From a string using IFS (Input Field Separator):**

```bash
string="car, bus, bike"
IFS=', ' read -r -a array <<< "${string}"
```

The `IFS=', '` sets both comma and space as separators. This is a common pattern when splitting CSV-like strings.

**From command output — use `mapfile` to avoid word splitting issues with filenames containing spaces:**

```bash
mapfile -t array < <(printf '%s\n' /tmp/*)
```

**Associative array (key-value pairs, bash 4+):**

```bash
declare -A assoc
assoc["name"]="Krzysztof"
assoc["role"]="DevOps"
assoc["location"]="Poland"
```

## Accessing Elements

```bash
fruits=("apple" "banana" "cherry" "date" "elderberry")

echo "${fruits[0]}"       # first element: apple
echo "${fruits[-1]}"      # last element: elderberry
echo "${fruits[-2]}"      # second to last: date
echo "${fruits[*]}"       # all elements
echo "${#fruits[@]}"      # array length: 5
echo "${#fruits[0]}"      # length of first element: 5
```

Note the difference between `[@]` and `[*]`:
- `"${array[@]}"` — expands each element as a separate word (use when iterating)
- `"${array[*]}"` — expands all elements as a single word joined by IFS (use in echo)

## Slicing

```bash
echo "${fruits[*]:1}"     # all elements from index 1
echo "${fruits[*]:1:2}"   # 2 elements starting at index 1
echo "${fruits[*]: -2}"   # last 2 elements (space before - is required)
```

The space before `-2` in the last example is mandatory — without it, Bash interprets `:-` as the default value operator.

## Iterating

**Over values:**

```bash
for element in "${fruits[@]}"; do
    echo "${element}"
done
```

**Over indexes:**

```bash
for index in "${!fruits[@]}"; do
    echo "${index}: ${fruits[${index}]}"
done
```

**Over an associative array:**

```bash
for key in "${!assoc[@]}"; do
    echo "${key}: ${assoc[${key}]}"
done
```

**C-style loop:**

```bash
for (( i=0; i<${#fruits[@]}; i++ )); do
    echo "${i}: ${fruits[${i}]}"
done
```

## Modifying Arrays

```bash
colors=("red" "green" "blue")

# Append single element
colors+=("yellow")

# Append multiple elements
colors+=("purple" "orange")

# Modify element by index
colors[0]="crimson"

# Insert at specific index
colors=("${colors[@]:0:2}" "white" "${colors[@]:2}")
```

## Removing Elements

**Remove by index** — leaves a gap in indexes:

```bash
unset 'animals[2]'
```

**Re-index after unset** — removes the gaps:

```bash
animals=("${animals[@]}")
```

**Remove by value** — use `mapfile` and `grep` to avoid word splitting:

```bash
target="dog"
mapfile -t animals < <(printf '%s\n' "${animals[@]}" | grep -v "^${target}$") || true
```

**Remove last element:**

```bash
unset 'animals[-1]'
```

**Clear entire array:**

```bash
unset animals
if [[ ${#animals[@]} -eq 0 ]]; then
    echo "empty"
fi
```

Note: checking `${var[@]:-default}` doesn't work reliably on arrays — always check the length with `${#array[@]}`.

## Searching and Filtering

**Check if value exists:**

```bash
search="docker"
found=false
for item in "${services[@]}"; do
    if [[ "${item}" == "${search}" ]]; then
        found=true
        break
    fi
done
```

**Find index of element:**

```bash
target="mongod"
for i in "${!services[@]}"; do
    if [[ "${services[${i}]}" == "${target}" ]]; then
        echo "Index: ${i}"
        break
    fi
done
```

**Filter — keep only matching elements:**

```bash
filtered=()
for item in "${services[@]}"; do
    if [[ "${item}" == *"o"* ]]; then
        filtered+=("${item}")
    fi
done
```

## Sorting

Use `mapfile` with `sort` — avoids word splitting issues:

```bash
# Sort ascending
mapfile -t sorted < <(printf '%s\n' "${unsorted[@]}" | sort) || true

# Sort descending
mapfile -t sorted_desc < <(printf '%s\n' "${unsorted[@]}" | sort -r) || true

# Sort numerically
mapfile -t sorted_num < <(printf '%s\n' "${numbers[@]}" | sort -n) || true
```

The `|| true` is needed because `mapfile` reading from a process substitution can return a non-zero exit code when the pipeline finishes, which would cause the script to exit if `set -e` is enabled.

## Array Operations

**Merge two arrays:**

```bash
merged=("${arr1[@]}" "${arr2[@]}")
```

**Copy an array** (true copy, not a reference):

```bash
copy=("${original[@]}")
```

**Reverse:**

```bash
reversed=()
for (( i=${#original[@]}-1; i>=0; i-- )); do
    reversed+=("${original[${i}]}")
done
```

**Remove duplicates:**

```bash
mapfile -t unique < <(printf '%s\n' "${with_dupes[@]}" | sort -u) || true
```

## String Manipulation on Elements

**Uppercase all elements:**

```bash
mapfile -t upper < <(printf '%s\n' "${envs[@]}" | tr '[:lower:]' '[:upper:]') || true
```

**Replace substring in all elements:**

```bash
replaced=("${envs[@]/_service/}")
```

**Add prefix to all elements:**

```bash
prefixed=("${envs[@]/#/aws_}")
```

**Add suffix to all elements:**

```bash
suffixed=("${envs[@]/%/_v2}")
```

The `/#/` and `/%/` patterns are parameter expansion operators — `#` matches the beginning of each element, `%` matches the end.

## Passing Arrays to Functions

Bash doesn't support passing arrays directly to functions. The cleanest approach is to pass the array name as a string and use a nameref (`local -n`) inside the function to reference the original array:

```bash
print_array() {
    local varname
    varname="${1}"
    local -n arr
    arr="${varname}"
    echo "Length: ${#arr[@]}"
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
    echo "Sum: ${total}"
}

my_array=("terraform" "ansible" "docker")
my_numbers=(1 2 3 4 5)

print_array my_array
sum_array my_numbers
```

Note that `local` and `local -n` declarations are separated from their assignments to avoid shellcheck warning SC2034 about masked return values.

## Returning Arrays from Functions

The same nameref pattern works for returning arrays — the function writes into the caller's variable via the nameref:

```bash
get_running_services() {
    local varname
    varname="${1}"
    local -n result
    result="${varname}"
    result=("nginx" "docker" "sshd")
}

declare -a running
get_running_services running
echo "${running[*]}"
```

## ShellCheck Notes

A few patterns that keep shellcheck happy:

- Use `mapfile -t` instead of `array=($(cmd))` — avoids SC2207 word splitting warning
- Always quote array expansions: `"${array[@]}"` not `${array[@]}`
- Use `${array[*]}` in `echo` and `${array[@]}` when iterating
- Separate `local var` from `var=value` — avoids SC2155 masked return value warning
- Use `unset 'array[index]'` with quotes — avoids SC2184 glob expansion warning
- Check array emptiness with `${#array[@]} -eq 0` not `${array[@]:-default}`