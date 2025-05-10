From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 10 May 2025 07:44:43 +0000
Subject: [PATCH 3/7] Revert "nvmem: core: Print error on wrong bits DT
 property"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250510-nvmem-dt-v1-3-eccfa6e33f6a@svenpeter.dev>
References: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
In-Reply-To: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
To: Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1031; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=hpPWBCehpQX+TRroEYSLZmoZuXPmZL8t0ylnYC5nM1Q=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y883++/u3l1adVWlJs9YLZTxQcu8fofWhL8YmaEy5cU
 +Rf17d0lLIwiHEwyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACZiUMnw3+vR7e2GDusU50ks
 z3jCtm3S2wPbI/5ufdvw/NekJt4HDHmMDL/uGzoqHLjJfEXi5U1z2z+BCZ7ui/VnX7ox4Ye1mqx
 FARMA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

This reverts commit def3173d4f17b37cecbd74d7c269a080b0b01598.

Now that the core supports accessing bits even beyond the first byte
this additional error check is no longer required.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/nvmem/core.c | 5 -----
 1 file changed, 5 deletions(-)

diff --git a/drivers/nvmem/core.c b/drivers/nvmem/core.c
index 02081c93fa467e5448bd78a4920072d437365fb9..ef1f59b34d262a533fb601d87fec123061cfff81 100644
--- a/drivers/nvmem/core.c
+++ b/drivers/nvmem/core.c
@@ -837,11 +837,6 @@ static int nvmem_add_cells_from_dt(struct nvmem_device *nvmem, struct device_nod
 		if (addr && len == (2 * sizeof(u32))) {
 			info.bit_offset = be32_to_cpup(addr++);
 			info.nbits = be32_to_cpup(addr);
-			if (info.bit_offset >= BITS_PER_BYTE || info.nbits < 1) {
-				dev_err(dev, "nvmem: invalid bits on %pOF\n", child);
-				of_node_put(child);
-				return -EINVAL;
-			}
 		}
 
 		info.np = of_node_get(child);

-- 
2.34.1

