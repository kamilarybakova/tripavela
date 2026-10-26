"""Run unmodified Flutter analysis in an ASCII copy (SDK LSP/Cyrillic workaround)."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='tripavela_analyze_') as temporary:
    target = Path(temporary)
    for folder in ['lib', 'test', 'assets']:
        shutil.copytree(root / folder, target / folder)
    for name in ['pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml']:
        shutil.copyfile(root / name, target / name)
    for command in [['flutter', 'pub', 'get', '--offline'], ['flutter', 'analyze', '--no-pub']]:
        result = subprocess.run(command, cwd=target, check=False)
        if result.returncode:
            raise SystemExit(result.returncode)
