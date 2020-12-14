#!/bin/bash
# 引入 PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 安装 lolcat
Install_lolcat(){
    wget https://github.com/busyloop/lolcat/archive/master.zip
    unzip master.zip
    cd locat-master/bin
    gem install lolcat
    cd ../../
    rm -rf lolcat-master/ master.zip
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
                            yay_var=${f}
                            Ipp $1 yay
                            yay -S ${yay_var}
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
                wifi-menu
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
sh_ver=`date -d "$(date +%y%m)01 last month" +%Y.%m.01`
source /etc/os-release
os="$ID"
# 镜像大小（MB）
iso_size=682
# 引导方式
grub=UEFI

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
||     Version:${sh_ver}                                                         ||
||     Author: teaper                                                             ||
||     Home：https://github.com/teaper/archlinux-install-script                   ||
====================================================================================
\033[0m" | lolcat
# TITLE 生成: http://patorjk.com/software/taag/#p=display&f=Slant&t=teaper

# 函数
Test_function(){
    echo -e "Hello ${USER}"
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
            dd if=archlinux-${sh_ver}-${bit}.iso of=/dev/${dd_disk} bs=1440k oflag=sync
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
    if [[ -e ./archlinux-${sh_ver}-${bit}.iso ]] ;then 
        iso_d_size=`ls -l archlinux-${sh_ver}-${bit}.iso | awk '{print $5}'`
        echo "archlinux-${sh_ver}-${bit}.iso 镜像文件已存在（size: $(( ${iso_d_size}/1024/1024 )) MiB）" && echo
        
        #判断文件大小是否正确
        iso_f_size=$(( ${iso_size}*1024*1024 ))
        if test $[iso_d_size] -le $[iso_f_size]; then
            echo -e "\033[41;30m iso 文件已损坏，正在重新下载 \033[0m"
            wget -N "http://mirrors.163.com/archlinux/iso/${sh_ver}/archlinux-${sh_ver}-${bit}.iso" archlinux-${sh_ver}-${bit}.iso
            Dd_iso
        else
            Dd_iso
        fi
    else 
        read -e -p "当前文件夹下没有 archlinux-${sh_ver}-${bit}.iso 镜像，是否立即下载[y/n]:" iso_yn
        [[ -z ${iso_yn} ]] && iso_yn="y"
        if [[ ${iso_yn} == [Yy] ]]; then
            echo "\n正在下载 iso 镜像文件"
            wget -N "http://mirrors.163.com/archlinux/iso/${sh_ver}/archlinux-${sh_ver}-${bit}.iso" archlinux-${sh_ver}-${bit}.iso
            Dd_iso
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

    # 判断分区个数
    if ((${part_count} != 4)) ; then
        echo -e "\033[31m Unreasonable number of partitions, go back and repartition \033[0m" 
        Cfdisk_ALL
        # 不进行自动挂载
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
                echo -e "${name} \033[35m[OK]\033[0m SIZE: ${size_GB}G \033[31mMATCH\033[0m ${partmap_size}G"
            else
                echo -e "${name} \033[31m[NO]\033[0m SIZE: ${size_GB}G \033[31mMISMATCH\033[0m ${partmap_size}G"
                NO=`awk 'BEGIN{print '${NO}'+1}'`
            fi
        done
         #格式化分区
         Mkfs_disks
        echo ""
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
                        # 格式化分区
                        Mkfs_disks
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
}

# 开始分区
Cfdisk_ALL(){
    echo -e "\033[45;37m READING PARTITION STRATEGY \033[0m"
    cat diskmap && echo
    echo -e "\033[43;37m Partition order \033[0m"
    echo "Single disk:   EFI > SWAP > HOME > /"
    echo "Dual disk:   EFI > SWAP > / > HOME"
    read -e -p "During the partitioning process, the partitioning strategy cannot be viewed. It is recommended to take a picture and record before continuing [y/n]:" cfdisk_yn
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
    cat cmd.log >/dev/null 2>&1 
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
    cat cmd.log >/dev/null 2>&1 
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
                    # 先格式化
                    Cm_disks
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
                        mkdir /mnt/boot
                        mkdir /mnt/boot/EFI
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
                            mkdir /mnt/boot
                            mkdir /mnt/boot/EFI
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
                    # 挂载分区
                    Mount_parts
                    break
                    ;;
                "SKIP")
                    rm diskmap >/dev/null 2>&1
                    # 挂载分区
                    Mount_parts
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
        #挂载分区
        Mount_parts
    fi
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
    read -e -p "The archlinux-install.sh script has been created under /mnt, please run the 'bash archlinux-install.sh'  command after 'arch-chroot' to continue the installation！[yn]:" chroot_yn
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
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc --utc
    echo ""
    echo -e "\033[45;37m Modify the encoding format \033[0m"
    pacman -S vim
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo LANG=en_US.UTF-8 > /etc/locale.conf
    cat /etc/locale.conf
    echo ""
    echo -e "\033[45;37m Create hostname \033[0m"
    read -e -p "Please enter your hostname（default: Arch）:" host_name
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
    echo -e "\033[45;37m Install network connection components（recommended: WIFI） \033[0m"
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
    echo ""
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

    # 修改源文件
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
    read -e -p "The system is about to be officially installed. The whole process is connected to the Internet and cannot be suspended. Are you ready?[yn]:" iyn
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

# 安装驱动
Install_drives(){
    # 安装声卡驱动
    echo
    echo -e "\033[45;37m INSTALL ALSA-UTILS \033[0m"
    Ipp ${os} alsa-utils
    read -e -p "Whether to set the volume immediately" alsa_yn
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

    # 安装触摸板驱动
    Ipp ${os} xf86-input-synaptics

}

# 安装字体
Install_ttf(){
    echo
    echo -e "\033[45;37m INSTALL FONTS \033[0m"
    echo -e "The operating system recommends using \033[36mWQY\033[0m fonts[1,n-1]"
    select ttf_num in "WQY" "DEJAVU" "JETBRAINS" "SKIP"
    do
        case ${ttf_num} in
                "WQY")
                    Ipp ${os} wqy-zenhei wqy-microhei
                    continue
                    ;;
                "DEJAVU")
                    Ipp ${os} ttf-dejavu
                    #Install_system
                    continue
                    ;;
                "JETBRAINS")
                    Ipp ${os} ttf-jetbrains-mono
                    continue
                    ;;
                "SKIP")
                    break
                    ;;
                *)
                    echo -e "\033[43;37m Input error, unknown option \033[0m"
        esac
    done
}

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
            i=cat /etc/sudoers | awk '/root ALL=\(ALL\) ALL/{print NR}'
            sed -i ''${i}'a'${username}' ALL=(ALL) ALL' /etc/sudoers
            break
        else
            read -e -p "Are you sure not to add users? [y/n]" add_user_yn
            [[ -z ${add_user_yn} ]] && add_user_yn="n"
            if [[ ${add_user_yn} == [Yy] ]] ; then
                break
            fi
        fi
    done
    
    # 安装驱动
    Install_drives

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
            sudo sysctl net.ipv4.tcp_congestion_control=bbr
            echo "tcp_bbr" > /etc/modules-load.d/80-bbr.conf
            echo "net.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.d/80-bbr.conf
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/80-bbr.conf
        else
            echo -e "Currently using \033[31m${control_bbr}\033[0m acceleration."
        fi
    fi

    # 安装 x 服务
    Ipp ${os} xorg
    
    # 安装字体
    Install_ttf

    # 安装桌面
    echo -e "\033[45;37m INSTALL DESKTOP AND DISPLAY MANAGER \033[0m"
    echo -e "Choose your desktop program and display manager. [1~n]"
    select desk in "GNOME+GDM" "KDE+SDDM" "DDE" "DWM-SDDM" "SKIP"
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
                    Ipp ${os} plasma-meta konsole dolphin
                    systemctl enable sddm
                    break
                    ;;
                "DDE")
                    echo "\033[45;37mWelcome to DDE desktop\033"
                    Ipp ${os} deepin deepin-extra
                    
                    #先修改lightdm配置文件
                    nmb=`cat < /etc/lightdm/lightdm.conf | sed -n '/greeter-session/='`
                    sed -i ''${nmb}'agreeter-session=lightdm-deepin-greeter' /etc/lightdm/lightdm.conf
                    sed -i '${nmb}d' /etc/lightdm/lightdm.conf

                    systemctl enable lightdm
                    break
                    ;;
                "DWM-SDDM")
                    echo "\033[45;37mWelcome to DWM desktop\033"
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
    Ipp ${os} networkmanager 
    systemctl enable NetworkManager
    
    read -e -p "After the desktop installation is complete, whether to type 'reboot' immediately to restart, you can continue to use 'bash /archlinux-install.sh' to run this script later！[yn]:" redesk_yn
    [[ -z ${redesk_yn} ]] && redesk_yn="y"
    if [[ ${redesk_yn} == [Yy] ]] ; then
        echo -e "\033[41;30m REBOOT \033[0m"
        reboot
    fi


}

# 安装桌面[end]********************************************

# 操作菜单
echo -e "Please enter the menu number. [1~n]"
select num in "制作启动盘" "INSTALL-SYSTEM" "INSTALL-DESKTOP" "安装软件" "功能三" "更新脚本" "退出"
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
                "安装软件")
                    echo -e "\033[45;37m 功能二 \033[0m"
                    echo "安装 QQ 音乐"
                    Ipp ${os} qqmusic-bin jstock
                    break
                    ;;
                "功能三")
                    echo -e "\033[45;37m 功能三 \033[0m"
                    Test_function
                    break
                    ;;
                "退出")
                    echo -e "\033[41;30m 退出脚本 \033[0m"
                    break
                    ;;
                *)
                    echo -e "\033[43;37m 输入错误，请重新输入 \033[0m"
        esac
done

