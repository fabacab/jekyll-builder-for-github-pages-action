# Jekyll Builder for GitHub Pages (Action)

Fast and simple [GitHub Action](https://github.com/features/actions) based on the official [Jekyll Docker](https://github.com/jekyll/docker) `builder` image for building a Jekyll site and optionally deploying that site on [GitHub Pages](https://pages.github.com/).

* **Lightweight for fast builds.** The action's container image clocks in at ~80MB smaller than many comparable others.
* **Minimal configuration.** Smart defaults are automatically pulled from your GitHub account via the [GitHub v3 REST API](https://developer.github.com/v3/).
* **Observable and debug-able**. Clear logs with plenty of hints for what to do when a commit breaks the build. Debug the action itself just by running it with the `DEBUG` environment variable set to `"true"`.
* **Batteries included**. Based on the official `jekyll/builder` Docker image means dependencies are always there when you need them.
* **Automatic updates**. You don't have to update your pipeline manually if you don't want to. If you do, specify a version-pinned ref in your workflow for guaranteed stability.
* **Highlighy customizable**. Define custom commands to run before or after your build to smooth over any rough edge cases easily.
* **Pipeline-ready.** Safe for Continuous Delivery workflows because only real issues, not no-ops, cause build errors. 

This Action was created to be fast, simple, and versatile. It ships with smart defaults that are augmented at runtime with data pulled from the GitHub API, you can keep your workflow file short and readable instead of spending time setting configuration options just to get the basics done. If you need even more power, simply grant the action more privileges (by adding scopes to [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) used as the `secret_gh_pages_api_token` value), and it will do more of the right things, automatically.

# Usage

In one of your [GitHub Actions workflow files](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/configuring-a-workflow#creating-a-workflow-file), add the following as [a step in a job](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idsteps):

```yaml
- name: Build Jekyll site.
  uses: meitar/jekyll-builder-for-github-pages@v1 # Or whatever "@ref" you want.
```

That's it. The action will use whatever source code is checked out from a previous [`actions/checkout`](https://github.com/actions/checkout) step as the Jekyll source to build. If the build succeeds, the step passes and the job continues with the next step.

For more details, see the [GitHub Actions documentation](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-actions-from-github-marketplace-in-your-workflow). For common usage examples, see [§ Examples](#examples).

## Inputs

You can customize this action by [using input variables](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepswith) that the action recognizes. All possible inputs are well-commented in the action's metadata file ([`action.yaml`](action.yaml)). The most common of these are also documented here.

*All inputs are optional.*

### `gh_pages_publishing_source`

Name of the branch your repository is using as its GitHub Pages publishing source. This is the branch in your GitHub repository to which the action will commit the result of the Jekyll build. By default, this is detected automatically if you have already [configured a GitHub Pages publishing source](https://help.github.com/en/github/working-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#choosing-a-publishing-source) in your repository settings.

For User or Organization repositories, this option is completely ignored because those types of GitHub Pages sites can only ever use their `master` branch as a publishing source. For other repositories, this defaults to the value set in your repository's settings.

### `git_commit_message`

When a commit to your GitHub Pages publishing source branch ([`gh_pages_publishing_source`](#gh-pages-publishing-source)) is made, this input variable defines the message to use. If none is specified, a generic default message will be used.

### `git_committer_email`

The email address to use for the committer when a commit is made to your GitHub Pages publishing source branch. This defaults to the email associated with the GitHub account running the GitHub Actions workflow if the access token passed as the [`secret_gh_pages_api_token`](#secret-gh-pages-api-token) input variable has permission to access that data. If not, it will default to the value of `"{$GITHUB_ACTOR}@users.noreply.github.com"`.

### `git_committer_name`

The name to use for the committer when a commit is made to your GitHub Pages publishing source branch. This defaults to the display name associated with the GitHub account running the GitHub Actions workflow.

### `jekyll_build_opts`

Extra arguments to pass to [the `jekyll build` command](https://jekyllrb.com/docs/usage/). This is particularly useful if your site requires non-default Jekyll build behaviors to be enabled. For example, to publish future-dated posts on your blog:

```yaml
- uses: meitar/jekyll-builder-for-github-pages-action@master
  with:
    jekyll_build_opts: --future
```

### `pre_build_commands`

Set this input variable to a shell command or short inline shell script, which will be executed prior to the build. This is particularly useful for ensuring bleeding-edge build dependencies are up to date that may be missing from the built-in Docker image.

For example, the following configuration will run this action with the absolute latest available `bundle` command by executing `gem install bundler` before the Jekyll build is initiated.

```yaml
- uses: meitar/jekyll-builder-for-github-pages-action@master
  with:
    # Use a newer `bundle` command.
    pre_build_commands: gem install bundler
```

### `post_build_commands`

Exactly the same as [`pre_build_commands`](#pre-build-commands) except these commands run immediately following a (successful) build.

### `secret_gh_pages_api_token`

Set this input variable to the value of a GitHub personal access token. This is required if you'd like to use this action to publish your Jekyll site to GitHub Pages. There is no default value.

You should always set this input variable by using the `secrets` expression context provided by GitHub:

```yaml
- uses: meitar/jekyll-builder-for-github-pages-action@master
  with:
    secret_gh_pages_api_token: ${{ secrets.YOUR_SECRET_VARIABLE }}
```

For more information, see [Creating and using encrypted secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets).

## Outputs

> :construction: TODO

The current version of this action does not produce any outputs. Hopefully, a future version will. :)

## Examples

This section offers some complete workflow examples to show you how to make use of this action.

### Deploying to GitHub Pages

By default, when the `secret_gh_pages_api_token` input variable is set, the action will deploy the Jekyll build to GitHub Pages. This input variable must be set to the value of a GitHub API Personal Access Token granted the proper scopes (permissions). [Create such a token at your GitHub account's *Settings &rarr; Developer settings &rarr; Personal access tokens* page](https://github.com/settings/tokens/new?scopes=public_repo,repo_deployment&description=GitHub%20Pages%20Deployment%20Token).

```yaml
# In your repository's `.github/workflows/publish-to-github-pages.yaml` file.
---
# Name of your GitHub Actions workflow.
name: Publish to GitHub Pages

# Specifies to run this workflow whenever a push is made (commits are
# added) to the branch named `jekyll`.
on:
  push:
    branches:
      # Change this to the branch where you keep your Jekyll code.
      - jekyll

# Define a job named `build-and-publish` in your workflow.
jobs:
  build-and-publish:
    runs-on: ubuntu-latest # This job uses a GitHub-hosted runner.

    steps:
      # Checkout the source from the `jekyll` branch.
      - uses: actions/checkout@v2

      # Invoke this action against the newly checked out source code.
      - uses: meitar/jekyll-builder-for-github-pages-action@master
        with:
          # Provide this action with your repository's `GH_PAGES_TOKEN`
          # "Secret" variable. This should be the value of a personal
          # access token granted, at a minimum, the `public_repo` and
          # the `repo_deployment` scopes needed to deploy to GH Pages.
          secret_gh_pages_api_token: ${{ secrets.GH_PAGES_TOKEN }}
```

Using the above workflow file, anytime someone with the appropriate permissions pushes to the `jekyll` branch in your repository, this action will run. The `build-and-publish` job will `git checkout` the `jekyll` branch source code, which should contain your Jekyll site's source (not your generated HTML). Assuming the secret `GH_PAGES_TOKEN` contains a personal access token granted the sufficient permissions, the action will automatically detect the correct branch to `git commit` and `git push` your generated HTML to.

# Support and Donations

Contributions are &hearts;ily welcomed.

In addition to contributing code, please consider sending some $ my way by [sponsoring me on GitHub](https://github.com/sponsors/meitar/), at least until grocery stores begin offering free food. Donations for this and my other Free Software projects make up the bulk of my income. Thank you!
