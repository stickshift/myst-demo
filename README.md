# Myst Demo

Demo project using Myst MD to publish site w/ multiple independent articles.

## File Structure

Site is built from multiple independent articles. All of the content for each article is saved in directory articles/{article_id}.

## Build and Test Locally

```sh
# Configure environment
source environment.sh

# Build all artifacts
make site

# Serve artifacts locally
make deploy
```
