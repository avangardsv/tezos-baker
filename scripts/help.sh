#!/usr/bin/env bash

cat << 'HELP'

Tezos Baker - Simplified Study Mode
====================================

Setup & Initialization:
  npm run setup                Initialize node configuration and identity
  npm run snapshot:download    Download latest Ghostnet rolling snapshot
  npm run snapshot:import      Import downloaded snapshot (stop node first)

Node Management:
  npm run node:start           Start the Tezos node
  npm run node:stop            Stop the node
  npm run node:logs            View live node logs

Account Management:
  npm run account:create       Create new account (alice)
  npm run account:show         Show account address
  npm run account:balance      Check account balance

Staking Operations:
  npm run stake:status         Show comprehensive staking status
  npm run stake:all            Stake all available funds

Delegation & Baking:
  npm run delegate:register    Register account as delegate
  npm run baker:start          Start the baker
  npm run baker:logs           View live baker logs

Utilities:
  npm run help                 Show this help message

Quick Start (Study Mode):
  1. npm run setup
  2. npm run snapshot:download
  3. npm run snapshot:import
  4. npm run node:start
  5. npm run account:create
  6. Get testnet XTZ from https://faucet.ghostnet.teztnets.xyz/
  7. npm run delegate:register
  8. npm run stake:all          ⚠️  CRITICAL: Must stake to receive baking rights!
  9. npm run baker:start
  10. Wait 14-21 days for baking rights

Direct Docker Commands (Advanced):
  docker ps                            # Show running containers
  docker logs -f tezos-node           # View node logs
  docker logs -f tezos-baker          # View baker logs
  docker rm -f tezos-node tezos-baker # Stop and remove containers

Resources:
  Blockchain Explorer: https://ghostnet.tzkt.io/
  Testnet Faucet: https://faucet.ghostnet.teztnets.xyz/
  Documentation: README.md, docs/STAKING-QUICK-START.md

Note: This is simplified study mode (15 essential commands).
      Advanced features archived for future production use.

HELP
