# /bin/bash

rm -rf spec/rails/experiment/vendor/gems/comodule

mkdir -p spec/rails/experiment/vendor/gems/comodule/

ls -a | grep -v -E '^copy_to_rails.sh$|[.]DS_Store$|^[.]$|^[.][.]$|^spec$|^[.]git$' | xargs -I{} cp -R {} spec/rails/experiment/vendor/gems/comodule/
