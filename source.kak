define-command -params 1..2 -file-completion rfind -docstring %{
rfind <file> [reg=a]
    searches for first occurance of <file> in current directory and above.
    returns result in <reg>, which defaults to register <a>.
} %{
    evaluate-commands %sh{
        rfind() {
            if [ -f "$1" ]; then
                echo "${PWD}/$1"
            elif [ "$PWD" = / ]; then
                false
            else
                (cd .. && rfind "$1")
            fi
        }

        PATH=$(rfind $1)
        if [ -z ${PATH} ]; then
            echo "fail file $1 not found"
        else
            echo "set-register ${2:-a} $PATH"
        fi
    }
}

define-command -params 1..2 -file-completion rfind-all -docstring %{
rfind-all <file> [reg=a]
    searches for all occurances of <file> in current directory and above.
    returns result in <reg>, which defaults to register <a>.
    the results are a comma delimited list, with the closest file last
} %{
    evaluate-commands %sh{
        rfind() {
            if [ -f "$1" ]; then
                printf "${PWD}/$1\n"
                (cd .. && rfind "$1")
            elif [ "$PWD" = / ]; then
                true
            else
                (cd .. && rfind "$1")
            fi
        }

        reverse() {
            if [ -z $(command -v tac) ]; then
                tail -r
            else
                tac
            fi
        }

        PATH=$(rfind $1 | reverse | tr '\n' ',')
        echo "echo -debug $PATH"
        if [ -z ${PATH} ]; then
            echo "fail file $1 not found"
        else
            echo "set-register ${2:-a} $PATH"
        fi
    }
}

define-command -params 1 -file-completion source-all -docstring %{
source-all <file>
    sources all occurances of <file> in current directory and above.
} %{ evaluate-commands -save-regs a %{
    try %{
        rfind-all %arg{1}
        evaluate-commands %sh{
            IFS=','
            for path in ${kak_reg_a}; do
                echo "echo -debug sourcing: ${path}"
                echo "try %{ source ${path} } catch %{ echo -debug sourcing ${path} failed }"
            done
            IFS='\n'
        }
    } catch %{
        echo -debug "file(s) %arg{1} not found, skipping"
    }
}}

define-command -params 1 -file-completion source-first -docstring %{
source-first <file>
    sources the first occurance of <file> in current directory and above.
} %{ try %{ evaluate-commands -save-regs a %{
        rfind %arg{1}
        echo -debug "sourcing %reg{a}"
        source %reg{a}
    } catch %{
        echo -debug "file %arg{1} not found, skipping"
    }
}}
