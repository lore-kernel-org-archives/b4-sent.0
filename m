From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:29:56 +0100
Subject: [PATCH 02/12] scripts: Adjust heuristic to see if current user can
 sudo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-2-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2158;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=l6fdWgpjKbFsO8OSF2C8SwibeLtb/ff0owgRzjJFREo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipCsPpkIX2JhlRX+z1rL10+Zhgtf+4MRzD
 AENts0jzDlM04kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQrAAoJELqXzVK3
 lkFPuZcL/jSPgS8nN0XdsUdhi40eNWjTWD+6rPmZ90OgmAjS0Zj4f7rpcTX3nQN4lBHbOYM/KXs
 KOZcYx00ZkZUjoBnz0furKziOeA0o6HGjHODWs19G5P0P6RfT/w48EPSTvDBaKoiuiOqEv+P84x
 YCq/61C3OqY03Y06Pqq1DYKhM8wwFle4Wj8deifpS6MeowsZepV6Rre57qRO1TQXJ9SSqeNqPHZ
 5AcEwn5jykIkES9VQh1e5RVdlP8Z2WlbET+GS86+FLbXo6Ialk7T7y+RtojjsuA8NRnRJ09pv4s
 ueV9wxC6W3CA5umovDZaoUfWsW8FliWAQtWEaWQzrZSq+aSntVjRDyGy8mP7NrapUB4RGLohfHU
 YM/BOI+5JxIuwr1+euvlbuWjgujom2Dn4kQpBDNYNQE0u/K7kLj4QrN0ve4Ix0neq2D5uajTEkl
 gfbXf2tS/ELYlb6Q5wcv0RvBMKD0Ur7HpZNx2kULqL3U2VqDbYwSUS7O0vt1VqmpBdt7AAv4M56
 rY=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

* New heuristic uses the following sudo command options:
  -n : "non-interactive"; will prevent sudo from prompting the user for
       any kind of input.
  -v : Update the user's cache credentials; has distinct output for users
       with and without sudo:
       1. Without sudo the output is "Sorry, user __USER__ may not run
          sudo..."
       2. With sudo it has two messages (with and without password). But
          we ignore the distinction as both of these mean that user can
          sudo.
* Avoid setting SUDO_ASKPASS. This env variable is suppose to have the
  executable that will be executed when asking for sudo instead of a
  boolean.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/libvirt_pool.sh | 25 +++++++++++++++++++++----
 1 file changed, 21 insertions(+), 4 deletions(-)

diff --git a/scripts/libvirt_pool.sh b/scripts/libvirt_pool.sh
index f8c309e..ffae928 100644
--- a/scripts/libvirt_pool.sh
+++ b/scripts/libvirt_pool.sh
@@ -1,6 +1,26 @@
 #!/bin/bash
 # Helpers to work with virsh pools
 
+get_can_sudo()
+{
+	# Heuristic to see if the current user can sudo
+	# -n : This is the non-interactive argument in sudo and will prevent
+	#      sudo from prompting the user for any kind of input.
+	# -v : This tries to update the users cache credentials but also has
+	#      distinct output for users with and without sudo:
+	#      1. Without sudo the output is
+	#         "Sorry, user __USER__ may not run sudo..."
+	#      2. With sudo it has two messages: one for paswordless sudo and
+	#         one passwordfull sudo. But we ignore the distinction as both
+	#         of these mean that can_sudo is "y".
+	if [[ $(sudo -nv 2>&1 | grep 'may not' > /dev/null) -eq 0 ]]; then
+		echo "n"
+		exit
+	fi
+	echo "y"
+	exit
+}
+
 get_pool_vars()
 {
 	if [[ -f $OS_FILE ]]; then
@@ -10,10 +30,7 @@ get_pool_vars()
 		fi
 	fi
 
-	SUDO_ASKPASS=/bin/false sudo -A whoami > /dev/null 2>&1
-	if [[ $? -eq 0 ]]; then
-		CAN_SUDO="y"
-	fi
+	CAN_SUDO=get_can_sudo
 
 	if [[ "$USES_QEMU_USER_SESSION" != "y" ]]; then
 		REQ_SUDO="sudo"

-- 
2.44.2

