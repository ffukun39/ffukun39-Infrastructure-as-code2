# AnsibleでRuby環境構築

Amazon Linux2環境に指定したバージョンのRuby環境を構築します。  
0→1でRailsアプリを作成した場合の環境構築用のテンプレートとしてご利用ください。  
Railsのバージョンは`5.2`以上を想定していますのでそれ以下の場合は別途ご相談ください。  

## 事前準備

- ansible 2.6.0
- [GitHubでssh接続する手順~公開鍵・秘密鍵の生成から~ - Qiita](https://qiita.com/shizuma/items/2b2f873a0034839e47ce)
- 上記で作成した公開鍵と秘密鍵は `group_vars/server_secret.yml` に`ansible-vault`で暗号化してください。
- master.keyも `group_vars/server_secret.yml` に`ansible-vault`で暗号化してください。

### ansible-vaultの使い方

```bash
ansible-vault edit group_vars/server_secret.yml
```

※ `vault_pass_sample` を `vault_pass` にリネームしてから実行してください。
※ `ansible.cfg` で `vault_pass` のファイルを指定しています。

## 環境設定

1. development, staging, production に対象EC2サーバのIPとssh鍵をセットして下さい。
2. `group_vars/server.yml`にrubyバージョンやgiturlなどの情報をセットして下さい。
3. `group_vars/{env}.yml`に暗号化が必要のない環境毎の変数を定義して下さい。(`git_branch`や`cap_env`など)

## 各自で用意するファイル

nginx.conf
`roles/nginx/templates/nginx.conf.j2`
logrotate
`roles/logrotate/templates/logrotate.j2`

※ファイル名は必ず`.j2`で格納お願いします。

## 実行コマンド(初回のみ)

`ansible-playbook init.yml -i development`  
※ development, staging, productionは環境に応じて変えてください。

## 実行コマンド(2回目以降)

`ansible-playbook deploy.yml -i development`  
※ development, staging, productionは環境に応じて変えてください。

## 注意事項

vault_passファイルは必ず `.gitignore` に登録してください。
