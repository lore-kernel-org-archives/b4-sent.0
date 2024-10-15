From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 15 Oct 2024 13:34:55 +0200
Subject: [PATCH 5/5] guestfs: bringup: add debug mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-bringup-guestfs-debug-v1-5-bd74c0c31412@samsung.com>
References: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
In-Reply-To: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.com>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728992109; l=2391;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=WZwxchjtEQrknS8F+lFGpB+NBAHq3BDvOI2VdkRBVAE=;
 b=QHvmE+dvCaP2yQ2MZqSYtuPGIbPIOPpoXOe2bB108A7dX5DDyrUjUFqFbw4IPppXY4VXuMSlU
 dA+vpOhliagBjpukH/nTtVDJRFjPureyN/SNXV/PURIvXZlmTWFHlou
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To be able to run bringup_guestfs.sh script in bash debug mode:
1. disabled
2. set -x
3. set -euxo pipefile

From set manual:
-x  Print commands and their arguments as they are executed.
-e  Exit immediately if a command exits with a non-zero status.
-u  Treat unset variables as an error when substituting.
-o option-name
          Set the variable corresponding to option-name:
              pipefail     the return value of a pipeline is the status of
                           the last command to exit with a non-zero status,
                           or zero if no command exited with a non-zero status

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 kconfigs/Kconfig.guestfs   | 21 +++++++++++++++++++++
 scripts/bringup_guestfs.sh |  8 ++++++++
 2 files changed, 29 insertions(+)

diff --git a/kconfigs/Kconfig.guestfs b/kconfigs/Kconfig.guestfs
index a804c8fce2fd48049bbd6a7954abff547e041a19..2ebd7987b66a0ebdf601eb30307e1296876957d3 100644
--- a/kconfigs/Kconfig.guestfs
+++ b/kconfigs/Kconfig.guestfs
@@ -203,4 +203,25 @@ config VIRT_BUILDER_OS_VERSION
          to get a list of operating systems and versions supported
          by guestfs.
 
+choice
+	prompt "Guestfs bringup debug mode"
+	default GUESTFS_BRINGUP_DEBUG_DISABLED
+
+config GUESTFS_BRINGUP_DEBUG_DISABLED
+	bool "Disabled"
+	help
+	  Disables bringup debug.
+
+config GUESTFS_BRINGUP_DEBUG_0
+	bool "set -x"
+	help
+	  Enables 'set -x' when running scripts/guestfs_bringup.sh.
+
+config GUESTFS_BRINGUP_DEBUG_1
+	bool "set -euxo pipefile"
+	help
+	  Enables 'set -euxo pipefile' when running scripts/guestfs_bringup.sh.
+
+endchoice
+
 endif # GUESTFS
diff --git a/scripts/bringup_guestfs.sh b/scripts/bringup_guestfs.sh
index 54d8d92dcf2ff5f1de2099cbff785866c9f1c27d..eb506b9c1b7b2105f443ce0b4194dcfa9fb5a476 100755
--- a/scripts/bringup_guestfs.sh
+++ b/scripts/bringup_guestfs.sh
@@ -5,6 +5,14 @@
 source ${TOPDIR}/.config
 source ${TOPDIR}/scripts/lib.sh
 
+if [[ "${CONFIG_GUESTFS_BRINGUP_DEBUG_0+x}" && ${CONFIG_GUESTFS_BRINGUP_DEBUG_0} == "y" ]]; then
+	set -x
+fi
+
+if [[ "${CONFIG_GUESTFS_BRINGUP_DEBUG_1+x}" && ${CONFIG_GUESTFS_BRINGUP_DEBUG_1} == "y" ]]; then
+	set -euxo pipefail
+fi
+
 export LIBVIRT_DEFAULT_URI=$CONFIG_LIBVIRT_URI
 
 # On systems using system sesion, ensure that we start the default

-- 
2.39.2

