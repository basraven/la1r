#!/usr/bin/env bash
#
# Run a minimal Solana cluster.  Ctrl-C to exit.
#
# Before running this script ensure standard Solana programs are available
# in the PATH, or that `cargo build` ran successfully
#
set -e

echo "Running Seb's custom entrypoint"

# Prefer possible `cargo build` binaries over PATH binaries
script_dir="$(readlink -f "$(dirname "$0")")"
if [[ "$script_dir" =~ /scripts$ ]]; then
  cd "$script_dir/.."
else
  cd "$script_dir"
fi



profile=debug
if [[ -n $NDEBUG ]]; then
  profile=release
fi
PATH=$PWD/target/$profile:$PATH

ok=true
for program in solana-{faucet,genesis,keygen,validator}; do
  $program -V || ok=false
done
$ok || {
  echo
  echo "Unable to locate required programs.  Try building them first with:"
  echo
  echo "  $ cargo build --all"
  echo
  exit 1
}

export RUST_LOG=${RUST_LOG:-solana=info,solana_runtime::message_processor=debug} # if RUST_LOG is unset, default to info
export RUST_BACKTRACE=1
dataDir=$PWD/config/"$(basename "$0" .sh)"
ledgerDir=$PWD/config/ledger

SOLANA_RUN_SH_CLUSTER_TYPE=${SOLANA_RUN_SH_CLUSTER_TYPE:-development}

set -x
if ! solana address; then
  echo Generating default keypair
  solana-keygen new --no-passphrase
fi
validator_identity="$dataDir/validator-identity.json"
if [[ -e $validator_identity ]]; then
  echo "Use existing validator keypair"
else
  solana-keygen new --no-passphrase -so "$validator_identity"
fi
validator_vote_account="$dataDir/validator-vote-account.json"
if [[ -e $validator_vote_account ]]; then
  echo "Use existing validator vote account keypair"
else
  solana-keygen new --no-passphrase -so "$validator_vote_account"
fi
validator_stake_account="$dataDir/validator-stake-account.json"
if [[ -e $validator_stake_account ]]; then
  echo "Use existing validator stake account keypair"
else
  solana-keygen new --no-passphrase -so "$validator_stake_account"
fi

if [[ -e "$ledgerDir"/genesis.bin || -e "$ledgerDir"/genesis.tar.bz2 ]]; then
  echo "Use existing genesis"
else
  ./fetch-spl.sh
  if [[ -r spl-genesis-args.sh ]]; then
    SPL_GENESIS_ARGS=$(cat spl-genesis-args.sh)
  fi

  # shellcheck disable=SC2086
  solana-genesis \
    --hashes-per-tick sleep \
    --faucet-lamports 500000000000000000 \
    --bootstrap-validator \
      "$validator_identity" \
      "$validator_vote_account" \
      "$validator_stake_account" \
    --ledger "$ledgerDir" \
    --cluster-type "$SOLANA_RUN_SH_CLUSTER_TYPE" \
    $SPL_GENESIS_ARGS \
    $SOLANA_RUN_SH_GENESIS_ARGS
fi

abort() {
  set +e
  kill "$faucet" "$validator"
  wait "$validator"
}
trap abort INT TERM EXIT

solana-faucet &
faucet=$!

# args=(
#   --identity "$validator_identity"
#   --vote-account "$validator_vote_account"
#   --ledger "$ledgerDir"
#   --gossip-port 8001
#   --full-rpc-api
#   --rpc-port 8899
#   --rpc-faucet-address 127.0.0.1:9900
#   --log -
#   --enable-rpc-transaction-history
#   --enable-extended-tx-metadata-storage
#   --init-complete-file "$dataDir"/init-completed
#   --require-tower
#   --no-wait-for-vote-to-start-leader
#   --no-os-network-limits-test
# )

args=(
  --identity "$validator_identity"
  --ledger "$ledgerDir"
  --no-voting
  --full-rpc-api
  --limit-ledger-size 50000000
  --maximum-local-snapshot-age 86400
  --minimal-snapshot-download-speed 10
  --entrypoint mainnet-beta.solana.com:8001
  --entrypoint entrypoint2.mainnet-beta.solana.com:8001
  --entrypoint entrypoint3.mainnet-beta.solana.com:8001
  --entrypoint entrypoint4.mainnet-beta.solana.com:8001
  --entrypoint entrypoint5.mainnet-beta.solana.com:8001
  --rpc-port 8899
  --no-port-check
  --snapshots /usr/bin/config/ledger/snapshot
  --log -
  --dynamic-port-range 8000-8020
  --no-os-network-limits-test
  --enable-rpc-transaction-history
  --init-complete-file "$dataDir"/init-completed
)
  # --no-wait-for-vote-to-start-leader
  # --no-genesis-fetch
  # --enable-extended-tx-metadata-storage


# shellcheck disable=SC2086
solana-validator "${args[@]}" $SOLANA_RUN_SH_VALIDATOR_ARGS &
validator=$!

wait "$validator"
