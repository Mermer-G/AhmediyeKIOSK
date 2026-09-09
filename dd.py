import argparse
import subprocess
from pathlib import Path
from datetime import datetime


def run_git(args):
    result = subprocess.run(
        ["git"] + args,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())

    return result.stdout


def get_repo_root():
    return Path(run_git(["rev-parse", "--show-toplevel"]).strip())


def get_commits():
    output = run_git([
        "log",
        "--reverse",
        "--format=%H%x1f%an%x1f%ae%x1f%ad%x1f%s%x1e",
        "--date=iso-strict",
    ])

    commits = []

    for raw in output.split("\x1e"):
        raw = raw.strip()

        if not raw:
            continue

        parts = raw.split("\x1f")

        if len(parts) != 5:
            continue

        commit_hash, author, email, date, subject = parts

        commits.append({
            "hash": commit_hash,
            "short_hash": commit_hash[:8],
            "author": author,
            "email": email,
            "date": date,
            "subject": subject,
        })

    return commits


def get_commit_stats(commit_hash):
    output = run_git([
        "show",
        "--format=",
        "--numstat",
        commit_hash,
    ])

    files = []
    added = 0
    deleted = 0

    for line in output.splitlines():
        parts = line.split("\t")

        if len(parts) != 3:
            continue

        add, delete, filename = parts

        # Binary files appear as "-"
        if add == "-" or delete == "-":
            files.append({
                "file": filename,
                "added": None,
                "deleted": None,
                "binary": True,
            })
            continue

        try:
            add = int(add)
            delete = int(delete)
        except ValueError:
            continue

        added += add
        deleted += delete

        files.append({
            "file": filename,
            "added": add,
            "deleted": delete,
            "binary": False,
        })

    return files, added, deleted


def get_commit_body(commit_hash):
    return run_git([
        "show",
        "--format=%b",
        "--no-patch",
        commit_hash,
    ]).strip()


def get_diff(commit_hash, max_lines):
    output = run_git([
        "show",
        "--format=",
        "--patch",
        "--no-ext-diff",
        commit_hash,
    ])

    lines = output.splitlines()

    if len(lines) <= max_lines:
        return output

    return (
        "\n".join(lines[:max_lines])
        + "\n\n"
        + f"[DIFF TRUNCATED: {len(lines) - max_lines} more lines]\n"
    )


def main():
    parser = argparse.ArgumentParser(
        description="Generate an AI-friendly development history from a Git repository."
    )

    parser.add_argument(
        "--output",
        default="development_history.md",
        help="Output markdown file.",
    )

    parser.add_argument(
        "--diff",
        action="store_true",
        help="Include commit diffs.",
    )

    parser.add_argument(
        "--diff-lines",
        type=int,
        default=200,
        help="Maximum diff lines per commit.",
    )

    parser.add_argument(
        "--max-commits",
        type=int,
        default=0,
        help="Maximum number of commits. 0 = all.",
    )

    args = parser.parse_args()

    repo_root = get_repo_root()

    print(f"Repository: {repo_root}")

    commits = get_commits()

    if args.max_commits > 0:
        commits = commits[:args.max_commits]

    print(f"Commits found: {len(commits)}")

    output = []

    output.append("# Development History")
    output.append("")
    output.append("Generated automatically from Git history.")
    output.append("")
    output.append(f"Repository: `{repo_root.name}`")
    output.append(f"Generated: `{datetime.now().isoformat(timespec='seconds')}`")
    output.append("")
    output.append("---")
    output.append("")

    # ---------------------------------------------------------
    # OVERVIEW
    # ---------------------------------------------------------

    if commits:
        first_date = commits[0]["date"]
        last_date = commits[-1]["date"]

        output.append("## Project Timeline")
        output.append("")
        output.append(f"- First commit: `{first_date}`")
        output.append(f"- Last commit: `{last_date}`")
        output.append(f"- Total commits analyzed: `{len(commits)}`")
        output.append("")

    # ---------------------------------------------------------
    # COMMIT HISTORY
    # ---------------------------------------------------------

    output.append("## Chronological Development")
    output.append("")

    total_added = 0
    total_deleted = 0

    for index, commit in enumerate(commits, start=1):

        print(
            f"[{index}/{len(commits)}] "
            f"{commit['short_hash']} {commit['subject']}"
        )

        files, added, deleted = get_commit_stats(commit["hash"])

        total_added += added
        total_deleted += deleted

        output.append(
            f"## {index}. {commit['subject']}"
        )
        output.append("")

        output.append(
            f"**Commit:** `{commit['short_hash']}`  \n"
            f"**Date:** `{commit['date']}`  \n"
            f"**Author:** `{commit['author']}`"
        )

        output.append("")

        body = get_commit_body(commit["hash"])

        if body:
            output.append("### Commit Notes")
            output.append("")
            output.append(body)
            output.append("")

        output.append("### Change Summary")
        output.append("")
        output.append(
            f"- Files changed: `{len(files)}`"
        )
        output.append(
            f"- Lines added: `{added}`"
        )
        output.append(
            f"- Lines deleted: `{deleted}`"
        )
        output.append("")

        if files:
            output.append("### Changed Files")
            output.append("")
            output.append("| File | Added | Deleted |")
            output.append("|---|---:|---:|")

            for file in files:
                if file["binary"]:
                    output.append(
                        f"| `{file['file']}` | binary | binary |"
                    )
                else:
                    output.append(
                        f"| `{file['file']}` | "
                        f"{file['added']} | "
                        f"{file['deleted']} |"
                    )

            output.append("")

        if args.diff:
            diff = get_diff(
                commit["hash"],
                args.diff_lines,
            )

            if diff.strip():
                output.append("### Diff")
                output.append("")
                output.append("```diff")
                output.append(diff.rstrip())
                output.append("```")
                output.append("")

        output.append("---")
        output.append("")

    # ---------------------------------------------------------
    # GLOBAL STATISTICS
    # ---------------------------------------------------------

    output.append("## Overall Change Statistics")
    output.append("")
    output.append(
        f"- Total commits: `{len(commits)}`"
    )
    output.append(
        f"- Total lines added: `{total_added}`"
    )
    output.append(
        f"- Total lines deleted: `{total_deleted}`"
    )
    output.append("")

    # ---------------------------------------------------------
    # AI INSTRUCTIONS
    # ---------------------------------------------------------

    output.append("## AI Analysis Instructions")
    output.append("")
    output.append(
        "Use this Git history as evidence of how the project developed over time."
    )
    output.append("")
    output.append(
        "Analyze the chronological relationship between changes rather than "
        "simply summarizing individual commits."
    )
    output.append("")
    output.append(
        "Infer reasonable development phases, technical motivations, "
        "dependencies between features, and problems that likely led to "
        "subsequent changes."
    )
    output.append("")
    output.append(
        "Construct a coherent development narrative while clearly "
        "distinguishing evidence from reasonable inference."
    )
    output.append("")

    # ---------------------------------------------------------
    # WRITE
    # ---------------------------------------------------------

    output_path = repo_root / args.output

    output_path.write_text(
        "\n".join(output),
        encoding="utf-8",
    )

    print()
    print("Done!")
    print(f"Output: {output_path}")


if __name__ == "__main__":
    main()