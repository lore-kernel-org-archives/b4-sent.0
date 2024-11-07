From: Oliver Facklam <oliver.facklam@zuehlke.com>
Date: Thu, 07 Nov 2024 12:43:28 +0100
Subject: [PATCH 2/4] usb: typec: hd3ss3220: use typec_get_fw_cap() to fill
 typec_cap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-usb-typec-controller-enhancements-v1-2-3886c1acced2@zuehlke.com>
References: <20241107-usb-typec-controller-enhancements-v1-0-3886c1acced2@zuehlke.com>
In-Reply-To: <20241107-usb-typec-controller-enhancements-v1-0-3886c1acced2@zuehlke.com>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Facklam <oliver.facklam@zuehlke.com>, 
 Benedict von Heyl <benedict.vonheyl@zuehlke.com>, 
 Mathis Foerst <mathis.foerst@zuehlke.com>, 
 Michael Glettig <michael.glettig@zuehlke.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730979838; l=1169;
 i=oliver.facklam@zuehlke.com; s=20241107; h=from:subject:message-id;
 bh=V/ZRmfdf8rYgiBJZgxIzqV0Qzt6dP65mnitUcwhfB4w=;
 b=CAlkuKbhXj0tvqdtVk2f1Ln9aB48sV4so98MjJKKfxfKG8Za5hyKKq/0s/E/2ZApPZo2Jhb2q
 oz3Iqv2qZo/AQ5EkCw4BGfjybZpQYk7qt0d3DLA2eea4TtbDU63qn+b
X-Developer-Key: i=oliver.facklam@zuehlke.com; a=ed25519;
 pk=bMlB+nko+ewJHQJLwq2t26VDbmRmNDPr/1woleqp7Lw=
X-Endpoint-Received: by B4 Relay for oliver.facklam@zuehlke.com/20241107 with auth_id=271
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The type, data, and prefer_role properties were previously hard-coded
when creating the struct typec_capability.

Use typec_get_fw_cap() to populate these fields based on the
respective fwnode properties.

Signed-off-by: Oliver Facklam <oliver.facklam@zuehlke.com>
---
 drivers/usb/typec/hd3ss3220.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/typec/hd3ss3220.c b/drivers/usb/typec/hd3ss3220.c
index 56f74bf70895ca701083bde44a5bbe0b691551e1..e6e4b1871b5d805f8c367131509f4e6ec0d2b5f0 100644
--- a/drivers/usb/typec/hd3ss3220.c
+++ b/drivers/usb/typec/hd3ss3220.c
@@ -259,12 +259,12 @@ static int hd3ss3220_probe(struct i2c_client *client)
 		goto err_put_fwnode;
 	}
 
-	typec_cap.prefer_role = TYPEC_NO_PREFERRED_ROLE;
+	ret = typec_get_fw_cap(&typec_cap, connector);
+	if (ret)
+		goto err_put_role;
+
 	typec_cap.driver_data = hd3ss3220;
-	typec_cap.type = TYPEC_PORT_DRP;
-	typec_cap.data = TYPEC_PORT_DRD;
 	typec_cap.ops = &hd3ss3220_ops;
-	typec_cap.fwnode = connector;
 
 	hd3ss3220->port = typec_register_port(&client->dev, &typec_cap);
 	if (IS_ERR(hd3ss3220->port)) {

-- 
2.34.1

