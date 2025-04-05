# Commit Message Guidelines

A good commit message should be descriptive and provide context about the changes made. This makes it easier to understand and review the changes in the future.

Here are some guidelines for writing descriptive commit messages:

- Start with a short summary of the changes made in the commit.

- Use imperative mood for the summary, as if you're giving a command. For example, "Add feature" instead of "Added feature".

- Provide additional details in the commit message body, if necessary. This could include the reason for the change, the impact of the change, or any dependencies that were introduced or removed.

- Keep the message within 72 characters per line to ensure that it's easy to read in Git log output.

Examples of good commit messages:

- "Add authentication feature for user login"
- "Fix bug causing application to crash on startup"
- "Update documentation for API endpoints"

Remember, writing descriptive commit messages can save time and frustration in the future, and help others understand the changes made to the codebase.

## Commit Message Types

Here's a more comprehensive list of commit types that you can use:

`feat`: Adding a new feature to the project

```markdown
feat: Add multi-image upload support
```

`fix`: Fixing a bug or issue in the project

```markdown
fix: Fix bug causing application to crash on startup
```

`docs`: Updating documentation in the project

```markdown
docs: Update documentation for API endpoints
```

`style`: Making cosmetic or style changes to the project (such as changing colors or formatting code)

```markdown
style: Update colors and formatting
```

`refactor`: Making code changes that don't affect the behavior of the project, but improve its quality or maintainability

```markdown
refactor: Remove unused code
```

`test`: Adding or modifying tests for the project

```markdown
test: Add tests for new feature
```

`chore`: Making changes to the project that don't fit into any other category, such as updating dependencies or configuring the build system

```markdown
chore: Update dependencies
```

`perf`: Improving performance of the project

```markdown
perf: Improve performance of image processing
```

`security`: Addressing security issues in the project

```markdown
security: Update dependencies to address security issues
```

`merge`: Merging branches in the project

```markdown
merge: Merge branch 'feature/branch-name' into develop
```

`revert`: Reverting a previous commit

```markdown
revert: Revert "Add feature"
```

`build`: Making changes to the build system or dependencies of the project

```markdown
build: Update dependencies
```

`ci`: Making changes to the continuous integration (CI) system for the project

```markdown
ci: Update CI configuration
```

`config`: Making changes to configuration files for the project

```markdown
config: Update configuration files
```

`deploy`: Making changes to the deployment process for the project

```markdown
deploy: Update deployment scripts
```

`init`: Creating or initializing a new repository or project

```markdown
init: Initialize project
```

`move`: Moving files or directories within the project

```markdown
move: Move files to new directory
```

`rename`: Renaming files or directories within the project

```markdown
rename: Rename files
```

`remove`: Removing files or directories from the project

```markdown
remove: Remove files
```

`update`: Updating code, dependencies, or other components of the project

```markdown
update: Update code
```

These are just some examples, and you can create your own custom commit types as well. However, it's important to use them consistently and write clear, descriptive commit messages to make it easy for others to understand the changes you've made.

**Important:** If you are planning to use a custom commit message type other than the ones listed above, make sure to add it to this list so that others can understand it as well. Create a pull request to add it to this file.
