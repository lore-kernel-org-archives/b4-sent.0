From: Fan Ye <fy15309206903@gmail.com>
Date: Wed, 12 Aug 2026 11:42:09 +0000
Subject: [PATCH v3] thunderbolt: Stop waiting on a path pending bit that
 never clears
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-b4-tb-pending-v3-1-3a292e7194c9@gmail.com>
X-B4-Tracking: v=1; b=H4sIABBcfGoC/yXMTQ5AMBBA4avIrE1S4yfiKmKh7WAsSlpEIu6uW
 H6L9y4I7IUDNMkFng8JsriIPE3ATL0bGcVGAymqVJ0R6gI3jSs7K25Em+WkFA2m4hJis3oe5Px
 +bfc77Hpms70TuO8HsnLJ43EAAAA=
X-Change-ID: 20260812-b4-tb-pending-d132002fc6e5
To: Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Andreas Noever <andreas.noever@gmail.com>
Cc: linux-usb@vger.kernel.org, Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786534928; l=5168;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=L3Lnw1mWZ/p8vS+tXDNiU2TpU0v+O3am4AgNeqUNTmI=;
 b=/XvGN1ezr9fpFXe7pnaxHCyvTv5lC0EQ4Rh1RCpd5lJlZgt6AkEm0TMhPN4MiB+8cCvvXgg6Q
 4xIfH3A33HkBcpxqV0R8xJwcfSWceKt5+duazqF563VQ16c/Ezf3oeM
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__tb_path_deactivate_hop() waits up to 500 ms for a hop's pending bit to
read back clear. On an ASMedia ASM4242 host router the host interface
adapter latches it once enough frames have gone through the DMA ring and
never clears it again: the teardown finds it already set, seconds after
the last frame and with the path still up. USB4 v2 table 8-23 has the
field read only and zero unless packets belonging to the path are waiting
to be dequeued, so the wait is right and this adapter is not.

Make the wait a per-adapter length and quirk those routers to zero, which
leaves the loop reading the bit exactly once. A hop that does drain still
says so on that read, and one that does not answers -ETIMEDOUT without
burning the timeout: bringing the interface down takes 6 ms where it took
506.

Assisted-by: Claude:claude-opus-5
Signed-off-by: Fan Ye <fy15309206903@gmail.com>
---
Measured on two ASM4242 hosts wired to each other, hw_vendor_id 0x174c,
hw_device_id 0x2428, NVM 200011.250708.

Both behaviours in one binary selected at runtime, three rounds each: the
single read reports drained at 200 frames in 3 of 3 and answers -ETIMEDOUT
at 400 frames in 3 of 3, where skipping the read answers -ETIMEDOUT at 200
frames as well.

v3:
- Give the adapter a pp_timeout_msec instead of the learned pending_stuck
  flag, and let the quirk clear it.
- Feed it to the existing timeout rather than skipping the wait, so a
  quirked adapter still reads the bit once.

v2: https://lore.kernel.org/linux-usb/20260812-b4-tb-pending-v2-v2-1-0667ee84c2d4@gmail.com/
---
 drivers/thunderbolt/path.c   |  2 +-
 drivers/thunderbolt/quirks.c | 18 ++++++++++++++++++
 drivers/thunderbolt/switch.c |  1 +
 drivers/thunderbolt/tb.h     |  6 ++++++
 4 files changed, 26 insertions(+), 1 deletion(-)

diff --git a/drivers/thunderbolt/path.c b/drivers/thunderbolt/path.c
index b2c322e76b8a..05249eed3f64 100644
--- a/drivers/thunderbolt/path.c
+++ b/drivers/thunderbolt/path.c
@@ -398,7 +398,7 @@ static int __tb_path_deactivate_hop(struct tb_port *port, int hop_index,
 		return ret;
 
 	/* Wait until it is drained */
-	timeout = ktime_add_ms(ktime_get(), 500);
+	timeout = ktime_add_ms(ktime_get(), port->pp_timeout_msec);
 	do {
 		ret = tb_port_read(port, &hop, TB_CFG_HOPS, 2 * hop_index, 2);
 		if (ret)
diff --git a/drivers/thunderbolt/quirks.c b/drivers/thunderbolt/quirks.c
index 9f7914ac2f48..f41c5b7ef114 100644
--- a/drivers/thunderbolt/quirks.c
+++ b/drivers/thunderbolt/quirks.c
@@ -52,6 +52,19 @@ static void quirk_block_rpm_in_redrive(struct tb_switch *sw)
 	tb_sw_dbg(sw, "preventing runtime PM in DP redrive mode\n");
 }
 
+static void quirk_stuck_pending(struct tb_switch *sw)
+{
+	struct tb_port *port;
+
+	tb_switch_for_each_port(sw, port) {
+		if (!tb_port_is_nhi(port))
+			continue;
+
+		port->pp_timeout_msec = 0;
+		tb_port_dbg(port, "pending bit does not clear, reading it once\n");
+	}
+}
+
 struct tb_quirk {
 	u16 hw_vendor_id;
 	u16 hw_device_id;
@@ -114,6 +127,11 @@ static const struct tb_quirk tb_quirks[] = {
 	{ 0x0438, 0x0209, 0x0000, 0x0000, quirk_clx_disable },
 	{ 0x0438, 0x020a, 0x0000, 0x0000, quirk_clx_disable },
 	{ 0x0438, 0x020b, 0x0000, 0x0000, quirk_clx_disable },
+	/*
+	 * ASMedia ASM4242 never clears the Pending Packets bit of its host
+	 * interface adapter.
+	 */
+	{ 0x174c, 0x2428, 0x0000, 0x0000, quirk_stuck_pending },
 };
 
 /**
diff --git a/drivers/thunderbolt/switch.c b/drivers/thunderbolt/switch.c
index a830c82bb905..fb0fc8def0a9 100644
--- a/drivers/thunderbolt/switch.c
+++ b/drivers/thunderbolt/switch.c
@@ -703,6 +703,7 @@ static int tb_init_port(struct tb_port *port)
 	int cap;
 
 	INIT_LIST_HEAD(&port->list);
+	port->pp_timeout_msec = TB_PENDING_TIMEOUT;
 
 	/* Control adapter does not have configuration space */
 	if (!port->port)
diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index ec9192b61bc0..3ddd3cbc2b39 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -27,6 +27,9 @@
 /* Need to keep power on while USB4 port is in redrive mode */
 #define QUIRK_KEEP_POWER_IN_DP_REDRIVE			BIT(2)
 
+/* How long a hop is given to drain when a path is deactivated */
+#define TB_PENDING_TIMEOUT				500 /* ms */
+
 /**
  * struct tb_nvm - Structure holding NVM information
  * @dev: Owner of the NVM
@@ -273,6 +276,8 @@ struct tb_bandwidth_group {
  * @max_bw: Maximum possible bandwidth through this adapter if set to
  *	    non-zero.
  * @redrive: For DP IN, if true the adapter is in redrive mode.
+ * @pp_timeout_msec: How long a hop of this adapter is given to drain when a
+ *		     path is deactivated. %0 means a single read.
  *
  * In USB4 terminology this structure represents an adapter (protocol or
  * lane adapter).
@@ -302,6 +307,7 @@ struct tb_port {
 	struct list_head group_list;
 	unsigned int max_bw;
 	bool redrive;
+	unsigned int pp_timeout_msec;
 };
 
 /**

---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260812-b4-tb-pending-d132002fc6e5

Best regards,
--  
Fan Ye <fy15309206903@gmail.com>

