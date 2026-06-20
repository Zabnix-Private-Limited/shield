import { existsSync } from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const projectRoot = process.cwd();
const bundledFlutter = path.join(
  projectRoot,
  '.vercel',
  'flutter',
  'bin',
  process.platform === 'win32' ? 'flutter.bat' : 'flutter',
);

function resolveFlutterCommand() {
  if (existsSync(bundledFlutter)) {
    return bundledFlutter;
  }

  return process.platform === 'win32' ? 'flutter.bat' : 'flutter';
}

function runCommand(command, args, options = {}) {
  const isWindowsBatch =
    process.platform === 'win32' &&
    (command.endsWith('.bat') || command.endsWith('.cmd'));

  if (isWindowsBatch) {
    execFileSync('cmd.exe', ['/c', command, ...args], {
      cwd: projectRoot,
      stdio: 'inherit',
      ...options,
    });
    return;
  }

  execFileSync(command, args, {
    cwd: projectRoot,
    stdio: 'inherit',
    ...options,
  });
}

function runFlutter(args) {
  runCommand(resolveFlutterCommand(), args);
}

export { bundledFlutter, projectRoot, resolveFlutterCommand, runCommand, runFlutter };
