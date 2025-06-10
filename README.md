# rfb
1.组合rg fzf bat三种工具制作的linux系统搜索文件脚本

2.提前安装好rg fzf bat三种工具

3.ubuntu下三种工具安装:sudo apt install ripgrep fzf bat

4.bat安装好后可能无法使用bat指令,需要做一个软链接:sudo ln -s /usr/bin/batcat /usr/local/bin/bat,这样就可以直接使用了

5.获取脚本文件后,赋予执行权限:chmod +x ./rfb.sh,即可使用:./rfb.sh,或者可以在~/.zshrc或~/.bashrc文件中添加别名则会更加方便快捷
