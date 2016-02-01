How to install on a new computer
================================

1. Fork this project into your own Github account
2. Clone on your machine:

        git clone https://github.com/<YOUR_GITHUB_USERNAME>/dotfiles.git ~/bin

3. Make sure the `.bashrc` file is loaded every time you open the Terminal:

        echo "if [ -f ~/.bashrc ]; then
          source ~/.bashrc
        fi" > ~/.bash_profile

4. Load **environment variables**, **aliases** and shell **settings**:

        ln -sf ~/bin/dotfiles/bashrc     ~/.bashrc

5. Enter your Github credentials in [gitconfig](http://git.io/-MEnNw), then load the **git settings**:

        ln -sf ~/bin/dotfiles/git/config  ~/.gitconfig

6. Load **git ignore settings**:

        ln -sf ~/bin/dotfiles/git/ignore  ~/.gitignore

6. Load **git global hooks**:

		mkdir -p ~/.git_template/hooks/
        ln -sf ~/bin/dotfiles/git/pre-commit  ~/.git_template/hooks/

7. Load **rubygems settings**:

        ln -sf ~/bin/dotfiles/gemrc      ~/.gemrc

8. Load **pry settings** for Rails:

        ln -sf ~/bin/dotfiles/pryrc      ~/.pryrc

9. Load **SSH settings**:

        mkdir -p ~/.ssh
        ln -sf ~/bin/dotfiles/ssh/config ~/.ssh/config

10. Load **git prompt** support:

        source ~/.bashrc
        vcprompt-install

11. Load **hub** support (optional):

        hub-install

12. Add custom bundles to Textmate 1 (optional):

        ln -sf ~/bin/dotfiles/textmate ~/Library/Application\ Support/TextMate/Bundles/claudiob.tmbundle


13. Don't track further changes to your private settings:

        cd ~/bin
        git update-index --assume-unchanged ~/bin/dotfiles/bash/env.secret
        git update-index --assume-unchanged ~/bin/dotfiles/ssh/config

14. Go and edit your aliases, configuration, settings, then push to your Github account!

Other tips
----------

* Install [OSX gcc installer](https://github.com/kennethreitz/osx-gcc-installer)
* Install [homebrew](http://mxcl.github.com/homebrew)
* Install [rbenv](https://github.com/sstephenson/rbenv)
* Learn how to [navigate with keyboard between OSX Terminal tabs](http://superuser.com/questions/26100/u/54004)
