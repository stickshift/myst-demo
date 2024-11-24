import click
import yaml
import shutil
from pathlib import Path
from uuid import uuid4

# Constants
github_url = "https://github.com/stickshift/myst-demo"

stickshift_metadata = {
    "github": github_url,
    "license": {
        "content": "CC-BY-SA-3.0",
        "code": "MIT",
    },
    "open_access": True,
    "subject": "tutorial",
    "venue": {
        "title": "Stickshift",
    },
    "authors": [
        {
            "name": "Andrew Young",
            "email": "joven@alum.wpi.edu",
            "github": "stickshift",
        },
    ],
    "toc": [
        {
            "file": "index.md",
        },
    ],
}


@click.command()
@click.argument(
    "article-path",
    type=click.Path(exists=True, path_type=Path),
)
def configure_myst(article_path: Path):
    """Generate myst.yml from article.yml."""
    
    # Validate parameters
    if not article_path.is_dir():
        raise ValueError(f"Article path {article_path} is not a directory")

    article_manifest = article_path / "article.yml"
    myst_manifest = article_path / "myst.yml"

    # Load the article config
    article_config = yaml.safe_load(article_manifest.read_text())

    # Configure myst
    myst_config = {
        "version": 1,
        "project": {
            **stickshift_metadata,
            "id": uuid4().hex,
            "banner": article_config["banner"],
            "title": article_config["title"],
            "subtitle": article_config["subtitle"],
            "abstract": article_config["abstract"],
            "date": article_config["date"],
        },
        "site": {
            "template": "article-theme",
        },
    }

    # Write the MyST config
    with open(myst_manifest, "w") as f:
        yaml.dump(myst_config, f)
    
    click.echo(f"Wrote {myst_manifest}")

if __name__ == "__main__":
    configure_myst()
