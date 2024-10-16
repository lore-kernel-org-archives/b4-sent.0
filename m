From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 16 Oct 2024 15:54:15 +0800
Subject: [PATCH v6 03/10] drm/bridge: it6505: add AUX operation for HDCP
 KSV list read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241016-upstream-v6-v6-3-4d93a0c46de1@ite.com.tw>
References: <20241016-upstream-v6-v6-0-4d93a0c46de1@ite.com.tw>
In-Reply-To: <20241016-upstream-v6-v6-0-4d93a0c46de1@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Pin-yen Lin <treapking@chromium.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Kenneth Hung <Kenneth.hung@ite.com.tw>, Pet Weng <Pet.Weng@ite.com.tw>, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729065263; l=3378;
 i=Hermes.wu@ite.com.tw; s=20241016; h=from:subject:message-id;
 bh=/fXuff/9Svbqq/yjBT5j6wJt5HiXdNiMkfV4cxh+1Hc=;
 b=hgM8V5HmaMpSlfa6wZQTlCWcl87TVKfQieSoZzkUfFgJdSlxP+CyEWIUhodpDPZt7RZQSrTEW
 e0biuS01fhpAgmpl84QOlj9qUzISbNCVue2iWR3FdHhe8dckvKAmJGv
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=kV18uQEXox+1WccdQceCbMlJKN+BBNUk3N8VsoULcQ0=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241016 with auth_id=250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HDCP KSV list readback can choose to use AUX FIFO or
general data register.
For some DisplayPort devices, the KSV list must be read
in 5 byte boundaries.
The original AUX read command does not support these devices.

The AUX command operation control register "REG_AUX_CMD_REQ" uses b[3:0]
as AUX operacion control, and b[7:4] are status bits and read only.
To change KSV read operation uses "CMD_AUX_NATIVE_READ" from using
the data registers to using AUX FIFO.
The extended command "CMD_AUX_GET_KSV_LIST" is added as
"CMD_AUX_NATIVE_READ" with the 0x10 flag which selects AUX FIFO mode.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 16 +++++++++++-----
 1 file changed, 11 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 9747d7ccf435d536da55c6a3ff79e504b7c724f0..4e6ec1695ae45111d06026d7548d108fac9e5219 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -126,6 +126,7 @@
 #define REG_AUX_OUT_DATA0 0x27
 
 #define REG_AUX_CMD_REQ 0x2B
+#define M_AUX_REQ_CMD 0x0F
 #define AUX_BUSY BIT(5)
 
 #define REG_AUX_DATA_0_7 0x2C
@@ -324,6 +325,9 @@ enum aux_cmd_type {
 	CMD_AUX_NATIVE_READ = 0x0,
 	CMD_AUX_NATIVE_WRITE = 0x5,
 	CMD_AUX_I2C_EDID_READ = 0xB,
+
+	/* KSV read with AUX FIFO extend from CMD_AUX_NATIVE_READ*/
+	CMD_AUX_GET_KSV_LIST = 0x10,
 };
 
 enum aux_cmd_reply {
@@ -965,7 +969,8 @@ static ssize_t it6505_aux_operation(struct it6505 *it6505,
 	it6505_set_bits(it6505, REG_AUX_CTRL, AUX_USER_MODE, AUX_USER_MODE);
 
 aux_op_start:
-	if (cmd == CMD_AUX_I2C_EDID_READ) {
+	/* HW AUX FIFO supports only EDID and DCPD KSV FIFO area */
+	if (cmd == CMD_AUX_I2C_EDID_READ || cmd == CMD_AUX_GET_KSV_LIST) {
 		/* AUX EDID FIFO has max length of AUX_FIFO_MAX_SIZE bytes. */
 		size = min_t(size_t, size, AUX_FIFO_MAX_SIZE);
 		/* Enable AUX FIFO read back and clear FIFO */
@@ -996,7 +1001,7 @@ static ssize_t it6505_aux_operation(struct it6505 *it6505,
 				  size);
 
 	/* Aux Fire */
-	it6505_write(it6505, REG_AUX_CMD_REQ, cmd);
+	it6505_write(it6505, REG_AUX_CMD_REQ, FIELD_GET(M_AUX_REQ_CMD, cmd));
 
 	ret = it6505_aux_wait(it6505);
 	if (ret < 0)
@@ -1030,7 +1035,7 @@ static ssize_t it6505_aux_operation(struct it6505 *it6505,
 		goto aux_op_start;
 	}
 
-	if (cmd == CMD_AUX_I2C_EDID_READ) {
+	if (cmd == CMD_AUX_I2C_EDID_READ || cmd == CMD_AUX_GET_KSV_LIST) {
 		for (i = 0; i < size; i++) {
 			ret = it6505_read(it6505, REG_AUX_DATA_FIFO);
 			if (ret < 0)
@@ -1055,7 +1060,7 @@ static ssize_t it6505_aux_operation(struct it6505 *it6505,
 	ret = i;
 
 aux_op_err:
-	if (cmd == CMD_AUX_I2C_EDID_READ) {
+	if (cmd == CMD_AUX_I2C_EDID_READ || cmd == CMD_AUX_GET_KSV_LIST) {
 		/* clear AUX FIFO */
 		it6505_set_bits(it6505, REG_AUX_CTRL,
 				AUX_EN_FIFO_READ | CLR_EDID_FIFO,
@@ -1076,7 +1081,8 @@ static ssize_t it6505_aux_do_transfer(struct it6505 *it6505,
 				      size_t size, enum aux_cmd_reply *reply)
 {
 	int i, ret_size, ret = 0, request_size;
-	int fifo_max_size = (cmd == CMD_AUX_I2C_EDID_READ) ? AUX_FIFO_MAX_SIZE : 4;
+	int fifo_max_size = (cmd == CMD_AUX_I2C_EDID_READ || cmd == CMD_AUX_GET_KSV_LIST) ?
+						 AUX_FIFO_MAX_SIZE : 4;
 
 	mutex_lock(&it6505->aux_lock);
 	i = 0;

-- 
2.34.1

