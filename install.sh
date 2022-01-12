#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi:${plain} Bạn phải chạy tập lệnh này bằng người dùng root!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Không có phiên bản hệ thống được phát hiện, vui lòng liên hệ với tác giả của kịch bản！${plain}\n" && exit 1
fi

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "Phần mềm này không hỗ trợ các hệ thống 32 bit (x86), vui lòng sử dụng hệ thống 64 bit (x86_64), nếu phát hiện không chính xác, vui lòng liên hệ với tác giả."
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng CentOS 7 hoặc hệ thống cao hơn！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Ubuntu phiên bản 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl tar crontabs socat -y
    else
        apt install wget curl tar cron socat -y
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/soga.service ]]; then
        return 2
    fi
    temp=$(systemctl status soga | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_soga() {
    cd /usr/local/
    if [[ -e /usr/local/soga/ ]]; then
        rm /usr/local/soga/ -rf
    fi

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/RManLuo/crack-soga-v2ray/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}kiểmTraPhiênBảnSogaKhôngThànhCông,CóThểVượtQuáCácHạnChếApiCủaGitHub,VuiLòngThửLạiSauHoặcChỉĐịnhThủCôngCàiĐặtPhiênBảnSoga ${plain}"
            exit 1
        fi
        echo -e "Đã phát hiện phiên bản mới nhất của SOGA：${last_version}, Bắt đầu cài đặt"
        wget -N --no-check-certificate -O /usr/local/soga.tar.gz https://github.com/RManLuo/crack-soga-v2ray/releases/download/${last_version}/soga-cracked-linux64.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Tải xuống SOGA không thành công, hãy đảm bảo máy chủ của bạn có thể tải xuống tệp của GitHub${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/RManLuo/crack-soga-v2ray/releases/download/${last_version}/soga-cracked-linux64.tar.gz"
        echo -e "Bắt đầu cài đặt Soga v$1"
        wget -N --no-check-certificate -O /usr/local/soga.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Tải xuống SOGA V $ 1 Không thành công, hãy đảm bảo phiên bản này tồn tại${plain}"
            exit 1
        fi
    fi

    tar zxvf soga.tar.gz
    rm soga.tar.gz -f
    cd soga
    chmod +x soga
    mkdir /etc/soga/ -p
    rm /etc/systemd/system/soga.service -f
    cp -f soga.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop soga
    systemctl enable soga
    echo -e "${green}soga v${last_version}${plain} Cài đặt hoàn tất, thiết lập khởi động"
    if [[ ! -f /etc/soga/soga.conf ]]; then
        cp soga.conf /etc/soga/
        echo -e ""
        echo -e "Cài đặt mới, vui lòng xem hướng dẫn Wiki trước：https://github.com/sprov065/soga/wiki，Cấu hình nội dung cần thiết"
    else
        systemctl start soga
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}soga Khởi động lại thành công${plain}"
        else
            echo -e "${red}soga Có thể bắt đầu thất bại, vui lòng sử dụng nhật ký SOGA để xem thông tin nhật ký sau này, nếu bạn không thể khởi động, bạn có thể thay đổi định dạng cấu hình, vui lòng truy cập Wiki View：https://github.com/RManLuo/crack-soga-v2ray/wiki${plain}"
        fi
    fi

    if [[ ! -f /etc/soga/blockList ]]; then
        cp blockList /etc/soga/
    fi
    if [[ ! -f /etc/soga/dns.yml ]]; then
        cp dns.yml /etc/soga/
    fi
    curl -o /usr/bin/soga -Ls https://raw.githubusercontent.com/RManLuo/crack-soga-v2ray/master/soga.sh
    chmod +x /usr/bin/soga
    echo -e ""
    echo "soga Quản lý kịch bản cách sử dụng: "
    echo "------------------------------------------"
    echo "soga              - Menu quản lý hiển thị (nhiều tính năng hơn)"
    echo "soga start        - Khởi động soga"
    echo "soga stop         - Dừng soga"
    echo "soga restart      - Khởi động lại soga"
    echo "soga status       - Tình trạng soga"
    echo "soga enable       - Kích hoạt soga"
    echo "soga disable      - Vô hiệu hoá soga"
    echo "soga log          - Xem nhật ký SOGA"
    echo "soga update       - Update soga"
    echo "soga update x.x.x - Cập nhật phiên bản SOGA được chỉ định"
    echo "soga install      - Cài đặt SOGA"
    echo "soga uninstall    - Gỡ cài đặt SOGA"
    echo "soga version      - Xem phiên bản SOGA."
    echo "------------------------------------------"
}

echo -e "${green}Bắt đầu cài đặt${plain}"
install_base
install_acme
install_soga $1
