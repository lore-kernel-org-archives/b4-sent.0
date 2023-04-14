From: Jaime Breva <jbreva@nayarsystems.com>
Date: Fri, 14 Apr 2023 13:07:40 +0200
Subject: [PATCH] net: wwan: Expose secondary AT port on DATA1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230414-rpmsg-wwan-secondary-at-port-v1-1-6d7307527911@nayarsystems.com>
X-B4-Tracking: v=1; b=H4sIAPwzOWQC/x2NQQqDMBAAvyJ77oKmQaFfKT1skq3mYBJ2Q7WIf
 2/scRiYOUBZIis8ugOEP1FjTg2GWwd+oTQzxtAYTG/uvR0sSll1xm2jhMo+p0DyRapYslQMbjI
 0jp4nS9ASjpTRCSW/XJGVtLJcogi/4/7/Pl/n+QMph2lPhwAAAA==
To: Stephan Gerhold <stephan@gerhold.net>, 
 Loic Poulain <loic.poulain@linaro.org>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jaime Breva <jbreva@nayarsystems.com>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681470586; l=1075;
 i=jbreva@nayarsystems.com; s=20230414; h=from:subject:message-id;
 bh=cSR4ZQap91Ye+xWxHZdF++TRRzXHB58d7aORnQDEYqM=;
 b=UtqPg4Ls/omSuTtTSlV0VkJABHHRNDsCfzzMZBGbx0UTm78zIV39iYILVj5p0bOVV8LWiNvRi
 1InMJSqRsISARwe/xrdCFAgj+PEDNk4JRU+vdLJAYeKPJMiP3rqDHnJ
X-Developer-Key: i=jbreva@nayarsystems.com; a=ed25519;
 pk=zDC7l1kB518eXlRUJzDUyrUOKe2m/yx+62R/yqmd/kM=
X-Endpoint-Received: by B4 Relay for jbreva@nayarsystems.com/20230414 with auth_id=42
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Our use-case needs two AT ports available:
One for running a ppp daemon, and another one for management

This patch enables a second AT port on DATA1

Signed-off-by: Jaime Breva <jbreva@nayarsystems.com>
---
 drivers/net/wwan/rpmsg_wwan_ctrl.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/wwan/rpmsg_wwan_ctrl.c b/drivers/net/wwan/rpmsg_wwan_ctrl.c
index 31c24420ab2e..e964bdeea2b3 100644
--- a/drivers/net/wwan/rpmsg_wwan_ctrl.c
+++ b/drivers/net/wwan/rpmsg_wwan_ctrl.c
@@ -149,6 +149,7 @@ static const struct rpmsg_device_id rpmsg_wwan_ctrl_id_table[] = {
 	/* RPMSG channels for Qualcomm SoCs with integrated modem */
 	{ .name = "DATA5_CNTL", .driver_data = WWAN_PORT_QMI },
 	{ .name = "DATA4", .driver_data = WWAN_PORT_AT },
+	{ .name = "DATA1", .driver_data = WWAN_PORT_AT },
 	{},
 };
 MODULE_DEVICE_TABLE(rpmsg, rpmsg_wwan_ctrl_id_table);

---
base-commit: c9c3395d5e3dcc6daee66c6908354d47bf98cb0c
change-id: 20230414-rpmsg-wwan-secondary-at-port-db72a66ce74a

Best regards,
-- 
Jaime Breva <jbreva@nayarsystems.com>

