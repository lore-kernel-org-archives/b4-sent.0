From: Mitchell Levy <levymitchell0@gmail.com>
Date: Wed, 09 Aug 2023 22:36:33 +0000
Subject: [PATCH RFC 2/2] Use raw_spinlock_t in vmbus_requestor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230809-b4-rt_preempt-fix-v1-2-7283bbdc8b14@gmail.com>
References: <20230809-b4-rt_preempt-fix-v1-0-7283bbdc8b14@gmail.com>
In-Reply-To: <20230809-b4-rt_preempt-fix-v1-0-7283bbdc8b14@gmail.com>
To: "K. Y. Srinivasan" <kys@microsoft.com>, 
 Haiyang Zhang <haiyangz@microsoft.com>, Wei Liu <wei.liu@kernel.org>, 
 Dexuan Cui <decui@microsoft.com>, Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-hyperv@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Mitchell Levy <levymitchell0@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691620601; l=1927;
 i=levymitchell0@gmail.com; s=20230725; h=from:subject:message-id;
 bh=EMJGmT0DQG0esS7skhyoOPlaFdOdEE5n0AicQTDKFKM=;
 b=nzyA2dEaoaRd4dZs3CNTlzbUnk4r4uOA/q8ghaPpY2ha0OZ1ImmjjWga6I4G6m2Hl99JhZWmY
 cM1WxeA70J1BmGVE6hve2u+KEmeyyz+vYgRNGnObBN7PP3wTJz4DXbT
X-Developer-Key: i=levymitchell0@gmail.com; a=ed25519;
 pk=o3BLKQtTK7QMnUiW3/7p5JcITesvc3qL/w+Tz19oYeE=
X-Endpoint-Received: by B4 Relay for levymitchell0@gmail.com/20230725 with auth_id=69
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Because hv_pci_onchannelcallback is called with irq disabled in
hv_compose_msi_msg, any locks held in that function must not be
sleepable. Therefore, change vmbus_requestor to use raw_spinlock_t.
---
 drivers/hv/channel.c   | 2 +-
 include/linux/hyperv.h | 6 +++---
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/hv/channel.c b/drivers/hv/channel.c
index 00d73ec060ed..08e6bd4a056d 100644
--- a/drivers/hv/channel.c
+++ b/drivers/hv/channel.c
@@ -635,7 +635,7 @@ static int vmbus_alloc_requestor(struct vmbus_requestor *rqstor, u32 size)
 	rqstor->req_bitmap = bitmap;
 	rqstor->size = size;
 	rqstor->next_request_id = 0;
-	spin_lock_init(&rqstor->req_lock);
+	raw_spin_lock_init(&rqstor->req_lock);
 
 	return 0;
 }
diff --git a/include/linux/hyperv.h b/include/linux/hyperv.h
index 56a1fb1647a4..664c03a78e11 100644
--- a/include/linux/hyperv.h
+++ b/include/linux/hyperv.h
@@ -787,7 +787,7 @@ struct vmbus_requestor {
 	unsigned long *req_bitmap; /* is a given slot available? */
 	u32 size;
 	u64 next_request_id;
-	spinlock_t req_lock; /* provides atomicity */
+	raw_spinlock_t req_lock; /* provides atomicity */
 };
 
 #define VMBUS_NO_RQSTOR U64_MAX
@@ -1050,7 +1050,7 @@ struct vmbus_channel {
 do {									\
 	struct vmbus_requestor *rqstor = &(channel)->requestor;		\
 									\
-	spin_lock_irqsave(&rqstor->req_lock, flags);			\
+	raw_spin_lock_irqsave(&rqstor->req_lock, flags);		\
 } while (0)
 
 static __always_inline void unlock_requestor(struct vmbus_channel *channel,
@@ -1058,7 +1058,7 @@ static __always_inline void unlock_requestor(struct vmbus_channel *channel,
 {
 	struct vmbus_requestor *rqstor = &channel->requestor;
 
-	spin_unlock_irqrestore(&rqstor->req_lock, flags);
+	raw_spin_unlock_irqrestore(&rqstor->req_lock, flags);
 }
 
 u64 vmbus_next_request_id(struct vmbus_channel *channel, u64 rqst_addr);

-- 
2.25.1

