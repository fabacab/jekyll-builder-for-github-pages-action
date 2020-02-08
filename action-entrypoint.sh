#!/bin/bash -
[ "true" = "$DEBUG" ] && set -x
set -e

# Simulate GitHub Actions environment if not invoked there.
if [ "true" != "$GITHUB_ACTIONS" ]; then
    source /usr/local/lib/github-action/environment.sh
    mkdir -p "$GITHUB_HOME"
    mkdir -p "$GITHUB_WORKSPACE"
    git clone --depth 1 --no-single-branch --branch "$GITHUB_REF" https://github.com/$GITHUB_REPOSITORY.git $GITHUB_WORKSPACE
fi

# Get library functions.
source /usr/local/lib/github-action/functions.sh

# Initialize constants.
readonly gh_api_token="$INPUT_SECRET_GH_PAGES_API_TOKEN"
[ ! -z "$gh_api_token" ] && readonly gh_pages_publishing_source=$(getGitHubPagesPublishingSource)

# Prepares the build directory's local Git repository.
#
# Global: $gh_api_token
# Global: $GITHUB_REPOSITORY
# Global: $GITHUB_ACTOR
# Global: $gh_pages_publishing_source
# Global: $INPUT_JEKYLL_BUILD_OPTS
# Global: $JEKYLL_DATA_DIR
# GLobal: $INPUT_GIT_COMMIT_MESSAGE
#
# Uses: callGitHubAPI
function setup_build_repo {
    # Set up Git committer identity and remote.
    local -r user_data_path=$(mktemp -t user_data.XXXXXX)
    callGitHubAPI -r user -- -u "${GITHUB_ACTOR}:${gh_api_token}" > "$user_data_path"

    local github_actor_email=$(jq --raw-output '.email' "$user_data_path")
    [ "null" = "$github_actor_email" ] && unset github_actor_email
    git config user.name "$(jq --raw-output '.name' "$user_data_path")"
    git config user.email "${github_actor_email:-$GITHUB_ACTOR@users.noreply.github.com}"
    git config remote.origin.url "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

    # Update local repo with the necessary branch's (shallow) history.
    git fetch
    git checkout -B "$gh_pages_publishing_source" origin/"$gh_pages_publishing_source"

    # Move the Git repository there.
    mv -f .git "$(getBuildDir)"
}

# Do the thing.
function main {
    cd $GITHUB_WORKSPACE

    # Execute pre-build commands specified by the user.
    [ ! -z "$INPUT_PRE_BUILD_COMMANDS" ] && eval "$INPUT_PRE_BUILD_COMMANDS"

    # Make sure we have permission. Needed to create `.jekyll-cache/`.
    [ "jekyll" != $(stat -c '%U' .) ] && chown jekyll .

    # Check for GitHub Pages requirements. If the `github-pages` Gem
    # is used, some additional environment variables need to be set.
    [ -r "Gemfile.lock" ] && \
        sed -ne '/^DEPENDENCIES$/,/^$/ p' "Gemfile.lock" \
            | grep -q "github-pages"
    if [ 0 -eq $? ]; then
        export JEKYLL_GITHUB_TOKEN="$gh_api_token"
        export PAGES_REPO_NWO="${PAGES_REPO_NWO:-$GITHUB_REPOSITORY}"
    fi

    # Execute the original image's own entrypoint.
    /usr/jekyll/bin/entrypoint jekyll build -d "$JEKYLL_DATA_DIR" "$INPUT_JEKYLL_BUILD_OPTS"

    # Execute post-build commands specified by the user.
    [ ! -z "$INPUT_POST_BUILD_COMMANDS" ] && eval "$INPUT_POST_BUILD_COMMANDS"

    setup_build_repo

    # Commit any changes back to the publishing source branch.
    cd "$(getBuildDir)"
    git add -A
    git commit -m "${INPUT_GIT_COMMIT_MESSAGE:-Auto-deployed via GitHub Actions.}" \
        && git push --force origin "$gh_pages_publishing_source"
    cd -

    # Without a user-provided GitHub API token, we cannot deploy to GitHub Pages.
    if [ -n "$gh_api_token" ]; then
        callGitHubAPI -r repos -e pages/builds -- -X POST -u "${GITHUB_ACTOR}:${gh_api_token}"
    fi
}

main "$@"
