#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";

const repoRoot = process.cwd();
const errors = [];
const warnings = [];

const pluginNamePattern = /^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/;

function addError(message) {
  errors.push(message);
}

function addWarning(message) {
  warnings.push(message);
}

async function pathExists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

async function ensureDirectory(targetPath, context) {
  try {
    const stat = await fs.stat(targetPath);
    if (!stat.isDirectory()) {
      addError(`${context} exists but is not a directory: ${targetPath}`);
      return false;
    }
    return true;
  } catch {
    addError(`${context} directory is missing: ${targetPath}`);
    return false;
  }
}

async function readJsonFile(filePath, context) {
  let raw;
  try {
    raw = await fs.readFile(filePath, "utf8");
  } catch {
    addError(`${context} is missing: ${filePath}`);
    return null;
  }

  try {
    return JSON.parse(raw);
  } catch (error) {
    addError(`${context} contains invalid JSON (${filePath}): ${error.message}`);
    return null;
  }
}

function normalizeNewlines(content) {
  return content.replace(/\r\n/g, "\n");
}

function parseFrontmatter(content) {
  const normalized = normalizeNewlines(content);
  if (!normalized.startsWith("---\n")) {
    return null;
  }

  const closingIndex = normalized.indexOf("\n---\n", 4);
  if (closingIndex === -1) {
    return null;
  }

  const frontmatterBlock = normalized.slice(4, closingIndex);
  const fields = {};

  for (const line of frontmatterBlock.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }
    const separator = line.indexOf(":");
    if (separator === -1) {
      continue;
    }
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    fields[key] = value;
  }

  return fields;
}

async function walkFiles(dirPath) {
  const files = [];
  const stack = [dirPath];

  while (stack.length > 0) {
    const current = stack.pop();
    const entries = await fs.readdir(current, { withFileTypes: true });
    for (const entry of entries) {
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(entryPath);
      } else if (entry.isFile()) {
        files.push(entryPath);
      }
    }
  }

  return files;
}

function isSafeRelativePath(value) {
  if (typeof value !== "string" || value.length === 0) {
    return false;
  }
  if (value.startsWith("http://") || value.startsWith("https://")) {
    return true;
  }
  if (path.isAbsolute(value)) {
    return false;
  }
  const normalized = path.posix.normalize(value.replace(/\\/g, "/"));
  return !normalized.startsWith("../") && normalized !== "..";
}

function extractPathValues(value) {
  if (typeof value === "string") {
    return [value];
  }

  if (Array.isArray(value)) {
    return value.flatMap((entry) => extractPathValues(entry));
  }

  if (value && typeof value === "object") {
    const candidates = [];
    if (typeof value.path === "string") {
      candidates.push(value.path);
    }
    if (typeof value.file === "string") {
      candidates.push(value.file);
    }
    return candidates;
  }

  return [];
}

async function validateReferencedPath(pluginDir, fieldName, pathValue) {
  if (pathValue.startsWith("http://") || pathValue.startsWith("https://")) {
    return;
  }

  if (!isSafeRelativePath(pathValue)) {
    addError(
      `Field "${fieldName}" has invalid path "${pathValue}". Use a relative path without ".." or absolute prefixes.`
    );
    return;
  }

  const resolved = path.resolve(pluginDir, pathValue);
  const exists = await pathExists(resolved);
  if (!exists) {
    addError(`Field "${fieldName}" references missing path "${pathValue}".`);
  }
}

async function validateFrontmatterFile(filePath, componentName, requiredKeys) {
  const content = await fs.readFile(filePath, "utf8");
  const parsed = parseFrontmatter(content);
  const relativeFile = path.relative(repoRoot, filePath);

  if (!parsed) {
    addError(`${componentName} file missing YAML frontmatter: ${relativeFile}`);
    return;
  }

  for (const key of requiredKeys) {
    if (!parsed[key] || parsed[key].length === 0) {
      addError(`${componentName} file missing "${key}" in frontmatter: ${relativeFile}`);
    }
  }
}

async function validateComponentFrontmatter(pluginDir) {
  const rulesDir = path.join(pluginDir, "rules");
  if (await pathExists(rulesDir)) {
    const files = await walkFiles(rulesDir);
    for (const file of files) {
      const ext = path.extname(file).toLowerCase();
      if (ext === ".md" || ext === ".mdc" || ext === ".markdown") {
        await validateFrontmatterFile(file, "rule", ["description"]);
      }
    }
  }

  const skillsDir = path.join(pluginDir, "skills");
  if (await pathExists(skillsDir)) {
    const files = await walkFiles(skillsDir);
    for (const file of files) {
      if (path.basename(file) === "SKILL.md") {
        await validateFrontmatterFile(file, "skill", ["name", "description"]);
      }
    }
  }

  const agentsDir = path.join(pluginDir, "agents");
  if (await pathExists(agentsDir)) {
    const files = await walkFiles(agentsDir);
    for (const file of files) {
      const ext = path.extname(file).toLowerCase();
      if (ext === ".md" || ext === ".mdc" || ext === ".markdown") {
        await validateFrontmatterFile(file, "agent", ["name", "description"]);
      }
    }
  }

  const commandsDir = path.join(pluginDir, "commands");
  if (await pathExists(commandsDir)) {
    const files = await walkFiles(commandsDir);
    for (const file of files) {
      const ext = path.extname(file).toLowerCase();
      if (ext === ".md" || ext === ".mdc" || ext === ".markdown" || ext === ".txt") {
        await validateFrontmatterFile(file, "command", ["name", "description"]);
      }
    }
  }
}

async function main() {
  const manifestPath = path.join(repoRoot, ".cursor-plugin", "plugin.json");
  const manifest = await readJsonFile(manifestPath, "Plugin manifest");
  if (!manifest) {
    summarizeAndExit();
    return;
  }

  if (typeof manifest.name !== "string" || !pluginNamePattern.test(manifest.name)) {
    addError(
      '"name" in plugin.json must be lowercase and use only alphanumerics, hyphens, and periods.'
    );
  }

  if (typeof manifest.displayName !== "string" || manifest.displayName.length === 0) {
    addError('"displayName" in plugin.json is required.');
  }

  if (typeof manifest.version !== "string" || manifest.version.length === 0) {
    addError('"version" in plugin.json is required.');
  }

  if (typeof manifest.description !== "string" || manifest.description.length === 0) {
    addError('"description" in plugin.json is required.');
  }

  if (!manifest.author || typeof manifest.author.name !== "string" || manifest.author.name.length === 0) {
    addError('"author.name" in plugin.json is required.');
  }

  const manifestFields = ["logo", "rules", "skills", "agents", "commands", "hooks", "mcpServers"];
  for (const field of manifestFields) {
    if (manifest[field] === undefined) {
      continue;
    }
    const values = extractPathValues(manifest[field]);
    for (const value of values) {
      await validateReferencedPath(repoRoot, field, value);
    }
  }

  await validateComponentFrontmatter(repoRoot);

  const hooksValue = manifest.hooks;
  if (hooksValue) {
    const hooksPath = path.resolve(repoRoot, hooksValue);
    if (!(await pathExists(hooksPath))) {
      addError(`"hooks" references missing path "${hooksValue}".`);
    }
  } else {
    addWarning("No hooks field in plugin.json (only needed when using hooks).");
  }

  const mcpValue = manifest.mcpServers;
  if (mcpValue) {
    const mcpPath = path.resolve(repoRoot, mcpValue);
    if (!(await pathExists(mcpPath))) {
      addError(`"mcpServers" references missing path "${mcpValue}".`);
    }
  } else {
    addWarning("No mcpServers field in plugin.json (only needed when using MCP servers).");
  }

  summarizeAndExit();
}

function summarizeAndExit() {
  if (warnings.length > 0) {
    console.log("Warnings:");
    for (const warning of warnings) {
      console.log(`- ${warning}`);
    }
    console.log("");
  }

  if (errors.length > 0) {
    console.error("Validation failed:");
    for (const error of errors) {
      console.error(`- ${error}`);
    }
    process.exit(1);
  }

  console.log("Validation passed.");
}

await main();
