# Create Proxy Server

### need

| program | version |
|-----|-----|
| ruby | 2.2.~ |
| curl | 7.~ |

## prepare

### install bundler

```
$ gem install bundler
```

### install gem set into vendor/bundler path

```
$ bundle install --path vendor/bundler
```

### set aws config

create file `aws_config/aws_config.yml`

and write like this.
```
access_key_id: xxxxxxxxxxxxxx
secret_access_key: zzzzzzzzzzzzzzzzzz
```

### set proxy user & password

create file `aws_config/basic_auth.yml`

and write like this.
```
user: proxy_user
pass: proxy_password
```

if you don't write, default user is `user`, default password is `pass`.

## execute create proxy

```
$ bundle exec ruby create_proxy.rb
```

### Option

#### --region

```
virginia
california
oregon
ireland
frankfurt
tokyo
seoul
singapore
sydney
sao_paulo
```

* defalt region is tokyo.

##### example

```
$ bundle exec ruby create_proxy.rb --region california
```

#### --port

port of proxy server.
if you want to 8080, type like this.

```
$ bundle exec ruby create_proxy.rb --port 8080
```

#### -s

`-s` mean `sound off`.

if you don't specify it, play finish music when done create proxy.

##### exaple

```
$ bundle exec ruby create_proxy.rb -s
```

#### -g

proxy server accept global ip address.

if you don't use `-g`, proxy server accept only your ip address.

##### exaple

```
$ bundle exec ruby create_proxy.rb -g
```


## execute delete proxy

```
$ bundle exec ruby delete_proxy.rb
```

* option `-s`(silent), `--region`, `-d`(execute demon), `-a`(delete each region proxy instance)

## execute check exists proxy

```
$ bundle exec ruby check_exists_proxy.rb
```

* no option

