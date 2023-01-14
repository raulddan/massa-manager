#!/bin/bash

#Script de instalare pentru un nod Massa in testnet

#Cere parola nod/client
echo "Introduceti parola pentru nod/client:"
read parola
PS3='Selectati:'
optiuni=("Instalare nod Massa" "Update nod Massa" "Rulare Client" "Instalare Systemd pentru mentinerea nodului pornit" "Update Config.toml cu ip nou" "Logs - doar pt Systemd" "Repornire Nod")
select opt in "${optiuni[@]}"
do
    case $opt in
        "Instalare nod Massa")
            #Update Ubuntu
            sudo apt update && sudo apt upgrade -y
            cd ~
            
            #Stergem orice alta instalare ulterioara
            rm -rf $HOME/massa

            #Instalare nod dupa documentatia echipei Massa
            sudo apt install pkg-config curl git build-essential libssl-dev libclang-dev
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
            source $HOME/.cargo/env
            rustc --version
            rustup toolchain install nightly-2022-12-24
            rustup default nightly-2022-12-24
            rustc --version
            git clone --branch testnet https://github.com/massalabs/massa.git

            #Rulare nod
            cd massa/massa-node/
            RUST_BACKTRACE=full cargo build --release --
            sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "`wget -qO- eth0.me`"
EOF
            ;;
        "Rulare Client")
            cd ~
            cd massa/massa-client/
            cargo run --release -- -p $parola
            ;;
        "Update Config.toml cu ip nou")
            sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml 
[network] 
routable_ip = "`wget -qO- eth0.me`"
EOF
            ;;
        "Update Nod Massa")
            sudo apt update && sudo apt upgrade -y
            cd ~
            rustup install nightly-2022-12-24
            rustup default nightly-2022-12-24
            cd massa/
            git stash
            git remote set-url origin https://github.com/massalabs/massa.git
            git checkout testnet
            git pull
            cd massa-node/
            RUST_BACKTRACE=full cargo build --release --
            ;;
        "Instalare Systemd pentru mentinerea nodului pornit")
            #Creare Systemd pentru mentinerea nodului pornit
            sudo chmod 777 /etc/systemd/system/
            sudo printf "[Unit]
Description=Massa Node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/target/release/massa-node -p $parola
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/massad.service
            sudo systemctl daemon-reload
            sudo systemctl enable massad
            sudo systemctl restart massad
            sudo chmod 755 /etc/systemd/system/
            ;;
        "Logs - doar pt Systemd")
            journalctl -xefu massad
            ;;
        "Repornire Nod")
            sudo systemctl restart massad
            ;;
        *) echo "Optiune inexistenta";;
    esac
done