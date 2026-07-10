#!/bin/bash

# Vychozi hodnoty pro konfiguraci. Mohou byt nasledne prepsany konfiguracnimi skripty
# bash -c "$(wget -nv -O - https://rxw.cz/adsb/install-czadsb.sh)"

# Cesta k novemu konfiguracnimu souboru
CFG="/etc/default/czadsb.cfg"


# Cesta k instalacnim skriptum
#INSTALL_URL="https://rxw.cz/adsb/install"
#INSTALL_URL="https://raw.githubusercontent.com/Tydyt-cz/czadsb-install/refs/heads/main/install"
INSTALL_URL="https://raw.githubusercontent.com/CZADSB/czadsb-install/refs/heads/main/install"

# echo ${{ vars.URL_SCRIPTS }}

# Uvodni pozdrav
function info_logo(){
    echo
    echo "               ██████╗███████╗ █████╗ ██████╗ ███████╗██████╗ "
    echo "              ██╔════╝╚══███╔╝██╔══██╗██╔══██╗██╔════╝██╔══██╗"
    echo "              ██║       ███╔╝ ███████║██║  ██║███████╗██████╔╝"
    echo "              ██║      ███╔╝  ██╔══██║██║  ██║╚════██║██╔══██╗"
    echo "              ╚██████╗███████╗██║  ██║██████╔╝███████║██████╔╝"
    echo "               ╚═════╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═════╝ "
}

# Funkce zobrazi dotaz a ceka na odpoved odpovidajici masce. Pokud je prazdna, tak nastavi default
# Povinne parametry: text, maska, default
function input(){
    while true; do
        read -p "$1 " X
        if [[ -z ${X} ]] && [[ -n "$3" ]];then
            X=$3
        fi
        if [[ "${X}" =~ $2 ]];then
            break
        fi
        echo "Neplatna hodnota. Prosim zadejte platnou hodnotu."
    done
}

# Funkce nacte udaje z ipinfo.io na zaklade verejne IP adresy a prednastavi lokalizaci a nazev. Nastavi vychozi hodnoty
function set_default(){
    wget -q http://ipinfo.io -O /tmp/ipinfo.log
    [[ -e /tmp/ipinfo.log ]] && STATION_PUBIP=$(cat /tmp/ipinfo.log | grep \"ip\" | awk -F\" '{print $4}')
    if [[ -z ${STATION_NAME} ]] && [[ -e /tmp/ipinfo.log ]];then
        NAME1=$(cat /tmp/ipinfo.log | grep \"country\" | awk -F\" '{print $4}')
        NAME2=$(cat /tmp/ipinfo.log | grep \"city\" | awk -F\" '{print $4}')
        STATION_NAME="${NAME1}-${NAME2}"
    fi
    if [[ -z ${STATION_LAT} ]] && [[ -e /tmp/ipinfo.log ]];then
        STATION_LAT=$(cat /tmp/ipinfo.log | grep \"loc\" | awk -F\" '{print $4}' | awk -F, '{print $1}' | tr -d '\n')
    fi
    if [[ -z ${STATION_LON} ]] && [[ -e /tmp/ipinfo.log ]];then
        STATION_LON=$(cat /tmp/ipinfo.log | grep \"loc\" | awk -F\" '{print $4}' | awk -F, '{print $2}' | tr -d '\n')
    fi
    if [[ -z ${STATION_ALT} ]];then
        wget -q "https://api.open-elevation.com/api/v1/lookup?locations=${STATION_LAT},${STATION_LON}" -O /tmp/ipinfo.log
        [[ -e /tmp/ipinfo.log ]] && STATION_ALT=$(grep -ioP 'elevation..[[:digit:]]*' /tmp/ipinfo.log | awk -F: '{print $2}' | tr -d '\n')
    fi
    
    # Jednoznacny identifikator stanice
    [[ -z ${STATION_UUID} ]] && STATION_UUID=$(cat /proc/sys/kernel/random/uuid)
    # Povoleni upgrade systemu [auto|enable|disable]
    [[ -z ${STATION_UPGRADE} ]] && STATION_UPGRADE=enable
    
    # Jmeno uzivatele pod kterym se spusti nektere skripty
    [[ -z ${CZADSB_USER} ]] && CZADSB_USER="adsb"
    # Adresar pro instalaci nekterych programu
    [[ -z ${INSTALL_FOLDER} ]] && INSTALL_FOLDER="/opt/czadsb"

    # Povoleni/stav instalace
    [[ -z ${DUMP1090} ]] && DUMP1090="notinstall"
    # Nazev programu Dump1090
    [[ -z ${DUMP1090_NAME} ]] && DUMP1090_NAME="dump1090-fa"
    # Vyber rtl-sdr zarizeni
    [[ -z ${DUMP1090_DEV} ]] && DUMP1090_DEV=0
    # Kalibrace rtl-sdr zarizeni
    [[ -z ${DUMP1090_PPM} ]] && DUMP1090_PPM=0
    # Zesileni rtl-sdr zarizebi
    [[ -z ${DUMP1090_GAIN} ]] && DUMP1090_GAIN="60"

    # Nazev programu ReADSB
    [[ -z ${READSB_NAME} ]] && READSB_NAME="readsb"
    # Vyber rtl-sdr zarizeni
    [[ -z ${READSB_DEV} ]] && READSB_DEV=0
    # Kalibrace rtl-sdr zarizeni
    [[ -z ${READSB_PPM} ]] && READSB_PPM=0
    # Zesileni rtl-sdr zarizebi
    [[ -z ${READSB_GAIN} ]] && READSB_GAIN="auto"
    # Vychozi adresa pro odesilani ADSB dat
    [[ -z ${READSB_DST} ]] && READSB_DST="feed.czadsb.cz,3004"
    # Zalozni adresa pro odesilani ADSB dat
    [[ -z ${READSB_BCK} ]] && READSB_BCK="feed.rxw.cz,3004"
    # Pridani dalsich voleb pro ReADSB
    [[ -z ${READSB_OPT} ]] && READSB_OPT=""

    # Povoleni/stav instalace
    [[ -z ${ADSBFWD} ]] && ADSBFWD="notinstall"
    # Typ SW pro ADSB FWD
    [[ -z ${ADSBFWD_TYPE} ]] && ADSBFWD_TYPE="adsbfwd"
    # Nazev programu pro forward ADSB dat
    [[ -z ${ADSBFWD_NAME} ]] && ADSBFWD_NAME="adsbfwd"
    # Vychozi adresa pro cteni ADSB dat z dump1090
    [[ -z ${ADSBFWD_SRC} ]] && ADSBFWD_SRC="127.0.0.1:30005"
    # Vychozi adresa pro odesilani ADSB dat
    [[ -z ${ADSBFWD_DST} ]] && ADSBFWD_DST="czadsb.cz:50000"
    # Zalozni adresa pro odesilani ADSB dat
    [[ -z ${ADSBFWD_BAC} ]] && ADSBFWD_BAC=${READSB_BCK}

    # Nazev programu MLAT client
    [[ -z ${MLAT_NAME} ]] && MLAT_NAME="czadsb-mlat"
    # Adresa mlat serveru pro vypocet
    [[ -z ${MLAT_SERVER} ]] && MLAT_SERVER="mlat.czadsb.cz:3109"
    # Adresa kam posilat vypocitane pozice letadel
    [[ -z ${MLAT_RESULT} ]] && MLAT_RESULT="127.0.0.1:30104"
    # Format a typ pripojeni pro odesilani zpracovanych dat
    [[ -z ${MLAT_FORMAT} ]] && MLAT_FORMAT="beast,connect"

    # Lighttpd  
    [[ -z ${LIGHTTPD} ]] && LIGHTTPD="notinstall"
    # Nazev programu web serveru
    [[ -z ${LIGHTTPD_NAME} ]] && LIGHTTPD_NAME="lighttpd"
    # Tar1090  
    [[ -z ${TAR1090} ]] && TAR1090="notinstall"
    # Nazev programu Tar1090
    [[ -z ${TAR1090_NAME} ]] && TAR1090_NAME="tar1090"

    # Nazev VPN Edge n2n
    [[ -z ${N2NADSB_NAME} ]] && N2NADSB_NAME="vpn-czadsb"
    # Adresa VPN serveru
    [[ -z ${N2NADSB_SERVER} ]] && N2NADSB_SERVER="n2n.czadsb.cz:82"

    # Nazev programu pro zasilani reportu
    [[ -z ${REPORTER_NAME} ]] && REPORTER_NAME="reporter"
    # url adresa pro odesilani dat z reportu
    REPORTER_URL="https://rxw.cz/reporter/" #   [[ -z ${REPORTER_URL} ]] && REPORTER_URL="https://report.czadsb.cz"
    # Seznam sledovanych sluzeb
    [[ -z ${REPORTER_SER} ]] && REPORTER_SER="dump1090 dump1090-fa adsbfwd mlat-client vpn-czadsb" 
    # Interval pro odesilani dat
    [[ -z ${REPORTER_REF} ]] && REPORTER_REF="*:6,21,36,51"

    # Vychozi stav je bez instalace OGN
    [[ -z ${OGN} ]] && OGN="notinstall"
    # Nazev programu OGN / Flarm
    [[ -z ${OGN_NAME} ]] && OGN_NAME="rtlsdr-ogn"
    #  Vyber rtl-sdr zarizeni
    [[ -z ${OGN_DEV} ]] && OGN_DEV=1
    # Kalibrace rtl-sdr zarizeni
    [[ -z ${OGN_PPM} ]] && OGN_PPM=0
    # Zesileni rtl-sdr zarizebi
    [[ -z ${OGN_GAIN} ]] && OGN_GAIN=48

    # Vychozi stav je bez instalace PiAware
    if [[ -z ${PIAWARE} ]] || [[ "${PIAWARE}" == "notinstall" ]];then 
        PIAWARE_state=$(systemctl show piaware.service | grep UnitFileState | awk -F = '{print $2}' | tr -d '\n' )
        if [[ "${PIAWARE_state}" == "disabled" ]];then
            PIAWARE="install"
        elif [[ "${PIAWARE_state}" == "enabled" ]];then
            PIAWARE="install"
        else    
            PIAWARE="notinstall"
        fi
    fi
    # Pokud jiz existuje uuid pro piaware, tak jej nacti
    if [[ "${PIAWARE_UI}" == "" ]] && [[ -f "/run/piaware/status.json" ]];then
        PIAWARE_UI=$(awk -F\" '/unclaimed_feeder_id/ {print $4}' /run/piaware/status.json)
    fi
    if [[ "${PIAWARE_UI}" == "" ]] && [[ -n $(command -v piaware-config) ]];then
        PIAWARE_UI=$($SUDO piaware-config -show feeder-id)
    fi
    
    # Vychozi nastaveni flightradar24 - fr24
    if [[ -z ${FR24} ]] || [[ "${FR24}" == "notinstall" ]];then 
        FR24_state=$(systemctl show fr24feed.service | grep UnitFileState | awk -F = '{print $2}' | tr -d '\n' )
        if [[ "${FR24_state}" == "disabled" ]];then
            FR24="disable"
        elif [[ "${FR24_state}" == "enabled" ]];then
            FR24="enable"
        else    
            FR24="notinstall"
        fi
    fi
    [[ -z ${FR24_NAME} ]] && FR24_NAME="fr24feed"
    if [[ -f "/etc/fr24feed.ini" ]];then
        [[ -z ${FR24_RECEIVER} ]] && FR24_RECEIVER=$(awk -F\" '/receiver/ {print $2}' /etc/fr24feed.ini)
        [[ -z ${FR24_KEY} ]] && FR24_KEY=$(awk -F\" '/fr24key/ {print $2}' /etc/fr24feed.ini)
        [[ -z ${FR24_HOST} ]] && FR24_HOST=$(awk -F\" '/host/ {print $2}' /etc/fr24feed.ini)
    else
        [[ -z ${FR24_RECEIVER} ]] && FR24_RECEIVER="beast-tcp"
        [[ -z ${FR24_HOST} ]] && FR24_HOST="127.0.0.1:30005"
    fi

    # Vychozi nastaveni pro ADS-B Exchange 
    [[ -z ${ADSBEXCHANGE} ]] && ADSBEXCHANGE="notinstall"
    
    # Vychozi stav pro adsb.lol
    if [[ -f /usr/local/share/adsblol/adsblol-uuid ]];then
        [[ -z ${ADSBLOL} ]] && ADSBLOL="install"
        ADSBLOL_ID=$(cat /usr/local/share/adsblol/adsblol-uuid)
    else
        [[ -z ${ADSBLOL} ]] && ADSBLOL="notinstall"
        [[ -z ${ADSBLOL_ID} ]] && ADSBLOL_ID=""
    fi

}

# Funkce nacte seznam rtl-sdr zarizeni
function list_rtlsdr(){
    if command -v rtl_biast &>/dev/null ;then
        rtl_biast 2> /tmp/rtlsdr.log
        grep -e "^ " /tmp/rtlsdr.log > /tmp/rtlsdr.list
        rm -f /tmp/rtlsdr.log
        RTL_SDR=$(cat /tmp/rtlsdr.list | wc -l)
    else
        RTL_SDR=""
    fi
}

# Funkce zjisti informace o systemu a zobrazi je
function info_system(){
    . /etc/os-release
    STATION_SYSTEM="${PRETTY_NAME}"
    STATION_USER=$(users)
    STATION_ARCH=$(dpkg --print-architecture)
    STATION_MACHINE=$(uname -m)
    STATION_MODEL=$(grep Model /proc/cpuinfo | awk -F : '{print $2}')
    [[ -z ${STATION_MODEL} ]] && STATION_MODEL=$($SUDO dmidecode | grep -A4 '^System Information' | grep 'Manufacturer' | awk -F: '{print $2}')
    INSTALL_TXT=$(printf "%.64s" "${INSTALL_URL}")
    
    if [[ "${STATION_MODEL}" == "" && -a /boot/dietpi/.hw_model ]];then
        . /boot/dietpi/.hw_model
        STATION_MODEL=${G_HW_MODEL_NAME}
    fi

    printf "┌────────────────────────── Informace o systemu ───────────────────────────┐\n"
    printf "│ System: %-64s │\n" "${STATION_SYSTEM} - ${STATION_ARCH}"
    printf "│ Model: %-64s  │\n" "${STATION_MODEL} - ${STATION_MACHINE}"
    printf "│ URL: %-62s  v.%-1s │\n" "${INSTALL_TXT}" "${CFG_VERSION}"
    [[ "$1" == "end" ]] && printf "└──────────────────────────────────────────────────────────────────────────┘\n"
}

# Funkce zobrazi informace o vlastnikovy a umisteni
function info_user(){
    MAPY_URL="https://mapy.cz/?source=coor&id=${STATION_LON}%2C${STATION_LAT}"
    printf "%10.7f %10.7f" "${STATION_LAT}" "${STATION_LON}" 2> /dev/null > /dev/null 
    if [[ "$?" == "0" ]];then
        LAT=${STATION_LAT}
        LON=${STATION_LON}
    else
        LAT=$(echo ${STATION_LAT} | sed 's/\./,/')
        LON=$(echo ${STATION_LON} | sed 's/\./,/')
    fi
    printf "├───────────────────────── Identifikace zarizeni ──────────────────────────┤\n"
    printf "│ Identifikace zarizeni UUID: %-42s   │\n" "${STATION_UUID}"
    printf "│ Uzivatel: %-30s  Pojmenovani: %-17s │\n" "${USER_EMAIL}" "${STATION_NAME}"
    printf "│ Souradnice a nadmorska vyska umisteni prijimace:                         │\n"
    printf "│ Zem.sirka: %11.7f° Zem.delka: %11.7f°  Nadmorska vyska: %3d m  │\n" ${LAT} ${LON} "${STATION_ALT}"
    printf "│ Url adresa pro overeni umisteni (ctrl+lev.tlac mysi):                    │\n"
    printf "│ %72s │\n" ${MAPY_URL}
    [[ "$1" == "end" ]] && printf "└──────────────────────────────────────────────────────────────────────────┘\n"
}

# Funkce zobrazi seznam rtl-sdr zarizeni
function info_rtlsdr(){
    list_rtlsdr
    printf     "├─────────────────────────── RTL SDR zarizeni ─────────────────────────────┤\n"
    if [[ -s /tmp/rtlsdr.list ]];then
        grep "^ " /tmp/rtlsdr.list | awk -F, '{ printf "│        %2s    %-20s %-28s│\n", $1, $2, $3 }'
    else
        printf "│                  \e[38;5;208mZarizeni RTL SDR nebylo detekovano !\e[0m                    │\n"
    fi
    printf     "└──────────────────────────────────────────────────────────────────────────┘\n"
}

function collor_set(){
    X=$1
    C=$1
    if [[ "${X}" == "inactive" ]];then
        C=$(echo -en "\e[0;31m${X}\e[0m    ")
    elif [[ "${X}" == "active" ]];then
        C=$(echo -en "\e[1;32m${X}\e[0m      ")
    elif [[ "${X}" == "enabled" ]];then
        C=$(echo -en "\e[1;32m${X}\e[0m        ")
    elif [[ "${X}" == "disabled" ]];then
        C=$(echo -en "\e[0;31m${X}\e[0m       ")
    elif [[ "${X}" == "generated" ]];then
        C=$(echo -en "\e[0;33m${X}\e[0m      ")
    fi
}

# Funkce zjisti cely nazev sluzby a stav nekterych hodnot 
function info_ctl(){
#    IS_CTL=$(systemctl | awk '/'$1'.*\.service/ {print $1}' | awk -F. '{print $1}' | tr -d '\n')
#    IS_CTL=$(systemctl show $1.service | awk -F = '/^Names=/{print $2}' | tr -d '\n')
    IS_CTL=$(systemctl list-units --all --plain --no-legend | awk '/'$1'\.service/ {print $1}' | awk -F. '{print $1}' | tr -d '\n')
    if [[ -z ${IS_CTL} ]];then 
        systemctl status $1 &>/dev/null
        [[ "$?" != "4" ]] && IS_CTL=$1
    fi
    if [[ ! -z ${IS_CTL} ]];then
        IS_CTL_STATE=$(systemctl show ${IS_CTL}.service   | awk -F = '/UnitFileState=/{print $2}'  | tr -d '\n' )
        IS_CTL_PRESENT=$(systemctl show ${IS_CTL}.service | awk -F = '/UnitFilePreset=/{print $2}' | tr -d '\n' )
        IS_CTL_ACTIVE=$(systemctl show ${IS_CTL}.service  | awk -F = '/ActiveState=/{print $2}'    | tr -d '\n' )
        collor_set ${IS_CTL_STATE} && IS_CTL_STATE=${C}
        collor_set ${IS_CTL_PRESENT} && IS_CTL_PRESENT=${C}
        collor_set ${IS_CTL_ACTIVE} && IS_CTL_ACTIVE=${C}
        printf "│ %-27s %-15s %-16s %-12s │\n" "${IS_CTL}" "${IS_CTL_STATE}" "${IS_CTL_PRESENT}" "${IS_CTL_ACTIVE}"
    else
        IS_CTL=""
    fi
}

# Funkce zobrazi stav vybranych sluzeb
function info_components() {

    printf "┌ Komponenty / sluzby ─────── Po startu ──── Prednastaveni ── Status ──────┐\n"

    # Prefixy služeb, které chceme dynamicky zachytit
    # Stačí přidat prefix do pole
    if [[ "${READSB}" != "enable" ]];then
        local prefixes=("dump1090")
    else
        local prefixes=()
    fi
    local prefixes+=(
        "readsb*"
        "czadsb*"         # czadsb  
        "tar1090*"
        "adsbfwd"
        "adsbhub"         # adsbhub.org
        "adsbexchange*"   # adsbexchange.com
        "mlat-client*"
        "piaware"         # flightaware.com
        "fr24feed"        # flightradar24.com
        "lighttpd"
        "adsbfi"          # adsb.fi
        "airplanes"       # adsb.one
        "adsblol"         # adsb.lol
        "theairtraffic"   # theairtraffic.com
        "sdrmapfeeder"    # adsb.chaos-consulting.de
        "opensky-feeder"  # opensky-network.org
    )

    # Vyhledané služby (unikátní)
    local found_services=()

    # Najdi všechny systemd služby podle prefixů
    for prefix in "${prefixes[@]}"; do
        for svcfile in /etc/systemd/system/${prefix}.service /lib/systemd/system/${prefix}.service; do
            [[ -e "$svcfile" ]] || continue
            local svc="$(basename "$svcfile" .service)"

            # vynech duplicitní položky
            if [[ ! "${found_services[*]}" =~ "${svc}" ]]; then
                found_services+=("${svc}")
            fi
        done
    done

    # Pro každou nalezenou službu zavolej původní funkci info_ctl
    for service in "${found_services[@]}"; do
        info_ctl "$service"
    done

    # Pokud máš OGN, zachováno z původního kódu
    if [[ "${OGN}" == "disable" ]] || [[ "${OGN}" == "enable" ]]; then
        info_ctl "${OGN_NAME}"
    fi

    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
}

# Funkce zobrazi uvitani pro novou instalaci
function info_newinst(){
    printf "┌───────────────────────── Nastaveni / Instalace ──────────────────────────┐\n"
    printf "│ Nebyl nalezen konfuguracni soubor  czadsb.cfg,  pravdepodobne se jedna o │\n"
    printf "│ prvni spusteni tohoto  pruvodce.  Ten vas provede vlastnim nastavenim  a │\n"
    printf "│ instalaci pro preposilani dat ADSB na servery, nejen pro CzADSB projekt. │\n"
    printf "│ Pripadne je zde take moznost preposilat informace z OGN/Flarm ( vyzaduje │\n"
    printf "│ dalsi sdr-rtl klicenku z antenou na pasmo 868 MHz ).                     │\n"
    printf "│ Pozor: Drivejsi konfiguracni soubor  '/boot/czadsb-config.txt'  neni jiz │\n"
    printf "│        podporovan.  Pokud  chcete  hodnoty  prenastavit,  pouzite  tento │\n"
    printf "│        instalacni skript znovu nebo spusste prikaz 'czadsb'.             │\n"
    printf "│                                                                          │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    echo
}

# Funkce zobrazi nastavenou konfiguraci dalsich programu
function info_setting(){
    if [ ${ADSBFWD_DST} == "czadsb.cz:50000" ];then
        ADSBFWD_TXT=$(echo -en " \e[0;31mNASTAVTE PRIRAZENY PORT !\e[0m")
    else
        ADSBFWD_TXT=""
    fi
    printf "┌ Sluzba ───── Instalace ───────────── Nastaveni ──────────────────────────┐\n"
    if [[ ${CFG_VERSION} -eq 4 ]];then
    printf "│ ReADSB       %-10s dev: %-15s ppm: %-5d  gain: %4s dB   │\n" "${READSB}" "${READSB_DEV}" "${READSB_PPM}" "${READSB_GAIN}"
    printf "│              dst: %-53s  │\n" "${READSB_DST}  (${READSB_BCK})"
    else
    printf "│ Dump1090-fa  %-10s dev: %-15s ppm: %-5d  gain: %4s dB   │\n" "${DUMP1090}" "${DUMP1090_DEV}" "${DUMP1090_PPM}" "${DUMP1090_GAIN}"
    printf "│ ADSBfwd      %-10s dst: %-42s  │\n" "${ADSBFWD}" "${ADSBFWD_DST} ${ADSBFWD_TXT}"
    fi
    printf "│ Mlat         %-10s Server: %-40s │\n" "${MLAT}" "${MLAT_SERVER} -> ${MLAT_RESULT}"
    printf "│ VPN-CzADSB   %-10s url: %-19s Local: %-16s │\n" "${N2NADSB}" "${N2NADSB_SERVER}" "${N2NADSB_LOCAL}"
    printf "│ RpiMonitor   %-59s │\n" "${RPIMONITOR}"
    printf "│ Reporter     %-59s │\n" "${REPORTER}"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
}

# Funkce zobrazi ukonceni ..
function info_exit(){
    printf "┌────────────────────────── Ukonceni konfigurace ──────────────────────────┐\n"
    printf "│ Konfiguracni  skript  je  prave  ukoncen.  V pripade  potreby jej muzete │\n"
    printf "│ opetovne zpustit prikazem 'czadsb'.                                      │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
}

function info_install(){
    printf "┌─────────────────────── Zakladni nastaveni hotovo ────────────────────────┐\n"
    printf "│  Pro prvni instalaci je vse potrebne nastaveno. Bude nasledovat vlastni  │\n"
    printf "│                   instalace dle predchozi konfigurace.                   │\n"
    printf "│  Pokracujte klavesou enter ...                                           │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    input ""
}

# Funkce nabidne moznosti editace
function menu_edit(){
    printf "┌──────────────────────────── Uprava / editace ────────────────────────────┐\n"
    printf "│ 1. Identifikace (email, lokace)       a. ADSB servery tretich stran      │\n"
    printf "│ 2. Umisteni   (Souradnice a vyska)    b. Mlat-client (spousteni)         │\n"
    if [[ ${CFG_VERSION} -eq 4 ]];then
    printf "│ 3. ReADSB     (dev, ppm, gain, ...)   c. RpiMonitor  (spousteni)         │\n"
    printf "│ 4. RTL-SDR    (Serial number)         d. Reporter    (spousteni)         │\n"
    printf "│ 5. Tar1090 / Lighttpd                 s. Apt upgrade (spousteni)         │\n"
    else    
    printf "│ 3. Dump1090   (dev, ppm, gain)        c. RpiMonitor  (spousteni)         │\n"
    printf "│ 4. RTL-SDR    (Serial number)         d. Reporter    (spousteni)         │\n"
    printf "│ 5. ADSBfwd    (destinace, port)       x. Smaze konfig soubor - vyvoj     │\n"
    fi
    printf "│ 6. VPN-CzADSB (local IP)              u. Upgrade/preinstalace aplikace   │\n"
    printf "│ 7. OGN /Flarm (dev, ppm, gain)        v. Aplikuj zmeny + upgrade         │\n"
    printf "│ 9. Aplikuj zmeny                      r. Aplikuj zmeny a proved restart  │\n"
    printf "│ 0. Aplikuj zmeny a ukonci skript      q. Ukonci skript bez aplikace zmen │\n"
    printf "├──────────────────────────────────────────────────────────────────────────┘\n"
    input "* Vase volba [0 - d] ?" '^[0-9a-duvrqsx]$' ""
}

# Funkce nabidne moznosti ADSB serveru tretich stran 
function menu_third(){
    printf "┌─────────────────────── ADSB servery tretich stran ───────────────────────┐\n"
    printf "│ a. Piaware                      (https://www.flightaware.com)            │\n"
    printf "│ b. Flightradar24                (https://www.flightradar24.com)          │\n"
    printf "│ c. ADSBHub                      (https://www.adsbhub.org)              x │\n"
    printf "│ d. ADS-B Exchange               (https://www.adsbexchange.com/)          │\n"
    printf "│ e. adsb.fi                      (https://adsb.fi/)                     x │\n"
    printf "│ f. ADS-B One                    (https://adsb.one)                     x │\n"
    printf "│ h. TheAirTraffic                (https://theairtraffic.com)            x │\n"
    printf "│ i. adsb.chaos-consulting        (https://adsb.chaos-consulting.de)     * │\n"
    printf "│ j. Opensky Network              (https://opensky-network.org)          x │\n"
    printf "│   Poznamka:  Ve vystavbe, zatim podporovane jen nektere (neoznacene x)!  │\n"
    printf "│ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  │\n"
    printf "│ Aplikuj zmeny + upgrade  - v                                             │\n"
    printf "│ Zpet do hlavniho menu    - Enter                                         │\n"
    printf "├──────────────────────────────────────────────────────────────────────────┘\n"
    input "* Vase volba [a-d v] ?" '^[a-dv]{0,1}$' ""
}


# Funkce nabidne a nastavy rezim pruvodce instalace
function set_expert(){
    printf "┌─────────────────────── Rezim pruvodce instalaci ─────────────────────────┐\n"
    printf "│ Pro bezneho uzivatele doporucujeme spustit pruvodce v uzivatelsem rezimu │\n"
    printf "│ ktery obsahuje mene dotazu pri instalaci.  Tento rezim pak ale jiz nijak │\n"
    printf "│ neomezuje pripadnou editaci po instalaci.                                │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"

    input "Spustit pruvodce v uzivatelskem rezimu [Y/n] ?" '^[ynYN]*$' "y"
    if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
        EXPERT="user"
    else
        EXPERT="expert"
    fi
    echo
}

# Funkce nastavi, zda se ma provadet aktualizace systemu
function set_upgrade(){
    if [[ "${EXPERT}" != "user" ]];then
        printf "┌──────────────────── Aktualizace operacniho systemu  ─────────────────────┐\n"
        printf "│  Doporucuje se udrzovat  operacni system  aktualni. Pokud nastavite Auto │\n"
        printf "│  bude  pri  kazdem  ukonceni  skriptu  provedena  kontrola  s  pripadnou │\n"
        printf "│  aktualizace. Pokud  nastavyte Yes provede se jen  vramci  ukonceni, kdy │\n"
        printf "│  jset tuto volbu zadali.                                                 │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        if [[ "${STATION_UPGRADE}" == "enable" ]];then
            input "Provest aktualizaci systemu [a/Y/n]" '^[aynAYN]*$' "y"
        else
            input "Provest aktualizaci systemu [A/y/n]" '^[aynAYN]*$' "a" 
        fi
        [[ "$X" == "a" ]] || [[ "$X" == "A" ]] && STATION_UPGRADE="auto"
        [[ "$X" == "y" ]] || [[ "$X" == "Y" ]] && STATION_UPGRADE="enable" 
        [[ "$X" == "n" ]] || [[ "$X" == "N" ]] && STATION_UPGRADE="disable"
        [[ "${STATION_UPGRADE}" != "auto" ]] && [[ "${STATION_UPGRADE}" != "enable" ]] && [[ "${STATION_UPGRADE}" != "disable" ]] && STATION_UPGRADE="auto"
        echo
    else
        STATION_UPGRADE="enable"
    fi      
    UPDATE_UPGRADE=true
}

# Funkce nastavi identifikacni udaje zarizeni
function set_identifikace(){
    printf "┌───────────────────────── Identifikace zarizeni ──────────────────────────┐\n"
    printf "│ Sklada z emailu a pojmenovani vlastnoho  prijicace.  Pojmenovani by melo │\n"
    printf "│ mit maximalne 9 znaku a bez mezer.  Je potreba pro identifikaci zarizeni │\n"
    printf "│ mlat klienta a OGN.                                                      │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"

    input "Registracni email (email musi byt platny) [${USER_EMAIL}]:" '^[a-zA-Z0-9_\.\-]*@[a-z0-9_\.\-]*\.[a-z]*$' "${USER_EMAIL}" 
    USER_EMAIL=${X}

    if [[ "${OGN}" == "disable" ]] || [[ "${OGN}" == "enable" ]];then
        input "Oznaceni / pojmenovani prijimace [${STATION_NAME}]:" '^[a-zA-Z0-9_\.\-]{3,9}$' "${STATION_NAME}"
    else
        input "Oznaceni / pojmenovani prijimace [${STATION_NAME}]:" '^[a-zA-Z0-9_\.\-]{3,27}$' "${STATION_NAME}"
    fi
    STATION_NAME=${X}

    UPDATE_MLAT=true
    UPDATE_OGN=true
    echo
}

# Funkce nastavi lokalizaci - umisteni zarizeni
function set_lokalizace(){
    printf "┌─────────────────────────── Umisteni zarizeni ────────────────────────────┐\n"
    printf "│ Urcuje umisteni zarizeni,  lepe receno  vlastni anteny.  Tyto udaje jsou │\n"
    printf "│ dulezite pro spravny vypocet poloh letadel pomoci mlat klienta. Zadavaji │\n"
    printf "│ se v zemepisne sirce a delce ve stupnich na minimalne 6 desetinych mist, │\n"
    printf "│ kde oddelovac je tecka, nikoliv carka.                                   │\n"
    printf "│ Nadmorska  vyska  se  zadava v metrech  nad  morem.  K zjistene vysce je │\n"
    printf "│ potreba jeste pripocitat umisteni anteny nad zemi.                       │\n"
    printf "│ Zemepisne  souradnice jsme schpni zjistit treba na webu https://mapy.cz. │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"

    while true; do
        input "Zemepisna sirka umisteni prijimace ve stupnich (XX.xxxxxx) [${STATION_LAT}]°:" '^[0-9\-]{0,4}\.[0-9]{5,8}$' "${STATION_LAT}"
        STATION_LAT=${X}
        input "Zemepisna delka umisteni prijimace ve stupnich (YY.yyyyyy) [${STATION_LON}]°:" '^[0-9\-]{0,4}\.[0-9]{5,8}$' "${STATION_LON}"
        STATION_LON=${X}

        MAPY_URL="https://mapy.cz/?source=coor&id=${STATION_LON}%2C${STATION_LAT}"
        echo
        echo "Prosim overte pomoci nize zobrazeneho odkazu spravnost zadanych souradnic:"
        echo ${MAPY_URL}
        input "Jsou zadane souradnice platne [y/N]" '^[ynYN]*$' "n"
        if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
            break
        fi
        echo
    done

    input "Nadmorska vyska umisteni přijímací antény v metrech [${STATION_ALT}]m :" '^[0-9\.\-]*$' "${STATION_ALT}"
    STATION_ALT=${X}

    UPDATE_DUMP1090=true
    UPDATE_READSB=true
    UPDATE_MLAT=true
    echo
}

# Funkce overi dump1090 a nastavi hodnoty
function set_dump1090(){
    if [[ "${DUMP1090}" != "enable" ]] && [[ "${DUMP1090}" != "disable" ]];then
        check=`netstat -tln | grep 30005`
        [[ ${#check} -ge 10 ]] &&  DUMP1090="install"
        command -v readsb &>/dev/null &&  DUMP1090="install"
        command -v dump1090 &>/dev/null &&  DUMP1090="install"
        command -v dump1090-fe &>/dev/null &&  DUMP1090="ninstall"
        [[ -z ${DUMP1090} ]] && DUMP1090="enable"
    fi
    if [[ "${DUMP1090}" != "enable" ]] && [[ "${DUMP1090}" != "disable" ]] && [[ "${DUMP1090}" != "install" ]];then
        DUMP1090="enable"
    fi    
    if [[ "${READSB}" =~ "enable" ]] || [[ "${READSB}" =~ "disable" ]];then
        [[ -z ${ADSBFWD_TYPE} ]] && ADSBFWD_TYPE="readsb"
    fi
    printf     "┌────────────────────────────── Dump1090-fa ───────────────────────────────┐\n"
    if [[ "${DUMP1090}" == "install"  ]];then
        printf "│ Na zarizeni byl detekovan program dump1090(fa) instalovany treti stranou.│\n"
        printf "│   Takto nainstalovany dump1090 neni mozne timto skriptem konfigurovat.   │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    else
        printf "│ Dump1090  zpracovava data z RTL-SDR 'klicenky' a dekoduje  vlastni  ADSB │\n"
        printf "│ spravy ktere se dale  preposilaji.  Take  umoznuje  zobrazit pres webove │\n"
        printf "│ rozhrani vlastni  pozice letadel ktere prijima.  Tato komponenta se bude │\n"
        printf "│ instalovat automaticky.                                                  │\n"
        list_rtlsdr
        if [[ ${RTL_SDR} -gt 1 ]];then
            printf "│                                                                          │\n"
            printf "│ Na zarizeni bylo detekovano vice RTL SDR zarizeni:                       │\n"
            info_rtlsdr
            RTL_SDR=$(( ${RTL_SDR} - 1 ))
            input "Vyberte ktera se ma pouzita pro dump1090 a to bud podle ID (0 az ${RTL_SDR}) nebo SN [${DUMP1090_DEV}]:" '^[0-9]*$' "${DUMP1090_DEV}"
            DUMP1090_DEV=$X
        else
            printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        fi
        if [[ "${EXPERT}" != "user" ]];then
            input "Nastaveni korekce ppm pro RTL-SDR (pokud nevite, ponechte) [${DUMP1090_PPM}]:" '^[-0-9]*$' "${DUMP1090_PPM}"
            DUMP1090_PPM=${X}
            input "Nastaveni zesileni pro RTL-SDR (pokud nevite, ponechte prazdne) [${DUMP1090_GAIN}]:" '^[0-9\.]*$' "${DUMP1090_GAIN}"
            DUMP1090_GAIN=${X}
        fi

        UPDATE_DUMP1090=true
    fi
    echo
}

# Funkce overi ReADSB a nastavi hodnoty
function set_readsb(){
    if [[ "${READSB}" != "enable" ]] && [[ "${READSB}" != "disable" ]];then
        check=`netstat -tln | grep 30005`
        [[ ${#check} -ge 10 ]] &&  READSB="install"
        command -v readsb &>/dev/null &&  READSB="install"
        command -v dump1090 &>/dev/null &&  READSB="install"
        command -v dump1090-fe &>/dev/null &&  READSB="ninstall"
    fi
    if [[ "${READSB}" != "enable" ]] && [[ "${READSB}" != "disable" ]] && [[ "${READSB}" != "install" ]];then
        READSB="enable"
    fi    
    if [[ "${READSB}" =~ "enable" ]] || [[ "${READSB}" =~ "disable" ]];then
        ADSBFWD_TYPE="direct"
    fi
    printf     "┌───────────────────────────────── ReADSB ─────────────────────────────────┐\n"
    if [[ "${READSB}" == "install"  ]];then
        printf "│ Na  zarizeni  byl  detekovan  program  Dump1090  nebo  ReADSB. V takovem │\n"
        printf "│ pripade neni  mozne  ReADSB  spravovat  tímto  skryptem, protoze  by  to │\n"
        printf "│ narusilo  stavajici  stav  zarizeni. Prosim  pridejte  primo  parametr k │\n"
        printf "│ zasilani dat na CzADSB, nebo pouzite sluzbu adsbfwd pro predavani dat na │\n"
        printf "│ na CzADSB.    Dekujiem                                                   │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        input "Pro pokracovabi stisknete ENTER ..." '' ""
    else
        printf "│ ReADSB plne nahrazuje drivejsi DUMP1090.  Zpracovava data z RTL klicenky │\n"
        printf "│ a zaroven  tyto  data  posila na  projekt  CzADSB k dalsimu  spracovani. │\n"
        printf "│ Zaroven je mozne na standartnim portu 30005 tyto data cist a preposilat  │\n"
        printf "│ dalsim projektum, joko napriklad FR24, ADSB.lol, ...                     │\n"
        printf "│ Tato  komponenta  se  bude  take instalovat automaticky.                 │\n"
        list_rtlsdr
        if [[ ${RTL_SDR} -gt 1 ]];then
            printf "│                                                                          │\n"
            printf "│ Na zarizeni bylo detekovano vice RTL SDR zarizeni:                       │\n"
            info_rtlsdr
            RTL_SDR=$(( ${RTL_SDR} - 1 ))
            input "Vyberte ktera se ma pouzita pro dump1090 a to bud podle ID (0 az ${RTL_SDR}) nebo SN [${DUMP1090_DEV}]:" '^[0-9]*$' "${READSB_DEV}"
            READSB_DEV=$X
        else
            printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        fi
        if [[ "${EXPERT}" != "user" ]];then
            input "Nastaveni korekce ppm pro RTL-SDR (pokud nevite, ponechte) [${READSB_PPM}]:" '^[-0-9]*$' "${READSB_PPM}"
            READSB_PPM=${X}
            input "Nastaveni zesileni pro RTL-SDR (pokud nevite, ponechte prazdne) [${READSB_GAIN}]:" '^[auto0-9\.]*$' "${READSB_GAIN}"
            READSB_GAIN=${X}
            input "Zadejte adresy a port (oddeleny carkou) kam se primarne maji data posilat [${READSB_DST}]:" '^[a-zA-Z0-9_\.,\-\ ]*$' "${READSB_DST}"
            READSB_DST=${X}
            input "Zadejte adresy a port (oddeleny carkou) zalozniho serveru pro zasilani dat [${READSB_BCK}]:" '^[a-zA-Z0-9_\.,\-\ ]*$' "${READSB_BCK}"
            READSB_BAC=${X}
            input "Zde muzete nastavit specialni paramatery pro ReADSB (prosim jen tehdy, pokud vite co delate!) [${READSB_OPT}]:" '' "${READSB_OPT}"
            READSB_OPT=${X}
        fi
        UPDATE_READSB=true
        UPDATE_LIGHTTPD=true
    fi    
    echo
}

# Funkce overi adsbfwd a nastavi hodnoty
function set_adsbfwd(){
    ADSBFWD_TYPE="adsbfwd"
    printf "┌──────────────────────────────── ADSBfwd ─────────────────────────────────┐\n"
    printf "│ ADSBfwd  preposila  ADSB  data z dump1090 komunite CzADSB.  Muze zaroven │\n"
    printf "│ preposilat i na jine, podobne projekty. Tato  komponenta  se  bude  take │\n"
    printf "│ instalovat automaticky.                                                  │\n"
    printf "│    (Prirazený port najdete na zaslane screene pri registraci na CzADSB.) │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    [[ -z ${ADSBFWD} ]] && ADSBFWD="enable"
    if [[ "${EXPERT}" != "user" ]];then
        if [[ "${ADSBFWD}" != "enable" ]] && [[ "${ADSB}" != "disable" ]];then
            if [[ "${ADSBFWD}" == "notinstall" ]];then
                input "Instalovat ADSBfwd pro preposilani ADSB dat ? [y/N]:" '^[ynYN]*$' "n"
            else
                input "Instalovat ADSBfwd pro preposilani ADSB dat ? [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                ADSBFWD="notinstall"
            else
                ADSBFWD="enable"
            fi
        fi
    fi
    if [[ "${ADSBFWD}" =~ "disable" ]] || [[ "${ADSBFWD}" =~ "enable" ]];then
        if [[ "${EXPERT}" != "user" ]];then
            if [[ "${ADSBFWD}" == "diseble" ]];then
                input "Ma se ADSBfwd spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
            else
                input "Ma se ADSBfwd spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                ADSBFWD="disable"
            else
                ADSBFWD="enable"
            fi
        fi
        input "Zadejte port, nebo seznam serveru kam se data posilaji [${ADSBFWD_DST}]:" '^[a-zA-Z0-9_\.\-\:\ ]*$' "${ADSBFWD_DST}"
        if [[ ${X} =~ ":" ]];then
            ADSBFWD_DST=${X}
        else
            ADSBFWD_DST="czadsb.cz:${X}"
        fi
        UPDATE_ADSBFWD=true
    fi
    echo
}

# Funkce overi adsbfwd a nastavi hodnoty
function set_adsbfwd2(){
    ADSBFWD_TYPE="readsb"
    printf "┌─────────────────────────────── ADSBfwd2 ─────────────────────────────────┐\n"
    printf "│ ADSBfwd  preposila  ADSB  data z dump1090 komunite CzADSB.  Muze zaroven │\n"
    printf "│ preposilat i na jine, podobne projekty. Tato  komponenta  se  bude  take │\n"
    printf "│ instalovat automaticky.                                                  │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    [[ -z ${ADSBFWD} ]] && ADSBFWD="enable"
    if [[ "${EXPERT}" != "user" ]];then
        if [[ "${ADSBFWD}" != "enable" ]] && [[ "${ADSB}" != "disable" ]];then
            if [[ "${ADSBFWD}" == "notinstall" ]];then
                input "Instalovat ADSBfwd pro preposilani ADSB dat ? [y/N]:" '^[ynYN]*$' "n"
            else
                input "Instalovat ADSBfwd pro preposilani ADSB dat ? [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                ADSBFWD="notinstall"
            else
                ADSBFWD="enable"
            fi
        fi
    fi
    if [[ "${ADSBFWD}" =~ "disable" ]] || [[ "${ADSBFWD}" =~ "enable" ]];then
        if [[ "${EXPERT}" != "user" ]];then
            if [[ "${ADSBFWD}" == "diseble" ]];then
                input "Ma se ADSBfwd spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
            else
                input "Ma se ADSBfwd spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                ADSBFWD="disable"
            else
                ADSBFWD="enable"
            fi
        fi
        if [[ "${EXPERT}" != "user" ]];then
            input "Zadejte adresy a port (oddeleny carkou) kam se primarne maji data posilat [${READSB_DST}]:" '^[a-zA-Z0-9_\.\-\ ]*$' "${ADSBFWD_DST}"
            ADSBFWD_DST=${X}
            input "Zadejte adresy a port (oddeleny carkou) zalozniho serveru pro zasilani dat [${READSB_BCK}]:" '^[a-zA-Z0-9_\.\-\ ]*$' "${READSB_BCK}"
            ADSBFWD_BAC=${X}
            input "Zde muzete nastavit specialni paramatery pro ReADSB (prosim jen tehdy, pokud vite co delate!) [${READSB_OPT}]:" '^[a-zA-Z0-9_\.\-\ ]*$' "${ADSBFWD_OPT}"
            ADSBFWD_OPT=${X}
            [[ "${ADSBFWD_OPT}" == " " ]] && ADSBFWD_OPT=""
        fi
        UPDATE_ADSBFWD=true
    fi
    echo
}

# Funkce overi mlatclient a nastavi hodnoty
function set_mlat(){
    printf "┌────────────────────────────── Mlat-client ───────────────────────────────┐\n"
    printf "│ Malt-client  pridava  casovou  znacku ke zpravam bez GPS udajum a posila │\n"
    printf "│ na MLAT server. Ten  na zaklade rozdilu casovych znacek od dalsich darcu │\n"
    printf "│ vypocita polohu letadla. I tato komponenta se instaluje automaticky.     │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    [[ -z ${MLAT} ]] && MLAT="enable"
    if [[ "${EXPERT}" != "user" ]];then
        if [[ "${MLAT}" != "enable" ]] && [[ "${MLAT}" != "disable" ]];then
            if [[ ${MLAT} == "notinstall"  ]];then
                input "Instalovat MLAT client pro vypocet polohy letadla ? [y/N]:" '^[ynYN]*$' "n"
            else
                input "Instalovat MLAT client pro vypocet polohy letadla ? [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                MLAT="notinstall"
            else
                MLAT="enable"
            fi
        fi
        if [[ "${MLAT}" =~ "disable" ]] || [[ "${MLAT}" =~ "enable" ]];then
            if [[ "${MALT}" == "diseble" ]];then
                input "Ma se MLAT client spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
            else
                input "Ma se MLAT client spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                MLAT="disable"
            else
                MLAT="enable"
            fi
        fi
    fi
    UPDATE_MLAT=true
    echo
}

# Funkce nastavi reporter dat
function set_tar1090(){
    printf "┌─────────────────────────── Tar1090 & Lighttpd ───────────────────────────┐\n"
    printf "│ Tar1090 z Lighttpd umoznuje zobrazeni zive mapy z letadly primo na vasem │\n"
    printf "│ zarizeni. Pokud  ale budete sledovat letadla jen na mape CzADSB,  nejsou │\n"
    printf "│ tyto komponety potreba instalovat. To  doporucujeme pro stare Rasperi ci │\n"
    printf "│ SD karty.                                                                │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    if [[ "${TAR1090}" != "enable" ]] && [[ "${TAR1090}" != "disable" ]];then
        if [[ -z ${TAR1090} ]] || [[ ${TAR1090} == "notinstall" ]];then
            input "Instalovat Tar1090 a Lighttpd pro lokalni zobrazeni letadel ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat Tar1090 a Lighttpd pro lokalni zobrazeni letadel ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            TAR1090="notinstall"
            if [[ "${LIGHTTPD}" =~ "disable" ]] || [[ "${LIGHTTPD}" =~ "enable" ]];then
                LIGHTTPD="notinstall"
            fi
        else
            TAR1090="enable"
            LIGHTTPD="enable"
        fi
    fi
    if [[ "${EXPERT}" != "user" ]];then
        if [[ "${LIGHTTPD}" =~ "disable" ]] || [[ "${LIGHTTPD}" =~ "enable" ]];then
            if [[ "${LIGHTTPD}" == "diseble" ]];then
                input "Ma se Lighttpd spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
            else
                input "Ma se Lighttpd spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                LIGHTTPD="disable"
            else
                LIGHTTPD="enable"
            fi
            UPDATE_TAR1090=true
            UPDATE_LIGHTTPD=true
        fi
    fi
    echo
}

# Funkce nastavi zda instalovat RpiMonitor
function set_rpimonitor(){
    check=`cat /proc/cpuinfo | grep Raspberry`
    if [[ "${check}" == "" ]];then
        RPIMONITOR=""
    else
        printf "┌─────────────────────────────── RpiMonotor ───────────────────────────────┐\n"
        printf "│ RpiMonitor umoznuje pres webove rozhrani sledovat aktualni stav Raspberry│\n"
        printf "│ PI.  Pokud system  bezi  na  Raspberry v.3 a novejší,  můzete si monitor │\n"
        printf "│ nainstalovat. Nejedna se o klicovou komponentu a zatezuje SD kartu.      │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        if [[ "${EXPERT}" == "user" ]];then
            [[ "${RPIMONITOR}" != "enable" ]] && [[ "${RPIMONITOR}" != "disable" ]] && UPDATE_RPIMONITOR=true
            RPIMONITOR="notinstall"
        else
            if [[ "${RPIMONITOR}" != "enable" ]] && [[ "${RPIMONITOR}" != "disable" ]];then
                if [[ ${RPIMONITOR} == "notinstall"  ]];then
                    input "Instalovat Rpi Monitor ? [y/N]:" '^[ynYN]*$' "n"
                else
                    input "Instalovat Rpi Monitor ? [Y/n]:" '^[ynYN]*$' "y"
                fi
                if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                    RPIMONITOR="notinstall"
                else
                    RPIMONITOR="enable"
                fi
            fi
            if [[ "${RPIMONITOR}" =~ "disable" ]] || [[ "${RPIMONITOR}" =~ "enable" ]];then
                if [[ "${RPIMONITOR}" == "diseble" ]];then
                    input "Ma se Rpi Monitor spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
                else
                    input "Ma se Rpi Monitor spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
                fi
                if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                    RPIMONITOR="disable"
                else
                    RPIMONITOR="enable"
                fi
            fi
            UPDATE_RPIMONITOR=true
        fi
    fi
    echo
}

# Funkce nastavi n2n vpn pro CzADSB
function set_n2nvpn(){
    printf "┌─────────────────────────────── VPN-CzADSB ───────────────────────────────┐\n"
    printf "│ VPN-CzADSB je VPN postavena na n2n edge. Je urcena pro admin tym aby mel │\n"
    printf "│ pripadnou  moznost  vzdaleneho  pristupu  ze  spracovskych PC.  Tim jsou │\n"
    printf "│ schopni  lepe  vyresit  pripadne  problemy  z  instalaci  a  konfiguraci │\n"
    printf "│ zarizeni.   Proto   doporucujeme   VPN   nainstalovat.  Pokud  ale  mate │\n"
    printf "│ pochybnosti,  nastavte aby se VPN nespoustela automaticky.               │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    if [[ "${N2NADSB}" != "enable" ]] && [[ "${N2NADSB}" != "disable" ]];then
    if [[ -z ${N2NADSB} ]];then
            input "Instalovat VPN edgo pro vzdaleny pristup ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat VPN edgo pro vzdaleny pristup ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            N2NADSB="notinstall"
        else
            N2NADSB="enable"
        fi
    fi
    if [[ "${N2NADSB}" =~ "disable" ]] || [[ "${N2NADSB}" =~ "enable" ]];then
        if [[ "${EXPERT}" != "user" ]];then
            if [[ "${N2NADSB}" == "diseble" ]];then
                input "Ma se VPN Edge CzADSB spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
            else
                input "Ma se VPN Edge CzADSB spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                N2NADSB="disable"
            else
                N2NADSB="enable"
            fi
        fi
        echo  "Lokalni IP adrtesa VPN prirazena komunitou CzADSB."
        input "Pokud ji zatim nemate, ponechte prazdne. [${N2NADSB_LOCAL}]:" '^[0-9\.]*$' "${N2NADSB_LOCAL}" 
        N2NADSB_LOCAL=${X}
        if [[ ${N2NADSB_LOCAL} == "" ]];then
            N2NADSB_LOCAL=$(curl -s "https://user.czadsb.cz/get_free_ip.php?device=${STATION_NAME}")
        fi

        UPDATE_N2NVPN=true
    fi
    echo
}


# Funkce nastavi reporter dat
function set_reporter(){
    printf "┌──────────────────────────────── Reporter ────────────────────────────────┐\n"
    printf "│ Reporter zasila statisticke a provozni data na server  CzADSB  pro lepsi │\n"
    printf "│ sledovani  stavu  jednotlivych  zarizeni. Toto neni povinna komponenta a │\n"
    printf "│ zpristupneni vyse zminenych dat je jen na vas. Zatim jen test.           │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    if [[ "${REPORTER}" != "enable" ]] && [[ "${REPORTER}" != "disable" ]];then
        if [[ -z ${REPORTER} ]];then
            input "Instalovat Reporter pro zasilani dat ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat Reporter pro zasilani dat ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            REPORTER="notinstall"
        else
            REPORTER="enable"
        fi
    fi
    if [[ "${REPORTER}" =~ "disable" ]] || [[ "${REPORTER}" =~ "enable" ]];then
        if [[ "${EXPERT}" != "user" ]];then
            if [[ "${REPORTER}" == "disable" ]];then
                input "Ma se Reporter spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
            else
                input "Ma se Reporter spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
            fi
            if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
                REPORTER="disable"
            else
                REPORTER="enable"
            fi
        fi
        UPDATE_REPORTER=true
    fi
    echo
}

# Funkce vytvori kratky skript pro spousteni pruvodce
function set_czadsb(){
    INSTALL_FILE="/usr/bin/czadsb"
    if [ ! -s ${INSTALL_FILE} ];then
        $SUDO touch ${INSTALL_FILE}
    fi
    $SUDO chmod 666 ${INSTALL_FILE}
/bin/cat <<EOM > ${INSTALL_FILE}
#!/bin/bash
# Jednoduchy odkaz pro snadnejsi spusteni pruvodce, konfigurace
cd ~        
bash -c "\$(wget -q -O - $( echo ${INSTALL_URL} | sed 's/\/install//g' )/install-czadsb.sh)"
EOM
    $SUDO chmod 755 ${INSTALL_FILE}
}
 
# Funkce zmeni seriova cisla rtl-sdr zarizeni
function set_rtl_sn(){
    while true; do
        printf "┌──────────────────── Nastaveni SN na rtl-sdr zarizeni ────────────────────┐\n"
        printf "│ POZOR: Zmena serioveho cisla je zasahem primo do rtl-sdr zarizeni !      │\n"
        printf "│           Veskere tyto zmeny jsou jen na vlastni nebezpeci !             │\n"
        printf "│          SN lze menit jen na nevyuzivanem rtl-sdr zarizeni !             │\n"
        printf "│                                                                          │\n"
        printf "│  Tato zmena je vhodna jen v pripade vice rtl-sdr na jednom zarizeni a    │\n"
        printf "│  projevi se az po odpojeni a znovuzapojeni  rtl-sdr nebo po restartu.    │\n"
        printf "│ Vyberte ID rtl-sdr zarizeni pro ktere chcete zmenit seriove cislo (SN).  │\n"
        printf "│                                                                          │\n"
        printf "│        Ukonceni nastaveni SN provedete prazdnou volbou (enter)           │\n"
        printf "│                                                                          │\n"
        info_rtlsdr

        input "Vyberte ID rtl-sdr pro ktere chcete zmenit SN [0 - ..] :" '^[0-9]{0,1}$' ""
        [[ ${X} == "" ]] && return
        echo
        if [[ ${X} -lt ${RTL_SDR} ]];then
            DEV=${X}
            echo "Vybrane rtl-sdr zarizeni:"
            cat /tmp/rtlsdr.list | grep "${DEV}:"
            echo
            input "Pokracovat s timto rtl-sdr zarizenim [Y/n]:" '^[ynYN]*$' "y"
            echo
            if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
                echo "Zadejte nove seriove cislo (SN) v delce 4 az 8 znaku."
                input "Povolene znaky jsou cisla, ASCI abeceda, pomlcka :" '^[0-9a-zA-Z\-]{3,9}$' "00000001"
                rtl_eeprom -d ${DEV} -s ${X}
                echo
                printf "┌───────────────────────────────── POZOR ──────────────────────────────────┐\n"
                printf "│   Zmena SN se projevi az po odpojeni a znovuzapojeni rtl-sdr zarizeni,   │\n"
                printf "│                    nebo po restartu celeho zarizeni !                    │\n"
                printf "│   Pokracujte klavesou enter ...                                          │\n"
                printf "└──────────────────────────────────────────────────────────────────────────┘\n"
                input ""
                UPDATE_DUMP1090=true
                UPDATE_OGN=true
            fi
        else
            echo "Error:"
            input "  Neplatna volba ID '${X}' !  Pokracijte entrem ..."
        fi
        clear
        info_logo
    done
}

# Funkce nastavi paramatru pro OGN / Flarm
function set_ogn(){
    printf "┌────────────────────────────── OGN / Flarm ───────────────────────────────┐\n"
    printf "│ OGN/Flarm pouzivaji mala letadla, zejmena ktera nemusi mit vysilac ADSB. │\n"
    printf "│ Vyuziva se tim padem pro vetrone, balony, mala motorova letadla,... Jeho │\n"
    printf "│ vyhodou je,  ze  nespada  pod  letecky  urad a tudiz i jeho  porizeni je │\n"
    printf "│ levnejsi. Pracuje v pasmu 868 MHz,  proto je pro nej potreba  samostatne │\n"
    printf "│ rtl-sdr zarizeni a antena.                                               │\n"
    printf "│                                                                          │\n"
    list_rtlsdr
    if [[ ${RTL_SDR} -gt 1 ]];then
        printf "│ Na zarizeni byly detekovano RTL SDR zarizeni:                            │\n"
        info_rtlsdr
        RTL_SDR=$(( ${RTL_SDR} - 1 ))
        input "Vyberte ktera se ma pouzita pro OGN/Flarm a to bud podle ID (0 az ${RTL_SDR}) nebo SN [${OGN_DEV}]:" '^[0-9\-]{1,9}$' "${OGN_DEV}"
        OGN_DEV=$X
    else
        printf "│ Na zarizeni neni detekovan dostatek  rtl-sdr  zarizeni.  To muze vest ke │\n"
        printf "│ konfliktu z jinymi  programy,  napriklad  dump1090.  Proto  zvazte,  zda │\n"
        printf "│ skutecne OGN / Flarm instalovat. V tomto pripade NEDOPORUCUJEME !        │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    fi
    if [[ "${OGN}" != "enable" ]] && [[ "${OGN}" != "disable" ]];then
        if [[ -z ${OGN} ]];then
            input "Instalovat OGN / Flarm prijimac ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat OGN / Flarm prijimac ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            OGN="notinstall"
        else
            OGN="enable"
        fi
    fi
    if [[ "${OGN}" =~ "disable" ]] || [[ "${OGN}" =~ "enable" ]];then
        if [[ "${OGN}" == "diseble" ]];then
            input "Ma se OGN / Flarm spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
        else
            input "Ma se OGN / Flarm spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            OGN="disable"
        else
            OGN="enable"
        fi
        input "Nastaveni korekce ppm pro RTL-SDR (pokud nevite, ponechte) [${OGN_PPM}]:" '^[-0-9]*$' "${OGN_PPM}"
        OGN_PPM=${X}
        input "Nastaveni zesileni pro RTL-SDR (pokud nevite, ponechte) [${OGN_GAIN}]:" '^[0-9\.]*$' "${OGN_GAIN}"
        OGN_GAIN=${X}
        UPDATE_OGN=true
        UPDATE_LIGHTTPD=true
    fi
}

# Funkce nastavi paramatru pro PiAware / FlightAware
function set_piaware(){
    printf "┌───────────────────────── PiAware / FlightAware ──────────────────────────┐\n"
    printf "│ PiAware umozni predavat data  na  server  https://www.flightaware.com .  │\n"
    printf "│ Jako  poskytovatel dat muzete  ziskat bezplatny ucet na teto platforme a │\n"
    printf "│ porovnata vase data z ostatnimi.                                         │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    if [[ "${PIAWARE}" != "enable" ]] && [[ "${PIAWARE}" != "disable" ]];then
        if [[ -z ${PIAWARE} ]];then
            input "Instalovat PiAware ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat PiAware ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            PIAWARE="notinstall"
        else
            PIAWARE="enable"
        fi
    fi
    if [[ "${PIAWARE}" =~ "disable" ]] || [[ "${PIAWARE}" =~ "enable" ]];then
        if [[ "${PIAWARE}" == "diseble" ]];then
            input "Ma se PiAware spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
        else
            input "Ma se PiaWare spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            PIAWARE="disable"
        else
            PIAWARE="enable"
        fi
        if [[ "${PIAWARE_UI}" == "" ]] && [[ -n "/run/piaware/status.json" ]];then
            PIAWARE_UI=$(awk -F\" '/unclaimed_feeder_id/ {print $4}' /run/piaware/status.json)
        fi
        if [[ "${PIAWARE_UI}" == "" ]] && [[ -n $(command -v piaware-config) ]];then
            PIAWARE_UI=$($SUDO piaware-config -show feeder-id)
        fi
        echo
        printf "┌────────────────────────────── FlightAware ───────────────────────────────┐\n"
        printf "│ FlightAware pro rozliseni prijimacu  pouziva unikatni idendifikator. Ten │\n"
        printf "│ je  jedinecny  pro  kazde  zarizeni a generuje se  automaticky  pro nove │\n"
        printf "│ prijmace.  Pokud  vsak  provadime  preinstalaci  stavajiciho,  je  dobre │\n"
        printf "│ nastavit tento kod pro automaticke sparovani na strane FlightAware.  Kod │\n"
        printf "│ v tomto  pripade  najdeme  pod  svym  uctem  na  strankach  FlightAware. │\n"

        if [[ -n ${PIAWARE_UI} ]];then
            printf "│                                                                          │\n"
            printf "│    Na zarizeni byl nalezen kod: '${PIAWARE_UI}'      │\n"
        else
            printf "│    ( Pro novou instalaci ponechte prazdne, doplni se automaticky ! )     │\n"
        fi
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        input "UI [${PIAWARE_UI}]:" '^[-0-9abcdef]{36}*$' "${PIAWARE_UI}"
        PIAWARE_UI=${X}
        UPDATE_PIAWARE=true
    fi
}

# Funkce nastavi paramatru pro Flightradar24 - fr24
function set_fr24(){
    printf "┌───────────────────────── Flightradar24 / FR24 ───────────────────────────┐\n"
    printf "│ Flightradar24 ( https://www.flightradar24.com ) umozni predavat  data na │\n"
    printf "│ profesionalni server. Jako poskytovatel dat muzete ziskat bezplatny ucet │\n"
    printf "│ na teto platforme a sledovat letovy provoz celeho sveta.                 │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    if [[ "${FR24}" != "enable" ]] && [[ "${FR24}" != "disable" ]];then
        if [[ -z ${FR24} ]];then
            input "Instalovat Flightradar24 ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat Flightradar24 ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            FR24="notinstall"
        else
            FR24="enable"
        fi
    fi
    if [[ "${FR24}" =~ "disable" ]] || [[ "${FR24}" =~ "enable" ]];then
        if [[ "${FR24}" == "diseble" ]];then
            input "Ma se Flightradar24 spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
        else
            input "Ma se Flightradar24 spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            FR24="disable"
        else
            FR24="enable"
        fi
        printf "┌───────────────────────────── Flightradar24 ──────────────────────────────┐\n"
        printf "│ Pri nove instalaci bude nasledovat  spusteni registrace noveho prijimace │\n"
        printf "│ na fr24.  V pripade  preinstalovani,  doporucujeme  pouzit jiz stavajici │\n"
        printf "│ zdileny klic (Sharing key). Ten naleznete na strance:                    │\n"
        printf "│                       https://www.flightradar24.com/account/data-sharing │\n"
        if [[ -n ${FR24_KEY} ]];then
            printf "│                                                                          │\n"
            printf "│          Na tomto zarizeni byl nalezen kod '${FR24_KEY}'.           │\n"
        fi
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        if [[ "${FR24_KEY}" == "" ]];then
            input "Pouzit stavajici zdileny klic (Sharing key) FR24 ? [y/N]" '^[ynYN]*$' "n"
        else
            input "Pouzit stavajici zdileny klic (Sharing key) FR24 ? [Y/n]:" '^[ynYN]*$' "y"
        fi
        if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
            input "Zadejte zdileny klic (Sharing key) prijmace [${FR24_KEY}]:" '^[0-9abcdef]{16}$' "${FR24_KEY}"
            FR24_KEY=$X
        else
            FR24_KEY=""
        fi
        UPDATE_FR24=true
    fi
}

# Funkce nastavi paramatru pro adsbexchange
function set_adsbexchange(){
    printf "┌──────────────────────────── ADS-B Exchange ──────────────────────────────┐\n"
    printf "│ 'ADS-B Exchange' je dalsi serve sledujici letecky provoz po celem svete. │\n"
    printf "│ Data jsou pak dostupna na adrese https://www.adsbexchange.com/           │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    if [[ "${ADSBEXCHANGE}" != "enable" ]] && [[ "${ADSBEXCHANGE}" != "disable" ]];then
        if [[ -z ${ADSBEXCHANGE} ]];then
            input "Instalovat ADS-B Exchange ? [Y/n]:" '^[ynYN]*$' "y"
        else
            input "Instalovat ADS-B Exchange ? [y/N]:" '^[ynYN]*$' "n"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            ADSBEXCHANGE="notinstall"
        else
            ADSBEXCHANGE="enable"
        fi
    fi
    if [[ "${ADSBEXCHANGE}" =~ "disable" ]] || [[ "${ADSBEXCHANGE}" =~ "enable" ]];then
        if [[ "${ADSBEXCHANGE}" == "diseble" ]];then
            input "Ma se ADSBEXCHANGE spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
        else
            input "Ma se ADSBEXCHANGE spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            ADSBEXCHANGE="disable"
        else
            ADSBEXCHANGE="enable"
        fi
        UPDATE_ADSBEXCHANGE=true
    fi
}


# Funkce ulozi nastavena data do konfiguracniho souboru
function set_cfg(){
STATION_LOCIP=$(hostname -I)
$SUDO touch ${CFG}
$SUDO chmod 666 ${CFG}
/bin/cat <<EOM > ${CFG}
# Tento soubor byl vygenerovan automaticky pomoci konfiguracniho skriptu
# Pokud jsi nejste jisti ze vite co delate, pouzite konfiguracni skript

# Oznaceni verze konfigurace pro pripadnou zpetnou kompatibilitu
CFG_VERSION="${CFG_VERSION}"

# Identifikace uzivatele a stanice
# email musi byt zhodny z registracnim emailem
USER_EMAIL="${USER_EMAIL}"
# pojmenovani prijimace. Max 9 znaku bez mezer
STATION_NAME="${STATION_NAME}"
# unikatni oznaceni stanice
STATION_UUID="${STATION_UUID}"

# Lokalizace anteny prijimace. Zemepisne souradnice ve stupnich.
STATION_LAT="${STATION_LAT}"
STATION_LON="${STATION_LON}"
# Lokalizace anteny prijimace. Nadmorska vyska v metrech
STATION_ALT="${STATION_ALT}"

# Dump1090
# instalace dump  [ notinstall | install | disable | enable ] (install = nainstalovan 3 stranou)
DUMP1090="${DUMP1090}"
# Pojmenovani sluzby
DUMP1090_NAME="${DUMP1090_NAME}"
# Vyber rtl-sdr zarizeni
DUMP1090_DEV="${DUMP1090_DEV}"
# Hodnota PPM pro kalibraci rtl-sdr klicenky
DUMP1090_PPM="${DUMP1090_PPM}"
# Zesileni signalu
DUMP1090_GAIN="${DUMP1090_GAIN}"

# ReADSB
# instalace readsb  [ notinstall | install | disable | enable ] (install = nainstalovan 3 stranou)
READSB="${READSB}"
# Pojmenovani sluzby
READSB_NAME="${READSB_NAME}"
# Vyber rtl-sdr zarizeni
READSB_DEV="${READSB_DEV}"
# Hodnota PPM pro kalibraci rtl-sdr klicenky
READSB_PPM="${READSB_PPM}"
# Zesileni signalu
READSB_GAIN="${READSB_GAIN}"
# Primarni adresa a port pro odesilani dat (odelene carkou)
READSB_DST="${READSB_DST}"
# Zalozni adresa a port pro odesilani dat (odelene carkou)
READSB_BCK="${READSB_BCK}"
# Rozsirujici parametry pro ReADSB
READSB_OPT="${READSB_OPT}"

# ADSBfwd
# instalace DASBfwd [ notinstall | disable | enable ]
ADSBFWD="${ADSBFWD}"
# Typ SW pro predavani dat [ adsbfwd | readsb | direct ]
ADSBFWD_TYPE="${ADSBFWD_TYPE}"
# Nazev programu pro forward ADSB dat
ADSBFWD_NAME="${ADSBFWD_NAME}"
# adresa a port zdroje adsb dat [ IP/DNS_url:port ]
ADSBFWD_SRC="${ADSBFWD_SRC}"
# adresa/y kam data chceme preposilat (oddelene mezerou) [ IP/DNS_url:port [IP/DNS_url:port] ... ]
ADSBFWD_DST="${ADSBFWD_DST}"

# MLAT client
# instalace mlat klienta [ notinstall | disable | enable ]
MLAT="${MLAT}"
# Nazev programu MLAT client
MLAT_NAME="${MLAT_NAME}"
# adresa MLAT serveru pro vypocet
MLAT_SERVER="${MLAT_SERVER}"
# adresa pro preposilani zpracovanych dat, nebo port pro cteni zpracovanych dat
MLAT_RESULT="${MLAT_RESULT}"
# Format a typ pripojeni pro poskytovani zpracovanych dat
MLAT_FORMAT="${MLAT_FORMAT}"

# Tar1090 & Lighttpd  
# instalace mlat klienta [ notinstall | disable | enable | install]
LIGHTTPD="${LIGHTTPD}"
# nazev web serveru
LIGHTTPD_NAME="${LIGHTTPD_NAME}"
# instalace mlat klienta [ notinstall | disable | enable ]
TAR1090="${TAR1090}"
# nazev programu Tar1090
TAR1090_NAME="${TAR1090_NAME}"

# RpiMonitor
# instalace RpiMonitoru [ notinstall | disable | enable ]
RPIMONITOR="${RPIMONITOR}"

# VPN Edgo
# instalace edgo [ notinstall | disable | enable ]
N2NADSB="${N2NADSB}"
# Nazev VPN Edge n2n
N2NADSB_NAME="${N2NADSB_NAME}"
# adresa n2n vpn serveru vcetne portu
N2NADSB_SERVER="${N2NADSB_SERVER}"
# prirazena lokalni IP adresa
N2NADSB_LOCAL="${N2NADSB_LOCAL}"
# Maska pro lokalni sit
N2NADSB_MASK="255.255.254.0"

# Reporter
# instalace reporteru [ notinstall | disable | enable ]
REPORTER="${REPORTER}"
# Nazev programu pro zasilani reportu
REPORTER_NAME="${REPORTER_NAME}"
# url adresa pro odesilani reportu
REPORTER_URL="${REPORTER_URL}"
# Seznam sledovanych sluzeb
REPORTER_SER="${REPORTER_SER}" 
# Interval pro odesilani dat
REPORTER_REF="${REPORTER_REF}"

# OGN / Flarm
# instalace OGN/Flarm [ notinstall | disable | enable ]
OGN="${OGN}"
# Nazev programu OGN / Flarm
OGN_NAME="rtlsdr-ogn"
# Vyber rtl-sdr zarizeni
OGN_DEV="${OGN_DEV}"
# Kalibrace rtl-sdr zarizeni
OGN_PPM="${OGN_PPM}"
# Zesileni rtl-sdr zarizebi
OGN_GAIN="${OGN_GAIN}"

# PiAware
# instalace piaware [ notinstall | disable | enable ]
PIAWARE="${PIAWARE}"
# Unique Identifier prijimace - je potreba pro obnovu, jinak je pouzito nove
PIAWARE_UI="${PIAWARE_UI}"

# Flightradar24 - fr24
# Instalace Flightradar24 [ notinstall | disable | enable ]
FR24="${FR24}"
# Nazev sluzby Flightradar24
FR24_NAME="${FR24_NAME}"
# Sharing key pro Flightradar24
FR24_KEY="${FR24_KEY}"
# Zdroj ADSB dat pro preposilani
FR24_HOST="${FR24_HOST}"
# Format zdroje ADSB dat
FR24_RECEIVER="${FR24_RECEIVER}"

# ADS-B Exchange 
# instalace ADS-B Exchange [ notinstall | disable | enable ]
ADSBEXCHANGE="${ADSBEXCHANGE}"

# ADSB.lol
# instalace ADSB.lol
ADSBLOL="${ADSBLOL}"
# UUID prijmace - je potreba pro obnovu, jinak je pouzito nove
ADSBLOL_ID="${ADSBLOL_ID}"

# Provadet test na aktualizaci systemu [ auto | enable | disable ]
STATION_UPGRADE="${STATION_UPGRADE}"

# Informace o zarizeni:
# Jmeno uzivatele pod kterym se spusti nektere skripty 
CZADSB_USER="${CZADSB_USER}"
STATION_SYSTEM="${STATION_SYSTEM}"
STATION_ARCH="${STATION_ARCH}"
STATION_MODEL="${STATION_MODEL}"
STATION_MACHINE="${STATION_MACHINE}"
STATION_PUBIP="${STATION_PUBIP}"
STATION_LOCIP="${STATION_LOCIP}"
STATION_USER="${STATION_USER}"

EOM
# Pokud je povolen reporter, odesli aktualni konfiguraci pro archivaci
    if [ ! "${REPORTER}" == "notinstall" -a ! "${REPORTER}" == "" ];then
        report=$(curl -s -X POST -F "file=@${CFG}" ${REPORTER_URL})
    else
        report=$(curl -s -X POST -F "file=@${CFG}" ${REPORTER_URL})
    fi
}
# --------------------- Konec funkci pro nastaveni -----------------------------

# ------------------------ Fumkce pro instalaci --------------------------------
# Funkce provede instalacu upgrade systemu
function install_upgrade(){
    if [[ "${STATION_UPGRADE}" != "disable" ]];then
        echo "Test a aktualizace systemu ..."
        $SUDO apt update > /tmp/apt_update.tmp 2>&1
        apt_update_upgrade=$(cat /tmp/apt_update.tmp | grep -o "^[[:digit:]]\+")
        $SUDO rm -f /tmp/apt_update.tmp
        [[ "$apt_update_upgrade" == "" ]] && apt_update_upgrade=0
        if [[ $apt_update_upgrade -gt 0 ]];then
            $SUDO apt upgrade -y
            $SUDO apt dist-upgrade -y
            $SUDO apt autoremove -y
        fi
    fi
}

# Funkce zobrazi informaci pred instalaci ovladacu SDR RTL a nasledne provede instalaci
function install_rtl_sdr(){
    printf "┌────────────────────── Instalace ovladacu RTL SDR  ───────────────────────┐\n"
    printf "│ Na vasem zarizeni nejsou detekovane ovladace pro RTL SDR zarizeni.  Tyto │\n"
    printf "│ ovladace jsou klicove pro vlastni provoz a proto musi byt  nainstalovany │\n"
    printf "│ jako  prvni  komponenta.  Po  instalaci ovladacu bude  proveden  restart │\n"
    printf "│ zarizeni aby se ovladace nacetly.                                        │\n"
    printf "│                                                                          │\n"
    printf "│ Po restartu prosim spuste prikaz 'czadsb' nebo znovu instalacni skript ! │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    echo
    input "Instalovat ovladace RTL SDR a restartovat zarizeni [Y/n]" '^[ynYN]*$' "y"
    if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
        $SUDO apt-get update
        $SUDO apt-get -y upgrade
        $SUDO apt autoremove -y
        $SUDO apt install -y --no-install-suggests --no-install-recommends rtl-sdr
        if ! [[ -s /etc/udev/rules.d/rtl-sdr.rules ]];then
            $SUDO wget -q https://raw.githubusercontent.com/osmocom/rtl-sdr/master/rtl-sdr.rules -O /etc/udev/rules.d/rtl-sdr.rules
        fi
        if ! command -v rtl_biast &>/dev/null ;then
            echo
            echo "ERROR: Instalace RTL SDR ovladacu se nezdarila. Bohuzel stimto stavem skript"
            echo "       neumi pracovat.  Zkuste nainstalovat cely system znovu a pokud ani to"
            echo "       nepomuze,  kontaktujte podporu z inforamcemi o sytemu a problemu."
            echo
            exit 2
        fi
        echo
        printf "┌────────────────── Instalace ovladacu RTL SDR hotova  ────────────────────┐\n"
        printf "│ Ovladace byly prave doinstalovany. Pro jejich nacteni je nutny restart ! │\n"
        printf "│                                                                          │\n"
        printf "│   Ten se provede ihned. Po restartu a opetovnem prihlaseni pokracujte    │\n"
        printf "│                             prikazem czadsb                              │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        $SUDO reboot
    else
        echo
        echo "ERROR: Vzhledem k odmitnuti instalace RTL SDR ovladacu bode pruvodce ukoncen !"
        echo
        input "Presto chcete pokracovat v konfiguraci [y/N]:" '^[ynYN]*$' "N"
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            exit 3
        fi
    fi
}

# Funkce instaluje dump1090 a provede nastaveno konfiguracniho souboru pro dump1090
function install_dump1090(){
    echo 
    echo -n "Dump1090"
    if [[ "${DUMP1090}" == "disable" ]] || [[ "${DUMP1090}" == "enable" ]];then
        UnitFileState=$(systemctl show ${DUMP1090_NAME} | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade Dump1090"
            wget -q ${INSTALL_URL}/install-dump1090.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        [[ "${UnitFileState}" != "${DUMP1090}d" ]] && $SUDO systemctl ${DUMP1090} ${DUMP1090_NAME}
        $SUDO sed -i "s/RECEIVER_SERIAL=.*/RECEIVER_SERIAL=${DUMP1090_DEV}/g" /etc/default/${DUMP1090_NAME}
        $SUDO sed -i "s/RECEIVER_GAIN=.*/RECEIVER_GAIN=${DUMP1090_GAIN}/g" /etc/default/${DUMP1090_NAME}
        $SUDO sed -i "s/EXTRA_OPTIONS=.*/EXTRA_OPTIONS=\"--ppm ${DUMP1090_PPM}\"/g" /etc/default/${DUMP1090_NAME}
        $SUDO sed -i "s/RECEIVER_LAT=.*/RECEIVER_LAT=${STATION_LAT}/g" /etc/default/${DUMP1090_NAME}
        $SUDO sed -i "s/RECEIVER_LON=.*/RECEIVER_LON=${STATION_LON}/g" /etc/default/${DUMP1090_NAME}
        if [[ "$(systemctl is-active ${DUMP1090_NAME})" != "active" ]];then
            echo " - ERROR: Dump1090 neni spusten !"
        else
            echo " - restart sluzbu Dump1090 pro aplikaci zmen."
            $SUDO systemctl restart ${DUMP1090_NAME}
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Funkce nainstaluje ReADSB jako hlavni zberac dat z rtl klicenky
function install_readsb(){
    echo 
    echo -n "ReADSB"
    if [[ "${READSB}" == "disable" ]] || [[ "${READSB}" == "enable" ]];then
        UnitFileState=$(systemctl show ${READSB_NAME} | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade ReADSB"
            wget -q ${INSTALL_URL}/install-readsb.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        [[ "${UnitFileState}" != "${READSB}d" ]] && $SUDO systemctl ${READSB} ${READSB_NAME}
        if [[ "${LIGHTTPD}" == "disable" ]] || [[ "${LIGHTTPD}" == "enable" ]];then
            READSB_API="--net-api-port unix:/run/readsb/api.sock "
        else
            READSB_API="--net-api-port 8008 "
        fi
        $SUDO touch /etc/default/${READSB_NAME}
        $SUDO chmod 666 /etc/default/${READSB_NAME}
        /bin/cat <<EOM >/etc/default/${READSB_NAME}
# Konfigurace pro ReADSB

# Nastaveni zdroje dat
RECEIVER_OPTIONS="--lat ${STATION_LAT} --lon ${STATION_LON} --device ${READSB_DEV} --device-type rtlsdr --gain ${READSB_GAIN} --ppm ${READSB_PPM}"
# Upresneni pro dekodovani
DECODER_OPTIONS="--modeac --modeac-auto --max-range 450 --write-json-every 1 ${READSB_API}${READSB_OPT}"
# Sitove nastaveni
NET_OPTIONS="--net --net-ri-port 30001 --net-ro-port 30002 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 30005 --net-connector ${READSB_DST},beast_reduce_plus_out,uuid=${STATION_UUID},${READSB_BCK}"
# Specifikace pro Json vystupy
JSON_OPTIONS="--json-location-accuracy 2 --range-outline-hours 24"
EOM
        if [[ "${READSB}" == "enable" ]];then
            echo " - restart sluzbu ReADSB client pro aplikaci zmen."
            $SUDO systemctl restart ${READSB_NAME}
            if [[ "$(systemctl is-active ${READSB_NAME})" != "active" ]];then
                echo " - ERROR: ReADSB client neni spusten !"
            fi
        else
            echo " - WARNING: ReADSB sluzba neni povolena, zm2ny se neaplikovali !"
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# ADSBfwd
function install_adsbfwd(){
    echo 
    echo -n "ADSBfwd"
    if [[ "${ADSBFWD}" == "disable" ]] || [[ "${ADSBFWD}" == "enable" ]];then
#        if [[ -z ${ADSBFWD_TYPE} ]] || [[ "${ADSBFWDE_TYPE}" == "direct" ]]; them 

        UnitFileState=$(systemctl show ${ADSBFWD_NAME} | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade ADSBfwd type ${ADSBFWDE_TYPE}"
            if [[ ! -z ${ADSBFWD_TYPE} ]] && [[ "${ADSBFWD_TYPE}" == "readsb" ]];then
                wget -q ${INSTALL_URL}/install-adsbfwd2.sh -O /tmp/install.tmp
            else
                wget -q ${INSTALL_URL}/install-adsbfwd.sh -O /tmp/install.tmp
            fi 
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        [[ "${UnitFileState}" != "${ADSBFWD}d" ]] && $SUDO systemctl ${ADSBFWD} ${ADSBFWD_NAME}
        if [[ "$(systemctl is-active ${ADSBFWD_NAME})" != "active" ]];then
            echo " - ERROR: ADSBfwd neni spusten !"
        else
            echo " - restart sluzbu ADSBfwd pro aplikaci zmen."
            $SUDO systemctl restart ${ADSBFWD_NAME}
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# MLAT client
function install_mlatclient(){
    echo 
    echo -n "MLAT client"
    if [[ "${MLAT}" == "disable" ]] || [[ "${MLAT}" == "enable" ]];then
        UnitFileState=$(systemctl show ${MLAT_NAME} | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade MLAT client"
            wget -q ${INSTALL_URL}/install-mlatclient.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
            set_cfg
        fi
        [[ "${UnitFileState}" != "${MLAT}d" ]] && $SUDO systemctl ${MLAT} ${MLAT_NAME}
        if [[ "${MLAT}" == "enable" ]];then
            echo " - restart sluzbu MLAT client pro aplikaci zmen."
            $SUDO systemctl restart ${MLAT_NAME}
            if [[ "$(systemctl is-active ${MLAT_NAME})" != "active" ]];then
                echo " - ERROR: MLAT client neni spusten !"
            fi
        else
            echo " - WARNING: MLAT sluzba neni povolena, zm2ny se neaplikovali !"
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Lighttpd
install_lighttpd(){
    echo
    echo -n "Lighttpd"
    if [[ "${LIGHTTPD}" == "disable" ]] || [[ "${LIGHTTPD}" == "enable" ]];then
        UnitFileState=$(systemctl show ${LIGHTTPD_NAME} | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade Lighttpd"
            $SUDO apt install -y lighttpd
            echo " - kopiruji dasboard"
            $SUDO wget -q ${INSTALL_URL}/web/index.html -O /var/www/html/index.html
            $SUDO wget -q ${INSTALL_URL}/web/ogn.html -O /var/www/html/ogn.html
            $SUDO wget -q ${INSTALL_URL}/web/dynamic.cgi -O /var/www/html/dynamic.cgi
            $SUDO wget -q ${INSTALL_URL}/web/piaware.cgi -O /var/www/html/piaware.cgi
            $SUDO wget -q ${INSTALL_URL}/web/status.cgi -O /var/www/html/status.cgi
            $SUDO wget -q ${INSTALL_URL}/web/czadsb_background.jpg -O /var/www/html/czadsb_background.jpg
            $SUDO wget -q ${INSTALL_URL}/web/czadsb_logo.png -O /var/www/html/czadsb_logo.png
            $SUDO wget -q ${INSTALL_URL}/web/93-cgi.conf -O /etc/lighttpd/conf-available/93-cgi.conf
            $SUDO rm -rf /etc/lighttpd/conf-enabled/93-cgi.conf
            $SUDO ln -s ../conf-available/93-cgi.conf /etc/lighttpd/conf-enabled/93-cgi.conf
            if [[ "${READSB}" == "disable" ]] || [[ "${READSB}" == "enable" ]];then
                echo " - nastaveni proxy api pro ReADSB"
                $SUDO wget -q ${INSTALL_URL}/web/64-readsb.conf -O /etc/lighttpd/conf-available/64-readsb.conf
                $SUDO rm -rf /etc/lighttpd/conf-enabled/64-readsb.conf
                $SUDO ln -s ../conf-available/64-readsb.conf /etc/lighttpd/conf-enabled/64-readsb.conf
            fi
            if [[ "${RPIMONITOR}" == "disable" ]] || [[ "${RPIMONITOR}" == "enable" ]];then
                echo " - nastaveni proxy pro Rpimonitor"
                $SUDO wget -q ${INSTALL_URL}/rpimonitor/68-rpimonitor.conf -O /etc/lighttpd/conf-available/68-rpimonitor.conf
                $SUDO rm -rf /etc/lighttpd/conf-enabled/68-rpimonitor.conf
                $SUDO ln -s ../conf-available/68-rpimonitor.conf /etc/lighttpd/conf-enabled/68-rpimonitor.conf
            fi
            if [[ "${OGN}" == "disable" ]] || [[ "${OGN}" == "enable" ]];then
                echo " - nastaveni proxy pro OGN"
                $SUDO wget -q ${INSTALL_URL}/web/62-ogn.conf -O /etc/lighttpd/conf-available/62-ogn.conf
                $SUDO rm -rf /etc/lighttpd/conf-enabled/62-ogn.conf
                $SUDO ln -s ../conf-available/62-ogn.conf /etc/lighttpd/conf-enabled/62-ogn.conf
            fi
            [[ "${LIGHTTPD}" == "enable" ]] && $SUDO systemctl reload ${LIGHTTPD_NAME}
        else
            if [[ "${LIGHTTPD}" == "enable" ]];then
                echo " - restart sluzby ${LIGHTTPD_NAME} pro aplikovani zmen."
                $SUDO systemctl restart ${LIGHTTPD_NAME}
            else
                echo " - nebyla provedena zadna zmena."
            fi
        fi
        [[ "${UnitFileState}" != "${LIGHTTPD}d" ]] && $SUDO systemctl ${LIGHTTPD} ${LIGHTTPD_NAME}
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Tar1090
install_tar1090(){
    echo
    echo -n "Tar1090"
    if [[ "${TAR1090}" == "disable" ]] || [[ "${TAR1090}" == "enable" ]];then
        UnitFileState=$(systemctl show ${TAR1090_NAME} | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade Tar1090"
            $SUDO bash -c "$(wget -nv -O - https://github.com/wiedehopf/tar1090/raw/master/install.sh)"
            $SUDO sed -i "s/\/\/PlaneCountInTitle = false.*/PlaneCountInTitle = true;/g" /usr/local/share/tar1090/html/config.js
            $SUDO sed -i "/^\/\/shareBaseUrl = 'https:\/\/adsb\.lol\/'[^;]*/i shareBaseUrl = 'https://aircrafts.rxw.cz/'" /usr/local/share/tar1090/html/config.js
            $SUDO sed -i "s/\/\/ imageConfigLink = .*/imageConfigLink = '\/';/g" /usr/local/share/tar1090/html/config.js
            $SUDO sed -i "s/\/\/ imageConfigText = .*/imageConfigText = 'Local panel';/g" /usr/local/share/tar1090/html/config.js
            [[ "${TAR1090}" == "enable" ]] && $SUDO systemctl restart ${TAR1090_NAME}
        else
            if [[ "${TAR1090}" == "enable" ]];then
                echo " - restart sluzby ${TAR1090_NAME} pro aplikovani zmen."
                $SUDO systemctl restart ${TAR1090_NAME}
            else
                echo " - nebyla provedena zadna zmena."
            fi
        fi
        [[ "${UnitFileState}" != "${TAR1090}d" ]] && $SUDO systemctl ${TAR1090} ${TAR1090_NAME}
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}


# RpiMonitor
function install_rpimonitor(){
    echo 
    echo -n "RpiMonitor (${RPIMONITOR}) "
    if [[ "${RPIMONITOR}" == "disable" ]] || [[ "${RPIMONITOR}" == "enable" ]];then
        UnitFileState=$(systemctl show rpimonitor.service | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade RpiMonitor"
            wget -q ${INSTALL_URL}/install-rpimonitor.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
# prida dump1090
# pokud OGN, tak ogn + mapu
#if [[ $(grep "addons-piaware.conf" /etc/rpimonitor/data.conf | wc -l) -eq 0 ]];then
#    $SUDO sh -c 'echo "include=/etc/rpimonitor/template/addons-piaware.conf" >> /etc/rpimonitor/data.conf'
#fi
        fi
       [[ "${UnitFileState}" != "${RPIMONITOR}d" ]] && $SUDO systemctl ${RPIMONITOR} rpimonitor.service
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# VPN Edge n2n
function install_n2nvpn(){
    echo 
    echo -n "VPN Edge n2n"
    if [[ "${N2NADSB}" == "disable" ]] || [[ "${N2NADSB}" == "enable" ]];then
        UnitFileState=$(systemctl show ${N2NADSB_NAME} | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade N2N VPN"
            wget -q ${INSTALL_URL}/install-n2nvpn.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        [[ "${UnitFileState}" != "${N2NADSB}d" ]] && $SUDO systemctl ${N2NADSB} ${N2NADSB_NAME}.service
        if [[ "$(systemctl is-active ${N2NADSB_NAME})" != "active" ]];then
            echo " - Warning: N2N VPN Edge pro CzADSB neni spustena !"
        else
            echo " - restart sluzbu N2N VPN Edge CzADSB pro aplikaci zmen."
            $SUDO systemctl restart ${MLAT_NAME}
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# OGN / Flarm
function install_ogn(){
    echo 
    echo -n "OGN / Flarm"
    if [[ "${OGN}" == "disable" ]] || [[ "${OGN}" == "enable" ]];then
        UnitFileState=$(systemctl show ${OGN_NAME} | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade OGN / Flarm"
            wget -q ${INSTALL_URL}/install-ogn.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
            if [[ "${LIGHTTPD}" == "disable" ]] || [[ "${LIGHTTPD}" == "enable" ]];then
                echo " - nastaveni proxy pro OGN"
                $SUDO wget -q ${INSTALL_URL}/web/62-ogn.conf -O /etc/lighttpd/conf-available/62-ogn.conf
                $SUDO rm -rf /etc/lighttpd/conf-enabled/62-ogn.conf
                $SUDO ln -s ../conf-available/62-ogn.conf /etc/lighttpd/conf-enabled/62-ogn.conf
                if [[ "${LIGHTTPD}" == "enable" ]];then
                    echo " - restart sluzby ${LIGHTTPD_NAME} pro aplikovani zmen."
                    $SUDO systemctl reload ${LIGHTTPD_NAME}
                fi
            fi
        fi
        [[ "${UnitFileState}" != "generated" ]] && [[ "${UnitFileState}" != "${OGN}d" ]] && $SUDO systemctl ${OGN} ${OGN_NAME}.service
        [[ "${UnitFileState}" == "generated" ]] && $SUDO /lib/systemd/systemd-sysv-install ${OGN} ${OGN_NAME}

        $SUDO sed -i "s/FreqCorr.[^;]*/FreqCorr     = ${OGN_PPM} /g" /opt/rtlsdr-ogn/OGNstation.conf
        if [[ ${#OGN_DEV} -gt 1 ]];then
            $SUDO sed -i "s/..Device [^;]*/# Device       = 1 /g" /opt/rtlsdr-ogn/OGNstation.conf
            $SUDO sed -i "s/..DeviceSerial[^;]*/  DeviceSerial = \"${OGN_DEV}\" /g" /opt/rtlsdr-ogn/OGNstation.conf
        else
            $SUDO sed -i "s/..Device [^;]*/  Device       = ${OGN_DEV} /g" /opt/rtlsdr-ogn/OGNstation.conf
            $SUDO sed -i "s/..DeviceSerial[^;]*/# DeviceSerial = "00000002" /g" /opt/rtlsdr-ogn/OGNstation.conf
        fi
        $SUDO sed -i "s/Gain[^;]*/Gain        = ${OGN_GAIN} /g" /opt/rtlsdr-ogn/OGNstation.conf

        $SUDO sed -i "s/Latitude.[^;]*/Latitude   = +${STATION_LAT} /g" /opt/rtlsdr-ogn/OGNstation.conf
        $SUDO sed -i "s/Longitude[^;]*/Longitude  = +${STATION_LON} /g" /opt/rtlsdr-ogn/OGNstation.conf
        $SUDO sed -i "s/Altitude.[^;]*/Altitude   = +${STATION_ALT} /g" /opt/rtlsdr-ogn/OGNstation.conf
        $SUDO sed -i "s/Call[^;]*/Call   = \"${STATION_NAME}\" /g" /opt/rtlsdr-ogn/OGNstation.conf

        if [[ "$(systemctl is-active ${OGN_NAME})" != "active" ]];then
            echo " - Warning: OGN / Flarm neni spusteno !"
        else
            echo " - restart sluzbu OGN / Flarm pro aplikaci zmen."
            $SUDO systemctl restart ${OGN_NAME}
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Piaware - FlightAware
install_piaware(){
    echo 
    echo -n "PiAware / FlightAware"
    if [[ "${PIAWARE}" == "disable" ]] || [[ "${PIAWARE}" == "enable" ]];then
        UnitFileState=$(systemctl show piaware | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade PiAware / FlightAware"
            wget -q ${INSTALL_URL}/install-piaware.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        UnitFileState=$(systemctl show piaware | grep "UnitFileState" | awk -F = '{print $2}')
        [[ "${UnitFileState}" == "generated" ]] && $SUDO /lib/systemd/systemd-sysv-install ${PIAWARE} ${PIAWARE_NAME}
        [[ "${UnitFileState}" != "generated" ]] && [[ "${UnitFileState}" != "${PIAWARE}d" ]] && $SUDO systemctl ${PIAWARE} ${PIAWARE_NAME}.service

        if [[ -n ${PIAWARE_UI} ]];then
            $SUDO piaware-config feeder-id ${PIAWARE_UI}
            $SUDO systemctl restart piaware.service
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Reporter
install_reporter(){
    echo
    echo -n "Reporter "
    if [[ "${REPORTER}" == "disable" ]] || [[ "${REPORTER}" == "enable" ]];then
        UnitFileState=$(systemctl show reporter.timer | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade Reporter"
            wget -q ${INSTALL_URL}/install-reporter.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        [[ "${UnitFileState}" != "${REPORTER}d" ]] && $SUDO systemctl ${REPORTER} reporter.timer
        echo
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Flightradar24 / FR24
install_fr24(){
    echo
    echo -n "Flightradar24 / FR24"
    if [[ "${FR24}" == "disable" ]] || [[ "${FR24}" == "enable" ]];then
        UnitFileState=$(systemctl show ${FR24_NAME}.service | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade Flightradar24 - fr24"
            wget -q ${INSTALL_URL}/install-fr24.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
            UnitFileState=$(systemctl show ${FR24_NAME}.service | grep "UnitFileState" | awk -F = '{print $2}' )
        fi
        [[ "${UnitFileState}" != "${FR24}d" ]] && $SUDO systemctl ${FR24} ${FR24_NAME}.service
        if [[ "$(systemctl is-active ${FR24_NAME})" != "active" ]];then
            echo " - Warning: Sluzba ${FR24_NAME} neni spustena !"
        else
            echo " - restart sluzbu ${FR24_NAME} pro aplikaci zmen."
            $SUDO systemctl restart ${FR24_NAME}.service
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# ADS-B Exchange
install_adsbexchange(){
    echo
    echo -m "ADS-b Exchange"
    if [[ "${ADSBEXCHANGE}" == "disable" ]] || [[ "${ADSBEXCHANGE}" == "enable" ]];then
        UnitFileStateF=$(systemctl show adsbexchange-feed.service | grep "UnitFileState" | awk -F = '{print $2}' )
        UnitFileStateM=$(systemctl show adsbexchange-mlat.service | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileStateF}" == "" ]] || [[ "${UnitFileStateM}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade Flightradar24 - fr24"
            wget -q ${INSTALL_URL}/install-adsbexchange.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
        fi
        UnitFileStateF=$(systemctl show adsbexchange-feed.service | grep "UnitFileState" | awk -F = '{print $2}' )
        UnitFileStateM=$(systemctl show adsbexchange-mlat.service | grep "UnitFileState" | awk -F = '{print $2}' )
        [[ "${UnitFileStateF}" != "${ADSBEXCHANGE}d" ]] && $SUDO systemctl ${ADSBEXCHANGE} adsbexchange-feed.service
        [[ "${UnitFileStateM}" != "${ADSBEXCHANGE}d" ]] && $SUDO systemctl ${ADSBEXCHANGE} adsbexchange-mlat.service
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# Funkce postupne pusti jednotlive instalacni skrypty, pokud je na nich zaznamenana zmena
function install_select(){
    [[ "${STATION_UPGRADE}" == "auto" ]] && UPDATE_UPGRADE=true 
    if ${UPGRADE_ALL} ;then
        install_upgrade && UPDATE_UPGRADE=false
        install_dump1090 && UPDATE_DUMP1090=false
        install_readsb && UPDATE_READSB=false
        install_adsbfwd && UPDATE_ADSBFWD=false
        install_mlatclient && UPDATE_MLAT=false
        install_lighttpd && UPDATE_LIGHTTPD=false
        install_tar1090 && UPDATE_TAR1090=false
        install_rpimonitor && UPDATE_RPIMONITOR=false
        install_n2nvpn && UPDATE_N2NVPN=false
        install_ogn && UPDATE_OGN=false
        install_piaware && UPDATE_PIAWARE=false
        install_reporter && UPDATE_REPORTER=false
        install_fr24 && UPDATE_FR24=false
        install_adsbexchange && UPDATE_ADSBEXCHANGE=false
    else
        ${UPDATE_UPGRADE} && install_upgrade && UPDATE_UPGRADE=false
        ${UPDATE_DUMP1090} && install_dump1090 && UPDATE_DUMP1090=false
        ${UPDATE_READSB} && install_readsb && UPDATE_READSB=false
        ${UPDATE_ADSBFWD} && install_adsbfwd && UPDATE_ADSBFWD=false
        ${UPDATE_MLAT} && install_mlatclient && UPDATE_MLAT=false
        ${UPDATE_LIGHTTPD} && install_lighttpd && UPDATE_LIGHTTPD=false
        ${UPDATE_TAR1090} && install_tar1090 && UPDATE_TAR1090=false
        ${UPDATE_RPIMONITOR} && install_rpimonitor && UPDATE_RPIMONITOR=false
        ${UPDATE_N2NVPN} && install_n2nvpn && UPDATE_N2NVPN=false
        ${UPDATE_OGN} && install_ogn && UPDATE_OGN=false
        ${UPDATE_PIAWARE} && install_piaware && UPDATE_PIAWARE=false
        ${UPDATE_REPORTER} && install_reporter && UPDATE_REPORTER=false
        ${UPDATE_FR24} && install_fr24 && UPDATE_FR24=false
        ${UPDATE_ADSBEXCHANGE} && install_adsbexchange && UPDATE_ADSBEXCHANGE=false
    fi
    UPGRADE=false
    UPGRADE_ALL=false
}

# Funkce pro upgrade na verzi 3, jen AdsbFWD
function upgrade_adsbfwd(){
    ADSBFWD="enable"
    ADSBFWD_TYPE="readsb"
    ADSBFWD_SRC="127.0.0.1,30005,beast_in"
    ADSBFWD_DST="feed.czadsb.cz,30004"
    ADSBFWD_BAC="feed.rxw.cz,30004"
    CFG_VERSION=3
#    set_readsb "${EXPERT}"
    UPGRADE=true
    install_adsbfwd && UPDATE_ADSBFWD=false
    UPGRADE=false
    echo; input "Pro pokracovani stiskni enter ..."
}

# Funkce pro upgrade na verzi 4, bez AdsbFWD
function upgrade_czadsb(){
    if [[ "$ADSBFWD}" == "disable" ]] || [[ "${ADSBFWD}" == "enable" ]];then    # Pokud je nainstalovan AdsbFWD, vypni, smaz, ..
        echo "- Vypinam sluzbu ${ADSBFWD_NAME}"
        $SUDO systemctl stop ${ADSBFWD_NAME}.service
        $SUDO systemctl disable ${ADSBFWD_NAME}.service 
        $SUDO rm -f /lib/systemd/system/${ADSBFWD_NAME}.service
        $SUDO systemctl daemon-reload    
        ADSBFWD="notinstall"
        ADSBFWD_TYPE="direct"
    else
        echo "- Sluzbu ${ADSBFWD_NAME} neni nainstalovana"
        ADSBFWD="notinstall"
        ADSBFWD_TYPE="direct"
    fi
    if [[ "${DUMP1090}" == "disable" ]] || [[ "${DUMP1090}" == "enable" ]];then # Pokud je instalace Dump1090, vypni
        echo "- Vypinam sluzbu ${DUMP1090_NAME}"
        $SUDO systemctl stop ${DUMP1090_NAME}.service
        $SUDO systemctl disable ${DUMP1090_NAME}.service 
        DUMP1090="install"
    else
        echo "- Sluzbu ${DUMP1090_NAME} neni nainstalovana"
        DUMP1090="notinstall"
    fi
    CFG_VERSION=4
    READSB="enable"
    ADSBFWD_TYPE="direct"
    [[ ! -z ${DUMP1090_DEV} ]] && READSB_DEV=${DUMP1090_DEV}
    [[ ! -z ${DUMP1090_PPM} ]] && READSB_PPM=${DUMP1090_PPM}
    [[ ! -z ${DUMP1090_GAIN} ]] && READSB_GAIN=${DUMP1090_GAIN}
    UPDATE_READSB=true
    UPDATE_LIGHTTPD=true   
#    set_readsb "${EXPERT}" 
    set_tar1090
    UPGRADE=true
    ${UPDATE_READSB} && install_readsb && UPDATE_READSB=false
    ${UPDATE_LIGHTTPD} && install_lighttpd && UPDATE_LIGHTTPD=false
    ${UPDATE_TAR1090} && install_tar1090 && UPDATE_TAR1090=false
    UPGRADE=false
    echo; input "Pro pokracovani stiskni enter ..."
}

# ------------------------ Konec definic funkci --------------------------------

# Menu pro sluzby tretich stran
function offer_third(){
    while true; do
        clear
        info_logo; info_system; info_user end;
        menu_third
        case "$X" in
            a) set_piaware; clear       # PiaWare
            ;;
            b) set_fr24; clear;         # Flightradar24
            ;;
            d) set_adsbexchange; clear; # ADS-B Exchange
            ;;
            v)  UPGRADE=true            # Aplikovat zmenu + upgrade
                install_select
                echo; input "Pro pokracovani stiskni enter ..."
            ;;
            *) return
            ;;
        esac
    done
}

# +=============================================================================+
# |                                                                             |
# |                      Zacatek vlastnoho skriptu                              |
# |                                                                             |
# +=============================================================================+

# Over prava na uzivatele root, pripadne nastav sudo
if [ "$(id -u)" != "0" ];then
    echo
    echo "Skript nema prava root ! Zapinam prava pomoci 'sudo'."
    SUDO="sudo"
else
    SUDO=""
fi

# Nastav /usr/bin/ skripy czadsb pro snassi spousteni
set_czadsb

# Nastav ceskou znakovou sadu
grep '# cs_CZ.UTF-8 UTF-8' /etc/locale.gen
if [ "$?" == "0" ];then
    echo "* Nastaveni jazykoveho prostredi"
    $SUDO sed -i 's/^# \(cs_CZ.UTF-8 UTF-8\)/\1/' /etc/locale.gen                # 1. Odkomentování požadovaných jazyků v souboru /etc/locale.gen
    $SUDO sed -i 's/^# \(en_GB.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    $SUDO locale-gen                                                             # 2. Vygenerování zvolených locales
    $SUDO update-locale LANG=cs_CZ.UTF-8 LC_ALL=cs_CZ.UTF-8                      # 3. Nastavení výchozího jazyka systému
fi

# Over nainstalovani rtl sdr ovladacu a pripadne je doinstaluj
if ! command -v rtl_test &>/dev/null ;then
    clear
    info_logo
    info_system "end"
    echo
    install_rtl_sdr
fi

# Over dostupnost dos2unix, pripadne doinstaluj
if ! command -v dos2unix &>/dev/null ;then
    echo "Program  pro  prevod  textu na unix  format nenalzen, bude doinstalovan."
    $SUDO apt update
    $SUDO apt install -y --no-install-suggests --no-install-recommends dos2unix
fi
# Over dostupnost netstat, pripadne doinstaluj
if ! command -v netstat &>/dev/null ;then
    $SUDO apt install -y --no-install-suggests --no-install-recommends net-tools
fi

# Over zda existuje novy konfiguracni soubor jinak ho vytvor a over puvodni konfiguracni soubor
if [ -s ${CFG} ];then
    $SUDO dos2unix ${CFG}
    source ${CFG}
    CFG_NEW="false"
    [[ -z ${CFG_VERSION} ]] &&  CFG_VERSION=2
# Over verzi cfg Upravit: VPNEDGE ; LOCAL ; DUMP1090    

else
    $SUDO touch ${CFG}
    $SUDO chmod 666 ${CFG}
    CFG_NEW="true"
    if [ -r /boot/czadsb-config.txt ];then
        $SUDO dos2unix /boot/czadsb-config.txt
        . /boot/czadsb-config.txt
        [[ "${N2N_VPN}" == "yes" ]] && N2NADSB="enable"
        [[ -n ${N2N_IP} ]] && LOCAL=${N2N_IP}
        [[ "${MM2_ENABLE_OUTCONNECT}" == "yes" ]] && ADSBFWD="enable"
        [[ -n ${MM2_OUTCONNECT_PORT} ]] && DESTINATION="czadsb.cz:${MM2_OUTCONNECT_PORT}"
        [[ -z ${CFG_VERSION} ]] &&  CFG_VERSION=1
    else
        CFG_VERSION=4
    fi
fi

# Dopln pripadne potrebne chybejejici vychozi hodnoty
set_default

# Vynuluj informaci ktere sluzby se maji instalocat / modifikovat
UPGRADE=false
UPGRADE_ALL=false
UPDATE_UPGRADE=false
UPDATE_DUMP1090=false
UPDATE_READSB=false
UPDATE_ADSBFWD=false
UPDATE_MLAT=false
UPDATE_LIGHTTPD=false
UPDATE_TAR1090=false
UPDATE_RPIMONITOR=false
UPDATE_N2NVPN=false
UPDATE_OGN=false
UPDATE_PIAWARE=false
UPDATE_REPORTER=false
UPDATE_FR24=false
UPDATE_ADSBEXCHANGE=false

# Test na verzi CFG a nabidka prislusneho upgrade
if [[ ${CFG_VERSION} -eq 2 ]];then
    READSB="notinstall"
    ADSBFWD_TYPE="adsbfwd"
    if [[ "$ADSBFWD}" == "disable" ]] || [[ "${ADSBFWD}" == "enable" ]];then        # Pokud je nainstalovan AdsbFWD, doporuceny upgrade
        if [[ "${DUMP1090}" == "disable" ]] || [[ "${DUMP1090}" == "enable" ]];then # prokud byl instalovan DUM1090 skripte, tak na v.4
            printf "┌──────────────────────  Upgrade na verzi 4 CzADSB  ───────────────────────┐\n"
            printf "│ Na vasem systemu je doporucen upgrade ze stavajiciho DUMP1090 na ReADSB. │\n"
            printf "│ Pokud byla provedena predchozi instalace skriptem CzADSB, melo by to byt │\n"
            printf "│ bezpecne a upgrade doporucujeme !                                        │\n"
            printf "├──────────────────────────────────────────────────────────────────────────┘\n"
            input  "* Muzeme provest upgrade na novou verzi ? [Y/n]:" '^[ynYN]*$' "y"
            if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
                upgrade_czadsb
            else
                printf "┌──────────────────────  Upgrade na verzi 3 CzADSB  ───────────────────────┐\n"
                printf "│ Z duvodu  prechodu na identifikaci prijmace podle uuid je doporuceno bud │\n"
                printf "│ upgrade celeho systemu na nejnovejsi,  nebo alespon stavajiciho AdsbFWD. │\n"
                printf "├──────────────────────────────────────────────────────────────────────────┘\n"
                input  "* Muzeme provest zatim upgrade AdsbFWD ? [Y/n]:" '^[ynYN]*$' "y"
                if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
                    upgrade_adsbfwd
                fi
            fi
        else                                                                        # Pokud neni Dump1090 instalovan skriptem, tak jen v.3
            READSB="notinstall"
            printf "┌──────────────────────  Upgrade na verzi 3 CzADSB  ───────────────────────┐\n"
            printf "│ Z duvodu  prechodu na identifikaci prijmace podle uuid je doporuceno bud │\n"
            printf "│ upgrade celeho systemu na nejnovejsi,  nebo alespon stavajiciho AdsbFWD. │\n"
            printf "├──────────────────────────────────────────────────────────────────────────┘\n"
            input  "* Muzeme provest zatim upgrade AdsbFWD ? [Y/n]:" '^[ynYN]*$' "y"
            if [[ "$X" == "y" ]] || [[ "$X" == "Y" ]];then
                upgrade_adsbfwd
            fi
        fi
    fi
    set_cfg
fi

# V pripade nove instalace spust pruvodce
if ${CFG_NEW} ;then
    check=`netstat -tln | grep 80`                                              # Over, zda jiz neni obsazen port 80 (web) a zda nejsou nainstalovane web servery
    [[ ${#check} -ge 10 ]] &&  LIGHTTPD="install"
    command -v lighttpd &>/dev/null &&  LIGHTTPD="install"
    command -v apache2  &>/dev/null &&  LIGHTTPD="install"
    command -v nginx    &>/dev/null &&  LIGHTTPD="install"
    check=`netstat -tln | grep 30005`                                           # Over zda neni obsazen port 30005 a neni nainstalovan jiz dump, nebo readsb
    [[ ${#check} -ge 10 ]] &&  DUMP1090="install" && READSB="install"
    command -v readsb      &>/dev/null &&  DUMP1090="install" && READSB="install"
    command -v dump1090    &>/dev/null &&  DUMP1090="install" && READSB="install"
    command -v dump1090-fe &>/dev/null &&  DUMP1090="install" && READSB="install"
    if [[ "${DUMP1090}" == "install" ]] || [[ "${READSB}" == "install" ]];then
        ADSBFWD_TYPE="readsb"
    else
        ADSBFWD_TYPE="direct"
    fi
    clear
    info_logo; info_system; info_rtlsdr
    info_newinst
    set_expert
    set_identifikace
# set old set   report=$(curl -d "user=${USER_EMAIL}&statiom=${STATION_NAME}" -X POST ${REPORTER_URL})
    set_lokalizace
    if [[ ${CFG_VERSION} -eq 4 ]];then   # Pro vezi 4 se jiz nepouzije Dump1090 a AdsbFWD
        set_readsb "${EXPERT}" 
        set_tar1090 "${EXPERT}"
    else
        set_dump1090 "${EXPERT}"
        set_adsbfwd "${EXPERT}"
    fi
    set_mlat "${EXPERT}"
    set_rpimonitor
    set_n2nvpn
    set_reporter
    set_upgrade
    set_cfg
    info_install
    UPGRADE=true
    install_select
    input "Pro pokracovani stiskni enter ..."
fi

if [ "$MLAT_NAME" != "czadsb-mlat" ];then
    UPGRADE=true
    UPDATE_MLAT=true
    install_mlatclient && UPDATE_MLAT=false
    UPGRADE=false
fi


while true; do
    clear
    info_logo; info_system; info_user; info_rtlsdr
    info_components; info_setting
    menu_edit
    case "$X" in
        0)  install_select
            info_exit
            exit 0 
        ;;
        1)  clear; info_logo
            set_identifikace
        ;;
        2)  clear; info_logo
            set_lokalizace
        ;;
        3)  clear; info_logo
            if [[ ${CFG_VERSION} -eq 4 ]];then
                set_readsb
            else
                set_dump1090
                [[ "${DUMP1090}" == "install" ]] && sleep 4
            fi 
        ;;
        4)  clear; info_logo
            set_rtl_sn
        ;;
        5)  clear; info_logo
            if [[ ${CFG_VERSION} -eq 4 ]];then
                set_tar1090
            else
                set_adsbfwd
            fi            
        ;;
        6)  clear; info_logo
            set_n2nvpn
        ;;
        7)  clear; info_logo
            set_ogn
        ;;
        9)  install_select
            echo; input "Pro pokracovani stiskni enter ..."
        ;;
        a)  offer_third
        ;;
        b)  clear; info_logo
            set_mlat
        ;;
        c)  clear; info_logo
            set_rpimonitor
        ;;
        d)  clear; info_logo
            set_reporter
        ;;
        u)  UPGRADE_ALL=true; UPGRADE=true
            install_select
            echo; input "Pro pokracovani stiskni enter ..."
        ;;
        v)  UPGRADE=true
            install_select
            echo; input "Pro pokracovani stiskni enter ..."
        ;;
        q)  info_exit
            exit 0
        ;;
        r)  info_exit
            install_select
            $SUDO reboot
        ;;
        s)  clear; info_logo
            set_upgrade            
        ;;
        x)  $SUDO rm ${CFG}
             exit 0
        ;;
    esac
    set_cfg
done


