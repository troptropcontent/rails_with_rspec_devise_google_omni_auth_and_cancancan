This template sets up : 

- rspec
- factorybot
- devise
- omniauth with google (through devise)
- cancancan

To use it you just need to run : 

`rails new your_future_awesome_project_name -m https://raw.githubusercontent.com/troptropcontent/rails_with_rspec_devise_google_omni_auth_and_cancancan/master/template.rb`

Then, to have it working you need to set up your google credentials ([how to get some](https://developers.google.com/workspace/guides/create-credentials)) in your rails credentials : 

```
# EDITOR="code --wait" bin/rails credentials:edit

google_oauth2:
  client_id: xxxxxxx.apps.googleusercontent.com
  client_secret: xxxxxx

```

And voilà !

PS : There is no CSS, you'll have to do what you have to do to make it pretty
