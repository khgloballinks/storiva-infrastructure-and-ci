import re

for filename in ['docker/docker-compose.dev.yml', 'docker/docker-compose.prod.yml']:
    with open(filename, 'r') as f:
        content = f.read()
    
    # Replace the test line
    def repl(m):
        port = m.group(1)
        return f'test: ["CMD-SHELL", "wget -qO- http://localhost:{port}/health || exit 1"]'
        
    content = re.sub(r'test:\s*\["CMD",\s*"curl",\s*"-f",\s*"http://localhost:(\d+)/health"\]', repl, content)
    
    with open(filename, 'w') as f:
        f.write(content)

print("Updated healthchecks")
