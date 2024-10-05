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
    if [[ -z ${STATION_NAME} ]] && [[ -e /tmp/ipinfo.log ]];then
        NAME1=$(cat /tmp/ipinfo.log | grep country | awk -F\" '{print $4}')
        NAME2=$(cat /tmp/ipinfo.log | grep city | awk -F\" '{print $4}')
        STATION_NAME="${NAME1}-${NAME2}"
    fi
    if [[ -z ${STATION_LAT} ]] && [[ -e /tmp/ipinfo.log ]];then
        STATION_LAT=$(cat /tmp/ipinfo.log | grep loc | awk -F\" '{print $4}' | awk -F, '{print $1}' | tr -d '\n')
    fi
    if [[ -z ${STATION_LON} ]] && [[ -e /tmp/ipinfo.log ]];then
        STATION_LON=$(cat /tmp/ipinfo.log | grep loc | awk -F\" '{print $4}' | awk -F, '{print $2}' | tr -d '\n')
    fi
    if [[ -z ${STATION_ALT} ]];then
        wget -q "https://api.open-elevation.com/api/v1/lookup?locations=${STATION_LAT},${STATION_LON}" -O /tmp/ipinfo.log
        [[ -e /tmp/ipinfo.log ]] && STATION_ALT=$(grep -ioP 'elevation..[[:digit:]]*' /tmp/ipinfo.log | awk -F: '{print $2}' | tr -d '\n')    
    fi

    # Jmeno uzivatele pod kterym se spusti nektere skripty 
    [[ -z ${CZADSB_USER} ]] && CZADSB_USER="adsb"
    # Adresar pro instalaci nekterych programu
    [[ -z ${INSTALL_FOLDER} ]] && INSTALL_FOLDER="/opt/czadsb"

    # Nazev programu Dump1090
    [[ -z ${DUMP1090_NAME} ]] && DUMP1090_NAME="dump1090-fa"
    # Vyber rtl-sdr zarizeni
    [[ -z ${DUMP1090_DEV} ]] && DUMP1090_DEV=0
    # Kalibrace rtl-sdr zarizeni
    [[ -z ${DUMP1090_PPM} ]] && DUMP1090_PPM=0
    # Zesileni rtl-sdr zarizebi
    [[ -z ${DUMP1090_GAIN} ]] && DUMP1090_GAIN="60"

    # Nazev programu pro forward ADSB dat
    [[ -z ${ADSBFWD_NAME} ]] && ADSBFWD_NAME="adsbfwd"
    # Vychozi adresa pro cteni ADSB dat z dump1090
    [[ -z ${ADSBFWD_SRC} ]] && ADSBFWD_SRC="127.0.0.1:30005"
    # Vychozi adresa pro odesilani ADSB dat
    [[ -z ${ADSBFWD_DST} ]] && ADSBFWD_DST="czadsb.cz:50000"

    # Nazev programu MLAT client
    [[ -z ${MLAT_NAME} ]] && MLAT_NAME="mlat-client"
    # Adresa mlat serveru pro vypocet
    [[ -z ${MLAT_SERVER} ]] && MLAT_SERVER="czadsb.cz:40147"
    # Adresa kam posilat vypocitane pozice letadel
    [[ -z ${MLAT_RESULT} ]] && MLAT_RESULT="czadsb.cz:31003"
    # Format a typ pripojeni pro odesilani zpracovanych dat
    [[ -z ${MLAT_FORMAT} ]] && MLAT_FORMAT="basestation,connect"
    
    # Nazev VPN Edge n2n
    [[ -z ${N2NADSB_NAME} ]] && N2NADSB_NAME="vpn-czadsb"
    # Adresa VPN serveru
    [[ -z ${N2NADSB_SERVER} ]] && N2NADSB_SERVER="n2n.czadsb.cz:82"
    
    # Adresa pro zasilani report zprav
    [[ -z ${REPORTER_URL} ]] && REPORTER_URL="https://report.czadsb.cz"
    
    # Nazev programu OGN / Flarm
    [[ -z ${OGN_NAME} ]] && OGN_NAME="rtlsdr-ogn" 
    #  Vyber rtl-sdr zarizeni
    [[ -z ${OGN_DEV} ]] && OGN_DEV=1
    Kalibrace rtl-sdr zarizeni
    [[ -z ${OGN_PPM} ]] && OGN_PPM=0
    Zesileni rtl-sdr zarizebi
    [[ -z ${OGN_GAIN} ]] && OGN_GAIN=48
    
}

# Funkce nacte seznam rtl-sdr zarizeni
function list_rtlsdr(){
    if command -v rtl_biast &>/dev/null ;then
        rtl_biast 2> /tmp/rtlsdr.log
        grep -e "^ " /tmp/rtlsdr.log > /tmp/rtlsdr.list
        RTL_SDR=$(cat /tmp/rtlsdr.list | wc -l)
    else
        RTL_SDR=""
    fi
    # grep -E " ${DEV}:| ${DEV}$" /tmp/rtlsdr.list
}

# Funkce zjisti informace o systemu a zobrazi je
function info_system(){
    . /etc/os-release
    STATION_SYSTEM="${PRETTY_NAME}"
    STATION_USERS=$(users)
    STATION_ARCH=$(dpkg --print-architecture)
    STATION_MACHINE=$(uname -m)
    STATION_MODEL=$(grep Model /proc/cpuinfo | awk -F : '{print $2}')
    [[ -z ${STATION_MODEL} ]] && STATION_MODEL=$($SUDO dmidecode | grep -A4 '^System Information' | grep 'Manufacturer' | awk -F: '{print $2}')

    printf "┌────────────────────────── Informace o systemu ───────────────────────────┐\n"
    printf "│ System: %-64s │\n" "${STATION_SYSTEM} - ${STATION_ARCH}"
    printf "│ Model: %-64s  │\n" "${STATION_MODEL} - ${STATION_MACHINE}"
    printf "│ URL: %-64s    │\n" "${INSTALL_URL}"
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
    printf "│ Uzivatel: %-34s  Pojmenovani: %-13s │\n" "${USER_EMAIL}" "${STATION_NAME}"
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
        printf "│                  Zarizeni RTL SDR nebylo detekovano !                    │\n"
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
    IS_CTL=$(systemctl | grep $1 | awk '{print $1}' | tr -d '\n')
    if [[ -z ${IS_CTL} ]];then 
        systemctl status $1 &>/dev/null
        [[ "$?" != "4" ]] && IS_CTL=$1
    fi
    if [[ ! -z ${IS_CTL} ]];then
        IS_CTL_STATE=$(systemctl show ${IS_CTL} | grep UnitFileState | awk -F = '{print $2}' | tr -d '\n' )
        IS_CTL_PRESENT=$(systemctl show ${IS_CTL} | grep UnitFilePreset | awk -F = '{print $2}' | tr -d '\n' )
        IS_CTL_ACTIVE=$(systemctl show ${IS_CTL} | grep ActiveState | awk -F = '{print $2}' | tr -d '\n' )
        collor_set ${IS_CTL_STATE} && IS_CTL_STATE=${C}
        collor_set ${IS_CTL_PRESENT} && IS_CTL_PRESENT=${C}
        collor_set ${IS_CTL_ACTIVE} && IS_CTL_ACTIVE=${C}
        printf "│ %-27s %-14s %-16s %-12s │\n" "${IS_CTL}" "${IS_CTL_STATE}" "${IS_CTL_PRESENT}" "${IS_CTL_ACTIVE}"
    else
        IS_CTL=""
    fi
}

# Funkce zobrazi stav vybranych sluzeb
function info_components(){
    printf "┌ Komponenty / sluzby ─────── Po startu ──── Prednastaveni ── Status ──────┐\n"
    info_ctl "dump1090"    ; IS_DUMP=${IS_CTL}
    info_ctl "adsbfwd"     ; IS_ADSB=${IS_CTL}
    info_ctl "mlat-client" ; IS_MLAT=${IS_CTL}
    info_ctl "fr24feed"    ; IS_FEED=${IS_CTL}
    info_ctl "piaware"     ; IS_PIAW=${IS_CTL}
    info_ctl "lighttpd"
    info_ctl "rpimonitor"  ; IS_RPIM=${IS_CTL}
    info_ctl "vpn-czadsb"  ; IS_VPNC=${IS_CTL}
    if [[ "${OGN}" == "disable" ]] || [[ "${OGN}" == "enable" ]];then
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
    printf "┌ Sluzba ───── Instalace ───────────── Nastaveni ──────────────────────────┐\n"
    printf "│ Dump1090-fa  %-10s dev: %-15s ppm: %-5d  gain: %4s dB   │\n" "${DUMP1090}" "${DUMP1090_DEV}" "${DUMP1090_PPM}" "${DUMP1090_GAIN}"
    printf "│ ADSBfwd      %-10s dst: %-42s  │\n" "${ADSBFWD}" "${ADSBFWD_DST}"
    printf "│ Mlat-client  %-10s Server: %-40s │\n" "${MLAT}" "${MLAT_SERVER} -> ${MLAT_RESULT}"
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

# Funkce nabidne moznosti editace
function menu_edit(){
    printf "┌──────────────────────────── Uprava / editace ────────────────────────────┐\n"
    printf "│ 1. Identifikace (email, lokace)       a. ADSB servery tretich stran      │\n"
    printf "│ 2. Lokalizace (Souradnice a vyska)    b. Mlat-client (spousteni)         │\n"
    printf "│ 3. Dump1090   (dev, ppm, gain)        c. RpiMonitor  (spousteni)         │\n"
    printf "│ 4. RTL-SDR    (Serial number)         d. Reporter    (spousteni)         │\n"
    printf "│ 5. ADSBfwd    (destinace)             x. Smaze konfig soubor - vyvoj     │\n"
    printf "│ 6. VPN-CzADSB (local IP)              u. Upgrade/preinstalace aplikace   │\n"
    printf "│ 7. OGN /Flarm (dev, ppm, gain)        v. Aplikuj zmeny + upgrade         │\n"
    printf "│ 9. Aplikuj zmeny                      r. Aplikuj zmeny a proved restart  │\n"
    printf "│ 0. Aplikuj zmeny a ukonci skript      q. Ukonci skript bez aplikace zmen │\n"
    printf "├──────────────────────────────────────────────────────────────────────────┘\n"
    input "* Vase volba [0 - d] ?" '^[0-9a-duvrqx]$' ""
}

# Funkce nabidne moznosti ADSB serveru tretich stran 
function menu_third(){
    printf "┌─────────────────────── ADSB servery tretich stran ───────────────────────┐\n"
    printf "│ a. Piaware                      (https://www.flightaware.com)          x │\n"
    printf "│ b. Flightradar24                (https://www.flightradar24.com)        x │\n"
    printf "│ c. ADSBHub                      (https://www.adsbhub.org)              x │\n"
    printf "│ d. ADS-B Exchange               (https://www.adsbexchange.com/)        x │\n"
    printf "│ e. adsb.fi                      (https://adsb.fi/)                     x │\n"
    printf "│ f. ADS-B One                    (https://adsb.one)                     x │\n"
    printf "│ g. ADSB.lol                     (https://adsb.lol)                     x │\n"
    printf "│ h. TheAirTraffic                (https://theairtraffic.com)            x │\n"
    printf "│ i. adsb.chaos-consulting        (https://adsb.chaos-consulting.de)     x │\n"
    printf "│ j. Opensky Network              (https://opensky-network.org)          x │\n"
    printf "│   Poznamka:  Ve vystavbe, zatim podporovane jen nektere (neoznacene x)!  │\n"
    printf "├──────────────────────────────────────────────────────────────────────────┘\n"
    input "* Vase volba [a - d] ?" '^[a-d]{0,1}$' ""
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

# Funkce nastavi identifikacni udaje zarizeni
function set_identifikace(){
    printf "┌───────────────────────── Identifikace zarizeni ──────────────────────────┐\n"
    printf "│ Sklada z emailu a pojmenovani vlastnoho  prijicace.  Pojmenovani by melo │\n"
    printf "│ mit maximalne 9 znaku a bez mezer.  Je potreba pro identifikaci zarizeni │\n"
    printf "│ mlat klienta a OGN.                                                      │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"

    input "Registracni email (email musi byt platny) [${USER_EMAIL}]:" '^[a-zA-Z0-9_\.\-]*@[a-z0-9_\.\-]*\.[a-z]*$' "${USER_EMAIL}" 
    USER_EMAIL=${X}

    input "Oznaceni / pojmenovani prijimace [${STATION_NAME}]:" '^[a-zA-Z0-9_\.\-]{3,9}$' "${STATION_NAME}"
    STATION_NAME=${X}

    UPDATE_MLAT=true
    echo
}

# Funkce nastavi lokalizaci - umisteni zarizeni
function set_lokalizace(){
    printf "┌────────────────────────── Lokalizace zarizeni ───────────────────────────┐\n"
    printf "│ Urcuje umisteni zarizeni,  lepe receno  vlastni anteny.  Tyto udaje jsou │\n"
    printf "│ dulezite pro spravny vypocet poloh letadel pomoci mlat klienta. Zadavaji │\n"
    printf "│ se v zemepisne sirce a delce ve stupnich na minimalne 6 desetinych mist, │\n"
    printf "│ kde oddelovac je tecka, nikoliv carka.                                   │\n"
    printf "│ Nadmorska  vyska  se  zadava v metrech  nad  morem.  K zjistene vysce je │\n"
    printf "│ potreba jeste pripocitat umisteni anteny nad zemi.                       │\n"
    printf "│ Zemepisne  souradnice jsme schpni zjistit treba na webu https://mapy.cz. │\n"
    printf "└──────────────────────────────────────────────────────────────────────────┘\n"

    while true; do
#        input "Zemepisna sirka umisteni prijimace ve stupnich (XX.xxxxxx) [${STATION_LAT}]°:" '^[0-9\.\-]{}$' "${STATION_LAT}"
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
    UPDATE_MLAT=true
    echo
}

# Funkce overi dump1090 a nastavi hodnoty
function set_dump1090(){
    if [[ "${DUMP1090}" != "enable" ]] && [[ "${DUMP1090}" != "disable" ]];then
        check=`netstat -tln | grep 30005`
        [[ ${#check} -ge 10 ]] &&  DUMP1090="install"
        command -v dump1090 &>/dev/null &&  DUMP1090="install"
        command -v dump1090-fe &>/dev/null &&  DUMP1090="install"
        [[ -z ${DUMP1090} ]] && DUMP1090="enable"
    fi
    printf     "┌────────────────────────────── Dump1090-fa ───────────────────────────────┐\n"
    if [[ "${DUMP1090}" == "install"  ]];then
        printf "│ Na zarizeni byl detekovan program dump1090(fa) instalovany treti stranou.│\n"
        printf "│   Takto nainstalovany dump1090 neni mozne timto skriptem konfigurovat.   │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
    else
        printf "│ Dump1090  zpracovava data z RTL-SDR 'klicenky' a dekoduje vlastni  ACARS │\n"
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

# Funkce overi adsbfwd a nastavi hodnoty
function set_adsbfwd(){
    printf "┌──────────────────────────────── ADSBfwd ─────────────────────────────────┐\n"
    printf "│ ADSBfwd  preposila  ADSB  data z dump1090 komunite CzADSB.  Muze zaroven │\n"
    printf "│ preposilat i na jine, podobne projekty.  Tato  komponent  se  bude  take │\n"
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
        input "Prirazeny port, nebo seznam serveru kam se data posilaji [${ADSBFWD_DST}]:" '^[a-zA-Z0-9_\.\-\:\ ]*$' "${ADSBFWD_DST}"
        if [[ ${X} =~ ":" ]];then
            ADSBFWD_DST=${X}
        else
            ADSBFWD_DST="czadsb.cz:${X}"
        fi
        UPDATE_ADSBFWD=true
    fi
    echo
}

# Funkce overi mlatclient a nastavi hodnoty
function set_mlat(){
    printf "┌────────────────────────────── Mlat-client ───────────────────────────────┐\n"
    printf "│ Malt-client  pridava  casovou znacku ke zpravam bez GPS udajum a posila  │\n"
    printf "│ na MLAT server.  Ten na zaklade rozdilu casovych znacek od dalsich darcu │\n"
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

# Funkce nastavi zda instalovat RpiMonitor
function set_rpimonitor(){
    check=`cat /proc/cpuinfo | grep Raspberry`
    if [[ "${check}" == "" ]];then
        RPIMONITOR=""
    else
        printf "┌─────────────────────────────── RpiMonotor ───────────────────────────────┐\n"
        printf "│ RpiMonitor umoznuje pres webove rozhrani na portu 8888 sledovat aktualni │\n"
        printf "│ stav Raspberry PI.  Pokud system bezi na Raspberry, doporucujeme monitor │\n"
        printf "│ nainstalovat ale nejedna se o klicovou  komponentu.                      │\n"
        printf "└──────────────────────────────────────────────────────────────────────────┘\n"
        if [[ "${EXPERT}" == "user" ]];then
            [[ "${RPIMONITOR}" != "enable" ]] &&  UPDATE_RPIMONITOR=true
            RPIMONITOR="enable"
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
        echo  "Lokalni IP adrtesa VPN prirazena komunitou CzADSB."
        input "Pokud ji zatim nemate, ponechte prazdne. [${N2NADSB_LOCAL}]:" '^[0-9\.]*$' "${N2NADSB_LOCAL}" 
        N2NADSB_LOCAL=${X}

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
        if [[ "${REPORTER}" == "diseble" ]];then
            input "Ma se Reporter spoustet automaticky [y/N]:" '^[ynYN]*$' "n"
        else
            input "Ma se Reporter spoustet automaticky [Y/n]:" '^[ynYN]*$' "y"
        fi
        if [[ "$X" == "n" ]] || [[ "$X" == "N" ]];then
            REPORTER="disable"
        else
            REPORTER="enable"
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
bash -c "\$(wget -q -O - ${INSTALL_URL}/install-czadsb.sh)"
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
    fi
}

# Funkce ulozi nastavena data do konfiguracniho souboru
function set_cfg(){
/bin/cat <<EOM > ${CFG}
# Tento soubor byl vygenerovan automaticky pomoci konfiguracniho skriptu
# Pokud jsi nejste jisti ze vite co delate, pouzite konfiguracni skript

# Oznaceni verze konfigurace pro pripadnou zpetnou kompatibilitu
CFG_VERSION=2

# Identifikace uzivatele a stanice
# email musi byt zhodny z registracnim emailem
USER_EMAIL="${USER_EMAIL}"
# pojmenovani prijimace. Max 9 znaku bez mezer
STATION_NAME="${STATION_NAME}"

# Lokalizace anteny prijimace. Zemepisne souradnice ve stupnich.
STATION_LAT="${STATION_LAT}"
STATION_LON="${STATION_LON}"
# Lokalizace anteny prijimace. Nadmorska vyska v metrech
STATION_ALT="${STATION_ALT}"

# Stav dump1090
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

# ADSBfwd
# instalace DASBfwd [ notinstall | disable | enable ]
ADSBFWD="${ADSBFWD}"
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
LOCAL="${N2NADSB_LOCAL}"
# Maska pro lokalni sit
N2NADSB_MASK="255.255.254.0"

# Reporter
# instalace reporteru [ notinstall | disable | enable ]
REPORTER="${REPORTER}"
# url adresa pro odesilani reportu
REPORTER_URL="${REPORTER_URL}"

# OGN / Flarm
# instalace edgo [ notinstall | disable | enable ]
OGN="${OGN}"
# Nazev programu OGN / Flarm
OGN_NAME="rtlsdr-ogn"
# Vyber rtl-sdr zarizeni
OGN_DEV="${OGN_DEV}"
# Kalibrace rtl-sdr zarizeni
OGN_PPM="${OGN_PPM}"
# Zesileni rtl-sdr zarizebi
OGN_GAIN="${OGN_GAIN}"

# Informace o zarizeni:
# Jmeno uzivatele pod kterym se spusti nektere skripty 
CZADSB_USER="${CZADSB_USER}"
STATION_SYSTEM="${STATION_SYSTEM}"
STATION_ARCH="${STATION_ARCH}"
STATION_MODEL="${STATION_MODEL}"
STATION_MACHINE="${STATION_MACHINE}"
STATION_USERS="${STATION_USERS}"

EOM
}
# --------------------- Konec funkci pro nastaveni -----------------------------

# ------------------------ Fumkce pro instalaci --------------------------------
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

# ADSBfwd
function install_adsbfwd(){
    echo 
    echo -n "ADSBfwd"
    if [[ "${ADSBFWD}" == "disable" ]] || [[ "${ADSBFWD}" == "enable" ]];then
        UnitFileState=$(systemctl show ${ADSBFWD_NAME} | grep "UnitFileState" | awk -F = '{print $2}')
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade ADSBfwd"
            wget -q ${INSTALL_URL}/install-adsbfwd.sh -O /tmp/install.tmp
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
        fi
        [[ "${UnitFileState}" != "${MLAT}d" ]] && $SUDO systemctl ${MLAT} ${MLAT_NAME}
        if [[ "$(systemctl is-active ${MLAT_NAME})" != "active" ]];then
            echo " - ERROR: MLAT client neni spusten !"
        else
            echo " - restart sluzbu MLAT client pro aplikaci zmen."
            $SUDO systemctl restart ${MLAT_NAME}
        fi
    else
        echo " - instalace neni povolena, neprovadi se zadna zmena."
    fi
}

# RpiMonitor
function install_rpimonitor(){
    echo 
    echo -n "RpiMonitor (${RPIMONITOR}) "
    if [[ "${RPIMONITOR}" == "disable" ]] || [[ "${RPIMONITOR}" == "enable" ]];then
        UnitFileState=$(systemctl show rpimonitor.service | grep "UnitFileState" | awk -F = '{print $2}' )
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
        UnitFileState=$(systemctl show ${OGN_NAME} | grep "UnitFileState" | awk -F = '{print $2}' )
        if [[ "${UnitFileState}" == "" ]] || ${UPGRADE} ;then
            echo " - instalace / upgrade OGN / Flarm"
            wget -q ${INSTALL_URL}/install-ogn.sh -O /tmp/install.tmp
            . /tmp/install.tmp
            rm -f /tmp/install.tmp
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
        $SUDO sed -i "s/Gain[^;]*/Gain        =  ${OGN_GAIN} /g" /opt/rtlsdr-ogn/OGNstation.conf

        $SUDO sed -i "s/Latitude.[^;]*/Latitude   =  +${STATION_LAT} /g" /opt/rtlsdr-ogn/OGNstation.conf
        $SUDO sed -i "s/Longitude[^;]*/Longitude  =  +${STATION_LON} /g" /opt/rtlsdr-ogn/OGNstation.conf
        $SUDO sed -i "s/Altitude.[^;]*/Altitude   =  +${STATION_ALT} /g" /opt/rtlsdr-ogn/OGNstation.conf
        $SUDO sed -i "s/Call[^;]*/Call = \"${STATION_NAME}\" /g" /opt/rtlsdr-ogn/OGNstation.conf

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

# Funkce postupne pusti jednotlive instalacni skrypty, pokud je na nich zaznamenana zmena
function install_select(){
    if ${UPGRADE_ALL} ;then
        install_dump1090 && UPDATE_DUMP1090=false
        install_adsbfwd && UPDATE_ADSBFWD=false
        install_mlatclient && UPDATE_MLAT=false
        install_rpimonitor && UPDATE_RPIMONITOR=false
        install_n2nvpn && UPDATE_N2NVPN=false
        install_ogn && UPDATE_OGN=false
#       install_piaware && UPDATE_PIAWARE=false
    else
        ${UPDATE_DUMP1090} && install_dump1090 && UPDATE_DUMP1090=false
        ${UPDATE_ADSBFWD} && install_adsbfwd && UPDATE_ADSBFWD=false
        ${UPDATE_MLAT} && install_mlatclient && UPDATE_MLAT=false
        ${UPDATE_RPIMONITOR} && install_rpimonitor && UPDATE_RPIMONITOR=false
        ${UPDATE_N2NVPN} && install_n2nvpn && UPDATE_N2NVPN=false
        ${UPDATE_OGN} && install_ogn && UPDATE_OGN=false
#       ${UPDATE_PIAWARE} && install_piaware && UPDATE_PIAWARE=false
    fi
    UPGRADE=false
    UPGRADE_ALL=false
}
# ------------------------ Konec definic funkci --------------------------------
function offer_third(){
    while true; do
        clear
        info_logo; info_system; info_user end;
        menu_third
        case "$X" in
            a)  clear; info_logo
            ;;
            b)  clear; info_logo
            ;;
            *) return
            ;;
        esac
    done
}


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

# Over nainstalovani rtl sdr ovladacu a pripadne je doinstaluj
if ! command -v rtl_biast &>/dev/null ;then
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
    . ${CFG}
    CFG_NEW="false"
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
    fi
fi

# Dopln pripadne potrebne chybejejici vychozi hodnoty
set_default

# Vynuluj informaci ktere sluzby se maji instalocat / modifikovat
UPGRADE=false
UPGRADE_ALL=false
UPDATE_DUMP1090=false
UPDATE_ADSBFWD=false
UPDATE_MLAT=false
UPDATE_RPIMONITOR=false
UPDATE_N2NVPN=false
UPDATE_OGN=false
UPDATE_PIAWARE=false

# V pripade nove instalace spust pruvodce
if ${CFG_NEW} ;then
    clear
    info_logo; info_system; info_rtlsdr
    info_newinst
    set_expert
    set_identifikace
    set_lokalizace
    set_dump1090 "${EXPERT}"
    set_adsbfwd "${EXPERT}"
    set_mlat "${EXPERT}"
    set_rpimonitor
    set_n2nvpn
    set_reporter
    set_cfg
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
            set_dump1090
            [[ "${DUMP1090}" == "install" ]] && sleep 4 
        ;;
        4)  clear; info_logo
            set_rtl_sn
        ;;
        5)  clear; info_logo
            set_adsbfwd
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
        u)  UPGRADE_ALL=true
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
        x)  $SUDO rm ${CFG}
             exit 0
        ;;
    esac
    set_cfg
done


