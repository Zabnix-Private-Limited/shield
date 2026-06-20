import { mkdirSync } from 'node:fs';
import path from 'node:path';
import { bundledFlutter, projectRoot, runCommand, runFlutter } from './vercel-shared.mjs';

const flutterRoot = path.dirname(path.dirname(bundledFlutter));

if (!process.env.VERCEL && process.platform === 'win32') {
  console.log('Skipping bundled Flutter download outside Vercel; local Flutter will be used.');
} else {
  mkdirSync(path.dirname(flutterRoot), { recursive: true });

  if (!path.basename(flutterRoot) || flutterRoot === projectRoot) {
    throw new Error('Resolved an invalid Flutter SDK destination.');
  }

  try {
    runCommand('git', [
      'clone',
      'https://github.com/flutter/flutter.git',
      '--depth',
      '1',
      '--branch',
      'stable',
      flutterRoot,
    ]);
  } catch (error) {
    if (!String(error.message).includes('already exists')) {
      throw error;
    }
  }
}

runFlutter(['config', '--enable-web']);
runFlutter(['--version']);
runFlutter(['pub', 'get']);
