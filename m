From: "Ji-Ze Hong (Peter Hong)" <peter_hong@fintek.com.tw>
Date: Tue, 01 Sep 2026 22:27:19 +0800
Subject: [PATCH] can: usb: f81604: fix use-after-free on disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-f81604-fix-v1-1-c55b5178f9f8@fintek.com.tw>
X-B4-Tracking: v=1; b=H4sIAMbglmoC/yWMQQ5AMBBFryKz1mQqNLiKWFRNGQukRSTi7gbL9
 3/euyBSYIpQJxcEOjjyMgvoNAE32nkgxb0wZJgZrFArX2qDufJ8qipHJKvlKgyIsAaS+Ys17c9
 x7yZy21uA+34AizRzPW4AAAA=
X-Change-ID: 20260901-f81604-fix-9400ea120256
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 "Ji-Ze Hong (Peter Hong)" <peter_hong@fintek.com.tw>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788272851; l=1272;
 i=peter_hong@fintek.com.tw; s=20260824; h=from:subject:message-id;
 bh=OrmVvmr1snDnaMTisWi/0+p/lhxiIIgiSJYL9JzLpr4=;
 b=XxfwAoT2qzgD1EcOdZuJy4uyNCRmVLd5sYBtJb2g9t8gVAedH+Hu4tvDhomxjSWAzawGHXY/B
 8cOYq9PH3ScD3YgIOhmirZwZUdGJfj/BzwZtrsOYfZNM1CpM6UUl57b
X-Developer-Key: i=peter_hong@fintek.com.tw; a=ed25519;
 pk=8sYixQfVOzNMM+g53fxG9d3MHOFC02ZggNS0OhG5LMA=
X-Endpoint-Received: by B4 Relay for peter_hong@fintek.com.tw/20260824 with auth_id=973
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unregister the URBs before cancelling clear_reg_work to prevent an URB
completion handler from scheduling work after cancel_work_sync() has
returned.

Otherwise the pending work may run after the netdev and private data are
freed, resulting in a use-after-free.

Suggested-by: Marc Kleine-Budde <mkl@pengutronix.de>
Closes: https://lore.kernel.org/all/20260824133009.CF85A1F00A3A@smtp.kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Ji-Ze Hong (Peter Hong) <peter_hong@fintek.com.tw>
---
 drivers/net/can/usb/f81604.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/f81604.c b/drivers/net/can/usb/f81604.c
index 4c147b9d6d69..bb155b876924 100644
--- a/drivers/net/can/usb/f81604.c
+++ b/drivers/net/can/usb/f81604.c
@@ -1075,10 +1075,10 @@ static int f81604_close(struct net_device *netdev)
 	f81604_set_reset_mode(priv);
 
 	netif_stop_queue(netdev);
-	cancel_work_sync(&priv->clear_reg_work);
 	close_candev(netdev);
 
 	f81604_unregister_urbs(priv);
+	cancel_work_sync(&priv->clear_reg_work);
 
 	return 0;
 }

---
base-commit: 475cb4ea138f4b0e7f43ff79220f4013a6a840b8
change-id: 20260901-f81604-fix-9400ea120256

Best regards,
--  
Ji-Ze Hong (Peter Hong) <peter_hong@fintek.com.tw>

