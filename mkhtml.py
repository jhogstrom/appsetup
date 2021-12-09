import markdown
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, metavar="FILE")
parser.add_argument("--output", required=True, metavar="FILE")

args = parser.parse_args()

print(f"Converting {args.input} -> {args.output}")
markdown.markdownFromFile(
    input=args.input,
    output=args.output)
