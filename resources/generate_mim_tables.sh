#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shopt -s nullglob
files=("${script_dir}"/*.mim.yml)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No .mim.yml files found in ${script_dir}" >&2
  exit 1
fi

for file in "${files[@]}"; do
  ruby -ryaml -e '
    file = ARGV[0]
    data = YAML.load_file(file) || {}

    def format_value(value)
      value = value.join(", ") if value.is_a?(Array)
      value = value.to_s
      value = value.gsub("|", "\\\\|")
      value = value.gsub(/\s+/, " ").strip
      value
    end

    def format_bullets(value)
      return "" if value.nil?
      if value.is_a?(Array)
        value = value.map { |item| "- #{item}" }.join("<br>")
      else
        value = "- #{value}"
      end
      value = value.to_s
      value = value.gsub("|", "\\\\|")
      value = value.gsub(/\s+/, " ").strip
      value
    end

    name = format_value(data["name"])
    desc = format_value(data.dig("description", "en", "shortDescription"))
    url = format_value(data["landingUrl"] || data["landingURL"])
    mims = format_bullets(data["mims"])
    license = format_value(data.dig("legal", "license"))

    puts "| #{name} |"
    puts "| ------ |"
    puts "| Description: | #{desc} |"
    puts "| URL: | #{url} |"
    puts "| MIMs: | #{mims} |"
    puts "| License: | #{license} |"
    puts
  ' "$file"
done
