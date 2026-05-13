from pathlib import Path
import re
root = Path('./lib')
patterns = [
    (re.compile(r"import\s+'(\.\./)+core/constants/(.+?)';"), "import 'package:reelscholar/core/constants/\2';"),
    (re.compile(r"import\s+'(\.\./)+models/(.+?)';"), "import 'package:reelscholar/models/\2';"),
    (re.compile(r"import\s+'(\.\./)+providers/(.+?)';"), "import 'package:reelscholar/providers/\2';"),
]
count = 0
for path in root.rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    new_text = text
    for pattern, repl in patterns:
        new_text = pattern.sub(repl, new_text)
    if new_text != text:
        path.write_text(new_text, encoding='utf-8')
        print('Updated', path)
        count += 1
print('Done', count)
