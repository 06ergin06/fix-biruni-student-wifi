#!/usr/bin/env bash
set -euo pipefail

CONN_DIR="/etc/NetworkManager/system-connections"
CONN_FILE="$CONN_DIR/Biruni_Student.nmconnection"
CONN_ID="Biruni_Student"
SSID="Biruni_Student"

sudo -v

check_internet() {
    ping -c 2 -W 3 biruni.edu.tr >/dev/null 2>&1 && ping -c 2 -W 3 google.com >/dev/null 2>&1
}

EXISTING_FILE=""
if sudo test -f "$CONN_FILE"; then
    EXISTING_FILE="$CONN_FILE"
else
    EXISTING_FILE=$(sudo grep -rl "^ssid=$SSID$" "$CONN_DIR" 2>/dev/null | head -n 1 || true)
fi

if [ -n "$EXISTING_FILE" ]; then
    echo "[*] Mevcut dosya bulundu: $EXISTING_FILE"
    CONN_FILE="$EXISTING_FILE"
    CONN_ID=$(sudo awk -F= '/^id=/{print $2; exit}' "$CONN_FILE")

    TMP_FILE=$(mktemp)
    sudo awk '
        /^phase1-auth-flags=/ { next }
        /^\[802-1x\]/ { print; print "phase1-auth-flags=32"; added=1; next }
        { print }
        END {
            if (!added) {
                print "\n[802-1x]"
                print "phase1-auth-flags=32"
            }
        }
    ' "$CONN_FILE" > "$TMP_FILE"

    sudo mv "$TMP_FILE" "$CONN_FILE"
    sudo chown root:root "$CONN_FILE"
    sudo chmod 600 "$CONN_FILE"
else
    echo "[*] Profil bulunamadı, yeni dosya oluşturuluyor."
    read -rp "Okul Numarası: " STUDENT_ID
    read -rsp "Şifre: " STUDENT_PASS
    echo ""

    UUID=$(cat /proc/sys/kernel/random/uuid)
    TMP_FILE=$(mktemp)

    {
        printf '[connection]\n'
        printf 'id=%s\n' "$CONN_ID"
        printf 'uuid=%s\n' "$UUID"
        printf 'type=wifi\n\n'
        printf '[wifi]\n'
        printf 'mode=infrastructure\n'
        printf 'ssid=%s\n\n' "$SSID"
        printf '[wifi-security]\n'
        printf 'key-mgmt=wpa-eap\n\n'
        printf '[802-1x]\n'
        printf 'eap=peap;\n'
        printf 'identity=%s\n' "$STUDENT_ID"
        printf 'password=%s\n' "$STUDENT_PASS"
        printf 'phase2-auth=mschapv2\n'
        printf 'phase1-auth-flags=32\n\n'
        printf '[ipv4]\n'
        printf 'method=auto\n\n'
        printf '[ipv6]\n'
        printf 'addr-gen-mode=stable-privacy\n'
        printf 'method=auto\n\n'
        printf '[proxy]\n'
    } > "$TMP_FILE"

    sudo mv "$TMP_FILE" "$CONN_FILE"
    sudo chown root:root "$CONN_FILE"
    sudo chmod 600 "$CONN_FILE"
fi

sudo nmcli connection reload
sudo nmcli connection up "$CONN_ID" >/dev/null 2>&1 || true
sleep 3

if check_internet; then
    echo "[+] Bağlantı başarılı (biruni.edu.tr ve google.com erişilebilir)."
    exit 0
fi

echo "[!] İlk test başarısız."

if command -v dnf >/dev/null 2>&1; then
    echo "[*] dnf tespit edildi, LEGACY policy uygulanıyor..."
    sudo update-crypto-policies --set LEGACY
    sudo systemctl restart NetworkManager
    sleep 3
    sudo nmcli connection up "$CONN_ID" >/dev/null 2>&1 || true
    sleep 3

    if check_internet; then
        echo "[+] Bağlantı ikinci denemede başarılı."
        exit 0
    else
        echo "[-] Policy güncellemesine rağmen bağlantı sağlanamadı."
        exit 1
    fi
else
    echo "[-] Sistemde dnf bulunmadığı için update-crypto-policies atlandı ve bağlantı kurulamadı."
    exit 1
fi
