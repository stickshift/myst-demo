import click
import yaml
import shutil
from pathlib import Path
from uuid import uuid4


@click.command()
@click.argument(
    "article-path",
    type=click.Path(exists=True, path_type=Path),
)
def configure_article(article_path: Path):
    """Configure a MyST article from an article.yml file."""
    
    article_manifest = article_path / "article.yml"
    myst_manifest = article_path / "myst.yml"

    # Load the article config
    article_config = yaml.safe_load(article_manifest.read_text())

    # Configure myst
    myst_config = {
        "version": 1,
        "project": {
            "id": uuid4().hex,
            "license": {
                "content": "CC-BY-SA-3.0",
                "code": "MIT",
            },
            "github": "https://github.com/stickshift/myst-demo",
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
            "banner": article_config["banner"],
            "title": article_config["title"],
            "subtitle": article_config["subtitle"],
            "abstract": article_config["abstract"],
            "date": article_config["date"],
            "toc": [
                {
                    "file": "index.md",
                },
            ],
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
    configure_article()
