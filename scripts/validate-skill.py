#!/usr/bin/env python3
"""
validate-skill.py — 静态校验 SKILL.md

检查项:
  1. frontmatter 完整: name / description / when_to_use / metadata.version
  2. name 规范: ≤64 字符, kebab-case, 不含 'anthropic'/'claude'
  3. description ≤1024 字符
  4. 整个 SKILL.md 字节数 < 字符预算阈值 (默认 9000, 留 buffer)
  5. references/*.md 链接全部能解析
  6. 无绝对路径 PII (/Users/<name>, /home/<name>)
  7. tests/examples/ 至少 1 个 case

用法:
  python3 scripts/validate-skill.py                       # 校验所有 .claude/skills/
  python3 scripts/validate-skill.py .claude/skills/search # 校验单个
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

CHAR_BUDGET_SOFT = 13000  # 留 ~13% 余量, 硬上限 15000 (Claude Code 默认)
NAME_MAX = 64
DESC_MAX = 1024
FORBIDDEN_IN_NAME = ("anthropic", "claude")


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """简化 YAML frontmatter parser, 只支持本仓约定的几个字段"""
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text
    body = text[end + 5:]
    fm_raw = text[4:end]

    fm = {}
    current_key = None
    for line in fm_raw.split("\n"):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        # 二级缩进 (metadata.version 等)
        if line.startswith("  ") and current_key:
            sub_key, _, sub_val = line.strip().partition(":")
            fm.setdefault(current_key, {})[sub_key.strip()] = sub_val.strip().strip('"\'')
            continue
        key, _, val = line.partition(":")
        key = key.strip()
        val = val.strip().strip('"\'')
        current_key = key
        fm[key] = val if val else {}
    return fm, body


def check_skill(skill_dir: Path) -> list[str]:
    errors: list[str] = []
    skill_md = skill_dir / "SKILL.md"

    if not skill_md.is_file():
        return [f"✗ {skill_dir}: SKILL.md 缺失"]

    raw = skill_md.read_text(encoding="utf-8")
    byte_len = len(raw.encode("utf-8"))
    fm, body = parse_frontmatter(raw)

    # 1. frontmatter 必填
    for required in ("name", "description", "when_to_use"):
        if required not in fm or not fm[required]:
            errors.append(f"frontmatter 缺 {required}")

    if "metadata" not in fm or not isinstance(fm.get("metadata"), dict) or "version" not in fm["metadata"]:
        errors.append("frontmatter 缺 metadata.version")

    # 2. name 规范
    name = fm.get("name", "")
    if name:
        if len(name) > NAME_MAX:
            errors.append(f"name 超 {NAME_MAX} 字符: {len(name)}")
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", name):
            errors.append(f"name 须 kebab-case (小写+数字+连字符): '{name}'")
        for forbidden in FORBIDDEN_IN_NAME:
            if forbidden in name.lower():
                errors.append(f"name 不可含 '{forbidden}': '{name}'")

    # 3. description 长度
    desc = fm.get("description", "")
    if len(desc) > DESC_MAX:
        errors.append(f"description 超 {DESC_MAX} 字符: {len(desc)}")

    # 4. 字符预算
    if byte_len > CHAR_BUDGET_SOFT:
        errors.append(f"SKILL.md 太长 ({byte_len} 字节 > {CHAR_BUDGET_SOFT} 软上限), 推 references/")

    # 5. references 链接
    for match in re.finditer(r"\[.+?\]\(references/([^)]+)\)", body):
        ref_path = skill_dir / "references" / match.group(1)
        if not ref_path.is_file():
            errors.append(f"references 死链: {match.group(1)}")

    # 6. PII 绝对路径
    pii_patterns = [r"/Users/[a-zA-Z0-9_-]+/", r"/home/[a-zA-Z0-9_-]+/"]
    for pat in pii_patterns:
        for hit in re.finditer(pat, raw):
            errors.append(f"含 PII 绝对路径: {hit.group()}")

    # 7. tests/examples/
    examples_dir = skill_dir / "tests" / "examples"
    if not examples_dir.is_dir() or not any(examples_dir.glob("*.md")):
        errors.append("tests/examples/ 缺或空 (至少 1 个 case)")

    return [f"  ✗ {e}" for e in errors]


def main() -> int:
    args = sys.argv[1:]
    if args:
        targets = [Path(a).resolve() for a in args]
    else:
        skills_root = REPO_ROOT / ".claude" / "skills"
        targets = sorted(skills_root.iterdir()) if skills_root.is_dir() else []
        targets = [t for t in targets if t.is_dir()]

    if not targets:
        print("无 skill 可检")
        return 0

    total_fails = 0
    for skill_dir in targets:
        errors = check_skill(skill_dir)
        if errors:
            print(f"\n✗ {skill_dir.name}:")
            print("\n".join(errors))
            total_fails += 1
        else:
            print(f"✓ {skill_dir.name}")

    print(f"\n{'─' * 40}")
    print(f"checked: {len(targets)} | fails: {total_fails}")
    return 1 if total_fails else 0


if __name__ == "__main__":
    sys.exit(main())
