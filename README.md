# rfb

1.组合rg fzf bat三种工具制作的linux系统搜索脚本，支持目录名、文件名、文件内容搜索

2.提前安装好rg fzf bat三种工具

3.ubuntu下三种工具安装:

```shell
sudo apt install ripgrep fzf bat
```

4.bat安装好后可能无法使用bat指令,需要做一个软链接:

```shell
sudo ln -s /usr/bin/batcat /usr/local/bin/bat
```

这样就可以直接使用了

5.获取脚本文件后,赋予执行权限:

```shell
chmod +x 脚本目录/rfb.sh
```

即可使用（脚本目录最好放在自己家目录或者家目录的子目录）:

```shell
脚本目录/rfb.sh
```

或者可以在~/.zshrc或~/.bashrc文件中添加别名则会更加方便快捷：

```shell
# 打开~/.zshrc或~/.bashrc，根据自己shell选择
vim ~/.zshrc或vim ~/.bashrc

# 在文件中添加别名
alias rfb='脚本目录/rfb.sh'

# 重新加载环境变量
source ~/.zshrc或source ~/.bashrc
```

现在就可以在终端中执行rfb指令使用搜索功能了

```
rfb
```
