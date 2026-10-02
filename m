From: Igor Velkov <iav@iav.lv>
Date: Fri, 02 Oct 2026 19:49:20 +0000
Subject: [PATCH] arm: mvebu: helios4_defconfig: enable device tree overlays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-helios4-overlays-v1-1-2e03eb306e38@iav.lv>
X-B4-Tracking: v=1; b=H4sIAL8KwGoC/x3MQQqAIBBA0avIrBN00IiuEi0kpxoIDQekiO6et
 HyL/x8QKkwCo3qgUGXhnBpsp2DZQ9pIc2wGNNhbY1DvdHAWp3OlcoRb9ICEMVpvXfTQsrPQyte
 /nOb3/QB8ehiSYgAAAA==
To: Stefan Roese <stefan.roese@mailbox.org>, 
 Dennis Gilmore <dgilmore@redhat.com>
Cc: Tom Rini <trini@konsulko.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=998; i=iav@iav.lv;
 h=from:subject:message-id; bh=wEpmrk9QbEB6mk+TlnWcyRteT/tXf6DXqjhPx4OuQZg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkHuA7u3Nd6Y1FD1p3qfQn1yqlTbx5eKBGmaLj2ypK/2
 Tc4VcKmdpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJvJvPyDB7T4ps2i/mvMLc
 Raq89rVcR79lVoV9Lgpdd8jnjGNz6HdGhtesFo9nLRHvjLH/Y7s1K9faTvdOyp5Ef5maAIP5Lxo
 jOQA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable OF_LIBFDT_OVERLAY so that "fdt apply" is available and boot
scripts can apply device tree overlays on Helios4.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Helios4: with this option "fdt apply" merges an overlay into a
device tree in RAM; without it fdt has no apply subcommand.
---
 configs/helios4_defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/configs/helios4_defconfig b/configs/helios4_defconfig
index d218949e307..9b56d87ea29 100644
--- a/configs/helios4_defconfig
+++ b/configs/helios4_defconfig
@@ -11,6 +11,7 @@ CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0xff0000
 CONFIG_TARGET_HELIOS4=y
 CONFIG_MVEBU_SPL_BOOT_DEVICE_MMC=y
 CONFIG_DEFAULT_DEVICE_TREE="armada-388-helios4"
+CONFIG_OF_LIBFDT_OVERLAY=y
 CONFIG_SPL_SERIAL=y
 CONFIG_SPL_STACK=0x4002c000
 CONFIG_SPL_TEXT_BASE=0x40000030

---
base-commit: a6ab6a66146ed0bf1420db0ee858b49005783222
change-id: 20261002-helios4-overlays-82e2dd1514d5

Best regards,
-- 
Igor Velkov <iav@iav.lv>

