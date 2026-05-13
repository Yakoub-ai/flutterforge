'use strict';

const { fetch } = require('undici');

const BASE_URL = 'https://pub.dev/api';
const REQUEST_TIMEOUT_MS = 10_000;
const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 500;

async function apiFetch(path) {
  let lastError;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    if (attempt > 0) {
      await new Promise((r) => setTimeout(r, RETRY_DELAY_MS * attempt));
    }
    try {
      const res = await fetch(`${BASE_URL}${path}`, {
        headers: { 'Accept': 'application/json', 'User-Agent': 'pub-dev-mcp/1.0' },
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
      if (!res.ok) {
        if (res.status === 404) throw Object.assign(new Error(`Not found: ${path}`), { code: 'NOT_FOUND' });
        if (res.status === 429) { lastError = new Error('Rate limited by pub.dev'); continue; }
        throw new Error(`pub.dev API error ${res.status}: ${path}`);
      }
      return await res.json();
    } catch (err) {
      lastError = err;
      if (err.code === 'NOT_FOUND') throw err;
    }
  }
  throw lastError;
}

/**
 * Search packages on pub.dev.
 * @param {string} query
 * @param {number} [limit=10]
 * @returns {Promise<Array<{name, description, version, likes, pubPoints, popularity, publishedAt}>>}
 */
async function searchPackages(query, limit = 10) {
  const data = await apiFetch(`/search?q=${encodeURIComponent(query)}`);
  const packages = (data.packages || []).slice(0, limit);
  const details = await Promise.allSettled(packages.map((p) => getPackage(p.package)));
  return details.map((result, i) => {
    if (result.status === 'fulfilled') return result.value;
    return { name: packages[i].package, error: result.reason?.message };
  });
}

/**
 * Get package info (latest version, pubspec, publisher).
 */
async function getPackage(name) {
  const data = await apiFetch(`/packages/${encodeURIComponent(name)}`);
  const latest = data.latest?.pubspec ?? {};
  const score = await getPackageScore(name).catch(() => null);
  return {
    name: data.name,
    version: data.latest?.version,
    description: latest.description ?? '',
    homepage: latest.homepage ?? '',
    repository: latest.repository ?? '',
    dartSdkConstraint: latest.environment?.sdk ?? '',
    flutterSdkConstraint: latest.environment?.flutter ?? '',
    publishedAt: data.latest?.published,
    publisher: data.publisherDomain ?? null,
    likes: score?.likeCount ?? 0,
    pubPoints: score?.grantedPoints ?? 0,
    maxPoints: score?.maxPoints ?? 0,
    popularity: score ? Math.round(score.popularityScore * 100) : 0,
  };
}

/**
 * Get package score metrics.
 */
async function getPackageScore(name) {
  const data = await apiFetch(`/packages/${encodeURIComponent(name)}/score`);
  return {
    likeCount: data.likeCount ?? 0,
    popularityScore: data.popularityScore ?? 0,
    grantedPoints: data.grantedPoints ?? 0,
    maxPoints: data.maxPoints ?? 0,
  };
}

/**
 * List all published versions of a package (newest first).
 */
async function getPackageVersions(name) {
  const data = await apiFetch(`/packages/${encodeURIComponent(name)}`);
  const versions = (data.versions || [])
    .map((v) => ({ version: v.version, published: v.published }))
    .reverse();
  return { name: data.name, versions };
}

/**
 * Check if a package is compatible with a given Flutter version.
 * Uses the `environment.flutter` constraint from the latest pubspec.
 */
async function checkCompatibility(name, flutterVersion) {
  const pkg = await getPackage(name);
  const constraint = pkg.flutterSdkConstraint;
  if (!constraint) {
    return {
      name,
      flutterVersion,
      constraint: null,
      compatible: null,
      note: 'Package does not declare a Flutter SDK constraint — likely compatible with any version.',
    };
  }
  const compatible = satisfiesFlutterConstraint(flutterVersion, constraint);
  return {
    name,
    version: pkg.version,
    flutterVersion,
    constraint,
    compatible,
    note: compatible
      ? `Package ${name}@${pkg.version} is compatible with Flutter ${flutterVersion}.`
      : `Package ${name}@${pkg.version} requires Flutter ${constraint}, which does not satisfy ${flutterVersion}.`,
  };
}

/**
 * Minimal Flutter semver constraint checker (handles ^X.Y.Z, >=X.Y.Z, >=X.Y.Z <A.B.C).
 */
function satisfiesFlutterConstraint(version, constraint) {
  try {
    const v = parseVersion(version);
    const parts = constraint.trim().split(/\s+/);
    for (const part of parts) {
      const m = part.match(/^(\^|>=|<=|>|<|=)?(\d+\.\d+\.\d+)$/);
      if (!m) continue;
      const [, op, vStr] = m;
      const c = parseVersion(vStr);
      if (op === '^') {
        if (!versionGte(v, c)) return false;
        if (c.major > 0 && v.major !== c.major) return false;
        if (c.major === 0 && c.minor > 0 && v.minor !== c.minor) return false;
      } else if (op === '>=' && !versionGte(v, c)) return false;
      else if (op === '<=' && !versionGte(c, v)) return false;
      else if (op === '>' && !versionGt(v, c)) return false;
      else if (op === '<' && !versionGt(c, v)) return false;
    }
    return true;
  } catch {
    return null;
  }
}

function parseVersion(s) {
  const [major, minor, patch] = s.split('.').map(Number);
  return { major, minor, patch };
}

function versionGte(a, b) {
  if (a.major !== b.major) return a.major > b.major;
  if (a.minor !== b.minor) return a.minor > b.minor;
  return a.patch >= b.patch;
}

function versionGt(a, b) {
  if (a.major !== b.major) return a.major > b.major;
  if (a.minor !== b.minor) return a.minor > b.minor;
  return a.patch > b.patch;
}

module.exports = { searchPackages, getPackage, getPackageScore, getPackageVersions, checkCompatibility };
