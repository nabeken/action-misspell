#!/bin/bash

echo "The upstream now includes the fix for the issue that this fork fixed." >&2
exit 1

# workaround for https://github.blog/2022-04-12-git-security-vulnerability-announced/
# I believe Github should address this.
git config --global --add safe.directory /github/workspace

cd "${GITHUB_WORKSPACE}" || exit 1

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

paths=()
while read -r pattern; do
    [[ -n ${pattern} ]] && paths+=("${pattern}")
done <<< "${INPUT_PATH:-.}"

names=()
if [[ "${INPUT_PATTERN:-*}" != '*' ]]; then
    while read -r pattern; do
        [[ -n ${pattern} ]] && names+=(-o -name "${pattern}")
    done <<< "${INPUT_PATTERN}"
    (( ${#names[@]} )) && { names[0]='('; names+=(')'); }
fi

excludes=()
while read -r pattern; do
    [[ -n ${pattern} ]] && excludes+=(-not -path "${pattern}")
done <<< "${INPUT_EXCLUDE:-}"

find "${paths[@]}" "${excludes[@]}" -type f "${names[@]}" -print0 \
    | xargs -0 misspell -locale="${INPUT_LOCALE}" -i "${INPUT_IGNORE}" \
    | reviewdog -efm="%f:%l:%c: %m" \
        -filter-mode="${INPUT_FILTER_MODE:-added}" \
        -name="misspell" \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -level="${INPUT_LEVEL}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"
exit_code=$?

exit $exit_code
