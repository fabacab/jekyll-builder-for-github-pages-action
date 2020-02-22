# Jekyll Builder for GitHub Pages (Action)

Fast and simple [GitHub Action](https://github.com/features/actions) based on the official [Jekyll Docker](https://github.com/jekyll/docker) `builder` image for building a Jekyll site and optionally deploying that site on [GitHub Pages](https://pages.github.com/).

* **Lightweight for fast builds.** The action's container image weighs in at ~80MB smaller than many comparable others.
* **Minimal configuration.** Smart defaults are automatically pulled from your GitHub account via the [GitHub v3 REST API](https://developer.github.com/v3/).
* **Observable and debug-able**. Clear logs with plenty of hints for what to do when a commit breaks the build. Debug the action itself just by running it with the `DEBUG` environment variable set to `"true"`.
* **Batteries included**. Based on the official `jekyll/builder` Docker image so dependencies are always there when you need them.
* **Automatic updates**. Never update your pipeline manually if you don't want to. If you do, specify a version-pinned ref in your workflow for guaranteed stability.
* **Highlighy customizable**. Run custom commands before or after your build to easily smooth over any edge cases.
* **Pipeline-ready.** Safe for Continuous Delivery workflows because only real issues, not no-ops, cause build errors. 

This Action was created to be fast, simple, and versatile. It ships with smart defaults that are augmented at runtime with data pulled from the GitHub API, so you can keep your workflow file short and readable instead of spending time setting configuration inputs just to get the basics done. Use all the feautures of the upstream `jekyll/builder` Docker image and, if you need even more power, granting the action more privileges (by adding scopes to a [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) used as the `secret_gh_pages_api_token` input variable) will make it do more of the right things, automatically.

# Usage

In one of your [GitHub Actions workflow files](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/configuring-a-workflow#creating-a-workflow-file), add the following as [a step in a job](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idsteps):

```yaml
- name: Build Jekyll site.
  uses: meitar/jekyll-builder-for-github-pages-action@v1 # Or whatever "@ref" you want.
```

That's it. The action will use whatever source code is checked out from a previous [`actions/checkout`](https://github.com/actions/checkout) step as the Jekyll source to build. If the build succeeds, the step passes and the job continues with the next step.

For more details, see the [GitHub Actions documentation](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-actions-from-github-marketplace-in-your-workflow). For more common use cases, notably deploying to GitHub Pages, see [§ Examples](#examples).

## Inputs

You can customize this action by [using input variables](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepswith).  Moreover,  *all inputs are optional*, so the action will still build your Jekyll site without any additional configuration. To enable deployments to GitHub Pages and other advanced features, some inputs are required as described below.

For additional details, inputs are well-commented in [the action's metadata file (`action.yaml`)](action.yaml).

### `gh_pages_publishing_source`

Name of the branch your repository is using as its GitHub Pages publishing source. This is the branch in your GitHub repository to which the action will commit the result of the Jekyll build.

By default, this is detected automatically if you have already [configured a GitHub Pages publishing source](https://help.github.com/en/github/working-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#choosing-a-publishing-source) in your repository settings and provided a [`secret_gh_pages_api_token`](#secret_gh_pages_api_token) input variable with appropriate permissions.

For [User or Organization repositories](https://help.github.com/en/github/working-with-github-pages/about-github-pages#types-of-github-pages-sites), this option is completely ignored because those types of GitHub Pages sites can only ever use their `master` branch as a publishing source. For other repositories, this defaults to the value set in your repository's settings.

To deploy on GitHub Pages, you *must* first enable GitHub Pages from your repository's settings screen and choose a GitHub Pages publishing source branch before using this action.

### `git_commit_message`

When a commit to your GitHub Pages publishing source branch ([`gh_pages_publishing_source`](#gh_pages_publishing_source)) is made, this input variable defines the message to use. If none is specified, a generic default message will be used.

### `git_committer_email`

The email address to use for the committer when a commit is made to your GitHub Pages publishing source branch. This defaults to the email associated with the GitHub account running the GitHub Actions workflow if the access token passed as the [`secret_gh_pages_api_token`](#secret_gh_pages_api_token) input variable has permission to access that data. If not, it will default to `"${GITHUB_ACTOR}@users.noreply.github.com"`.

### `git_committer_name`

The name to use for the committer when a commit is made to your GitHub Pages publishing source branch. This defaults to the display name associated with the GitHub account running the GitHub Actions workflow.

### `jekyll_build_opts`

Extra arguments to pass to [the `jekyll build` command](https://jekyllrb.com/docs/usage/). This is particularly useful if your site requires non-default Jekyll build behaviors to be enabled. For example, to publish future-dated posts on your blog:

```yaml
- uses: meitar/jekyll-builder-for-github-pages-action@master
  with:
    jekyll_build_opts: --future
```

See the output of `jekyll build --help` for more options.

### `pre_build_commands`

Set this input variable to a shell command or short inline shell script, which will be executed prior to the build. This is particularly useful for ensuring bleeding-edge build dependencies that may be missing from the upstream Docker image are installed or up to date.

For example, the following configuration will run this action with the absolute latest version of the `bundle` command by executing `gem install bundler` before the Jekyll build is initiated.

```yaml
- uses: meitar/jekyll-builder-for-github-pages-action@master
  with:
    # Use a newer `bundle` command.
    pre_build_commands: gem install bundler
```

A more complex script can be passed as a multi-line string using a [YAML literal block scalar](https://yaml.org/spec/current.html#id2540046):

```yaml
- uses: meitar/jekyll-builder-for-github-pages-action@master
  with:
    pre_build_commands: |
      echo "Packaged bundler version: $(bundle --version)"
      echo "Updating bundler..."
      gem install bundler
```

### `post_build_commands`

Exactly the same as [`pre_build_commands`](#pre_build_commands) except these commands run immediately following a (successful) build. Jekyll build failures will terminate execution of the action before these commands have a chance to run.

### `secret_gh_pages_api_token`

Set this input variable to the value of a [GitHub personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line). This input variable is **required if you'd like to use this action to publish your Jekyll site to GitHub Pages.** There is no default value.

You should always set this input variable by using the `secrets` expression context provided by GitHub Actions runners:

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

By default, when the `secret_gh_pages_api_token` input variable is set, the action will deploy the Jekyll build to the GitHub Pages publishing source branch configured in your repository's GitHub Pages Settings section. This means you must first [configure a GitHub Pages publishing source](https://help.github.com/en/github/working-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#choosing-a-publishing-source) before using this action to deploy a Jekyll site on GitHub Pages.

This input variable must be set to the value of a GitHub API personal access token granted the proper scopes (permissions). [Create such a token at your GitHub account's *Settings &rarr; Developer settings &rarr; Personal access tokens* page](https://github.com/settings/tokens/new?scopes=public_repo,repo_deployment&description=GitHub%20Pages%20Deployment%20Token). Then navigate to your repository's Settings &rarr; Secrets screen and add a new secret whose value is exactly the same as the personal access token you created moments earlier. In the example configuration below, we assume you have created a repository secret named `GH_PAGES_TOKEN`.

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

#### Automatically rebuilding a GitHub Pages site

You can schedule your workflow to run this action in order to keep your (otherwise static) GitHub Pages site content fresh This is particularly useful if your Jekyll templates show different content based on the date or time of the build, such as featuring your organization's next calendar event on the site's home page. Enable scheduled builds by adding a `schedule` key in the `on` dictionary from the above example:

```yaml
on:
  # Automatically execute this workflow on a schedule.
  schedule:
    # POSIX-compatible cron syntax is supported.
    - cron:  '0 */12 * * *' # Rebuild twice a day (every twelve hours on the hour).

  # Also run this workflow whenever pushes are made to these branches, as before.
  push:
    branches:
      # Change this to the branch where you keep your Jekyll code.
      - jekyll
```

See [Events that trigger workflows § Scheduled events: `schedule`](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/events-that-trigger-workflows#scheduled-events-schedule) for more information.

# Support and Donations

Contributions are &hearts;ily welcomed.

In addition to contributing code, please consider sending some $ my way by [sponsoring me on GitHub](https://github.com/sponsors/meitar/), at least until grocery stores begin offering free food. Donations for this and my other Free Software projects make up the bulk of my income. Thank you!
