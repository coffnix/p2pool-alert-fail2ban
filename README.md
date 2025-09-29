# P2Pool payout alerts with Fail2Ban and Telegram

This setup uses Fail2Ban to monitor the P2Pool log and send a Telegram message whenever a payout line appears. It does **not** ban any IP. Fail2Ban is only used as a trigger to run a script.

## Files and purpose

- **/etc/fail2ban/filter.d/p2pool-payout.conf**
  Fail2Ban filter that matches payout lines in the P2Pool log. It captures the wallet address as `<F-ID>` so actions can reuse it.

- **/etc/fail2ban/action.d/telegram.conf**
  Fail2Ban action that calls the Telegram script with your chat id and the full matched line.
  ⚠️ You must edit this file to set your real Telegram chat id.

- **/etc/fail2ban/jail.local**
  Jail that connects the filter to the P2Pool log path and selects the Telegram action. No firewall actions are used here.

- **/usr/local/bin/send_telegram.sh**
  Shell script that posts to the Telegram Bot API using POST and urlencoding. It writes its own debug output to `/var/log/p2pool_telegram.log`.
  ⚠️ You must edit this file to set your Telegram bot token.

## Requirements

1. A Telegram bot token from @BotFather.
2. Your Telegram chat id. Start a private chat with your bot and send `/start`. Then run:
   ```
   curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates" | jq .
   ```
   Look for `result[0].message.chat.id`.

## Installation

1. Copy the files to their correct paths:
   ```
   sudo install -Dm0755 usr/local/bin/send_telegram.sh /usr/local/bin/send_telegram.sh
   sudo install -Dm0644 etc/fail2ban/filter.d/p2pool-payout.conf /etc/fail2ban/filter.d/p2pool-payout.conf
   sudo install -Dm0644 etc/fail2ban/action.d/telegram.conf /etc/fail2ban/action.d/telegram.conf
   sudo install -Dm0644 etc/fail2ban/jail.local /etc/fail2ban/jail.local
   ```

2. Edit the Telegram action and the script:
   ```
   sudo editor /etc/fail2ban/action.d/telegram.conf
   sudo editor /usr/local/bin/send_telegram.sh
   ```
   In `telegram.conf` set your chat id:
   ```
   actionban   = /usr/local/bin/send_telegram.sh "<your chat id>" "P2Pool payout detected | wallet=<F-ID> | <matches>"
   ```
   In `send_telegram.sh` set:
   ```
   TOKEN='YOUR_BOT_TOKEN'
   ```

3. Ensure permissions and log file exist:
   ```
   sudo chmod 0755 /usr/local/bin/send_telegram.sh
   sudo touch /var/log/p2pool_telegram.log
   sudo chown root:root /var/log/p2pool_telegram.log
   ```

4. Restart Fail2Ban and check the jail:
   ```
   sudo systemctl restart fail2ban
   sudo fail2ban-client status p2pool-payout
   ```

## How it works

1. P2Pool writes a payout line like:
   ```
   NOTICE  YYYY-MM-DD HH:MM:SS.mmm P2Pool Your wallet <WALLET> got a payout of <AMOUNT> XMR in block <HEIGHT>
   ```
2. The filter matches the line and captures the wallet as `<F-ID>`.
3. The jail triggers the `telegram` action.
4. The script sends a message to your Telegram chat including the wallet and the full log line (`<matches>`).

## Testing

- Validate the filter (does not send messages):
  ```
  fail2ban-regex /path/to/test.log /etc/fail2ban/filter.d/p2pool-payout.conf --print-all-matched
  ```

- Test the Telegram script directly:
  ```
  /usr/local/bin/send_telegram.sh "<your chat id>" "direct script test"
  ```

- Simulate a payout event:
  ```
  WALLET="45X...UnGf"
  AMOUNT="0.001110235172"
  BLOCK="3509850"
  TS=$(date +"%Y-%m-%d %H:%M:%S.%4N")
  echo "NOTICE  $TS P2Pool Your wallet $WALLET got a payout of $AMOUNT XMR in block $BLOCK" | sudo tee -a /var/lib/p2pool/p2pool.log
  sleep 2
  tail -n 50 /var/log/p2pool_telegram.log
  ```

If nothing arrives on Telegram, check:
```
sudo tail -n 100 /var/log/fail2ban.log
sudo tail -n 100 /var/log/p2pool_telegram.log
```

## Notes

- `<F-ID>` captures the wallet, `<matches>` expands to the full matched line.
- `fail2ban-regex` never runs actions, only validates regex.
- For testing, always append fresh lines with current timestamps, otherwise Fail2Ban may ignore them as “too old”.
- To bypass timestamp age restriction temporarily, add `ignoreolder = 0` to a jail override in `/etc/fail2ban/jail.d/` and restart Fail2Ban.
