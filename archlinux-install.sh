#!/bin/bash
# 引入 PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 安装 lolcat
Install_lolcat(){
    curl -LO https://github.com/busyloop/lolcat/archive/master.zip
    unzip master.zip
    cd locat-master/bin
    gem install lolcat
    cd ../../
    rm -rf lolcat-master/ master.zip
}
# archlinux 新的联网方式
iwd(){
    while true
    do
        iwctl device list
        read -e -p "Please enter device name:" device_name
        if ! [[ -z ${device_name} ]] ; then
            iwctl station ${device_name} get-networks
            read -e -p "Please enter wifi name:" wifi_name
            read -e -p "Please enter wifi passwd:" wifi_pwd
            iwctl --passphrase ${wifi_pwd} station ${device_name} connect ${wifi_name}
            Network_check
            if (($? == 0)) ; then
                break
            fi
        fi
    done

}

# 安装软件函数，两个参数，$1 系统，$2 要安装的软件名字
Ipp(){
    for f in "$@"
    do 
        if test ${f} == $1
        then
            continue 
        fi 
        if ! type ${f} > /dev/null 2>&1; then
            case $1 in
                debian|ubuntu|devuan|deepin)
                    if test ${f} == "lolcat"
                    then
                        apt autoremove libevent-core libevent-pthreads libopts25 sntp
                        Install_lolcat
                    else
                        apt-get install ${f}
                    fi
                    ;;
                centos|fedora|rhel)
                    yumdnf="yum"
                    if test "$(echo "$VERSION_ID >=22" | bc)" -ne 0; then
                        yumdnf="dnf"
                    fi
                    if test ${f} == "lolcat"
                    then
                        Install_lolcat
                    else
                        ${yumdnf} install ${f}
                    fi
                    ;;
                arch|manjaro)
                    Qs=`pacman -Qs ${f}`
                    if [[ ${Qs} == "" ]] ; then
                        pacman -S ${f}
                        if [ $? -ne 0 ]; then
                            # yay_var 记录下原本安装的软件
                            yay_Qs=`pacman -Qs yay`
                            if [[ ${yay_Qs} == "" ]] ; then
                            pacman -S yay
                            fi
                            sudo -u $(logname) yay -S ${f}
                        fi
                    fi
                    ;;
                *)
                    echo -e "\033[43;37m The script does not apply to the $1 system \033[0m"
                    exit 1
                ;;
            esac
        fi
    done
}

# 切换 root 用户
Check_root(){
    [[ $EUID != 0 ]] && echo -e "\033[31m 当前账号非 ROOT (或没有ROOT权限)，无法继续操作，请使用 sudo su 来获取临时 ROOT 权限（执行后会提示输入当前账号的密码）\033[0m" && exit 1
}

# 检测网络链接畅通
Network_check()
{
    #超时时间
    local timeout=1
    #目标网站
    local target=www.baidu.com
    #获取响应状态码
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
    if [ "x$ret_code" = "x200" ]; then
        #网络畅通
        echo -e "\033[36mNetwork: connected \033[0m"
        return 1
    else
        #网络不畅通
        return 0
    fi
    return 0
}

Network_link(){
    echo -e "\033[45;37mEnter the number [1~n] to select the networking method (recommended: WIFI)  \033[0m"
    select net in "WIFI" "DHCP" "ADSL" "SKIP"
    do
        case ${net} in
            "WIFI")
                echo "Use WIFI connection"
                iwd
                break
                ;;
            "DHCP")
                echo "Use DHCP connection"
                dhcpcd
                break
                ;;
            "ADSL")
                echo "Use ADSL connection"
                pppoe-setup
                systemctl start adsl
                break
                ;;
            "SKIP")
                echo -e "\033[41;30m Skip network connection failed \033[0m"
                exit 1
                ;;
            *)
                echo -e "\033[43;37m Input errors, please re-enter \033[0m"
        esac
    done

}

# 系统检查
System_check(){
    # 切换 root 用户
    Check_root
    
    # 检查系统类型
    echo -e "\033[45;37m CHECK THE SYSTEM \033[0m"
    echo "System: ${os}"
    
    # 当前用户
    echo "USER: $USER"
    
    # 检查 x86_64 架构
    bit=`uname -m`
    if test ${bit} == "x86_64" ;then
        bit="x86_64"
        echo "Architecture: ${bit}"
    else
        echo -e "\033[43;37m The script is not applicable to non-x86_64 architecture systems \033[0m"
        exit 1
    fi
    
    # 检查网络
    Network_check
    if [ $? -eq 0 ];then
        echo ""
        echo -e "\033[31m The network is not smooth, please check the network settings \033[0m"
        Network_link
        exit 1
    fi

    # 安装终端彩虹屁
    archiso=`lsblk -nlo MOUNTPOINT | sed -n '/archiso/='`
    if [[ ${archiso} == "" ]] ; then
        Ipp $ID ruby lolcat
    fi
}

# 定义全局变量
iso_release=`date -d "$(date +%y%m)01 last month" +%Y.%m.01`
source /etc/os-release
os="$ID"
# 引导方式
grub=UEFI
shell_ver="0.2.0"
# 脚本标题图案
System_check 

echo -e "\033[33m 
    ___              __    __    _                     ____           __        ____
   /   |  __________/ /_  / /   (_)___  __  ___  __   /  _/___  _____/ /_____ _/ / /
  / /| | / ___/ ___/ __ \/ /   / / __ \/ / / / |/_/   / // __ \/ ___/ __/ __ \`/ / / 
 / ___ |/ /  / /__/ / / / /___/ / / / / /_/ />  <   _/ // / / (__  ) /_/ /_/ / / /  
/_/  |_/_/   \___/_/ /_/_____/_/_/ /_/\__,_/_/|_|  /___/_/ /_/____/\__/\__,_/_/_/   
                                                                                    
=================================== Quick Start ====================================
||     OS: Arch Linux x86_64                                                      ||
||     Description: ArchLinux system installation script                          ||
||     Version:${shell_ver}                                                              ||
||     Author: teaper                                                             ||
||     GitHub:https://github.com/teaper/archlinux-install-script                  ||
||     Help:https://teaper.dev/ArchLinux-java-febe1fe5bc764929aaeb02ed933c04f8    ||
====================================================================================
\033[0m" | lolcat
# TITLE 生成: http://patorjk.com/software/taag/#p=display&f=Slant&t=teaper

# 检查脚本更新
Update_shell(){
    latest=$(curl -L "https://api.github.com/repos/teaper/archlinux-install-script/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    echo "最新版本:${latest}"
    for((i=1;i<=3;i++));
    do
        latest_num=`echo "${latest}" | cut -d "." -f ${i}`
        current_num=`echo "${shell_ver}" | cut -d "." -f ${i}`
        if (( latest_num > current_num )) ; then
            echo -e "当前版本: v${shell_ver} 最新版本: \033[36m${latest}\033[0m"
            read -e -p "是否下载最新版本<<y/n>>:" download_shell_yn
            [[ -z ${download_shell_yn} ]] && download_shell_yn="y"
            if [[ ${download_shell_yn} == [Yy] ]] ; then
                curl -LO https://github.com/teaper/archlinux-install-script/releases/download/${latest}/archlinux-install.sh
                echo -e "\033[33m 脚本已更新\033[0m"
                exit 1
            fi
            break
        fi
    done
}

# 制作启动盘
Dd_iso(){
    echo -e "\033[45;37m 即将制作启动盘 \033[0m"
    # 判断是否插入 U 盘
    usb_status=`ls /proc/scsi/ | grep usb-storage`
    if [[ ${usb_status} != "" ]]; then
        echo "已插入 U 盘" && echo
        # 判断 U 盘大小
        lsblk
        read -e -p "输入你想要写入的设备（默认：sdb）:" dd_disk
        if [[ ${dd_disk} == "" ]]; then
            dd_disk="sdb"
        fi
        
        # 判断路径是否正确
        ls /dev/${dd_disk} >/dev/null 2>&1
        if test $? != 0 ;then
            echo -e "\033[41;37m 路径不存在 \033[0m"
            exit 1
        fi
        echo "U 盘路径: /dev/${dd_disk}" && echo

        # 判断 U 盘是 TB 还是 GB
        disk_unit=`fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $4}' | cut -d "," -f 1`
        disk_GB=`fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $3}' | cut -d "." -f 1`
        if test $disk_unit == "GiB"; then
            dd_disk_size=`awk 'BEGIN{print '${disk_GB}'*1024*1024*1024}'`
        elif test $disk_unit == "TiB"; then
            dd_disk_size=`awk 'BEGIN{print '${disk_GB}'*1024*1024*1024*1024}'`
        else
            echo -e "\033[41;30m U 盘可用空间不足，请更换 U 盘后再试 \033[0m"
            exit 1
        fi
        
        echo -e "\033[45;37m U 盘容量: `fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $3}'` `fdisk -l /dev/${dd_disk} | awk -F " " 'NR==1{print $4}' | cut -d "," -f 1` \033[0m"
        if test $[dd_disk_size] -gt $[iso_d_size]; then
            echo -e "\033[43;37m 开始写入 \033[0m"
            dd if=archlinux-${iso_release}-${bit}.iso of=/dev/${dd_disk} bs=1440k oflag=sync
            echo -e "\033[45;37m 写入完成\033[0m"
        else
            echo -e "\033[41;30m U 盘可用空间不足，请更换 U 盘后再试 \033[0m"
        fi
    else
        echo -e "\033[31m 请插入 U 盘后再试 \033[0m"
    fi
}

#下载 iso 镜像
Download_iso(){
    echo -e "\033[45;37m 下载 iso 镜像 \033[0m"
    if [[ -e archlinux-${iso_release}-${bit}.iso ]] ; then
        iso_d_size=`ls -l archlinux-${iso_release}-${bit}.iso | awk '{print $5}'`
        # 文件完整性
        echo -e "\n\033[33m 校验文件\033[0m"
        curl -LO http://mirrors.163.com/archlinux/iso/${iso_release}/sha1sums.txt >/dev/null 2>&1
        sha1sums_iso=`sha1sum -b archlinux-${iso_release}-${bit}.iso | cut -d " " -f 1`
        sha1sum_yn=`head -1  sha1sums.txt | cut -d " " -f 1`
        echo -e "\033[33m 校验完成\033[0m\n"
        rm -rf sha1sums.txt
        #判断校验码是否匹配
        if [[ ${sha1sums_iso} != ${sha1sum_yn} ]] ; then
            echo -e "\033[41;30m iso 文件已损坏，正在重新下载 \033[0m"
            curl -LO http://mirrors.163.com/archlinux/iso/${iso_release}/archlinux-${iso_release}-${bit}.iso
            Download_iso
        else
            Dd_iso
        fi
    else 
        read -e -p "当前文件夹下没有 archlinux-${iso_release}-${bit}.iso 镜像，是否立即下载<<y/n>>" iso_yn
        [[ -z ${iso_yn} ]] && iso_yn="y"
        if [[ ${iso_yn} == [Yy] ]]; then
            echo "\n正在下载 iso 镜像文件"
            curl -LO http://mirrors.163.com/archlinux/iso/${iso_release}/archlinux-${iso_release}-${bit}.iso
            Download_iso
        else
            echo -e "\033[43;37m 已取消启动盘制作 \033[0m"
        fi
    fi
}

# 检查分区情况是否合理
Cfdisk_check(){
    echo -e "\033[45;37m CHECK PARTITION RESULTS \033[0m"
    # part_count:类型为 part 的分区个数<int>
    part_lines=`lsblk -nlo TYPE |  sed -n  '/part/='`
    part_count=`lsblk -nlo TYPE | sed -n '/part/=' | awk 'END{print NR}'`
    NO=0
    
    # 判断镜像U盘是否存在，删除 U 盘分区行号
    live_cd_part_lines=`lsblk -nlo NAME | sed -n '/sdb[1-9]/='`
    if [[ ${live_cd_part_lines} != "" ]] ; then
        part_lines=`echo ${part_lines/${live_cd_part_lines}/}`
    fi

    # 判断分区个数
    if ((${part_count} < 4)) ; then
        echo -e "\033[31m Unreasonable number of partitions, go back and repartition \033[0m" 
        # 分区小于 4 个强制重新分区
        Cfdisk_ALL
    else
        # 检查分区情况和策略匹配程度
        echo -e "Number of available disks: ${part_count}"
        for part_line in ${part_lines}
        do
            name=`lsblk -nlo NAME | sed -n ${part_line}p`
            size=`lsblk -nlo SIZE | sed -n ${part_line}p`
            # 存储单位G/T<byte>
            size_bit=${size: -1}
            # 去掉存储单位后的数字<double>
            size_num=`echo ${size} | cut -d "T" -f 1 | cut -d "G" -f 1 | cut -d "M" -f  1`
            # 转化成 GB 之后的存储大小<double>
            size_GB=`echo | awk '{print '${size_num}'}'`

            # 单位转化成 GB
            if test ${size_bit} == "T" ; then
                size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'*1024}'`
            elif test ${size_bit} == "M" ; then
                size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'/1024}'`
            fi

            # 获取 partmap 中记录的分盘数据
            partmap_name=`cut partmap  -d " " -f 1 | grep ${name}`
            partmap_size=`cat partmap | grep ${name} | cut -d " " -f 2`
            partmap_size_num=`echo ${partmap_size} | cut -d "T" -f 1 | cut -d "G" -f 1 | cut -d "M" -f  1`
            partmap_size=`echo | awk '{print '${partmap_size_num}'}'`

            # 分区结果比原来小一点，造成无法判断
            partmap_size_add1=`awk 'BEGIN{print '${partmap_size}'-1}'`
            
            # 小数位无法 if 判断
            size_GB_1=`awk 'BEGIN{print '${size_GB}'*10}'`
            partmap_size_add1_1=`awk 'BEGIN{print '${partmap_size_add1}'*10}'`
            partmap_size_1=`awk 'BEGIN{print '${partmap_size}'*10}'`

            if ((${size_GB_1} >= ${partmap_size_add1_1})) && ((${size_GB_1} <= ${partmap_size_1})) ; then
                echo -e "${name} \033[35m[OK]\033[0m SIZE: ${size_GB}G \033[36mMATCH\033[0m ${partmap_size}G"
            else
                echo -e "${name} \033[31m[NO]\033[0m SIZE: ${size_GB}G \033[31mMISMATCH\033[0m ${partmap_size}G"
                NO=`awk 'BEGIN{print '${NO}'+1}'`
            fi
        done
        
        if ((${NO} != 0)) ; then
            echo -e "\033[33mWarning: You have ${NO} partitions unreasonable (recommendation: repartition)\033[0m"
            select num in "PREVIOUS" "SKIP" "EXIT"
            do
                case ${num} in
                    "PREVIOUS")
                        Cfdisk_ALL
                        break
                        ;;
                    "SKIP")
                        break
                        ;;
                    "EXIT")
                        echo -e "\033[41;30m Exit script \033[0m"
                        rm diskmap >/dev/null 2>&1 && echo
                        exit 1
                        break
                        ;;
                    *)
                        echo -e "\033[43;37m Input errors, please re-enter \033[0m"
                esac
            done
        fi
        rm diskmap >/dev/null 2>&1 && echo
        
    fi
    # 格式化分区
     Mkfs_disks
}

# 开始分区
Cfdisk_ALL(){
    echo -e "\033[45;37m READING PARTITION STRATEGY \033[0m"
    cat diskmap && echo
    echo -e "\033[43;37m Partition order \033[0m"
    echo "Single disk:   EFI > SWAP > HOME > /"
    echo "Dual disk:   EFI > SWAP > / > HOME"
    read -e -p "During the partitioning process, the partitioning strategy cannot be viewed. It is recommended to take a picture and record before continuing <<y/n>>" cfdisk_yn
    [[ -z ${cfdisk_yn} ]] && cfdisk_yn="y"
    if [[ ${cfdisk_yn} == [Yy] ]]; then
        echo ""
        echo -e "\033[45;37m Start partition \033[0m"
        for disk_line in ${disk_lines}
        do
            var=`lsblk -nlo NAME | sed -n ${disk_line}p`
            cfdisk /dev/${var}
        done
        # 分区完成查看一眼睛
        echo "Partition successful" && echo
        echo -e "\033[43;37m View partition results \033[0m"
        lsblk
        echo ""
    else
        echo -e "\033[43;37m Unpartitioned \033[0m"
        echo ""
    fi

    # 检查分区是否合理
    Cfdisk_check
}

# 手动格式化
Cm_disks(){
    echo -e "\033[45;37m MANUAL FORMAT \033[0m"
    lsblk -nlo NAME,SIZE,TYPE,MOUNTPOINT | grep part
    echo -e "\033[33m \nTip: Some commands are as follows: \033[0m"
    echo -e "\033[36m [FORMAT] mkfs.ext4 /dev/</ PARTITION> \033[0m"
    echo -e "\033[36m [FORMAT] mkfs.vfat /dev/<EFI PARTITION> \033[0m"
    echo -e "\033[36m [FORMAT] mkswap -f /dev/<[SWAP] PARTITION> \033[0m"
    echo -e "\033[32m [OPEN] swapon /dev/<SWAP PARTITION> \033[0m"
    echo -e "\033[36m [FORMAT] mkfs.ext4 /dev/<HOME PARTITION> \033[0m"
    echo -e "\033[33m \n(Tip: Type q and press Enter to end the command input)  \033[0m"
    while true
    do
        read -e -p " >> " cmd
        [[ -z ${cmd} ]] && cmd=""
        if [[ ${cmd} != [Qq] ]] ; then
            echo "#!/bin/bash" > cmd.sh
            echo "${cmd}" >> cmd.sh
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] Running '${cmd}'" >> cmd.log
            /bin/bash cmd.sh 
            rm cmd.sh
        else
            break
        fi
    done
    echo -e "\n\033[33m[Operation log]\033[0m"
    cat cmd.log
    rm cmd.log >/dev/null 2>&1 
    echo ""
}

# 手动挂载
Cm_mount(){
    echo -e "\033[45;37m MANUALLY MOUNT \033[0m"
    lsblk -nlo NAME,SIZE,TYPE,MOUNTPOINT | grep part
    echo -e "\033[33m \nTip: Some commands are as follows: \033[0m"
    echo -e "\033[36m [MOUNT] mount /dev/</ PARTITION> /mnt \033[0m"
    echo -e "\033[32m [CREATE] mkdir /mnt/home \033[0m"
    echo -e "\033[32m [CREATE] mkdir -p /mnt/boot/EFI \033[0m"
    echo -e "\033[36m [MOUNT] mount /dev/<HOME PARTITION> /mnt/home \033[0m"
    echo -e "\033[36m [MOUNT] mount /dev/<EFI PARTITION> /mnt/boot/EFI \033[0m"
    echo -e "\033[33m \n(Tip: Type q and press Enter to end the command input)  \033[0m"
    
    while true
    do
        read -e -p " >> " cmd
        [[ -z ${cmd} ]] && cmd=""
        if [[ ${cmd} != [Qq] ]] ; then
            echo "#!/bin/bash" > cmd.sh
            echo "${cmd}" >> cmd.sh
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] Running '${cmd}'" >> cmd.log
            /bin/bash cmd.sh 
            rm cmd.sh
        else
            break
        fi
    done
    echo -e "\n\033[33m[Operation log]\033[0m"
    cat cmd.log
    rm cmd.log >/dev/null 2>&1 
    echo ""
}

# 挂载分区
Mount_parts(){
    echo""
    echo -e "\033[45;37m MOUNT PARTITION \033[0m"
    if ((${NO} != 0)) ; then
        #手动挂载分区
        echo -e "\033[33mWarning: You have ${NO} partitions unreasonable (recommendation: mount manually)\033[0m"
        select num in "PREVIOUS" "MANUAL" "SKIP" "EXIT"
        do
            case ${num} in
                "PREVIOUS")
                    Cfdisk_ALL
                    break
                    ;;
                "MANUAL")
                    rm diskmap >/dev/null 2>&1 && echo
                    rm partmap >/dev/null 2>&1 && echo
                    # 手动挂载
                    Cm_mount
                    break
                    ;;
                "SKIP")
                    rm diskmap >/dev/null 2>&1 && echo
                    rm partmap >/dev/null 2>&1 && echo
                    break
                    ;;
                "EXIT")
                    echo -e "\033[41;30m Exit script \033[0m"
                    rm diskmap >/dev/null 2>&1 && echo
                    rm partmap >/dev/null 2>&1 && echo
                    exit 1
                break
                    ;;
                *)
                    echo -e "\033[43;37m Input errors, please re-enter \033[0m"
            esac
        done

    else
        # 自动挂载分区
        #part_lines:所有类型为 part 的分区行号<list>
        part_lines=`lsblk -nlo TYPE | sed -n '/part/=' | sort -r`
    
        # 判断镜像U盘是否存在，删除 U 盘分区行号
        live_cd_part_lines=`lsblk -nlo NAME | sed -n '/sdb[1-9]/=' | sort -r`
        if [[ ${live_cd_part_lines} != "" ]] ; then
            part_lines=`echo ${part_lines/${live_cd_part_lines}/}`
        fi

        for part_line in ${part_lines}
        do
            name=`lsblk -nlo NAME | sed -n ${part_line}p`
            name_top=`echo ${name} | cut -b 1-3`
            name_end=${name: -1}

            # 挂载
            if ((${disk_count} == 1)) ; then
                # 单个硬盘
                if ((${name_end} == 1)) ; then
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/boot/EFI"
                    if [[ ! -d "/mnt/boot/EFI" ]] ; then
                        mkdir -p /mnt/boot/EFI
                        echo -e "\033[33m mkdir -p /mnt/boot/EFI \033[0m"
                    fi
                    mount /dev/${name} /mnt/boot/EFI
                elif ((${name_end} == 2)) ; then
                    echo "No need to mount swap partition"
                elif ((${name_end} == 3)) ; then
                    # 第三 home 分区
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/home"
                    if [[ ! -d "/mnt/home" ]] ; then
                        mkdir /mnt/home
                        echo -e "\033[33m mkdir /mnt/home \033[0m"
                    fi
                    mount /dev/${name} /mnt/home
                elif ((${name_end} == 4)) ; then
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt"
                    mount /dev/${name} /mnt
                else
                    echo "Unmounted partition:/dev/${name}"
                fi

            elif ((${disk_count} == 2)) ; then
                # 两个硬盘
                if [[ ${name_top} == "nvm" ]] ; then
                    if ((${name_end} == 1)) ; then
                        echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/boot/EFI"
                        if [[ ! -d "/mnt/boot/EFI" ]] ; then
                            mkdir -p /mnt/boot/EFI
                            echo -e "\033[33m mkdir -p /mnt/boot/EFI \033[0m"
                        fi
                        mount /dev/${name} /mnt/boot/EFI
                    elif ((${name_end} == 2)) ; then
                        echo "No need to mount swap partition"
                    elif ((${name_end} == 3)) ; then
                        # 第三个根分区
                        echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt"
                        mount /dev/${name} /mnt
                    else
                        echo "Unmounted partition: /dev/${name}"
                    fi
                else
                    echo -e "\033[33m[OK]\033[0m mount /dev/${name} /mnt/home"
                    if [[ ! -d "/mnt/home" ]] ; then
                        mkdir /mnt/home
                        echo -e "\033[33m mkdir /mnt/home \033[0m"
                    fi
                    mount /dev/${name} /mnt/home
                fi
            else
                echo -e "\033[43;37m Unable to mount unknown partition \033[0m"
            fi
        done
    fi
    rm diskmap >/dev/null 2>&1
    rm partmap >/dev/null 2>&1
}

# 格式化分区
Mkfs_disks(){
    echo ""
    echo -e "\033[45;37m FORMAT PARTITION \033[0m"
    if ((${NO} != 0)) ; then
        #手动格式化分区
        echo -e "\033[33mWarning: You have ${NO} partitions unreasonable (recommendation: format manually)\033[0m"
        select num in "PREVIOUS" "MANUAL" "SKIP" "EXIT"
        do
            case ${num} in
                "PREVIOUS")
                    Cfdisk_ALL
                    break
                    ;;
                "MANUAL")
                    rm diskmap >/dev/null 2>&1
                    # 手动格式化
                    Cm_disks
                    break
                    ;;
                "SKIP")
                    rm diskmap >/dev/null 2>&1
                    break
                    ;;
                "EXIT")
                    echo -e "\033[41;30m Exit script \033[0m"
                    rm diskmap >/dev/null 2>&1 
                    exit 1
                break
                    ;;
                *)
                    echo -e "\033[43;37m Input errors, please re-enter \033[0m"
            esac
        done

    else
        # 自动格式化分区
        #part_lines:所有类型为 part 的分区行号<list>
        part_lines=`lsblk -nlo TYPE | sed -n '/part/='`
        
        # 判断镜像U盘是否存在，删除 U 盘分区行号
        live_cd_part_lines=`lsblk -nlo NAME | sed -n '/sdb[1-9]/='`
        if [[ ${live_cd_part_lines} != "" ]] ; then
            part_lines=`echo ${part_lines/${live_cd_part_lines}/}`
        fi

        for part_line in ${part_lines}
        do
            name=`lsblk -nlo NAME | sed -n ${part_line}p`
            name_top=`echo ${name} | cut -b 1-3`
            name_end=${name: -1}

            # 格式化
            if ((${disk_count} == 1)) ; then
                # 单个硬盘
                if ((${name_end} == 1)) ; then
                    echo -e "\033[33m[OK]\033[0m mkfs.vfat /dev/${name}"
                    mkfs.vfat /dev/${name}
                elif ((${name_end} == 2)) ; then
                    echo -e "\033[33m[OK]\033[0m mkswap -f /dev/${name}"
                    mkswap -f /dev/${name}
                    echo -e "\033[33m[OK]\033[0m swapon /dev/${name}"
                    swapon /dev/${name}
                elif ((${name_end} == 3)) ; then
                    # 第三 home 分区
                    echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                    mkfs.ext4 /dev/${name}
                elif ((${name_end} == 4)) ; then
                    echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                    mkfs.ext4 /dev/${name}
                else
                    echo "Unformatted partition: /dev/${name}"
                fi

            elif ((${disk_count} == 2)) ; then
                # 两个硬盘
                if [[ ${name_top} == "nvm" ]] ; then
                    if ((${name_end} == 1)) ; then
                        echo -e "\033[33m[OK]\033[0m mkfs.vfat /dev/${name}"
                        mkfs.vfat /dev/${name}
                    elif ((${name_end} == 2)) ; then
                        echo -e "\033[33m[OK]\033[0m mkswap -f /dev/${name}"
                        mkswap -f /dev/${name}
                        echo -e "\033[33m[OK]\033[0m swapon /dev/${name}"
                        swapon /dev/${name}
                    elif ((${name_end} == 3)) ; then
                        # 第三个根分区
                        echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                        mkfs.ext4 /dev/${name}
                    else
                        echo "Unformatted partition: /dev/${name}"
                    fi
                else
                    echo -e "\033[33m[OK]\033[0m mkfs.ext4 /dev/${name}"
                    mkfs.ext4 /dev/${name}
                fi
            else
                echo -e "\033[43;37m Unable to format unknown partition \033[0m"
            fi
        done
    fi
    #挂载分区
    Mount_parts
}


# 分区策略
Disk_map(){
    echo -e "\033[45;37m CURRENT DISK PARTITION SITUATION \033[0m"
    lsblk -l
    # disk_names:所有磁盘和分区的名字<list>
    disk_names=`lsblk -nlo NAME`
    # disk_lines:类型为 disk 的磁盘行号<list>
    disk_lines=`lsblk -nlo TYPE |  sed -n  '/disk/='`
    # disk_count:类型为 disk 的磁盘个数<int>
    disk_count=`lsblk -nlo TYPE | sed -n '/disk/=' | awk 'END{print NR}'`

    echo -e "\nNumber of available disks: ${disk_count}"
    for disk_line in ${disk_lines}
    do
        name=`lsblk -nlo NAME | sed -n ${disk_line}p`
        size=`lsblk -nlo SIZE | sed -n ${disk_line}p`

        echo "PATH: /dev/${name}  SIZE: ${size}"
    done
    echo ""
    
    # 判断镜像U盘是否存在，删除 U 盘行号
    live_cd_disk_line=`lsblk -nlo TYPE,MOUNTPOINT | sed -n '/part \/run\/archiso/='`
    if [[ ${live_cd_disk_line} != "" ]] ; then
        let disk_count=$disk_count-1
        let live_cd_disk_line=$live_cd_disk_line-1
        disk_lines=`echo ${disk_lines/${live_cd_disk_line}/}`
    fi
    
    #生成策略
    echo -e "\033[45;37m GENERATE PARTITIONING STRATEGY \033[0m"
    echo "NAME    SIZE    TYPE    MOUNTPOINT" > diskmap
    echo "NAME SIZE" > partmap
    for disk_line in ${disk_lines}
    do
        # 获取磁盘名称和大小
        name=`lsblk -nlo NAME | sed -n ${disk_line}p`
        size=`lsblk -nlo SIZE | sed -n ${disk_line}p`
        # 存储单位G/T<byte>
        size_bit=${size: -1}
        # 去掉存储单位后的数字<double>
        size_num=`echo ${size} | cut -d "T" -f 1 | cut -d "G" -f 1 | cut -d "M" -f  1`
        # 转化成 GB 之后的存储大小<double>
        size_GB=`echo | awk '{print '${size_num}'}'`

        # 单位转化成 GB
        if test ${size_bit} == "T" ; then
            size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'*1024}'`
        elif test ${size_bit} == "M" ; then
            size_GB=`awk 'BEGIN{printf "%.1f\n",'${size_num}'/1024}'`
        fi
        
        # 内存
        memory=`awk '($1 == "MemTotal:"){print $2/1048576}' /proc/meminfo | cut -d "." -f 1`
        #两种分盘策略
        echo "${name}    ${size}  disk" >> diskmap
        if ((${disk_count} == 1)) ; then
            # 单个磁盘
            if [[ ${name} == "nvme0n1" ]] ; then
                # EFI 分区大小
                efi_size=`echo ${size_GB} | cut -d "." -f 2`
                if ((${efi_size} <= 10)) ; then
                    efi_size=`awk 'BEGIN{printf "%.1f\n",'${efi_size}'/10}'`
                else
                    efi_size=1
                fi
                sed -i "/${name}/a├─${name}p1    ${efi_size}G   EFI System     /boot/EFI" diskmap
                echo "${name}p1 ${efi_size}G" >> partmap
                # swap 分区大小
                if ((${memory} <= 4)); then
                    swap_size=4
                elif (( ${memory} > 4 && ${memory} <= 16)); then
                    swap_size=$((${memory}+2))
                elif ((${memory} > 16 && ${memory} <=64)); then
                    swap_size=16
                else
                    swap_size=32
                fi
                sed -i "/${name}p1/a├─${name}p2    ${swap_size}G   Linux Swap     [SWAP]" diskmap
                echo "${name}p2 ${swap_size}G" >> partmap
                # 其他 / 根分区大小
                outher_size=`awk 'BEGIN{print '${size_GB}'-'${efi_size}'-'${swap_size}'}'`
                # home 分区大小
                home_size=`awk 'BEGIN{printf "%.1f\n",'${outher_size}'/2}'`
                sed -i "/${name}p2/a├─${name}p3    ${home_size}G    Linux Filesystem    /home" diskmap
                echo "${name}p3 ${home_size}G" >> partmap
                sed -i "/${name}p3/a└─${name}p4    ${home_size}G   Linux Filesystem     /" diskmap
                echo "${name}p4 ${home_size}G" >> partmap
                # 跳出循环
                break
            else
                # EFI 分区大小
                efi_size=`echo ${size_GB} | cut -d "." -f 2`
                if ((${efi_size} <= 10)) ; then
                    efi_size=`awk 'BEGIN{printf "%.1f\n",'${efi_size}'/10}'`
                else
                    efi_size=1
                fi
                sed -i "/${name}/a├─${name}1    ${efi_size}G   EFI System     /boot/EFI" diskmap
                echo "${name}1 ${efi_size}G" >> partmap
                # swap 分区大小
                if ((${memory} <= 4)); then
                    swap_size=4
                elif (( ${memory} > 4 && ${memory} <= 16)); then
                    swap_size=$((${memory}+2))
                elif ((${memory} > 16 && ${memory} <=64)); then
                    swap_size=16
                else
                    swap_size=32
                fi
                sed -i "/${name}1/a├─${name}2    ${swap_size}G   Linux Swap     [SWAP]" diskmap
                echo "${name}2 ${swap_size}G" >> partmap
                # 其他 / 根分区大小
                outher_size=`awk 'BEGIN{print '${size_GB}'-'${efi_size}'-'${swap_size}'}'`
                # home 分区大小
                home_size=`awk 'BEGIN{printf "%.1f\n",'${outher_size}'/2}'`
                sed -i "/${name}2/a├─${name}3    ${home_size}G    Linux Filesystem    /home" diskmap
                echo "${name}3 ${home_size}G" >> partmap
                sed -i "/${name}3/a└─${name}4    ${home_size}G   Linux Filesystem     /" diskmap
                echo "${name}4 ${home_size}G" >> partmap
                # 跳出循环
                break
            fi

        elif ((${disk_count} == 2)) ; then
            # 多个磁盘
            if [[ ${name} == "nvme0n1" ]] ; then
                # EFI 分区大小
                efi_size=`echo ${size_GB} | cut -d "." -f 2`
                if ((${efi_size} <= 10)) ; then
                    efi_size=`awk 'BEGIN{printf "%.1f\n",'${efi_size}'/10}'`
                else
                    efi_size=1
                fi
                sed -i "/${name}/a├─${name}p1    ${efi_size}G   EFI System     /boot/EFI" diskmap
                echo "${name}p1 ${efi_size}G" >> partmap
                # swap 分区大小
                if ((${memory} <= 4)); then
                    swap_size=4
                elif (( ${memory} > 4 && ${memory} <= 16)); then
                    swap_size=$((${memory}+2))
                elif ((${memory} > 16 && ${memory} <=64)); then
                    swap_size=16
                else
                    swap_size=32
                fi
                sed -i "/${name}p1/a├─${name}p2    ${swap_size}G   Linux Swap     [SWAP]" diskmap
                echo "${name}p2 ${swap_size}G" >> partmap
                # 其他 / 根分区大小
                outher_size=`awk 'BEGIN{print '${size_GB}'-'${efi_size}'-'${swap_size}'}'`
                sed -i "/${name}p2/a└─${name}p3    ${outher_size}G   Linux Filesystem     /" diskmap
                echo "${name}p3 ${outher_size}G" >> partmap
            else
                sed -i "/${name}/a└─${name}1    ${size}    Linux Filesystem    /home" diskmap
                echo "${name}1 ${size_GB}G" >> partmap
            fi

        else
            echo -e "\033[43;37m There is no suitable partition strategy for you at the moment \033[0m"
        fi
    done
}

# 安装 linux 内核和 base
Install_linux(){
    lsblk -l
    echo -e "\033[45;37m INSTALL LINUX-KERNEL AND BASH \033[0m"
    pacstrap /mnt base
    pacstrap /mnt base-devel
    pacstrap /mnt linux linux-firmware
    echo ""
    echo -e "\033[45;37m The partition mount status is written to fstab \033[0m"
    genfstab -U /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab
    echo ""
}

# 切换到安装的系统
Arch_chroot(){
    echo -e "\033[45;37m SWITCHING SYSTEM ARCH-CHROOT \033[0m"
    read -e -p "The archlinux-install.sh script has been created under /mnt, please run the 'bash archlinux-install.sh'  command after 'arch-chroot' to continue the installation！<<y/n>>" chroot_yn
    [[ -z ${chroot_yn} ]] && chroot_yn="y"
    if [[ ${chroot_yn} == [Nn] ]] ; then
        echo -e "\033[41;30m Exit script \033[0m"
        exit 1
    fi
    # 先把后面需要的命令放在文件中，arch-choot 之后继续运行脚本
    # 复制软件源文件
    cp /etc/pacman.d/mirrorlist* /mnt/etc/pacman.d
    
    echo "#/bin/bash" > /mnt/archlinux-install.sh
    cat >> /mnt/archlinux-install.sh <<EOF
    # 保存变量值
    grub_new=${grub}
    echo -e "\033[45;37m Set time \033[0m"
    ln -sf /usr/share/zoneinfo/\$(tzselect) /etc/localtime
    hwclock --systohc --utc
    echo ""
    echo -e "\033[45;37m Modify the encoding format \033[0m"
    pacman -S vim
    sed -i '/en_US.UTF-8/{s/#//}' /etc/locale.gen
    sed -i '/zh_CN.UTF-8/{s/#//}' /etc/locale.gen
    locale-gen
    echo LANG=en_US.UTF-8 > /etc/locale.conf
    cat /etc/locale.conf
    echo ""
    echo -e "\033[45;37m Create hostname \033[0m"
    read -e -p "Please enter your hostname <<default: Arch>>:" host_name
    [[ -z \${host_name} ]] && host_name="Arch"
    if [[ \${host_name} != "Arch" ]] ; then
        echo \${host_name} > /etc/hostname
    else
        echo Arch > /etc/hostname
    fi
    echo "127.0.0.1   localhost.localdomain   localhost"
    echo "::1         localhost.localdomain   localhost"
    echo "127.0.1.1   \${host_name}.localdomain    \${host_name}"
    echo ""
    echo -e "\033[45;37m Install network connection components <<recommended: WIFI>> \033[0m"
    select net in "WIFI" "DHCP" "ADSL"
    do
        case \${net} in
            "WIFI")
                pacman -S iw wpa_supplicant dialog netctl dhcpcd
                systemctl disable dhcpcd.service
                break
                ;;
            "DHCP")
                pacman -S dhcpcd
                systemctl enable dhcpcd
                systemctl start dhcpcd
                break
                ;;
            "ADSL")
                pacman -S rp-pppoe pppoe-setup
                systemctl start adsl
                break
                ;;
            *)
                pacman -S iw wpa_supplicant dialog netctl dhcpcd
                systemctl disable dhcpcd.service
        esac
    done
    echo -e "\033[45;37m Initramfs \033[0m"
    mkinitcpio -P
    echo -e "\033[45;37m Set ROOT user password \033[0m"
    passwd
    echo ""
    echo -e "\033[45;37m Install Intel-ucode \033[0m"
    cat /proc/cpuinfo | grep "model name" >/dev/null 2>&1
    if ((\$? == 0)) ; then
        pacman -S intel-ucode
    fi
    echo ""
    echo -e "\033[45;37m Install Bootloader \033[0m"
    

    if [[ \${grub_new} == "UEFI" ]] ;then
        echo -e "\033[33m Set up UEFI boot \033[0m"
        pacman -S grub efibootmgr
        # 删除多余引导菜单
        efiboot_menu=`efibootmgr | grep "ArchLinux" | cut -c 5-8`
        if [[ -z \${efiboot_menu} ]] ; then
            echo -e "\033[31m The old boot menu has been deleted \033[0m"
            efibootmgr -b \${efiboot_menu} -B
        fi
        grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=ArchLinux
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        echo -e "\033[33m Set up BIOS boot \033[0m"
        pacman -S grub
        echo -e "\033[43;37m List optional disks \033[0m"
        lsblk -l | grep "disk"
        echo ""
        read -e -p "Please enter the name of your primary disk, note that it is a disk, not a partition, used to install GRUB boot (default: sda):" grub_install_path
        [[ -z \${grub_install_path} ]] && grub_install_path="sda"
        if [[ \${grub_install_path} != "sda" ]]; then
            grub-install --target=i386-pc /dev/\${grub_install_path}
        else
            grub-install --target=i386-pc /dev/sda
        fi
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
    # 检查引导是否正常
    cat /boot/grub/grub.cfg | grep "Arch Linux" >/dev/null 2>&1
    if (( \$? == 0)) ; then
        echo "\${grub_new} The boot setup is successful"
    else
        echo "\${grub_new} Boot setup failed"
    fi
    #多系统自动添加到引导目录
    pacman -S os-prober
    echo -e "Type \033[31m'exit'\033[0m to exit chroot mode."
    # 退出后删除该文件
EOF
    arch-chroot /mnt
    # 退出 /mnt 中的系统
    cp archlinux-install.sh /mnt/archlinux-install.sh
    echo ""
    echo -e "\033[45;37m Reboot the system \033[0m"
    umount -R /mnt
    echo -e "Done! Unmount the CD image from the VM, then type \033[31m'reboot'\033[0m."
    #reboot
}

# 安装系统[start]----------------------------------------------------------------------------------------
Install_system(){
    echo -e "\033[45;37m INSTALL THE SYSTEM \033[0m"
    
    # 确认引导方式
    ls /sys/firmware/efi/efivars >/dev/null 2>&1
    if test $? != 0 ;then
        echo -e "\033[41;37m Does not support UEFI boot, has been switched to BIOS mode \033[0m"
        grub="BIOS"
    fi

    # 更新系统时间
    timedatectl set-ntp true

    # 解开所有中国大陆的源
    sed -i '/China/!{n;/Server/s/^/#/};t;n' /etc/pacman.d/mirrorlist
    cat /etc/pacman.d/mirrorlist | sed -n '1,2'p | grep mirrors.ustc.edu.cn >/dev/null 2>&1
    if (($? != 0)); then
        sed -i '1iServer = http://mirrors.aliyun.com/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
        sed -i '1iServer = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
    fi
    pacman -Syy
    
    # 分区策略
    Disk_map

    # 开始分区
    Cfdisk_ALL
    read -e -p "The system is about to be officially installed. The whole process is connected to the Internet and cannot be suspended. Are you ready？<<y/n>>" iyn
    [[ -z ${iyn} ]] && iyn="y"
    if [[ ${iyn} == [Nn] ]] ; then
        echo -e "\033[41;30m Exit script \033[0m"
        exit 1
    fi
    # 安装 Linux 系统 base | base-devel
    Install_linux
    # 切换到安装的系统
    Arch_chroot
}
# 安装系统[end]-------------------------------------------------------------------------------------------

# 安装桌面[start]***************************************
Install_desktop(){
    # 添加用户
    echo
    echo -e "\033[45;37m ADD USER \033[0m"
    while true
    do
        read -e -p "Create an individual user, please enter the user name:" username
        if [[ ${username} != "" ]] ;then
            useradd -m -g users -s /bin/bash ${username}
            passwd ${username}
            # 配置 /etc/sudoers 文件
            i=`cat /etc/sudoers | awk '/root ALL=\(ALL\) ALL/{print NR}'`
            sed -i ''${i}'a'${username}' ALL=\(ALL\) ALL' /etc/sudoers
            sed -i '5acommon_user='${username}'' /archlinux-install.sh
            break
        else
            read -e -p "Are you sure not to add users?  <<y/n>>" add_user_yn
            [[ -z ${add_user_yn} ]] && add_user_yn="n"
            if [[ ${add_user_yn} == [Yy] ]] ; then
                break
            fi
        fi
    done

    # 开启 bbr 加速
    echo
    echo -e "\033[45;37m OPEN BBR \033[0m"
    bbr_info=`modinfo tcp_bbr | grep "tcp_bbr"`
    if ! [[ -z ${bbr_info} ]] ; then
        control=`sysctl net.ipv4.tcp_congestion_control | cut -d "=" -f 2`
        if [[ ${control} != "bbr" ]] ; then
            echo -e "Currently using \033[31m${control}\033[0m acceleration."
            modprobe tcp_bbr
            control_bbr=`sysctl net.ipv4.tcp_congestion_control | cut -d "=" -f 2`
            echo -e "Change \033[31${control}\033[0m acceleration to \033[36m${control_bbr}\033[0m acceleration"
            sysctl net.ipv4.tcp_congestion_control=bbr
            lsmod | grep tcp_bbr
            echo "tcp_bbr" > /etc/modules-load.d/80-bbr.conf
            echo "net.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.d/80-bbr.conf
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/80-bbr.conf
        else
            echo -e "Currently using \033[31m${control_bbr}\033[0m acceleration."
        fi
    fi
    
    # 安装声卡驱动
    echo
    echo -e "\033[45;37m INSTALL ALSA-UTILS \033[0m"
    Ipp ${os} alsa-utils
    read -e -p "Whether to set the volume immediately？<<y/n>>" alsa_yn
    [[ -z ${alsa_yn} ]] && alsa_yn="n"
    if [[ ${alsa_yn} == [Yy] ]] ; then
        alsamixer
    fi
    
    # 安装显卡驱动
    echo
    echo -e "\033[45;37m INSTALL GRAPHICS DRIVER \033[0m"
    pci_intel=`lspci -k | grep -A 2 -E "(VGA|3D)" | awk '/Intel/{print NR}'`
    pci_amd=`lspci -k | grep -A 2 -E "(VGA|3D)" | awk '/AMD/{print NR}'`
    pci_nvidia=`lspci -k | grep -A 2 -E "(VGA|3D)" | awk '/NVIDIA/{print NR}'`
    if ! [[ -z ${pci_intel} ]] ; then
        Ipp ${os} xf86-video-intel
        echo "Intel graphics driver installed"
    fi
    if ! [[ -z ${pci_amd} ]] ; then
        Ipp ${os} xf86-video-amdgpu
        echo "AMD graphics driver installed"
    fi
    if ! [[ -z ${pci_nvidia} ]] ; then
        Ipp ${os} nvidia
        echo "NVIDIA graphics driver installed"
    fi

    # 安装 x 服务
    Ipp ${os} xorg
    
    # 安装系统字体
    echo -e "\033[45;37m INSTALL FONTS \033[0m"
     Ipp ${os} wqy-zenhei wqy-microhei ttf-dejavu ttf-jetbrains-mono adobe-source-han-sans-cn-fonts

    # 安装桌面
    echo -e "\033[45;37m INSTALL DESKTOP AND DISPLAY MANAGER \033[0m"
    echo -e "Choose your desktop program and display manager. [1~n]"
    select desk in "GNOME+GDM" "KDE+SDDM" "SKIP"
    do
        case ${desk} in
                "GNOME+GDM")
                    echo "\033[45;37mWelcome to GNOME desktop\033"
                    Ipp ${os} gnome gnome-tweak-tool alacarte
                    systemctl enable gdm
                    break
                    ;;
                "KDE+SDDM")
                    echo "\033[45;37mWelcome to KDE desktop\033"
                    Ipp ${os} plasma-meta kde-applications-meta konsole dolphin
                    systemctl enable sddm
                    break
                    ;;
                "SKIP")
                    break
                    ;;
                *)
                    echo -e "\033[43;37m Input error, re-select your desktop manager \033[0m"
        esac
    done
    
    # 启用网络管理
    echo ""
    echo -e "\033[45;37m INSTALL NETWORKMANAGER \033[0m"
    Ipp ${os} networkmanager 
    systemctl enable NetworkManager
    
    # 重启提示
    read -e -p "After the desktop installation is complete, whether to type 'reboot' immediately to restart, you can continue to use 'bash /archlinux-install.sh' to run this script later！<<y/n>>" redesk_yn
    [[ -z ${redesk_yn} ]] && redesk_yn="y"
    if [[ ${redesk_yn} == [Yy] ]] ; then
        echo -e "\033[41;30m REBOOT \033[0m"
        reboot
    fi
}
# 安装桌面[end]********************************************

# 安装其他驱动
Install_drives(){
    echo -e "\033[45;37m 其他驱动 \033[0m"
    while true
    do
        echo -e "请输入编号选择您要安装的驱动[1~n]"
        select num in "触摸板" "蓝牙" "打印机" "EXIT"
        do
            case ${num} in
                "触摸板")
                    # 安装触摸板驱动
                    echo -e "\033[45;37m Install the touchpad driver \033[0m"
                    Ipp ${os} xf86-input-synaptics
                    #TapButton=`synclient -l | grep "TapButton1" | cut -d "=" -f 2`
                    #if [[ ${TapButton} == " 0" ]] ; then
                        sed -i '13aOption "TapButton1" "1"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "TapButton2" "3"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "TapButton3" "2"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "VertEdgeScroll" "on"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "VertTwoFingerScroll" "on"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "HorizEdgeScroll" "on"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "HorizTwoFingerScroll" "on"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "CircularScrolling" "on"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "CircScrollTrigger" "2"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "EmulateTwoFingerMinZ" "40"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "EmulateTwoFingerMinW" "8"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "FingerLow" "30"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "FingerHigh" "50"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        sed -i '13aOption "MaxTapTime" "125"' /usr/share/X11/xorg.conf.d/70-synaptics.conf
                        source /usr/share/X11/xorg.conf.d/70-synaptics.conf >/dev/null 2>&1
                    #fi
                    cat /usr/share/X11/xorg.conf.d/70-synaptics.conf
                    break
                    ;;
                "蓝牙")
                    echo -e "\033[45;37m 安装蓝牙驱动 \033[0m"
                    Ipp %{os} bluez bluez-utils pipewire pipewire-pulse pipewire-jack pipewire-alsa
                    echo "启动蓝牙服务"
                    systemctl --user start pipewire pipewire-pulse pipewire-media-session
                    systemctl --user enable pipewire pipewire-pulse pipewire-media-session
                    systemctl enable bluetooth.service
                    systemctl start bluetooth.service
                    pulseaudio -k
                    pulseaudio --start
                    usermod -a -G lp $USER
                    sed -i 's/AutoEnable.*$/AutoEnable=true/g' /etc/bluetooth/main.conf
                    Ipp %{os} ansible
                    ansible localhost -m lineinfile -a "path=/etc/bluetooth/main.conf line='AutoEnable=true'"
                    break
                    ;;
                "打印机")
                    echo -e "\033[45;37m 安装打印机驱动 \033[0m"
                    Ipp %{os} cups ghostscript gsfonts hplip hpoj
                    systemctl restart avahi-daemon.service
                    systemctl start cups-browsed.service
                    systemctl enable cups-browsed.service
                    echo "配置成功： http://localhost:631"
                    break
                    ;;
                "EXIT")
                    echo -e "\033[41;30m Exit the current script \033[0m"
                    exit 1
                    ;;
                *)
                    echo -e "\033[43;37m 输入错误，请重新输入 \033[0m"
            esac
        done
    done
}

# 添加 CN 源
Archlinuxcn(){
    echo -e "\033[45;37m ADD ARCHLINUXCN MIRRORS \033[0m"
    mirrors_cn=`cat /etc/pacman.conf | grep "archlinuxcn/\$arch" | cut -d "=" -f 2`
    if [[ ${mirrors_cn} == "" ]] ; then
        echo -e "\033[36m Added https://mirrors.ustc.edu.cn/archlinuxcn/\$arch \033[0m"
        echo "[archlinuxcn]" >> /etc/pacman.conf
        echo "Server = https://repo.archlinuxcn.org/\$arch" >> /etc/pacman.conf
        echo "[multilib]" >> /etc/pacman.conf
        echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
        # 生成 GnuPG-2.1 密钥环
        pacman -Syu haveged
        systemctl start haveged
        systemctl enable haveged
        rm -fr /etc/pacman.d/gnupg
        pacman-key --init
        pacman-key --populate archlinux
        # 安装密钥包
        pacman -S archlinuxcn-keyring
        pacman-key --populate archlinuxcn
        pacman -S archlinuxcn-mirrorlist-git
        pacman -Syy
    fi
    Ipp ${os} net-tools dnsutils inetutils iproute2 pacman-contrib yaourt yay
}

# 安装和配置 Git&SSH
Git_SSH(){
    echo -e "\033[45;37m 安装 GIT 及 SSH \033[0m"
    Ipp ${os} git openssh gitflow-avh
    read -e -p "请输入 GIT 用户名: " git_name
    if [[ ${git_name} != "" ]] ; then
        sudo -u $(logname) git config --global user.name "${git_name}"
    fi
    read -e -p "请输入 GIT 邮箱: " git_email
    if [[ ${git_email} != "" ]] ; then
        sudo -u $(logname) git config --global user.email "${git_email}"
    fi
    sudo -u $(logname) git config --global alias.co checkout
    sudo -u $(logname) git config --global alias.ci commit
    sudo -u $(logname) git config --global alias.st status
    sudo -u $(logname) git config --global alias.br branch

    sudo -u $(logname) git config --global alias.psm 'push origin main'
    sudo -u $(logname) git config --global alias.plm 'pull origin main'

    sudo -u $(logname) git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

    sudo -u $(logname) git config --list
    
    echo -e "\033[33m 配置普通用户 $(logname) 的 SSH 公钥，默认一直按 Enter 即可 \033[0m"
    sudo -u $(logname) ssh-keygen -t rsa -C "${git_email}"
    echo -e "\033[31m 将SSH 认证公钥复制到服务器 \033[0m"
    pub_key=`cat /home/$(logname)/.ssh/id_rsa.pub`
    echo ""
    echo -e "echo '\033[33m${pub_key}\033[0m' >> ~/.ssh/authorized_keys"
    echo ""
}

# 安装浏览器
Browsers(){
    echo -e "\033[45;37m 浏览器列表 \033[0m"
    while true
    do
        select browser in "Chrome" "Chromium" "Firefox" "Microsoft-Edge" "Opera" "Tor" "EXIT"
        do
            case ${browser} in
                "Chrome")
                    Ipp ${os} google-chrome
                    break
                    ;;
                "Chromium")
                    Ipp ${os} chromium
                    break
                    ;;
                "Firefox")
                    Ipp ${os} firefox
                    break
                    ;;
                "Microsoft-Edge")
                    Ipp ${os} microsoft-edge-dev-bin
                    break
                    ;;
                "Opera")
                    Ipp ${os} opera
                    break
                    ;;
                "Tor")
                    Ipp ${os} tor-browser
                    break
                    ;;
                "EXIT")
                    exit 1
                    ;;
                *)
                    echo -e "\033[43;37m 输入错误，请重新输入 \033[0m"
            esac
        done
    done
}

# Fcitx 输入法
Fcitx5-Input(){
    echo -e "\033[45;37m Fcitx 安装 Fcitx5 输入法 \033[0m"
    Ipp ${os} fcitx5 fcitx5-chinese-addons fcitx5-chewing
    Ipp ${os} fcitx5-qt fcitx5-gtk fcitx5-qt4-git
    Ipp ${os} fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl
    Ipp ${os} fcitx5-configtool
    Ipp ${os} fcitx5-material-color noto-fonts-emoji noto-fonts-sc
    # 判断桌面（必须使用 sudo -E 参数运行脚本才能识别）
    if [ "$XDG_CURRENT_DESKTOP" = "" ] ; then
        desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
    else
        desktop=$XDG_CURRENT_DESKTOP
    fi
    desktop=${desktop,,}

    case ${desktop} in
        "xfce")
            echo "xfce"
            ;;
        "kde" | "plasma")
            Ipp ${os} kcm-fcitx5
            ;;
        "gnome")
            Ipp ${os} fcitx5-config-qt
            ;;
        *)
            echo ""
    esac

    # 图标存储在去不图床 https://7bu.top/
    curl -o zh.svg https://7.dusays.com/2021/01/24/1f34aac60a1ca.svg
    mv zh.svg /usr/share/icons/hicolor/48x48/apps/fcitx-pinyin.svg
    # 配置输入法环境变量
    echo "INPUT_METHOD  DEFAULT=fcitx5" > /home/$(logname)/.xprofile
    echo "GTK_IM_MODULE DEFAULT=fcitx5" >> /home/$(logname)/.xprofile
    echo "QT_IM_MODULE  DEFAULT=fcitx5" >> /home/$(logname)/.xprofile
    echo "XMODIFIERS    DEFAULT=\@im=fcitx5" >> /home/$(logname)/.xprofile

    echo "INPUT_METHOD  DEFAULT=fcitx5" > /etc/environment
    echo "GTK_IM_MODULE DEFAULT=fcitx5" >> /etc/environment
    echo "QT_IM_MODULE  DEFAULT=fcitx5" >> /etc/environment
    echo "XMODIFIERS    DEFAULT=\@im=fcitx5" >> /etc/environment

    echo "INPUT_METHOD  DEFAULT=fcitx5" > /home/$(logname)/.pam_environment
    echo "GTK_IM_MODULE DEFAULT=fcitx5" >> /home/$(logname)/.pam_environment
    echo "QT_IM_MODULE  DEFAULT=fcitx5" >> /home/$(logname)/.pam_environment
    echo "XMODIFIERS    DEFAULT=\@im=fcitx5" >> /home/$(logname)/.pam_environment

    kill `ps -A | grep fcitx5 | awk '{print $1}'` && fcitx5&
    echo -e "\033[33m 打开 Fcitx 5 Configuration ，Input Method 选项卡中将 pinyin 添加到美式键盘下面；设置激活输入法和切换快捷键 Trigger Input Method 为 Left Shift；Addons 选项卡 Classic User Inteface 选择主题，重启系统后生效\033[0m"
}

# 安装软件菜单
Install_packages(){
    echo -e "\033[45;37m 软件列表 \033[0m"
    echo -e "\033[33m 建议：在安装软件之前先配置 ArchLinuxCN 源\033[0m"
    echo -e "\033[33m 如果是安装 Fcitx5 输入法，请使用 sudo -E 参数运行当前脚本\033[0m"
    while true
    do
        echo -e "请输入编号选择您要安装的应用程序[1~n]"
        select package in "配置CN源" "GIT&&SSH" "Gitkraken" "SVN" "on-my-zsh" "浏览器" "Fcitx5输入法" "科学上网" "网易云音乐" "QQ音乐" "Spotify音乐" "TIM&&QQ" "微信" "微信小程序开发工具" "钉钉" "Telegram" "多线程下载工具" "BaiduPCS" "百度网盘" "eDEX-UI" "MEGAsync网盘" "OBS-STUDIO" "哔哩哔哩弹幕库" "Teamviewer" "WPS" "JDK" "XMind" "Drawio" "Eclipse" "MyEclipse" "Maven" "Tomcat" "Redis" "Docker" "MySQL&&MariaDB" "DataGrip" "DBeaver" "IntelliJIDEA" "Pycharm" "AndroidStudio" "VMware" "Virtualbok" "Visual Studio Code" "GitBook" "tldr" "xchm" "Krita" "GIMP" "Slack" "Goldendict" "有到云笔记" "Notion" "Jstock" "EXIT"
        do
            case ${package} in
                "配置CN源")
                    Archlinuxcn
                    break
                    ;;
                "GIT&&SSH")
                    Git_SSH
                    break
                    ;;
                "Gitkraken")
                    Ipp ${os} gitkraken
                    break
                    ;;
                "SVN")
                    Ipp ${os} svn
                    break
                    ;;
                "on-my-zsh")
                    break
                    ;;
                "浏览器")
                    Browsers
                    break
                    ;;
                "Fcitx5输入法")
                    Fcitx5-Input
                    break
                    ;;
                "科学上网")
                    Ipp ${os} qv2ray qv2ray-plugin-trojan qv2ray-plugin-ssr-dev-git
                    #下载 v2ray-core
                    v2raycore_latest=$(curl -L "https://api.github.com/repos/v2fly/v2ray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
                    curl -LO https://github.com/v2fly/v2ray-core/releases/download/${v2raycore_latest}/v2ray-linux-64.zip
                    Ipp ${os} unzip
                    unzip v2ray-linux-64.zip -d /usr/share/qv2ray/v2ray-core/
                    rm -rf v2ray-linux-64.zip
                    echo -e "\033[33m启动 Qv2ray → 首选项 → 内核设置，修改核心可执行文件路径为 /usr/share/qv2ray/v2ray-core/v2ray ，资源目录为 /usr/share/qv2ray/v2ray-core  ，设置完成测试没问题点击 OK 即可\033[0m"
                    break
                    ;;
                "网易云音乐")
                    Ipp ${os} etease-cloud-music
                    git clone https://github.com/HexChristmas/archlinux && cd archlinux/qcef
                    sudo -u $(logname) makepkg -si
                    sed -i "3,5s/^/#/" /opt/netease/netease-cloud-music/netease-cloud-music.bash
                    echo "export XDG_CURRENT_DESKTOP=DDE" >> /opt/netease/netease-cloud-music/netease-cloud-music.bash
                    cd ../../
                    rm -rf archlinux
                    break
                    ;;
                "QQ音乐")
                    Ipp ${os} qqmusic-bin
                    break
                    ;;
                "Spotify音乐")
                    Ipp ${os} spotify spicetify-cli spicetify-themes-git
                    chmod a+wr /opt/spotify
                    chmod a+wr /opt/spotify/Apps -R
                    sudo -u $(logname) spicetify backup apply enable-devtool
                    sudo -u $(logname) spicetify update
                    # 配置主题
                    cd /usr/share/spicetify-cli/Themes/Dribbblish
                    cp dribbblish.js ../../Extensions
                    sudo -u $(logname) spicetify config extensions dribbblish.js
                    sudo -u $(logname) spicetify config current_theme Dribbblish color_scheme base
                    sudo -u $(logname) spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
                    sudo -u $(logname) spicetify apply
                    echo "选择想要使用的主题，样式来源https://github.com/morpheusthewhite/spicetify-themes/blob/master/Dribbblish/README.md"
                    select spotify_theme in "Dracula" "White"
                    do
                        case ${spotify_theme} in
                            "Dracula")
                                sudo -u $(logname) spicetify config color_scheme dracula
                                sudo -u $(logname) spicetify apply
                                break
                                ;;
                            "White")
                                sudo -u $(logname) spicetify config color_scheme white
                                sudo -u $(logname) spicetify apply
                                break
                                ;;
                            *)
                                echo ""
                        esac
                    done

                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "")
                    break
                    ;;
                "EXIT")
                    echo -e "\033[41;30m Exit the current script \033[0m"
                    exit 1
                    ;;
                *)
                    echo -e "\033[43;37m 输入错误，请重新输入 \033[0m"
            esac
        done
    done
}


# 操作菜单
echo -e "Please enter the menu number. [1~n]"
select num in "制作启动盘" "INSTALL-SYSTEM" "INSTALL-DESKTOP" "其他驱动" "安装软件" "游戏" "更新脚本" "EXIT"
do
        case ${num} in
                "制作启动盘")
                    Download_iso
                    break
                    ;;
                "INSTALL-SYSTEM")
                    Install_system
                    break
                    ;;
                "INSTALL-DESKTOP")
                    Install_desktop
                    break
                    ;;
                "其他驱动")
                    Install_drives
                    break
                    ;;
                "安装软件")
                    Install_packages
                    break
                    ;;
                "游戏")
                    break
                    ;;
                "更新脚本")
                    echo -e "\033[45;37m 更新脚本 \033[0m"
                    Update_shell
                    break
                    ;;
                "EXIT")
                    echo -e "\033[41;30m Exit the current script \033[0m"
                    exit 1
                    ;;
                *)
                    echo -e "\033[43;37m 输入错误，请重新输入 \033[0m"
        esac
done

