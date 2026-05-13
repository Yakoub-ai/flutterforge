'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const Module = require('module');

const DEPENDENCIES = [
  '@modelcontextprotocol/sdk@^1.0.0',
  'undici@^6.0.0',
];

function dependencyRoot() {
  if (process.env.CLAUDE_PLUGIN_DATA) {
    return path.join(process.env.CLAUDE_PLUGIN_DATA, 'pub-dev-mcp');
  }

  const cacheBase = process.env.LOCALAPPDATA ||
    process.env.XDG_CACHE_HOME ||
    (process.env.HOME ? path.join(process.env.HOME, '.cache') : process.cwd());

  return path.join(
    cacheBase,
    'flutterforge',
    'pub-dev-mcp'
  );
}

function ensureDependencies() {
  const localModulesDir = path.join(__dirname, 'node_modules');
  if (
    fs.existsSync(path.join(localModulesDir, '@modelcontextprotocol', 'sdk', 'package.json')) &&
    fs.existsSync(path.join(localModulesDir, 'undici', 'package.json'))
  ) {
    process.env.NODE_PATH = process.env.NODE_PATH
      ? `${localModulesDir}${path.delimiter}${process.env.NODE_PATH}`
      : localModulesDir;
    Module._initPaths();
    return;
  }

  const root = dependencyRoot();
  const modulesDir = path.join(root, 'node_modules');
  const sdkEntry = path.join(modulesDir, '@modelcontextprotocol', 'sdk', 'package.json');
  const undiciEntry = path.join(modulesDir, 'undici', 'package.json');

  fs.mkdirSync(root, { recursive: true });

  if (!fs.existsSync(sdkEntry) || !fs.existsSync(undiciEntry)) {
    const result = spawnSync(
      process.platform === 'win32' ? 'npm.cmd' : 'npm',
      ['install', '--prefix', root, '--no-audit', '--no-fund', '--omit=dev', ...DEPENDENCIES],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }
    );

    if (result.status !== 0) {
      process.stderr.write(
        'pub-dev-mcp dependency install failed. ' +
        'Check npm/network access, or run npm install in mcp-servers/pub-dev-mcp for local development.\n' +
        `${result.stderr || result.stdout || ''}\n`
      );
      process.exit(1);
    }
  }

  process.env.NODE_PATH = process.env.NODE_PATH
    ? `${modulesDir}${path.delimiter}${process.env.NODE_PATH}`
    : modulesDir;
  Module._initPaths();
}

ensureDependencies();

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const {
  searchPackages,
  getPackage,
  getPackageScore,
  getPackageVersions,
  checkCompatibility,
} = require('./lib/pubdev-client.js');

const TOOLS = [
  {
    name: 'searchPackages',
    description: 'Search pub.dev for packages matching a query. Returns name, version, description, likes, pub points, and popularity score.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search query (e.g. "http client flutter", "state management")' },
        limit: { type: 'number', description: 'Max results to return (default: 10, max: 20)', default: 10 },
      },
      required: ['query'],
    },
  },
  {
    name: 'getPackage',
    description: 'Get detailed info for a pub.dev package: latest version, description, Flutter/Dart SDK constraints, publisher, likes, pub points, and popularity.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Package name (e.g. "riverpod", "go_router")' },
      },
      required: ['name'],
    },
  },
  {
    name: 'getPackageScore',
    description: 'Get pub.dev health scores for a package: like count, popularity score (0–1), granted pub points, and max possible points.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Package name' },
      },
      required: ['name'],
    },
  },
  {
    name: 'getPackageVersions',
    description: 'List all published versions of a pub.dev package, newest first, with publication dates.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Package name' },
      },
      required: ['name'],
    },
  },
  {
    name: 'checkCompatibility',
    description: 'Check if a package is compatible with a given Flutter version, based on its pubspec environment.flutter constraint.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Package name' },
        flutterVersion: { type: 'string', description: 'Flutter version to check against (e.g. "3.24.0")' },
      },
      required: ['name', 'flutterVersion'],
    },
  },
];

const server = new Server(
  { name: 'pub-dev-mcp', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  try {
    let result;
    switch (name) {
      case 'searchPackages':
        result = await searchPackages(args.query, Math.min(args.limit ?? 10, 20));
        break;
      case 'getPackage':
        result = await getPackage(args.name);
        break;
      case 'getPackageScore':
        result = await getPackageScore(args.name);
        break;
      case 'getPackageVersions':
        result = await getPackageVersions(args.name);
        break;
      case 'checkCompatibility':
        result = await checkCompatibility(args.name, args.flutterVersion);
        break;
      default:
        return { content: [{ type: 'text', text: `Unknown tool: ${name}` }], isError: true };
    }
    return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
  } catch (err) {
    return { content: [{ type: 'text', text: `Error: ${err.message}` }], isError: true };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  process.stderr.write(`pub-dev-mcp fatal error: ${err.message}\n`);
  process.exit(1);
});
