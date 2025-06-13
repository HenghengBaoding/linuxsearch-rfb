#!/bin/bash

# 依赖检查
for cmd in rg fzf bat; do
    if ! command -v $cmd &>/dev/null; then
        echo "缺少依赖: $cmd，请先安装。"
        exit 1
    fi
done

# 支持ESC直接返回上一层的输入函数，支持退格删除
read_input() {
    local prompt="$1"
    local input=""
    local char
    printf "%s" "$prompt"
    while IFS= read -rsn1 char; do
        # ESC直接返回上一层
        if [[ $char == $'\e' ]]; then
            echo
            return 130
        fi
        # Tab键，直接忽略
        if [[ $char == $'\t' ]]; then
            continue
        fi
        # 回车结束输入
        if [[ $char == "" ]]; then
            echo
            break
        fi
        # 退格键
        if [[ $char == $'\x7f' ]]; then
            if [[ -n $input ]]; then
                input="${input%?}"
                # 光标左移并清除字符
                printf "\b \b"
            fi
            continue
        fi
        input+="$char"
        printf "%s" "$char"
    done
    REPLY="$input"
    return 0
}

while true; do
    echo -e "\n\033[1;36m *********************\033[0m"
    echo -e "\033[1;33m 1.请选择搜索类型：\033[0m"
    echo -e "\033[1;32m n. 文件名/目录名 \033[0m"
    echo -e "\033[1;34m c. 文件内容 \033[0m"
    echo -e "\033[2m (输入n或c，[ESC]退出)\033[0m"
    read_input " >>> "
    [[ $? -eq 130 ]] && echo "已退出。" && exit 0
    search_type="$REPLY"

    if [[ $search_type != "n" && $search_type != "c" ]]; then
        echo -e "\033[1;31m 请输入正确的字符（n或c）\033[0m"
        continue
    fi

    # 目录输入循环
    while true; do
      echo -e "\n\033[1;36m *********************\033[0m"
      echo -e "\n\033[1;33m 2.请输入要搜索的目录：\033[0m"
      echo -e "\033[2m (可输入多个目录，用空格隔开，留空默认当前路径，[ESC]返回上一级)\033[0m"
      read_input " >>> "
      # 1. 按ESC返回搜索类型输入页面
      if [[ $? -eq 130 ]]; then
          break  # 跳出内容输入循环，回到搜索类型输入
      fi
      dirs="$REPLY"
      [[ -z $dirs ]] && dirs="$(pwd)"

      # 搜索内容输入循环
      while true; do
          if [[ $search_type == "n" ]]; then
              type_str="文件名/目录名"
          else
              type_str="文件内容"
          fi
          echo -e "\n\033[1;36m *********************\033[0m"
          echo -e "\n\033[1;33m 3.请输入要搜索的内容：\033[0m"
          echo -e "\033[2m (类型: $type_str | 目录: $dirs | [ESC]返回上一级)\033[0m"
          read_input " >>> "
          # 1. 按ESC返回目录输入页面
          if [[ $? -eq 130 ]]; then
              break  # 跳出内容输入循环，回到目录输入
          fi
          pattern="$REPLY"
          # 2. 直接回车未输入内容，提示并重新输入
          if [[ -z $pattern ]]; then
              echo -e "\033[1;31m 请输入搜索内容。\033[0m"
              continue
          fi

        if [[ $search_type == "n" ]]; then
            # 文件名/目录名模糊匹配（不区分大小写，包含关系）
            # 支持特殊字符的文件/目录名模糊匹配
            result=$(find $dirs -type f -o -type d 2>/dev/null | awk -F/ -v pat="$pattern" 'BEGIN{IGNORECASE=1} index(tolower($NF), tolower(pat)) > 0 {print $0}')
            if [[ -z $result ]]; then
                echo -e "\033[1;31m 未找到匹配的文件名或目录名。\033[0m"
                continue
            fi
            # 生成带类型标签的列表
            result_with_type=$(echo "$result" | while read -r path; do
                if [[ -d "$path" ]]; then
                    echo -e "[\033[1;34m目录\033[0m] $path"
                else
                    echo -e "[\033[1;32m文件\033[0m] $path"
                fi
            done)
            # fzf绑定回车退出，预览时去掉类型标签
            selected=$(echo -e "$result_with_type" | \
                fzf --ansi --prompt="[↑][↓]选择文件/目录: " \
                    --header="[ESC]返回上一级 | [enter]退出并输出内容" \
                    --preview="p={}; p=\${p#*\] }; if [[ -d \"\$p\" ]]; then ls -l --color=always \"\$p\"; else bat --style=numbers --color=always --line-range :100 \"\$p\" 2>/dev/null || cat \"\$p\"; fi" \
                    --bind "esc:abort,enter:accept+abort")
            fzf_status=$?
            # 还原真实路径
            selected_path=$(echo "$selected" | sed 's/^\[[^]]*\] //')
            if [[ $fzf_status -eq 130 ]]; then
                continue  # 返回内容输入页面
            elif [[ $fzf_status -eq 0 ]]; then
                echo "$selected_path"
                exit 0    # 回车退出脚本
            fi
            break
          else
              # 文件内容搜索（不区分大小写，支持特殊字符）
              result=$(rg -i -F --color=always --line-number --no-heading -- "$pattern" $dirs 2>/dev/null)
              if [[ -z $result ]]; then
                  echo -e "\033[1;31m 未找到匹配的内容。\033[0m"
                  continue
              fi
              
              selected=$(echo "$result" | \
                  fzf --ansi --prompt="[↑][↓]可以选择文件并查看具体内容: " \
                      --header="[ESC]返回上一级 | [enter]退出并输出文件内容" \
                      --delimiter : \
                      --preview="bat --style=numbers --color=always --highlight-line {2} {1}" \
                      --preview-window=up:60%:wrap \
                      --bind "esc:abort,enter:accept+abort")
              fzf_status=$?
              if [[ $fzf_status -eq 130 ]]; then
                  continue  # 返回内容输入页面
              elif [[ $fzf_status -eq 0 && -n $selected ]]; then
                  echo "$selected"
                  exit 0    # 回车退出脚本
              fi
              # 若fzf无选择直接回车，重新输入搜索内容
              echo -e "\033[1;31m 未选择任何内容。\033[0m"
              continue
          fi
      done
    done
done