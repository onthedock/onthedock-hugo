#!/bin/bash
usage="Usa \"-o [rpi|onthedock]\" o \"--output [rpi|onthedock]\" para construir OnTheDock"
sitepath="/Users/xavi/Dropbox/dev/hugo/onthedock-githubpages/"
hugopath="/Users/xavi/Applications/hugo"

if [ "$1" != "" ]; then
   case $1 in
      -o | --output )
         shift
         output=$1 ;;
       * )
         echo $usage
         exit 1 ;;
   esac
fi

if [ $output == "rpi" -o $output == "onthedock" ]; then
   cd $sitepath
   $hugopath --config $output-config.toml
   cd $sitepath/public
   if [ $output == "rpi" ]; then
      scp -r . pirate@rpi.local:/home/pirate/web
   fi
   if [ $output == "onthedock" ]; then
      echo ""
      echo "Remember to git add and then git push"
   fi
else
   echo $usage
fi