#!/bin/bash

CONFIG_FILE="local-repos.json"
WORKFLOW_FILE="ntfy-centralized-workflow.yml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file $CONFIG_FILE not found!"
    echo "Create it with your repository paths:"
    echo '{'
    echo '  "repositories": ['
    echo '    {'
    echo '      "name": "your-repo",'
    echo '      "path": "/path/to/your/repo"'
    echo '    }'
    echo '  ]'
    echo '}'
    exit 1
fi

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Workflow file $WORKFLOW_FILE not found!"
    exit 1
fi

echo "🔄 Updating all repositories with new workflow..."

# Parse JSON and update each repository
python3 -c "
import json
import os
import shutil

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

workflow_file = '$WORKFLOW_FILE'
updated_count = 0
error_count = 0

for repo in config['repositories']:
    repo_name = repo['name']
    repo_path = repo['path']
    
    print(f'📁 Processing {repo_name} at {repo_path}...')
    
    if not os.path.exists(repo_path):
        print(f'   ⚠️  Path does not exist: {repo_path}')
        error_count += 1
        continue
    
    # Create .github/workflows directory if it doesn't exist
    workflows_dir = os.path.join(repo_path, '.github', 'workflows')
    os.makedirs(workflows_dir, exist_ok=True)
    
    # Copy workflow file
    target_file = os.path.join(workflows_dir, 'ntfy-notifications.yml')
    try:
        shutil.copy2(workflow_file, target_file)
        print(f'   ✅ Workflow updated successfully')
        updated_count += 1
    except Exception as e:
        print(f'   ❌ Error copying workflow: {e}')
        error_count += 1

print(f'\\n📊 Summary:')
print(f'   ✅ Updated: {updated_count} repositories')
print(f'   ❌ Errors: {error_count} repositories')

if updated_count > 0:
    print(f'\\n💡 Next steps:')
    print(f'   1. Review changes in each repository')
    print(f'   2. Commit and push the workflow files')
    print(f'   3. Test the notifications')
"

echo "✨ Update process completed!"