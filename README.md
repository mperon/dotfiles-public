# Peron Public Dotfiles
 
These are config files to set up a system the way I like it. 

They support `MacOS`, `Linux`, `WSL` and `Cygwin`. 

All the commands and personalization is for my taste, so be free to clone and customize. If you have any suggestion, send me a _PR_.

My main operation system for personal projects is `MacOS`, but, for now, professinal work is done using `WSL`.

## Installation

Run the following commands in your terminal. It will prompt you before it does anything destructive. Check out the [Source Code](https://mperon.org/dotfiles/public.sh) to see exactly what it does.

You have to has installed `curl` or `wget` on your target system. We need `ssh` and `git` as well.


### Installing using `curl`:

Execute the following command in your Terminal:

```terminal
curl -fsSL https://mperon.org/dotfiles/public.sh | bash
```

When you execute the installation on an user that already have any file that will be installed, an warning will be shown:

> You have files that will be overritten from this script.  
> If you are sure that you will want to continue, please:  
>   1) Backup and move files that will be overritten  
>   2) Run this script with T_FORCE=y (curl ... | T_FORCE=y bash)  

So, to fix that, you can use the variable `T_FORCE=y`:

```terminal
T_FORCE=y curl -fsSL https://mperon.org/dotfiles/public.sh | bash
```

After installing, open a new terminal window to see the effects.

Feel free to customize the `.zshrc` file to match your preference.


### Installing using `wget`:

Execute the following command in your Terminal:

```terminal
wget -qO- https://mperon.org/dotfiles/public.sh | bash
```

When you execute the installation on an user that already have any file that will be installed, an warning will be shown:

> You have files that will be overritten from this script.  
> If you are sure that you will want to continue, please:  
>   1) Backup and move files that will be overritten  
>   2) Run this script with T_FORCE=y (wget ... | T_FORCE=y bash)  

So, to fix that, you can use the variable `T_FORCE=y`:

```terminal
T_FORCE=y wget -qO- https://mperon.org/dotfiles/public.sh | bash
```

After installing, open a new terminal window to see the effects.

Feel free to customize the `.zshrc` file to match your preference.


## Features

A lot! Will put here when i have the time to do-it!

## Uninstall

These *public-dotfiles* installs lots of stuff on your home directory so there is no safe way of deleting without checking file by file. You can easily disable-it by commenting the references from `.zshrc` and `.bashrc`. Comment this lines on `Bash`:

```bash
# -* Peron DotFiles -*
# Avaliable at: https://github.com/mperon/dotfiles-public.git

if [[ -f "$HOME/.shell/bashrc" ]]; then
    source "$HOME/.shell/bashrc"
fi
```

Comment this lines on `ZSH`:

```zsh
# -* Peron DotFiles -*
# Avaliable at: https://github.com/mperon/dotfiles-public.git

if [[ -f "$HOME/.shell/zshrc" ]]; then
    source "$HOME/.shell/zshrc"
fi
```

Then open a new terminal window to see the effects.

Now, if you want to delete all files, you have to use `git`. Be carefull when you do that!

```terminal
rm -rf $HOME/.config/dotfiles
git ls-files -z | xargs -0 git rm
```

And then, all files have been deleted. Open a new terminal window to see the effects.

## Author

| [![@mperon](https://s.gravatar.com/avatar/a97056b5eddd67dd9996717a0bc5242b?s=80)](https://instagram.com/peron_sc "Follow @peron_sc on Instagram") |
|---|
| [Marcos Peron](https://mperon.org/) |

## Thanks to…

* [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
* [Mathias Bynens] and his [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
