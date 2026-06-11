#!/usr/bin/env bash

CONFIG="$HOME/.config/hypr/config/monitor_profiles.lua"

# =====================================
# CURRENT MONITORS
# =====================================

declare -A current

while IFS= read -r desc; do
    current["$desc"]=1
done < <(
    hyprctl monitors -j | jq -r '.[].description'
)

echo "============================"
echo "CURRENT MONITORS"
echo "============================"

for mon in "${!current[@]}"; do
    echo "-> $mon"
done

echo
echo "============================"
echo "PROFILE MATCHING"
echo "============================"

matched_profile=""

check_profile() {
    local profile_name="$1"
    shift

    local profile_monitors=("$@")

    echo
    echo "PROFILE: $profile_name"

    for mon in "${profile_monitors[@]}"; do
        echo "-> $mon"
    done

    local match=true

    if [[ ${#profile_monitors[@]} -ne ${#current[@]} ]]; then
        match=false
    fi

    if $match; then
        for mon in "${profile_monitors[@]}"; do
            if [[ -z "${current[$mon]}" ]]; then
                match=false
                break
            fi
        done
    fi

    echo "MATCH: $match"

    if $match; then
        matched_profile="$profile_name"
    fi
}

current_profile=""
profile_monitors=()

while IFS='|' read -r type value; do

    if [[ "$type" == "PROFILE" ]]; then

        if [[ -n "$current_profile" ]]; then
            check_profile "$current_profile" "${profile_monitors[@]}"
        fi

        current_profile="$value"
        profile_monitors=()

    elif [[ "$type" == "MONITOR" ]]; then
        profile_monitors+=("$value")
    fi

done < <(
    awk '
    {
        if($2 == "=" && $3 == "{" && $1 != "monitors")
        {
            print "PROFILE|" $1
        }

        if($1 == "desc" && $2 == "=")
        {
            desc=""

            for(i=3;i<=NF;i++)
            {
                desc=desc" "$i
            }

            print "MONITOR|" substr(desc,3,length(desc)-4)
        }
    }
    ' "$CONFIG"
)

# ostatni profil
if [[ -n "$current_profile" ]]; then
    check_profile "$current_profile" "${profile_monitors[@]}"
fi

echo
echo "============================"
echo "RESULT"
echo "============================"

if [[ -n "$matched_profile" ]]; then
    echo "MATCHED PROFILE: $matched_profile"
else
    echo "NO MATCH"
fi


generate_profile_block() {
    local name="$1"

    hyprctl monitors -j | jq -r --arg name "$name" '
        "    " + $name + " = {\n" +
        "        primary = \"" + (.[0].description // .[0].name) + "\",\n" +
        "        monitors = {\n" +
        (
            map(
                "            {\n" +
                "                desc = \"" + (.description // .name) + "\",\n" +
                "                mode = \"" +
                    (.width|tostring) + "x" +
                    (.height|tostring) + "@" +
                    (.refreshRate|floor|tostring) +
                "\",\n" +
                "                position = \"" +
                    (.x|tostring) + "x" +
                    (.y|tostring) +
                "\",\n" +
                "                scale = " + (.scale|tostring) +
                (if .disabled then ",\n                disabled = true" else "" end) +
                "\n            }"
            ) | join(",\n")
        ) +
        "\n        }\n    }"
    '
}

update_profile_in_file() {
    local file="$1"
    local profile="$2"
    local new_block="$3"

    tmp=$(mktemp)

    awk -v profile="$profile" -v replacement="$new_block" '
    BEGIN {
        in_target = 0
        depth = 0
    }

    {
        # znalezienie startu profilu
        if (!in_target &&
            $1 == profile &&
            $2 == "=" &&
            $3 == "{")
        {
            print replacement
            in_target = 1
            depth = 1
            next
        }

        if (in_target)
        {
            depth += gsub(/\{/, "{")
            depth -= gsub(/\}/, "}")

            if (depth == 0)
                in_target = 0

            next
        }

        print
    }
    ' "$file" > "$tmp"

    mv "$tmp" "$file"
}

append_profile_to_file() {
    local file="$1"
    local new_block="$2"

    tmp=$(mktemp)

    awk -v block="$new_block" '
    BEGIN {
        inserted = 0
    }

    # wykryj return profiles i wstaw PRZED
    /return[[:space:]]+profiles/ {
        print block
        print ""
        inserted = 1
    }

    { print }

    END {
        if (!inserted) {
            print "\n" block
        }
    }
    ' "$file" > "$tmp"

    mv "$tmp" "$file"
}

if [[ -n "$matched_profile" ]]; then
    echo
    echo "============================"
    echo "UPDATING PROFILE"
    echo "============================"

    echo "Updating: $matched_profile"

    NEW_BLOCK=$(generate_profile_block "$matched_profile")
    update_profile_in_file "$CONFIG" "$matched_profile" "$NEW_BLOCK"

    echo "DONE (updated existing profile)"

else
    echo
    echo "============================"
    echo "CREATING NEW PROFILE"
    echo "============================"

    NEW_BLOCK=$(generate_profile_block "auto")

    append_profile_to_file "$CONFIG" "$NEW_BLOCK"

    echo "DONE (added auto profile)"
fi
