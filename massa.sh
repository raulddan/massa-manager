#!/bin/bash

#Script de instalare pentru un nod Massa in testnet

#Cere parola nod/client
echo "Introduceti parola pentru nod/client:"
read parola
PS3='Selectati:'
while true; do
    optiuni=("Instalare nod Massa" "Update nod Massa" "Rulare Client" "Instalare Systemd pentru mentinerea nodului pornit" "Update Config.toml cu ip nou" "Logs - doar pt Systemd" "Repornire Nod" "Iesire")
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
                sudo apt install pkg-config curl git build-essential libssl-dev libclang-dev cmake
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
                source $HOME/.cargo/env
                rustc --version
                rustup toolchain install 1.74.1
                rustup default 1.74.1
                rustc --version
                git clone https://github.com/massalabs/massa.git
                
                #Rulare nod
                cd massa/massa-node/
                RUST_BACKTRACE=full cargo build --release --
                sudo ufw allow 31244
                sudo ufw allow 31245
                sudo ufw allow 33035
                sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[protocol]
routable_ip = "`wget -qO- eth0.me`"
EOF
                break
                ;;
            "Update nod Massa")
                sudo apt update && sudo apt upgrade -y
                cd ~
                rustup toolchain install 1.74.1
                rustup default 1.74.1
                cd massa/
                git stash
                git remote set-url origin https://github.com/massalabs/massa.git
                git checkout main
                git pull
                cd massa-node/
                RUST_BACKTRACE=full cargo build --release --
                break
                ;;
            "Rulare Client")
                cd ~
                cd massa/massa-client/
                cargo run --release -- -p $parola
                break
                ;;
            "Update Config.toml cu ip nou")
                sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml 
[protocol] 
routable_ip = "`wget -qO- eth0.me`"
EOF
                break
                ;;
            "Instalare Systemd pentru mentinerea nodului pornit")
                #Creare Systemd pentru mentinerea nodului pornit
                sudo chmod 777 /etc/systemd/system/
                printf "[Unit]
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
                break
                ;;
            "Logs - doar pt Systemd")
                sudo journalctl -u massad -f --no-hostname -o cat
                break
                ;;
            "Repornire Nod")
                sudo systemctl restart massad
                break
                ;;
            "Iesire")
                break 2
                ;;
            *) echo "Optiune inexistenta";;
        esac
    done
done
