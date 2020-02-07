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

# Do the thing.
function main {
    cd $GITHUB_WORKSPACE

    # Execute pre-build commands specified by the user.
    [ ! -z "$INPUT_PRE_BUILD_COMMANDS" ] && eval "$INPUT_PRE_BUILD_COMMANDS"

    # Make sure we have permission.
    [ "jekyll" != $(stat -c '%U' .) ] && chown jekyll .

    # Execute the original image's own entrypoint.
    /usr/jekyll/bin/entrypoint jekyll build -d "$JEKYLL_DATA_DIR" "$INPUT_JEKYLL_BUILD_OPTS"

    # Without a GitHub API token, we cannot deploy to GitHub Pages.
    if [ -z "$gh_api_token" ]; then
        return 0
    fi

    # Get the actual build directory.
    local -r input_dir=$(parseBuildDir "$INPUT_JEKYLL_BUILD_OPTS")
    local -r build_dir=${input_dir:-$JEKYLL_DATA_DIR}

    # Set up Git remote and committer identity.
    git config remote.origin.url "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    local github_actor_email=$(callGitHubAPI user | jq --raw-output '.email')
    [ "null" = $github_actor_email ] && unset github_actor_email
    git config user.name "$(callGitHubAPI user | jq --raw-output '.name')"
    git config user.email "${github_actor_email:-$GITHUB_ACTOR@users.noreply.github.com}"

    git fetch
    git checkout -B "$gh_pages_publishing_source" origin/"$gh_pages_publishing_source"
    mv -f .git "$build_dir"

    cd "$build_dir"
    git add -A
    git commit -m "${INPUT_GIT_COMMIT_MESSAGE:-Auto-deployed via GitHub Actions.}"
    git push --force origin "$gh_pages_publishing_source"
    cd -

    callGitHubAPI -X POST repos pages/builds
}

main "$@"
