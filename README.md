# Jekyll Builder for GitHub Pages (Action)

Fast and simple [GitHub Action](https://github.com/features/actions) based on the official [Jekyll Docker](https://github.com/jekyll/docker) `builder` image for building a Jekyll site and optionally deploying that site on [GitHub Pages](https://pages.github.com/).

* **Lightweight for fast builds.** The action's container image clocks in at ~80MB smaller than many comparable others.
* **Minimal configuration.** Smart defaults are automatically pulled from your GitHub account via the [GitHub v3 REST API](https://developer.github.com/v3/).
* **Observable and debug-able**. Clear logs with plenty of hints for what to do when a commit breaks the build. Debug the action itself just by running it with the `DEBUG` environment variable set to `"true"`.
* **Batteries included**. Based on the `jekyll/builder` Docker image, so all your Jekyll dependencies are always there when you need them.
* **Automatic updates**. Reusing the best Jekyll builder means you don't have to update your pipeline manually if you don't want to. If you do want that, specify a version-pinned ref in your workflow for guaranteed stability.
* **Highlighy customizable**. Define custom commands to run before or after your build to smooth over any rough edge cases easily.
* **Schedule ready.** Safe to use in your Continuous Delivery workflows because a lack of changes won't cause build errors. 

> :construction: TODO

# Usage

> :construction: TODO

## Examples

> :construction: TODO

### Deploying to GitHub Pages

By default, when the `secret_gh_pages_api_token` input variable is set, the action will deploy the Jekyll build to GitHub Pages. This input variable must be set to the value of a GitHub API Personal Access Token granted the proper scopes (permissions). [Create such a token at your GitHub account's *Settings &rarr; Developer settings &rarr; Personal access tokens* page](https://github.com/settings/tokens/new?scopes=public_repo,repo_deployment&description=Token%20for%20Deploy%20GitHub%20Pages%20GitHub%20Action).

> :construction: TODO
