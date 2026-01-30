# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "local-time", to: "https://ga.jspm.io/npm:local-time@3.0.2/app/assets/javascripts/local-time.es2017-esm.js"
pin "tom-select", to: "https://esm.sh/tom-select@2.4.3?bundle-deps"
pin "simplycountdown", to: "https://esm.sh/simplycountdown.js@3.0.0"
