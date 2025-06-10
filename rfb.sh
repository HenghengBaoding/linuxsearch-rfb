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
    echo -e "\033[1;32m n. 文件名 \033[0m"
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
      echo -e "\033[2m (可输入多个目录，用空格隔开，留空默认$HOME，[ESC]返回上一级)\033[0m"
      read_input " >>> "
      # 1. 按ESC返回搜索类型输入页面
      if [[ $? -eq 130 ]]; then
          break  # 跳出内容输入循环，回到搜索类型输入
      fi
      dirs="$REPLY"
      [[ -z $dirs ]] && dirs="$HOME"

      # 搜索内容输入循环
      while true; do
          if [[ $search_type == "n" ]]; then
              type_str="文件名"
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
              # 文件名模糊匹配（basename包含关系，不再完全等于）
              result=$(rg --files $dirs 2>/dev/null | awk -F/ '{print $0"\t"$(NF)}' | awk -v pat="$pattern" 'index($2, pat)>0{print $1}')
              if [[ -z $result ]]; then
                  echo -e "\033[1;31m 未找到匹配的文件名。\033[0m"
                  continue
              fi
              # fzf绑定回车退出
              echo "$result" | fzf --prompt="[↑][↓]可以选择文件并查看具体内容: " --header="[ESC]返回上一级 | [enter]退出并输出文件内容" --preview="bat --style=numbers --color=always --line-range :100 {}" --bind "esc:abort,enter:accept+abort"
              fzf_status=$?
              if [[ $fzf_status -eq 130 ]]; then
                  continue  # 返回内容输入页面
              elif [[ $fzf_status -eq 0 ]]; then
                  exit 0    # 回车退出脚本
              fi
              break
          else
              # 文件内容搜索
              rg --color=always --line-number --no-heading "$pattern" $dirs 2>/dev/null | \
              fzf --ansi --prompt="[↑][↓]可以选择文件并查看具体内容: " --header="[ESC]返回上一级 | [enter]退出并输出文件内容" --preview="bat --style=numbers --color=always --highlight-line {2} {1}" \
                    --delimiter : --preview-window=up:60%:wrap --bind "esc:abort,enter:accept+abort"
              fzf_status=${PIPESTATUS[1]}
              if [[ $fzf_status -eq 130 ]]; then
                  continue  # 返回内容输入页面
              elif [[ $fzf_status -eq 0 ]]; then
                  exit 0    # 回车退出脚本
              fi
              break
          fi
      done
    done
done