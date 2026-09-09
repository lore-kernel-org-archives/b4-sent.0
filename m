From: Petr Hodina <petr.hodina@protonmail.com>
Date: Wed, 09 Sep 2026 08:27:22 +0200
Subject: [PATCH u-boot] net, common: add NET_SKIP_BOOT_INIT for gadget-only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-b4-net-skip-boot-init-v1-1-e2a460818205@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7kAiEqVXKV0046SOhUQysRTEu
 xvt8n3+exsoZ2GFe7NB5q+opFjB3hqg6RXfjDJWhta0zjhr0XcYuaB+ZEGfUkGJUnBwgQKRcX0
 3QnWXzEF+V/cB63WE53/X1c9M5YzCvh+oRIKigQAAAA==
X-Change-ID: 20260611-b4-net-skip-boot-init-86fcfcc0674d
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Peter Robinson <pbrobinson@gmail.com>, Simon Glass <sjg@chromium.org>, 
 Michael Walle <mwalle@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin@pqrs.dk>, 
 David Heidelberg <david@ixit.cz>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788935254; l=1858;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=IF4rVkjfbIS1XY/uUJfKFGMRapQTniYTNdv/cb22bn0=;
 b=WFWiV4SfUHJb7nhE8STLwX7+g4DCD86qVEucJkwG9XFbvPcqfj1n4hQAsUr1v/TxJfCU5ZMZC
 /kfdp3qOSEgA+SNTGU6isQ+LbkXnGHPA7iZba3Z/+nyRQkm0VoECxdV
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Gate the initr_net() INITCALL on CONFIG_NET_SKIP_BOOT_INIT at the
call site in initcall_run_r(), so boards with no wired NIC can skip
the boot-time probe and "Net:" banner without touching initr_net()
itself.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
initr_net() probes for Ethernet and prints a "Net:" banner when `NET` option
is enabled, which is not relevant for boards that use USB gadgets
for networking.

Add CONFIG_NET_SKIP_BOOT_INIT to skip that boot-time probe. Later
invocations still probe UCLASS_ETH normally. Defaults to n.
---
 common/board_r.c | 6 ++++--
 net/Kconfig      | 7 +++++++
 2 files changed, 11 insertions(+), 2 deletions(-)

diff --git a/common/board_r.c b/common/board_r.c
index a397e20959d..1de4b4925b1 100644
--- a/common/board_r.c
+++ b/common/board_r.c
@@ -761,8 +761,10 @@ static void initcall_run_r(void)
 	INITCALL(pci_ep_init);
 #endif
 #if CONFIG_IS_ENABLED(NET)
-	WATCHDOG_RESET();
-	INITCALL(initr_net);
+	if (!IS_ENABLED(CONFIG_NET_SKIP_BOOT_INIT)) {
+		WATCHDOG_RESET();
+		INITCALL(initr_net);
+	}
 #endif
 #if CONFIG_IS_ENABLED(POST)
 	INITCALL(initr_post);
diff --git a/net/Kconfig b/net/Kconfig
index e712a0dd2ac..d42a68d8e12 100644
--- a/net/Kconfig
+++ b/net/Kconfig
@@ -14,6 +14,13 @@ menuconfig NET
 
 if NET
 
+config NET_SKIP_BOOT_INIT
+	bool "Skip the boot-time ethernet probe + 'Net:' banner"
+	help
+	  By default init runs eth_initialize() if `NET` option is enabled.
+	  Some boards do not have a wired NIC but use RNDIS or CDC-NCM
+	  gadgets on the USB to provide network connectivity.
+
 choice
 	prompt "Networking stack"
 	default NET_LEGACY

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260611-b4-net-skip-boot-init-86fcfcc0674d

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

