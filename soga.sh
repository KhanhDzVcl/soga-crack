#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi: ${plain} Bạn phải chạy tập lệnh này bằng người dùng root！\n" && exit 1

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
    echo -e "${red}Nếu bạn chưa phát hiện phiên bản hệ thống, vui lòng liên hệ với tác giả!${plain}\n" && exit 1
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
        echo -e "${red}Vui lòng sử dụng CentOS 7 Hoặc phiên bản cao hơn của hệ thống! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng Ubuntu 16 Hoặc phiên bản cao hơn của hệ thống! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [vỡ nợ$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Liệu để khởi động lại Soga" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhấn ENTER để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/KhanhDzVcl/soga-crack/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "Nhập phiên bản đã chỉ định (phiên bản mặc định mới nhất): " && read version
    else
        version=$2
    fi
#    confirm "Tính năng này sẽ buộc tải lại phiên bản mới nhất hiện tại, dữ liệu sẽ không bị mất, bạn có tiếp tục không??" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}Hủy bỏ${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/RManLuo/crack-soga-v2ray/master/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}Bản cập nhật hoàn tất và SOGA sẽ tự động được khởi động lại, vui lòng sử dụng trạng thái SOGA để xem tình huống khởi động${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

uninstall() {
    confirm "Bạn có phải gỡ cài đặt SOGA??" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop soga
    systemctl disable soga
    rm /etc/systemd/system/soga.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/soga/ -rf
    rm /usr/local/soga/ -rf

    echo ""
    echo -e "Gỡ cài đặt thành công, nếu bạn muốn xóa tập lệnh này, hãy hết sau khi chạy ${green}rm /usr/bin/soga -f${plain} Xóa bỏ"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}SOGA đã chạy, không cần phải bắt đầu lại, nếu bạn cần khởi động lại, hãy chọn Khởi động lại${plain}"
    else
        systemctl start soga
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}Cài đặt soga thành công,có thể sử dụng${plain}"
        else
            echo -e "${red}Cài đặt soga lỗi${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop soga
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}Soga dừng thành công${plain}"
    else
        echo -e "${red}SOGA STOPS không thành công, có thể vì thời gian dừng là hơn hai giây, vui lòng kiểm tra thông tin nhật ký sau.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart soga
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}Cài đặt soga thành công,có thể sử dụng${plain}"
    else
        echo -e "${red}Cài đặt soga lỗi${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status soga --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable soga
    if [[ $? == 0 ]]; then
        echo -e "${green}Cài đặt SOGA đang tự khởi động${plain}"
    else
        echo -e "${red}SOGA Cài đặt thất bại${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable soga
    if [[ $? == 0 ]]; then
        echo -e "${green}Soga hủy bỏ sự khởi đầu của việc tự bắt đầu${plain}"
    else
        echo -e "${red}SOGA hủy bỏ thất bại${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u soga.service -e --no-pager
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://github.com/sprov065/blog/raw/master/bbr.sh)
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}Cài đặt thành công BBR, vui lòng khởi động lại máy chủ${plain}"
    else
        echo ""
        echo -e "${red}Tải xuống tập lệnh cài đặt BBR không thành công, vui lòng kiểm tra xem đơn vị có thể kết nối Github không${plain}"
    fi

    before_show_menu
}

update_shell() {
    wget -O /usr/bin/soga -N --no-check-certificate https://raw.githubusercontent.com/KhanhDzVcl/soga-crack/main/soga.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Tải xuống kịch bản không thành công, vui lòng kiểm tra xem đơn vị có thể kết nối Github không${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/soga
        echo -e "${green}Tập lệnh nâng cấp thành công, vui lòng chạy lại tập lệnh${plain}" && exit 0
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

check_enabled() {
    temp=$(systemctl is-enabled soga)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}SOGA đã được cài đặt, vui lòng không lặp lại cài đặt${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui lòng cài đặt SOGA trước${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Trạng thái SOGA: ${green}Chạy${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Trạng thái SOGA: ${yellow}Không chạy${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Trạng thái SOGA: ${red}Lỗi${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Cho dù là khởi động: ${green}Đúng${plain}"
    else
        echo -e "Cho dù là khởi động: ${red}không${plain}"
    fi
}

show_soga_version() {
    echo -n "soga Phiên bản:"
    /usr/local/soga/soga -v
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
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
    echo "BẢN QUYỀN SOGA VIỆT HOÁ THUỘC VỀ FLASHVPN"
}

show_menu() {
    echo -e "
  ${green}soga Kịch bản quản lý back-end,${plain}${red}Không áp dụng cho Docker${plain}
--- https://github.com/RManLuo/crack-soga-v2ray ---
  ${green}0.${plain} Thoát kịch bản
————————————————
  ${green}1.${plain} Cài đặt soga
  ${green}2.${plain} thay mới soga
  ${green}3.${plain} Gỡ cài đặt soga
————————————————
  ${green}4.${plain} bắt đầu soga
  ${green}5.${plain} dừng lại soga
  ${green}6.${plain} Khởi động lại soga
  ${green}7.${plain} Kiểm tra soga trạng thái
  ${green}8.${plain} Kiểm tra soga Đăng nhập.
————————————————
  ${green}9.${plain} cài đặt soga Boot.
 ${green}10.${plain} Hủy bỏ soga Boot.
————————————————
 ${green}11.${plain} Một cài đặt chính bbr (Kernel mới nhất)
 ${green}12.${plain} Kiểm tra soga Phiên bản
 "
    show_status
    echo && read -p "Vui lòng nhập lựa chọn [0-12]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_soga_version
        ;;
        *) echo -e "${red}Vui lòng nhập đúng số [0-12]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_soga_version 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
