From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 24 Mar 2025 10:24:59 +0400
Subject: [PATCH] wifi: ath11k: support fetching mac address from nvmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250324-ath11k-nvmem-v1-1-d82bdf72820e@outlook.com>
X-B4-Tracking: v=1; b=H4sIALv64GcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYyMT3cSSDEPDbN28stzUXF3LJJM0U5M0ExNDCwsloJaCotS0zAqwcdG
 xtbUAm2N0AF4AAAA=
To: Jeff Johnson <jjohnson@kernel.org>
Cc: ath11k@lists.infradead.org, linux-wireless@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742797500; l=1623;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=KFf/U6jpX3DLdf5cfXG9vG8Hbqcu1hFbIGhlckUUI7s=;
 b=PoKhNSfsaNEQZQFXjHirGqsZeV20EcazdhX8I5TzQPa2R5lvPNK6z6IzkvT152fkvWA0wqYRc
 pYhUAbz+GmRA9jGIGq7rRxXYScv+jjqoQr0WP0xU9nY4HQw+aRbHwa9
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Many embedded devices with ath11k wifi chips store their mac address in
nvmem partitions. Currently, the ath11k driver supports getting the
mac address from the 'mac-address', 'local-mac-address', and 'address'
device tree properties only. As such, add support for obtaining the mac
address from nvmem if defined in a 'mac-address' cell by replacing the
call to device_get_mac_address by of_get_mac_address which does exactly
the same as the former but tries to get it from nvmem if it is not set
by above mentioned DT properties,

Tested-on: IPQ5018, QCN6122, and QCN9074

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/mac.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/mac.c b/drivers/net/wireless/ath/ath11k/mac.c
index 97816916abac..49af6b9fc867 100644
--- a/drivers/net/wireless/ath/ath11k/mac.c
+++ b/drivers/net/wireless/ath/ath11k/mac.c
@@ -9,6 +9,7 @@
 #include <linux/etherdevice.h>
 #include <linux/bitfield.h>
 #include <linux/inetdevice.h>
+#include <linux/of_net.h>
 #include <net/if_inet6.h>
 #include <net/ipv6.h>
 
@@ -10379,7 +10380,7 @@ int ath11k_mac_register(struct ath11k_base *ab)
 	if (ret)
 		return ret;
 
-	device_get_mac_address(ab->dev, mac_addr);
+	of_get_mac_address(ab->dev->of_node, mac_addr);
 
 	for (i = 0; i < ab->num_radios; i++) {
 		pdev = &ab->pdevs[i];

---
base-commit: 9388ec571cb1adba59d1cded2300eeb11827679c
change-id: 20250324-ath11k-nvmem-9b4f54f44188

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

