From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 18 Feb 2026 10:54:45 -0800
Subject: [PATCH] MAINTAINERS: update usnic maintainer list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-usnic-maintainers-update-v1-1-dbbcd47e4656@cisco.com>
X-B4-Tracking: v=1; b=H4sIAPUKlmkC/x2MMQqAMAwAvyKZDbRBi/oVcSiaagarNCqC+HeLw
 w033D2gnIQVuuKBxJeobDGLLQsYFx9nRpmyAxlyhmyDp0YZcfUSjwwnxXOf/MFItg4tka2caSD
 ne+Ig97/uh/f9AJjiq41qAAAA
To: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771440905; l=963;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=XXis8Q3RTLAezBt3nclyBpHBs1gea64wFHPCq4VKzdc=;
 b=teoWY4K0b72+WlyIONFEHUsyIaCdb5icol5n9ZTBfdsaEHUuWciXivMbaOs1nwRCdGt2HE6aB
 tVZxYtkrjPPAb1SJg9iIL12ILM6U6ClxwL/uv1O7UJZJ/POEtQs1ED6
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove Christian Benvenuti from the usnic maintainer list because he is no
longer working on the driver and the email address is no longer valid.
Add Satish Kharat and Norman Anderson as maintainers.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 MAINTAINERS | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 04e5fb80c32c..3310c2afa177 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6179,8 +6179,9 @@ S:	Maintained
 F:	drivers/net/ethernet/cisco/enic/
 
 CISCO VIC LOW LATENCY NIC DRIVER
-M:	Christian Benvenuti <benve@cisco.com>
 M:	Nelson Escobar <neescoba@cisco.com>
+M:	Satish Kharat <satishkh@cisco.com>
+M:	Norman Anderson <noanders@cisco.com>
 S:	Supported
 F:	drivers/infiniband/hw/usnic/
 

---
base-commit: 37a93dd5c49b5fda807fd204edf2547c3493319c
change-id: 20260218-usnic-maintainers-update-215f92214608

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

