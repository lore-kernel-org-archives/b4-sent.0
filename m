From: David Heidelberg <david@ixit.cz>
Date: Sun, 22 Nov 2026 21:24:18 +0100
Subject: [PATCH v2 1/2] rpmsg: glink: Support waking up on channel rx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rpmsg-qcom-glink-v2-1-d60419793095@ixit.cz>
References: <20261122-rpmsg-qcom-glink-v2-0-d60419793095@ixit.cz>
In-Reply-To: <20261122-rpmsg-qcom-glink-v2-0-d60419793095@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>
Cc: Dylan Van Assche <git@dylanvanassche.be>, 
 Casey Connolly <casey.connolly@linaro.org>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2360; i=david@ixit.cz;
 h=from:subject:message-id; bh=06ZIYAQUhWWSAAEUAnmn8k9bBrxIJztSjTuxD93oOH8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrA09yMdhKSwVswez+9ehBpuUYcJ29+8JxL+s+j
 d8AC6ovBrqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawNPcgAKCRBgAj/E00kg
 cniVEACOoyCgN1DP4Wo2KEoeOdBiZGDfBZbVTaTfeV8harG1bv9zwlQei7kr/sHnOyngIq+aw3P
 wcJp7O7LjErJaM46/1rBeMN/bdxaz2hlkgv6GKT3eOmyX5j6ymcdduSdovBWXe/UdXbNpaUwpkd
 jmUfvJvPbd9yjBRZvZFnE7Gf1rR0Mn1R8l75zSJJ+i6ocjU+9HhO76o04fcBDFGEapyXZhaGK6y
 u6T9hDFR1AKEXQ1KFZcg2ZntqMlCsZI/d1wrIgeL8xTGUKrGjMTKmEDCNElikFlgON94K6SBAZu
 xCgPXR1RP9abb1TUWSXuRTDpj1lYuACobxZ+WKwwliCkQITeCOFvg+q3G3AFCy5W+lqrrjQYRTV
 urgOc1X33Qh7ySML9ymvtZmXERLlykM2PxQGb+3mvhJfybUbCNNWLs8RpSgaRbKiFQ49Gf8Pcnt
 6elPc1zvyPqDSTcxtIPXkkSIAvWEtDJV5noreDJFfS8NeESDpPkszvTZ0xwlCyAzhV1ZSzOxuAS
 vEJY2qG4us65Gm0Rq+YPCtUfPmzLEXyQp4BZlD5YxmqOw/ugckobS0KKgUXBxF4XgKq95Ye+95x
 EiKzAk8zu71ppVMKMrchPe7Tgrm6qS4HecrJYeLiAFwBxiOKlABtR5WH++woDn2nXGIoeIQGIKe
 rPwkGypTw7TaIUQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Configure all channels as wakeup capable and report a wakeup event
when data is received.

This allows userspace to "subscribe" to a particular channel where
it is useful to wake up to process new data. The expected usecase
is to allow for handling incoming SMS or phone calls where the only
notification mechanism is via QRTR on the IPCRTR glink channel.

As this behaviour is likely undesirable for most users, this patch
doesn't enable a wakeup_source for any channels by default.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/rpmsg/qcom_glink_native.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/rpmsg/qcom_glink_native.c b/drivers/rpmsg/qcom_glink_native.c
index f848ab46161d1..02ac790251303 100644
--- a/drivers/rpmsg/qcom_glink_native.c
+++ b/drivers/rpmsg/qcom_glink_native.c
@@ -993,16 +993,17 @@ static int qcom_glink_rx_data(struct qcom_glink *glink, size_t avail)
 	if (!left_size) {
 		spin_lock(&channel->recv_lock);
 		if (channel->ept.cb) {
 			channel->ept.cb(channel->ept.rpdev,
 					intent->data,
 					intent->offset,
 					channel->ept.priv,
 					RPMSG_ADDR_ANY);
+			pm_wakeup_hard_event(&channel->ept.rpdev->dev);
 		}
 		spin_unlock(&channel->recv_lock);
 
 		intent->offset = 0;
 		channel->buf = NULL;
 
 		qcom_glink_rx_done(glink, channel, intent);
 	}
@@ -1684,16 +1685,27 @@ static int qcom_glink_rx_open(struct qcom_glink *glink, unsigned int rcid,
 		rpdev->dev.of_node = node;
 		rpdev->dev.parent = glink->dev;
 		rpdev->dev.release = qcom_glink_rpdev_release;
 
 		ret = rpmsg_register_device(rpdev);
 		if (ret)
 			goto rcid_remove;
 
+		/*
+		 * Declare all channels as wakeup capable, but don't enable
+		 * waking up by default.
+		 *
+		 * Userspace may wish to be woken up for incoming messages on a
+		 * specific channel, for example to handle incoming calls or SMS
+		 * messages on the IPCRTR channel. This can be done by enabling
+		 * the wakeup source via sysfs.
+		 */
+		device_set_wakeup_capable(&rpdev->dev, true);
+
 		channel->rpdev = rpdev;
 	}
 
 	return 0;
 
 rcid_remove:
 	spin_lock_irqsave(&glink->idr_lock, flags);
 	idr_remove(&glink->rcids, channel->rcid);

-- 
2.55.0

