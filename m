From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:00 +0100
Subject: [PATCH RESEND 02/12] scripts: Adjust heuristic to see if current
 user can sudo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-2-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2158;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=l6fdWgpjKbFsO8OSF2C8SwibeLtb/ff0owgRzjJFREo=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGeE/qKhqs3WN4N4sdaFXPB9a6rZ1Vdh2hYcDaYSFePad3Onn
 YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6iAAoJELqXzVK3lkFPEEkL/1F7
 Yk9iCgc3wHGfmEWQHA8nOMz6aC3m5BPgfvCKRQP9xSjPDvyYjSpMaYCHn+fe4Ml6CAvevRdybhO
 uh3bn7ELojnMOBjrCYiXwiJoCwrGmXb1dIj6EvAuYDy2g352bqr2B6JJLU/gGs2a6pQrp4R+GjD
 n1ibbcXmZqRNUtZm0o3kqBE+xMQK1AAesM/DrsaukSOVM8pfkm3Dz/bOPCNacptNZ0kIg/miFuE
 AukJ2+zVcKrCPTArHAtDFpnGnQ0WlTtF1GyCQQiFDDNiPgtg24DLMkhjy4V/4F8kHk/C67ZlyN7
 UKgZ6GZjN/J3GLjofC/Y75fgQi04wYnYP/r5ZQTy6UJ5Y3DcvlyayxRB0iN8iV2fVHBMof04X6r
 izUXuWMm8Decj27mWqz8nx/c1NP7HBCXCu00eFJjz/lx6FK2Io5n0IKvEdqZNkR48exM96A7Cic
 1aHwmvQalnqNlTtwE1SEKoVptdTBz0WBJhGJpf5wSU/v4gglIk8l0pwLfJuA==
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

