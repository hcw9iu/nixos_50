{ pkgs, config, ... }:
let
  # 從 stylix 配置中獲取字體設置
  font = config.stylix.fonts.serif.name;
  fontSize = toString config.stylix.fonts.sizes.terminal;

  notif = pkgs.writeShellScriptBin "notif" # bash
    ''
      # Shell script to send custom notifications
      # Usage: notif "sender_id" "message" ["description"]
      NOTIF_FOLDER="/tmp/notif"
      sender_id=$1 # To overwrite existing notifications
      title=$2
      description=$3

      [[ -d "$NOTIF_FOLDER" ]] || mkdir $NOTIF_FOLDER
      [[ -f "$NOTIF_FOLDER/$sender_id" ]] || (echo "0" > "$NOTIF_FOLDER/$sender_id")

      old_notification_id=$(cat "$NOTIF_FOLDER/$sender_id")
      [[ -z "$old_notification_id" ]] && old_notification_id=0

       ${pkgs.libnotify}/bin/notify-send \
      --replace-id="$old_notification_id" --print-id \
      --app-name="$sender_id" \
      --hint="string:x-canonical-private-synchronous:$sender_id" \
      --hint="string:desktop-entry:$sender_id" \
      --hint="int:transient:1" \
      --hint="string:x-dunst-stack-tag:$sender_id" \
      --hint="string:urgency:normal" \
      "<span font='${font} ${fontSize}'><b>$title</b></span>" \
      "<span font='${font} ${fontSize}'>$description</span>" \
      > "$NOTIF_FOLDER/$sender_id"
    '';
      #"$title" \
      #"$description" \

in { home.packages = [ pkgs.libnotify notif ]; }
