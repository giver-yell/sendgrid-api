#!/bin/bash

API_KEY="$1"
TEMPLATE_ID1="$2"
TEMPLATE_ID2="$3"

if [[ -z $API_KEY || -z $TEMPLATE_ID1 || -z $TEMPLATE_ID2 ]]; then
    echo "Missing arguments."
    exit 1
fi

get_template_html_content() {
    local template_id=$1
    curl -s -X GET "https://api.sendgrid.com/v3/templates/${template_id}" -H "Authorization: Bearer ${API_KEY}" | jq -r '.versions[0].html_content'
}

get_template_subject() {
    local template_id=$1
    curl -s -X GET "https://api.sendgrid.com/v3/templates/${template_id}" -H "Authorization: Bearer ${API_KEY}" | jq -r '.versions[0].subject'
}

# Update the version of TEMPLATE_ID2 with the content of TEMPLATE_ID1.
update_template_version() {
    local target_template_id=$1
    local target_version_id=$2
    local new_html_content=$3
    local new_subject=$4

    curl -s -X PATCH "https://api.sendgrid.com/v3/templates/${target_template_id}/versions/${target_version_id}" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"html_content\": \"$new_html_content\",
            \"subject\": \"$new_subject\"
        }"
}

template1_html_content=$(get_template_html_content $TEMPLATE_ID1)
template2_html_content=$(get_template_html_content $TEMPLATE_ID2)
template1_subject=$(get_template_subject $TEMPLATE_ID1)
template2_subject=$(get_template_subject $TEMPLATE_ID2)
NEW_VERSION_ID2="new_template_version"

# Save the contents of each template to temporary files.
echo "$template1_html_content" > /tmp/template1_html.txt
echo "$template2_html_content" > /tmp/template2_html.txt
echo "$template1_subject" > /tmp/template1_subject.txt
echo "$template2_subject" > /tmp/template2_subject.txt

# Check differences and ask for user confirmation.
differences_found=false

if ! diff -u /tmp/template1_html.txt /tmp/template2_html.txt > /tmp/diff_output_html.txt; then
    echo "Differences found in HTML content:"
    cat /tmp/diff_output_html.txt
    echo ""
    differences_found=true
fi

if ! diff -u /tmp/template1_subject.txt /tmp/template2_subject.txt > /tmp/diff_output_subject.txt; then
    echo "Differences found in Subject:"
    cat /tmp/diff_output_subject.txt
    echo ""
    differences_found=true
fi

if $differences_found; then
    read -p "Do you want to overwrite the content of TEMPLATE_ID2 with TEMPLATE_ID1? (y/N): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        update_template_version $TEMPLATE_ID2 $NEW_VERSION_ID2 "$template1_html_content" "$template1_subject"
        echo "TEMPLATE_ID2 updated successfully!"
    else
        echo "No changes were made."
    fi
else
    echo "No differences found between the templates."
fi

# Remove temporary files.
rm /tmp/template1_html.txt /tmp/template2_html.txt /tmp/template1_subject.txt /tmp/template2_subject.txt /tmp/diff_output_html.txt /tmp/diff_output_subject.txt
