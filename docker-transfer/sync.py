from ruamel.yaml import YAML
import re
import sys
import os

yaml = YAML()
yaml.preserve_quotes = True
yaml.indent(mapping=2, sequence=4, offset=2)

# 👇 This line forces `None` to be written as `~`
yaml.representer.add_representer(
    type(None), lambda self, _: self.represent_scalar('tag:yaml.org,2002:null', '~')
)

def parse_release_images_yaml(file_path):
    with open(file_path) as f:
        data = yaml.load(f)
    image_versions = {}
    for key, image_full in data.items():
        match = re.match(r"(.+):([\w.-]+)", image_full)
        if match:
            image_name, tag = match.groups()
            image_versions[image_name] = tag
    return image_versions

def update_values_yaml(values_path, image_versions):
    if not os.path.exists(values_path):
        print(f"File not found: {values_path}")
        return

    with open(values_path) as f:
        values = yaml.load(f)

    image_block = values.get("image")
    if not isinstance(image_block, dict):
        print("'image' block not found or invalid.")
        return

    repo = image_block.get("repository")
    if repo in image_versions:
        print(f"Updating tag for {repo} → {image_versions[repo]}")
        old_tag = image_block.get("tag", "<missing>")
        new_tag = image_versions[repo]
        if old_tag != new_tag:
            print(f"Updating {repo} tag: {old_tag} → {new_tag}")
        else:
            print(f"No change needed for {repo}: already {new_tag}")

        image_block["tag"] = image_versions[repo]
    else:
        print(f"No matching tag found in releases.yaml for {repo}")

    with open(values_path, "w") as f:
        yaml.dump(values, f)

if __name__ == "__main__":
    releases_file = sys.argv[1] if len(sys.argv) > 1 else "releases.yaml"
    values_file = sys.argv[2] if len(sys.argv) > 2 else "values.yaml"

    image_versions = parse_release_images_yaml(releases_file)
    update_values_yaml(values_file, image_versions)
