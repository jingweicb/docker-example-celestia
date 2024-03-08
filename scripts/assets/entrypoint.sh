#!/bin/bash
set -euxo pipefail

# debug cmd
#tail -f /dev/null
if [[ "$MODE" = "ONLINE" ]]; then
  if [ ! -d "/data" ]; then
    echo "No /data volume attached"
  fi
fi

if [ -f "/data/config/node_key.json" ]; then
    rm /data/config/node_key.json
    echo "node_key.json removed"
fi


echo "CELESTIA_NETWORK = $CELESTIA_NETWORK"
echo "CHAIN_ID = $CHAIN_ID"
echo "CONFIG_PATH = $CONFIG_PATH"
echo "FROM_SCRATCH = $FROM_SCRATCH"
echo "HOME_DIR = $HOME_DIR"

if [ ! -d "$HOME_DIR/config" ]; then
  echo "init celestia home"
  /app/bin/celestia-appd init "celestia-cb-01" --home $HOME_DIR --chain-id $CHAIN_ID -o
fi

# copy the app.toml file
if [[ "$CELESTIA_NETWORK" = "mocha-4" ]]; then
  echo "prepare the config of $CELESTIA_NETWORK"

  cp /app/assets/app.toml.mocha "$HOME_DIR/config/app.toml"
  cp /app/assets/config.toml.mocha "$HOME_DIR/config/config.toml"
  cp /app/assets/genesis.json.mocha "$HOME_DIR/config/genesis.json"
  cp /app/assets/addrbook.json.mocha "$HOME_DIR/config/addrbook.json"
elif [[ "$CELESTIA_NETWORK" = "mainnet" ]]; then
  echo "prepare the config of $CELESTIA_NETWORK"

  cp /app/assets/app.toml.mainnet "$HOME_DIR/config/app.toml"
  cp /app/assets/config.toml.mainnet "$HOME_DIR/config/config.toml"
  cp /app/assets/genesis.json.mainnet "$HOME_DIR/config/genesis.json"
  cp /app/assets/addrbook.json.mainnet "$HOME_DIR/config/addrbook.json"
else
  echo "network $CELESTIA_NETWORK is not recognized"
fi

# sync snapshot from scratch
if [[ "$FROM_SCRATCH" = "true" ]]; then
  echo "downloading snapshot..."
  /app/bin/celestia-appd tendermint unsafe-reset-all --home $HOME_DIR --keep-addr-book
  export SNAP_NAME=$(curl -s https://snaps.qubelabs.io/celestia/ | egrep -o ">$CHAIN_ID.*tar" | tr -d ">" | head -1)

  wget -O - https://snaps.qubelabs.io/celestia/${SNAP_NAME} | tar xvf - -C $HOME_DIR

  echo "successfully downloaded the snapshot data"
fi

# debug cmd
# tail -f /dev/null
echo "start celestia-appd"
exec /app/bin/celestia-appd start --home $HOME_DIR
