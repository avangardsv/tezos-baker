#!/bin/bash

cat << 'EOF'

Tezos Baker - Available npm Commands
=====================================

Setup & Initialization:
  npm run setup                Initialize node configuration and identity
  npm run setup:snapshot       Setup + download snapshot for faster sync

Node Management:
  npm run node:start           Start the Tezos node
  npm run node:stop            Stop the node
  npm run node:restart         Restart the node
  npm run node:logs            View live node logs
  npm run node:status          Check current block info
  npm run node:bootstrap       Wait for node to bootstrap

Snapshot Operations:
  npm run snapshot:download    Download latest Ghostnet rolling snapshot
  npm run snapshot:check       Check if snapshot downloaded and file size
  npm run snapshot:import      Import downloaded snapshot (stop node first)

Account Management:
  npm run account:create       Create new account (alice)
  npm run account:show         Show account address
  npm run account:balance      Check account balance

Delegation & Baking:
  npm run delegate:register    Register account as delegate
  npm run baker:start          Start the baker
  npm run baker:stop           Stop the baker
  npm run baker:logs           View live baker logs
  npm run baker:rights         Check baking rights

Utilities:
  npm run ps                   Show all Tezos containers
  npm run clean                Stop all containers
  npm run clean:data           Stop all + delete blockchain data
  npm run help                 Show this help message

Quick Start:
  1. npm run setup
  2. npm run node:start
  3. npm run snapshot:download && npm run node:stop && npm run snapshot:import && npm run node:start
  4. npm run account:create && npm run account:show
  5. Get testnet XTZ from https://faucet.ghostnet.teztnets.xyz/
  6. npm run delegate:register
  7. npm run baker:start

EOF
