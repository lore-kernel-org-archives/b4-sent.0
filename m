From: Satish Kharat <satishkh@cisco.com>
Date: Thu, 19 Feb 2026 11:24:00 -0800
Subject: [PATCH] MAINTAINERS: update enic and usnic maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260219-enic-maintainers-update-v2-v1-1-c58aa11c2ea8@cisco.com>
X-B4-Tracking: v=1; b=H4sIAE9jl2kC/x3MOwqAMBBF0a3I1A7E+EHdilgE89QpjJJoEMS9G
 yxucZr7UIAXBOqzhzyiBNldQpFnNK3GLWCxyaSVbpQuOoaTiTcj7kzBB74Oa05w1GzRokarqnK
 uKA0Oj1nufz6M7/sBYxncCGwAAAA=
To: netdev@vger.kernel.org
Cc: Jakub Kicinski <kuba@kernel.org>, Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771529102; l=1100;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=7EAm7q54AU0UQ6XPv8J2+vHkr+1SMF1VEQ16JVUETpw=;
 b=YSIdvXPmGz6z8kxnMYyLzYt4Z1lG8y26WJw1hYgR1NWoA45TeRE1AnGgnX1fnI9xxk0zDRTW+
 iHf5ITT0oNbCKmdl57ujzoZxrvbekFkHNEt1UBPWR7ISMce89Vp35m6
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove Christian Benvenuti from the enic/usnic maintainer lists because he
is no longer working on the drivers and the email address is no longer valid.
Keep Satish Kharat as the enic maintainer and the usnic co-maintainer.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 MAINTAINERS | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 04e5fb80c..239a1948c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6173,14 +6173,13 @@ S:	Supported
 F:	drivers/scsi/snic/
 
 CISCO VIC ETHERNET NIC DRIVER
-M:	Christian Benvenuti <benve@cisco.com>
 M:	Satish Kharat <satishkh@cisco.com>
 S:	Maintained
 F:	drivers/net/ethernet/cisco/enic/
 
 CISCO VIC LOW LATENCY NIC DRIVER
-M:	Christian Benvenuti <benve@cisco.com>
 M:	Nelson Escobar <neescoba@cisco.com>
+M:	Satish Kharat <satishkh@cisco.com>
 S:	Supported
 F:	drivers/infiniband/hw/usnic/
 

---
base-commit: 37a93dd5c49b5fda807fd204edf2547c3493319c
change-id: 20260219-enic-maintainers-update-v2-de8e5e8043f4

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

