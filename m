From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 25 Aug 2026 00:46:33 +0200
Subject: [PATCH v2] platform/x86: asus-wmi: suppress -ENODEV warning in
 fan_curve_get_factory_default()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260825-fan-curve-v2-1-2ee1ffd2a1a3@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDCyMT3bTEPN3k0qKyVN3UPH8X1zAloMqCotS0zAqwKdGxEH5xaVJWanI
 JSKtSbS0AMvTBv2cAAAA=
X-Change-ID: 20260824-fan-curve-enODEV
To: luke@ljones.dev
Cc: denis.benato@linux.dev, ilpo.jarvinen@linux.intel.com, hansg@kernel.org, 
 corentin.chary@gmail.com, fxzxaxon@outlook.com, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787611592; l=1285;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=5pBe+s77ZOy93/fwA7ehJ07ZlIr00ptgYIjNjLjwA9w=;
 b=E5yuCqVjc4wnPArmrapjBIVXmsVi5slpvrrhIjDrAnQ2nEaNHVMIj8lPs1S5KPNOD3xd+LzFH
 12olN68QLxeCvLpySxHi0RyuKYxUcyV2HyAybNYGsF4dYeNAA6QFc5s
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When firmware does not support the fan curve WMI method,
asus_wmi_evaluate_method_buf() returns -ENODEV. Callers treat this
as non-fatal, but the pr_warn() here still fires, producing
spurious boot noise on unsupported hardware. Downgrade the message
to pr_debug().

---
Changes in v2:
- Downgrade the message to pr_debug() as suggested by Ilpo Järvinen.
- Link to v1: https://lore.kernel.org/r/20260503174752.26288-1-armundunelis@gmail.com
---
 drivers/platform/x86/asus-wmi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/platform/x86/asus-wmi.c b/drivers/platform/x86/asus-wmi.c
index e835779b6..527289b7d 100644
--- a/drivers/platform/x86/asus-wmi.c
+++ b/drivers/platform/x86/asus-wmi.c
@@ -3610,7 +3610,7 @@ static int fan_curve_get_factory_default(struct asus_wmi *asus, u32 fan_dev)
 	err = asus_wmi_evaluate_method_buf(asus->dsts_id, fan_dev, mode, buf,
 					   FAN_CURVE_BUF_LEN);
 	if (err) {
-		pr_warn("%s (0x%08x) failed: %d\n", __func__, fan_dev, err);
+		pr_debug("%s (0x%08x) failed: %d\n", __func__, fan_dev, err);
 		return err;
 	}
 

---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260824-fan-curve-enODEV

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

