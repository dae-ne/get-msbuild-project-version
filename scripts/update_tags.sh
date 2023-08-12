#!/bin/bash

echo "Fetching tags..."

git tag | xargs git tag -d > /dev/null
git pull --tags --quiet

tag=`git tag --sort=-v:refname | head -n 1`

if [[ -z $tag ]]; then
  echo
  echo "No tags found. Using v0.0.0"
  tag="v0.0.0"
fi

if [[ ! $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo
  echo "Invalid version format: $tag"
  exit 1
fi

echo "Current version: $tag"
echo

tag_components=($(echo "${tag#v}" | tr '.' ' '))

major="${tag_components[0]}"
minor="${tag_components[1]}"
patch="${tag_components[2]}"

new_patch=$((patch + 1))
new_minor=$((minor + 1))
new_major=$((major + 1))

new_version_patch="v${major}.${minor}.${new_patch}"
new_version_minor="v${major}.${new_minor}.0"
new_version_major="v${new_major}.0.0"

function update_tags {
  version=$1

  echo
  echo "Selected version: $version"

  echo "Updating tags..."

  echo $version
  git tag -a -m "Release $version" $version
  git push origin $version --quiet
  tag=$version

  for i in {1..2}
  do
    tag="${tag%.*}"
    echo $tag
    git tag -f -a -m "Updating tag $tag using $version" $tag
    git push origin $tag --force --no-verify --quiet
  done

  echo "Tags updated successfully"
}

PS3="Select the new version: "

select opt in $new_version_patch $new_version_minor $new_version_major quit;
do
  case $opt in
    $new_version_patch)
      update_tags $new_version_patch
      break
      ;;
    $new_version_minor)
      update_tags $new_version_minor
      break
      ;;
    $new_version_major)
      update_tags $new_version_major
      break
      ;;
    quit)
      break
      ;;
    *)
      echo "Invalid option $REPLY"
      ;;
  esac
done